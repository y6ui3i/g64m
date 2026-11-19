// The x87 floating-point unit, of the i686 machine and of the 64-bit CPU (E098).
//
// A register holds a value in two forms: an f64, and, when the value has one, its exact 80-bit
// original (64 bits of mantissa, where an f64 has 53).
//
// - Add, subtract, multiply and divide work on the 80-bit form, in integers, and round as the
//   control word says: to 64, 53 or 24 bits of mantissa, in any of the four directions. So does
//   comparison, and so does conversion to and from integers. C libraries depend on this: musl's
//   printf decides how to round a digit by asking whether 2^64 plus a small number is 2^64.
// - A value that is only moved keeps all its bits, which makes saving and restoring the whole
//   unit (FNSAVE, FRSTOR) exact.
// - Everything else is computed as an f64: the square root, the functions that go through libm,
//   and arithmetic whose operands or result are not ordinary numbers (zeros, infinities, NaNs,
//   denormals, overflow). There the rounding direction is made from the sign of the exact
//   residual: if the nearest f64 lies on the wrong side of the true result, its neighbour is taken.
//
// No floating-point exception is ever raised, and the exception bits of the status word stay
// zero. What a masked exception would produce (a NaN, an infinity, a zero) is what f64 arithmetic
// gives anyway. An escape opcode that is not implemented stops the machine and says which: letting
// one pass silently is how rustx86 once turned `sleep 3` into a 20 ms sleep.
//
// The file belongs to no CPU. What it needs of the one it serves, that CPU's files give
// under these names (exec.goose for the i686, cpu64.goose for the 64-bit CPU):
//   frd(k, w), fwr(k, w, v)   read and write w bits at the memory operand's address plus k
//   fp_env32()                the environment is in its 32-bit layout (28 bytes, not 14)
//   fp_set_ax(v)              FNSTSW AX
//   fp_set_zpc(bits)          ZF, PF and CF from a comparison (FCOMI and its kin)
//   flag(CF) ...              the flags, for FCMOVcc
//   fp_stop(code)             an escape opcode that is not written: stop and say which
// and m_mod, m_reg, m_rm: the ModRM byte's three fields, 0 to 7 each. The CPU checks that
// the unit is available (CR0's EM and TS) before it calls fpu_escape.

import std;
import math;
import lanes;

extern fn ldexp(x: f64, e: i32) -> f64 = "ldexp";
extern fn logb(x: f64) -> f64 = "logb";
extern fn remainder(x: f64, y: f64) -> f64 = "remainder";

// A float's bits, through the runtime functions the standard library's binary module uses.

// The condition codes, at their places in the status word.
let C0 = 0x0100; let C1 = 0x0200; let C2 = 0x0400; let C3 = 0x4000;

let TOP_BIT: u64 = 0x8000000000000000;
let FRAC_MASK: u64 = 0x000FFFFFFFFFFFFF;

var fp: f64[8] = [0.0; 8];           // physical registers; ST(i) is fp[(fp_top + i) & 7]
var fp_mant: u64[8] = [0; 8];        // the 80-bit original of a register, when fp_raw says it has one
var fp_se: u16[8] = [0; 8];
var fp_raw: bool[8] = [false; 8];
var fp_empty: u8 = 0xFF;             // one bit per physical register: set when it is empty
var fp_top: u8 = 0;
var fp_cond: u16 = 0;                // C0 to C3
var fp_cw: u16 = 0x037F;

fn fpu_reset() {
    fp_empty = 0xFF;
    fp_top = 0;
    fp_cond = 0;
    fp_cw = 0x037F;
    for i in 8 { fp[i] = 0.0; fp_raw[i] = false; }
}

fn bit8(p: u8) -> u8 { let one: u8 = 1; return one << p; }
fn phys(i: u8) -> u8 { return (fp_top + i) & 7; }
// ST(i) as an instruction reads it. An empty register reads as the indefinite NaN, which is
// what the chip gives with the stack fault masked (E098); the fault itself is not recorded.
fn st(i: u8) -> f64 {
    let p = phys(i);
    if fp_empty & bit8(p) != 0 { return f64_of_bits(0xFFF8000000000000); }
    return fp[p];
}

fn set_st(i: u8, v: f64) {
    let p = phys(i);
    fp[p] = v;
    fp_raw[p] = false;
    fp_empty &= 0xFF ^ bit8(p);
}

// Sets ST(i) to an 80-bit value.
fn set_st80(i: u8, mant: u64, se: u16) {
    let p = phys(i);
    fp[p] = f80_to_f64(mant, se);
    fp_mant[p] = mant;
    fp_se[p] = se;
    fp_raw[p] = true;
    fp_empty &= 0xFF ^ bit8(p);
}

fn fpush(v: f64) {
    fp_top = (fp_top + 7) & 7;
    set_st(0, v);
}

fn fpop() {
    fp_empty |= bit8(fp_top);
    fp_top = (fp_top + 1) & 7;
}

// Copies ST(from) to ST(to), the 80-bit original included.
fn copy_st(to: u8, from: u8) {
    let d = phys(to);
    let s = phys(from);
    fp[d] = fp[s];
    fp_mant[d] = fp_mant[s];
    fp_se[d] = fp_se[s];
    fp_raw[d] = fp_raw[s];
    fp_empty &= 0xFF ^ bit8(d);
}

fn swap_st(i: u8) {
    let a = phys(0);
    let b = phys(i);
    let v = fp[a]; fp[a] = fp[b]; fp[b] = v;
    let m = fp_mant[a]; fp_mant[a] = fp_mant[b]; fp_mant[b] = m;
    let e = fp_se[a]; fp_se[a] = fp_se[b]; fp_se[b] = e;
    let r = fp_raw[a]; fp_raw[a] = fp_raw[b]; fp_raw[b] = r;
    fp_empty &= 0xFF ^ (bit8(a) | bit8(b));
}

fn status() -> u16 {
    let t: u16 = fp_top;
    return fp_cond | t << 11;
}

// Two bits per physical register: 0 valid, 1 zero, 2 special (NaN, infinity), 3 empty.
fn tag_word() -> u16 {
    var w: u16 = 0;
    for p in 8 {
        var t: u16 = 0;
        if fp_empty & bit8(p as! u8) != 0 { t = 3; }
        else if fp[p] == 0.0 { t = 1; }
        else if !is_finite(fp[p]) { t = 2; }
        w |= t << (p * 2);
    }
    return w;
}

fn load_tags(w: u16) {
    fp_empty = 0;
    for p in 8 {
        if w >> (p * 2) & 3 == 3 { fp_empty |= bit8(p as! u8); }
    }
}

// ---- The 80-bit format ----

// The mantissa (bit 63 is the explicit integer bit) and the sign with the 15-bit exponent.
fn f64_to_f80(v: f64) -> u64, u16 {
    let bits = bits_of_f64(v);
    let sign: u16 = if bits >> 63 != 0 { 0x8000 } else { 0 };
    let exp = (bits >> 52 & 0x7FF) as! i64;
    let frac = bits & FRAC_MASK;
    if exp == 0 {
        if frac == 0 { return 0, sign; }
        // An f64 denormal is an ordinary number in 80 bits, where the exponent has more room.
        let lz = clz(frac);
        return frac << lz, sign | (16383 + 63 - 1074 - lz) as! u16;
    }
    if exp == 0x7FF {
        // A NaN that is loaded is made quiet (E098).
        if frac != 0 { return TOP_BIT | 0x4000000000000000 | frac << 11, sign | 0x7FFF; }
        return TOP_BIT, sign | 0x7FFF;
    }
    return TOP_BIT | frac << 11, sign | (exp - 1023 + 16383) as! u16;
}

// Rounds to nearest, ties to even, in integers: the 11 bits an f64 has no room for decide.
fn f80_to_f64(mant: u64, se: u16) -> f64 {
    let sign: u64 = if se & 0x8000 != 0 { TOP_BIT } else { 0 };
    var e = (se & 0x7FFF) as! i64;
    if e == 0x7FFF {
        if mant << 1 == 0 { return f64_of_bits(sign | 0x7FF0000000000000); }
        return f64_of_bits(sign | 0x7FF8000000000000 | (mant >> 11 & FRAC_MASK));
    }
    if mant == 0 { return f64_of_bits(sign); }
    if e == 0 { e = 1; }                 // a denormal's exponent field is 0 and means 1
    let lz = clz(mant);
    let m = mant << lz;
    let biased = e - lz - 16383 + 1023;
    if biased >= 2047 { return f64_of_bits(sign | 0x7FF0000000000000); }
    if biased >= 1 {
        var frac = m >> 11;
        let rem = m & 0x7FF;
        if rem > 0x400 || (rem == 0x400 && frac & 1 != 0) { frac += 1; }
        // A carry out of the mantissa lands in the exponent, which is what it should do.
        return f64_of_bits(sign | (((biased as! u64) << 52) + (frac - 0x0010000000000000)));
    }
    let shift = 12 - biased;             // too small for a normal f64: make a denormal
    if shift > 64 { return f64_of_bits(sign); }
    let one: u64 = 1;
    var frac: u64 = 0;
    var rem = m;
    var half = TOP_BIT;
    if shift < 64 {
        frac = m >> shift;
        rem = m & ((one << shift) - 1);
        half = one << (shift - 1);
    }
    if rem > half || (rem == half && frac & 1 != 0) { frac += 1; }
    return f64_of_bits(sign | frac);
}

fn st80(i: u8) -> u64, u16 {
    let p = phys(i);
    if fp_empty & bit8(p) != 0 { return 0xC000000000000000, 0xFFFF; }
    if fp_raw[p] { return fp_mant[p], fp_se[p]; }
    return f64_to_f80(fp[p]);
}

// What is in ST(i), empty or not: for the instructions that save the whole unit.
fn raw80(i: u8) -> u64, u16 {
    let p = phys(i);
    if fp_raw[p] { return fp_mant[p], fp_se[p]; }
    return f64_to_f80(fp[p]);
}

// An 80-bit value as the bits of a double (wide) or a single, rounded once, as the control
// word says, from all 64 bits of mantissa (E098: by way of the register's f64 it was rounded
// twice for a single, and to nearest whatever the control word said).
fn store_float(m0: u64, se: u16, wide: bool) -> u64 {
    let p: u64 = if wide { 53 } else { 24 };
    let bias: i64 = if wide { 1023 } else { 127 };
    let emax: i64 = if wide { 2047 } else { 255 };
    let one: u64 = 1;
    let neg = se & 0x8000 != 0;
    let sign: u64 = if neg { one << (if wide { 63 } else { 31 }) } else { 0 };
    let top = (emax as! u64) << (p - 1);                  // the exponent field all ones
    let e = (se & 0x7FFF) as! i64;
    if e == 0x7FFF {
        if m0 << 1 == 0 { return sign | top; }
        return sign | top | one << (p - 2) | (m0 << 1 >> (65 - p));
    }
    if m0 == 0 { return sign; }
    let lz = clz(m0);
    let m = m0 << lz;
    var biased = (if e == 0 { 1 } else { e }) - lz - 16383 + bias;
    let dir = rc();
    // How far the 64 bits are moved right: to p bits for a normal number, further for one
    // too small to be normal.
    var shift: u64 = 64 - p;
    if biased < 1 { shift += (1 - biased) as! u64; }
    var frac: u64 = 0;
    var rem = m;
    var half = TOP_BIT;
    var below = false;                 // every bit is beyond even the half place
    if shift > 64 { below = true; }
    else if shift < 64 {
        frac = m >> shift;
        rem = m & ((one << shift) - 1);
        half = one << (shift - 1);
    }
    var up = false;
    if dir == 0 { up = !below && (rem > half || (rem == half && frac & 1 != 0)); }
    else if dir == 1 { up = neg && rem != 0; }
    else if dir == 2 { up = !neg && rem != 0; }
    if up { frac += 1; }
    if biased < 1 { return sign | frac; }          // a denormal, or the smallest normal by the carry
    if frac >> p != 0 { frac = frac >> 1; biased += 1; }
    if biased >= emax {
        // Too large: infinity, or the largest number when the rounding is away from it.
        let largest = sign | top - 1;
        if dir == 3 || (dir == 1 && !neg) || (dir == 2 && neg) { return largest; }
        return sign | top;
    }
    return sign | (biased as! u64) << (p - 1) | frac & ((one << (p - 1)) - 1);
}

// ---- Arithmetic on 128 bits, for the square root ----

// The square root of an ordinary positive 80-bit number, in integers: all 64 bits of the
// mantissa, with what is left over deciding the rounding. False if the result is out of
// range (it never is, for an ordinary operand).
fn sqrt80(m: u64, se: u16) -> u64, u16, bool {
    let e = (se & 0x7FFF) as! i64 - 16383;
    // The root's 64 bits r are such that r * r is m * 2^63 for an even exponent and
    // m * 2^64 for an odd one: n is that number, as a high and a low half.
    let odd = e & 1 != 0;
    var nh: u64 = if odd { m } else { m >> 1 };
    var nl: u64 = if odd { 0 } else { m << 63 };
    var root: u64 = 0;
    var rh: u64 = 0;                   // the remainder, which needs 66 bits
    var rl: u64 = 0;
    for i in 64 {
        // Two more bits of n come down.
        rh = rh << 2 | rl >> 62;
        rl = rl << 2 | nh >> 62;
        nh = nh << 2 | nl >> 62;
        nl = nl << 2;
        // The trial: four times the root so far, and one.
        let th = root >> 62;
        let tl = root << 2 | 1;
        if rh > th || (rh == th && rl >= tl) {
            if rl < tl { rh -= 1; }
            rl -= tl;
            rh -= th;
            root = root << 1 | 1;
        } else {
            root = root << 1;
        }
    }
    // More than half a unit is left when the remainder exceeds the root.
    var lo: u64 = if rh != 0 || rl != 0 { 1 } else { 0 };
    if rh != 0 || rl > root { lo |= TOP_BIT; }
    let half_e = if odd { (e - 1) / 2 } else { e / 2 };
    let rm, rse, ok = round_pack(0, 16383 + half_e, root, lo);
    return rm, rse, ok;
}

// The constants the unit holds, to 64 bits: `down` is the mantissa cut off, and `more` says
// the part cut off is over a half. So to nearest it is one more when `more`; upward one
// more always; downward and toward zero as cut.
fn push_const(down: u64, se: u16, more: bool) {
    let dir = rc();
    let m = if dir == 2 || (dir == 0 && more) { down + 1 } else { down };
    fpush(0.0);
    set_st80(0, m, se);
}

// ---- The memory operand ----

fn frd64(k: u32) -> u64 {
    let lo: u64 = frd(k, 32);
    let hi: u64 = frd(k + 4, 32);
    return hi << 32 | lo;
}

fn fwr64(k: u32, v: u64) {
    fwr(k, 32, v as! u32);
    fwr(k + 4, 32, (v >> 32) as! u32);
}

// ---- Rounding ----

fn rc() -> u16 { return fp_cw >> 10 & 3; }

// To an integral value, in the direction the control word asks for.
fn round_int(v: f64) -> f64 {
    match rc() {
        0 => { return rint(v); },        // the host rounds to nearest even, and is never told otherwise
        1 => { return floor(v); },
        2 => { return ceil(v); },
        _ => { return trunc(v); },
    }
}

// The next f64 above v.
fn next_up(v: f64) -> f64 {
    if is_nan(v) || v == INF { return v; }
    if v == 0.0 { return f64_of_bits(1); }
    let b = bits_of_f64(v);
    if v > 0.0 { return f64_of_bits(b + 1); }
    return f64_of_bits(b - 1);
}

fn next_down(v: f64) -> f64 { return -next_up(-v); }

// Fits a result to the control word. r is the result rounded to nearest; err has the sign of
// (true result - r).
fn finish(r: f64, err: f64) -> f64 {
    let dir = rc();
    if is_inf(r) {
        // An overflow stops at the largest finite number when the rounding goes toward zero.
        let biggest = f64_of_bits(0x7FEFFFFFFFFFFFFF);
        if r > 0.0 && (dir == 1 || dir == 3) { return biggest; }
        if r < 0.0 && (dir == 2 || dir == 3) { return -biggest; }
        return r;
    }
    var v = r;
    if dir == 1 && err < 0.0 { v = next_down(r); }
    else if dir == 2 && err > 0.0 { v = next_up(r); }
    else if dir == 3 && err < 0.0 && r > 0.0 { v = next_down(r); }
    else if dir == 3 && err > 0.0 && r < 0.0 { v = next_up(r); }
    if fp_cw >> 8 & 3 == 0 && v != 0.0 {
        // Single precision: 24 bits of mantissa, but still the x87's exponent range, so the value
        // cannot go through an f32. Round the low 29 mantissa bits away, ties to even.
        let bits = bits_of_f64(v);
        let low = bits & 0x1FFFFFFF;
        var hi = bits >> 29;
        if low > 0x10000000 || (low == 0x10000000 && hi & 1 != 0) { hi += 1; }
        return f64_of_bits(hi << 29);
    }
    return v;
}

fn f_add(a: f64, b: f64) -> f64 {
    let r = a + b;
    if is_nan(r) || !is_finite(a) || !is_finite(b) { return r; }
    let bb = r - a;
    return finish(r, (a - (r - bb)) + (b - bb));
}

fn f_mul(a: f64, b: f64) -> f64 {
    let r = a * b;
    if is_nan(r) || !is_finite(a) || !is_finite(b) { return r; }
    if r == 0.0 && a != 0.0 && b != 0.0 {
        // The product fell below the smallest f64 and so did its residual; the sign is still known.
        return finish(r, if (a < 0.0) == (b < 0.0) { 1.0 } else { -1.0 });
    }
    return finish(r, mul_add(a, b, -r));
}

fn f_div(a: f64, b: f64) -> f64 {
    let r = a / b;
    if is_nan(r) || b == 0.0 || !is_finite(a) || !is_finite(b) { return r; }
    let res = mul_add(-r, b, a);
    return finish(r, if b > 0.0 { res } else { -res });
}

fn f_sqrt(a: f64) -> f64 {
    if a < 0.0 { return f64_of_bits(0xFFF8000000000000); }       // the x87's "indefinite" NaN
    let r = sqrt(a);
    if !is_finite(r) { return r; }
    return finish(r, mul_add(-r, r, a));
}

// The six arithmetic operations of the D8 row, by the reg field: a is ST(0), b the other operand.
fn arith(r: u8, a: f64, b: f64) -> f64 {
    var v = 0.0;
    match r {
        0 => { v = f_add(a, b); },
        1 => { v = f_mul(a, b); },
        4 => { v = f_add(a, -b); },
        5 => { v = f_add(b, -a); },
        6 => { v = f_div(a, b); },
        _ => { v = f_div(b, a); },
    }
    // A result that is not a number, of operands that were (infinity less infinity, zero
    // by zero), is the one "indefinite": quiet, with the sign set (E098).
    if is_nan(v) && !is_nan(a) && !is_nan(b) { return f64_of_bits(0xFFF8000000000000); }
    return v;
}

// An integer of the given width, as its two's complement bits. Out of range, or a NaN, gives the
// "integer indefinite": the most negative number.
fn to_int(r: f64, bits: i32) -> u64 {
    let lim = ldexp(1.0, bits - 1);
    if is_nan(r) || r < -lim || r >= lim {
        let one: u64 = 1;
        return one << (bits - 1);
    }
    return (r as! i64) as! u64;
}

// ---- Arithmetic on the 80-bit format ----

// An ordinary number: not zero, a denormal, an infinity or a NaN, and with its integer bit set.
fn normal80(m: u64, se: u16) -> bool {
    let e = se & 0x7FFF;
    return e != 0 && e != 0x7FFF && m >> 63 != 0;
}

// The exponent field, as a number to calculate with.
fn exp80(se: u16) -> i64 { return se & 0x7FFF; }

fn zero80(m: u64, se: u16) -> bool { return m == 0 && se & 0x7FFF == 0; }
fn nan80(m: u64, se: u16) -> bool { return se & 0x7FFF == 0x7FFF && m << 1 != 0; }

// The 128-bit product of two 64-bit numbers: high half, low half.
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

// Rounds an exact result to the precision and direction of the control word and packs it. hi is
// the mantissa with its top bit set, lo what lies below it: its top bit is the half, and any other
// bit set means "something more". The third result is false when the exponent has left the range
// of ordinary numbers; the caller then computes the operation as an f64.
fn round_pack(sign: u16, e0: i64, hi0: u64, lo: u64) -> u64, u16, bool {
    var e = e0;
    var hi = hi0;
    let pc = fp_cw >> 8 & 3;
    let cut = if pc == 3 { 0 } else if pc == 0 { 40 } else { 11 };      // mantissa bits given up
    var half = false;
    var sticky = false;
    var unit: u64 = 1;
    if cut == 0 {
        half = lo >> 63 != 0;
        sticky = lo << 1 != 0;
    } else {
        unit = unit << cut;
        let dropped = hi & (unit - 1);
        half = dropped >> (cut - 1) != 0;
        sticky = dropped & ((unit >> 1) - 1) != 0 || lo != 0;
        hi -= dropped;
    }
    let dir = rc();
    var up = false;
    if dir == 0 { up = half && (sticky || hi & unit != 0); }
    else if dir == 1 { up = sign != 0 && (half || sticky); }
    else if dir == 2 { up = sign == 0 && (half || sticky); }
    if up {
        hi += unit;
        if hi == 0 { hi = TOP_BIT; e += 1; }     // the mantissa carried out
    }
    if e <= 0 || e >= 0x7FFF { return 0, 0, false; }
    return hi, sign | (e as! u16), true;
}

// a + b. Subtraction is addition with b's sign turned.
fn soft_add(am0: u64, ase0: u16, bm0: u64, bse0: u16) -> u64, u16, bool {
    var am = am0; var ase = ase0; var bm = bm0; var bse = bse0;
    // Adding zero must not cost the other operand its low bits.
    if zero80(bm, bse) && normal80(am, ase) { return round_pack(ase & 0x8000, exp80(ase), am, 0); }
    if zero80(am, ase) && normal80(bm, bse) { return round_pack(bse & 0x8000, exp80(bse), bm, 0); }
    if !normal80(am, ase) || !normal80(bm, bse) { return 0, 0, false; }
    if ase & 0x7FFF < bse & 0x7FFF || (ase & 0x7FFF == bse & 0x7FFF && am < bm) {
        let tm = am; am = bm; bm = tm;
        let ts = ase; ase = bse; bse = ts;
    }
    var e = exp80(ase);
    let d = e - exp80(bse);
    // b, moved down to a's exponent, as 128 bits. Bits that fall off the end leave a mark.
    var bh: u64 = 0;
    var bl: u64 = 0;
    if d == 0 { bh = bm; }
    else if d < 64 { bh = bm >> d; bl = bm << (64 - d); }
    else if d == 64 { bl = bm; }
    else if d < 128 { bl = bm >> (d - 64); if bm << (128 - d) != 0 { bl |= 1; } }
    else { bl = 1; }
    var hi: u64 = 0;
    var lo: u64 = 0;
    if ase & 0x8000 == bse & 0x8000 {
        lo = bl;
        hi = am + bh;
        if hi < am {                             // carried out: one place down
            lo = (lo >> 1) | (lo & 1) | (hi << 63);
            hi = (hi >> 1) | TOP_BIT;
            e += 1;
        }
    } else {
        let borrow: u64 = if bl != 0 { 1 } else { 0 };
        lo = 0 - bl;
        hi = am - bh - borrow;
        if hi == 0 && lo == 0 {
            // Exactly zero: positive, except when rounding down.
            let zs: u16 = if rc() == 1 { 0x8000 } else { 0 };
            return 0, zs, true;
        }
        if hi == 0 { hi = lo; lo = 0; e -= 64; }
        let lz = clz(hi);
        if lz > 0 { hi = (hi << lz) | (lo >> (64 - lz)); lo = lo << lz; e -= lz; }
    }
    return round_pack(ase & 0x8000, e, hi, lo);
}

fn soft_mul(am: u64, ase: u16, bm: u64, bse: u16) -> u64, u16, bool {
    if !normal80(am, ase) || !normal80(bm, bse) { return 0, 0, false; }
    var e = exp80(ase) + exp80(bse) - 16383 + 1;
    var hi, lo = mul64(am, bm);
    if hi >> 63 == 0 { hi = (hi << 1) | (lo >> 63); lo = lo << 1; e -= 1; }
    return round_pack((ase ^ bse) & 0x8000, e, hi, lo);
}

// a / b, by long division: 64 quotient bits, one more for the half, and whether anything is left.
fn soft_div(am: u64, ase: u16, bm: u64, bse: u16) -> u64, u16, bool {
    if !normal80(am, ase) || !normal80(bm, bse) { return 0, 0, false; }
    var e = exp80(ase) - exp80(bse) + 16383 - 1;
    var q: u64 = 0;
    var rem = am;
    var n = 64;
    if am >= bm { rem = am - bm; q = 1; n = 63; e += 1; }
    for k in n {
        let carry = rem >> 63 != 0;
        rem = rem << 1;
        q = q << 1;
        if carry || rem >= bm { rem -= bm; q |= 1; }
    }
    var lo: u64 = 0;
    let carry = rem >> 63 != 0;
    rem = rem << 1;
    if carry || rem >= bm { rem -= bm; lo = TOP_BIT; }
    if rem != 0 { lo |= 1; }
    return round_pack((ase ^ bse) & 0x8000, e, q, lo);
}

// The six arithmetic operations on 80-bit operands: a is ST(0), b the other. Ordinary numbers are
// computed exactly; anything else goes through f64.
fn arith80(r: u8, am: u64, ase: u16, bm: u64, bse: u16) -> u64, u16 {
    match r {
        0 => { let m, se, ok = soft_add(am, ase, bm, bse); if ok { return m, se; } },
        1 => { let m, se, ok = soft_mul(am, ase, bm, bse); if ok { return m, se; } },
        4 => { let m, se, ok = soft_add(am, ase, bm, bse ^ 0x8000); if ok { return m, se; } },
        5 => { let m, se, ok = soft_add(bm, bse, am, ase ^ 0x8000); if ok { return m, se; } },
        6 => { let m, se, ok = soft_div(am, ase, bm, bse); if ok { return m, se; } },
        _ => { let m, se, ok = soft_div(bm, bse, am, ase); if ok { return m, se; } },
    }
    let fm, fse = f64_to_f80(arith(r, f80_to_f64(am, ase), f80_to_f64(bm, bse)));
    return fm, fse;
}

fn i64_to_f80(v: i64) -> u64, u16 {
    if v == 0 { return 0, 0; }
    let sign: u16 = if v < 0 { 0x8000 } else { 0 };
    let bits = v as! u64;
    let mag = if v < 0 { 0 - bits } else { bits };
    let lz = clz(mag);
    let e = (16383 + 63 - lz) as! u16;
    return mag << lz, sign | e;
}

// The magnitude of an ordinary 80-bit number rounded to an integer in the given direction (the
// control word's encoding: nearest, down, up, toward zero). False when it needs more than 63 bits.
fn round80(m: u64, se: u16, mode: u16) -> u64, bool {
    let e = exp80(se) - 16383;
    if e >= 63 { return 0, false; }
    let neg = se & 0x8000 != 0;
    let shift = 63 - e;
    var n: u64 = 0;
    var half = false;
    var sticky = false;
    if shift >= 65 { sticky = true; }
    else if shift == 64 { half = true; sticky = m << 1 != 0; }
    else {
        let one: u64 = 1;
        n = m >> shift;
        half = m >> (shift - 1) & 1 != 0;
        sticky = m & ((one << (shift - 1)) - 1) != 0;
    }
    var up = false;
    if mode == 0 { up = half && (sticky || n & 1 != 0); }
    else if mode == 1 { up = neg && (half || sticky); }
    else if mode == 2 { up = !neg && (half || sticky); }
    if up { n += 1; }
    return n, true;
}

// ST(0) as an integer of the given width, in two's complement, rounded in the given direction.
fn st_int(bits: i32, mode: u16) -> u64 {
    let m, se = st80(0);
    if normal80(m, se) {
        let mag, ok = round80(m, se, mode);
        if ok {
            let one: u64 = 1;
            let lim = one << (bits - 1);
            let neg = se & 0x8000 != 0;
            if mag > lim || (mag == lim && !neg) { return lim; }       // the integer indefinite
            if neg { return 0 - mag; }
            return mag;
        }
    }
    var v = st(0);
    match mode {
        0 => { v = rint(v); },
        1 => { v = floor(v); },
        2 => { v = ceil(v); },
        _ => { v = trunc(v); },
    }
    return to_int(v, bits);
}

// ---- Comparison ----

// -1, 0 or 1 for a below, equal to or above b; 2 when either is a NaN.
fn cmp80(am: u64, ase: u16, bm: u64, bse: u16) -> i64 {
    if nan80(am, ase) || nan80(bm, bse) { return 2; }
    let an = ase & 0x8000 != 0;
    let bn = bse & 0x8000 != 0;
    if am == 0 && bm == 0 { return 0; }
    if am == 0 { return if bn { 1 } else { -1 }; }
    if bm == 0 { return if an { -1 } else { 1 }; }
    if an != bn { return if an { -1 } else { 1 }; }
    var rel = 0;
    let ea = ase & 0x7FFF;
    let eb = bse & 0x7FFF;
    if ea != eb { rel = if ea > eb { 1 } else { -1 }; }
    else if am != bm { rel = if am > bm { 1 } else { -1 }; }
    return if an { -rel } else { rel };
}

fn cmp_st(i: u8) -> i64 {
    let am, ase = st80(0);
    let bm, bse = st80(i);
    return cmp80(am, ase, bm, bse);
}

fn set_cond(rel: i64) {
    fp_cond &= 0xFFFF ^ (C0 | C1 | C2 | C3);     // C1 is cleared too (E098: the real CPU)
    if rel == 2 { fp_cond |= C0 | C2 | C3; }
    else if rel < 0 { fp_cond |= C0; }
    else if rel == 0 { fp_cond |= C3; }
}

// FCOMI and its relatives: the result goes to ZF, PF and CF.
fn set_cmp_flags(rel: i64) {
    var f: u32 = 0;
    if rel == 2 { f |= ZF | PF | CF; }
    else if rel < 0 { f |= CF; }
    else if rel == 0 { f |= ZF; }
    fp_set_zpc(f);
}

// ---- The environment: control, status and tag words, and the pointers nobody reads ----

// Writes the environment at the operand and returns its size: 28 bytes with a 32-bit operand size,
// 14 with a 16-bit one. The instruction and operand pointers are written as zero.
fn store_env() -> u32 {
    if fp_env32() {
        // The upper half of each of the three words' places is written as ones (E098).
        let ones: u32 = 0xFFFF0000;
        fwr(0, 32, ones | fp_cw);
        fwr(4, 32, ones | status());
        fwr(8, 32, ones | tag_word());
        for i in 4 { fwr((12 + i * 4) as! u32, 32, 0); }
        return 28;
    }
    fwr(0, 16, fp_cw);
    fwr(2, 16, status());
    fwr(4, 16, tag_word());
    for i in 4 { fwr((6 + i * 2) as! u32, 16, 0); }
    return 14;
}

fn load_env() -> u32 {
    let step: u32 = if fp_env32() { 4 } else { 2 };
    let cw = frd(0, 16) as! u16;
    let sw = frd(step, 16) as! u16;
    let tags = frd(step * 2, 16) as! u16;
    fp_cw = cw;
    fp_top = (sw >> 11 & 7) as! u8;
    fp_cond = sw & (C0 | C1 | C2 | C3);
    load_tags(tags);
    return step * 7;
}

// ---- Execution ----

fn fpu_unknown() {
    let modrm: i64 = m_mod << 6 | m_reg << 3 | m_rm;
    fp_stop((cpu_op as i64) << 8 | modrm);
}

var cpu_op: u8 = 0;

// Arithmetic or comparison of ST(0) with b, the result going to ST(dest).
fn arith_to(r: u8, bm: u64, bse: u16, dest: u8) {
    let am, ase = st80(0);
    if r == 2 || r == 3 {
        set_cond(cmp80(am, ase, bm, bse));
        if r == 3 { fpop(); }
        return;
    }
    let m, se = arith80(r, am, ase, bm, bse);
    set_st80(dest, m, se);
}

fn fpu_mem(row: u8, r: u8) {
    if row & 1 == 0 {
        // D8, DA, DC, DE: arithmetic with a 32-bit real, 32-bit integer, 64-bit real, 16-bit integer.
        var b: f64 = 0.0;
        match row {
            0 => { b = f32_of_bits(frd(0, 32)); },
            2 => { let iv = frd(0, 32) as! i32; b = iv; },
            4 => { b = f64_of_bits(frd64(0)); },
            _ => { let iv = frd(0, 16) as! i16; b = iv; },
        }
        let bm, bse = f64_to_f80(b);
        arith_to(r, bm, bse, 0);
        return;
    }
    match row << 3 | r {
        // D9
        0x08 => { fpush(f32_of_bits(frd(0, 32))); },
        0x0A, 0x0B => { let mant, se = st80(0); fwr(0, 32, store_float(mant, se, false) as! u32); if r == 3 { fpop(); } },
        0x0C => { load_env(); },
        0x0D => { fp_cw = frd(0, 16) as! u16; },
        0x0E => { store_env(); fp_cw |= 0x3F; },         // FNSTENV then masks every exception
        0x0F => { fwr(0, 16, fp_cw); },
        // DB
        0x18 => { let iv = frd(0, 32) as! i32; fpush(iv); },
        0x19 => { fwr(0, 32, st_int(32, 3) as! u32); fpop(); },      // FISTTP
        0x1A, 0x1B => { fwr(0, 32, st_int(32, rc()) as! u32); if r == 3 { fpop(); } },
        0x1D => {
            let mant = frd64(0);
            let se = frd(8, 16) as! u16;
            fpush(f80_to_f64(mant, se));
            fp_mant[fp_top] = mant;
            fp_se[fp_top] = se;
            fp_raw[fp_top] = true;
        },
        0x1F => {
            let mant, se = st80(0);
            fwr64(0, mant);
            fwr(8, 16, se);
            fpop();
        },
        // DD
        0x28 => { fpush(f64_of_bits(frd64(0))); },
        0x29 => { fwr64(0, st_int(64, 3)); fpop(); },
        0x2A, 0x2B => { let mant, se = st80(0); fwr64(0, store_float(mant, se, true)); if r == 3 { fpop(); } },
        0x2C => {                                        // FRSTOR
            let n = load_env();
            for i in 8 {
                let at = n + (i * 10) as! u32;
                let mant = frd64(at);
                let se = frd(at + 8, 16) as! u16;
                let p = phys(i as! u8);
                fp[p] = f80_to_f64(mant, se);
                fp_mant[p] = mant;
                fp_se[p] = se;
                fp_raw[p] = true;
            }
        },
        0x2E => {                                        // FNSAVE, which then initialises the unit
            let n = store_env();
            for i in 8 {
                let at = n + (i * 10) as! u32;
                let mant, se = raw80(i as! u8);
                fwr64(at, mant);
                fwr(at + 8, 16, se);
            }
            fpu_reset();
        },
        0x2F => { fwr(0, 16, status()); },
        // DF
        0x38 => { let iv = frd(0, 16) as! i16; fpush(iv); },
        0x39 => { fwr(0, 16, (st_int(16, 3) as! u16)); fpop(); },
        0x3A, 0x3B => { fwr(0, 16, (st_int(16, rc()) as! u16)); if r == 3 { fpop(); } },
        0x3D => {                                        // FILD of 64 bits: exact, where an f64 is not
            let m, se = i64_to_f80(frd64(0) as! i64);
            fp_top = (fp_top + 7) & 7;
            set_st80(0, m, se);
        },
        0x3F => { fwr64(0, st_int(64, rc())); fpop(); },
        _ => { fpu_unknown(); },         // among them FBLD and FBSTP, the packed decimal pair
    }
}

// The low three bits of a quotient, where FPREM and FPREM1 report them: C0, C3, C1 from the top.
fn quotient_bits(q: f64) {
    fp_cond &= 0xFFFF ^ (C0 | C1 | C2 | C3);
    if !is_finite(q) || abs(q) >= 9.0e18 { return; }
    let qi = abs(q) as! u64;
    if qi & 1 != 0 { fp_cond |= C1; }
    if qi & 2 != 0 { fp_cond |= C3; }
    if qi & 4 != 0 { fp_cond |= C0; }
}

// FPREM and FPREM1 of ordinary numbers, in integers (E098): the remainder of a by b by long
// division of the mantissas, a bit of the quotient at a time. When the exponents are 64 or more apart the chip does part of it and says so (C2),
// leaving a smaller number to go on from: 32 bits of the quotient and what the difference
// leaves over 32. Else the remainder is whole, and the quotient's low three bits go to C0,
// C3 and C1. FPREM cuts the quotient off; FPREM1 (nearest) takes the nearest, a tie to the
// even one.
fn rem80(am: u64, ase: u16, bm: u64, bse: u16, nearest: bool) -> u64, u16 {
    fp_cond &= 0xFFFF ^ (C0 | C1 | C2 | C3);
    let ea = exp80(ase);
    let eb = exp80(bse);
    let d = ea - eb;
    if d < 0 {
        // a is the smaller: it is its own remainder, with a quotient of zero; unless, for
        // FPREM1, it is over half of b (which needs the exponents one apart and a's
        // mantissa the larger): then b is taken once and the sign changes.
        if nearest && d == -1 && am > bm {
            let r = bm + bm - am;                 // b less a, at a's exponent
            fp_cond |= C1;
            let lz = clz(r);
            if ea - lz <= 0 { return 0, ase ^ 0x8000; }
            return r << lz, (ase ^ 0x8000) & 0x8000 | ((ea - lz) as! u16);
        }
        return am, ase;
    }
    let part = d >= 64;
    let steps = if part { 32 + d % 32 + 1 } else { d + 1 };
    var r = am;
    var carry = false;
    var q: u64 = 0;
    for it in steps {
        let ge = carry || r >= bm;
        q = q << 1 | (if ge { 1 } else { 0 });
        if ge { r -= bm; }
        if it != steps - 1 { carry = r >> 63 != 0; r = r << 1; }
    }
    var sign = ase & 0x8000;
    var e = if part { ea - (steps - 1) } else { eb };      // where r stands now
    if part { fp_cond |= C2; }
    else {
        if nearest {
            // Over half of b left, or exactly half with an odd quotient: one more of b is
            // taken, and the remainder changes sign.
            let over = r >> 63 != 0 || r << 1 > bm;
            let tie = r >> 63 == 0 && r << 1 == bm;
            if over || (tie && q & 1 != 0) {
                r = bm - r;
                sign ^= 0x8000;
                q += 1;
            }
        }
        if q & 1 != 0 { fp_cond |= C1; }
        if q & 2 != 0 { fp_cond |= C3; }
        if q & 4 != 0 { fp_cond |= C0; }
    }
    if r == 0 { return 0, sign; }
    let lz = clz(r);
    e -= lz;
    if e <= 0 { return 0, sign; }
    return r << lz, sign | (e as! u16);
}

fn fpu_reg(row: u8, r: u8, i: u8) {
    let a = st(0);
    let b = st(i);
    let s1 = st(1);                      // for D9 F0 to FF, where the r/m field is part of the opcode
    let am, ase = st80(0);
    let bm, bse = st80(i);
    match row << 3 | r {
        // D8: ST(0) = ST(0) op ST(i)
        0x00..0x08 => { arith_to(r, bm, bse, 0); },
        // D9
        0x08 => { fp_top = (fp_top + 7) & 7; copy_st(0, i + 1); },      // FLD ST(i)
        0x09 => { swap_st(i); },
        0x0A => { if i != 0 { fpu_unknown(); } },                       // FNOP
        0x0B => { copy_st(i, 0); fpop(); },
        0x0C => {
            match i {
                0 => { set_st80(0, am, ase ^ 0x8000); },                // FCHS
                1 => { set_st80(0, am, ase & 0x7FFF); },                // FABS
                4 => { set_cond(cmp80(am, ase, 0, 0)); },               // FTST
                5 => {                                                  // FXAM: what kind of number
                    fp_cond &= 0xFFFF ^ (C0 | C1 | C2 | C3);
                    if bits_of_f64(a) >> 63 != 0 { fp_cond |= C1; }
                    if fp_empty & bit8(fp_top) != 0 { fp_cond |= C0 | C3; }
                    else if is_nan(a) { fp_cond |= C0; }
                    else if is_inf(a) { fp_cond |= C0 | C2; }
                    else if a == 0.0 { fp_cond |= C3; }
                    else {
                        // Only an 80-bit original can be a denormal: an f64 denormal is not one in 80 bits.
                        let mant, se = st80(0);
                        if se & 0x7FFF == 0 && mant != 0 { fp_cond |= C2 | C3; } else { fp_cond |= C2; }
                    }
                },
                _ => { fpu_unknown(); },
            }
        },
        0x0D => {
            match i {
                0 => { fpush(1.0); },
                1 => { push_const(0xD49A784BCD1B8AFE, 0x4000, false); },    // log2(10)
                2 => { push_const(0xB8AA3B295C17F0BB, 0x3FFF, true); },     // log2(e)
                3 => { push_const(0xC90FDAA22168C234, 0x4000, true); },     // pi
                4 => { push_const(0x9A209A84FBCFF798, 0x3FFD, true); },     // log10(2)
                5 => { push_const(0xB17217F7D1CF79AB, 0x3FFE, true); },     // ln(2)
                6 => { fpush(0.0); },
                _ => { fpu_unknown(); },
            }
        },
        0x0E => {
            match i {
                0 => { set_st(0, expm1(a * 0.6931471805599453)); },     // F2XM1
                1 => { set_st(1, s1 * log2(a)); fpop(); },               // FYL2X
                2 => { set_st(0, tan(a)); fpush(1.0); fp_cond &= 0xFFFF ^ C2; },        // FPTAN
                3 => { set_st(1, atan2(s1, a)); fpop(); },               // FPATAN
                4 => {                                                  // FXTRACT
                    if a == 0.0 || !is_finite(a) { set_st(0, if a == 0.0 { -INF } else { abs(a) }); fpush(a); }
                    else if normal80(am, ase) {
                        // In integers: the exponent as a number, and the mantissa with an
                        // exponent of zero, all 64 bits of it (E098).
                        let em, ese = i64_to_f80(exp80(ase) - 16383);
                        set_st80(0, em, ese);
                        fpush(0.0);
                        set_st80(0, am, ase & 0x8000 | 0x3FFF);
                    }
                    else {
                        let e = logb(a);
                        set_st(0, e);
                        fpush(ldexp(a, -(e as! i32)));
                    }
                },
                5 => {                                                  // FPREM1
                    let dm, dse = st80(1);
                    if normal80(am, ase) && normal80(dm, dse) {
                        let m, se = rem80(am, ase, dm, dse, true);
                        set_st80(0, m, se);
                    } else { set_st(0, remainder(a, s1)); quotient_bits(rint(a / s1)); }
                },
                6 => { fp_top = (fp_top + 7) & 7; },                    // FDECSTP
                _ => { fp_top = (fp_top + 1) & 7; },                    // FINCSTP
            }
        },
        0x0F => {
            match i {
                // FPREM. The remainder is fmod, which is exact; ST(0) - q * ST(1) is not.
                0 => {
                    let dm, dse = st80(1);
                    if normal80(am, ase) && normal80(dm, dse) {
                        let m, se = rem80(am, ase, dm, dse, false);
                        set_st80(0, m, se);
                    } else { set_st(0, a % s1); quotient_bits(trunc(a / s1)); }
                },
                1 => { set_st(1, s1 * (log1p(a) / 0.6931471805599453)); fpop(); },       // FYL2XP1
                2 => {
                    // FSQRT: in integers for an ordinary positive number (E098).
                    var done = false;
                    if normal80(am, ase) && ase & 0x8000 == 0 {
                        let m, se, ok = sqrt80(am, ase);
                        if ok { set_st80(0, m, se); done = true; }
                    }
                    if !done { set_st(0, f_sqrt(a)); }
                },
                3 => { set_st(0, sin(a)); fpush(cos(a)); fp_cond &= 0xFFFF ^ C2; },     // FSINCOS
                4 => {                                                  // FRNDINT
                    var done = false;
                    if normal80(am, ase) {
                        let mag, ok = round80(am, ase, rc());
                        if !ok { done = true; }                         // 2^63 or more: already an integer
                        else if mag != 0 {
                            let m, se = i64_to_f80(mag as! i64);
                            set_st80(0, m, se | (ase & 0x8000));
                            done = true;
                        }
                    }
                    if !done { set_st(0, round_int(a)); }
                },
                5 => {                                                  // FSCALE
                    var e = trunc(s1);
                    if is_nan(e) { e = 0.0; }
                    if e > 99999.0 { e = 99999.0; }
                    if e < -99999.0 { e = -99999.0; }
                    let ne = exp80(ase) + (e as! i64);
                    if normal80(am, ase) && ne > 0 && ne < 0x7FFF { set_st80(0, am, ase & 0x8000 | (ne as! u16)); }
                    else { set_st(0, ldexp(a, e as! i32)); }
                },
                6 => { set_st(0, sin(a)); fp_cond &= 0xFFFF ^ C2; },
                _ => { set_st(0, cos(a)); fp_cond &= 0xFFFF ^ C2; },
            }
        },
        // DA: FCMOV on CF, ZF, CF or ZF, PF; and FUCOMPP
        0x10 => { if flag(CF) { copy_st(0, i); } },
        0x11 => { if flag(ZF) { copy_st(0, i); } },
        0x12 => { if flag(CF | ZF) { copy_st(0, i); } },
        0x13 => { if flag(PF) { copy_st(0, i); } },
        0x15 => { if i != 1 { fpu_unknown(); } set_cond(cmp_st(1)); fpop(); fpop(); },
        // DB: FCMOV on the opposite conditions, the housekeeping row, FUCOMI and FCOMI
        0x18 => { if !flag(CF) { copy_st(0, i); } },
        0x19 => { if !flag(ZF) { copy_st(0, i); } },
        0x1A => { if !flag(CF | ZF) { copy_st(0, i); } },
        0x1B => { if !flag(PF) { copy_st(0, i); } },
        0x1C => {
            match i {
                0, 1, 2, 4 => {},        // FNENI, FNDISI, FSETPM do nothing; FNCLEX has nothing to clear
                3 => { fpu_reset(); },   // FNINIT
                _ => { fpu_unknown(); },
            }
        },
        0x1D, 0x1E => { set_cmp_flags(cmp_st(i)); },
        // DC: ST(i) = ST(0) op ST(i), the reg field meaning what it means in the D8 row
        0x20..0x28 => { arith_to(r, bm, bse, i); },
        // DD
        0x28 => { fp_empty |= bit8(phys(i)); },                         // FFREE
        0x29 => { swap_st(i); },
        0x2A => { copy_st(i, 0); },
        0x2B => { copy_st(i, 0); fpop(); },
        0x2C => { set_cond(cmp_st(i)); },                               // FUCOM
        0x2D => { set_cond(cmp_st(i)); fpop(); },
        // DE: as DC, then pop; DE D9 is FCOMPP
        0x30, 0x31, 0x34..0x38 => { arith_to(r, bm, bse, i); fpop(); },
        0x32 => { set_cond(cmp_st(i)); fpop(); },
        0x33 => { if i != 1 { fpu_unknown(); } set_cond(cmp_st(1)); fpop(); fpop(); },
        // DF
        0x38 => { fp_empty |= bit8(phys(i)); fpop(); },                 // FFREEP
        0x3C => { if i != 0 { fpu_unknown(); } fp_set_ax(status()); },        // FNSTSW AX
        0x3D, 0x3E => { set_cmp_flags(cmp_st(i)); fpop(); },
        _ => { fpu_unknown(); },
    }
}

// An escape opcode, D8 to DF, after its ModRM byte has been decoded.
fn fpu_escape(op: u8) {
    cpu_op = op;
    if m_mod == 3 { fpu_reg(op & 7, m_reg, m_rm); }
    else { fpu_mem(op & 7, m_reg); }
}
