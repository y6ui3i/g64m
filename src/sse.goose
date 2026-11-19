// MMX and SSE2 of the i686 machine (E077).
//
// The guest's C library and its TLS are compiled for a CPU that has them: a 64-bit load is a
// MOVQ through an XMM register, whatever CPUID says. So they are here, on the general path
// only: no short executor and nothing in the JIT knows them.
//
// - An XMM register is two 64-bit words, low and high (xmm[2i] and xmm[2i+1]).
// - An MMX register is the mantissa of an FPU register, as on the chip: mm(i) is physical
//   register i, whatever the stack's top is. Every MMX instruction but EMMS leaves the top at
//   0 and every register in use; a register written gets an exponent of all ones. The FPU's
//   80-bit originals (fpu.goose: fp_mant, fp_se, fp_raw) hold exactly that.
// - The packed integer instructions are the same for both: on one 64-bit word for MMX, on two
//   for XMM. Most work lane by lane inside a word (pop64); the ones that move lanes between
//   words (unpack, pack, shuffle, the byte shifts) are written out.
// - Floats are the host's, single precision by way of double (which rounds the same for the
//   four operations and the square root), with the chip's own rules where an operand or a
//   result is not a number (far32, far64). No exception is raised, MXCSR's status bits stay
//   as written, and its rounding mode is not obeyed: the conversions that round, round to
//   nearest.
// - FXSAVE and FXRSTOR are the kernel's way of switching all of this between processes once
//   CPUID says FXSR; they carry the FPU's registers as 80-bit values, so MMX goes with them.
//
// Not here: SSE3 and later, MASKMOVQ and MASKMOVDQU, and the 3DNow! instructions. An opcode
// that is not implemented stops the machine and says which.

import std;
import math;
import state;
import exec;
import fpu;
import lanes;

var xmm: u64[16] = [0; 16];
var mxcsr: u32 = 0x1F80;
var pad_sse: u8[4] = [0; 4];

let M32: u64 = 0xFFFFFFFF;

// ---- MMX registers ----

fn mm_get(i: i64) -> u64 {
    if fp_raw[i] { return fp_mant[i]; }
    let m, se = f64_to_f80(fp[i]);
    return m;
}

fn mm_set(i: i64, v: u64) {
    fp_mant[i] = v;
    fp_se[i] = 0xFFFF;
    fp_raw[i] = true;
    fp[i] = f80_to_f64(v, 0xFFFF);
}

fn mm_touch() {
    fp_top = 0;
    fp_empty = 0;
}

// ---- Operands ----

// Which prefix chose the instruction: 0 none, 1 66, 2 F3, 3 F2.
fn sse_pfx() -> u8 {
    if ins.rep == 2 { return 2; }
    if ins.rep == 1 { return 3; }
    let plain: u8 = if code32() { 32 } else { 16 };
    return if ins.osz != plain { 1 } else { 0 };
}

// Word k (0 low, 1 high) of the XMM register or 128 bits of memory that r/m names.
fn xq(k: i64) -> u64 {
    if m_mod == 3 { let b: i64 = m_rm; return xmm[b * 2 + k]; }
    return frd64((k * 8) as! u32);
}

// The MMX register or 64 bits of memory that r/m names.
fn mq() -> u64 {
    if m_mod == 3 { return mm_get(m_rm); }
    return frd64(0);
}

// The general register or 32 bits of memory that r/m names.
fn rm32() -> u32 {
    if m_mod == 3 { return r32(m_rm); }
    return frd(0, 32);
}

fn sse_unknown(op: u8) {
    cpu.ip = saved.ip;
    stop("unimplemented opcode 0F (MMX or SSE)", op);
}

// The four arithmetic forms of one opcode: packed single, packed double, scalar single,
// scalar double.
fn farith(op: u8, p: u8, r: i64) {
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
        let b: u64 = if m_mod == 3 { xq(0) } else { frd(0, 32) };
        xmm[r] = a0 & ~M32 | far32(op, a0, b);
    } else {
        xmm[r] = far64(op, a0, xq(0));
    }
}

// ---- FXSAVE and FXRSTOR ----

fn fxsave() {
    let used: u8 = ~fp_empty;
    fwr(0, 16, fp_cw);
    fwr(2, 16, status());
    fwr(4, 16, used);                // one bit to a register: in use
    fwr(6, 16, 0);
    for k: u32 in 4 { fwr(8 + k * 4, 32, 0); }       // the instruction and operand pointers: not kept
    fwr(24, 32, mxcsr);
    fwr(28, 32, 0xFFBF);
    for i: u8 in 8 {
        let m, se = st80(i);
        let at: u32 = 32 + (i as u32) * 16;
        fwr64(at, m);
        fwr(at + 8, 32, se);
        fwr(at + 12, 32, 0);
    }
    for i in 8 {
        let at: u32 = 160 + (i as! u32) * 16;
        fwr64(at, xmm[i * 2]);
        fwr64(at + 8, xmm[i * 2 + 1]);
    }
}

fn fxrstor() {
    let cw = frd(0, 16) as! u16;
    let sw = frd(2, 16) as! u16;
    let used = frd(4, 16) as! u8;
    mxcsr = frd(24, 32) & 0xFFBF;
    fp_cw = cw;
    fp_top = (sw >> 11 & 7) as! u8;
    fp_cond = sw & (C0 | C1 | C2 | C3);
    for i: u8 in 8 {
        let at: u32 = 32 + (i as u32) * 16;
        let m = frd64(at);
        set_st80(i, m, frd(at + 8, 16) as! u16);
    }
    fp_empty = ~used;
    for i in 8 {
        let at: u32 = 160 + (i as! u32) * 16;
        xmm[i * 2] = frd64(at);
        xmm[i * 2 + 1] = frd64(at + 8);
    }
}

// 0F AE: FXSAVE, FXRSTOR, LDMXCSR, STMXCSR by the reg field with a memory operand; the fences
// with a register one, and CLFLUSH, which have nothing to do here.
fn sse_group15() {
    decode_modrm();
    if m_mod == 3 {
        if m_reg < 5 { sse_unknown(0xAE); }
        return;
    }
    match m_reg {
        0 => { fxsave(); },
        1 => { fxrstor(); },
        2 => { mxcsr = frd(0, 32) & 0xFFBF; },
        3 => { fwr(0, 32, mxcsr); },
        7 => {},
        _ => { sse_unknown(0xAE); },
    }
}

// ---- The instructions ----

// Is the second opcode byte one of this file's?
fn sse_is(op: u8) -> bool {
    return (op >= 0x10 && op <= 0x17) || (op >= 0x28 && op <= 0x2F) || (op >= 0x50 && op <= 0x7F)
        || (op >= 0xC2 && op <= 0xC6) || op >= 0xD0 || op == 0xAE;
}

fn sse_op(op: u8) {
    let p = sse_pfx();
    if op == 0x77 { fp_empty = 0xFF; return; }       // EMMS
    if op == 0xAE { sse_group15(); return; }
    decode_modrm();
    let rg: i64 = m_reg;
    let r = rg * 2;
    let bg: i64 = m_rm;
    let b = bg * 2;
    let reg = m_mod == 3;
    match op {
        0x10 => {
            // MOVUPS, MOVUPD, MOVSS, MOVSD: to the register.
            if p < 2 { let lo = xq(0); let hi = xq(1); xmm[r] = lo; xmm[r + 1] = hi; }
            else if p == 2 {
                if reg { xmm[r] = xmm[r] & ~M32 | xmm[b] & M32; } else { xmm[r] = frd(0, 32); xmm[r + 1] = 0; }
            }
            else if reg { xmm[r] = xmm[b]; } else { xmm[r] = frd64(0); xmm[r + 1] = 0; }
        },
        0x11 => {
            // And from it.
            if p < 2 {
                if reg { xmm[b] = xmm[r]; xmm[b + 1] = xmm[r + 1]; } else { fwr64(0, xmm[r]); fwr64(8, xmm[r + 1]); }
            }
            else if p == 2 {
                if reg { xmm[b] = xmm[b] & ~M32 | xmm[r] & M32; } else { fwr(0, 32, xmm[r] as! u32); }
            }
            else if reg { xmm[b] = xmm[r]; } else { fwr64(0, xmm[r]); }
        },
        0x12 => {
            // MOVLPS and MOVLPD from memory; between registers MOVHLPS, the source's high word.
            if p > 1 { sse_unknown(op); return; }
            xmm[r] = if reg { xmm[b + 1] } else { frd64(0) };
        },
        0x13 => { if reg || p > 1 { sse_unknown(op); return; } fwr64(0, xmm[r]); },
        0x16 => { if p > 1 { sse_unknown(op); return; } xmm[r + 1] = xq(0); },         // MOVHPS, MOVHPD, MOVLHPS
        0x17 => { if reg || p > 1 { sse_unknown(op); return; } fwr64(0, xmm[r + 1]); },
        0x14, 0x15 => {
            // UNPCKLPS, UNPCKLPD and the high ones.
            if p > 1 { sse_unknown(op); return; }
            let k: i64 = if op == 0x14 { 0 } else { 1 };
            let x = xmm[r + k];
            let y = xq(k);
            if p == 1 { xmm[r] = x; xmm[r + 1] = y; }
            else { let lo, hi = weave(x, y, 32); xmm[r] = lo; xmm[r + 1] = hi; }
        },
        0x28 => { let lo = xq(0); let hi = xq(1); xmm[r] = lo; xmm[r + 1] = hi; },      // MOVAPS, MOVAPD
        0x29 => { if reg { xmm[b] = xmm[r]; xmm[b + 1] = xmm[r + 1]; } else { fwr64(0, xmm[r]); fwr64(8, xmm[r + 1]); } },
        0x2B => { if reg { sse_unknown(op); return; } fwr64(0, xmm[r]); fwr64(8, xmm[r + 1]); },    // MOVNTPS
        0x2A => {
            // Integers to floats: two from an MMX register (packed), one from a general one.
            if p == 0 { let s = mq(); if reg { mm_touch(); } xmm[r] = sbits(i2f(s & M32)) | sbits(i2f(s >> 32)) << 32; }
            else if p == 1 { let s = mq(); if reg { mm_touch(); } xmm[r] = dbits(i2f(s & M32)); xmm[r + 1] = dbits(i2f(s >> 32)); }
            else if p == 2 { xmm[r] = xmm[r] & ~M32 | sbits(i2f(rm32())); }
            else { xmm[r] = dbits(i2f(rm32())); }
        },
        0x2C, 0x2D => {
            // Floats to integers, cut off (2C) or rounded: to an MMX register or a general one.
            let cut = op == 0x2C;
            if p == 0 { let s = xq(0); mm_set(rg, f2i(fs(s, 0), cut) | f2i(fs(s, 1), cut) << 32); mm_touch(); }
            else if p == 1 { let s0 = xq(0); let s1 = xq(1); mm_set(rg, f2i(fd(s0), cut) | f2i(fd(s1), cut) << 32); mm_touch(); }
            else if p == 2 { let s: u64 = if reg { xmm[b] } else { frd(0, 32) }; set_r32(m_reg, f2i(fs(s, 0), cut) as! u32); }
            else { set_r32(m_reg, f2i(fd(xq(0)), cut) as! u32); }
        },
        0x2E, 0x2F => {
            // UCOMISS, UCOMISD and COMISS, COMISD: ZF, PF and CF; the rest of the six clear.
            if p > 1 { sse_unknown(op); return; }
            var x = 0.0;
            var y = 0.0;
            if p == 0 { let s: u64 = if reg { xmm[b] } else { frd(0, 32) }; x = fs(xmm[r], 0); y = fs(s, 0); }
            else { x = fd(xmm[r]); y = fd(xq(0)); }
            let un = is_nan(x) || is_nan(y);
            cpu.flags &= ~(OF | SF | ZF | AF | PF | CF);
            if un { cpu.flags |= ZF | PF | CF; }
            else if x < y { cpu.flags |= CF; }
            else if x == y { cpu.flags |= ZF; }
        },
        0x50 => {
            // MOVMSKPS, MOVMSKPD: the signs.
            if !reg || p > 1 { sse_unknown(op); return; }
            let lo = xmm[b];
            let hi = xmm[b + 1];
            if p == 1 { set_r32(m_reg, (lo >> 63 | hi >> 63 << 1) as! u32); }
            else { set_r32(m_reg, (lo >> 31 & 1 | lo >> 63 << 1 | (hi >> 31 & 1) << 2 | hi >> 63 << 3) as! u32); }
        },
        0x51, 0x58, 0x59, 0x5C, 0x5D, 0x5E, 0x5F => { farith(op, p, r); },
        0x52, 0x53 => { if p == 1 || p == 3 { sse_unknown(op); return; } farith(op, p, r); },
        0x54, 0x55, 0x56, 0x57 => {
            // ANDPS, ANDNPS, ORPS, XORPS and the PD ones: the same bits.
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
            else if p == 1 { let s0 = xq(0); let s1 = xq(1); xmm[r] = sbits(fd(s0)) | sbits(fd(s1)) << 32; xmm[r + 1] = 0; }
            else if p == 2 { let s: u64 = if reg { xmm[b] } else { frd(0, 32) }; xmm[r] = dbits(fs(s, 0)); }
            else { xmm[r] = xmm[r] & ~M32 | sbits(fd(xq(0))); }
        },
        0x5B => {
            // Four integers to singles, and back, rounded or cut off.
            if p == 3 { sse_unknown(op); return; }
            let s0 = xq(0);
            let s1 = xq(1);
            if p == 0 {
                xmm[r] = sbits(i2f(s0 & M32)) | sbits(i2f(s0 >> 32)) << 32;
                xmm[r + 1] = sbits(i2f(s1 & M32)) | sbits(i2f(s1 >> 32)) << 32;
            } else {
                let cut = p == 2;
                xmm[r] = f2i(fs(s0, 0), cut) | f2i(fs(s0, 1), cut) << 32;
                xmm[r + 1] = f2i(fs(s1, 0), cut) | f2i(fs(s1, 1), cut) << 32;
            }
        },
        0x6E => {
            // MOVD from a general register or memory.
            if p == 0 { mm_set(rg, rm32()); mm_touch(); }
            else if p == 1 { xmm[r] = rm32(); xmm[r + 1] = 0; }
            else { sse_unknown(op); }
        },
        0x7E => {
            // MOVD to one; with F3, MOVQ to an XMM register.
            if p == 2 { let v = xq(0); xmm[r] = v; xmm[r + 1] = 0; return; }
            if p == 3 { sse_unknown(op); return; }
            let v: u32 = if p == 0 { mm_get(rg) as! u32 } else { xmm[r] as! u32 };
            if p == 0 { mm_touch(); }
            if reg { set_r32(m_rm, v); } else { fwr(0, 32, v); }
        },
        0x6F => {
            // MOVQ to an MMX register; MOVDQA, MOVDQU to an XMM one.
            if p == 0 { mm_set(rg, mq()); mm_touch(); }
            else if p == 3 { sse_unknown(op); }
            else { let lo = xq(0); let hi = xq(1); xmm[r] = lo; xmm[r + 1] = hi; }
        },
        0x7F => {
            if p == 0 { let v = mm_get(rg); if reg { mm_set(bg, v); } else { fwr64(0, v); } mm_touch(); }
            else if p == 3 { sse_unknown(op); }
            else if reg { xmm[b] = xmm[r]; xmm[b + 1] = xmm[r + 1]; }
            else { fwr64(0, xmm[r]); fwr64(8, xmm[r + 1]); }
        },
        0xD6 => {
            // MOVQ from an XMM register; MOVQ2DQ and MOVDQ2Q between the two kinds.
            if p == 1 { if reg { xmm[b] = xmm[r]; xmm[b + 1] = 0; } else { fwr64(0, xmm[r]); } }
            else if p == 2 && reg { xmm[r] = mm_get(bg); xmm[r + 1] = 0; mm_touch(); }
            else if p == 3 && reg { mm_set(rg, xmm[b]); mm_touch(); }
            else { sse_unknown(op); }
        },
        0xE7 => {
            // MOVNTQ, MOVNTDQ.
            if reg || p > 1 { sse_unknown(op); return; }
            if p == 0 { fwr64(0, mm_get(rg)); mm_touch(); } else { fwr64(0, xmm[r]); fwr64(8, xmm[r + 1]); }
        },
        0xC3 => { if reg || p != 0 { sse_unknown(op); return; } fwr(0, 32, r32(m_reg)); },      // MOVNTI
        0xE6 => {
            // Two integers to doubles, and two doubles to integers.
            if p == 2 { let s = xq(0); xmm[r] = dbits(i2f(s & M32)); xmm[r + 1] = dbits(i2f(s >> 32)); }
            else if p == 1 || p == 3 { let s0 = xq(0); let s1 = xq(1); xmm[r] = f2i(fd(s0), p == 1) | f2i(fd(s1), p == 1) << 32; xmm[r + 1] = 0; }
            else { sse_unknown(op); }
        },
        0xC2 => {
            // CMPPS and the others: all ones where the predicate holds.
            let x0 = xmm[r];
            let x1 = xmm[r + 1];
            var y0: u64 = 0;
            var y1: u64 = 0;
            if p == 2 && !reg { y0 = frd(0, 32); } else { y0 = xq(0); if p < 2 { y1 = xq(1); } }
            let pred = fetch8();
            let all: u64 = 0xFFFFFFFFFFFFFFFF;
            if p == 0 {
                var lo: u64 = 0;
                var hi: u64 = 0;
                if fcmp(pred, fs(x0, 0), fs(y0, 0)) { lo |= M32; }
                if fcmp(pred, fs(x0, 1), fs(y0, 1)) { lo |= M32 << 32; }
                if fcmp(pred, fs(x1, 0), fs(y1, 0)) { hi |= M32; }
                if fcmp(pred, fs(x1, 1), fs(y1, 1)) { hi |= M32 << 32; }
                xmm[r] = lo;
                xmm[r + 1] = hi;
            } else if p == 1 {
                xmm[r] = if fcmp(pred, fd(x0), fd(y0)) { all } else { 0 };
                xmm[r + 1] = if fcmp(pred, fd(x1), fd(y1)) { all } else { 0 };
            } else if p == 2 {
                xmm[r] = x0 & ~M32 | (if fcmp(pred, fs(x0, 0), fs(y0, 0)) { M32 } else { 0 });
            } else {
                xmm[r] = if fcmp(pred, fd(x0), fd(y0)) { all } else { 0 };
            }
        },
        0xC6 => {
            // SHUFPS: two lanes from the destination, two from the source. SHUFPD: one each.
            if p > 1 { sse_unknown(op); return; }
            let x0 = xmm[r];
            let x1 = xmm[r + 1];
            let y0 = xq(0);
            let y1 = xq(1);
            let imm: u32 = fetch8();
            if p == 1 {
                xmm[r] = if imm & 1 != 0 { x1 } else { x0 };
                xmm[r + 1] = if imm & 2 != 0 { y1 } else { y0 };
            } else {
                var lo: u64 = 0;
                var hi: u64 = 0;
                for i: u32 in 2 {
                    let k = imm >> (i * 2) & 3;
                    lo |= ((if k < 2 { x0 } else { x1 }) >> ((k & 1) * 32) & M32) << (i * 32);
                    let j = imm >> (i * 2 + 4) & 3;
                    hi |= ((if j < 2 { y0 } else { y1 }) >> ((j & 1) * 32) & M32) << (i * 32);
                }
                xmm[r] = lo;
                xmm[r + 1] = hi;
            }
        },
        0xC4 => {
            // PINSRW: a word from a general register or memory into a lane.
            let v: u64 = if reg { r32(m_rm) & 0xFFFF } else { frd(0, 16) };
            let imm: u32 = fetch8();
            if p == 0 {
                let at = (imm & 3) * 16;
                let clear: u64 = 0xFFFF;
                mm_set(rg, mm_get(rg) & ~(clear << at) | v << at);
                mm_touch();
            } else if p == 1 {
                let at = (imm & 3) * 16;
                let k: i64 = if imm & 4 != 0 { 1 } else { 0 };
                let clear: u64 = 0xFFFF;
                xmm[r + k] = xmm[r + k] & ~(clear << at) | v << at;
            } else { sse_unknown(op); }
        },
        0xC5 => {
            // PEXTRW: a lane into a general register.
            if !reg || p > 1 { sse_unknown(op); return; }
            let imm: u32 = fetch8();
            if p == 0 { set_r32(m_reg, (mm_get(bg) >> ((imm & 3) * 16) & 0xFFFF) as! u32); mm_touch(); }
            else {
                let k: i64 = if imm & 4 != 0 { 1 } else { 0 };
                set_r32(m_reg, (xmm[b + k] >> ((imm & 3) * 16) & 0xFFFF) as! u32);
            }
        },
        0xD7 => {
            // PMOVMSKB: the bytes' top bits.
            if !reg || p > 1 { sse_unknown(op); return; }
            var mask: u32 = 0;
            let lo = if p == 0 { mm_get(bg) } else { xmm[b] };
            for i: u32 in 8 { mask |= ((lo >> (i * 8 + 7) & 1) as! u32) << i; }
            if p == 1 { let hi = xmm[b + 1]; for i: u32 in 8 { mask |= ((hi >> (i * 8 + 7) & 1) as! u32) << (i + 8); } }
            else { mm_touch(); }
            set_r32(m_reg, mask);
        },
        0x70 => {
            // PSHUFW (MMX), PSHUFD, PSHUFHW, PSHUFLW.
            if p == 0 { let s = mq(); let imm: u32 = fetch8(); mm_set(rg, shuf4(s, 16, imm)); mm_touch(); return; }
            let s0 = xq(0);
            let s1 = xq(1);
            let imm: u32 = fetch8();
            if p == 1 {
                var lo: u64 = 0;
                var hi: u64 = 0;
                for i: u32 in 2 {
                    let k = imm >> (i * 2) & 3;
                    lo |= ((if k < 2 { s0 } else { s1 }) >> ((k & 1) * 32) & M32) << (i * 32);
                    let j = imm >> (i * 2 + 4) & 3;
                    hi |= ((if j < 2 { s0 } else { s1 }) >> ((j & 1) * 32) & M32) << (i * 32);
                }
                xmm[r] = lo;
                xmm[r + 1] = hi;
            }
            else if p == 2 { xmm[r] = s0; xmm[r + 1] = shuf4(s1, 16, imm); }
            else { xmm[r] = shuf4(s0, 16, imm); xmm[r + 1] = s1; }
        },
        0x71, 0x72, 0x73 => {
            // The shifts by a constant, of the register r/m names: /2 right, /4 right keeping
            // the sign, /6 left; and of a whole XMM register by bytes, /3 right and /7 left.
            if !reg || p > 1 { sse_unknown(op); return; }
            let n: u64 = fetch8();
            let w: u32 = if op == 0x71 { 16 } else if op == 0x72 { 32 } else { 64 };
            if op == 0x73 && (m_reg == 3 || m_reg == 7) {
                if p != 1 { sse_unknown(op); return; }
                let lo = xmm[b];
                let hi = xmm[b + 1];
                let bits = n * 8;
                if n > 15 { xmm[b] = 0; xmm[b + 1] = 0; }
                else if m_reg == 3 {
                    if bits == 0 {} else if bits < 64 { xmm[b] = lo >> bits | hi << (64 - bits); xmm[b + 1] = hi >> bits; }
                    else { xmm[b] = hi >> (bits - 64); xmm[b + 1] = 0; }
                } else {
                    if bits == 0 {} else if bits < 64 { xmm[b + 1] = hi << bits | lo >> (64 - bits); xmm[b] = lo << bits; }
                    else { xmm[b + 1] = lo << (bits - 64); xmm[b] = 0; }
                }
                return;
            }
            var kind: u8 = 255;
            if m_reg == 2 { kind = 0; } else if m_reg == 4 && op != 0x73 { kind = 1; } else if m_reg == 6 { kind = 2; }
            if kind == 255 { sse_unknown(op); return; }
            if p == 0 { mm_set(bg, pshift(kind, w, mm_get(bg), n)); mm_touch(); }
            else { xmm[b] = pshift(kind, w, xmm[b], n); xmm[b + 1] = pshift(kind, w, xmm[b + 1], n); }
        },
        _ => {
            // Everything else is a packed integer instruction of two operands, or nothing.
            if p > 1 { sse_unknown(op); return; }
            if p == 0 {
                let a = mm_get(rg);
                let s = mq();
                let v, hi, known = pint(op, false, a, 0, s, 0);
                if !known { sse_unknown(op); return; }
                mm_set(rg, v);
                mm_touch();
            } else {
                let s0 = xq(0);
                let s1 = xq(1);
                let lo, hi, known = pint(op, true, xmm[r], xmm[r + 1], s0, s1);
                if !known { sse_unknown(op); return; }
                xmm[r] = lo;
                xmm[r + 1] = hi;
            }
        },
    }
}
