// A JIT for the 64-bit CPU, for arm64 (E120). With --jit, runs of the short front's kinds
// (cpu64.goose) that touch no memory are translated into host code, block by block. The
// design is docs/jit64.md; this is its second task: no memory operands, no stack, no links
// between blocks yet. The C it needs is in jit.c.
//
// A block is instructions that follow one another in one physical page, found through the
// decode cache: its first instruction's entry loses its kind, which is kept in dc_k0, and
// has the block's length in dc_n; an instruction of no kind goes to the rest of the CPU,
// which looks there. The translator decodes nothing: it reads the entries, and the constants from
// memory.
//
// Host registers in generated code:
//   x0          the time left: how many instructions may still be run before control
//               goes back (each way out of a block takes off what the block ran)
//   x8..x17     RAX RCX RDX RBX RSP RBP RSI RDI R8 R9
//   x19..x24    R10 to R15              (x18 is the platform's)
//   x1..x4      scratch; x1 holds the next RIP on the way out
//   x5 x6 x7    the flags' record: the operands of the last instruction that set the flags
//               and what it was (the operation, and the width in bits above it); x7 is 0
//               while RFLAGS in memory is right
//   x25         RIP at the block's first instruction (a block is found by its physical
//               address, so the same code serves wherever the page is mapped)
//   x26         the address of jx: RFLAGS as the block found it, and what it gives back
//   x27         the address of the guest's memory (a program without a kernel: a guest
//               address is an index into it)
//   x28         the address of dc_mark: which pages hold remembered instructions
//   x29 x30     scratch for --jit-check's log of stores
//
// Generated code never faults and calls nothing. What it cannot do (an address outside
// memory, a store into a page that holds remembered instructions) leaves by a way out
// placed behind the block, before the instruction has changed anything: a block gives back
// how many instructions it ran, and the interpreter runs the next. The flags are not made in
// generated code at all: the record is settled afterwards by the interpreter's own
// functions (alu, shift, imul2), so they are right by construction where the record is.
// INC and DEC leave CF as it was, and are translated only as the first to set flags in
// their block: what they leave is then RFLAGS in memory. A shift by CL may be by zero,
// which changes no flag: the record is replaced only if the count is not zero.

import std;
import cpu64;
import sse64;
import sys64;

extern fn jit_alloc(size: i64) -> i64;
extern fn jit_write(at: i64, code: const u8[:]);
extern fn jit_addr_u64(a: const u64[:]) -> i64;
extern fn jit_addr8(a: const u8[:]) -> i64;
extern fn jit_addr32(a: const u32[:]) -> i64;
extern fn jit_addr_any(a: const Entry[:]) -> i64;
extern fn jit_peek64(at: i64) -> i64;
extern fn jit_call4(enter: i64, a: i64, b: i64, c: i64, d: i64) -> i64;

var jit_on = false;
var jit_check = false;       // --jit-check: every block is run both ways and compared
var jit_stats = false;       // --jit-stats: what the JIT did, on standard error at the end
var jit_hold = false;        // blocks are not entered (the check's second way)
var jit_no: u64 = 0;         // --jit-off: a bit for each group of kinds not to translate
var j_mem = 0;               // where the code is mapped
var j_used = 0;              // how much of it holds code
var j_keep = 0;              // how much of that is the way in and out
var j_out_at = 0;
var j_fark_at: i64[2] = [0; 2];      // the far way in a machine, for privilege levels 0 and 3; 0 if not built
var j_far_at = 0;            // the far way: to the block at the address in x1, if there is one; 0 if not built
var j_regs = 0;
var j_ctx = 0;
var j_blocks = 0;            // blocks translated
var j_entered: u64 = 0;      // times one was entered
var j_ran: u64 = 0;          // guest instructions executed in blocks
var j_flushes = 0;
let J_SIZE = 67108864;       // 64 MB
let J_HOT = 8;               // arrivals at a jump's target before it is translated
let J_MAX = 60;              // instructions in a block at most
let J_MIN = 2;               // and at least

// What a block is given and gives back: [0] RFLAGS in, [1] [2] [3] the flags' record,
// [4] the next RIP, [5] where the memory is, [6] where dc_mark is, [7] how many stores
// are in the log and [8] where the log is, [9] the time left, in and out, [10] where the
// guest's registers are, [11] the decode cache, [12] dc_n, [13] dc_code and [14] the
// mapping, for the far way, [15] whether the flags are stale (--jit-check), [16] where the
// XMM registers are, [17] and [18] the bases of FS and GS, [19] and [20] where the TLB's
// tags and its physical pages are (a machine's loads and stores).
var jx: u64[24] = [0; 24];
// --jit-check: each store's address and the eight bytes that were there.
var jlog: u64[256] = [0; 256];

var jc: u8[>..];             // the code being generated

// ---- The emitter ----

let S1 = 1; let S2 = 2; let S3 = 3; let S4 = 4;
let FA = 5; let FB = 6; let FK = 7;
let RIPB = 25; let CTX = 26; let MEMR = 27; let MARK = 28; let ZR = 31;

let A_ADD = 0x0B000000; let A_ADDS = 0x2B000000; let A_SUB = 0x4B000000; let A_SUBS = 0x6B000000;
let A_AND = 0x0A000000; let A_ORR = 0x2A000000; let A_EOR = 0x4A000000; let A_ANDS = 0x6A000000;

let C_EQ = 0; let C_NE = 1; let C_HS = 2; let C_LO = 3; let C_MI = 4; let C_PL = 5;
let C_VS = 6; let C_VC = 7; let C_HI = 8; let C_LS = 9; let C_GE = 10; let C_LT = 11;
let C_GT = 12; let C_LE = 13;
let C_NONE = 255;

fn e(w: u32) {
    jc.push(w as! u8);
    jc.push((w >> 8) as! u8);
    jc.push((w >> 16) as! u8);
    jc.push((w >> 24) as! u8);
}

fn e_at(at: i64, w: u32) {
    jc[at] = w as! u8;
    jc[at + 1] = (w >> 8) as! u8;
    jc[at + 2] = (w >> 16) as! u8;
    jc[at + 3] = (w >> 24) as! u8;
}

// A guest register's host register.
fn hg(i: u8) -> u32 { return if i < 10 { 8 + (i as u32) } else { 9 + (i as u32) }; }

// op rd, rn, rm; sf is 1 for 64 bits.
fn a_rrr(op: u32, sf: u32, rd: u32, rn: u32, rm: u32) { e(op | sf << 31 | rm << 16 | rn << 5 | rd); }
fn a_mov(sf: u32, rd: u32, rm: u32) { a_rrr(A_ORR, sf, rd, ZR, rm); }
// add or sub (0x11, 0x31, 0x51, 0x71 in the top byte) rd, rn, #v, v under 4096.
fn a_addi(op: u32, sf: u32, rd: u32, rn: u32, v: u32) { e(op << 24 | sf << 31 | v << 10 | rn << 5 | rd); }
// mov xd, #v
fn a_imm(rd: u32, v: u64) {
    e(0xD2800000 | ((v & 0xFFFF) as! u32) << 5 | rd);
    for h in 3 {
        let hw = (h as! u64) + 1;
        let part = (v >> (hw * 16) & 0xFFFF) as! u32;
        if part != 0 { e(0xF2800000 | (hw as! u32) << 21 | part << 5 | rd); }
    }
}
// which: 4 and 6 left, 5 right, 7 right with the sign; s from 1 to the width less one.
fn a_shifti(which: u8, sf: u32, rd: u32, rn: u32, s: u32) {
    let top: u32 = if sf == 1 { 63 } else { 31 };
    let base: u32 = if which == 7 { if sf == 1 { 0x93400000 } else { 0x13000000 } } else { if sf == 1 { 0xD3400000 } else { 0x53000000 } };
    if which == 5 || which == 7 { e(base | s << 16 | top << 10 | rn << 5 | rd); }
    else { e(base | ((top + 1 - s) & top) << 16 | (top - s) << 10 | rn << 5 | rd); }
}
fn a_shiftv(which: u8, sf: u32, rd: u32, rn: u32, rm: u32) {
    let op: u32 = if which == 5 { 0x1AC02400 } else if which == 7 { 0x1AC02800 } else { 0x1AC02000 };
    e(op | sf << 31 | rm << 16 | rn << 5 | rd);
}
// csel rd, rn, rm, cond: rn if cond.
fn a_csel(sf: u32, rd: u32, rn: u32, rm: u32, cond: u32) { e(0x1A800000 | sf << 31 | rm << 16 | cond << 12 | rn << 5 | rd); }
// ldr and str xt, [xn, #off]; ldp and stp x1, x2, [xn, #off]
fn a_ldr(rt: u32, rn: u32, off: u32) { e(0xF9400000 | (off >> 3) << 10 | rn << 5 | rt); }
fn a_str(rt: u32, rn: u32, off: u32) { e(0xF9000000 | (off >> 3) << 10 | rn << 5 | rt); }
fn a_ldp(r1: u32, r2: u32, rn: u32, off: u32) { e(0xA9400000 | (off >> 3) << 15 | r2 << 10 | rn << 5 | r1); }
fn a_stp(r1: u32, r2: u32, rn: u32, off: u32) { e(0xA9000000 | (off >> 3) << 15 | r2 << 10 | rn << 5 | r1); }

// Maps the room for code and writes the way in and the way out. False if there is none
// (a host that is not arm64).
fn jit64_init() -> bool {
    j_mem = jit_alloc(J_SIZE);
    if j_mem == 0 { return false; }
    j_regs = jit_addr_u64(reg[..]);
    j_ctx = jit_addr_u64(jx[..]);
    jx[5] = jit_addr8(mem[..]) as! u64;
    jx[6] = jit_addr8(dc_mark[..]) as! u64;
    jx[8] = jit_addr_u64(jlog[..]) as! u64;
    jx[10] = j_regs as! u64;
    jx[16] = jit_addr_u64(xmm[..]) as! u64;
    jx[19] = jit_addr_u64(tlb_tag[..]) as! u64;
    jx[20] = jit_addr_u64(tlb_phys[..]) as! u64;
    jc = [];
    // The way in: x0 the registers, x1 jx, x2 the block, x3 RIP.
    e(0xA9BA7BFD);                       // stp x29, x30, [sp, #-96]!
    a_stp(19, 20, 31, 16);
    a_stp(21, 22, 31, 32);
    a_stp(23, 24, 31, 48);
    a_stp(25, 26, 31, 64);
    a_stp(27, 28, 31, 80);
    a_mov(1, CTX, 1);
    a_ldr(MEMR, 1, 40);
    a_ldr(MARK, 1, 48);
    a_mov(1, RIPB, 3);
    for i in 8 { a_ldp(hg((i * 2) as! u8), hg((i * 2 + 1) as! u8), 0, (i as! u32) * 16); }
    a_imm(FK, 0);
    a_ldr(0, CTX, 72);
    e(0xD61F0040);                       // br x2
    // The way out: x1 the next RIP.
    j_out_at = jc.len;
    a_ldr(S3, CTX, 80);
    for i in 8 { a_stp(hg((i * 2) as! u8), hg((i * 2 + 1) as! u8), S3, (i as! u32) * 16); }
    a_str(0, CTX, 72);
    a_str(FA, CTX, 8);
    a_str(FB, CTX, 16);
    a_str(FK, CTX, 24);
    a_str(1, CTX, 32);
    a_ldp(27, 28, 31, 80);
    a_ldp(19, 20, 31, 16);
    a_ldp(21, 22, 31, 32);
    a_ldp(23, 24, 31, 48);
    a_ldp(25, 26, 31, 64);
    e(0xA8C67BFD);                       // ldp x29, x30, [sp], #96
    e(0xD65F03C0);                       // ret
    // The far way (E123): x1 an address that was not known when the block was translated
    // (a RET's, a jump's through an operand). The decode cache's entry for it is found as
    // dc_slot finds it; if it is that address's and a block begins there, into the block,
    // which checks the rest; if not, out. Only if the cache is laid out as this reads it:
    // an entry of 32 bytes with the tag first.
    let dc_at = jit_addr_any(dc[..]);
    let keep = dc[1].tag;
    dc[1].tag = 0x1122334455667788;
    let laid = jit_peek64(dc_at + 32) == 0x1122334455667788 && jit_peek64(dc_at) == (dc[0].tag as! i64);
    dc[1].tag = keep;
    if laid && DC_BITS == 18 {
        jx[11] = dc_at as! u64;
        jx[12] = jit_addr8(dc_n[..]) as! u64;
        jx[13] = jit_addr32(dc_code[..]) as! u64;
        jx[14] = j_mem as! u64;
        let out_back: u32 = (((j_out_at - jc.len) >> 2) as! u32) & 0x3FFFFFF;
        let to_out = jc.len;
        e(0x14000000 | out_back);                            // b the way out
        j_far_at = jc.len;
        e(0xCA404800 | S1 << 16 | S1 << 5 | S2);             // eor x2, x1, x1, lsr #18
        e(0x92404400 | S2 << 5 | S2);                        // and x2, x2, #0x3FFFF
        a_ldr(S3, CTX, 88);
        e(0x8B001400 | S2 << 16 | S3 << 5 | S3);             // add x3, x3, x2, lsl #5
        a_ldr(S3, S3, 0);
        a_rrr(A_SUBS, 1, ZR, S3, S1);                        // cmp x3, x1
        e(0x54000001 | ((((to_out - jc.len) >> 2) as! u32) & 0x7FFFF) << 5);     // b.ne out
        a_ldr(S3, CTX, 96);
        e(0x38606800 | S2 << 16 | S3 << 5 | S3);             // ldrb w3, [x3, x2]
        e(0x34000000 | ((((to_out - jc.len) >> 2) as! u32) & 0x7FFFF) << 5 | S3);    // cbz w3, out
        a_ldr(S3, CTX, 104);
        e(0xB8607800 | S2 << 16 | S3 << 5 | S3);             // ldr w3, [x3, x2, lsl #2]
        a_ldr(S4, CTX, 112);
        a_rrr(A_ADD, 1, S3, S4, S3);
        e(0xD61F0000 | S3 << 5);                             // br x3
        // The far way in a machine (E134), one for privilege level 0 and one for 3: the
        // address in x1 is a linear one. The TLB's entry for fetching instructions at
        // that level gives its page (a miss goes out, and the interpreter finds it);
        // then the look-up above by the physical address, and the block must be one
        // made at this level.
        jx[21] = jit_addr8(dc_cpl[..]) as! u64;
        for lv in 2 {
            let out2 = jc.len;
            e(0x14000000 | (((j_out_at - jc.len) >> 2) as! u32) & 0x3FFFFFF);
            j_fark_at[lv] = jc.len;
            a_shifti(5, 1, S2, S1, 12);
            e(0x92402C00 | S2 << 5 | S3);                    // and x3, x2, #0xFFF
            e(0x91400000 | ((4 + lv) as! u32) << 10 | S3 << 5 | S3);         // the table for fetches
            a_ldr(29, CTX, 152);
            e(0xF8607800 | S3 << 16 | 29 << 5 | 30);
            a_rrr(A_SUBS, 1, ZR, 30, S2);
            e(0x54000001 | ((((out2 - jc.len) >> 2) as! u32) & 0x7FFFF) << 5);
            a_ldr(29, CTX, 160);
            e(0xF8607800 | S3 << 16 | 29 << 5 | 30);
            e(0x92402C00 | S1 << 5 | S2);                    // and x2, x1, #0xFFF
            a_rrr(A_ORR, 1, S2, 30, S2);                     // the physical address
            e(0xCA404800 | S2 << 16 | S2 << 5 | S3);         // eor x3, x2, x2, lsr #18
            e(0x92404400 | S3 << 5 | S3);
            a_ldr(29, CTX, 88);
            e(0x8B001400 | S3 << 16 | 29 << 5 | 29);         // add x29, x29, x3, lsl #5
            a_ldr(29, 29, 0);
            a_rrr(A_SUBS, 1, ZR, 29, S2);
            e(0x54000001 | ((((out2 - jc.len) >> 2) as! u32) & 0x7FFFF) << 5);
            a_ldr(29, CTX, 96);
            e(0x38606800 | S3 << 16 | 29 << 5 | 29);         // ldrb w29, [x29, x3]: a block?
            e(0x34000000 | ((((out2 - jc.len) >> 2) as! u32) & 0x7FFFF) << 5 | 29);
            a_ldr(29, CTX, 168);
            e(0x38606800 | S3 << 16 | 29 << 5 | 29);         // its level
            e(0x7100001F | (if lv == 0 { 0 } else { 3 }) << 10 | 29 << 5);
            e(0x54000001 | ((((out2 - jc.len) >> 2) as! u32) & 0x7FFFF) << 5);
            a_ldr(29, CTX, 104);
            e(0xB8607800 | S3 << 16 | 29 << 5 | 29);         // ldr w29, [x29, x3, lsl #2]
            a_ldr(30, CTX, 112);
            a_rrr(A_ADD, 1, 29, 30, 29);
            e(0xD61F0000 | 29 << 5);
        }
    }
    jit_write(j_mem, jc[..]);
    j_keep = jc.len;
    j_used = j_keep;
    return true;
}

// ---- The translator ----

var je: Ins = Ins { op: 0, rex: 0, osz: 32, rep: 0, p66: false, asz32: false, sg: 0, plen: 0,
                    mlen: 0, mod: 0, reg: 0, rm: 0, base: 16, index: 16, scale: 0, kind: 0, disp: 0 };
var j_at: u64 = 0;           // where the instruction in je is
var jk: u8 = 0;              // its kind, its own where it begins a block
var j_hf: u8 = 0;            // what the host's flags are from: 0 nothing the guest can use
let HF_SUB = 1; let HF_ADD = 2; let HF_LOGIC = 3; let HF_INCDEC = 4;
let HF_FCMP = 5;             // the host's FCMP, for UCOMIS and COMIS
var j_set = false;           // an instruction of this block has set the flags' record
var j_dyn = false;           // and whether it did was decided as it ran (a shift by CL)
var j_end = false;           // the block ended at a jump
var j_stop = false;          // and nothing follows it (JMP, RET)
var j_off: u64 = 0;          // the instruction being translated: how far from the block's first,
var j_cnt: u64 = 0;          // how many are before it,
var j_ilen: u64 = 0;         // and how long it is
var j_head: u64 = 0;         // the block's first instruction's physical address
var j_dead = false;           // the instruction being translated sets flags no record is needed of
var j_nohost = false;         // and nothing reads them from the host's flags either
// The flags as the record has them are not the last flag-setting instruction's: it made no
// record, its flags being dead. --jit-check is told at each way out (jx[15]), and does not
// compare RFLAGS there.
var j_stale = false;
var j_needs = false;         // the block reads RFLAGS in memory, or builds on it (INC, DEC)
var jit_links: u64 = 0;      // exits made into branches to a block
var lk_n = 0;
// The exits of the block being translated that could be linked later: where, and to what.
let TP_MAX = 128;
var tp_n = 0;
var tp_pos: i64[TP_MAX] = [0; TP_MAX];
var tp_to: u64[TP_MAX] = [0; TP_MAX];
var jp: u8[>..];
// The block's branches back to its own first instruction, to be filled in.
let SS_MAX = 16;
var ss_n = 0;
var ss_pos: i64[SS_MAX] = [0; SS_MAX];
// A block begins with what an entry from another block needs (BODY_AT bytes), and the
// interpreter enters behind it.
let BODY_AT = 24;

// Makes the branch at `site` in the mapping go to `to`.
fn j_patch(site: i64, to: i64) {
    let w: u32 = 0x14000000 | (((to - site) >> 2) as! u32) & 0x3FFFFFF;
    jp = [];
    jp.push(w as! u8);
    jp.push((w >> 8) as! u8);
    jp.push((w >> 16) as! u8);
    jp.push((w >> 24) as! u8);
    jit_write(j_mem + site, jp[..]);
    jit_links += 1;
}
// The branches to ways out, to be filled in behind the block: where each is, and the
// instruction it leaves before.
let SO_MAX = 240;
var so_n = 0;
var so_pos: i64[SO_MAX] = [0; SO_MAX];
var so_off: u64[SO_MAX] = [0; SO_MAX];
var so_cnt: u64[SO_MAX] = [0; SO_MAX];
var so_op: u32[SO_MAX] = [0; SO_MAX];        // the branch itself: cbnz or cbz and its register, or b.cond
var so_link: bool[SO_MAX] = [false; SO_MAX]; // it is a jump taken, to be linked, and not an instruction to interpret
var so_stale: bool[SO_MAX] = [false; SO_MAX];
// A record to be made in the way out (E130): how, 0 for none, and from what.
var so_how: u8[SO_MAX] = [0; SO_MAX];
var so_ska: u32[SO_MAX] = [0; SO_MAX];
var so_skb: u32[SO_MAX] = [0; SO_MAX];
var so_ski: u64[SO_MAX] = [0; SO_MAX];
var so_skw: u32[SO_MAX] = [0; SO_MAX];

// The entry of the instruction at physical address q, into je and jk. False if there is none.
fn j_entry(q: u64) -> bool {
    let slot = dc_slot(q);
    if dc[slot].tag != q { return false; }
    je = dc[slot].ins;
    jk = if dc_n[slot] != 0 { dc_k0[slot] } else { je.kind };
    j_at = q;
    return true;
}

// How long the instruction in je is, in bytes; 0 if that is not known.
fn j_len() -> u64 {
    let op = je.op;
    let il: u64 = if je.osz == 16 { 2 } else { 4 };
    let m: u64 = je.mlen;
    let p: u64 = je.plen;
    if jk == 0 {
        // No kind: an SSE instruction's length is known if its operand's is (all of them
        // have one but EMMS), with a constant behind it for some.
        if op != 0x0F || m == 0 { return 0; }
        let op2 = mem_rd(j_at + p, 8) as! u8;
        if !sse64_is(op2) || op2 == 0x77 || op2 == 0xAE { return 0; }
        let has_imm = op2 == 0x70 || op2 == 0x71 || op2 == 0x72 || op2 == 0x73 || (op2 >= 0xC2 && op2 <= 0xC6 && op2 != 0xC3);
        return if has_imm { m + 1 } else { m };
    }
    if jk >= K_JCC32 && jk < K_CMOV { return p + 5; }
    if jk >= K_CMOV { return m; }
    match jk {
        K_ALU, K_TEST, K_MOV, K_LEA, K_MOVSXD, K_SHIFT, K_GRP5, K_NOPM, K_MOVZX8, K_MOVZX16, K_MOVSX8, K_MOVSX16, K_IMUL2 => { return m; },
        K_GRP1 => { return if m == 0 { 0 } else if op == 0x81 { m + il } else { m + 1 }; },
        K_SHIFTI => { return if m == 0 { 0 } else { m + 1 }; },
        K_MOVMI => { return if m == 0 { 0 } else if op == 0xC6 { m + 1 } else { m + il }; },
        K_IMUL3 => { return if m == 0 { 0 } else if op == 0x69 { m + il } else { m + 1 }; },
        K_GRP3 => { return if m == 0 { 0 } else if je.reg & 7 >= 2 { m } else if op == 0xF6 { m + 1 } else { m + il }; },
        K_PUSH, K_POP, K_RET, K_NOP, K_CONV => { return p; },
        K_CALL, K_JMP32 => { return p + 4; },
        K_JMP8, K_JCC8 => { return p + 1; },
        K_MOVI => { return if op < 0xB8 { p + 1 } else if je.osz == 64 { p + 8 } else { p + il }; },
        K_ALUA, K_TESTA => { return if op & 1 == 0 { p + 1 } else { p + il }; },
        K_PUSHI => { return if op == 0x6A { p + 1 } else { p + il }; },
        _ => { return 0; },
    }
}

// A constant of n bytes at physical address at, sign-extended.
fn j_const(at: u64, n: u64) -> u64 { return sx(mem_rd(at, (n * 8) as! u8), (n * 8) as! u8); }

// The record: what, at which width, of the values in host registers a and b (b may be ZR).
fn j_rec(what: u32, a: u32, b: u32) { j_rec_w(what, je.osz, a, b); }

fn j_rec_w(what: u32, w: u32, a: u32, b: u32) {
    // Nothing can read these flags (E128): no record, and whatever record there was
    // stays, as stale as the flags are dead.
    if j_dead { j_stale = true; return; }
    j_stale = false;
    a_mov(1, FA, a);
    a_mov(1, FB, b);
    a_imm(FK, what | w << 8);
    j_set = true;
    j_dyn = false;
}

// A record put off (E130): the flag-setting instruction has a conditional jump right behind
// it, which uses the host's flags; the record is made only on the sides of that jump where
// the flags are not dead, from what the registers still hold there. How: 1 the operands
// are as they were (sk_a and sk_b; sk_b 255 for the constant sk_i); 2 and 3 the first
// operand was overwritten by the result of a SUB or an ADD and is the result with the
// second put back; 4 a logic instruction, whose flags are its result's.
var sk_live = false;
var sk_how: u8 = 0;
var sk_a: u32 = 0;
var sk_b: u32 = 0;
var sk_i: u64 = 0;
var sk_w: u32 = 0;                // what it was, and the width above it
var j_next_jcc = false;       // the instruction behind the one being translated is a conditional jump

fn j_sink_emit(how: u8, a: u32, b: u32, i: u64, w: u32) {
    if how == 4 { a_mov(1, FA, a); a_mov(1, FB, a); }
    else {
        if b == 255 { a_imm(FB, i); } else { a_mov(1, FB, b); }
        if how == 1 { a_mov(1, FA, a); }
        else { a_rrr(if how == 2 { A_ADD } else { A_SUB }, 1, FA, a, FB); }
    }
    a_imm(FK, w);
}

// The record put off is made here after all.
fn j_sink_flush() {
    j_sink_emit(sk_how, sk_a, sk_b, sk_i, sk_w);
    sk_live = false;
    j_set = true;
    j_dyn = false;
    j_stale = false;
}

// The record of an ALU instruction: what, at width w, of a and b (b 255 for the constant
// i) with the result going to dst (ZR for none). Made now, or put off, or not at all.
fn j_rec_alu(what: u32, w: u32, dst: u32, a: u32, b: u32, i: u64) {
    if j_dead { j_stale = true; return; }
    if j_next_jcc && jit_no >> 58 & 1 == 0 {
        var how: u8 = 0;
        if dst == ZR || (dst != a && dst != b) { how = 1; }
        else if dst == a && dst != b {
            if what == 6 { how = 2; } else if what == 1 { how = 3; }
            else if what == 2 || what == 5 || what == 7 { how = 4; }
        }
        if how != 0 {
            sk_live = true;
            sk_how = how;
            sk_a = if how == 1 { a } else { dst };
            sk_b = b;
            sk_i = i;
            sk_w = (if how == 4 { 5 } else { what }) | w << 8;
            return;
        }
    }
    j_stale = false;
    a_mov(1, FA, a);
    if b == 255 { a_imm(FB, i); } else { a_mov(1, FB, b); }
    a_imm(FK, what | w << 8);
    j_set = true;
    j_dyn = false;
}

// ALU operation k (the instruction's 3-bit field) of a and b into dst (not for CMP and TEST,
// test true).
fn j_alu(k: u8, test: bool, dst: u32, a: u32, b: u32) {
    let sf: u32 = if je.osz == 64 { 1 } else { 0 };
    if !test && (k == 2 || k == 3) {
        // ADC and SBB (j_carry_ok has said the carry can be had): the carry that goes in,
        // 0 or 1, into x29, from the host's flags or from RFLAGS in memory; kept in the
        // record, above the width; and put into the host's carry as ADCS and SBCS want it.
        if !j_dyn && j_hf == HF_LOGIC { a_mov(0, 29, ZR); }
        else if !j_dyn && (j_hf == HF_ADD || j_hf == HF_SUB) { e(0x1A9F07E0 | ((if j_hf == HF_ADD { C_HS } else { C_LO }) ^ 1) << 12 | 29); }    // cset w29
        else {
            j_needs = true;
            a_ldr(29, CTX, 0);
            e(0x12000000 | 29 << 5 | 29);                    // and w29, w29, #1
        }
        j_rec(if k == 2 { 3 } else { 4 }, a, b);
        if !j_dead { e(0xAA1D40E7); }                        // orr x7, x7, x29, lsl #16
        if k == 3 { e(0x52000000 | 29 << 5 | 29); }          // eor w29, w29, #1: SBCS takes the borrow upside down
        a_addi(0x71, 0, ZR, 29, 1);                          // cmp w29, #1: the host's carry
        a_rrr(if k == 2 { 0x3A000000 } else { 0x7A000000 }, sf, dst, a, b);      // adcs, sbcs
        j_hf = if k == 2 { HF_ADD } else { HF_SUB };
        return;
    }
    j_rec_alu(if test { 5 } else { (k as u32) + 1 }, je.osz, if test || k == 7 { ZR } else { dst }, a, b, 0);
    if test { a_rrr(A_ANDS, sf, ZR, a, b); j_hf = HF_LOGIC; return; }
    match k {
        0 => { a_rrr(A_ADDS, sf, dst, a, b); j_hf = HF_ADD; },
        5 => { a_rrr(A_SUBS, sf, dst, a, b); j_hf = HF_SUB; },
        7 => { a_rrr(A_SUBS, sf, ZR, a, b); j_hf = HF_SUB; },
        4 => { a_rrr(A_ANDS, sf, dst, a, b); j_hf = HF_LOGIC; },
        _ => {
            a_rrr(if k == 1 { A_ORR } else { A_EOR }, sf, dst, a, b);
            // The host's flags, only if anything can read them (E129).
            if j_nohost { j_hf = 0; }
            else { a_rrr(A_ANDS, sf, ZR, dst, dst); j_hf = HF_LOGIC; }
        },
    }
}

// The same with a constant for b. ADD, SUB and CMP take one under 4096 as it is; the rest
// have it built in host register tmp.
fn j_alu_i(k: u8, dst: u32, a: u32, v: u64, tmp: u32) {
    if (k == 0 || k == 5 || k == 7) && v < 4096 {
        let sf: u32 = if je.osz == 64 { 1 } else { 0 };
        j_rec_alu((k as u32) + 1, je.osz, if k == 7 { ZR } else { dst }, a, 255, v);
        a_addi(if k == 0 { 0x31 } else { 0x71 }, sf, if k == 7 { ZR } else { dst }, a, v as! u32);
        j_hf = if k == 0 { HF_ADD } else { HF_SUB };
        return;
    }
    a_imm(tmp, v);
    j_alu(k, false, dst, a, tmp);
}

// rd = rn + v, in as few instructions as v allows (S2 is used for a large one).
fn a_add_const(rd: u32, rn: u32, v: u64) {
    if v == 0 { if rd != rn { a_mov(1, rd, rn); } }
    else if v < 4096 { a_addi(0x11, 1, rd, rn, v as! u32); }
    else if 0 - v < 4096 { a_addi(0x51, 1, rd, rn, (0 - v) as! u32); }
    else { a_imm(S2, v); a_rrr(A_ADD, 1, rd, rn, S2); }
}

// Whether the carry that ADC and SBB take in can be had: RFLAGS in memory is right, or
// the host's flags are from an instruction whose carry they hold.
fn j_carry_ok() -> bool { return !j_set || (!j_dyn && (j_hf == HF_ADD || j_hf == HF_SUB || j_hf == HF_LOGIC)); }

// An ALU operation on bytes: k as for j_alu, of the byte in host register a and the byte
// in b, or the constant v if b is ZR. The result's byte is left in S4, and the host's
// flags are the byte's: the operands are shifted up 24 bits. S2 and S4 are used.
fn j_alu8(k: u8, test: bool, a: u32, b: u32, v: u64) {
    if b == ZR { a_imm(S4, v & 0xFF); } else { a_mov(0, S4, b); }
    j_rec_w(if test { 5 } else { (k as u32) + 1 }, 8, a, S4);
    a_shifti(4, 0, S2, a, 24);
    a_shifti(4, 0, S4, S4, 24);
    if test || k == 4 { a_rrr(A_ANDS, 0, S4, S2, S4); j_hf = HF_LOGIC; }
    else if k == 0 { a_rrr(A_ADDS, 0, S4, S2, S4); j_hf = HF_ADD; }
    else if k == 5 || k == 7 { a_rrr(A_SUBS, 0, S4, S2, S4); j_hf = HF_SUB; }
    else {
        a_rrr(if k == 1 { A_ORR } else { A_EOR }, 0, S4, S2, S4);
        if j_nohost { j_hf = 0; }
        else { a_rrr(A_ANDS, 0, ZR, S4, S4); j_hf = HF_LOGIC; }
    }
    a_shifti(5, 0, S4, S4, 24);
}

// The host's condition for the guest's cc as the flags stand, or C_NONE. With no instruction
// of the block having set them, the code to test RFLAGS in memory is generated here.
fn j_cond(cc: u8) -> u32 {
    // The host's flags wherever they are good (E130): an instruction may have set them
    // and made no record.
    let h = j_cond_host(cc);
    if h != C_NONE { return h; }
    // A record put off for this jump, and the host's flags cannot give its condition: no
    // condition, so the block ends here and the record is made.
    if sk_live { return C_NONE; }
    if !j_set {
        j_needs = true;
        a_ldr(S1, CTX, 0);
        let masks: u64[6] = [0x800, 1, 0x40, 0x41, 0x80, 4];
        let which = cc >> 1 & 7;
        if which < 6 {
            a_imm(S2, masks[which]);
            a_rrr(A_ANDS, 1, ZR, S1, S2);
        } else {
            e(0xCA400000 | S1 << 16 | 4 << 10 | S1 << 5 | S2);       // eor x2, x1, x1, lsr #4: SF != OF at bit 7
            a_imm(S3, 0x80);
            if which == 6 { a_rrr(A_ANDS, 1, ZR, S2, S3); }
            else {
                a_rrr(A_AND, 1, S2, S2, S3);
                a_imm(S3, 0x40);
                a_rrr(A_AND, 1, S3, S1, S3);
                a_rrr(A_ORR, 1, S2, S2, S3);
                a_rrr(A_ANDS, 1, ZR, S2, S2);
            }
        }
        return if cc & 1 == 0 { C_NE } else { C_EQ };
    }
    return C_NONE;
}

// Whether j_cond will give a condition.
fn j_cond_ok(cc: u8) -> bool { return !j_set || j_cond_host(cc) != C_NONE; }

// The host's condition for the guest's cc from the host's own flags, or C_NONE.
fn j_cond_host(cc: u8) -> u32 {
    if j_dyn { return C_NONE; }
    return j_cond_of(j_hf, cc);
}

// The same for the host's flags as an instruction of regime hf leaves them.
fn j_cond_of(hf: u8, cc: u8) -> u32 {
    if hf == 0 { return C_NONE; }
    // The guest's conditions 0 to 15: O NO B AE E NE BE A S NS P NP L GE LE G.
    let sub: u8[16] = [6, 7, 3, 2, 0, 1, 9, 8, 4, 5, 255, 255, 11, 10, 13, 12];
    let add: u8[16] = [6, 7, 2, 3, 0, 1, 255, 255, 4, 5, 255, 255, 11, 10, 13, 12];
    let logic: u8[16] = [255, 255, 255, 255, 0, 1, 0, 1, 4, 5, 255, 255, 4, 5, 13, 12];
    let incdec: u8[16] = [6, 7, 255, 255, 0, 1, 255, 255, 4, 5, 255, 255, 11, 10, 13, 12];
    // After FCMP: below is "less or unordered" (LT), above "greater" (GT), parity
    // "unordered" (VS); equal is "equal or unordered", which no one condition says.
    let fcmp: u8[16] = [255, 255, 11, 10, 255, 255, 13, 12, 255, 255, 6, 7, 255, 255, 255, 255];
    let c: u8 = if hf == HF_SUB { sub[cc] } else if hf == HF_ADD { add[cc] } else if hf == HF_LOGIC { logic[cc] } else if hf == HF_FCMP { fcmp[cc] } else { incdec[cc] };
    return c;
}

// The address off bytes from the block's first instruction, into rd (S2 is used).
fn j_rip(rd: u32, off: u64) {
    if off < 4096 { a_addi(0x11, 1, rd, RIPB, off as! u32); }
    else if 0 - off < 4096 { a_addi(0x51, 1, rd, RIPB, (0 - off) as! u32); }
    else { a_imm(S2, off); a_rrr(A_ADD, 1, rd, RIPB, S2); }
}

// For --jit-check: whether the flags are stale at this way out.
fn j_tell() {
    if !jit_check { return; }
    a_imm(S2, if j_stale { 1 } else { 0 });
    a_str(S2, CTX, 120);
}

// The way out to the instruction off bytes from the block's first, cnt instructions run.
// With link, it goes into the block there if there is one, or will when there is: in a
// program without a kernel, where an address is the same wherever it is jumped to from.
fn j_exit(off: u64, cnt: u64, link: bool) {
    var to = j_out_at;
    // In a machine a link stays on the page: there an address's page is known to be this
    // block's. (And blocks are for one privilege level, which nothing in a block changes.)
    let linked = link && !jit_check && jit_no >> 63 == 0 && (!machine || (j_head + off) >> 12 == j_head >> 12);
    if linked && off == 0 && ss_n < SS_MAX {
        // Back to this block's own first instruction (E129): what it ran taken off the
        // time, and if there is time for another round and the block does not read
        // RFLAGS in memory, straight to its body. The two instructions for that are
        // filled in when the block's length is known; without them, round by its entry.
        a_addi(0x51, 1, 0, 0, cnt as! u32);
        ss_pos[ss_n] = jc.len;
        ss_n += 1;
        e(0xD503201F);
        e(0xD503201F);
    } else { j_tell(); a_addi(0x51, 1, 0, 0, cnt as! u32); }
    j_rip(S1, off);
    if linked {
        let t = j_head + off;
        let slot = dc_slot(t);
        if t == j_head { to = j_used; jit_links += 1; }
        else if dc[slot].tag == t && dc_n[slot] != 0 && dc_cpl[slot] == cpl { to = dc_code[slot]; jit_links += 1; }
        else if tp_n < TP_MAX { tp_pos[tp_n] = jc.len; tp_to[tp_n] = t; tp_n += 1; }
    }
    // In a machine, an address on another page: looked up as it is jumped to.
    if link && machine && !linked { to = j_far(); }
    let d: u32 = ((to - (j_used + jc.len)) >> 2) as! u32;
    e(0x14000000 | d & 0x3FFFFFF);
}

// Where an exit to an address not known to be a block's goes: the far way for this kind
// of run and privilege level, or out.
fn j_far() -> i64 {
    if j_far_at == 0 || jit_check || jit_no >> 62 & 1 != 0 { return j_out_at; }
    if !machine { return j_far_at; }
    if jit_no >> 55 & 1 != 0 { return j_out_at; }
    if cpl == 0 { return j_fark_at[0]; }
    if cpl == 3 { return j_fark_at[1]; }
    return j_out_at;
}

// The way out to the address in host register r.
fn j_exit_to(r: u32, cnt: u64) {
    a_mov(1, S1, r);
    j_tell();
    a_addi(0x51, 1, 0, 0, cnt as! u32);
    let d: u32 = ((j_far() - (j_used + jc.len)) >> 2) as! u32;
    e(0x14000000 | d & 0x3FFFFFF);
}

// What the host's flags are from behind the instruction in je, as j_one will translate it:
// HF_ADD, HF_SUB or HF_LOGIC, or 0 for an instruction that leaves them no use to a jump.
fn j_regime() -> u8 {
    let f = je.reg & 7;
    var ak: u8 = 255;
    match jk {
        K_ALU, K_ALUA => { ak = je.op >> 3; },
        K_GRP1 => { ak = f; },
        K_TEST, K_TESTA => { ak = 4; },
        K_GRP3 => { if f < 2 { ak = 4; } else if f == 3 { ak = 5; } },
        _ => {},
    }
    if ak == 0 || ak == 2 { return HF_ADD; }
    if ak == 3 || ak == 5 || ak == 7 { return HF_SUB; }
    if ak == 1 || ak == 4 || ak == 6 { return HF_LOGIC; }
    return 0;
}

// Whether no record is needed of the flags the instruction in je sets although a
// conditional jump comes right behind it, at q (E130): the jump will be in this block and
// will use the host's flags, and the flags are dead both where it goes and behind it. Every
// reason j_one could have not to translate that jump here is looked at first, since a
// jump interpreted, or begun a block with, would read a record that was not made. cnt is
// how many instructions the block has before the one in je.
fn j_dead_past_jump(q: u64, page_end: u64, cnt: u64) -> bool {
    if jit_no >> 61 & 1 != 0 || jit_no >> 59 & 1 != 0 { return false; }
    let hf = j_regime();
    if hf == 0 || cnt + 2 > J_MAX || so_n + 12 > SO_MAX || q >= page_end { return false; }
    let keep = je;
    let keep_k = jk;
    let keep_at = j_at;
    var ok = false;
    var fall: u64 = 0;
    var to: u64 = 0;
    if j_entry(q) {
        let k = jk;
        let len = j_len();
        if (k == K_JCC8 || (k >= K_JCC32 && k < K_CMOV)) && len != 0 && len <= page_end - q
            && !je.asz32 && !je.p66 && je.sg == 0 && je.rep == 0 && jit_no >> k & 1 == 0 {
            let cc = if k == K_JCC8 { je.op & 15 } else { k & 15 };
            if j_cond_of(hf, cc) != C_NONE {
                fall = q + len;
                to = fall + (if k == K_JCC8 { j_const(q + len - 1, 1) } else { j_const(q + len - 4, 4) });
                ok = to >= page_end - 0x1000 && to < page_end;
            }
        }
    }
    je = keep;
    jk = keep_k;
    j_at = keep_at;
    return ok && j_flags_dead(fall, page_end) && j_flags_dead(to, page_end);
}

// ---- Memory, for a program without a kernel ----

// cbnz x2 to the way out before the instruction being translated.
fn j_leave_if() { j_leave(S2, false); }

// To that way out if host register r is not zero, or if it is.
fn j_leave(r: u32, zero: bool) {
    so_pos[so_n] = jc.len;
    so_off[so_n] = j_off;
    so_cnt[so_n] = j_cnt;
    so_op[so_n] = (if zero { 0xB4000000 } else { 0xB5000000 }) | r;
    so_link[so_n] = false;
    so_stale[so_n] = j_stale;
    so_how[so_n] = 0;
    so_n += 1;
    e(0);
}

// Whether the flags the instruction in je sets are overwritten before anything can read
// them: the instructions behind it on the page, as far as the decode cache knows them,
// come to one that sets all six before one that reads any, sets only some, or jumps.
// (That later instruction may be run by the interpreter, after the block is left: the
// flags are as dead.) je and jk are as they were afterwards. page_end bounds the look.
fn j_flags_dead(q: u64, page_end: u64) -> bool {
    let keep = je;
    let keep_k = jk;
    let keep_at = j_at;
    var at = q;
    var dead = false;
    for i in 12 {
        if at >= page_end || !j_entry(at) { break; }
        let len = j_len();
        if len == 0 { break; }
        let k = jk;
        let op = je.op;
        let f = je.reg & 7;
        var full = false;
        var neutral = false;
        match k {
            K_ALU, K_ALUA => { full = op >> 3 != 2 && op >> 3 != 3; },
            K_GRP1 => { full = f != 2 && f != 3; },
            K_TEST, K_TESTA, K_IMUL2, K_IMUL3 => { full = true; },
            K_GRP3 => { full = f != 2 && f < 6; neutral = f == 2; },
            K_SHIFTI => { neutral = f < 2; full = f >= 4 && mem_rd(at + len - 1, 8) & 0x1F != 0 && (je.osz != 64 || op == 0xC0 || mem_rd(at + len - 1, 8) & 0x3F != 0); },
            K_SHIFT => { neutral = f < 2 || op >= 0xD2 && f >= 4; full = f >= 4 && op < 0xD2; },
            K_MOV, K_LEA, K_MOVZX8, K_MOVZX16, K_MOVSX8, K_MOVSX16, K_MOVSXD, K_MOVI, K_MOVMI, K_PUSH, K_POP, K_PUSHI, K_NOP, K_NOPM, K_CONV => { neutral = true; },
            // INC and DEC read no flag and set some: what is looked for comes behind them.
            K_GRP5 => { neutral = f < 2; },
            _ => {},
        }
        if full { dead = true; break; }
        if !neutral { break; }
        at += len;
    }
    je = keep;
    jk = keep_k;
    j_at = keep_at;
    return dead;
}

// The address of je's operand in memory, into S1.
fn j_addr() {
    j_lea();
    // FS's or GS's base, which a block is given as it is entered.
    if je.sg != 0 {
        a_ldr(29, CTX, if je.sg == 1 { 136 } else { 144 });
        a_rrr(A_ADD, 1, S1, S1, 29);
    }
}

// The operand's offset, which is what LEA gives: no segment's base.
fn j_lea() {
    if je.base == 17 { a_add_const(S1, RIPB, j_off + j_ilen + je.disp); }
    else if je.base < 16 { a_add_const(S1, hg(je.base), je.disp); }
    else { a_imm(S1, je.disp); }
    if je.index < 16 { e(0x8B000000 | hg(je.index) << 16 | (je.scale as u32) << 10 | S1 << 5 | S1); }
}

// The checks on the address in S1 (rd and wr, cpu64.goose): eight bytes from it are inside
// memory, and for a store neither page it may touch holds remembered instructions. None
// changes the host's flags. S2 and S3 are used.
fn j_chk(write: bool) { j_chk_n(write, 8); }

// The same for n bytes, 8 or 16.
fn j_chk_n(write: bool, n: u32) {
    if machine {
        // In a machine (E133) the address in S1 is a linear one: the TLB's entry for its
        // page, in the table for this kind of access at the privilege level the block is
        // translated for, gives the physical page, and S1 is made the physical address.
        // A miss leaves the block (the interpreter walks the tables, or faults); so does
        // an access that may lie across two pages, and a page not in memory. x29, x30,
        // S2 and S3 are used; the host's flags are not.
        let table: u32 = (if write { 2 } else { 0 }) + (if cpl == 3 { 1 } else { 0 });
        a_shifti(5, 1, S2, S1, 12);
        e(0x92402C00 | S2 << 5 | S3);                        // and x3, x2, #0xFFF
        if table != 0 { e(0x91400000 | table << 10 | S3 << 5 | S3); }        // add x3, x3, #table, lsl #12
        a_ldr(29, CTX, 152);
        e(0xF8607800 | S3 << 16 | 29 << 5 | 30);             // ldr x30, [x29, x3, lsl #3]
        a_rrr(A_EOR, 1, S2, S2, 30);
        j_leave(S2, false);
        e(0x92402C00 | S1 << 5 | S2);                        // and x2, x1, #0xFFF
        a_addi(0x11, 1, 30, S2, n - 1);
        a_shifti(5, 1, 30, 30, 12);
        j_leave(30, false);
        a_ldr(29, CTX, 160);
        e(0xF8607800 | S3 << 16 | 29 << 5 | 30);
        a_rrr(A_ORR, 1, S1, 30, S2);
        e(0x91400400 | S1 << 5 | S2);                        // add x2, x1, #1, lsl #12
        a_shifti(5, 1, S2, S2, 28);
        j_leave(S2, false);
    } else {
        a_addi(0x11, 1, S2, S1, n);
        a_rrr(A_ORR, 1, S2, S2, S1);
        a_shifti(5, 1, S2, S2, 28);
        j_leave_if();
    }
    j_chk_mark(write, n);
}

// For a store to the physical address in S1: neither page it may touch holds remembered
// instructions.
fn j_chk_mark(write: bool, n: u32) {
    if write {
        a_shifti(5, 1, S2, S1, 12);
        e(0x38606800 | S2 << 16 | MARK << 5 | S2);           // ldrb w2, [x28, x2]
        a_addi(0x11, 1, S3, S1, n - 1);
        a_shifti(5, 1, S3, S3, 12);
        e(0x38606800 | S3 << 16 | MARK << 5 | S3);
        a_rrr(A_ORR, 0, S2, S2, S3);
        j_leave_if();
    }
}

// A load of n bits at the guest address in S1 into rt, zero-extended; a store of rt's low
// n bits there. With --jit-check a store is logged first: the address and what was there.
fn j_load(n: u8, rt: u32) {
    let op: u32 = if n == 64 { 0xF8606800 } else if n == 32 { 0xB8606800 } else if n == 16 { 0x78606800 } else { 0x38606800 };
    e(op | S1 << 16 | MEMR << 5 | rt);
}
// With --jit-check: the eight bytes at the guest address in S1 into the log, with the address.
fn j_log() {
    if !jit_check { return; }
    a_ldr(29, CTX, 56);
    a_ldr(30, CTX, 64);
    e(0x8B000000 | 29 << 16 | 4 << 10 | 30 << 5 | 30);       // add x30, x30, x29, lsl #4
    a_str(S1, 30, 0);
    a_addi(0x11, 1, 29, 29, 1);
    a_str(29, CTX, 56);
    e(0xF8606800 | S1 << 16 | MEMR << 5 | 29);               // ldr x29, [x27, x1]
    a_str(29, 30, 8);
}

fn j_store(n: u8, rt: u32) {
    j_log();
    let op: u32 = if n == 64 { 0xF8206800 } else if n == 32 { 0xB8206800 } else if n == 16 { 0x78206800 } else { 0x38206800 };
    e(op | S1 << 16 | MEMR << 5 | rt);
}

// A push of the value in rt (not S1 or S2): the store, and then RSP.
fn j_push(rt: u32) {
    a_addi(0x51, 1, S1, hg(4), 8);
    j_chk(true);
    j_store(64, rt);
    a_addi(0x51, 1, hg(4), hg(4), 8);            // (S1 may be a physical address by now)
}

// ---- SSE ----
//
// The XMM registers stay in memory (cpu64's xmm, two words each): an instruction loads
// what it reads into v0 and v1 and stores what it writes. x29 holds their address for the
// length of one instruction.

fn x_base() { a_ldr(29, CTX, 128); }
// A load of n bits (32, 64, 128) of XMM register i into host vector vt, the rest of vt
// cleared; a store of vt's low n bits there.
fn x_ld(n: u32, vt: u32, i: u8) {
    let at: u32 = (i as u32) * 16;
    e((if n == 64 { 0xFD400000 | (at >> 3) << 10 } else if n == 32 { 0xBD400000 | (at >> 2) << 10 } else { 0x3DC00000 | (at >> 4) << 10 }) | 29 << 5 | vt);
}
fn x_st(n: u32, vt: u32, i: u8) {
    let at: u32 = (i as u32) * 16;
    e((if n == 64 { 0xFD000000 | (at >> 3) << 10 } else if n == 32 { 0xBD000000 | (at >> 2) << 10 } else { 0x3D800000 | (at >> 4) << 10 }) | 29 << 5 | vt);
}
// The same at the guest address in S1.
fn m_ld(n: u32, vt: u32) {
    e((if n == 64 { 0xFC606800 } else if n == 32 { 0xBC606800 } else { 0x3CE06800 }) | S1 << 16 | MEMR << 5 | vt);
}
fn m_st(n: u32, vt: u32) {
    j_log();
    if n == 128 && jit_check { a_addi(0x11, 1, S1, S1, 8); j_log(); a_addi(0x51, 1, S1, S1, 8); }
    e((if n == 64 { 0xFC206800 } else if n == 32 { 0xBC206800 } else { 0x3CA06800 }) | S1 << 16 | MEMR << 5 | vt);
}
// The operand r/m names, n bits of it, into vt.
fn x_src(n: u32, vt: u32) {
    if je.mod == 3 { x_base(); x_ld(n, vt, je.rm); }
    else { j_addr(); j_chk_n(false, if n == 128 { 16 } else { 8 }); m_ld(n, vt); }
}
// Leaves the block, before the instruction has changed anything, if the double (or single)
// in vt is not a finite number: what the chip gives then is the interpreter's to say. The
// host's flags are left alone. S2 is used.
fn x_finite(double: bool, vt: u32) {
    if double {
        e(0x9E660000 | vt << 5 | S2);                        // fmov x2, d
        e(0xD3400000 | 52 << 16 | 62 << 10 | S2 << 5 | S2);  // ubfx x2, x2, #52, #11
        e(0xD2402800 | S2 << 5 | S2);                        // eor x2, x2, #0x7FF
    } else {
        e(0x1E260000 | vt << 5 | S2);                        // fmov w2, s
        e(0x53000000 | 23 << 16 | 30 << 10 | S2 << 5 | S2);  // ubfx w2, w2, #23, #8
        e(0x52001C00 | S2 << 5 | S2);                        // eor w2, w2, #0xFF
    }
    j_leave(S2, true);
}

// Translates the SSE instruction in je, at q and len bytes long. False with nothing
// generated if it is not one of those taken.
fn j_sse(q: u64, len: u64) -> bool {
    let op2 = mem_rd(q + je.plen, 8) as! u8;
    // Which prefix chose the instruction: 0 none, 1 66, 2 F3, 3 F2.
    let p: u8 = if je.rep == 0xF3 { 2 } else if je.rep == 0xF2 { 3 } else if je.p66 { 1 } else { 0 };
    let r = je.reg;
    let regs = je.mod == 3;
    let wide = je.rex & 8 != 0;          // a general register here is 64 bits
    let gr = hg(je.rm);                  // r/m as a general register
    match op2 {
        0x10 => {
            // To the register. From memory a scalar clears the rest; from a register not.
            if p < 2 { x_src(128, 0); x_base(); x_st(128, 0, r); }
            else {
                let n: u32 = if p == 2 { 32 } else { 64 };
                x_src(n, 0);
                x_base();
                x_st(if regs { n } else { 128 }, 0, r);
            }
        },
        0x11 => {
            let n: u32 = if p < 2 { 128 } else if p == 2 { 32 } else { 64 };
            if regs { x_base(); x_ld(n, 0, r); x_st(n, 0, je.rm); }
            else { j_addr(); j_chk_n(true, if n == 128 { 16 } else { 8 }); x_base(); x_ld(n, 0, r); m_st(n, 0); }
        },
        0x28 => { x_src(128, 0); x_base(); x_st(128, 0, r); },
        0x29 => {
            if regs { x_base(); x_ld(128, 0, r); x_st(128, 0, je.rm); }
            else { j_addr(); j_chk_n(true, 16); x_base(); x_ld(128, 0, r); m_st(128, 0); }
        },
        0x6F => {
            if p == 0 || p == 3 { return false; }
            x_src(128, 0); x_base(); x_st(128, 0, r);
        },
        0x7F => {
            if p == 0 || p == 3 { return false; }
            if regs { x_base(); x_ld(128, 0, r); x_st(128, 0, je.rm); }
            else { j_addr(); j_chk_n(true, 16); x_base(); x_ld(128, 0, r); m_st(128, 0); }
        },
        0x6E => {
            // MOVD and MOVQ from a general register or memory: the rest cleared.
            if p != 1 { return false; }
            if regs { e((if wide { 0x9E670000 } else { 0x1E270000 }) | gr << 5); }      // fmov d0 or s0
            else { j_addr(); j_chk(false); m_ld(if wide { 64 } else { 32 }, 0); }
            x_base();
            x_st(128, 0, r);
        },
        0x7E => {
            if p == 2 { x_src(64, 0); x_base(); x_st(128, 0, r); }
            else if p == 1 {
                // To a general register or memory.
                if regs {
                    x_base();
                    a_ldr(S3, 29, (r as u32) * 16);
                    a_mov(if wide { 1 } else { 0 }, gr, S3);
                } else {
                    j_addr(); j_chk(true);
                    x_base();
                    a_ldr(S3, 29, (r as u32) * 16);
                    j_store(if wide { 64 } else { 32 }, S3);
                }
            } else { return false; }
        },
        0xD6 => {
            if p != 1 { return false; }
            if regs { x_base(); x_ld(64, 0, r); x_st(128, 0, je.rm); }
            else { j_addr(); j_chk(true); x_base(); x_ld(64, 0, r); m_st(64, 0); }
        },
        0x51, 0x58, 0x59, 0x5C, 0x5E => {
            // The scalar arithmetic: the host's, unless what comes out is not finite.
            if p < 2 { return false; }
            let n: u32 = if p == 2 { 32 } else { 64 };
            let ty: u32 = if p == 2 { 0x1E200000 } else { 0x1E600000 };
            x_src(n, 1);
            x_base();
            if op2 == 0x51 { e(ty | 0x1C000 | 1 << 5 | 2); }                  // fsqrt v2, v1
            else {
                x_ld(n, 0, r);
                let f: u32 = if op2 == 0x58 { 0x2800 } else if op2 == 0x59 { 0x0800 } else if op2 == 0x5C { 0x3800 } else { 0x1800 };
                e(ty | f | 1 << 16 | 0 << 5 | 2);                             // fadd, fmul, fsub, fdiv v2, v0, v1
            }
            x_finite(p == 3, 2);
            x_st(n, 2, r);
        },
        0x5D, 0x5F => {
            // The smaller and the larger: the second operand unless the first is strictly
            // less (or greater), so also when either is not a number.
            if p < 2 { return false; }
            let n: u32 = if p == 2 { 32 } else { 64 };
            x_src(n, 1);
            x_base();
            x_ld(n, 0, r);
            e((if p == 2 { 0x1E202000 } else { 0x1E602000 }) | 1 << 16 | 0 << 5);       // fcmp v0, v1
            e((if p == 2 { 0x1E200C00 } else { 0x1E600C00 }) | 1 << 16 | (if op2 == 0x5D { C_MI } else { C_GT }) << 12 | 0 << 5 | 2);    // fcsel v2, v0, v1
            x_st(n, 2, r);
            j_hf = 0;
        },
        0x2A => {
            // An integer to a float: rounded once, as the host does it.
            if p < 2 { return false; }
            var from = gr;
            if !regs { j_addr(); j_chk(false); j_load(if wide { 64 } else { 32 }, S3); from = S3; }
            e((if p == 3 { 0x1E620000 } else { 0x1E220000 }) | (if wide { 1 << 31 } else { 0 }) | from << 5);       // scvtf d0 or s0
            x_base();
            x_st(if p == 3 { 64 } else { 32 }, 0, r);
        },
        0x2C => {
            // A float to an integer, cut off. Out of the integer's range, or not a number,
            // the chip gives the "integer indefinite", the smallest integer: the host's
            // conversion stops at the nearest end and gives 0 for what is not a number,
            // so both are looked for. (The host's flags are used up.)
            if p < 2 { return false; }
            x_src(if p == 3 { 64 } else { 32 }, 0);
            e((if p == 3 { 0x9E780000 } else { 0x9E380000 }) | 0 << 5 | S3);    // fcvtzs x3, d0 or s0
            if wide {
                a_imm(S4, 0x8000000000000000);
                e(0xCA800000 | 63 << 10 | S3 << 16 | S3 << 5 | S2);             // eor x2, x3, x3, asr #63: the largest for either end
                a_addi(0x11, 1, S2, S2, 1);
                a_rrr(A_SUBS, 1, ZR, S2, S4);                                   // cmp x2, x4
                a_csel(1, S3, S4, S3, C_EQ);
            } else {
                a_imm(S4, 0x80000000);
                e(0x93407C00 | S3 << 5 | S2);                                   // sxtw x2, w3
                a_rrr(A_SUBS, 1, ZR, S2, S3);                                   // cmp x2, x3
                a_csel(1, S3, S3, S4, C_EQ);
            }
            e((if p == 3 { 0x1E602000 } else { 0x1E202000 }) | 0 << 16 | 0 << 5);       // fcmp v0, v0
            a_csel(1, S3, S4, S3, C_VS);
            a_mov(if wide { 1 } else { 0 }, hg(r), S3);
            j_hf = 0;
        },
        0x5A => {
            if p == 2 { x_src(32, 1); e(0x1E22C000 | 1 << 5); x_base(); x_st(64, 0, r); }       // fcvt d0, s1
            else if p == 3 { x_src(64, 1); e(0x1E624000 | 1 << 5); x_base(); x_st(32, 0, r); }  // fcvt s0, d1
            else { return false; }
        },
        0x2E, 0x2F => {
            // The comparisons: the host's FCMP, whose flags a jump can use; and a record
            // of the two values, if anything else can read the flags.
            if p > 1 { return false; }
            let n: u32 = if p == 0 { 32 } else { 64 };
            x_src(n, 1);
            x_base();
            x_ld(n, 0, r);
            if j_dead { j_stale = true; }
            else {
                e((if p == 0 { 0x1E260000 } else { 0x9E660000 }) | 0 << 5 | FA);        // fmov to x5
                e((if p == 0 { 0x1E260000 } else { 0x9E660000 }) | 1 << 5 | FB);
                a_imm(FK, if p == 0 { 0x40 } else { 0x41 });
                j_set = true;
                j_dyn = false;
                j_stale = false;
            }
            e((if p == 0 { 0x1E202000 } else { 0x1E602000 }) | 1 << 16 | 0 << 5);       // fcmp v0, v1
            j_hf = HF_FCMP;
        },
        0x54, 0x55, 0x56, 0x57, 0xDB, 0xEB, 0xEF => {
            // The 128-bit AND, ANDN, OR and XOR, on floats' bits or integers'.
            if (op2 < 0x58 && p > 1) || (op2 >= 0xDB && p != 1) { return false; }
            x_src(128, 1);
            x_base();
            x_ld(128, 0, r);
            if op2 == 0x54 || op2 == 0xDB { e(0x4E201C00 | 1 << 16 | 0 << 5); }         // and v0, v0, v1
            else if op2 == 0x55 { e(0x4E601C00 | 0 << 16 | 1 << 5); }                   // bic v0, v1, v0
            else if op2 == 0x56 || op2 == 0xEB { e(0x4EA01C00 | 1 << 16 | 0 << 5); }    // orr
            else { e(0x6E201C00 | 1 << 16 | 0 << 5); }                                  // eor
            x_st(128, 0, r);
        },
        _ => { return false; },
    }
    return true;
}

// A register that is a byte: false for AH, CH, DH and BH, which are not translated.
fn j_byte_ok(i: u8) -> bool { return je.rex != 0 || i < 4 || i >= 8; }

// Translates the instruction in je, which is at q and off bytes from the block's first,
// with room bytes left on the page. Returns its length, or 0 with nothing generated if it
// is not one this translator takes, or not as the flags stand.
fn j_one(q: u64, off: u64, room: u64, cnt: u64) -> u64 {
    let len = j_len();
    if len == 0 || len > room || so_n + 4 > SO_MAX { return 0; }
    j_off = off;
    j_cnt = cnt;
    j_ilen = len;
    // A record put off for a jump that this is not: made now, with the registers as that
    // instruction left them.
    if sk_live && !(jk == K_JCC8 || (jk >= K_JCC32 && jk < K_CMOV)) { j_sink_flush(); }
    {
        let keep = je;
        let keep_k = jk;
        let keep_at = j_at;
        j_next_jcc = q + len < q + room && j_entry(q + len) && (jk == K_JCC8 || (jk >= K_JCC32 && jk < K_CMOV));
        je = keep;
        jk = keep_k;
        j_at = keep_at;
    }
    j_nohost = jit_no >> 60 & 1 == 0 && j_flags_dead(q + len, q + room);
    j_dead = j_nohost || (jit_no >> 60 & 1 == 0 && j_dead_past_jump(q + len, q + room, cnt));
    let op = je.op;
    let k = jk;
    if k == 0 {
        // An SSE instruction, in a program without a kernel (in a machine they need the
        // operating system's leave, which the interpreter looks for).
        if machine || je.asz32 || je.sg != 0 || jit_no >> 57 & 1 != 0 { return 0; }
        return if j_sse(q, len) { len } else { 0 };
    }
    // (A NOP may have the prefix 66h: the compiler's padding in front of a loop.)
    // (And MOV is taken with it: 16 bits moved.)
    if je.asz32 || (je.p66 && k != K_NOP && k != K_NOPM && k != K_MOV && k != K_MOVMI) { return 0; }
    if je.rep != 0 && k != K_NOP && k != K_NOPM { return 0; }
    if k < 64 && jit_no >> k & 1 != 0 { return 0; }
    let sf: u32 = if je.osz == 64 { 1 } else { 0 };
    let r = hg(je.reg);
    let m = hg(je.rm);
    let regs = je.mod == 3;
    let wide = op & 1 == 1;              // not a byte, for the opcodes whose low bit says so
    // An operand in memory, a push or a pop: in a machine through the TLB (E133), which
    // --jit-off's bit 56 leaves to the interpreter as before.
    let inmem = !regs && (!machine || jit_no >> 56 & 1 == 0);
    let stack = !machine || jit_no >> 56 & 1 == 0;
    let wb: u8 = if wide { je.osz } else { 8 };

    if k >= K_SETCC {
        if !regs || !j_byte_ok(je.rm) { return 0; }
        let c = j_cond(k & 15);
        if c == C_NONE { return 0; }
        e(0x1A9F07E0 | (c ^ 1) << 12 | S1);                  // cset w1, c
        e(0xB3401C00 | S1 << 5 | m);                         // bfi xm, x1, #0, #8
        return len;
    }
    if k >= K_CMOV {
        if !(regs || inmem) || !j_cond_ok(k & 15) { return 0; }
        // The operand is read whether it is moved or not.
        if inmem { j_addr(); j_chk(false); j_load(je.osz, S4); }
        let c = j_cond(k & 15);
        a_csel(sf, r, if regs { m } else { S4 }, r, c);
        return len;
    }
    if k == K_JCC8 || k >= K_JCC32 {
        let c = j_cond(if k == K_JCC8 { op & 15 } else { k & 15 });
        if c == C_NONE { return 0; }
        let d = if k == K_JCC8 { j_const(q + len - 1, 1) } else { j_const(q + len - 4, 4) };
        if jit_no >> 61 & 1 == 0 {
            // The block goes on through the side not taken (E127): taken, the jump leaves
            // by a way out behind the block, which is a link like any exit's.
            so_pos[so_n] = jc.len;
            so_off[so_n] = off + len + d;
            so_cnt[so_n] = cnt + 1;
            so_op[so_n] = 0x54000000 | c;
            so_link[so_n] = true;
            so_stale[so_n] = j_stale;
            so_how[so_n] = 0;
            // A record put off: on the side taken it is made in the way out, unless the
            // flags are dead where the jump goes; on the other side here, unless dead.
            if sk_live {
                let to = q + len + d;
                if to >= q + room - 0x1000 && to < q + room && j_flags_dead(to, q + room) { so_stale[so_n] = true; }
                else {
                    so_stale[so_n] = false;
                    so_how[so_n] = sk_how;
                    so_ska[so_n] = sk_a;
                    so_skb[so_n] = sk_b;
                    so_ski[so_n] = sk_i;
                    so_skw[so_n] = sk_w;
                }
            }
            so_n += 1;
            e(0);
            if sk_live {
                if j_flags_dead(q + len, q + room) { sk_live = false; j_stale = true; }
                else { j_sink_flush(); }
            }
            return len;
        }
        if sk_live { j_sink_flush(); }
        let at = jc.len;
        e(0);
        j_exit(off + len, cnt + 1, true);
        e_at(at, 0x54000000 | (((jc.len - at) >> 2) as! u32) << 5 | c);      // b.c over the way out
        j_exit(off + len + d, cnt + 1, true);
        j_end = true;
        return len;
    }
    match k {
        K_ALU => {
            let ak = op >> 3;
            if !(regs || inmem) { return 0; }
            if (ak == 2 || ak == 3) && (!wide || !j_carry_ok()) { return 0; }
            if !wide {
                // Bytes: both registers must be ones a byte of which is their low byte.
                if !j_byte_ok(je.reg) || (regs && !j_byte_ok(je.rm)) { return 0; }
                if regs {
                    if op & 2 == 0 { j_alu8(ak, false, m, r, 0); if ak != 7 { e(0xB3401C00 | S4 << 5 | m); } }
                    else { j_alu8(ak, false, r, m, 0); if ak != 7 { e(0xB3401C00 | S4 << 5 | r); } }
                } else if op & 2 != 0 {
                    j_addr(); j_chk(false); j_load(8, S3);
                    j_alu8(ak, false, r, S3, 0);
                    if ak != 7 { e(0xB3401C00 | S4 << 5 | r); }
                } else {
                    j_addr(); j_chk(ak != 7); j_load(8, S3);
                    j_alu8(ak, false, S3, r, 0);
                    if ak != 7 { j_store(8, S4); }
                }
            } else if regs {
                if op & 2 == 0 { j_alu(ak, false, m, m, r); } else { j_alu(ak, false, r, r, m); }
            } else if op & 2 != 0 {
                j_addr(); j_chk(false); j_load(wb, S3);
                j_alu(ak, false, r, r, S3);
            } else if ak == 7 {
                j_addr(); j_chk(false); j_load(wb, S3);
                j_alu(ak, false, 0, S3, r);
            } else {
                j_addr(); j_chk(true); j_load(wb, S3);
                j_alu(ak, false, S4, S3, r);
                j_store(wb, S4);
            }
        },
        K_GRP1 => {
            let ak = je.reg & 7;
            if !(regs || inmem) { return 0; }
            if (ak == 2 || ak == 3) && (!wide || !j_carry_ok()) { return 0; }
            let v = if op == 0x81 { j_const(q + len - 4, 4) } else { j_const(q + len - 1, 1) };
            if !wide {
                if regs && !j_byte_ok(je.rm) {
                    // AH, CH, DH, BH: the register's second byte out, and the result back.
                    let whole = hg(je.rm - 4);
                    e(0x53083C00 | whole << 5 | S3);                 // ubfx w3, w, #8, #8
                    j_alu8(ak, false, S3, ZR, v);
                    if ak != 7 { e(0xB3781C00 | S4 << 5 | whole); }  // bfi x, x4, #8, #8
                } else if regs {
                    j_alu8(ak, false, m, ZR, v);
                    if ak != 7 { e(0xB3401C00 | S4 << 5 | m); }
                } else {
                    j_addr(); j_chk(ak != 7); j_load(8, S3);
                    j_alu8(ak, false, S3, ZR, v);
                    if ak != 7 { j_store(8, S4); }
                }
            } else if regs {
                j_alu_i(ak, m, m, v, S1);
            } else {
                j_addr(); j_chk(ak != 7); j_load(wb, S3);
                j_alu_i(ak, S4, S3, v, S2);
                if ak != 7 { j_store(wb, S4); }
            }
        },
        K_ALUA => {
            let ak = op >> 3;
            if (ak == 2 || ak == 3) && (!wide || !j_carry_ok()) { return 0; }
            if !wide {
                j_alu8(ak, false, hg(0), ZR, mem_rd(q + len - 1, 8));
                if ak != 7 { e(0xB3401C00 | S4 << 5 | hg(0)); }
            } else {
                j_alu_i(ak, hg(0), hg(0), j_const(q + len - 4, 4), S1);
            }
        },
        K_TEST => {
            if !(regs || inmem) { return 0; }
            if !wide {
                if !j_byte_ok(je.reg) || (regs && !j_byte_ok(je.rm)) { return 0; }
                if regs { j_alu8(4, true, m, r, 0); }
                else { j_addr(); j_chk(false); j_load(8, S3); j_alu8(4, true, S3, r, 0); }
            } else if regs { j_alu(4, true, 0, m, r); }
            else { j_addr(); j_chk(false); j_load(wb, S3); j_alu(4, true, 0, S3, r); }
        },
        K_TESTA => {
            if !wide { j_alu8(4, true, hg(0), ZR, mem_rd(q + len - 1, 8)); }
            else {
                a_imm(S1, j_const(q + len - 4, 4));
                j_alu(4, true, 0, hg(0), S1);
            }
        },
        K_MOV => {
            if je.p66 {
                // Sixteen bits: the rest of a register stays.
                if !wide || je.osz != 16 || !(regs || inmem) { return 0; }
                if regs {
                    if op & 2 == 0 { e(0xB3403C00 | r << 5 | m); } else { e(0xB3403C00 | m << 5 | r); }      // bfi #0, #16
                } else if op & 2 == 0 { j_addr(); j_chk(true); j_store(16, r); }
                else { j_addr(); j_chk(false); j_load(16, S3); e(0xB3403C00 | S3 << 5 | r); }
                return len;
            }
            if regs {
                if !wide { return 0; }
                if op & 2 == 0 { a_mov(sf, m, r); } else { a_mov(sf, r, m); }
            } else {
                if !inmem || (!wide && !j_byte_ok(je.reg)) { return 0; }
                if op & 2 == 0 { j_addr(); j_chk(true); j_store(wb, r); }
                else {
                    j_addr(); j_chk(false);
                    if wide { j_load(wb, r); }
                    else { j_load(8, S3); e(0xB3401C00 | S3 << 5 | r); }      // bfi xr, x3, #0, #8
                }
            }
        },
        K_LEA => {
            if regs { return 0; }
            j_lea();
            a_mov(sf, r, S1);
        },
        K_MOVZX8 => {
            if regs {
                if j_byte_ok(je.rm) { e(0x12001C00 | m << 5 | r); }          // and wr, wm, #0xFF
                else { e(0x53083C00 | hg(je.rm - 4) << 5 | r); }             // AH, CH, DH, BH: ubfx wr, w, #8, #8
            }
            else { if !inmem { return 0; } j_addr(); j_chk(false); j_load(8, r); }
        },
        K_MOVZX16 => {
            if regs { e(0x12003C00 | m << 5 | r); }          // and wr, wm, #0xFFFF
            else { if !inmem { return 0; } j_addr(); j_chk(false); j_load(16, r); }
        },
        K_MOVSX8 => {
            var from = m;
            if regs { if !j_byte_ok(je.rm) { return 0; } }
            else { if !inmem { return 0; } j_addr(); j_chk(false); j_load(8, S3); from = S3; }
            e((if sf == 1 { 0x93401C00 } else { 0x13001C00 }) | from << 5 | r);  // sxtb
        },
        K_MOVSX16 => {
            var from = m;
            if !regs { if !inmem { return 0; } j_addr(); j_chk(false); j_load(16, S3); from = S3; }
            e((if sf == 1 { 0x93403C00 } else { 0x13003C00 }) | from << 5 | r);  // sxth
        },
        K_MOVSXD => {
            var from = m;
            if !regs { if !inmem { return 0; } j_addr(); j_chk(false); j_load(32, S3); from = S3; }
            if sf == 1 { e(0x93407C00 | from << 5 | r); } else { a_mov(0, r, from); }    // sxtw
        },
        K_MOVI => {
            let low: u8 = op & 7 | (je.rex & 1) << 3;
            if op < 0xB8 {
                // One byte of a register.
                if !j_byte_ok(low) { return 0; }
                a_imm(S4, mem_rd(q + len - 1, 8));
                e(0xB3401C00 | S4 << 5 | hg(low));           // bfi
                return len;
            }
            a_imm(hg(low), if sf == 1 { mem_rd(q + len - 8, 64) } else { mem_rd(q + len - 4, 32) });
        },
        K_MOVMI => {
            if je.reg & 7 != 0 { return 0; }
            if je.p66 {
                if !wide || je.osz != 16 || !(regs || inmem) { return 0; }
                a_imm(S4, mem_rd(q + len - 2, 16));
                if regs { e(0xB3403C00 | S4 << 5 | m); } else { j_addr(); j_chk(true); j_store(16, S4); }
                return len;
            }
            if regs {
                if !wide { return 0; }
                let v = j_const(q + len - 4, 4);
                a_imm(m, if sf == 1 { v } else { v & 0xFFFFFFFF });
            } else {
                if !inmem { return 0; }
                j_addr(); j_chk(true);
                a_imm(S4, if wide { j_const(q + len - 4, 4) } else { mem_rd(q + len - 1, 8) });
                j_store(wb, S4);
            }
        },
        K_SHIFTI, K_SHIFT => {
            let which = je.reg & 7;
            if regs && wide && which < 2 {
                // ROL and ROR set CF and OF and leave the rest: translated where what they
                // set is dead (no record, and the host's flags stay the last setter's), or
                // by a constant as the first to set flags in the block.
                let bits: u32 = je.osz;
                let dead = j_flags_dead(q + len, q + room);
                if dead { j_stale = true; }
                if op == 0xD3 {
                    if !dead { return 0; }
                    var by = hg(1);
                    if which == 0 { a_rrr(A_SUB, sf, S2, ZR, hg(1)); by = S2; }      // left: right by the count's negative
                    e(0x1AC02C00 | sf << 31 | by << 16 | m << 5 | m);                 // rorv
                    return len;
                }
                let n: u32 = (if op == 0xD1 { 1 } else { mem_rd(q + len - 1, 8) & (if sf == 1 { 63 } else { 31 }) }) as! u32;
                if n == 0 || (!dead && j_set) { return 0; }
                if !dead {
                    j_needs = true;
                    a_imm(S1, n);
                    // 28h and 29h: of a register by a constant, which leaves OF unless by one.
                    j_rec((if op == 0xC1 { 0x28 } else { 0x20 }) | (which as u32), m, S1);
                    j_hf = 0;
                }
                let right: u32 = if which == 1 { n } else { bits - n };
                e((if sf == 1 { 0x93C00000 } else { 0x13800000 }) | m << 16 | right << 10 | m << 5 | m);     // ror #right
                return len;
            }
            if regs && !wide && which >= 4 && op != 0xD2 {
                // A byte shifted by a constant: on 32 bits, and the byte put back.
                if !j_byte_ok(je.rm) { return 0; }
                let n = if op == 0xD0 { 1 } else { mem_rd(q + len - 1, 8) & 0x1F };
                if n == 0 { return 0; }
                a_imm(S1, n);
                j_rec_w(0x20 | (which as u32), 8, m, S1);
                if which == 7 { e(0x13001C00 | m << 5 | S4); } else { e(0x12001C00 | m << 5 | S4); }     // sxtb, or and #0xFF
                a_shifti(which, 0, S4, S4, n as! u32);
                e(0xB3401C00 | S4 << 5 | m);                 // bfi
                j_hf = 0;
                return len;
            }
            if !regs || !wide || which < 4 { return 0; }
            let top: u64 = if sf == 1 { 63 } else { 31 };
            if op == 0xD3 {
                // By CL: by zero it changes no flag, so the record is set only if not, and
                // what was there (this block's, or none: RFLAGS in memory) stays.
                if !j_dead {
                    e((if sf == 1 { 0x92401400 } else { 0x12001000 }) | hg(1) << 5 | S1);    // and x1, xCL, #63 or #31
                    a_addi(0x71, 1, ZR, S1, 0);                  // cmp x1, #0
                    a_csel(1, FA, m, FA, C_NE);
                    a_csel(1, FB, S1, FB, C_NE);
                    a_imm(S2, 0x20 | (which as u32) | (je.osz as u32) << 8);
                    a_csel(1, FK, S2, FK, C_NE);
                    j_set = true;
                    j_dyn = true;
                }
                if j_dead { j_stale = true; }
                a_shiftv(which, sf, m, m, hg(1));
            } else {
                let n = if op == 0xD1 { 1 } else { mem_rd(q + len - 1, 8) & top };
                if n == 0 { return 0; }
                a_imm(S1, n);
                j_rec(0x20 | (which as u32), m, S1);
                a_shifti(which, sf, m, m, n as! u32);
            }
            j_hf = 0;
        },
        K_GRP3 => {
            let field = je.reg & 7;
            if field > 3 {
                // MUL, IMUL, DIV and IDIV with one operand: the operand into S3.
                if !wide || !(regs || inmem) { return 0; }
                if regs { a_mov(sf, S3, m); } else { j_addr(); j_chk(false); j_load(wb, S3); }
                let ax = hg(0);
                let dx = hg(2);
                if field < 6 {
                    j_rec(if field == 4 { 0x31 } else { 0x32 }, ax, S3);
                    if sf == 1 {
                        e((if field == 4 { 0x9BC07C00 } else { 0x9B407C00 }) | S3 << 16 | ax << 5 | S2);    // umulh, smulh
                        e(0x9B007C00 | S3 << 16 | ax << 5 | ax);                                            // mul
                        a_mov(1, dx, S2);
                    } else {
                        e((if field == 4 { 0x9BA07C00 } else { 0x9B207C00 }) | S3 << 16 | ax << 5 | S4);    // umull, smull
                        a_mov(0, ax, S4);
                        a_shifti(5, 1, dx, S4, 32);
                    }
                    j_hf = 0;
                    return len;
                }
                // The divisions leave the flags alone. They leave the block where the
                // interpreter would fault or would need the dividend's upper half.
                if sf == 1 {
                    if field == 6 { j_leave(dx, false); }
                    else {
                        a_shifti(7, 1, S1, ax, 63);
                        a_rrr(A_EOR, 1, S1, S1, dx);
                        j_leave(S1, false);
                        a_addi(0x11, 1, S1, S3, 1);
                        j_leave(S1, true);               // by -1: the one quotient that does not fit
                    }
                    j_leave(S3, true);
                    e((if field == 6 { 0x9AC00800 } else { 0x9AC00C00 }) | S3 << 16 | ax << 5 | S2);       // udiv, sdiv
                    e(0x9B008000 | S3 << 16 | ax << 10 | S2 << 5 | dx);                                     // msub: the remainder
                    a_mov(1, ax, S2);
                } else {
                    if field == 7 { e(0x93407C00 | S3 << 5 | S3); }                  // sxtw: the divisor's sign
                    j_leave(S3, true);
                    a_mov(0, S4, ax);
                    e(0xAA008000 | dx << 16 | S4 << 5 | S4);                         // orr x4, x4, xDX, lsl #32
                    e((if field == 6 { 0x9AC00800 } else { 0x9AC00C00 }) | S3 << 16 | S4 << 5 | S2);
                    // The quotient must fit 32 bits: unsigned, or with its sign.
                    if field == 6 { a_shifti(5, 1, S1, S2, 32); }
                    else { e(0x93407C00 | S2 << 5 | S1); a_rrr(A_EOR, 1, S1, S1, S2); }
                    j_leave(S1, false);
                    e(0x9B008000 | S3 << 16 | S4 << 10 | S2 << 5 | S1);              // msub
                    a_mov(0, ax, S2);
                    a_mov(0, dx, S1);
                }
                return len;
            }
            if !wide {
                // TEST of a byte with a constant.
                if field > 1 || !(regs || inmem) { return 0; }
                let v = mem_rd(q + len - 1, 8);
                if !regs { j_addr(); j_chk(false); j_load(8, S3); j_alu8(4, true, S3, ZR, v); }
                else if j_byte_ok(je.rm) { j_alu8(4, true, m, ZR, v); }
                else { e(0x53083C00 | hg(je.rm - 4) << 5 | S3); j_alu8(4, true, S3, ZR, v); }       // AH, CH, DH, BH
                return len;
            }
            if !regs || !wide { return 0; }
            if field < 2 {
                a_imm(S1, j_const(q + len - 4, 4));
                j_alu(4, true, 0, m, S1);
            } else if field == 2 {
                e(0x2A2003E0 | sf << 31 | m << 16 | m);      // mvn
            } else {
                j_rec(6, ZR, m);
                a_rrr(A_SUBS, sf, m, ZR, m);                 // negs
                j_hf = HF_SUB;
            }
        },
        K_GRP5 => {
            let field = je.reg & 7;
            if field == 2 || field == 4 {
                // CALL and JMP through an operand: the operand is read before anything is pushed.
                if op != 0xFF || !stack || !(regs || inmem) { return 0; }
                if regs { a_mov(1, S4, m); } else { j_addr(); j_chk(false); j_load(64, S4); }
                if field == 2 {
                    a_addi(0x51, 1, S1, hg(4), 8);
                    j_chk(true);
                    j_rip(S3, off + len);
                    j_store(64, S3);
                    a_addi(0x51, 1, hg(4), hg(4), 8);
                }
                j_exit_to(S4, cnt + 1);
                j_end = true;
                j_stop = field == 4;
                return len;
            }
            if !regs || !wide || field > 1 { return 0; }
            // INC and DEC leave CF as it was. Where their flags are dead, nothing is made
            // of them (and the host's flags stay the last setter's); else only as the
            // block's first to set flags.
            if j_flags_dead(q + len, q + room) {
                a_addi(if field == 0 { 0x11 } else { 0x51 }, sf, m, m, 1);
                j_stale = true;
                return len;
            }
            if j_set { return 0; }
            j_needs = true;
            j_rec(16 + (field as u32), m, ZR);
            a_addi(if field == 0 { 0x31 } else { 0x71 }, sf, m, m, 1);
            j_hf = HF_INCDEC;
        },
        K_IMUL2 => {
            var from = m;
            if !regs { if !inmem { return 0; } j_addr(); j_chk(false); j_load(je.osz, S3); from = S3; }
            j_rec(0x30, r, from);
            e(0x1B007C00 | sf << 31 | from << 16 | r << 5 | r);  // mul
            j_hf = 0;
        },
        K_IMUL3 => {
            var from = m;
            if !regs { if !inmem { return 0; } j_addr(); j_chk(false); j_load(je.osz, S3); from = S3; }
            a_imm(S4, if op == 0x69 { j_const(q + len - 4, 4) } else { j_const(q + len - 1, 1) });
            j_rec(0x30, from, S4);
            e(0x1B007C00 | sf << 31 | S4 << 16 | from << 5 | r);
            j_hf = 0;
        },
        K_PUSH => {
            if !stack { return 0; }
            j_push(hg(op & 7 | (je.rex & 1) << 3));
        },
        K_PUSHI => {
            if !stack { return 0; }
            a_imm(S4, if op == 0x6A { j_const(q + len - 1, 1) } else { j_const(q + len - 4, 4) });
            j_push(S4);
        },
        K_POP => {
            if !stack { return 0; }
            a_mov(1, S1, hg(4));
            j_chk(false);
            j_load(64, S3);
            a_addi(0x11, 1, hg(4), hg(4), 8);
            a_mov(1, hg(op & 7 | (je.rex & 1) << 3), S3);
        },
        K_CALL => {
            if !stack { return 0; }
            a_addi(0x51, 1, S1, hg(4), 8);
            j_chk(true);
            j_rip(S3, off + len);
            j_store(64, S3);
            a_addi(0x51, 1, hg(4), hg(4), 8);
            j_exit(off + len + j_const(q + len - 4, 4), cnt + 1, true);
            j_end = true;
        },
        K_RET => {
            if !stack { return 0; }
            a_mov(1, S1, hg(4));
            j_chk(false);
            j_load(64, S3);
            a_addi(0x11, 1, hg(4), hg(4), 8);
            j_exit_to(S3, cnt + 1);
            j_end = true;
            j_stop = true;
        },
        K_CONV => {
            if op == 0x98 { e((if sf == 1 { 0x93407C00 } else { 0x13003C00 }) | hg(0) << 5 | hg(0)); }
            else { a_shifti(7, sf, hg(2), hg(0), if sf == 1 { 63 } else { 31 }); }
        },
        K_NOP, K_NOPM => {},
        K_JMP8, K_JMP32 => {
            let d = if k == K_JMP8 { j_const(q + len - 1, 1) } else { j_const(q + len - 4, 4) };
            j_exit(off + len + d, cnt + 1, true);
            j_end = true;
            j_stop = true;
        },
        _ => { return 0; },
    }
    return len;
}

// Forgets every block: the room for code is full.
fn jit_flush() {
    for slot in DC_SIZE {
        if dc_n[slot] != 0 { dc[slot].ins.kind = dc_k0[slot]; dc_n[slot] = 0; }
        dc_wait[slot] = 0;
        // Arrivals are counted from nothing again: a count left at its top would never
        // come to J_HOT, and what was translated before would be interpreted for good.
        dc_heat[slot] = 0;
    }
    for i in MEM_SIZE >> 12 { jit_page[i] = 0; }
    lk_n = 0;
    j_used = j_keep;
    j_flushes += 1;
}

// Translates what begins at physical address ph, and what follows it on the page: a block
// to a jump or to an instruction that is not translated, then the next block after that
// instruction or at the jump's other side, as far as the decode cache knows the
// instructions.
fn jit_translate(ph: u64) {
    var q = ph;
    let page_end = (ph | 0xFFF) + 1;
    var walked = 0;
    while walked < 200 && q < page_end {
        let head = q;
        let head_slot = dc_slot(head);
        if dc[head_slot].tag != head || dc_n[head_slot] != 0 { return; }
        jc = [];
        j_hf = 0;
        j_set = false;
        j_dyn = false;
        j_end = false;
        j_stop = false;
        so_n = 0;
        sk_live = false;
        ss_n = 0;
        j_stale = false;
        tp_n = 0;
        j_head = head;
        j_needs = false;
        // What an entry from another block needs: time for the whole block, no record
        // waiting if the block reads RFLAGS in memory, and RIP.
        e(0);                                // cmp x0, #n: filled in below
        e(0x54000083);                       // b.lo to the branch out
        e(0xD503201F);                       // nop, or cbnz x7 to the branch out
        a_mov(1, RIPB, S1);
        e(0x14000002);                       // b the body
        e(0x14000000 | (((j_out_at - (j_used + jc.len)) >> 2) as! u32) & 0x3FFFFFF);
        var n = 0;
        while n < J_MAX {
            if !j_entry(q) { break; }
            let len = j_one(q, q - head, page_end - q, n as! u64);
            if len == 0 { break; }
            q += len;
            n += 1;
            if j_end { break; }
        }
        // One instruction is worth a block where blocks are entered from one another.
        if n >= J_MIN || (n == 1 && !jit_check) {
            if sk_live { j_sink_flush(); }
            if !j_end { j_exit(q - head, n as! u64, true); }
            // The ways out, behind the block.
            for i in so_n {
                let at = so_pos[i];
                e_at(at, so_op[i] | (((jc.len - at) >> 2) as! u32) << 5);
                j_stale = so_stale[i];
                if so_how[i] != 0 { j_sink_emit(so_how[i], so_ska[i], so_skb[i], so_ski[i], so_skw[i]); }
                j_exit(so_off[i], so_cnt[i], so_link[i]);
            }
            if j_used + jc.len + 64 > J_SIZE { jit_flush(); return; }
            e_at(0, 0xF100001F | (n as! u32) << 10);         // cmp x0, #n
            if j_needs { e_at(8, 0xB5000067); }              // cbnz x7, three on
            if !j_needs {
                for i in ss_n {
                    let at = ss_pos[i];
                    e_at(at, 0xF100001F | (n as! u32) << 10);                                        // cmp x0, #n
                    e_at(at + 4, 0x54000002 | ((((BODY_AT - (at + 4)) >> 2) as! u32) & 0x7FFFF) << 5);    // b.hs the body
                }
            }
            jit_write(j_mem + j_used, jc[..]);
            // The exits that wait for a block, by the address they wait for; and the ones
            // that waited for this.
            for i in tp_n {
                if lk_n + 1 >= LK_MAX { break; }
                let ws = dc_slot(tp_to[i]);
                lk_site[lk_n] = j_used + tp_pos[i];
                lk_to[lk_n] = tp_to[i];
                lk_cpl[lk_n] = cpl;
                lk_next[lk_n] = dc_wait[ws];
                lk_n += 1;
                dc_wait[ws] = lk_n as! u32;
            }
            var w = dc_wait[head_slot];
            dc_wait[head_slot] = 0;
            while w != 0 {
                let i = (w - 1) as! i64;
                if lk_to[i] == head && lk_cpl[i] == cpl { j_patch(lk_site[i], j_used); }
                w = lk_next[i];
            }
            jit_page[(head >> 12) as! i64] = 1;
            dc_code[head_slot] = j_used as! u32;
            dc_n[head_slot] = n as! u8;
            dc_cpl[head_slot] = cpl;
            dc_k0[head_slot] = dc[head_slot].ins.kind;
            dc[head_slot].ins.kind = 0;
            j_used += jc.len;
            j_blocks += 1;
        }
        walked += n + 1;
        if j_stop { return; }
        if j_end || n > 0 { continue; }
        // The instruction at q is not translated, even first in a block: on behind it,
        // unless it goes somewhere else for good.
        if !j_entry(q) { return; }
        let len = j_len();
        if len == 0 || jk == K_RET || jk == K_JMP8 || jk == K_JMP32 || (jk == K_GRP5 && je.reg & 7 == 4) { return; }
        q += len;
    }
}

// A jump has arrived at RIP: counted, and translated at the J_HOT-th.
fn jit_arrive() {
    if rip >> 12 != code_page || cpl != code_cpl { return; }
    let ph = rip - code_delta;
    let slot = dc_slot(ph);
    if dc[slot].tag != ph || dc_n[slot] != 0 { return; }
    if dc_heat[slot] < 255 { dc_heat[slot] += 1; }
    if dc_heat[slot] == J_HOT { jit_translate(ph); }
}

// The flags of the record a block left.
fn j_settle() {
    let fk = jx[3];
    if fk == 0 { return; }
    let w = (fk >> 8) as! u8;
    let what = (fk & 0xFF) as! u8;
    if what == 3 || what == 4 {
        // ADC and SBB: with the carry that went in.
        rflags = rflags & ~CF | fk >> 16 & 1;
        alu(what - 1, jx[1], jx[2], w);
    }
    else if what <= 8 { alu(what - 1, jx[1], jx[2], w); }
    else if what == 16 { incdec(false, jx[1], w); }
    else if what == 17 { incdec(true, jx[1], w); }
    else if what == 0x30 { imul2(jx[1], jx[2], w); }
    else if what == 0x31 || what == 0x32 {
        // MUL and IMUL with one operand: as muldiv has them.
        let a = jx[1];
        let b = jx[2];
        let m = mask(w);
        var lo: u64 = 0;
        var over = false;
        if w == 64 {
            if what == 0x31 { let hi, l = mul64(a, b); lo = l; over = hi != 0; }
            else { let hi, l = imul64(a, b); lo = l; over = hi != ones(l >> 63 != 0); }
        } else if what == 0x31 {
            let full = (a & m) * (b & m);
            lo = full & m;
            over = full >> w & m != 0;
        } else {
            let full = sx(a & m, w) * sx(b & m, w);
            lo = full & m;
            over = sx(lo, w) != full;
        }
        mul_flags(over, lo, w);
    }
    else if what == 0x28 || what == 0x29 { shift(what & 7, jx[1], jx[2], w, true); }
    else if what == 0x40 || what == 0x41 { sse64_comis(what == 0x40, jx[1], jx[2]); }
    else { shift(what & 7, jx[1], jx[2], w, false); }
}

// Runs the block whose first instruction is the one at hand (dc_cur). False if it may not
// be run now: the instruction is then interpreted.
fn jit_enter() -> bool {
    let slot = dc_cur;
    let n: u64 = dc_n[slot];
    if jit_hold || steps + n > rep_until || dc_cpl[slot] != cpl { return false; }
    jx[17] = fs_base;
    jx[18] = gs_base;
    if jit_check { return jit_both(slot, n); }
    jx[0] = rflags;
    let time = rep_until - steps;
    jx[9] = time;
    jit_call4(j_mem, j_regs, j_ctx, j_mem + dc_code[slot] + BODY_AT, rip as! i64);
    let ran = time - jx[9];
    // Left before its first instruction: that one is interpreted.
    if ran == 0 { return false; }
    rip = jx[4];
    j_settle();
    // Where the block went is an arrival like any jump's: counted, or nothing after a
    // block would ever be translated.
    jit_arrive();
    steps += ran - 1;
    j_entered += 1;
    j_ran += ran;
    return true;
}

// --jit-check: the block is run, what it left is kept, and the state is put back; the same
// instructions are then interpreted, one at a time by the run loop (g64m.goose), with no
// block entered, and jit_tick compares when the last is done. They touch no memory, so the
// registers, RFLAGS and RIP are all there is to compare.
var jit_left: u64 = 0;       // instructions of the block being checked still to interpret
var jv_n: u64 = 0;
var jv_ip0: u64 = 0;
var jv_ip: u64 = 0;
var jv_flags: u64 = 0;
var jv_reg: u64[16] = [0; 16];
var jv_xmm: u64[32] = [0; 32];
var jv_stale = false;         // the block left with flags it made no record of: not compared
var jv_stores = 0;           // how many stores the block made, and what each left
var jv_new: u64[128] = [0; 128];

fn jit_both(slot: i64, n: u64) -> bool {
    var r0: u64[16] = [0; 16];
    var x0: u64[32] = [0; 32];
    for i in 16 { r0[i] = reg[i]; }
    for i in 32 { x0[i] = xmm[i]; }
    let f0 = rflags;
    jx[0] = rflags;
    jx[7] = 0;
    jx[9] = n;
    jit_call4(j_mem, j_regs, j_ctx, j_mem + dc_code[slot] + BODY_AT, rip as! i64);
    let ran = n - jx[9];
    if ran == 0 { return false; }
    j_settle();
    // What the block stored is kept and taken back, last store first.
    jv_stores = jx[7] as! i64;
    for i in jv_stores { jv_new[i] = mem_rd(jlog[i * 2], 64); }
    for k in jv_stores {
        let i = jv_stores - 1 - k;
        mem_put(jlog[i * 2] as! i64, 64, jlog[i * 2 + 1]);
    }
    for i in 16 { jv_reg[i] = reg[i]; reg[i] = r0[i]; }
    for i in 32 { jv_xmm[i] = xmm[i]; xmm[i] = x0[i]; }
    jv_flags = rflags;
    jv_stale = jx[15] != 0;
    jv_ip = jx[4];
    jv_ip0 = rip;
    jv_n = ran;
    rflags = f0;
    jit_hold = true;
    jit_left = ran;
    attn = true;             // the run (E106) stops after this instruction
    j_entered += 1;
    j_ran += ran;
    return false;
}

// One instruction of the block being checked has been interpreted.
fn jit_tick() {
    jit_left -= 1;
    if jit_left != 0 { return; }
    jit_hold = false;
    var bad = rip != jv_ip || (!jv_stale && rflags != jv_flags);
    for i in 16 { if reg[i] != jv_reg[i] { bad = true; } }
    var bad_xmm = -1;
    for i in 32 { if xmm[i] != jv_xmm[i] { bad = true; bad_xmm = i; } }
    var bad_at: u64 = 0;
    for i in jv_stores {
        if mem_rd(jlog[i * 2], 64) != jv_new[i] { bad = true; bad_at = jlog[i * 2]; }
    }
    if !bad { return; }
    var msg: u8[>..] = [];
    format(msg, "g64m: --jit-check: a block of ", jv_n as! i64, " at ");
    hex64(msg, jv_ip0);
    format(msg, " differs: RIP ");
    hex64(msg, jv_ip);
    format(msg, " for ");
    hex64(msg, rip);
    format(msg, ", RFLAGS ");
    hex64(msg, jv_flags);
    format(msg, " for ");
    hex64(msg, rflags);
    for i in 16 {
        if reg[i] != jv_reg[i] {
            format(msg, ", register ", i, " ");
            hex64(msg, jv_reg[i]);
            format(msg, " for ");
            hex64(msg, reg[i]);
        }
    }
    if bad_at != 0 { format(msg, ", memory at "); hex64(msg, bad_at); }
    if bad_xmm >= 0 { format(msg, ", XMM word ", bad_xmm, " "); hex64(msg, jv_xmm[bad_xmm]); format(msg, " for "); hex64(msg, xmm[bad_xmm]); }
    format(msg, "\n");
    write_stderr(msg);
    exit(3);
}
