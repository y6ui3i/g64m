// The 64-bit CPU (M10, E091): sixteen 64-bit registers, RIP and RFLAGS, in long mode's
// 64-bit code and at privilege level 3. Nothing here is shared with the 32-bit machine of
// exec.goose; x64.goose is the root file that uses this one.
//
// What is here so far is what runs a program in user mode: the integer instructions a
// compiler emits. A list, by first byte:
//   00-3F the eight arithmetic operations; 50-5F PUSH and POP; 63 MOVSXD; 68 6A PUSH of a
//   constant; 69 6B IMUL; 70-7F Jcc; 80 81 83; 84 85 TEST; 86 87 XCHG; 88-8B MOV; 8D LEA;
//   8F POP; 90-97; 98 99; 9C 9D PUSHF POPF; 9E 9F; A0-A3; A4-A7 AA-AF the strings, with REP;
//   A8 A9; B0-BF; C0 C1 D0-D3 shifts and rotates; C2 C3 RET; C6 C7; C9 LEAVE; E0-E3; E8 E9
//   EB; F5 F8 F9 FC FD; F6 F7; FE FF.
//   0F: 05 SYSCALL; 0B UD2; 0D 18-1F (no operation); 31 RDTSC; 40-4F CMOVcc; 80-8F Jcc;
//   90-9F SETcc; A2 CPUID; A3 AB B3 BB BA the bit tests; A4 A5 AC AD SHLD SHRD; AF IMUL;
//   B0 B1 CMPXCHG; B6 B7 BE BF MOVZX MOVSX; B8 POPCNT; BC BD BSF BSR; C0 C1 XADD; C7
//   CMPXCHG8B and 16B; C8-CF BSWAP.
// SSE and SSE2 are in sse64.goose (0F 10-17, 28-2F, 50-7F, AE, C2-C6, D0-FF).
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
import x64;
import sse64;
import sys64;

let MEM_SIZE = 67108864;        // 64 MB

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
var seg_base: u64 = 0;
var rex: u8 = 0;                // the REX prefix, 0 for none
var osz: u8 = 32;               // the operand size where it is not a byte: 16, 32 or 64
var rep: u8 = 0;                // F2h, F3h or 0
var m_mod: u8 = 0;
var m_reg: u8 = 0;
var m_rm: u8 = 0;
var p66 = false;
var asz32 = false;

var halted = false;
var stopped = false;
var faulted = false;
var exit_code: i64 = 0;

var mem: u8[MEM_SIZE];

// ---- Stopping ----

// Ends the run where an instruction cannot be done: not written yet, or a fault that
// nothing delivers yet. The registers are left as they are; RIP is the instruction's start.
fn stop64(what: const u8[:], v: u64) {
    var msg: u8[>..] = [];
    format(msg, "x64: ", what, " ");
    format_int(msg, v as! i64, 16, 2, '0');
    format(msg, " at ");
    format_int(msg, rip as! i64, 16, 8, '0');
    format(msg, "  bytes:");
    for i in 12 {
        let a = rip + (i as! u64);
        if a < MEM_SIZE { format(msg, " "); format_int(msg, mem[a], 16, 2, '0'); }
    }
    format(msg, "\n");
    write_stderr(msg);
    stopped = true;
    faulted = true;
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
fn mem_rd(a: u64, w: u8) -> u64 {
    let i = a as! i64;
    let b0: u64 = mem[i];
    if w == 8 { return b0; }
    let b1: u64 = mem[i + 1];
    if w == 16 { return b0 | b1 << 8; }
    let b2: u64 = mem[i + 2];
    let b3: u64 = mem[i + 3];
    let lo = b0 | b1 << 8 | b2 << 16 | b3 << 24;
    if w == 32 { return lo; }
    let b4: u64 = mem[i + 4];
    let b5: u64 = mem[i + 5];
    let b6: u64 = mem[i + 6];
    let b7: u64 = mem[i + 7];
    return lo | b4 << 32 | b5 << 40 | b6 << 48 | b7 << 56;
}

fn mem_wr(a: u64, w: u8, v: u64) {
    let i = a as! i64;
    mem[i] = v as! u8;
    if w == 8 { return; }
    mem[i + 1] = (v >> 8) as! u8;
    if w == 16 { return; }
    mem[i + 2] = (v >> 16) as! u8;
    mem[i + 3] = (v >> 24) as! u8;
    if w == 32 { return; }
    mem[i + 4] = (v >> 32) as! u8;
    mem[i + 5] = (v >> 40) as! u8;
    mem[i + 6] = (v >> 48) as! u8;
    mem[i + 7] = (v >> 56) as! u8;
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

// ---- Fetching ----

fn fb() -> u64 { let v = rd(ip, 8); ip += 1; return v; }
fn fw() -> u64 { let v = rd(ip, 16); ip += 2; return v; }
fn fd() -> u64 { let v = rd(ip, 32); ip += 4; return v; }
fn fq() -> u64 { let v = rd(ip, 64); ip += 8; return v; }
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
        if rex == 0 && i >= 4 && i < 8 { return reg[i - 4] >> 8 & 0xFF; }
        return reg[i] & 0xFF;
    }
    return reg[i] & mask(w);
}

// A 32-bit result clears the register's upper half; 8 and 16-bit results leave the rest.
fn sr(i: u8, w: u8, v: u64) {
    if w == 64 { reg[i] = v; }
    else if w == 32 { reg[i] = v & 0xFFFFFFFF; }
    else if w == 16 { reg[i] = reg[i] & 0xFFFFFFFFFFFF0000 | v & 0xFFFF; }
    else if rex == 0 && i >= 4 && i < 8 { reg[i - 4] = reg[i - 4] & 0xFFFFFFFFFFFF00FF | (v & 0xFF) << 8; }
    else { reg[i] = reg[i] & 0xFFFFFFFFFFFFFF00 | v & 0xFF; }
}

// ---- The ModRM byte ----

// Reads the ModRM byte and what belongs to it. after is how many bytes of the instruction
// come after the operand (a constant): an address relative to RIP is relative to the end of
// the whole instruction.
fn modrm(after: u64) {
    let b = fb() as! u8;
    m_mod = b >> 6;
    m_reg = b >> 3 & 7 | (rex & 4) << 1;
    m_rm = b & 7;
    if m_mod == 3 { m_rm |= (rex & 1) << 3; return; }
    var a: u64 = 0;
    if m_rm == 4 {
        let s = fb() as! u8;
        let base = s & 7 | (rex & 1) << 3;
        let index = s >> 3 & 7 | (rex & 2) << 2;
        let scale: u64 = s >> 6;
        if index != 4 { a = reg[index] << scale; }
        if s & 7 == 5 && m_mod == 0 { let d = fs32(); a += d; } else { a += reg[base]; }
    } else if m_rm == 5 && m_mod == 0 {
        let d = fs32();
        a = ip + after + d;
    } else {
        a = reg[m_rm | (rex & 1) << 3];
    }
    if m_mod == 1 { let d = fs8(); a += d; } else if m_mod == 2 { let d = fs32(); a += d; }
    if asz32 { a &= 0xFFFFFFFF; }
    m_off = a;
    m_ea = a + seg_base;
}

fn rm_get(w: u8) -> u64 {
    if m_mod == 3 { return gr(m_rm, w); }
    return rd(m_ea, w);
}

fn rm_set(w: u8, v: u64) {
    if m_mod == 3 { sr(m_rm, w, v); } else { wr(m_ea, w, v); }
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

// The 128-bit product of two 64-bit numbers: the upper half, then the lower.
fn mul64(a: u64, b: u64) -> u64, u64 {
    let al = a & 0xFFFFFFFF;
    let ah = a >> 32;
    let bl = b & 0xFFFFFFFF;
    let bh = b >> 32;
    let ll = al * bl;
    let lh = al * bh;
    let hl = ah * bl;
    let mid = (ll >> 32) + (lh & 0xFFFFFFFF) + (hl & 0xFFFFFFFF);
    return ah * bh + (lh >> 32) + (hl >> 32) + (mid >> 32), (mid << 32) | (ll & 0xFFFFFFFF);
}

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
inline fn ssz() -> u8 { return if p66 { 16 } else { 64 }; }

// ---- The strings ----

// One repetition of a string instruction; with REP, RIP stays on the instruction until the
// count runs out, as on a CPU, where something may come in between two repetitions. Until
// the last one RF is set, as it is in what such an interruption saves; and the flags of a
// repeated CMPS or SCAS are not to be seen until the last one either: between two
// repetitions the CPU shows the flags the instruction began with.
fn string_op(op: u8) -> u64 {
    let w: u8 = if op & 1 == 0 { 8 } else { osz };
    let n: u64 = w / 8;
    let am: u64 = if asz32 { 0xFFFFFFFF } else { 0xFFFFFFFFFFFFFFFF };
    if rep != 0 && reg[RCX] & am == 0 { return ip; }
    let began = rflags;
    let step = if flag(DF) { 0 - n } else { n };
    let si = reg[RSI] & am;
    let di = reg[RDI] & am;
    var uses_si = false;
    var uses_di = false;
    var compares = false;
    match op & 0xFE {
        0xA4 => { wr(di, w, rd(si + seg_base, w)); uses_si = true; uses_di = true; },
        0xA6 => { let a = rd(si + seg_base, w); let b = rd(di, w); alu(7, a, b, w); uses_si = true; uses_di = true; compares = true; },
        0xAA => { wr(di, w, reg[RAX]); uses_di = true; },
        0xAC => { sr(RAX, w, rd(si + seg_base, w)); uses_si = true; },
        _ => { alu(7, reg[RAX], rd(di, w), w); uses_di = true; compares = true; },
    }
    if uses_si { if asz32 { reg[RSI] = (si + step) & am; } else { reg[RSI] = si + step; } }
    if uses_di { if asz32 { reg[RDI] = (di + step) & am; } else { reg[RDI] = di + step; } }
    if rep == 0 { return ip; }
    let left = (reg[RCX] - 1) & am;
    if asz32 { reg[RCX] = left; } else { reg[RCX] = left; }
    if left == 0 { return ip; }
    if compares && flag(ZF) != (rep == 0xF3) { return ip; }
    rflags = began | RF;
    return rip;
}

// ---- Bits ----

fn bit_op(kind: u8, w: u8, off: u64, from_reg: bool) {
    let bits: u64 = w;
    var a = m_ea;
    if m_mod != 3 && from_reg {
        // A register's bit number reaches outside the operand: it is a signed number of bits
        // from the operand's address.
        let o = sx(off, w);
        var words = o >> (if w == 16 { 4 } else if w == 32 { 5 } else { 6 });
        if o >> 63 != 0 { words |= 0xFFFFFFFFFFFFFFFF << (if w == 16 { 60 } else if w == 32 { 59 } else { 58 }); }
        a += words * (bits / 8);
    }
    let v = if m_mod == 3 { gr(m_rm, w) } else { rd(a, w) };
    let bit: u64 = 1 << (off & (bits - 1));
    set_flag(CF, v & bit != 0);
    var r = v;
    match kind {
        0 => { return; },
        1 => { r = v | bit; },
        2 => { r = v & ~bit; },
        _ => { r = v ^ bit; },
    }
    if m_mod == 3 { sr(m_rm, w, r); } else { wr(a, w, r); }
}

// The instructions that touch ports and the interrupt flag need IOPL to allow the current
// privilege level; a user-mode program has neither.
fn io_level() {
    if !machine { stop64("an instruction of a machine in a user-mode program, at privilege level", 3); }
    if cpl > (rflags >> 12 & 3) { fault(13, true, 0); }
}

// ---- CPUID ----

fn cpuid() {
    let leaf = reg[RAX] & 0xFFFFFFFF;
    var a: u64 = 0;
    var b: u64 = 0;
    var c: u64 = 0;
    var d: u64 = 0;
    if leaf == 0 { a = 1; b = 0x756E6547; d = 0x49656E69; c = 0x6C65746E; }      // "GenuineIntel"
    else if leaf == 1 { a = 0x000306A9; d = 0x06008111; c = 0x00800000; }        // FPU TSC CX8 CMOV SSE SSE2; POPCNT
    else if leaf == 0x80000000 { a = 0x80000001; }
    else if leaf == 0x80000001 { d = 0x20000800; c = 1; }                        // long mode, SYSCALL; LAHF
    reg[RAX] = a; reg[RBX] = b; reg[RCX] = c; reg[RDX] = d;
}

// ---- One instruction ----

// Runs the instruction at RIP. False if the run stopped in it.
fn exec64() -> bool {
    if machine {
        if pending >= 0 { deliver_pending(); return true; }
        save_start();
        // The first byte's page must be one that may be executed.
        xlate(rip, ACC_EXEC);
    }
    ip = rip;
    rex = 0;
    rep = 0;
    p66 = false;
    asz32 = false;
    seg_base = 0;
    var op: u8 = 0;
    while true {
        op = fb() as! u8;
        if op & 0xF0 == 0x40 { rex = op; continue; }
        match op {
            0x66 => { p66 = true; },
            0x67 => { asz32 = true; },
            0xF2, 0xF3 => { rep = op; },
            0xF0, 0x26, 0x2E, 0x36, 0x3E => {},
            0x64 => { seg_base = fs_base; },
            0x65 => { seg_base = gs_base; },
            _ => { break; },
        }
        // A REX prefix counts only when it is the last prefix.
        rex = 0;
    }
    osz = if rex & 8 != 0 { 64 } else if p66 { 16 } else { 32 };
    let w: u8 = if op & 1 == 0 { 8 } else { osz };
    let low: u8 = op & 7 | (rex & 1) << 3;         // the register in the opcode's low bits
    var next: u64 = 0;                             // where to go, when not to the next instruction
    var jump = false;
    rflags &= ~RF;

    if op < 0x40 && op & 7 < 6 {
        let k = op >> 3;
        if op & 7 < 4 {
            modrm(0);
            if op & 2 == 0 {
                let r = alu(k, rm_get(w), gr(m_reg, w), w);
                if k != 7 { rm_set(w, r); }
            } else {
                let r = alu(k, gr(m_reg, w), rm_get(w), w);
                if k != 7 { sr(m_reg, w, r); }
            }
        } else {
            let r = alu(k, gr(RAX, w), fimm(w), w);
            if k != 7 { sr(RAX, w, r); }
        }
    } else if op == 0x0F {
        let op2 = fb() as! u8;
        let w2: u8 = if op2 & 1 == 0 { 8 } else { osz };
        if sse64_is(op2) { sse64_op(op2); rip = ip; return true; }
        match op2 >> 4 {
            0x0 => {
                if op2 == 0x05 {
                    if machine { stop64("SYSCALL in a machine, which is not written yet, 0F", op2); }
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
                else if op2 == 0x06 { need_level0(); cr0 &= ~8; }                    // CLTS
                else if op2 == 0x08 || op2 == 0x09 { need_level0(); }                // INVD, WBINVD
                else { stop64("an instruction not written yet, 0F", op2); }
            },
            0x2 => {
                // MOV to and from the control registers (CR8 by REX.R) and the debug registers,
                // which read as zero and keep nothing.
                if !machine { stop64("an instruction not written yet, 0F", op2); }
                need_level0();
                modrm(0);
                match op2 {
                    0x20 => { reg[m_rm | (rex & 1) << 3] = cr_get(m_reg); },
                    0x22 => { cr_set(m_reg, reg[m_rm | (rex & 1) << 3]); },
                    0x21 => { reg[m_rm | (rex & 1) << 3] = 0; },
                    0x23 => {},
                    _ => { stop64("an instruction not written yet, 0F", op2); },
                }
            },
            0x1 => {
                if op2 >= 0x18 { modrm(0); }
                else { stop64("an instruction not written yet, 0F", op2); }
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
            0x4 => {
                modrm(0);
                let v = rm_get(osz);
                // With a 32-bit operand the upper half is cleared whether it moves or not.
                if cond(op2 & 15) { sr(m_reg, osz, v); } else if osz == 32 { sr(m_reg, 32, gr(m_reg, 32)); }
            },
            0x8 => {
                let d = fs32();
                if cond(op2 & 15) { next = ip + d; jump = true; }
            },
            0x9 => {
                modrm(0);
                rm_set(8, if cond(op2 & 15) { 1 } else { 0 });
            },
            0xA => {
                match op2 {
                    0xA2 => { cpuid(); },
                    0xA0 => { push(seg[SEG_FS], ssz()); },
                    0xA8 => { push(seg[SEG_GS], ssz()); },
                    0xA1 => { let v = pop(ssz()); seg_load(SEG_FS, v); },
                    0xA9 => { let v = pop(ssz()); seg_load(SEG_GS, v); },
                    0xA3 => { modrm(0); bit_op(0, osz, gr(m_reg, osz), true); },
                    0xAB => { modrm(0); bit_op(1, osz, gr(m_reg, osz), true); },
                    0xA4, 0xAC => {
                        modrm(1);
                        let n = fb();
                        rm_set(osz, shift_double(op2 == 0xA4, rm_get(osz), gr(m_reg, osz), n, osz));
                    },
                    0xA5, 0xAD => {
                        modrm(0);
                        rm_set(osz, shift_double(op2 == 0xA5, rm_get(osz), gr(m_reg, osz), reg[RCX] & 0xFF, osz));
                    },
                    0xAF => { modrm(0); sr(m_reg, osz, imul2(gr(m_reg, osz), rm_get(osz), osz)); },
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
                        if flag(ZF) { rm_set(w2, gr(m_reg, w2)); }
                        else { rm_set(w2, cur); sr(RAX, w2, cur); }
                    },
                    0xB3 => { modrm(0); bit_op(2, osz, gr(m_reg, osz), true); },
                    0xBB => { modrm(0); bit_op(3, osz, gr(m_reg, osz), true); },
                    0xB6, 0xB7 => { modrm(0); sr(m_reg, osz, rm_get(if op2 == 0xB6 { 8 } else { 16 })); },
                    0xBE => { modrm(0); sr(m_reg, osz, sx(rm_get(8), 8)); },
                    0xBF => { modrm(0); sr(m_reg, osz, sx(rm_get(16), 16)); },
                    0xBA => {
                        modrm(1);
                        let n = fb();
                        if m_reg & 7 < 4 { stop64("an instruction not written yet, 0F BA field", m_reg); }
                        bit_op(m_reg & 3, osz, n, false);
                    },
                    0xB8 => {
                        if rep != 0xF3 { stop64("an instruction not written yet, 0F", op2); }
                        modrm(0);
                        var v = rm_get(osz);
                        var n: u64 = 0;
                        while v != 0 { n += v & 1; v = v >> 1; }
                        sr(m_reg, osz, n);
                        rflags = rflags & ~ARITH | (if n == 0 { ZF } else { 0 });
                    },
                    0xBC, 0xBD => {
                        // BSF and BSR. Of a zero the register is left as it was, upper half
                        // and all. (F3h in front makes no difference on a CPU without TZCNT
                        // and LZCNT.)
                        modrm(0);
                        let v = rm_get(osz);
                        if v == 0 {
                            rflags = rflags & ~ARITH | ZF | PF;
                        } else {
                            var n: u64 = 0;
                            if op2 == 0xBC { while v >> n & 1 == 0 { n += 1; } }
                            else { n = osz - 1; while v >> n & 1 == 0 { n -= 1; } }
                            sr(m_reg, osz, n);
                            rflags = rflags & ~ARITH | PARITY[n];
                        }
                    },
                    _ => { stop64("an instruction not written yet, 0F", op2); },
                }
            },
            0xC => {
                if op2 >= 0xC8 {
                    let i = op2 & 7 | (rex & 1) << 3;
                    let v = reg[i];
                    if osz == 64 {
                        reg[i] = v >> 56 | (v >> 40 & 0xFF00) | (v >> 24 & 0xFF0000) | (v >> 8 & 0xFF000000)
                            | (v << 8 & 0xFF00000000) | (v << 24 & 0xFF0000000000) | (v << 40 & 0xFF000000000000) | v << 56;
                    } else {
                        reg[i] = (v >> 24 & 0xFF) | (v >> 8 & 0xFF00) | (v << 8 & 0xFF0000) | (v << 24 & 0xFF000000);
                    }
                } else if op2 == 0xC0 || op2 == 0xC1 {
                    modrm(0);
                    let a = rm_get(w2);
                    let b = gr(m_reg, w2);
                    let r = alu(0, a, b, w2);
                    sr(m_reg, w2, a);
                    rm_set(w2, r);
                } else if op2 == 0xC7 {
                    modrm(0);
                    if m_reg & 7 != 1 || m_mod == 3 { stop64("an instruction not written yet, 0F C7 field", m_reg); }
                    // CMPXCHG8B and, with a 64-bit operand size, CMPXCHG16B.
                    let h: u8 = if osz == 64 { 64 } else { 32 };
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
            0x5 => {
                if op < 0x58 { push(gr(low, ssz()), ssz()); }
                else { let v = pop(ssz()); sr(low, ssz(), v); }
            },
            0x6 => {
                match op {
                    0x63 => {
                        modrm(0);
                        let v = rm_get(32);
                        sr(m_reg, osz, if osz == 64 { sx(v, 32) } else { v });
                    },
                    0x68 => { let v = fimm(if p66 { 16 } else { 32 }); push(v, ssz()); },
                    0x6A => { let v = fs8(); push(v, ssz()); },
                    0x69 => { modrm(imm_len(osz)); let b = fimm(osz); sr(m_reg, osz, imul2(rm_get(osz), b, osz)); },
                    0x6B => { modrm(1); let b = fs8(); sr(m_reg, osz, imul2(rm_get(osz), b, osz)); },
                    _ => { stop64("an instruction not written yet,", op); },
                }
            },
            0x7 => {
                let d = fs8();
                if cond(op & 15) { next = ip + d; jump = true; }
            },
            0x8 => {
                match op {
                    0x80, 0x81, 0x83 => {
                        modrm(if op == 0x81 { imm_len(osz) } else { 1 });
                        let b = if op == 0x81 { fimm(osz) } else { fs8() };
                        let r = alu(m_reg & 7, rm_get(w), b, w);
                        if m_reg & 7 != 7 { rm_set(w, r); }
                    },
                    0x84, 0x85 => { modrm(0); alu(4, rm_get(w), gr(m_reg, w), w); },
                    0x86, 0x87 => {
                        modrm(0);
                        let a = rm_get(w);
                        let b = gr(m_reg, w);
                        rm_set(w, b);
                        sr(m_reg, w, a);
                    },
                    0x88, 0x89 => { modrm(0); rm_set(w, gr(m_reg, w)); },
                    0x8A, 0x8B => { modrm(0); sr(m_reg, w, rm_get(w)); },
                    0x8D => {
                        modrm(0);
                        if m_mod == 3 { stop64("LEA of a register,", op); }
                        sr(m_reg, osz, m_off);
                    },
                    0x8C => {
                        // A segment register's selector: to a register at the operand size,
                        // to memory as 16 bits.
                        modrm(0);
                        if m_reg & 7 > 5 { fault(6, false, 0); }
                        rm_set(if m_mod == 3 { osz } else { 16 }, seg[m_reg & 7]);
                    },
                    0x8E => {
                        modrm(0);
                        if m_reg & 7 > 5 || m_reg & 7 == 1 { fault(6, false, 0); }
                        seg_load(m_reg & 7, rm_get(16));
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
                        // 90h alone is NOP (and PAUSE with F3h): it does not clear RAX's upper half.
                        if low != 0 {
                            let a = gr(RAX, osz);
                            let b = gr(low, osz);
                            sr(RAX, osz, b);
                            sr(low, osz, a);
                        }
                    },
                    0x98 => {
                        if osz == 16 { sr(RAX, 16, sx(reg[RAX], 8)); }
                        else if osz == 32 { sr(RAX, 32, sx(reg[RAX], 16)); }
                        else { reg[RAX] = sx(reg[RAX], 32); }
                    },
                    0x99 => { sr(RDX, osz, ones(reg[RAX] & msb(osz) != 0)); },
                    0x9C => { push(rflags & 0xFCFFFF, ssz()); },
                    0x9D => {
                        // IF and IOPL stay as they are unless the privilege level may change them.
                        let v = pop(ssz());
                        var can: u64 = if p66 { 0x4DD5 } else { 0x244DD5 };
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
                    let a = (if asz32 { fd() } else { fq() }) + seg_base;
                    if op < 0xA2 { sr(RAX, w, rd(a, w)); } else { wr(a, w, reg[RAX]); }
                } else if op == 0xA8 || op == 0xA9 {
                    alu(4, gr(RAX, w), fimm(w), w);
                } else {
                    next = string_op(op);
                    jump = true;
                }
            },
            0xB => {
                if op < 0xB8 { let v = fb(); sr(low, 8, v); }
                else if osz == 64 { reg[low] = fq(); }
                else if osz == 32 { reg[low] = fd(); }
                else { let v = fw(); sr(low, 16, v); }
            },
            0xC => {
                match op {
                    0xC0, 0xC1 => {
                        modrm(1);
                        let n = fb();
                        rm_set(w, shift(m_reg & 7, rm_get(w), n, w, m_mod == 3));
                    },
                    0xC2 => { let n = fw(); next = pop(64); reg[RSP] += n; jump = true; },
                    0xC3 => { next = pop(64); jump = true; },
                    0xC6, 0xC7 => {
                        modrm(imm_len(w));
                        if m_reg & 7 != 0 { stop64("an instruction not written yet, C6 or C7 field", m_reg); }
                        let v = fimm(w);
                        rm_set(w, v);
                    },
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
                if op < 0xD4 {
                    modrm(0);
                    let n: u64 = if op < 0xD2 { 1 } else { reg[RCX] & 0xFF };
                    rm_set(w, shift(m_reg & 7, rm_get(w), n, w, false));
                } else { stop64("an instruction not written yet,", op); }
            },
            0xE => {
                match op {
                    0xE0, 0xE1, 0xE2 => {
                        let d = fs8();
                        var left = reg[RCX] - 1;
                        if asz32 { left &= 0xFFFFFFFF; }
                        reg[RCX] = left;
                        if left != 0 && (op == 0xE2 || flag(ZF) == (op == 0xE1)) { next = ip + d; jump = true; }
                    },
                    0xE3 => {
                        let d = fs8();
                        if reg[RCX] & mask(if asz32 { 32 } else { 64 }) == 0 { next = ip + d; jump = true; }
                    },
                    0xE4, 0xE5 => { let port = fb(); io_level(); sr(RAX, if op == 0xE4 { 8 } else if p66 { 16 } else { 32 }, port_in(port, if op == 0xE4 { 8 } else if p66 { 16 } else { 32 })); },
                    0xE6, 0xE7 => { let port = fb(); io_level(); port_out(port, if op == 0xE6 { 8 } else if p66 { 16 } else { 32 }, reg[RAX]); },
                    0xEC, 0xED => { io_level(); sr(RAX, if op == 0xEC { 8 } else if p66 { 16 } else { 32 }, port_in(reg[RDX] & 0xFFFF, if op == 0xEC { 8 } else if p66 { 16 } else { 32 })); },
                    0xEE, 0xEF => { io_level(); port_out(reg[RDX] & 0xFFFF, if op == 0xEE { 8 } else if p66 { 16 } else { 32 }, reg[RAX]); },
                    0xE8 => { let d = fs32(); push(ip, 64); next = ip + d; jump = true; },
                    0xE9 => { let d = fs32(); next = ip + d; jump = true; },
                    0xEB => { let d = fs8(); next = ip + d; jump = true; },
                    _ => { stop64("an instruction not written yet,", op); },
                }
            },
            0xF => {
                match op {
                    0xF4 => {
                        // HLT. Nothing can wake the machine yet, so it is the end of the run.
                        io_level();
                        need_level0();
                        halted = true;
                        stopped = true;
                    },
                    0xFA => { io_level(); rflags &= ~IF; },
                    0xFB => { io_level(); rflags |= IF; },
                    0xF5 => { rflags ^= CF; },
                    0xF8 => { rflags &= ~CF; },
                    0xF9 => { rflags |= CF; },
                    0xFC => { rflags &= ~DF; },
                    0xFD => { rflags |= DF; },
                    0xF6, 0xF7 => {
                        // Peek at the field: TEST has a constant behind the operand.
                        let field = (rd(ip, 8) as! u8) >> 3 & 7;
                        modrm(if field < 2 { imm_len(w) } else { 0 });
                        match field {
                            0, 1 => { let b = fimm(w); alu(4, rm_get(w), b, w); },
                            2 => { rm_set(w, ~rm_get(w)); },
                            3 => { rm_set(w, alu(5, 0, rm_get(w), w)); },
                            _ => { muldiv(field, rm_get(w), w); },
                        }
                    },
                    0xFE, 0xFF => {
                        modrm(0);
                        match m_reg & 7 {
                            0 => { rm_set(w, incdec(false, rm_get(w), w)); },
                            1 => { rm_set(w, incdec(true, rm_get(w), w)); },
                            2 => { if op == 0xFE { stop64("an instruction not written yet, FE field", 2); } next = rm_get(64); push(ip, 64); jump = true; },
                            4 => { if op == 0xFE { stop64("an instruction not written yet, FE field", 4); } next = rm_get(64); jump = true; },
                            6 => { if op == 0xFE { stop64("an instruction not written yet, FE field", 6); } push(rm_get(ssz()), ssz()); },
                            _ => { stop64("an instruction not written yet, FF field", m_reg); },
                        }
                    },
                    _ => { stop64("an instruction not written yet,", op); },
                }
            },
            _ => { stop64("an instruction not written yet,", op); },
        }
    }
    rip = if jump { next } else { ip };
    return true;
}
