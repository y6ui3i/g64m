// SSE and SSE2 of the 64-bit CPU (E093): sixteen XMM registers and MXCSR.
//
// - An XMM register is two 64-bit words, low and high (xmm[2i] and xmm[2i+1]).
// - What the instructions compute is in lanes.goose, shared with the i686 machine's
//   sse.goose; this file is the 64-bit CPU's operands around it: registers 8 to 15 by the
//   REX prefix, a 64-bit general register where REX.W says so, addresses from cpu64.goose.
// - There are no MMX registers here: a compiler for x86_64 does not use them. The forms of
//   these opcodes that name one stop the run, as does anything else not written.
// - Floats are the host's, single precision by way of double. MXCSR's rounding mode is
//   obeyed where a float becomes an integer, and not in arithmetic, which rounds to nearest.
//   No exception is raised and MXCSR's six status bits stay as the program wrote them.
// - Nothing checks that the memory operand of an aligned move is aligned.

import std;
import math;
import cpu64;
import lanes;
import fpu;

var xmm: u64[32] = [0; 32];
var mxcsr: u32 = 0x1F80;

// Is the second opcode byte one of this file's?
fn sse64_is(op: u8) -> bool {
    return (op >= 0x10 && op <= 0x17) || (op >= 0x28 && op <= 0x2F) || (op >= 0x50 && op <= 0x7F)
        || (op >= 0xC2 && op <= 0xC6) || op >= 0xD0 || op == 0xAE;
}

fn sse64_unknown(op: u8) {
    stop64("an instruction not written yet, 0F (SSE)", op);
}

// Word k (0 low, 1 high) of the XMM register or 128 bits of memory that r/m names.
fn xq(k: i64) -> u64 {
    if ins.mod == 3 { let b: i64 = ins.rm; return xmm[b * 2 + k]; }
    return rd(m_ea + ((k * 8) as! u64), 64);
}

// The low 32 bits of the XMM register, or 32 bits of memory, that r/m names.
fn xs() -> u64 {
    if ins.mod == 3 { let b: i64 = ins.rm; return xmm[b * 2] & LOW32; }
    return rd(m_ea, 32);
}

// The flags of a comparison of two singles (in the low halves) or two doubles: ZF, PF and
// CF, the rest of the six clear. (The JIT settles its record of one with this too.)
fn sse64_comis(single: bool, a: u64, b: u64) {
    var x = 0.0;
    var y = 0.0;
    if single { x = fs(a, 0); y = fs(b, 0); } else { x = fd(a); y = fd(b); }
    rflags &= ~ARITH;
    if is_nan(x) || is_nan(y) { rflags |= ZF | PF | CF; }
    else if x < y { rflags |= CF; }
    else if x == y { rflags |= ZF; }
}

// ---- Floats to integers and back ----

// A float as a whole number: cut off, or rounded as MXCSR says (to nearest, down, up, or
// toward zero).
fn round_rc(v: f64, cut: bool) -> f64 {
    if cut { return trunc(v); }
    match mxcsr >> 13 & 3 {
        0 => { return rint(v); },
        1 => { return floor(v); },
        2 => { return ceil(v); },
        _ => { return trunc(v); },
    }
}

// As a 32-bit integer; out of range, or not a number, the "integer indefinite".
fn to_i32(v: f64, cut: bool) -> u64 {
    let x = round_rc(v, cut);
    if is_nan(x) || x < -2147483648.0 || x >= 2147483648.0 { return 0x80000000; }
    return ((x as! i64) as! u64) & LOW32;
}

fn to_i64(v: f64, cut: bool) -> u64 {
    let x = round_rc(v, cut);
    if is_nan(x) || x < -9223372036854775808.0 || x >= 9223372036854775808.0 { return 0x8000000000000000; }
    return (x as! i64) as! u64;
}

// A signed 64-bit integer as a single, rounded once. By way of a double it would be rounded
// twice; so the integer is first cut to 53 bits with a bit that says whether anything was
// lost, which a double holds exactly and which rounds to the same single.
fn i64_to_single(v: u64) -> u64 {
    let neg = v >> 63 != 0;
    let mag = if neg { ~v + 1 } else { v };
    var d: f64 = 0.0;
    if mag >> 53 == 0 { d = (mag as! i64); }
    else {
        let cutm = mag >> 11 | (if mag & 0x7FF != 0 { 1 } else { 0 });
        d = (cutm as! i64);
        d = d * 2048.0;
    }
    return sbits(if neg { -d } else { d });
}

fn i64_to_double(v: u64) -> u64 {
    let d: f64 = (v as! i64);
    return dbits(d);
}

// The four arithmetic forms of one opcode: packed single, packed double, scalar single,
// scalar double.
fn farith64(op: u8, p: u8, r: i64) {
    let a0 = xmm[r];
    let a1 = xmm[r + 1];
    if p == 0 {
        let b0 = xq(0);
        let b1 = xq(1);
        xmm[r] = far32(op, a0, b0) | far32(op, a0 >> 32, b0 >> 32) << 32;
        xmm[r + 1] = far32(op, a1, b1) | far32(op, a1 >> 32, b1 >> 32) << 32;
    } else if p == 1 {
        let b0 = xq(0);
        let b1 = xq(1);
        xmm[r] = far64(op, a0, b0);
        xmm[r + 1] = far64(op, a1, b1);
    } else if p == 2 {
        xmm[r] = a0 & ~LOW32 | far32(op, a0, xs());
    } else {
        xmm[r] = far64(op, a0, xq(0));
    }
}

// FXSAVE and FXRSTOR: the x87's and SSE's state in 512 bytes of memory, which is how a
// kernel keeps it for a program that is not running. The control and status words, a bit
// for each x87 register in use, MXCSR and the bits of it that exist, the eight x87
// registers as 80-bit values in sixteen bytes each, and the sixteen XMM registers. The
// last x87 instruction's address and operand are not kept, and are written as zero.
fn fxsave64() {
    let used: u8 = ~fp_empty;
    fwr(0, 16, fp_cw);
    fwr(2, 16, status());
    fwr(4, 16, used);
    fwr(6, 16, 0);
    for k: u32 in 4 { fwr(8 + k * 4, 32, 0); }
    fwr(24, 32, mxcsr);
    fwr(28, 32, 0xFFFF);
    for i: u8 in 8 {
        let m, se = raw80(i);
        let at: u32 = 32 + (i as u32) * 16;
        fwr64(at, m);
        fwr(at + 8, 32, se);
        fwr(at + 12, 32, 0);
    }
    for i in 16 {
        let at: u32 = 160 + (i as! u32) * 16;
        fwr64(at, xmm[i * 2]);
        fwr64(at + 8, xmm[i * 2 + 1]);
    }
}

fn fxrstor64() {
    let cw = frd(0, 16) as! u16;
    let sw = frd(2, 16) as! u16;
    let used = frd(4, 16) as! u8;
    let mx = frd(24, 32);
    if mx & 0xFFFF0000 != 0 { fault(13, true, 0); }
    mxcsr = mx;
    fp_cw = cw;
    fp_top = (sw >> 11 & 7) as! u8;
    fp_cond = sw & (C0 | C1 | C2 | C3);
    for i: u8 in 8 {
        let at: u32 = 32 + (i as u32) * 16;
        let m = frd64(at);
        set_st80(i, m, frd(at + 8, 16) as! u16);
    }
    fp_empty = ~used;
    for i in 16 {
        let at: u32 = 160 + (i as! u32) * 16;
        xmm[i * 2] = frd64(at);
        xmm[i * 2 + 1] = frd64(at + 8);
    }
}

// 0F AE: FXSAVE, FXRSTOR, LDMXCSR and STMXCSR by the reg field with a memory operand; the
// fences with a register one, and CLFLUSH, which have nothing to do here.
fn sse64_group15() {
    modrm(0);
    if ins.mod == 3 {
        if ins.reg & 7 < 5 { sse64_unknown(0xAE); }
        return;
    }
    match ins.reg & 7 {
        0 => { fxsave64(); },
        1 => { fxrstor64(); },
        2 => { mxcsr = (rd(m_ea, 32) & 0xFFFF) as! u32; },
        3 => { wr(m_ea, 32, mxcsr); },
        7 => {},
        _ => { sse64_unknown(0xAE); },
    }
}

// The lanes of 32 bits picked by two bits of imm each: the low two from x, the high two
// from y (SHUFPS; PSHUFD with x and y the same).
fn pick4(x0: u64, x1: u64, y0: u64, y1: u64, imm: u32) -> u64, u64 {
    var lo: u64 = 0;
    var hi: u64 = 0;
    for i: u32 in 2 {
        let k = imm >> (i * 2) & 3;
        lo |= ((if k < 2 { x0 } else { x1 }) >> ((k & 1) * 32) & LOW32) << (i * 32);
        let j = imm >> (i * 2 + 4) & 3;
        hi |= ((if j < 2 { y0 } else { y1 }) >> ((j & 1) * 32) & LOW32) << (i * 32);
    }
    return lo, hi;
}

// Is the 0F AE instruction at hand one with a register operand (a fence)? Looked at before
// the ModRM byte is taken.
fn m_ae_fence() -> bool { return peek8() >> 6 == 3; }

fn sse64_op(op: u8) {
    // Which prefix chose the instruction: 0 none, 1 66, 2 F3, 3 F2.
    let p: u8 = if ins.rep == 0xF3 { 2 } else if ins.rep == 0xF2 { 3 } else if ins.p66 { 1 } else { 0 };
    if machine {
        // In a machine these are there once the operating system says it keeps their state
        // (CR4.OSFXSR) and has not asked for the x87 to be emulated (CR0.EM): else the opcode
        // is undefined. With CR0.TS set they trap, for the state to be brought in first.
        // (FXSAVE, FXRSTOR and the fences of 0F AE are not held to the first.)
        if op != 0xAE && (cr4 & 0x200 == 0 || cr0 & 4 != 0) { fault(6, false, 0); }
        if cr0 & 8 != 0 && !(op == 0xAE && m_ae_fence()) { fault(7, false, 0); }
    }
    if op == 0xAE { sse64_group15(); return; }
    if op == 0x77 { sse64_unknown(op); }
    let has_imm = op == 0x70 || op == 0x71 || op == 0x72 || op == 0x73 || (op >= 0xC2 && op <= 0xC6 && op != 0xC3);
    modrm(if has_imm { 1 } else { 0 });
    let rg: i64 = ins.reg;
    let r = rg * 2;
    let bg: i64 = ins.rm;
    let b = bg * 2;
    let direct = ins.mod == 3;
    let gw: u8 = if ins.rex & 8 != 0 { 64 } else { 32 };       // a general register's width here
    match op {
        0x10 => {
            // MOVUPS, MOVUPD, MOVSS, MOVSD: to the register.
            if p < 2 { let lo = xq(0); let hi = xq(1); xmm[r] = lo; xmm[r + 1] = hi; }
            else if p == 2 {
                if direct { xmm[r] = xmm[r] & ~LOW32 | xmm[b] & LOW32; } else { xmm[r] = rd(m_ea, 32); xmm[r + 1] = 0; }
            }
            else if direct { xmm[r] = xmm[b]; } else { xmm[r] = rd(m_ea, 64); xmm[r + 1] = 0; }
        },
        0x11 => {
            // And from it.
            if p < 2 {
                if direct { xmm[b] = xmm[r]; xmm[b + 1] = xmm[r + 1]; } else { wr(m_ea, 64, xmm[r]); wr(m_ea + 8, 64, xmm[r + 1]); }
            }
            else if p == 2 {
                if direct { xmm[b] = xmm[b] & ~LOW32 | xmm[r] & LOW32; } else { wr(m_ea, 32, xmm[r]); }
            }
            else if direct { xmm[b] = xmm[r]; } else { wr(m_ea, 64, xmm[r]); }
        },
        0x12 => {
            // MOVLPS and MOVLPD from memory; between registers MOVHLPS, the source's high word.
            if p > 1 { sse64_unknown(op); }
            xmm[r] = if direct { xmm[b + 1] } else { rd(m_ea, 64) };
        },
        0x13 => { if direct || p > 1 { sse64_unknown(op); } wr(m_ea, 64, xmm[r]); },
        0x16 => { if p > 1 { sse64_unknown(op); } xmm[r + 1] = xq(0); },                // MOVHPS, MOVHPD, MOVLHPS
        0x17 => { if direct || p > 1 { sse64_unknown(op); } wr(m_ea, 64, xmm[r + 1]); },
        0x14, 0x15 => {
            // UNPCKLPS, UNPCKLPD and the high ones.
            if p > 1 { sse64_unknown(op); }
            let k: i64 = if op == 0x14 { 0 } else { 1 };
            let x = xmm[r + k];
            let y = xq(k);
            if p == 1 { xmm[r] = x; xmm[r + 1] = y; }
            else { let lo, hi = weave(x, y, 32); xmm[r] = lo; xmm[r + 1] = hi; }
        },
        0x28 => { let lo = xq(0); let hi = xq(1); xmm[r] = lo; xmm[r + 1] = hi; },      // MOVAPS, MOVAPD
        0x29 => { if direct { xmm[b] = xmm[r]; xmm[b + 1] = xmm[r + 1]; } else { wr(m_ea, 64, xmm[r]); wr(m_ea + 8, 64, xmm[r + 1]); } },
        0x2B => { if direct || p > 1 { sse64_unknown(op); } wr(m_ea, 64, xmm[r]); wr(m_ea + 8, 64, xmm[r + 1]); },    // MOVNTPS, MOVNTPD
        0x2A => {
            // An integer in a general register or memory, 32 or 64 bits, to a float.
            if p < 2 { sse64_unknown(op); }
            let v = rm_get(gw);
            let wide = if gw == 64 { v } else { sx(v, 32) };
            if p == 2 { xmm[r] = xmm[r] & ~LOW32 | i64_to_single(wide); }
            else { xmm[r] = i64_to_double(wide); }
        },
        0x2C, 0x2D => {
            // A float to an integer in a general register, cut off (2C) or rounded.
            if p < 2 { sse64_unknown(op); }
            let cut = op == 0x2C;
            let v = if p == 2 { fs(xs(), 0) } else { fd(xq(0)) };
            if gw == 64 { reg64_set(ins.reg, to_i64(v, cut)); } else { sr(ins.reg, 32, to_i32(v, cut)); }
        },
        0x2E, 0x2F => {
            // UCOMISS, UCOMISD and COMISS, COMISD: ZF, PF and CF; the rest of the six clear.
            if p > 1 { sse64_unknown(op); }
            if p == 0 { sse64_comis(true, xmm[r], xs()); }
            else { sse64_comis(false, xmm[r], xq(0)); }
        },
        0x50 => {
            // MOVMSKPS, MOVMSKPD: the signs.
            if !direct || p > 1 { sse64_unknown(op); }
            let lo = xmm[b];
            let hi = xmm[b + 1];
            if p == 1 { sr(ins.reg, 32, lo >> 63 | hi >> 63 << 1); }
            else { sr(ins.reg, 32, lo >> 31 & 1 | lo >> 63 << 1 | (hi >> 31 & 1) << 2 | hi >> 63 << 3); }
        },
        0x51, 0x58, 0x59, 0x5C, 0x5D, 0x5E, 0x5F => { farith64(op, p, r); },
        0x52, 0x53 => { if p == 1 || p == 3 { sse64_unknown(op); } farith64(op, p, r); },
        0x54, 0x55, 0x56, 0x57 => {
            // ANDPS, ANDNPS, ORPS, XORPS and the PD ones: the same bits.
            if p > 1 { sse64_unknown(op); }
            let s0 = xq(0);
            let s1 = xq(1);
            if op == 0x54 { xmm[r] &= s0; xmm[r + 1] &= s1; }
            else if op == 0x55 { xmm[r] = ~xmm[r] & s0; xmm[r + 1] = ~xmm[r + 1] & s1; }
            else if op == 0x56 { xmm[r] |= s0; xmm[r + 1] |= s1; }
            else { xmm[r] ^= s0; xmm[r + 1] ^= s1; }
        },
        0x5A => {
            // Between single and double.
            if p == 0 { let s = xq(0); xmm[r] = dbits(fs(s, 0)); xmm[r + 1] = dbits(fs(s, 1)); }
            else if p == 1 { let s0 = xq(0); let s1 = xq(1); xmm[r] = cvt_ds(s0) | cvt_ds(s1) << 32; xmm[r + 1] = 0; }
            else if p == 2 { xmm[r] = cvt_sd(xs()); }
            else { xmm[r] = xmm[r] & ~LOW32 | cvt_ds(xq(0)); }
        },
        0x5B => {
            // Four integers to singles, and back, rounded or cut off.
            if p == 3 { sse64_unknown(op); }
            let s0 = xq(0);
            let s1 = xq(1);
            if p == 0 {
                xmm[r] = sbits(i2f(s0 & LOW32)) | sbits(i2f(s0 >> 32)) << 32;
                xmm[r + 1] = sbits(i2f(s1 & LOW32)) | sbits(i2f(s1 >> 32)) << 32;
            } else {
                let cut = p == 2;
                xmm[r] = to_i32(fs(s0, 0), cut) | to_i32(fs(s0, 1), cut) << 32;
                xmm[r + 1] = to_i32(fs(s1, 0), cut) | to_i32(fs(s1, 1), cut) << 32;
            }
        },
        0x6E => {
            // MOVD and MOVQ from a general register or memory.
            if p != 1 { sse64_unknown(op); }
            xmm[r] = rm_get(gw);
            xmm[r + 1] = 0;
        },
        0x7E => {
            // MOVD and MOVQ to one; with F3, MOVQ to an XMM register.
            if p == 2 { let v = xq(0); xmm[r] = v; xmm[r + 1] = 0; return; }
            if p != 1 { sse64_unknown(op); }
            rm_set(gw, xmm[r]);
        },
        0x6F => {
            // MOVDQA, MOVDQU.
            if p == 0 || p == 3 { sse64_unknown(op); }
            let lo = xq(0);
            let hi = xq(1);
            xmm[r] = lo;
            xmm[r + 1] = hi;
        },
        0x7F => {
            if p == 0 || p == 3 { sse64_unknown(op); }
            if direct { xmm[b] = xmm[r]; xmm[b + 1] = xmm[r + 1]; }
            else { wr(m_ea, 64, xmm[r]); wr(m_ea + 8, 64, xmm[r + 1]); }
        },
        0xD6 => {
            // MOVQ from an XMM register.
            if p != 1 { sse64_unknown(op); }
            if direct { xmm[b] = xmm[r]; xmm[b + 1] = 0; } else { wr(m_ea, 64, xmm[r]); }
        },
        0xE7 => {
            // MOVNTDQ.
            if direct || p != 1 { sse64_unknown(op); }
            wr(m_ea, 64, xmm[r]);
            wr(m_ea + 8, 64, xmm[r + 1]);
        },
        0xC3 => { if direct || p != 0 { sse64_unknown(op); } wr(m_ea, gw, reg[ins.reg]); },      // MOVNTI
        0xE6 => {
            // Two integers to doubles, and two doubles to integers.
            if p == 2 { let s = xq(0); xmm[r] = dbits(i2f(s & LOW32)); xmm[r + 1] = dbits(i2f(s >> 32)); }
            else if p == 1 || p == 3 { let s0 = xq(0); let s1 = xq(1); xmm[r] = to_i32(fd(s0), p == 1) | to_i32(fd(s1), p == 1) << 32; xmm[r + 1] = 0; }
            else { sse64_unknown(op); }
        },
        0xC2 => {
            // CMPPS and the others: all ones where the predicate holds.
            let x0 = xmm[r];
            let x1 = xmm[r + 1];
            var y0: u64 = 0;
            var y1: u64 = 0;
            if p == 2 { y0 = xs(); } else { y0 = xq(0); if p < 2 { y1 = xq(1); } }
            let pred = fb() as! u8;
            let all: u64 = 0xFFFFFFFFFFFFFFFF;
            if p == 0 {
                var lo: u64 = 0;
                var hi: u64 = 0;
                if fcmp(pred, fs(x0, 0), fs(y0, 0)) { lo |= LOW32; }
                if fcmp(pred, fs(x0, 1), fs(y0, 1)) { lo |= LOW32 << 32; }
                if fcmp(pred, fs(x1, 0), fs(y1, 0)) { hi |= LOW32; }
                if fcmp(pred, fs(x1, 1), fs(y1, 1)) { hi |= LOW32 << 32; }
                xmm[r] = lo;
                xmm[r + 1] = hi;
            } else if p == 1 {
                xmm[r] = if fcmp(pred, fd(x0), fd(y0)) { all } else { 0 };
                xmm[r + 1] = if fcmp(pred, fd(x1), fd(y1)) { all } else { 0 };
            } else if p == 2 {
                xmm[r] = x0 & ~LOW32 | (if fcmp(pred, fs(x0, 0), fs(y0, 0)) { LOW32 } else { 0 });
            } else {
                xmm[r] = if fcmp(pred, fd(x0), fd(y0)) { all } else { 0 };
            }
        },
        0xC6 => {
            // SHUFPS: two lanes from the destination, two from the source. SHUFPD: one each.
            if p > 1 { sse64_unknown(op); }
            let x0 = xmm[r];
            let x1 = xmm[r + 1];
            let y0 = xq(0);
            let y1 = xq(1);
            let imm = fb() as! u32;
            if p == 1 {
                xmm[r] = if imm & 1 != 0 { x1 } else { x0 };
                xmm[r + 1] = if imm & 2 != 0 { y1 } else { y0 };
            } else {
                let lo, hi = pick4(x0, x1, y0, y1, imm);
                xmm[r] = lo;
                xmm[r + 1] = hi;
            }
        },
        0xC4 => {
            // PINSRW: a word from a general register or memory into a lane.
            if p != 1 { sse64_unknown(op); }
            let v = rm_get(16);
            let imm = fb() as! u32;
            let at = (imm & 3) * 16;
            let k: i64 = if imm & 4 != 0 { 1 } else { 0 };
            let clear: u64 = 0xFFFF;
            xmm[r + k] = xmm[r + k] & ~(clear << at) | v << at;
        },
        0xC5 => {
            // PEXTRW: a lane into a general register.
            if !direct || p != 1 { sse64_unknown(op); }
            let imm = fb() as! u32;
            let k: i64 = if imm & 4 != 0 { 1 } else { 0 };
            sr(ins.reg, 32, xmm[b + k] >> ((imm & 3) * 16) & 0xFFFF);
        },
        0xD7 => {
            // PMOVMSKB: the bytes' top bits.
            if !direct || p != 1 { sse64_unknown(op); }
            var bits: u64 = 0;
            let lo = xmm[b];
            let hi = xmm[b + 1];
            for i: u32 in 8 { bits |= (lo >> (i * 8 + 7) & 1) << i | (hi >> (i * 8 + 7) & 1) << (i + 8); }
            sr(ins.reg, 32, bits);
        },
        0xF7 => {
            // MASKMOVDQU: the bytes of the register whose byte in the mask has its top bit
            // set go to memory at RDI.
            if !direct || p != 1 { sse64_unknown(op); }
            let at = (if ins.asz32 { reg[RDI] & 0xFFFFFFFF } else { reg[RDI] }) + seg_base();
            for i: u32 in 16 {
                let k: i64 = if i < 8 { 0 } else { 1 };
                let sh = (i & 7) * 8;
                if xmm[b + k] >> (sh + 7) & 1 != 0 { wr(at + i, 8, xmm[r + k] >> sh & 0xFF); }
            }
        },
        0x70 => {
            // PSHUFD, PSHUFHW, PSHUFLW.
            if p == 0 { sse64_unknown(op); }
            let s0 = xq(0);
            let s1 = xq(1);
            let imm = fb() as! u32;
            if p == 1 { let lo, hi = pick4(s0, s1, s0, s1, imm); xmm[r] = lo; xmm[r + 1] = hi; }
            else if p == 2 { xmm[r] = s0; xmm[r + 1] = shuf4(s1, 16, imm); }
            else { xmm[r] = shuf4(s0, 16, imm); xmm[r + 1] = s1; }
        },
        0x71, 0x72, 0x73 => {
            // The shifts by a constant, of the register r/m names: /2 right, /4 right keeping
            // the sign, /6 left; and of the whole register by bytes, /3 right and /7 left.
            if !direct || p != 1 { sse64_unknown(op); }
            let n = fb();
            let w: u32 = if op == 0x71 { 16 } else if op == 0x72 { 32 } else { 64 };
            let field = ins.reg & 7;
            if op == 0x73 && (field == 3 || field == 7) {
                let lo = xmm[b];
                let hi = xmm[b + 1];
                let bits = n * 8;
                if n > 15 { xmm[b] = 0; xmm[b + 1] = 0; }
                else if field == 3 {
                    if bits == 0 {} else if bits < 64 { xmm[b] = lo >> bits | hi << (64 - bits); xmm[b + 1] = hi >> bits; }
                    else { xmm[b] = if bits == 64 { hi } else { hi >> (bits - 64) }; xmm[b + 1] = 0; }
                } else {
                    if bits == 0 {} else if bits < 64 { xmm[b + 1] = hi << bits | lo >> (64 - bits); xmm[b] = lo << bits; }
                    else { xmm[b + 1] = if bits == 64 { lo } else { lo << (bits - 64) }; xmm[b] = 0; }
                }
                return;
            }
            var kind: u8 = 255;
            if field == 2 { kind = 0; } else if field == 4 && op != 0x73 { kind = 1; } else if field == 6 { kind = 2; }
            if kind == 255 { sse64_unknown(op); }
            xmm[b] = pshift(kind, w, xmm[b], n);
            xmm[b + 1] = pshift(kind, w, xmm[b + 1], n);
        },
        _ => {
            // Everything else is a packed integer instruction of two operands, or nothing.
            if p != 1 { sse64_unknown(op); }
            let s0 = xq(0);
            let s1 = xq(1);
            let lo, hi, known = pint(op, true, xmm[r], xmm[r + 1], s0, s1);
            if !known { sse64_unknown(op); }
            xmm[r] = lo;
            xmm[r + 1] = hi;
        },
    }
}

// A double's bits as a single's, and a single's as a double's, a NaN made quiet on the way.
fn cvt_ds(q: u64) -> u64 { return sbits(fd(q)); }
fn cvt_sd(q: u64) -> u64 { return dbits(fs(q, 0)); }

fn reg64_set(i: u8, v: u64) { reg[i] = v; }
