// The 64-bit CPU (M10, E091): sixteen 64-bit registers, RIP and RFLAGS, in long mode's
// 64-bit code and at privilege level 3. Nothing here is shared with the 32-bit machine of
// exec.goose; g64m.goose is the root file that uses this one.
//
// What is here so far is what runs a program in user mode: the integer instructions a
// compiler emits. A list, by first byte:
//   00-3F the eight arithmetic operations; 50-5F PUSH and POP; 63 MOVSXD; 68 6A PUSH of a
//   constant; 69 6B IMUL; 70-7F Jcc; 80 81 83; 84 85 TEST; 86 87 XCHG; 88-8B MOV; 8D LEA;
//   8F POP; 90-97; 98 99; 9C 9D PUSHF POPF; 9E 9F; A0-A3; A4-A7 AA-AF the strings, with REP
//   (and 6C-6F, those of the ports, in a machine);
//   A8 A9; B0-BF; C0 C1 D0-D3 shifts and rotates; C2 C3 RET; C6 C7; C9 LEAVE; E0-E3; E8 E9
//   EB; F5 F8 F9 FC FD; F6 F7; FE FF.
//   0F: 05 SYSCALL; 0B UD2; 0D 18-1F (no operation); 31 RDTSC; 40-4F CMOVcc; 80-8F Jcc;
//   90-9F SETcc; A2 CPUID; A3 AB B3 BB BA the bit tests; A4 A5 AC AD SHLD SHRD; AF IMUL;
//   B0 B1 CMPXCHG; B6 B7 BE BF MOVZX MOVSX; B8 POPCNT; BC BD BSF BSR; C0 C1 XADD; C7
//   CMPXCHG8B and 16B; C8-CF BSWAP.
// SSE and SSE2 are in sse64.goose (0F 10-17, 28-2F, 50-7F, AE, C2-C6, D0-FF), and the x87
// (D8-DF) in fpu.goose, which the i686 machine uses too.
// Not yet: x87, segment registers, anything privileged, and faults: an instruction
// that would fault stops the run with a message.
//
// The flags the manual leaves undefined are what an Intel Core i7-3770K (Ivy Bridge) leaves
// in them: the traces of tests/expected64 were taken on one (tools/oracle/step64.c).
//
// Memory, for now, is one block that starts at address 0: a program's addresses are indexes
// into it. Every access goes through rd and wr, which is where paging will go.

import std;
import os;
import g64m;
import sse64;
import sys64;
import jit64;
import fpu;

let MEM_SIZE = 268435456;       // 256 MB

let RAX = 0; let RCX = 1; let RDX = 2; let RBX = 3;
let RSP = 4; let RBP = 5; let RSI = 6; let RDI = 7;

let CF = 0x0001; let PF = 0x0004; let AF = 0x0010; let ZF = 0x0040;
let SF = 0x0080; let TF = 0x0100; let IF = 0x0200; let DF = 0x0400; let OF = 0x0800;
let RF = 0x10000;
let ARITH = 0x8D5;              // CF, PF, AF, ZF, SF and OF

var reg: u64[16] = [0; 16];
var rip: u64 = 0;
var rflags: u64 = 0x202;
var fs_base: u64 = 0;
var gs_base: u64 = 0;
var steps: u64 = 0;             // instructions done, which is also what RDTSC reads

// The instruction at hand.
var ip: u64 = 0;                // where the next byte of it is fetched from
var m_off: u64 = 0;             // a memory operand's offset,
var m_ea: u64 = 0;              // and its address: the offset with FS's or GS's base added

// What the instruction's bytes say (E109): the prefixes and the opcode, then what its ModRM,
// SIB and displacement bytes describe. 24 bytes, kept whole in the decode cache, so that an
// instruction met again is one copy and nothing is unpacked.
struct Ins {
    op: u8,
    rex: u8,             // the REX prefix, 0 for none
    osz: u8,             // the operand size where it is not a byte: 16, 32 or 64
    rep: u8,             // F2h, F3h or 0
    p66: bool,
    asz32: bool,
    sg: u8,              // a segment prefix that counts: 1 FS, 2 GS, 0 none
    plen: u8,            // how many bytes the prefixes and the opcode take
    mlen: u8,            // how many up to the end of the operand's bytes; 0: the rest is not known
    mod: u8,
    reg: u8,             // with REX.R
    rm: u8,              // with REX.B where it names a register
    base: u8,            // the base register; 16 none, 17 RIP
    index: u8,           // the index register; 16 none
    scale: u8,
    kind: u8,            // which arm of the short front runs it (K_...); 0 none
    disp: u64,           // the displacement, sign-extended
}
var ins: Ins = Ins { op: 0, rex: 0, osz: 32, rep: 0, p66: false, asz32: false, sg: 0, plen: 0,
                     mlen: 0, mod: 0, reg: 0, rm: 0, base: 16, index: 16, scale: 0, kind: 0, disp: 0 };

// The ModRM byte's fields as the x87 reads them (fpu.goose, shared with the 32-bit machine):
// 0 to 7 each, set for an escape opcode only.
var m_mod: u8 = 0;
var m_reg: u8 = 0;
var m_rm: u8 = 0;

// The base a segment prefix adds. It is read from the register at each use: the prefix is
// remembered, the base is not, since the program changes it.
inline fn seg_base() -> u64 {
    if ins.sg == 0 { return 0; }
    return if ins.sg == 1 { fs_base } else { gs_base };
}

var halted = false;
// Set by the few instructions after which the run loop must look up before the next one
// (E106): a halt, a stop, STI's shadow, SYSCALL and SYSRET (for the single step).
var attn = false;
var sti_shadow = false;      // the instruction at hand follows an STI that set IF
var stopped = false;
var faulted = false;
var exit_code: i64 = 0;

// What every instruction reads or writes before its own work, kept together and in front
// of the memory (E110): globals lie in the order they are declared, and one that is far
// from the rest costs two host instructions more at each use. The code page's are
// described at code_fill, the decode cache's at its head, the last six in sys64.goose.
var code_page: u64 = 0xFFFFFFFFFFFFFFFF;     // its page number; all ones for none
var code_end: u64 = 0;                       // the address just past it; 0 for none
var code_delta: u64 = 0;                     // what to take from an address on it to index memory
var dc_cur: i64 = -1;            // the entry of the instruction at hand; -1 if it can have none
var saved_flags: u64 = 0;         // the flags the instruction at hand started with
var pending: i64 = -1;            // a fault or interrupt waiting to be delivered; -1 none
var code_cpl: u8 = 0;                        // the privilege level it was taken at
var dc_on = true;                // --no-decode-cache clears it
var start_saved = false;          // the registers and the level were saved; the flags always are
var delivered = false;
var machine = false;
var cpl: u8 = 3;

var mem: u8[MEM_SIZE];

// A 64-bit number as sixteen hex digits (format_int would write an address in the upper half
// as a negative number).
fn hex64(out: u8[>..]&, v: u64) {
    for i in 16 { out.push("0123456789abcdef"[v >> (((15 - i) * 4) as! u64) & 15]); }
}

// ---- Stopping ----

// Ends the run where an instruction cannot be done: not written yet, or a fault that
// nothing delivers yet. The registers are left as they are; RIP is the instruction's start.
fn stop64(what: const u8[:], v: u64) {
    var msg: u8[>..] = [];
    format(msg, "g64m: ", what, " ");
    format_int(msg, v as! i64, 16, 2, '0');
    format(msg, " at ");
    hex64(msg, rip);
    format(msg, "  bytes:");
    for i in 12 {
        let a = rip + (i as! u64);
        if a < MEM_SIZE { format(msg, " "); format_int(msg, mem[a], 16, 2, '0'); }
    }
    format(msg, "\n");
    write_stderr(msg);
    stopped = true;
    faulted = true;
    attn = true;
    return false from exec64;
}

// ---- Memory ----

inline fn mask(w: u8) -> u64 {
    if w == 8 { return 0xFF; }
    if w == 16 { return 0xFFFF; }
    if w == 32 { return 0xFFFFFFFF; }
    return 0xFFFFFFFFFFFFFFFF;
}

inline fn msb(w: u8) -> u64 {
    if w == 8 { return 0x80; }
    if w == 16 { return 0x8000; }
    if w == 32 { return 0x80000000; }
    return 0x8000000000000000;
}

// All ones if on, else zero.
inline fn ones(on: bool) -> u64 {
    if on { return 0xFFFFFFFFFFFFFFFF; }
    return 0;
}

// v's low w bits as a signed number, in 64 bits.
inline fn sx(v: u64, w: u8) -> u64 {
    if w == 8 { return ((v as! u8) as! i8) as! u64; }
    if w == 16 { return ((v as! u16) as! i16) as! u64; }
    if w == 32 { return ((v as! u32) as! i32) as! u64; }
    return v;
}

// The block itself: i is inside it.
// One test of the whole access, so that the bytes are taken by one load (E108). The callers
// keep a under MEM_SIZE - 8; the test here is what lets the compiler see it.
// The shape matters to the compiler: where two widths both begin with the byte at i it
// takes that byte out in front of the test of the width, and then neither becomes one
// load. So eight bytes are read from the top byte down, and four are in a function of
// their own. A store of eight bytes is four and four; the upper four the compiler makes
// vector instructions of (about fifteen), which three ways of writing it did not change.
fn mem_rd(a: u64, w: u8) -> u64 {
    if a >= MEM_SIZE - 8 { return 0; }
    let i = a as! i64;
    if w == 64 {
        let b7: u64 = mem[i + 7];
        let b6: u64 = mem[i + 6];
        let b5: u64 = mem[i + 5];
        let b4: u64 = mem[i + 4];
        let b3: u64 = mem[i + 3];
        let b2: u64 = mem[i + 2];
        let b1: u64 = mem[i + 1];
        let b0: u64 = mem[i];
        return b0 | b1 << 8 | b2 << 16 | b3 << 24 | b4 << 32 | b5 << 40 | b6 << 48 | b7 << 56;
    }
    if w == 32 { return ld32(i); }
    if w == 8 { return mem[i]; }
    let b0: u64 = mem[i];
    let b1: u64 = mem[i + 1];
    return b0 | b1 << 8;
}

// Four bytes at once; i is known to be inside the block.
fn ld32(i: i64) -> u64 {
    let b0: u32 = mem[i];
    let b1: u32 = mem[i + 1];
    let b2: u32 = mem[i + 2];
    let b3: u32 = mem[i + 3];
    return b0 | b1 << 8 | b2 << 16 | b3 << 24;
}

// ---- The decode cache (E107) ----
//
// What an instruction's bytes say that does not change from one execution to the next: its
// prefixes and opcode, and what its ModRM, SIB and displacement bytes describe. An entry is
// found by the physical address of the instruction's first byte (its tag) and holds the
// instruction as decoded (Ins, above), in the form it is used in: 32 bytes with the tag.
// Constants are not kept: they are read from the code page each time.
//
// An entry is made only from bytes that all lie on one page (the code page, E105), and is
// good while that page is not written to: a page that holds entries is marked, and a write
// to a marked page drops its entries. A page that is dropped again and again (code and data
// that is written on one page) is given up: nothing is remembered from it.
let DC_BITS = 20;
let DC_SIZE = 1 << DC_BITS;
let DC_NONE: u64 = 0xFFFFFFFFFFFFFFFF;
let DC_GIVE_UP = 32;             // drops of one page after which it is not remembered from

struct Entry {
    tag: u64,            // all ones for none
    ins: Ins,
}
var dc: Entry[DC_SIZE] = [Entry { tag: 0xFFFFFFFFFFFFFFFF, ins: Ins { op: 0, rex: 0, osz: 32, rep: 0, p66: false, asz32: false, sg: 0, plen: 0,
                          mlen: 0, mod: 0, reg: 0, rm: 0, base: 16, index: 16, scale: 0, kind: 0, disp: 0 } }; DC_SIZE];
var dc_mark: u8[MEM_SIZE >> 12] = [0; MEM_SIZE >> 12];      // 1: holds entries; 2: given up
var dc_drops: u8[MEM_SIZE >> 12] = [0; MEM_SIZE >> 12];

// Beside each entry of the decode cache, for the JIT (jit64.goose). (Here, behind the
// memory, so that they do not push the CPU's own state away from the front of the globals.)
var dc_heat: u8[DC_SIZE] = [0; DC_SIZE];     // arrivals counted
var dc_cov: u8[DC_SIZE] = [0; DC_SIZE];      // 1: inside a block (E137)
var jit_land = false;                       // the instruction at hand is where a jump landed
var jit_resume = false;                     // the next one is to be taken so: a block left this one to the interpreter (E155)
var dc_k0: u8[DC_SIZE] = [0; DC_SIZE];       // a block's first instruction's own kind
var dc_n: u8[DC_SIZE] = [0; DC_SIZE];        // how many instructions the block is
var j_evicted: u64 = 0;                     // blocks lost to another instruction taking the entry
var dc_code: u32[DC_SIZE] = [0; DC_SIZE];    // where in the mapping it is
// Links (E122): the exits that wait for a block at an address, chained from the entry that
// address has; and which pages hold blocks.
var dc_wait: u32[DC_SIZE] = [0; DC_SIZE];
// The privilege level a block was translated at (E133): a machine's loads and stores use
// that level's tables of the TLB.
var dc_cpl: u8[DC_SIZE] = [0; DC_SIZE];
var jit_page: u8[MEM_SIZE >> 12] = [0; MEM_SIZE >> 12];
// How often a page that was given up has been run from since the last write to it.
let DC_CALM = 4096;
var dc_calm: u16[MEM_SIZE >> 12] = [0; MEM_SIZE >> 12];


inline fn dc_slot(p: u64) -> i64 { return ((p ^ p >> DC_BITS) & (DC_SIZE - 1)) as! i64; }
// The cache is in sets of two ways, a slot and its neighbour (E142: one cache line), so
// that a block's first instruction keeps its entry when another instruction wants the
// slot. The entry that holds p: its slot, or the first way's, which then does not hold p.
// How well the entry in slot s is worth keeping: 0 empty, 1 its instruction is inside a
// block, 2 to 257 in no block (by its arrivals), 300 a block's first instruction.
inline fn dc_worth(s: i64) -> i64 {
    if dc_n[s] != 0 { return 300; }
    if dc[s].tag == DC_NONE { return 0; }
    if dc_cov[s] != 0 { return 1; }
    return 2 + (dc_heat[s] as i64);
}
// The way of slot s's set that a new entry takes.
inline fn dc_give_up(s: i64) -> i64 {
    return if dc_worth(s ^ 1) < dc_worth(s) { s ^ 1 } else { s };
}
inline fn dc_find(p: u64) -> i64 {
    let s = dc_slot(p);
    if dc[s].tag == p { return s; }
    if dc[s ^ 1].tag == p { return s ^ 1; }
    return s;
}

// A marked page was written to: its entries go.
inline fn dc_drop(page: i64) {
    // A write to a page that was given up: it is not calm yet (E134).
    if dc_mark[page] == 2 { dc_calm[page] = 0; return; }
    if dc_mark[page] != 1 { return; }
    let base = (page << 12) as! u64;
    for k in 4096 {
        let at = base + (k as! u64);
        let slot = dc_find(at);
        if dc[slot].tag == at { dc[slot].tag = DC_NONE; }
    }
    // Blocks run into one another without looking (E122): if any is on this page, all go.
    // But in a machine a link never leaves its page (E133), and the far way looks at the
    // entries dropped just above: the page's blocks can be reached from nowhere now, and
    // the others stand (E134).
    if jit_page[page] != 0 {
        if machine { jit_page[page] = 0; } else { jit_flush(); }
    }
    if dc_drops[page] < 255 { dc_drops[page] += 1; }
    dc_mark[page] = if dc_drops[page] >= DC_GIVE_UP { 2 } else { 0 };
}

fn mem_wr(a: u64, w: u8, v: u64) {
    if a >= MEM_SIZE - 8 { return; }
    let i = a as! i64;
    // A store to a page that holds remembered instructions goes the long way, from an arm
    // that returns, so that the usual store has no call in it.
    if dc_mark[i >> 12] | dc_mark[(i + 7) >> 12] != 0 { mem_wr_marked(i, w, v); return; }
    mem_put(i, w, v);
}

fn mem_wr_marked(i: i64, w: u8, v: u64) {
    dc_drop(i >> 12);
    let last = (i + w / 8 - 1) >> 12;
    if last != i >> 12 { dc_drop(last); }
    mem_put(i, w, v);
}

inline fn mem_put(i: i64, w: u8, v: u64) {
    if w >= 32 {
        st32(i, v as! u32);
        if w == 64 { st32(i + 4, (v >> 32) as! u32); }
        return;
    }
    if w == 8 { mem[i] = v as! u8; return; }
    mem[i + 1] = (v >> 8) as! u8;
    mem[i] = v as! u8;
}

fn st32(i: i64, v: u32) {
    mem[i] = v as! u8;
    mem[i + 1] = (v >> 8) as! u8;
    mem[i + 2] = (v >> 16) as! u8;
    mem[i + 3] = (v >> 24) as! u8;
}

// A program's view of memory: in a user-mode program the block itself, in a machine through
// the page tables (sys64.goose).
fn rd(a: u64, w: u8) -> u64 {
    if machine { return sys_rd(a, w, 0); }
    if a >= MEM_SIZE - 8 { stop64("a read outside memory, at", a); }
    return mem_rd(a, w);
}

fn wr(a: u64, w: u8, v: u64) {
    if machine { sys_wr(a, w, v, 0); return; }
    if a >= MEM_SIZE - 8 { stop64("a write outside memory, at", a); }
    mem_wr(a, w, v);
}

// ---- What the x87 file needs of this CPU (see fpu.goose's head) ----

fn frd(k: u32, w: u8) -> u32 { return rd(m_ea + k, w) as! u32; }
fn fwr(k: u32, w: u8, v: u32) { wr(m_ea + k, w, v); }
fn fp_env32() -> bool { return !ins.p66; }
fn fp_set_ax(v: u16) { sr(RAX, 16, v); }
fn fp_set_zpc(bits: u32) { rflags = rflags & ~ARITH | bits; }
fn fp_stop(code: i64) { stop64("an x87 instruction not written yet, opcode and ModRM", code as! u64); }

// ---- Fetching ----

// The instruction's bytes are read as what they are: in a machine, through the translation
// for executing, so that a page that may not be executed faults at its first byte fetched.
fn code_rd(a: u64, w: u8) -> u64 {
    if machine { return sys_rd(a, w, ACC_EXEC); }
    if a >= MEM_SIZE - 8 { stop64("an instruction outside memory, at", a); }
    return mem_rd(a, w);
}

// The code page (E105): the page the instruction at hand starts on, translated once, so that
// its bytes are read from memory and not fetched through the tables one call each (which was
// 190 of the 654 host instructions a guest instruction cost, E104). It is taken, with the
// check that it may be executed, when RIP is on another page or the privilege level has
// changed, and forgotten when the TLB is emptied or a page of it forgotten. A byte that is
// not on it (an instruction that runs across the page's end) goes the long way.

fn code_fill() {
    code_page = 0xFFFFFFFFFFFFFFFF;
    code_end = 0;
    // With no code page the decode cache is to find nothing: RIP less this is an address
    // that is no entry's tag, and not the tag of an empty one either.
    code_delta = rip + 2;
    let start = rip & 0xFFFFFFFFFFFFF000;
    var p = start;
    if machine { p = xlate(rip, ACC_EXEC) & 0xFFFFFFFFFFFFF000; }
    // A page that is not in memory is fetched the long way, which knows what such reads give.
    if p >= MEM_SIZE - 0x2000 { return; }
    code_page = rip >> 12;
    code_cpl = cpl;
    code_end = start + 0x1000;
    code_delta = start - p;
    // The first instruction run on a page is where a jump from another page landed.
    jit_land = true;
}

inline fn fb() -> u64 {
    if ip < code_end { let v: u64 = mem[(ip - code_delta) as! i64]; ip += 1; return v; }
    let v = code_rd(ip, 8);
    ip += 1;
    return v;
}

inline fn fw() -> u64 {
    if ip + 1 < code_end { let v = mem_rd(ip - code_delta, 16); ip += 2; return v; }
    let v = code_rd(ip, 16);
    ip += 2;
    return v;
}

inline fn fd() -> u64 {
    if ip + 3 < code_end { let v = mem_rd(ip - code_delta, 32); ip += 4; return v; }
    let v = code_rd(ip, 32);
    ip += 4;
    return v;
}

fn fq() -> u64 {
    if ip + 7 < code_end { let v = mem_rd(ip - code_delta, 64); ip += 8; return v; }
    let v = code_rd(ip, 64);
    ip += 8;
    return v;
}

// The next byte, without taking it.
inline fn peek8() -> u64 {
    if ip < code_end { return mem[(ip - code_delta) as! i64]; }
    return code_rd(ip, 8);
}
fn fs8() -> u64 { return sx(fb(), 8); }
fn fs32() -> u64 { return sx(fd(), 32); }

// How many bytes a constant of an operand w bits wide takes: a 64-bit operand's is 32 bits,
// sign-extended.
inline fn imm_len(w: u8) -> u64 {
    if w == 8 { return 1; }
    if w == 16 { return 2; }
    return 4;
}

// That constant, sign-extended to 64 bits.
fn fimm(w: u8) -> u64 {
    if w == 8 { return fs8(); }
    if w == 16 { return sx(fw(), 16); }
    return fs32();
}

// ---- Registers ----

// Byte registers 4 to 7 are AH, CH, DH and BH without a REX prefix, and SPL, BPL, SIL and
// DIL with one.
fn gr(i: u8, w: u8) -> u64 {
    if w == 8 {
        if ins.rex == 0 && i >= 4 && i < 8 { return reg[i - 4] >> 8 & 0xFF; }
        return reg[i] & 0xFF;
    }
    return reg[i] & mask(w);
}

// A 32-bit result clears the register's upper half; 8 and 16-bit results leave the rest.
fn sr(i: u8, w: u8, v: u64) {
    if w == 64 { reg[i] = v; }
    else if w == 32 { reg[i] = v & 0xFFFFFFFF; }
    else if w == 16 { reg[i] = reg[i] & 0xFFFFFFFFFFFF0000 | v & 0xFFFF; }
    else if ins.rex == 0 && i >= 4 && i < 8 { reg[i - 4] = reg[i - 4] & 0xFFFFFFFFFFFF00FF | (v & 0xFF) << 8; }
    else { reg[i] = reg[i] & 0xFFFFFFFFFFFFFF00 | v & 0xFF; }
}

// ---- The ModRM byte ----

// Reads the ModRM byte and what belongs to it. after is how many bytes of the instruction
// come after the operand (a constant): an address relative to RIP is relative to the end of
// the whole instruction.
fn modrm(after: u64) {
    if ins.mlen != 0 {
        // Remembered: the fields are there, and the address is made from the registers as
        // they are now.
        ip = rip + ins.mlen;
        if ins.mod == 3 { return; }
        var a = ins.disp;
        if ins.base < 16 { a += reg[ins.base]; } else if ins.base == 17 { a += ip + after; }
        if ins.index < 16 { a += reg[ins.index] << ins.scale; }
        if ins.asz32 { a &= 0xFFFFFFFF; }
        m_off = a;
        m_ea = a + seg_base();
        return;
    }
    let b = fb() as! u8;
    ins.mod = b >> 6;
    ins.reg = b >> 3 & 7 | (ins.rex & 4) << 1;
    ins.rm = b & 7;
    var a: u64 = 0;
    var base: u64 = 16;
    var index: u64 = 16;
    var scale: u64 = 0;
    var disp: u64 = 0;
    if ins.mod == 3 { ins.rm |= (ins.rex & 1) << 3; }
    else {
        if ins.rm == 4 {
            let s = fb() as! u8;
            let i = s >> 3 & 7 | (ins.rex & 2) << 2;
            scale = s >> 6;
            if i != 4 { index = i; a = reg[i] << scale; }
            if s & 7 == 5 && ins.mod == 0 { disp = fs32(); }
            else { base = s & 7 | (ins.rex & 1) << 3; a += reg[base]; }
        } else if ins.rm == 5 && ins.mod == 0 {
            disp = fs32();
            base = 17;
            a = ip + after;
        } else {
            base = ins.rm | (ins.rex & 1) << 3;
            a = reg[base];
        }
        if ins.mod == 1 { let d = fs8(); disp += d; } else if ins.mod == 2 { let d = fs32(); disp += d; }
        a += disp;
        if ins.asz32 { a &= 0xFFFFFFFF; }
        m_off = a;
        m_ea = a + seg_base();
    }
    // Remembered for the next time, if all of it lies on the page.
    if dc_cur >= 0 && ip <= code_end && ip - rip <= 15 {
        ins.base = base as! u8;
        ins.index = index as! u8;
        ins.scale = scale as! u8;
        ins.disp = disp;
        ins.mlen = (ip - rip) as! u8;
        dc[dc_cur].ins = ins;
    }
}

fn rm_get(w: u8) -> u64 {
    if ins.mod == 3 { return gr(ins.rm, w); }
    return rd(m_ea, w);
}

fn rm_set(w: u8, v: u64) {
    if ins.mod == 3 { sr(ins.rm, w, v); } else { wr(m_ea, w, v); }
}

// ---- Arithmetic and flags ----

let PARITY: u8[256] = [
    4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4, 0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
    0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0, 4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
    0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0, 4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
    4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4, 0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
    0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0, 4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
    4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4, 0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
    4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4, 0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
    0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0, 4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
];

// The zero, sign and parity bits for a result, as they sit in RFLAGS.
inline fn szp(r: u64, w: u8) -> u64 {
    var f: u64 = PARITY[r & 0xFF];
    if r & mask(w) == 0 { f |= ZF; }
    if r & msb(w) != 0 { f |= SF; }
    return f;
}

inline fn flag(m: u64) -> bool { return rflags & m != 0; }

inline fn set_flag(m: u64, on: bool) {
    if on { rflags |= m; } else { rflags &= ~m; }
}

// op is the 3-bit field from the instruction: 0 ADD 1 OR 2 ADC 3 SBB 4 AND 5 SUB 6 XOR 7 CMP
fn alu(op: u8, a0: u64, b0: u64, w: u8) -> u64 {
    let m = mask(w);
    let s = msb(w);
    let a = a0 & m;
    let b = b0 & m;
    var r: u64 = 0;
    var f: u64 = 0;
    match op {
        0, 2 => {
            let c: u64 = if op == 2 && flag(CF) { 1 } else { 0 };
            r = (a + b + c) & m;
            // The carry out of the top bit: both operands had it, or one had it and the
            // result has lost it.
            if (a & b | (a | b) & ~r) & s != 0 { f |= CF; }
            if (a ^ r) & (b ^ r) & s != 0 { f |= OF; }
            f |= (a ^ b ^ r) & AF;
        },
        3, 5, 7 => {
            let c: u64 = if op == 3 && flag(CF) { 1 } else { 0 };
            r = (a - b - c) & m;
            if (~a & b | (~a | b) & r) & s != 0 { f |= CF; }
            if (a ^ b) & (a ^ r) & s != 0 { f |= OF; }
            f |= (a ^ b ^ r) & AF;
        },
        _ => {
            if op == 1 { r = a | b; } else if op == 4 { r = a & b; } else { r = a ^ b; }
        },
    }
    rflags = rflags & ~ARITH | f | szp(r, w);
    return r;
}

// INC and DEC leave CF alone.
fn incdec(dec: bool, a: u64, w: u8) -> u64 {
    let carry = rflags & CF;
    let r = alu(if dec { 5 } else { 0 }, a, 1, w);
    rflags = rflags & ~CF | carry;
    return r;
}

// kind: 0 ROL 1 ROR 2 RCL 3 RCR 4 SHL 5 SHR 6 SAL 7 SAR
// The count uses its low 6 bits for a 64-bit operand and its low 5 for any other.
//
// The manual defines OF for a count of one only. The CPU these flags are taken from sets it,
// at every count, to what a count of one would have given for the same operand; so OF here
// is worked out from the operand and not from the result. The one exception is ROL and ROR of
// a register by a constant larger than one (quiet is true for that form), which leave OF as
// it was. AF is cleared by the shifts and left alone by the rotates.
fn shift(kind: u8, v0: u64, count: u64, w: u8, quiet: bool) -> u64 {
    let m = mask(w);
    let s = msb(w);
    let bits: u64 = w;
    var n = count & (if w == 64 { 0x3F } else { 0x1F });
    if n == 0 { return v0 & m; }
    let v = v0 & m;
    let top = v & s != 0;
    let second = v & s >> 1 != 0;
    var r = v;
    var cf = flag(CF);
    match kind {
        0 => {
            let k = n % bits;
            if k != 0 { r = (v << k | v >> (bits - k)) & m; }
            cf = r & 1 != 0;
            if n == 1 || !quiet { set_flag(OF, top != second); }
        },
        1 => {
            let k = n % bits;
            if k != 0 { r = (v >> k | v << (bits - k)) & m; }
            cf = r & s != 0;
            if n == 1 || !quiet { set_flag(OF, top != (v & 1 != 0)); }
        },
        2, 3 => {
            // Through the carry: one bit at a time, of a count taken modulo the width and
            // one. A whole turn changes nothing, the flags included.
            n = n % (bits + 1);
            if n == 0 { return v; }
            set_flag(OF, top != (if kind == 2 { second } else { cf }));
            for i in n {
                if kind == 2 {
                    let out = r & s != 0;
                    r = (r << 1 | (if cf { 1 } else { 0 })) & m;
                    cf = out;
                } else {
                    let out = r & 1 != 0;
                    r = r >> 1 | (if cf { s } else { 0 });
                    cf = out;
                }
            }
        },
        5 => {
            if n > bits { cf = false; r = 0; }
            else {
                cf = v >> (n - 1) & 1 != 0;
                r = if n == bits { 0 } else { v >> n };
            }
            set_flag(OF, top);
        },
        7 => {
            if n >= bits { cf = top; r = if top { m } else { 0 }; }
            else {
                cf = v >> (n - 1) & 1 != 0;
                r = v >> n;
                if top { r |= m << (bits - n) & m; }
            }
            set_flag(OF, false);
        },
        _ => {
            if n > bits { cf = false; r = 0; }
            else {
                cf = v >> (bits - n) & 1 != 0;
                r = if n == bits { 0 } else { v << n & m };
            }
            set_flag(OF, top != second);
        },
    }
    set_flag(CF, cf);
    if kind >= 4 { rflags = rflags & ~(ZF | SF | PF | AF) | szp(r, w); }
    return r;
}

// SHLD (left) and SHRD: shifts dst by count bits, filling from src. OF as for the shifts:
// what a count of one would give. With a 16-bit operand and a count over 16 the bits that
// come in after src's are dst's own again.
fn shift_double(left: bool, dst0: u64, src0: u64, count: u64, w: u8) -> u64 {
    let m = mask(w);
    let s = msb(w);
    let n = count & (if w == 64 { 0x3F } else { 0x1F });
    if n == 0 { return dst0 & m; }
    var dst = dst0 & m;
    var src = src0 & m;
    let top = dst & s != 0;
    if left { set_flag(OF, top != (dst & s >> 1 != 0)); }
    else { set_flag(OF, top != (src & 1 != 0)); }
    var cf = false;
    for i in n {
        if left {
            cf = dst & s != 0;
            dst = (dst << 1 | (if src & s != 0 { 1 } else { 0 })) & m;
            src = (src << 1 | (if cf { 1 } else { 0 })) & m;
        } else {
            cf = dst & 1 != 0;
            dst = dst >> 1 | (if src & 1 != 0 { s } else { 0 });
            src = src >> 1 | (if cf { s } else { 0 });
        }
    }
    set_flag(CF, cf);
    rflags = rflags & ~(ZF | SF | PF | AF) | szp(dst, w);
    return dst;
}

// (mul64, the 128-bit product of two 64-bit numbers, upper half then lower, is fpu.goose's.)

// The same for signed numbers.
fn imul64(a: u64, b: u64) -> u64, u64 {
    var hi, lo = mul64(a, b);
    if a >> 63 != 0 { hi -= b; }
    if b >> 63 != 0 { hi -= a; }
    return hi, lo;
}

// The flags after a multiplication: CF and OF say that the upper half holds something, and
// the rest are the lower half's.
fn mul_flags(over: bool, lo: u64, w: u8) {
    rflags = rflags & ~ARITH | (if over { CF | OF } else { 0 }) | szp(lo, w) & (SF | PF);
}

// A signed multiplication of two operands w bits wide, where only the lower half is kept.
fn imul2(a: u64, b: u64, w: u8) -> u64 {
    var r: u64 = 0;
    var over = false;
    if w == 64 {
        let hi, lo = imul64(a, b);
        r = lo;
        over = hi != ones(lo >> 63 != 0);
    } else {
        let full = sx(a, w) * sx(b, w);
        r = full & mask(w);
        over = sx(r, w) != full;
    }
    mul_flags(over, r, w);
    return r;
}

// hi:lo divided by d, all unsigned, when the quotient fits in 64 bits (hi < d): the
// quotient and the remainder.
fn div128(hi: u64, lo: u64, d: u64) -> u64, u64 {
    // Nearly always the upper half is empty (E114), and it is one division.
    if hi == 0 {
        let q0 = lo / d;
        return q0, lo - q0 * d;
    }
    var r = hi;
    var q: u64 = 0;
    for i in 64 {
        let top = r >> 63;
        r = r << 1 | lo >> (63 - (i as! u64)) & 1;
        q = q << 1;
        if top != 0 || r >= d { r -= d; q |= 1; }
    }
    return q, r;
}

// MUL, IMUL, DIV and IDIV with one operand (F6h and F7h, fields 4 to 7).
fn muldiv(kind: u8, src: u64, w: u8) {
    let m = mask(w);
    if kind == 4 || kind == 5 {
        var hi: u64 = 0;
        var lo: u64 = 0;
        var over = false;
        if w == 64 {
            if kind == 4 { hi, lo = mul64(reg[RAX], src); over = hi != 0; }
            else {
                hi, lo = imul64(reg[RAX], src);
                over = hi != ones(lo >> 63 != 0);
            }
        } else {
            let a = reg[RAX] & m;
            let full = if kind == 4 { a * src } else { sx(a, w) * sx(src, w) };
            lo = full & m;
            hi = full >> w & m;
            over = if kind == 4 { hi != 0 } else { sx(lo, w) != full };
        }
        if w == 8 { sr(RAX, 16, hi << 8 | lo); }
        else { sr(RAX, w, lo); sr(RDX, w, hi); }
        mul_flags(over, lo, w);
        return;
    }
    if src == 0 { fault(0, false, 0); }
    var q: u64 = 0;
    var r: u64 = 0;
    // The dividend: AX for a byte, the D register and the A register together for the rest.
    var hi = if w == 8 { reg[RAX] >> 8 & 0xFF } else { reg[RDX] & m };
    var lo = reg[RAX] & m;
    if w != 64 {
        // It fits in 64 bits.
        let n = hi << w | lo;
        if kind == 6 {
            q = n / src;
            r = n - q * src;
            if q > m { fault(0, false, 0); }
        } else {
            let sn = sx(n, w * 2) as! i64;
            let sd = sx(src, w) as! i64;
            let sq = sn / sd;
            let rem = sn - sq * sd;
            let top = (msb(w)) as! i64;
            if sq >= top || sq < 0 - top { fault(0, false, 0); }
            q = (sq as! u64) & m;
            r = (rem as! u64) & m;
        }
    } else if kind == 6 {
        if hi >= src { fault(0, false, 0); }
        q, r = div128(hi, lo, src);
    } else {
        // Signed: divide the sizes, then put the signs on.
        let nneg = hi >> 63 != 0;
        let dneg = src >> 63 != 0;
        if nneg { lo = ~lo + 1; hi = ~hi + (if lo == 0 { 1 } else { 0 }); }
        let d = if dneg { ~src + 1 } else { src };
        if hi >= d { fault(0, false, 0); }
        q, r = div128(hi, lo, d);
        if nneg != dneg {
            if q > 0x8000000000000000 { fault(0, false, 0); }
            q = ~q + 1;
        } else if q > 0x7FFFFFFFFFFFFFFF { fault(0, false, 0); }
        if nneg { r = ~r + 1; }
    }
    if w == 8 { sr(RAX, 16, r << 8 | q & 0xFF); }
    else { sr(RAX, w, q); sr(RDX, w, r); }
}

// The sixteen conditions of Jcc, SETcc and CMOVcc.
fn cond(cc: u8) -> bool {
    var r = false;
    match cc >> 1 & 7 {
        0 => { r = flag(OF); },
        1 => { r = flag(CF); },
        2 => { r = flag(ZF); },
        3 => { r = flag(CF) || flag(ZF); },
        4 => { r = flag(SF); },
        5 => { r = flag(PF); },
        6 => { r = flag(SF) != flag(OF); },
        _ => { r = flag(ZF) || flag(SF) != flag(OF); },
    }
    return r != (cc & 1 != 0);
}

// ---- The stack ----

fn push(v: u64, w: u8) {
    let sp = reg[RSP] - w / 8;
    wr(sp, w, v);
    reg[RSP] = sp;
}

fn pop(w: u8) -> u64 {
    let v = rd(reg[RSP], w);
    reg[RSP] += w / 8;
    return v;
}

// The operand size of what uses the stack: 64 bits, or 16 with the prefix 66h.
inline fn ssz() -> u8 { return if ins.p66 { 16 } else { 64 }; }

// ---- The strings ----

// One repetition of a string instruction; with REP, RIP stays on the instruction until the
// count runs out, as on a CPU, where something may come in between two repetitions. Until
// the last one RF is set, as it is in what such an interruption saves; and the flags of a
// repeated CMPS or SCAS are not to be seen until the last one either: between two
// repetitions the CPU shows the flags the instruction began with.
// How far the run loop lets a string instruction go on by itself (E113): the instruction
// count before which nothing outside is due. 0 when every repetition is to be an
// instruction of its own to the run loop (a trace, a single step, something waiting).
var rep_until: u64 = 0;

// REP MOVS and REP STOS, as many repetitions in one call as the run loop allows (E113).
// To everything outside it is as if each had been an instruction: the count goes on by
// one for each, and the start saved for a fault is moved on, so that a fault in a later
// repetition finds the registers as the repetitions before it left them. False if there
// is no room for more than one, and the caller does one in the old way.
fn string_run(op: u8, w: u8, am: u64) -> bool {
    var k = reg[RCX] & am;
    if rep_until <= steps + 1 { return false; }
    if rep_until - steps < k { k = rep_until - steps; }
    let n: u64 = w / 8;
    let up = !flag(DF);
    let step = if up { n } else { 0 - n };
    let moves = op & 0xFE == 0xA4;
    let base = seg_base();
    let v = reg[RAX];
    var done: u64 = 0;
    while done < k {
        let di = reg[RDI] & am;
        let si = reg[RSI] & am;
        // A stretch that lies on one page at each end is moved in memory itself.
        var m: u64 = 0;
        if up { m = string_block(moves, di, si + base, n, k - done, v); }
        if m == 0 {
            if moves { wr(di, w, rd(si + base, w)); } else { wr(di, w, v); }
            m = 1;
        }
        if moves { reg[RSI] = (si + step * m) & am; }
        reg[RDI] = (di + step * m) & am;
        if ins.asz32 { reg[RCX] = (reg[RCX] - m) & am; } else { reg[RCX] -= m; }
        done += m;
        // That many more instructions done, as far as anything outside can tell.
        steps += m;
        if machine {
            saved_reg[RSI] = reg[RSI];
            saved_reg[RDI] = reg[RDI];
            saved_reg[RCX] = reg[RCX];
        }
    }
    // The last of them is the one the run loop counts.
    steps -= 1;
    return true;
}

// Moves, or fills, up to `most` elements of n bytes going up from di (and si), as far as
// both stay on the page they begin on: the pages are found once, and the bytes moved in
// memory. Gives how many it did; 0 if it is not a case for it (an element across a page's
// end, a page that is not plain memory or holds remembered code, a source that begins
// inside the element being written), and then nothing has been done. Finding a page can
// fault, as moving the first element would have.
fn string_block(moves: bool, di: u64, si: u64, n: u64, most: u64, v: u64) -> u64 {
    var m = (0x1000 - (di & 0xFFF)) / n;
    if moves {
        let ms = (0x1000 - (si & 0xFFF)) / n;
        if ms < m { m = ms; }
    }
    if most < m { m = most; }
    if m == 0 { return 0; }
    var pd = di;
    var ps = si;
    if machine {
        if moves { ps = xlate(si, 0); }
        pd = xlate(di, ACC_WRITE);
    }
    let bytes = m * n;
    if pd >= MEM_SIZE - 0x2000 || dc_mark[(pd >> 12) as! i64] != 0 { return 0; }
    let d = pd as! i64;
    if moves {
        if ps >= MEM_SIZE - 0x2000 { return 0; }
        // Going up a byte at a time is going up an element at a time, unless the source
        // begins less than an element below the destination.
        if pd > ps && pd - ps < n { return 0; }
        let f = ps as! i64;
        for i in bytes as! i64 { mem[d + i] = mem[f + i]; }
    } else if n == 1 {
        for i in bytes as! i64 { mem[d + i] = v as! u8; }
    } else {
        for j in m as! i64 { mem_put(d + j * (n as! i64), (n * 8) as! u8, v); }
    }
    return m;
}

fn string_op(op: u8) -> u64 {
    let w: u8 = if op & 1 == 0 { 8 } else { ins.osz };
    let n: u64 = w / 8;
    let am: u64 = if ins.asz32 { 0xFFFFFFFF } else { 0xFFFFFFFFFFFFFFFF };
    if ins.rep != 0 && reg[RCX] & am == 0 { return ip; }
    if ins.rep != 0 && (op & 0xFE == 0xA4 || op & 0xFE == 0xAA) && string_run(op, w, am) {
        if reg[RCX] & am == 0 { return ip; }
        rflags |= RF;
        return rip;
    }
    let began = rflags;
    let step = if flag(DF) { 0 - n } else { n };
    let si = reg[RSI] & am;
    let di = reg[RDI] & am;
    var uses_si = false;
    var uses_di = false;
    var compares = false;
    match op & 0xFE {
        0xA4 => { wr(di, w, rd(si + seg_base(), w)); uses_si = true; uses_di = true; },
        0xA6 => { let a = rd(si + seg_base(), w); let b = rd(di, w); alu(7, a, b, w); uses_si = true; uses_di = true; compares = true; },
        0xAA => { wr(di, w, reg[RAX]); uses_di = true; },
        0xAC => { sr(RAX, w, rd(si + seg_base(), w)); uses_si = true; },
        _ => { alu(7, reg[RAX], rd(di, w), w); uses_di = true; compares = true; },
    }
    if uses_si { if ins.asz32 { reg[RSI] = (si + step) & am; } else { reg[RSI] = si + step; } }
    if uses_di { if ins.asz32 { reg[RDI] = (di + step) & am; } else { reg[RDI] = di + step; } }
    if ins.rep == 0 { return ip; }
    let left = (reg[RCX] - 1) & am;
    if ins.asz32 { reg[RCX] = left; } else { reg[RCX] = left; }
    if left == 0 { return ip; }
    if compares && flag(ZF) != (ins.rep == 0xF3) { return ip; }
    rflags = began | RF;
    return rip;
}

// INS and OUTS: a string instruction between a port (DX) and memory, one repetition at a time
// like the others. The width is a byte, or 16 bits with the prefix 66h, or 32.
fn port_string(op: u8) -> u64 {
    io_level();
    let w: u8 = if op & 1 == 0 { 8 } else if ins.p66 { 16 } else { 32 };
    let n: u64 = w / 8;
    let am: u64 = if ins.asz32 { 0xFFFFFFFF } else { 0xFFFFFFFFFFFFFFFF };
    if ins.rep != 0 && reg[RCX] & am == 0 { return ip; }
    let step = if flag(DF) { 0 - n } else { n };
    let port = reg[RDX] & 0xFFFF;
    if op < 0x6E {
        // The page is asked for before the port is read: a fault must not lose what the
        // device gave.
        let di = reg[RDI] & am;
        if machine { xlate(di, ACC_WRITE); xlate(di + n - 1, ACC_WRITE); }
        wr(di, w, io_in(port, w));
        reg[RDI] = (di + step) & am;
    } else {
        let si = reg[RSI] & am;
        io_out(port, w, rd(si + seg_base(), w));
        reg[RSI] = (si + step) & am;
    }
    if ins.rep == 0 { return ip; }
    let left = (reg[RCX] - 1) & am;
    reg[RCX] = left;
    if left == 0 { return ip; }
    rflags |= RF;
    return rip;
}

// ---- Bits ----

fn bit_op(kind: u8, w: u8, off: u64, from_reg: bool) {
    let bits: u64 = w;
    var a = m_ea;
    if ins.mod != 3 && from_reg {
        // A register's bit number reaches outside the operand: it is a signed number of bits
        // from the operand's address.
        let o = sx(off, w);
        var words = o >> (if w == 16 { 4 } else if w == 32 { 5 } else { 6 });
        if o >> 63 != 0 { words |= 0xFFFFFFFFFFFFFFFF << (if w == 16 { 60 } else if w == 32 { 59 } else { 58 }); }
        a += words * (bits / 8);
    }
    let v = if ins.mod == 3 { gr(ins.rm, w) } else { rd(a, w) };
    let bit: u64 = 1 << (off & (bits - 1));
    set_flag(CF, v & bit != 0);
    var r = v;
    match kind {
        0 => { return; },
        1 => { r = v | bit; },
        2 => { r = v & ~bit; },
        _ => { r = v ^ bit; },
    }
    if ins.mod == 3 { sr(ins.rm, w, r); } else { wr(a, w, r); }
}

// The instructions that touch ports and the interrupt flag need IOPL to allow the current
// privilege level; a user-mode program has neither.
fn io_level() {
    if !machine { stop64("an instruction of a machine in a user-mode program, at privilege level", 3); }
    if cpl > (rflags >> 12 & 3) { fault(13, true, 0); }
}

// ---- CPUID ----

// --cpu-open: the CPU as it was until E156, an Ivy Bridge with no word about what it is
// open to, which a kernel takes as open to Meltdown and MDS and guards against.
var cpu_open = false;

fn cpuid() {
    let leaf = reg[RAX] & 0xFFFFFFFF;
    var a: u64 = 0;
    var b: u64 = 0;
    var c: u64 = 0;
    var d: u64 = 0;
    if leaf == 0 { a = if cpu_open { 1 } else { 7 }; b = 0x756E6547; d = 0x49656E69; c = 0x6C65746E; }      // "GenuineIntel"
    else if leaf == 1 { a = 0x000306A9; d = 0x07008111; c = 0x00800000; }        // FPU TSC CX8 CMOV FXSR SSE SSE2; POPCNT
    // Leaf 7 (E156): IA32_ARCH_CAPABILITIES is there, which says what this CPU is not
    // open to (sys64.goose, MSR 10Ah). Leaves 2 to 6 are nothing.
    else if leaf == 7 && !cpu_open && reg[RCX] & 0xFFFFFFFF == 0 { d = 0x20000000; }
    else if leaf == 0x80000000 { a = 0x80000001; }
    else if leaf == 0x80000001 { d = 0x20000800; c = 1; }                        // long mode, SYSCALL; LAHF
    reg[RAX] = a; reg[RBX] = b; reg[RCX] = c; reg[RDX] = d;
}

// ---- One instruction ----

// The kinds of instruction the short front runs (E110). None of them changes a register
// before the last point it can fault at, so the front does not save the registers
// (start_saved, sys64.goose): a fault finds them as the instruction found them.
let K_ALU = 1;          // 00h to 3Bh with a ModRM byte
let K_GRP1 = 2;         // 80h, 81h, 83h
let K_TEST = 3;         // 84h, 85h
let K_MOV = 4;          // 88h to 8Bh
let K_LEA = 5;
let K_PUSH = 6;         // 50h to 57h
let K_POP = 7;          // 58h to 5Fh
let K_CALL = 8;         // E8h
let K_RET = 9;          // C3h
let K_JMP8 = 10;
let K_JMP32 = 11;
let K_MOVZX8 = 12;      // 0F B6h
let K_MOVZX16 = 13;     // 0F B7h
let K_JCC8 = 0x10;      // 70h to 7Fh
let K_JCC32 = 0x20;     // 0F 80h to 8Fh: with the condition in the low four bits
// The kinds that used to cut a run of the ones above short (E118).
let K_SHIFTI = 14;      // C0h, C1h: a shift or rotation by a constant
let K_SHIFT = 15;       // D0h to D3h: by one, or by CL
let K_GRP3 = 17;        // F6h, F7h: TEST, NOT, NEG, MUL, IMUL, DIV, IDIV
let K_GRP5 = 18;        // FEh, FFh: INC, DEC, and CALL, JMP and PUSH of an operand
let K_NOP = 19;         // 90h without REX.B
let K_NOPM = 20;        // 0F 18h to 1Fh: the hints, the long NOP, ENDBR64
let K_MOVSXD = 21;      // 63h
let K_MOVI = 22;        // B0h to BFh: a constant to a register
let K_MOVMI = 23;       // C6h, C7h: a constant to an operand
let K_ALUA = 24;        // 04h, 05h, 0Ch, ... 3Dh: the A register and a constant
let K_TESTA = 25;       // A8h, A9h
let K_IMUL2 = 26;       // 0F AFh
let K_IMUL3 = 27;       // 69h, 6Bh: IMUL by a constant
let K_MOVSX8 = 28;      // 0F BEh
let K_MOVSX16 = 29;     // 0F BFh
let K_CONV = 30;        // 98h, 99h: CBW, CWDE, CDQE and CWD, CDQ, CQO
let K_PUSHI = 31;       // 68h, 6Ah: PUSH of a constant
let K_CMOV = 0x30;      // 0F 40h to 4Fh: with the condition in the low four bits
let K_SETCC = 0x40;     // 0F 90h to 9Fh: with the condition in the low four bits

// The kind of the instruction whose prefixes and opcode have just been read. (F2h and F3h
// in front of these do nothing.)
fn kind_of(op: u8) -> u8 {
    if op == 0x0F {
        let op2 = peek8() as! u8;
        if op2 & 0xF0 == 0x80 { return K_JCC32 | op2 & 15; }
        if op2 == 0xB6 { return K_MOVZX8; }
        if op2 == 0xB7 { return K_MOVZX16; }
        if op2 & 0xF0 == 0x40 { return K_CMOV | op2 & 15; }
        if op2 & 0xF0 == 0x90 { return K_SETCC | op2 & 15; }
        if op2 == 0xAF { return K_IMUL2; }
        if op2 == 0xBE { return K_MOVSX8; }
        if op2 == 0xBF { return K_MOVSX16; }
        if op2 >= 0x18 && op2 < 0x20 { return K_NOPM; }
        return 0;
    }
    if op < 0x40 { return if op & 7 < 4 { K_ALU } else if op & 7 < 6 { K_ALUA } else { 0 }; }
    if op >= 0x50 && op < 0x58 { return K_PUSH; }
    if op >= 0x58 && op < 0x60 { return K_POP; }
    if op >= 0x70 && op < 0x80 { return K_JCC8; }
    if op == 0x80 || op == 0x81 || op == 0x83 { return K_GRP1; }
    if op == 0x84 || op == 0x85 { return K_TEST; }
    if op >= 0x88 && op < 0x8C { return K_MOV; }
    if op == 0x8D { return K_LEA; }
    if op == 0x63 { return K_MOVSXD; }
    if op == 0x68 || op == 0x6A { return K_PUSHI; }
    if op == 0x69 || op == 0x6B { return K_IMUL3; }
    if op == 0x98 || op == 0x99 { return K_CONV; }
    if op == 0x90 { return if ins.rex & 1 == 0 { K_NOP } else { 0 }; }
    if op == 0xA8 || op == 0xA9 { return K_TESTA; }
    if op >= 0xB0 && op < 0xC0 { return K_MOVI; }
    if op == 0xC0 || op == 0xC1 { return K_SHIFTI; }
    if op == 0xC6 || op == 0xC7 { return K_MOVMI; }
    if op >= 0xD0 && op < 0xD4 { return K_SHIFT; }
    if op == 0xF6 || op == 0xF7 { return K_GRP3; }
    if op == 0xFE || op == 0xFF { return K_GRP5; }
    if op == 0xC3 { return K_RET; }
    if op == 0xE8 { return K_CALL; }
    if op == 0xE9 { return K_JMP32; }
    if op == 0xEB { return K_JMP8; }
    return 0;
}

// Runs the instruction at RIP. False if the run stopped in it.
//
// The short front: an instruction found in the decode cache with a kind is run here. All
// else goes to exec64_rest, which is the whole CPU.
fn exec64() -> bool {
    if machine {
        delivered = false;
        if pending >= 0 { save_start(); deliver_pending(); return true; }
        start_saved = false;
        saved_flags = rflags;
    }
    if rip >> 12 != code_page || cpl != code_cpl { code_fill(); }
    ip = rip;
    // The decode cache: found by the instruction's physical address. Where there is no code
    // page, code_fill has left a delta that gives an address no entry has.
    let ph = rip - code_delta;
    var slot = dc_slot(ph);
    if dc[slot].tag != ph {
        // The set's other way (E142); or, for the new entry, the way that is given up
        // (E152): an empty one, else one whose instruction is inside a block (the block
        // is made, and the entry of little more use), else the one with fewer arrivals;
        // a block's first instruction only when both ways hold one.
        slot ^= 1;
        if dc[slot].tag != ph {
            slot ^= 1;
            if dc_n[slot] != 0 { slot ^= 1; }
            dc_cur = slot;
            if jit_why { ji[0] += 1; }
            return exec64_miss();
        }
    }
    dc_cur = slot;
    if jit_why { jit_ran_one(slot, ph); }
    // An instruction run from the cache and no block's first is an arrival (E137): at
    // the J_HOT-th a block is made there, and run at once.
    ins = dc[slot].ins;
    if jit_on {
        let made = dc_n[slot] == 0 && jit_arrive(slot, ph);
        jit_land = jit_resume;
        jit_resume = false;
        if made { return exec64_rest(); }
    }
    if ins.kind == 0 { return exec64_rest(); }
    return run_kind();
}

// An instruction that was not in the decode cache: decoded, and run as any other.
fn exec64_miss() -> bool {
    decode();
    if ins.kind == 0 { return exec64_rest(); }
    return run_kind();
}

// A jump has gone somewhere. (Until E137 the arrival was counted here; now every
// instruction the interpreter runs from the decode cache is one, in exec64.)
inline fn went() -> bool {
    jit_land = true;
    return true;
}

// The short front's arms. Every instruction of these kinds is run here, met for the first
// time or not: exec64_rest has no arms for them.
inline fn run_kind() -> bool {
    let op = ins.op;
    let w: u8 = if op & 1 == 0 { 8 } else { ins.osz };
    ip = rip + ins.plen;
    rflags &= ~RF;
    match ins.kind {
        K_ALU => {
            modrm(0);
            let k = op >> 3;
            if op & 2 == 0 {
                let r = alu(k, rm_get(w), gr(ins.reg, w), w);
                if k != 7 { rm_set(w, r); }
            } else {
                let r = alu(k, gr(ins.reg, w), rm_get(w), w);
                if k != 7 { sr(ins.reg, w, r); }
            }
        },
        K_GRP1 => {
            modrm(if op == 0x81 { imm_len(ins.osz) } else { 1 });
            let b = if op == 0x81 { fimm(ins.osz) } else { fs8() };
            let r = alu(ins.reg & 7, rm_get(w), b, w);
            if ins.reg & 7 != 7 { rm_set(w, r); }
        },
        K_TEST => { modrm(0); alu(4, rm_get(w), gr(ins.reg, w), w); },
        K_MOV => {
            modrm(0);
            if op & 2 == 0 { rm_set(w, gr(ins.reg, w)); } else { sr(ins.reg, w, rm_get(w)); }
        },
        K_LEA => {
            modrm(0);
            if ins.mod == 3 { stop64("LEA of a register,", op); }
            sr(ins.reg, ins.osz, m_off);
        },
        K_PUSH => { let low: u8 = op & 7 | (ins.rex & 1) << 3; push(gr(low, ssz()), ssz()); },
        K_POP => { let low: u8 = op & 7 | (ins.rex & 1) << 3; let v = pop(ssz()); sr(low, ssz(), v); },
        K_CALL => { let d = fs32(); push(ip, 64); rip = ip + d; return went(); },
        K_RET => { rip = pop(64); return went(); },
        K_JMP8 => { let d = fs8(); rip = ip + d; return went(); },
        K_JMP32 => { let d = fs32(); rip = ip + d; return went(); },
        K_MOVZX8 => { ip += 1; modrm(0); sr(ins.reg, ins.osz, rm_get(8)); },
        K_MOVZX16 => { ip += 1; modrm(0); sr(ins.reg, ins.osz, rm_get(16)); },
        K_SHIFTI => {
            modrm(1);
            let n = fb();
            rm_set(w, shift(ins.reg & 7, rm_get(w), n, w, ins.mod == 3));
        },
        K_SHIFT => {
            modrm(0);
            let n: u64 = if op < 0xD2 { 1 } else { reg[RCX] & 0xFF };
            rm_set(w, shift(ins.reg & 7, rm_get(w), n, w, false));
        },
        K_GRP3 => {
            // Peek at the field: TEST has a constant behind the operand. MUL and DIV
            // change RAX and RDX after the last fault they can raise.
            let field = (peek8() as! u8) >> 3 & 7;
            modrm(if field < 2 { imm_len(w) } else { 0 });
            match field {
                0, 1 => { let b = fimm(w); alu(4, rm_get(w), b, w); },
                2 => { rm_set(w, ~rm_get(w)); },
                3 => { rm_set(w, alu(5, 0, rm_get(w), w)); },
                _ => { muldiv(field, rm_get(w), w); },
            }
        },
        K_GRP5 => {
            modrm(0);
            match ins.reg & 7 {
                0 => { rm_set(w, incdec(false, rm_get(w), w)); },
                1 => { rm_set(w, incdec(true, rm_get(w), w)); },
                2 => { if op == 0xFE { stop64("an instruction not written yet, FE field", 2); } let to = rm_get(64); push(ip, 64); rip = to; return went(); },
                4 => { if op == 0xFE { stop64("an instruction not written yet, FE field", 4); } rip = rm_get(64); return went(); },
                6 => { if op == 0xFE { stop64("an instruction not written yet, FE field", 6); } push(rm_get(ssz()), ssz()); },
                _ => { stop64("an instruction not written yet, FF field", ins.reg); },
            }
        },
        K_NOP => {},
        K_NOPM => { ip += 1; modrm(0); },
        K_MOVSXD => {
            modrm(0);
            let v = rm_get(32);
            sr(ins.reg, ins.osz, if ins.osz == 64 { sx(v, 32) } else { v });
        },
        K_MOVI => {
            let low: u8 = op & 7 | (ins.rex & 1) << 3;
            if op < 0xB8 { let v = fb(); sr(low, 8, v); }
            else if ins.osz == 64 { reg[low] = fq(); }
            else if ins.osz == 32 { reg[low] = fd(); }
            else { let v = fw(); sr(low, 16, v); }
        },
        K_MOVMI => {
            modrm(imm_len(w));
            if ins.reg & 7 != 0 { stop64("an instruction not written yet, C6 or C7 field", ins.reg); }
            let v = fimm(w);
            rm_set(w, v);
        },
        K_ALUA => {
            let k = op >> 3;
            let r = alu(k, gr(RAX, w), fimm(w), w);
            if k != 7 { sr(RAX, w, r); }
        },
        K_TESTA => { alu(4, gr(RAX, w), fimm(w), w); },
        K_IMUL2 => { ip += 1; modrm(0); sr(ins.reg, ins.osz, imul2(gr(ins.reg, ins.osz), rm_get(ins.osz), ins.osz)); },
        K_IMUL3 => {
            modrm(if op == 0x69 { imm_len(ins.osz) } else { 1 });
            let b = if op == 0x69 { fimm(ins.osz) } else { fs8() };
            sr(ins.reg, ins.osz, imul2(rm_get(ins.osz), b, ins.osz));
        },
        K_MOVSX8 => { ip += 1; modrm(0); sr(ins.reg, ins.osz, sx(rm_get(8), 8)); },
        K_MOVSX16 => { ip += 1; modrm(0); sr(ins.reg, ins.osz, sx(rm_get(16), 16)); },
        K_CONV => {
            if op == 0x99 { sr(RDX, ins.osz, ones(reg[RAX] & msb(ins.osz) != 0)); }
            else if ins.osz == 16 { sr(RAX, 16, sx(reg[RAX], 8)); }
            else if ins.osz == 32 { sr(RAX, 32, sx(reg[RAX], 16)); }
            else { reg[RAX] = sx(reg[RAX], 32); }
        },
        K_PUSHI => {
            let v = if op == 0x6A { fs8() } else { fimm(if ins.p66 { 16 } else { 32 }) };
            push(v, ssz());
        },
        _ => {
            if ins.kind >= K_SETCC {
                ip += 1;
                modrm(0);
                rm_set(8, if cond(ins.kind & 15) { 1 } else { 0 });
            } else if ins.kind >= K_CMOV {
                ip += 1;
                modrm(0);
                let v = rm_get(ins.osz);
                // With a 32-bit operand the upper half is cleared whether it moves or not.
                if cond(ins.kind & 15) { sr(ins.reg, ins.osz, v); } else if ins.osz == 32 { sr(ins.reg, 32, gr(ins.reg, 32)); }
            } else if ins.kind & K_JCC32 != 0 {
                ip += 1;
                let d = fs32();
                if cond(ins.kind & 15) { rip = ip + d; return went(); }
            } else {
                let d = fs8();
                if cond(op & 15) { rip = ip + d; return went(); }
            }
        },
    }
    rip = ip;
    return true;
}

// Reads the prefixes and the opcode into `ins`, with the instruction's kind, and remembers
// them if it may.
fn decode() {
    var op: u8 = 0;
    if !dc_on { dc_cur = -1; }
    ins.rex = 0;
    ins.rep = 0;
    ins.p66 = false;
    ins.asz32 = false;
    ins.sg = 0;
    while true {
        op = fb() as! u8;
        if op & 0xF0 == 0x40 { ins.rex = op; continue; }
        match op {
            0x66 => { ins.p66 = true; },
            0x67 => { ins.asz32 = true; },
            0xF2, 0xF3 => { ins.rep = op; },
            0xF0, 0x26, 0x2E, 0x36, 0x3E => {},
            0x64 => { ins.sg = 1; },
            0x65 => { ins.sg = 2; },
            _ => { break; },
        }
        // A REX prefix counts only when it is the last prefix.
        ins.rex = 0;
    }
    ins.op = op;
    ins.osz = if ins.rex & 8 != 0 { 64 } else if ins.p66 { 16 } else { 32 };
    ins.plen = (ip - rip) as! u8;
    ins.mlen = 0;
    ins.kind = kind_of(op);
    if dc_cur >= 0 {
        // Remembered, if the prefixes and the opcode lie on the page and the page has
        // not been given up.
        let ph = rip - code_delta;
        let page = (ph >> 12) as! i64;
        if ip <= code_end && ip - rip <= 15 && dc_mark[page] != 2 {
            dc[dc_cur].tag = ph;
            dc[dc_cur].ins = ins;
            dc_heat[dc_cur] = 0;
            dc_cov[dc_cur] = 0;
            // A block whose first instruction's entry is taken by another instruction
            // dies with it (E141 counts how often).
            if dc_n[dc_cur] != 0 { j_evicted += 1; }
            dc_n[dc_cur] = 0;
            // (A page that comes to hold remembered instructions leaves the TLB's tables
            // for writes, E150: a block's store there is not checked any more.)
            if machine && dc_mark[page] == 0 { tlb_unwrite(page); }
            dc_mark[page] = 1;
        } else {
            dc_cur = -1;
            // A page given up is taken back when it has been run from DC_CALM times with
            // no write to it in between (E134): a kernel patches its code as it starts,
            // often enough to be given up, and then runs it for good.
            if ip <= code_end && dc_mark[page] == 2 {
                dc_calm[page] += 1;
                if dc_calm[page] >= DC_CALM { dc_mark[page] = 0; dc_drops[page] = 0; dc_calm[page] = 0; }
            }
        }
    }
}

// The rest of the CPU: every instruction the front has no kind for. `ins` holds its
// prefixes and opcode.
fn exec64_rest() -> bool {
    // The first instruction of a translated block (jit64.goose) is kept without a kind, so
    // that it comes here and the front's path has nothing of the JIT in it: the block is
    // run, or the instruction as its own kind.
    if dc_cur >= 0 && dc_n[dc_cur] != 0 {
        rflags &= ~RF;
        if jit_enter() { return true; }
        // (A block may begin at an instruction of no kind, an SSE one: that goes on below.)
        if dc_k0[dc_cur] != 0 {
            ins.kind = dc_k0[dc_cur];
            return run_kind();
        }
    }
    if machine { save_start(); }
    let op = ins.op;
    ip = rip + ins.plen;
    let w: u8 = if op & 1 == 0 { 8 } else { ins.osz };
    let low: u8 = op & 7 | (ins.rex & 1) << 3;         // the register in the opcode's low bits
    var next: u64 = 0;                             // where to go, when not to the next instruction
    var jump = false;
    rflags &= ~RF;

    // (Arms that are not here are the short front's: run_kind.)
    if op == 0x0F {
        let op2 = fb() as! u8;
        let w2: u8 = if op2 & 1 == 0 { 8 } else { ins.osz };
        if sse64_is(op2) { sse64_op(op2); rip = ip; return true; }
        match op2 >> 4 {
            0x0 => {
                if op2 == 0x05 {
                    if machine { syscall_enter(ip); return true; }
                    reg[RCX] = ip;
                    reg[11] = rflags;
                    rip = ip;
                    syscall64();
                    return !stopped;
                } else if op2 == 0x0D { modrm(0); }
                else if op2 == 0x0B { fault(6, false, 0); }
                else if !machine { stop64("an instruction not written yet, 0F", op2); }
                else if op2 == 0x00 { sys_group6(); }
                else if op2 == 0x01 { sys_group7(); }
                else if op2 == 0x07 { sysret(); return true; }
                else if op2 == 0x06 { need_level0(); cr0 &= ~8; }                    // CLTS
                else if op2 == 0x08 || op2 == 0x09 { need_level0(); }                // INVD, WBINVD
                else { stop64("an instruction not written yet, 0F", op2); }
            },
            0x2 => {
                // MOV to and from the control registers (CR8 by REX.R) and the debug registers:
                // DR6 and DR7 keep what is written, the rest read as zero, and none does anything.
                if !machine { stop64("an instruction not written yet, 0F", op2); }
                need_level0();
                modrm(0);
                match op2 {
                    0x20 => { reg[ins.rm | (ins.rex & 1) << 3] = cr_get(ins.reg); },
                    0x22 => { cr_set(ins.reg, reg[ins.rm | (ins.rex & 1) << 3]); },
                    0x21 => { reg[ins.rm | (ins.rex & 1) << 3] = if ins.reg & 7 == 6 { dr6 } else if ins.reg & 7 == 7 { dr7 } else { 0 }; },
                    0x23 => { if ins.reg & 7 == 6 { dr6 = reg[ins.rm | (ins.rex & 1) << 3]; } else if ins.reg & 7 == 7 { dr7 = reg[ins.rm | (ins.rex & 1) << 3]; } },
                    _ => { stop64("an instruction not written yet, 0F", op2); },
                }
            },
            0x3 => {
                if op2 == 0x31 { reg[RAX] = steps & 0xFFFFFFFF; reg[RDX] = steps >> 32; }
                else if machine && op2 == 0x30 {
                    need_level0();
                    msr_set(reg[RCX] & 0xFFFFFFFF, reg[RAX] & 0xFFFFFFFF | reg[RDX] << 32);
                } else if machine && op2 == 0x32 {
                    need_level0();
                    let v = msr_get(reg[RCX] & 0xFFFFFFFF);
                    reg[RAX] = v & 0xFFFFFFFF;
                    reg[RDX] = v >> 32;
                }
                else { stop64("an instruction not written yet, 0F", op2); }
            },
            0xA => {
                match op2 {
                    0xA2 => { cpuid(); },
                    0xA0 => { push(seg[SEG_FS], ssz()); },
                    0xA8 => { push(seg[SEG_GS], ssz()); },
                    0xA1 => { let v = pop(ssz()); seg_load(SEG_FS, v); },
                    0xA9 => { let v = pop(ssz()); seg_load(SEG_GS, v); },
                    0xA3 => { modrm(0); bit_op(0, ins.osz, gr(ins.reg, ins.osz), true); },
                    0xAB => { modrm(0); bit_op(1, ins.osz, gr(ins.reg, ins.osz), true); },
                    0xA4, 0xAC => {
                        modrm(1);
                        let n = fb();
                        rm_set(ins.osz, shift_double(op2 == 0xA4, rm_get(ins.osz), gr(ins.reg, ins.osz), n, ins.osz));
                    },
                    0xA5, 0xAD => {
                        modrm(0);
                        rm_set(ins.osz, shift_double(op2 == 0xA5, rm_get(ins.osz), gr(ins.reg, ins.osz), reg[RCX] & 0xFF, ins.osz));
                    },
                    _ => { stop64("an instruction not written yet, 0F", op2); },
                }
            },
            0xB => {
                match op2 {
                    0xB0, 0xB1 => {
                        // CMPXCHG: the A register is compared with the operand; if they are
                        // equal the operand takes the register named, and if not, A takes it.
                        modrm(0);
                        let cur = rm_get(w2);
                        alu(7, gr(RAX, w2), cur, w2);
                        if flag(ZF) { rm_set(w2, gr(ins.reg, w2)); }
                        else { rm_set(w2, cur); sr(RAX, w2, cur); }
                    },
                    0xB3 => { modrm(0); bit_op(2, ins.osz, gr(ins.reg, ins.osz), true); },
                    0xBB => { modrm(0); bit_op(3, ins.osz, gr(ins.reg, ins.osz), true); },
                    0xBA => {
                        modrm(1);
                        let n = fb();
                        if ins.reg & 7 < 4 { stop64("an instruction not written yet, 0F BA field", ins.reg); }
                        bit_op(ins.reg & 3, ins.osz, n, false);
                    },
                    0xB8 => {
                        if ins.rep != 0xF3 { stop64("an instruction not written yet, 0F", op2); }
                        modrm(0);
                        var v = rm_get(ins.osz);
                        var n: u64 = 0;
                        while v != 0 { n += v & 1; v = v >> 1; }
                        sr(ins.reg, ins.osz, n);
                        rflags = rflags & ~ARITH | (if n == 0 { ZF } else { 0 });
                    },
                    0xBC, 0xBD => {
                        // BSF and BSR. Of a zero the register is left as it was, upper half
                        // and all. (F3h in front makes no difference on a CPU without TZCNT
                        // and LZCNT.)
                        modrm(0);
                        let v = rm_get(ins.osz);
                        if v == 0 {
                            rflags = rflags & ~ARITH | ZF | PF;
                        } else {
                            var n: u64 = 0;
                            if op2 == 0xBC { while v >> n & 1 == 0 { n += 1; } }
                            else { n = ins.osz - 1; while v >> n & 1 == 0 { n -= 1; } }
                            sr(ins.reg, ins.osz, n);
                            rflags = rflags & ~ARITH | PARITY[n];
                        }
                    },
                    _ => { stop64("an instruction not written yet, 0F", op2); },
                }
            },
            0xC => {
                if op2 >= 0xC8 {
                    let i = op2 & 7 | (ins.rex & 1) << 3;
                    let v = reg[i];
                    if ins.osz == 64 {
                        reg[i] = v >> 56 | (v >> 40 & 0xFF00) | (v >> 24 & 0xFF0000) | (v >> 8 & 0xFF000000)
                            | (v << 8 & 0xFF00000000) | (v << 24 & 0xFF0000000000) | (v << 40 & 0xFF000000000000) | v << 56;
                    } else {
                        reg[i] = (v >> 24 & 0xFF) | (v >> 8 & 0xFF00) | (v << 8 & 0xFF0000) | (v << 24 & 0xFF000000);
                    }
                } else if op2 == 0xC0 || op2 == 0xC1 {
                    modrm(0);
                    let a = rm_get(w2);
                    let b = gr(ins.reg, w2);
                    let r = alu(0, a, b, w2);
                    sr(ins.reg, w2, a);
                    rm_set(w2, r);
                } else if op2 == 0xC7 {
                    modrm(0);
                    if ins.reg & 7 != 1 || ins.mod == 3 { stop64("an instruction not written yet, 0F C7 field", ins.reg); }
                    // CMPXCHG8B and, with a 64-bit operand size, CMPXCHG16B.
                    let h: u8 = if ins.osz == 64 { 64 } else { 32 };
                    let lo = rd(m_ea, h);
                    let hi = rd(m_ea + h / 8, h);
                    if lo == gr(RAX, h) && hi == gr(RDX, h) {
                        wr(m_ea, h, reg[RBX]);
                        wr(m_ea + h / 8, h, reg[RCX]);
                        rflags |= ZF;
                    } else {
                        sr(RAX, h, lo);
                        sr(RDX, h, hi);
                        rflags &= ~ZF;
                    }
                } else { stop64("an instruction not written yet, 0F", op2); }
            },
            _ => { stop64("an instruction not written yet, 0F", op2); },
        }
    } else {
        match op >> 4 {
            0x6 => {
                match op {
                    0x6C, 0x6D, 0x6E, 0x6F => { next = port_string(op); jump = true; },
                    _ => { stop64("an instruction not written yet,", op); },
                }
            },
            0x8 => {
                match op {
                    0x86, 0x87 => {
                        modrm(0);
                        let a = rm_get(w);
                        let b = gr(ins.reg, w);
                        rm_set(w, b);
                        sr(ins.reg, w, a);
                    },
                    0x8C => {
                        // A segment register's selector: to a register at the operand size,
                        // to memory as 16 bits.
                        modrm(0);
                        if ins.reg & 7 > 5 { fault(6, false, 0); }
                        rm_set(if ins.mod == 3 { ins.osz } else { 16 }, seg[ins.reg & 7]);
                    },
                    0x8E => {
                        modrm(0);
                        if ins.reg & 7 > 5 || ins.reg & 7 == 1 { fault(6, false, 0); }
                        seg_load(ins.reg & 7, rm_get(16));
                    },
                    0x8F => {
                        // The operand's address is worked out with RSP already moved.
                        let v = pop(ssz());
                        modrm(0);
                        rm_set(ssz(), v);
                    },
                    _ => { stop64("an instruction not written yet,", op); },
                }
            },
            0x9 => {
                match op {
                    0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97 => {
                        // 90h alone is NOP (and PAUSE with F3h), which is the front's: this
                        // is XCHG with the A register.
                        let a = gr(RAX, ins.osz);
                        let b = gr(low, ins.osz);
                        sr(RAX, ins.osz, b);
                        sr(low, ins.osz, a);
                    },
                    0x9B => { if machine && cr0 & 0x0A == 0x0A { fault(7, false, 0); } },      // FWAIT
                    0x9C => { push(rflags & 0xFCFFFF, ssz()); },
                    0x9D => {
                        // IF and IOPL stay as they are unless the privilege level may change them.
                        let v = pop(ssz());
                        var can: u64 = if ins.p66 { 0x4DD5 } else { 0x244DD5 };
                        if machine && cpl == 0 { can |= 0x3200; }
                        else if machine && cpl <= (rflags >> 12 & 3) { can |= 0x200; }
                        rflags = rflags & ~can | v & can;
                    },
                    0x9E => { rflags = rflags & ~0xD5 | reg[RAX] >> 8 & 0xD5; },
                    0x9F => { reg[RAX] = reg[RAX] & 0xFFFFFFFFFFFF00FF | (rflags & 0xD5 | 2) << 8; },
                    _ => { stop64("an instruction not written yet,", op); },
                }
            },
            0xA => {
                if op < 0xA4 {
                    let a = (if ins.asz32 { fd() } else { fq() }) + seg_base();
                    if op < 0xA2 { sr(RAX, w, rd(a, w)); } else { wr(a, w, reg[RAX]); }
                } else {
                    next = string_op(op);
                    jump = true;
                }
            },
            0xC => {
                match op {
                    0xC2 => { let n = fw(); next = pop(64); reg[RSP] += n; jump = true; },
                    0xC9 => { reg[RSP] = reg[RBP]; let v = pop(ssz()); sr(RBP, ssz(), v); },
                    0xCA => { let n = fw(); far_ret(n); return true; },
                    0xCB => { far_ret(0); return true; },
                    0xCC => { if !machine { stop64("INT3 in a user-mode program,", op); } deliver(3, false, 0, ip, true); return true; },
                    0xCD => { let n = fb(); if !machine { stop64("INT in a user-mode program,", n); } deliver(n, false, 0, ip, true); return true; },
                    0xCF => { if !machine { stop64("IRET in a user-mode program,", op); } iret(); return true; },
                    _ => { stop64("an instruction not written yet,", op); },
                }
            },
            0xD => {
                if op >= 0xD8 {
                    // The x87 (fpu.goose). REX names no other register stack: the fields are
                    // 0 to 7. With EM or TS set in CR0 the unit is not available.
                    modrm(0);
                    m_mod = ins.mod;
                    m_reg = ins.reg & 7;
                    m_rm = ins.rm & 7;
                    if machine && cr0 & 0x0C != 0 { fault(7, false, 0); }
                    fpu_escape(op);
                } else { stop64("an instruction not written yet,", op); }
            },
            0xE => {
                match op {
                    0xE0, 0xE1, 0xE2 => {
                        let d = fs8();
                        var left = reg[RCX] - 1;
                        if ins.asz32 { left &= 0xFFFFFFFF; }
                        reg[RCX] = left;
                        if left != 0 && (op == 0xE2 || flag(ZF) == (op == 0xE1)) { next = ip + d; jump = true; }
                    },
                    0xE3 => {
                        let d = fs8();
                        if reg[RCX] & mask(if ins.asz32 { 32 } else { 64 }) == 0 { next = ip + d; jump = true; }
                    },
                    0xE4, 0xE5 => { let port = fb(); io_level(); sr(RAX, if op == 0xE4 { 8 } else if ins.p66 { 16 } else { 32 }, io_in(port, if op == 0xE4 { 8 } else if ins.p66 { 16 } else { 32 })); },
                    0xE6, 0xE7 => { let port = fb(); io_level(); io_out(port, if op == 0xE6 { 8 } else if ins.p66 { 16 } else { 32 }, reg[RAX]); },
                    0xEC, 0xED => { io_level(); sr(RAX, if op == 0xEC { 8 } else if ins.p66 { 16 } else { 32 }, io_in(reg[RDX] & 0xFFFF, if op == 0xEC { 8 } else if ins.p66 { 16 } else { 32 })); },
                    0xEE, 0xEF => { io_level(); io_out(reg[RDX] & 0xFFFF, if op == 0xEE { 8 } else if ins.p66 { 16 } else { 32 }, reg[RAX]); },
                    _ => { stop64("an instruction not written yet,", op); },
                }
            },
            0xF => {
                match op {
                    0xF4 => {
                        // HLT: asleep until an interrupt from outside (g64m.goose's between()).
                        io_level();
                        need_level0();
                        halted = true;
                        attn = true;
                    },
                    0xFA => { io_level(); rflags &= ~IF; },
                    0xFB => {
                        // STI: an interrupt is not taken until the instruction after this one
                        // is done, if IF was clear.
                        io_level();
                        if rflags & IF == 0 { sti_shadow = true; attn = true; }
                        rflags |= IF;
                    },
                    0xF5 => { rflags ^= CF; },
                    0xF8 => { rflags &= ~CF; },
                    0xF9 => { rflags |= CF; },
                    0xFC => { rflags &= ~DF; },
                    0xFD => { rflags |= DF; },
                    _ => { stop64("an instruction not written yet,", op); },
                }
            },
            _ => { stop64("an instruction not written yet,", op); },
        }
    }
    rip = if jump { next } else { ip };
    return true;
}
