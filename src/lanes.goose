// What MMX and SSE2 compute, apart from any CPU: the packed integers lane by lane, the
// shifts, unpacking, packing and shuffling of lanes, and the floats with the chip's rules
// for what is not a number. The i686 machine (sse.goose) and the 64-bit CPU (sse64.goose)
// both use these; nothing here reads or writes a register, memory or a global.
//
// A value is one 64-bit word of a register: an MMX register is one, an XMM register two.

import std;
import math;

let LOW32: u64 = 0xFFFFFFFF;

// Rounds to a whole number by the host's rounding mode, which is to nearest, ties to even.
extern fn rint(x: f64) -> f64 = "rint";

// A float's bits as an integer, and back.
extern fn f32_of_bits(bits: u32) -> f32 = "gs_f32_from_bits";
extern fn f64_of_bits(bits: u64) -> f64 = "gs_f64_from_bits";
extern fn bits_of_f32(v: f32) -> u32 = "gs_f32_to_bits";
extern fn bits_of_f64(v: f64) -> u64 = "gs_f64_to_bits";

// ---- Packed integers, lane by lane ----

fn sxl(x: u64, w: u32) -> i64 {
    let sh: u64 = 64 - w;
    return ((x << sh) as! i64) >> sh;
}

// How wide the lanes of an instruction are; 0 for one that is not lane by lane.
fn lane_w(op: u8) -> u32 {
    match op {
        0xFC, 0xF8, 0xDC, 0xD8, 0xEC, 0xE8, 0x74, 0x64, 0xDA, 0xDE, 0xE0 => { return 8; },
        0xFD, 0xF9, 0xDD, 0xD9, 0xED, 0xE9, 0x75, 0x65, 0xD5, 0xE5, 0xE4, 0xEA, 0xEE, 0xE3 => { return 16; },
        0xFE, 0xFA, 0x76, 0x66 => { return 32; },
        _ => { return 0; },
    }
}

// One lane: x and y are the lanes' bits, w their width (8, 16 or 32).
fn lane(op: u8, x: u64, y: u64, w: u32) -> u64 {
    let one: u64 = 1;
    let m = (one << w) - 1;
    let a = sxl(x, w);
    let b = sxl(y, w);
    let top: i64 = (1 as i64) << (w - 1);
    var s: i64 = 0;
    match op {
        0xFC, 0xFD, 0xFE => { return x + y; },                           // PADD
        0xF8, 0xF9, 0xFA => { return x + (m + 1 - y); },                 // PSUB
        0xDC, 0xDD => { return if x + y > m { m } else { x + y }; },     // PADDUS
        0xD8, 0xD9 => { return if x > y { x - y } else { 0 }; },         // PSUBUS
        0xEC, 0xED => { s = a + b; },                                    // PADDS
        0xE8, 0xE9 => { s = a - b; },                                    // PSUBS
        0x74, 0x75, 0x76 => { return if x == y { m } else { 0 }; },      // PCMPEQ
        0x64, 0x65, 0x66 => { return if a > b { m } else { 0 }; },       // PCMPGT
        0xD5 => { return (a * b) as! u64; },                             // PMULLW
        0xE5 => { return ((a * b) >> 16) as! u64; },                     // PMULHW
        0xE4 => { return x * y >> 16; },                                 // PMULHUW
        0xDA => { return if x < y { x } else { y }; },                   // PMINUB
        0xDE => { return if x > y { x } else { y }; },                   // PMAXUB
        0xEA => { return (if a < b { a } else { b }) as! u64; },         // PMINSW
        0xEE => { return (if a > b { a } else { b }) as! u64; },         // PMAXSW
        _ => { return (x + y + 1) >> 1; },                               // PAVG
    }
    if s > top - 1 { s = top - 1; }
    if s < -top { s = -top; }
    return s as! u64;
}

// A packed integer instruction on one 64-bit word. False in `known` for an opcode that is none.
fn pop64(op: u8, a: u64, b: u64) -> u64, bool {
    match op {
        0xDB => { return a & b, true; },
        0xDF => { return ~a & b, true; },
        0xEB => { return a | b, true; },
        0xEF => { return a ^ b, true; },
        0xD4 => { return a + b, true; },                                 // PADDQ
        0xFB => { return a + (~b + 1), true; },                          // PSUBQ
        0xF4 => { return (a & LOW32) * (b & LOW32), true; },                 // PMULUDQ
        0xF5 => {
            // PMADDWD: the products of the words, added in pairs.
            var r: u64 = 0;
            for i: u32 in 2 {
                let p0 = sxl(a >> (i * 32), 16) * sxl(b >> (i * 32), 16);
                let p1 = sxl(a >> (i * 32 + 16), 16) * sxl(b >> (i * 32 + 16), 16);
                r |= (((p0 + p1) as! u64) & LOW32) << (i * 32);
            }
            return r, true;
        },
        0xF6 => {
            // PSADBW: the sum of the bytes' differences.
            var sum: u64 = 0;
            for i: u32 in 8 {
                let x = a >> (i * 8) & 0xFF;
                let y = b >> (i * 8) & 0xFF;
                sum += if x > y { x - y } else { y - x };
            }
            return sum, true;
        },
        _ => {},
    }
    let w = lane_w(op);
    if w == 0 { return 0, false; }
    let one: u64 = 1;
    let m = (one << w) - 1;
    var r: u64 = 0;
    var at: u32 = 0;
    while at < 64 {
        r |= (lane(op, a >> at & m, b >> at & m, w) & m) << at;
        at += w;
    }
    return r, true;
}

// A shift of every lane of a word by n: kind 0 right, 1 right keeping the sign, 2 left.
fn pshift(kind: u8, w: u32, a: u64, n: u64) -> u64 {
    if w == 64 {
        if n > 63 { return 0; }
        return if kind == 2 { a << n } else { a >> n };
    }
    let one: u64 = 1;
    let m = (one << w) - 1;
    var r: u64 = 0;
    var at: u32 = 0;
    while at < 64 {
        let x = a >> at & m;
        var v: u64 = 0;
        if kind == 1 {
            let c: u64 = if n > w - 1 { w - 1 } else { n };
            v = (sxl(x, w) >> c) as! u64;
        } else if n < w {
            v = if kind == 2 { x << n } else { x >> n };
        }
        r |= (v & m) << at;
        at += w;
    }
    return r;
}

// The lanes of x and y, e bits each, taken in turn: x0 y0 x1 y1 ... The first 64 bits and the
// rest.
fn weave(x: u64, y: u64, e: u32) -> u64, u64 {
    let one: u64 = 1;
    let m = if e == 32 { LOW32 } else { (one << e) - 1 };
    var lo: u64 = 0;
    var hi: u64 = 0;
    let n: u32 = 64 / e;
    for i: u32 in n {
        let a = x >> (i * e) & m;
        let b = y >> (i * e) & m;
        let at = i * 2 * e;
        if at < 64 { lo |= a << at | b << (at + e); } else { hi |= a << (at - 64) | b << (at - 64 + e); }
    }
    return lo, hi;
}

// The lanes of x, w bits each, each squeezed into half as many bits: by its sign, or (to an
// unsigned byte) from 0 to 255.
fn pack(x: u64, w: u32, unsigned: bool) -> u64 {
    let h = w / 2;
    let one: u64 = 1;
    let hm = (one << h) - 1;
    var r: u64 = 0;
    let n: u32 = 64 / w;
    for i: u32 in n {
        var v = sxl(x >> (i * w), w);
        let top: i64 = (1 as i64) << (h - 1);
        if unsigned {
            if v < 0 { v = 0; }
            if v > top * 2 - 1 { v = top * 2 - 1; }
        } else {
            if v > top - 1 { v = top - 1; }
            if v < -top { v = -top; }
        }
        r |= ((v as! u64) & hm) << (i * h);
    }
    return r;
}

// The two-operand packed integer instructions that MMX and SSE2 share, on words a (the
// destination's) and b (the source's); with wide, XMM. False for an opcode that is none.
fn pint(op: u8, wide: bool, a0: u64, a1: u64, b0: u64, b1: u64) -> u64, u64, bool {
    // Shifts by the count in the source's low word.
    var kind: u8 = 255;
    var w: u32 = 0;
    match op {
        0xD1 => { kind = 0; w = 16; }, 0xD2 => { kind = 0; w = 32; }, 0xD3 => { kind = 0; w = 64; },
        0xE1 => { kind = 1; w = 16; }, 0xE2 => { kind = 1; w = 32; },
        0xF1 => { kind = 2; w = 16; }, 0xF2 => { kind = 2; w = 32; }, 0xF3 => { kind = 2; w = 64; },
        _ => {},
    }
    if kind != 255 { return pshift(kind, w, a0, b0), pshift(kind, w, a1, b0), true; }
    match op {
        0x60, 0x61, 0x62 => {
            let e: u32 = if op == 0x60 { 8 } else if op == 0x61 { 16 } else { 32 };
            if wide { let lo, hi = weave(a0, b0, e); return lo, hi, true; }
            let lo, hi = weave(a0 & LOW32, b0 & LOW32, e);
            return lo, 0, true;
        },
        0x68, 0x69, 0x6A => {
            let e: u32 = if op == 0x68 { 8 } else if op == 0x69 { 16 } else { 32 };
            if wide { let lo, hi = weave(a1, b1, e); return lo, hi, true; }
            let lo, hi = weave(a0 >> 32, b0 >> 32, e);
            return lo, 0, true;
        },
        0x6C => { return a0, b0, wide; },                                // PUNPCKLQDQ
        0x6D => { return a1, b1, wide; },                                // PUNPCKHQDQ
        0x63, 0x67, 0x6B => {
            let pw: u32 = if op == 0x6B { 32 } else { 16 };
            let un = op == 0x67;
            if wide { return pack(a0, pw, un) | pack(a1, pw, un) << 32, pack(b0, pw, un) | pack(b1, pw, un) << 32, true; }
            return pack(a0, pw, un) | pack(b0, pw, un) << 32, 0, true;
        },
        _ => {},
    }
    let r0, known = pop64(op, a0, b0);
    if !known { return 0, 0, false; }
    if !wide { return r0, 0, true; }
    let r1, k1 = pop64(op, a1, b1);
    return r0, r1, true;
}

// ---- Floats ----

fn fs(q: u64, i: u32) -> f64 { return f32_of_bits((q >> (i * 32)) as! u32); }
fn sbits(v: f64) -> u64 { return bits_of_f32(v as! f32); }
fn fd(q: u64) -> f64 { return f64_of_bits(q); }
fn dbits(v: f64) -> u64 { return bits_of_f64(v); }

// Add, subtract, multiply, divide, the square root, and the two reciprocals, which are exact
// here where the chip's are approximate. Not for an operand that is not a number.
fn fop(op: u8, a: f64, b: f64) -> f64 {
    match op {
        0x58 => { return a + b; },
        0x59 => { return a * b; },
        0x5C => { return a - b; },
        0x5E => { return a / b; },
        0x51 => { return sqrt(b); },
        0x52 => { return 1.0 / sqrt(b); },
        _ => { return 1.0 / b; },
    }
}

// The same on the bits of two singles (in the low halves of a and b) and of two doubles, with
// what the chip does where a number is missing, which the host's arithmetic does otherwise:
// - the smaller and the larger give the second operand when either is not a number, and
//   when the two are equal (so for zeros of both signs);
// - an operand that is not a number comes out, the first before the second, made quiet;
// - a result that is not a number, of operands that were, is the one "real indefinite":
//   quiet, with the sign set.
fn nan32(x: u64) -> bool { return x & 0x7F800000 == 0x7F800000 && x & 0x007FFFFF != 0; }
fn nan64(x: u64) -> bool { return x & 0x7FF0000000000000 == 0x7FF0000000000000 && x & 0x000FFFFFFFFFFFFF != 0; }

fn far32(op: u8, a0: u64, b0: u64) -> u64 {
    let a = a0 & LOW32;
    let b = b0 & LOW32;
    if op == 0x5D || op == 0x5F {
        if nan32(a) || nan32(b) { return b; }
        let x = fs(a, 0);
        let y = fs(b, 0);
        return if (op == 0x5D && x < y) || (op == 0x5F && x > y) { a } else { b };
    }
    let unary = op == 0x51 || op == 0x52 || op == 0x53;
    if !unary && nan32(a) { return a | 0x00400000; }
    if nan32(b) { return b | 0x00400000; }
    let r = sbits(fop(op, fs(a, 0), fs(b, 0)));
    return if nan32(r) { 0xFFC00000 } else { r };
}

fn far64(op: u8, a: u64, b: u64) -> u64 {
    if op == 0x5D || op == 0x5F {
        if nan64(a) || nan64(b) { return b; }
        let x = fd(a);
        let y = fd(b);
        return if (op == 0x5D && x < y) || (op == 0x5F && x > y) { a } else { b };
    }
    if op != 0x51 && nan64(a) { return a | 0x0008000000000000; }
    if nan64(b) { return b | 0x0008000000000000; }
    let r = dbits(fop(op, fd(a), fd(b)));
    return if nan64(r) { 0xFFF8000000000000 } else { r };
}

// A comparison by predicate 0 to 7: equal, less, less or equal, unordered, and their opposites.
fn fcmp(pred: u8, a: f64, b: f64) -> bool {
    let un = is_nan(a) || is_nan(b);
    match pred & 7 {
        0 => { return !un && a == b; },
        1 => { return !un && a < b; },
        2 => { return !un && a <= b; },
        3 => { return un; },
        4 => { return un || a != b; },
        5 => { return un || !(a < b); },
        6 => { return un || !(a <= b); },
        _ => { return !un; },
    }
}

// A float as a 32-bit integer, cut off or rounded to nearest; out of range, or not a number,
// the "integer indefinite".
fn f2i(v: f64, cut: bool) -> u64 {
    let x = if cut { v } else { rint(v) };
    if is_nan(x) || x <= -2147483649.0 || x >= 2147483648.0 { return 0x80000000; }
    return ((x as! i64) as! u64) & LOW32;
}

fn i2f(v: u64) -> f64 { return sxl(v, 32); }

// A shuffle of four lanes of e bits each inside a word, by two bits of `imm` to a lane.
fn shuf4(x: u64, e: u32, imm: u32) -> u64 {
    let one: u64 = 1;
    let m = (one << e) - 1;
    var r: u64 = 0;
    for i: u32 in 4 { r |= (x >> ((imm >> (i * 2) & 3) * e) & m) << (i * e); }
    return r;
}
