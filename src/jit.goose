// A JIT for arm64 (E059, E061). With --jit, runs of 32-bit instructions are translated into
// host code, block by block. See docs/experiments.md, E059 and E061, for the design; this file
// is the translator, and jit.c the C it needs.
//
// Host registers in generated code:
//   x0        the address of cpu.regs (the rest of the CPU state is at fixed places from it)
//   x19       the address of RAM
//   x20       the address of the TLB: tlb_rtag, with tlb_rphys, tlb_wtag and tlb_wphys behind it
//   x21       the address of seg_top
//   w22       what a physical address of the page of code is above the instruction pointer
//   w8..w15   EAX ECX EDX EBX ESP EBP ESI EDI, loaded on entry, stored back where changed
//   w1 w2 w3  the operands and the result of the last instruction that set the flags
//   w4        which half of the TLB the current privilege level uses: 0 or 100h
//   w16 w17 w6 w5 w7  scratch
//   x23       the time left: how many instructions may still be executed before control has
//             to go back (a block takes its length off it where it begins)
//   x24       what x23 was on the way in; x25 the virtual time then
// Generated code is entered at the start of the mapping (jit_init), which saves the registers
// a C function must keep, loads the ones above and the guest's eight, and jumps to a block.
// It is left through the code behind that, with the next instruction's physical address in
// w16 and, in x17, the address of the link slot it left through or 0: that code stores the
// guest's eight registers and returns the address with the count of instructions executed
// above it. In between, a block that ends at a known address in its page branches through a
// link slot, which goes to the way out until jit_blocks has seen where it leads and makes it
// a branch to the next block (E065).

import state;

extern fn jit_alloc(size: i64) -> i64;
extern fn jit_write(at: i64, code: const u8[:]);
extern fn jit_call(enter: i64, regs: u32[:], ram: i64, tlb: i64, seg: i64, pbase: i64, code: i64, time: i64, vt: i64) -> i64;
extern fn jit_slot() -> i64;
extern fn jit_addr8(a: const u8[:]) -> i64;
extern fn jit_addr32(a: const u32[:]) -> i64;

var jit_on = false;
var jit_mem = 0;             // where the code is mapped
var jit_used = 0;            // how much of it holds code
var jit_blocks_made = 0;     // blocks translated
var jit_room = 33554432;     // how much of the mapping is used before the code is dropped: --jit-size makes it
                             // small, so that a test can see the code fill up
var jit_flushes = 0;         // times the code filled up and was dropped
var jit_calls = 0;           // times generated code was entered
var jit_links = 0;           // link slots filled in
// For finding a wrong translation: groups of kinds the translator is told to leave alone
// (--jit-off, one bit each; see jit_plain).
var jit_off: u32 = 0;            // times a block left before its end
var jit_ran = 0;             // guest instructions executed in blocks
var run_pmax: u32 = 0;       // the highest address the current run may execute at (exec_short)
let JIT_SIZE = 33554432;     // 32 MB
let JIT_HOT = 8;             // arrivals at a jump's target before it is translated
let JIT_MAX = 60;            // instructions in a block at most
let FLAGS_AT = 0x78;         // cpu.flags from cpu.regs

var jit_out_at = 0;          // where in the mapping the way out is
var jit_keep = 0;            // how much of the mapping is the way in and out, which a flush keeps
var jit_ram = 0;             // where RAM, the TLB and seg_top are, for generated code
var jit_tlb = 0;
var jit_seg = 0;

let R_A = 1;                 // the flags' record
let R_B = 2;
let R_R = 3;
let R_MODE = 4;
let T1 = 16;                 // scratch
let T2 = 17;
let T3 = 6;
let T4 = 5;
let BASE_AT = 0x2C;          // cpu.base from cpu.regs
let CPL_AT = 0x7C;           // cpu.cpl

fn jit_init() {
    jit_mem = jit_alloc(JIT_SIZE);
    if jit_mem == 0 { return; }
    jit_ram = jit_addr8(ram[..]);
    jit_tlb = jit_addr32(tlb_rtag[..]);
    jit_seg = jit_addr32(seg_top[..]);
    // Generated code reaches the four TLB arrays from one address.
    if jit_addr32(tlb_rphys[..]) != jit_tlb + 2048 || jit_addr32(tlb_wtag[..]) != jit_tlb + 4096
        || jit_addr32(tlb_wphys[..]) != jit_tlb + 6144 { return; }
    // The way in: x0 the registers, x1 RAM, x2 the TLB, x3 seg_top, x4 pbase, x5 the block,
    // x6 the time, x7 the virtual time.
    e(0xA9BB7BFD);           // stp x29, x30, [sp, #-80]!
    e(0xA90153F3);           // stp x19, x20, [sp, #16]
    e(0xA9025BF5);           // stp x21, x22, [sp, #32]
    e(0xA90363F7);           // stp x23, x24, [sp, #48]
    e(0xF90023F9);           // str x25, [sp, #64]
    e(0xAA0103F3);           // mov x19, x1
    e(0xAA0203F4);           // mov x20, x2
    e(0xAA0303F5);           // mov x21, x3
    e(0xAA0403F6);           // mov x22, x4
    e(0xAA0603F7);           // mov x23, x6
    e(0xAA0603F8);           // mov x24, x6
    e(0xAA0703F9);           // mov x25, x7
    e(0x29402408);           // ldp w8, w9, [x0]
    e(0x29412C0A);           // ldp w10, w11, [x0, #8]
    e(0x2942340C);           // ldp w12, w13, [x0, #16]
    e(0x29433C0E);           // ldp w14, w15, [x0, #24]
    e(0x3941F004);           // ldrb w4, [x0, #CPL_AT]: 100h for the user's half of the TLB
    e(0x71000C9F);           // cmp w4, #3
    e(0x1A9F17E4);           // cset w4, eq
    e(0x53185C84);           // lsl w4, w4, #8
    e(0xD61F00A0);           // br x5
    // The way out: w16 the next address, x17 the link slot or 0.
    jit_out_at = jc.len;
    e(0x29002408);           // stp w8, w9, [x0]
    e(0x29012C0A);           // stp w10, w11, [x0, #8]
    e(0x2902340C);           // stp w12, w13, [x0, #16]
    e(0x29033C0E);           // stp w14, w15, [x0, #24]
    e(0xCB170301);           // sub x1, x24, x23: the instructions executed
    e(0xAA018200);           // orr x0, x16, x1, lsl #32
    e(0xAA1103E1);           // mov x1, x17
    e(0xF94023F9);           // ldr x25, [sp, #64]
    e(0xA94363F7);           // ldp x23, x24, [sp, #48]
    e(0xA9425BF5);           // ldp x21, x22, [sp, #32]
    e(0xA94153F3);           // ldp x19, x20, [sp, #16]
    e(0xA8C57BFD);           // ldp x29, x30, [sp], #80
    e(0xD65F03C0);           // ret
    jit_write(jit_mem, jc[..]);
    jit_used = jc.len;
    jit_keep = jc.len;
    jit_on = true;
}

// ---- arm64 ----

var jc: u8[>..];             // the block being generated

fn e(w: u32) {
    jc.push(w as! u8);
    jc.push((w >> 8) as! u8);
    jc.push((w >> 16) as! u8);
    jc.push((w >> 24) as! u8);
}

fn g(i: u32) -> u32 { return 8 + (i & 7); }                          // a guest register's host register

fn a_mov(rd: u32, rm: u32) { e(0x2A0003E0 | rm << 16 | rd); }        // mov wd, wm
fn a_movi(rd: u32, v: u32) {                                         // mov wd, #v
    let lo = v & 0xFFFF;
    let hi = v >> 16;
    if hi == 0 { e(0x52800000 | lo << 5 | rd); return; }
    if lo == 0 { e(0x52A00000 | hi << 5 | rd); return; }
    e(0x52800000 | lo << 5 | rd);
    e(0x72A00000 | hi << 5 | rd);
}
// wd = wn op wm, with wm shifted left by sh. op: 0 add 1 adds 2 sub 3 subs 4 and 5 orr 6 eor 7 ands
fn a_op(op: u32, rd: u32, rn: u32, rm: u32, sh: u32) {
    let base: u32 = match op {
        0 => 0x0B000000,
        1 => 0x2B000000,
        2 => 0x4B000000,
        3 => 0x6B000000,
        4 => 0x0A000000,
        5 => 0x2A000000,
        6 => 0x4A000000,
        _ => 0x6A000000,
    };
    e(base | rm << 16 | sh << 10 | rn << 5 | rd);
}
// The same with wm shifted right.
fn a_op_lsr(op: u32, rd: u32, rn: u32, rm: u32, sh: u32) {
    let base: u32 = match op { 4 => 0x0A400000, 5 => 0x2A400000, _ => 0x4A400000 };
    e(base | rm << 16 | sh << 10 | rn << 5 | rd);
}
fn a_addi(rd: u32, rn: u32, v: u32) { e(0x11000000 | v << 10 | rn << 5 | rd); }      // add wd, wn, #v (v < 4096)
fn a_addsi(rd: u32, rn: u32, v: u32) { e(0x31000000 | v << 10 | rn << 5 | rd); }
fn a_subi(rd: u32, rn: u32, v: u32) { e(0x51000000 | v << 10 | rn << 5 | rd); }
fn a_subsi(rd: u32, rn: u32, v: u32) { e(0x71000000 | v << 10 | rn << 5 | rd); }
fn a_lsr(rd: u32, rn: u32, s: u32) { e(0x53007C00 | s << 16 | rn << 5 | rd); }       // lsr wd, wn, #s
fn a_lsl(rd: u32, rn: u32, s: u32) { e(0x53000000 | (32 - s & 31) << 16 | (31 - s) << 10 | rn << 5 | rd); }
fn a_cset(rd: u32, cond: u32) { e(0x1A9F07E0 | (cond ^ 1) << 12 | rd); }             // cset wd, cond
fn a_ldr(rt: u32, off: u32) { e(0xB9400000 | (off >> 2) << 10 | rt); }               // ldr wt, [x0, #off]
fn a_str(rt: u32, off: u32) { e(0xB9000000 | (off >> 2) << 10 | rt); }
fn a_ldp(r1: u32, r2: u32, off: u32) { e(0x29400000 | (off >> 2) << 15 | r2 << 10 | r1); }   // ldp w1, w2, [x0, #off]
fn a_stp(r1: u32, r2: u32, off: u32) { e(0x29000000 | (off >> 2) << 15 | r2 << 10 | r1); }
fn a_ret() { e(0xD65F03C0); }
fn a_ldrn(rt: u32, rn: u32, off: u32) { e(0xB9400000 | (off >> 2) << 10 | rn << 5 | rt); }    // ldr wt, [xn, #off]
// A load or a store of n bytes at [x19, x6]: in RAM, at the place j_mem worked out.
fn a_load(n: u32, rt: u32) { e((if n == 4 { 0xB8606800 } else if n == 2 { 0x78606800 } else { 0x38606800 }) | T3 << 16 | 19 << 5 | rt); }
fn a_store(n: u32, rt: u32) { e((if n == 4 { 0xB8206800 } else if n == 2 { 0x78206800 } else { 0x38206800 }) | T3 << 16 | 19 << 5 | rt); }
// A branch from here to the way out. jb is where in the mapping the block being generated
// will be.
fn a_out() {
    let d: u32 = ((jit_out_at - (jb + jc.len)) >> 2) as! u32;
    e(0x14000000 | d & 0x3FFFFFF);
}
// Sets the instruction at `at`, a branch emitted as its opcode alone, to go to `to`.
fn a_patch(at: i64, to: i64) {
    let d: u32 = ((to - at) >> 2) as! u32;
    var w: u32 = jc[at + 3];
    w = w << 24;
    if w == 0x54000000 || w == 0x34000000 || w == 0x35000000 { w = w | (d & 0x7FFFF) << 5 | jc[at]; } else { w = w | d & 0x3FFFFFF; }
    jc[at] = w as! u8;
    jc[at + 1] = (w >> 8) as! u8;
    jc[at + 2] = (w >> 16) as! u8;
    jc[at + 3] = (w >> 24) as! u8;
}

// arm64 conditions, and two that are not: taken always, taken never, and no translation.
let C_EQ = 0;
let C_NE = 1;
let C_HS = 2;
let C_LO = 3;
let C_MI = 4;
let C_PL = 5;
let C_VS = 6;
let C_VC = 7;
let C_HI = 8;
let C_LS = 9;
let C_GE = 10;
let C_LT = 11;
let C_GT = 12;
let C_LE = 13;
let C_ALWAYS = 14;
let C_NEVER = 15;
let C_NONE = 255;

// ---- flags ----

// Which instruction set the flags last in the block being generated.
let F_MEM = 0;       // none: EFLAGS in memory is right
let F_LOGIC = 1;     // AND OR XOR TEST: the result in w5
let F_ADD = 2;       // w5 = w3 + w4
let F_SUB = 3;       // w5 = w3 - w4
let F_INC = 4;       // w5 = w3 + 1, w4 = 1; CF is not touched
let F_DEC = 5;       // the result = a - 1, b = 1
let F_ADD8 = 6;      // an 8-bit ADD: a and b are the operands shifted up 24 bits, the result their sum
let F_SUB8 = 7;      // an 8-bit SUB or CMP, the same way
let F_SH = 8;        // a shift by more than one: the result, and CF in a; OF and AF are not touched
let F_SH1 = 9;       // a shift by one: OF in b as well

// ZF, SF and PF of the result in host register r, ORed into the flags in f; sc is scratch.
// With high set, the result is an 8-bit one in r's top byte.
fn j_szp(f: u32, r: u32, sc: u32, high: bool) {
    a_subsi(31, r, 0);                       // ZF
    a_cset(sc, C_EQ);
    a_op(5, f, f, sc, 6);
    a_lsr(sc, r, 31);                        // SF
    a_op(5, f, f, sc, 7);
    if high { a_lsr(sc, r, 24); a_op_lsr(6, sc, sc, sc, 4); } else { a_op_lsr(6, sc, r, r, 4); }
    a_op_lsr(6, sc, sc, sc, 2);              // PF: the low byte's bits folded into bit 0
    a_op_lsr(6, sc, sc, sc, 1);
    e(0x12000000 | sc << 5 | sc);            // and sc, sc, #1
    e(0x52000000 | sc << 5 | sc);            // eor sc, sc, #1
    a_op(5, f, f, sc, 2);
}

// Writes EFLAGS out from the record. What alu(), inc(), dec() and the shifts leave, bit for
// bit.
fn jit_flags(ft: u8) {
    if ft == F_MEM { return; }
    let high = ft == F_ADD8 || ft == F_SUB8;
    let add = ft == F_ADD || ft == F_ADD8;
    let sub = ft == F_SUB || ft == F_SUB8;
    a_ldr(T1, FLAGS_AT);
    a_movi(T2, if ft == F_SH { 0xFFFFFF3A } else if ft == F_SH1 { 0xFFFFF73A } else if ft == F_INC || ft == F_DEC { 0xFFFFF72B } else { 0xFFFFF72A });
    a_op(4, T1, T1, T2, 0);
    j_szp(T1, R_R, T2, high);
    if ft == F_SH || ft == F_SH1 {
        a_op(5, T1, T1, R_A, 0);             // CF: the last bit shifted out
        if ft == F_SH1 { a_op(5, T1, T1, R_B, 11); }
    } else if ft != F_LOGIC {
        if add {                             // CF: the sum is below an operand
            a_op(3, 31, R_R, R_A, 0);
            a_cset(T2, C_LO);
            a_op(5, T1, T1, T2, 0);
        } else if sub {                      // CF: a borrow
            a_op(3, 31, R_A, R_B, 0);
            a_cset(T2, C_LO);
            a_op(5, T1, T1, T2, 0);
        }
        if add || ft == F_INC {              // OF: both operands differ in sign from the sum
            a_op(6, T2, R_A, R_R, 0);
            a_op(6, T3, R_B, R_R, 0);
        } else {                             // OF: the operands differ, and the first from the difference
            a_op(6, T2, R_A, R_B, 0);
            a_op(6, T3, R_A, R_R, 0);
        }
        a_op(4, T2, T2, T3, 0);
        a_lsr(T2, T2, 31);
        a_op(5, T1, T1, T2, 11);
        a_op(6, T2, R_A, R_B, 0);            // AF
        a_op(6, T2, T2, R_R, 0);
        if high { a_lsr(T2, T2, 24); }
        e(0x121C0000 | T2 << 5 | T2);        // and w17, w17, #0x10
        a_op(5, T1, T1, T2, 0);
    }
    a_str(T1, FLAGS_AT);
}

// The host condition for x86 condition cc after an instruction of kind ft, once jit_compare
// has set the host's flags; C_NONE where there is none.
fn jit_cond(ft: u8, cc: u8) -> u8 {
    if ft == F_MEM || cc == 10 || cc == 11 { return C_NONE; }
    if ft == F_SH || ft == F_SH1 {
        // Of a shift, the result's zero and sign only.
        if cc == 4 { return C_EQ; }
        if cc == 5 { return C_NE; }
        if cc == 8 { return C_MI; }
        if cc == 9 { return C_PL; }
        return C_NONE;
    }
    if ft == F_LOGIC {
        match cc {
            0, 2 => { return C_NEVER; },
            1, 3 => { return C_ALWAYS; },
            4, 6 => { return C_EQ; },
            5, 7 => { return C_NE; },
            8, 12 => { return C_MI; },
            9, 13 => { return C_PL; },
            14 => { return C_LE; },
            _ => { return C_GT; },
        }
    }
    let carry = ft == F_ADD || ft == F_SUB || ft == F_ADD8 || ft == F_SUB8;
    let sub = ft == F_SUB || ft == F_SUB8 || ft == F_DEC;
    match cc {
        0 => { return C_VS; },
        1 => { return C_VC; },
        2 => { if !carry { return C_NONE; } return if sub { C_LO } else { C_HS }; },
        3 => { if !carry { return C_NONE; } return if sub { C_HS } else { C_LO }; },
        4 => { return C_EQ; },
        5 => { return C_NE; },
        6 => { return if carry && sub { C_LS } else { C_NONE }; },
        7 => { return if carry && sub { C_HI } else { C_NONE }; },
        8 => { return C_MI; },
        9 => { return C_PL; },
        12 => { return C_LT; },
        13 => { return C_GE; },
        14 => { return C_LE; },
        _ => { return C_GT; },
    }
}

// Sets the host's flags from the record, as the instruction that made it would have.
fn jit_compare(ft: u8) {
    if ft == F_LOGIC || ft == F_SH || ft == F_SH1 { a_subsi(31, R_R, 0); }
    else if ft == F_ADD || ft == F_ADD8 { a_op(1, 31, R_A, R_B, 0); }
    else if ft == F_SUB || ft == F_SUB8 { a_op(3, 31, R_A, R_B, 0); }
    else if ft == F_INC { a_addsi(31, R_A, 1); }
    else { a_subsi(31, R_A, 1); }
}

// ---- a block ----

var jf: u8 = 0;              // which instruction set the flags last, so far in the block
var jd: u32 = 0;             // (which guest registers the block has written: no longer used)
var jb = 0;                  // where in the mapping the block being generated will be

// The ways out of a block before an instruction whose memory operand is not on the short
// path. Each is a few instructions after the block's body: the time the block took for the
// instructions it will not now execute is given back, the instruction's own address is what
// is returned, and the flags are written out by code the ways out share, one piece for each
// kind of record.
let SX_MAX = 64;
var sx_n = 0;
var sx_jf: u8[SX_MAX] = [0; SX_MAX];
var sx_next: u32[SX_MAX] = [0; SX_MAX];
var sx_cnt: u32[SX_MAX] = [0; SX_MAX];
let ST_MAX = 256;
var st_n = 0;                // the branches to them, to be filled in
var st_at: i64[ST_MAX] = [0; ST_MAX];
var st_sx: i64[ST_MAX] = [0; ST_MAX];
// The link slots: the block's exits to fixed addresses. A slot is one branch; it goes to a
// few instructions after the body that leave with the address and the slot's own.
let LK_MAX = 4;
var lk_n = 0;
var lk_at: i64[LK_MAX] = [0; LK_MAX];
var lk_next: u32[LK_MAX] = [0; LK_MAX];

// w16 = v.
fn a_next(rd: u32, v: u32) {
    e(0x52800000 | (v & 0xFFFF) << 5 | rd);
    e(0x72A00000 | (v >> 16) << 5 | rd);
}

// Leaves the block for the instruction at `next`: the flags written out, then a link slot.
fn jit_leave(next: u32) {
    jit_flags(jf);
    lk_at[lk_n] = jc.len;
    lk_next[lk_n] = next;
    lk_n += 1;
    e(0x14000000);
}

// A way out before the instruction at address p, the block having executed cnt instructions.
// The accesses of that instruction branch to it (j_mem).
fn jit_exit_here(p: u32, cnt: u32) {
    sx_jf[sx_n] = jf;
    sx_next[sx_n] = p;
    sx_cnt[sx_n] = cnt;
    sx_n += 1;
}

// A branch on host condition c to the way out made last.
fn j_out(c: u32) {
    st_at[st_n] = jc.len;
    st_sx[st_n] = sx_n - 1;
    st_n += 1;
    e(0x54000000 | c);
}

// What comes after the body of a block of n instructions that begins at p0: where the link
// slots go until they are linked, the ways out, the flags' code they share, and where the
// block goes when there is no time for it. `short_at` is the branch to that last.
fn jit_exits(n: u32, p0: u32, short_at: i64) {
    for k in lk_n {
        a_patch(lk_at[k], jc.len);
        a_next(T1, lk_next[k]);
        let off: u32 = (lk_at[k] - jc.len) as! u32;
        e(0x10000000 | (off & 3) << 29 | (off >> 2 & 0x7FFFF) << 5 | T2);  // adr x17, the slot
        a_out();
    }
    var at: i64[SX_MAX] = [0; SX_MAX];
    var tail_from: i64[SX_MAX] = [0; SX_MAX];
    for k in sx_n {
        at[k] = jc.len;
        e(0x91000000 | (n - sx_cnt[k]) << 10 | 23 << 5 | 23);              // add x23, x23, #(n - cnt)
        // The address waits in w7 while the flags are written out: that code uses w16.
        if sx_jf[k] == F_MEM { a_next(T1, sx_next[k]); e(0xD2800011); a_out(); }
        else { a_next(7, sx_next[k]); tail_from[k] = jc.len; e(0x14000000); }
    }
    for k in st_n { a_patch(st_at[k], at[st_sx[k]]); }
    for ft: u8 in 1..10 {
        var used = false;
        for k in sx_n { if sx_jf[k] == ft { used = true; } }
        if used {
            let here = jc.len;
            jit_flags(ft);
            e(0x2A0703F0);                   // mov w16, w7
            e(0xD2800011);                   // mov x17, #0
            a_out();
            for k in sx_n { if sx_jf[k] == ft { a_patch(tail_from[k], here); } }
        }
    }
    // No time for the block: its length back on the time, and out, at its own address.
    a_patch(short_at, jc.len);
    e(0x91000000 | n << 10 | 23 << 5 | 23);
    a_next(T1, p0);
    e(0xD2800011);
    a_out();
}

// The offset of a memory operand into w16, as ea_short works it out.
fn j_ea(mm: u32, disp: u32) {
    let base = mm >> 14 & 15;
    let index = mm >> 18 & 15;
    let scale = mm >> 22 & 3;
    if base != 0 && index != 0 { a_op(0, T1, g(base - 1), g(index - 1), scale); }
    else if base != 0 { a_mov(T1, g(base - 1)); }
    else if index != 0 { a_lsl(T1, g(index - 1), scale); }
    else { a_movi(T1, disp); }
    if disp != 0 && (base != 0 || index != 0) { a_movi(T2, disp); a_op(0, T1, T1, T2, 0); }
}

// The short path of seg_read and seg_write (state.goose), for n bytes at the offset in w16 in
// segment sg: the offset below seg_top, the access inside one page, the TLB's tag for a read
// or for a write at this privilege level. Leaves in x6 where the bytes are in RAM; anything
// else goes to the way out made last. An entry in the TLB says the page is in RAM.
fn j_mem(sg: u32, n: u32, write: bool) {
    a_ldrn(T2, 21, sg * 4);                              // seg_top[sg]
    a_op(3, 31, T1, T2, 0);
    j_out(C_HS);
    a_ldr(T2, BASE_AT + sg * 4);                         // the linear address
    a_op(0, T1, T1, T2, 0);
    if n > 1 {
        e(0x12002C00 | T1 << 5 | T2);                    // and w17, w16, #0xFFF
        a_subsi(31, T2, 0x1000 - n);
        j_out(C_HI);
    }
    e(0x53000000 | 12 << 16 | 19 << 10 | T1 << 5 | T2);  // ubfx w17, w16, #12, #8
    a_op(5, T2, T2, R_MODE, 0);
    e(0x8B000000 | T2 << 16 | 2 << 10 | 20 << 5 | T2);   // add x17, x20, x17, lsl #2
    a_ldrn(T3, T2, if write { 4096 } else { 0 });        // the tag
    e(0x6B400000 | T1 << 16 | 12 << 10 | T3 << 5 | 31);  // cmp w6, w16, lsr #12
    j_out(C_NE);
    a_ldrn(T3, T2, if write { 6144 } else { 2048 });     // the page in RAM
    e(0x12002C00 | T1 << 5 | T2);                        // and w17, w16, #0xFFF
    a_op(5, T3, T3, T2, 0);
}

// A conditional jump's condition code, from what its entry keeps (see jcc_data and fuse_data).
fn jit_cc(kind: u8, d: u32) -> u8 {
    if kind == K_JCC { return d as! u8; }
    let neg: u8 = (d >> 31) as! u8;
    if kind == K_JCC_L { return 12 | ((d & 1) as! u8); }
    if kind == K_JCC_LE { return 14 | ((d & 1) as! u8); }
    let m = d & 0xFFF;
    if m == OF { return neg; }
    if m == CF { return 2 | neg; }
    if m == ZF { return 4 | neg; }
    if m == CF | ZF { return 6 | neg; }
    if m == SF { return 8 | neg; }
    if m == PF { return 10 | neg; }
    if m == 2 { return 12 | neg; }
    return 14 | neg;
}

// Puts 1 or 0 in w5 as x86 condition cc holds or not, from EFLAGS in memory: the record has
// to have been written out.
fn j_cond_mem(cc: u8) {
    a_ldr(T1, FLAGS_AT);
    match cc >> 1 {
        0 => { a_lsr(T4, T1, 11); },
        1 => { a_mov(T4, T1); },
        2 => { a_lsr(T4, T1, 6); },
        3 => { a_op_lsr(5, T4, T1, T1, 6); },
        4 => { a_lsr(T4, T1, 7); },
        5 => { a_lsr(T4, T1, 2); },
        6 => { a_lsr(T4, T1, 7); a_op_lsr(6, T4, T4, T1, 11); },
        _ => { a_lsr(T4, T1, 7); a_op_lsr(6, T4, T4, T1, 11); a_op_lsr(5, T4, T4, T1, 6); },
    }
    e(0x12000000 | T4 << 5 | T4);            // and w5, w5, #1
    if cc & 1 != 0 { e(0x52000000 | T4 << 5 | T4); }
}

// Writes the record out, after which EFLAGS in memory is right and there is no record.
fn j_settle() {
    if jf != F_MEM { jit_flags(jf); jf = F_MEM; }
}

// Puts 1 or 0 in w5 as x86 condition cc holds or not: from the record with the host's flags
// where that can be had, else from EFLAGS.
fn j_cond(cc: u8) {
    let c: u32 = jit_cond(jf, cc);
    if c == C_NONE { j_settle(); j_cond_mem(cc); }
    else if c == C_ALWAYS { a_movi(T4, 1); }
    else if c == C_NEVER { a_movi(T4, 0); }
    else { jit_compare(jf); a_cset(T4, c); }
}

// Ends the block with a conditional jump: to `to` if cc holds, else to `fall`.
fn jit_jcc(cc: u8, fall: u32, to: u32) {
    let c: u32 = jit_cond(jf, cc);
    if c == C_ALWAYS { jit_leave(to); return; }
    if c == C_NEVER { jit_leave(fall); return; }
    var at = 0;
    if c == C_NONE {
        j_settle();
        j_cond_mem(cc);
        at = jc.len;
        e(0x35000000 | T4);                  // cbnz w5
    } else {
        jit_compare(jf);
        at = jc.len;
        e(0x54000000 | c);
    }
    // Both ways write the same record out: jf is as it was for the second.
    let f = jf;
    jit_leave(fall);
    jf = f;
    a_patch(at, jc.len);
    jit_leave(to);
}

// An 8-bit register (AL CL DL BL AH CH DH BH) into host register rd, and from host register rs.
fn j_get8(rd: u32, i: u32) {
    if i < 4 { e(0x12001C00 | g(i) << 5 | rd); } else { e(0x53000000 | 8 << 16 | 15 << 10 | g(i - 4) << 5 | rd); }
}
fn j_set8(i: u32, rs: u32) {
    if i < 4 { e(0x33001C00 | rs << 5 | g(i)); jd |= 1 << i; }
    else { e(0x33181C00 | rs << 5 | g(i - 4)); jd |= 1 << (i - 4); }
}

// Can this entry's instruction go into a block, as anything but its last?
fn jit_plain(kind: u8, mm: u32, op: u8) -> bool {
    let regs = mm & 0x0C == 0x0C;
    let which = (mm >> 4 & 7) as! u8;
    if kind == K_MOV_R_R || kind == K_MOV_R_R_89 || kind == K_MOV_R_I || kind == K_NOP || kind == K_LEA { return true; }
    if kind == K_INC || kind == K_DEC { return true; }
    if kind == K_MOV_R_RM || kind == K_MOV_RM_R || kind == K_MOV_RM_I { return true; }
    if kind == K_MOVZX8 || kind == K_MOVZX16 || kind == K_PUSH || kind == K_POP { return true; }
    if kind == K_TEST || kind == K_TEST_I || kind == K_TEST_A_I { return true; }
    if kind == K_ALU_A_I { return !carries(op >> 3); }
    if kind >= K_ALU_R_RM_OP && kind < K_ALU_R_RM_OP + 8 { return true; }
    if kind >= K_ALU_RM_R_OP && kind < K_ALU_RM_I_OP + 8 {
        // To memory, CMP stores nothing; the others are group 1.
        return regs || kind == K_ALU_RM_R_OP + 7 || kind == K_ALU_RM_I_OP + 7 || jit_off & 1 == 0;
    }
    if kind == K_INC_RM || kind == K_DEC_RM || kind == K_NOT || kind == K_NEG { return jit_off & 2 == 0; }
    if kind == K_ALU_RM_R || kind == K_ALU_R_RM || kind == K_ALU_RM_I { return jit_off & 4 == 0; }      // ADC and SBB
    if kind == K_MOV8_R_RM || kind == K_MOV8_RM_R || kind == K_MOV8_RM_I { return jit_off & 8 == 0; }
    if kind == K_TEST8 || kind == K_TEST8_I || kind == K_TEST8_A_I { return jit_off & 16 == 0; }
    if kind == K_ALU8_RM_R || kind == K_ALU8_R_RM || kind == K_ALU8_A_I { return !carries(op >> 3) && jit_off & 32 == 0; }
    if kind == K_ALU8_RM_I { return !carries(which) && jit_off & 32 == 0; }
    if kind == K_SHL_I || kind == K_SHR_I || kind == K_SAR_I { return jit_off & 64 == 0; }
    if kind == K_SHIFT_CL { return regs && which >= 4 && jit_off & 128 == 0; }      // SHL SHR SAL SAR of a register
    if kind == K_SHIFT_I { return regs && which < 2 && jit_off & 256 == 0; }        // ROL and ROR of a register
    if kind == K_SETCC { return jit_off & 512 == 0; }
    return false;
}

// The memory operand of the instruction at p, for n bytes: a way out before the instruction,
// the offset, the short path. Leaves the place in x6.
fn j_operand(mm: u32, disp: u32, p: u32, cnt: u32, n: u32, write: bool) {
    jit_exit_here(p, cnt);
    j_ea(mm, disp);
    j_mem(mm >> 29, n, write);
}

// The 32-bit arithmetic, CMP and TEST: aop with first operand rm (a register, or memory when
// !regs) or guest register a_reg when a_first, and second operand the other, or imm when
// b_imm. The result goes where the first operand was, unless aop is CMP or test is set.
fn j_alu32(aop: u8, test: bool, mm: u32, disp: u32, p: u32, cnt: u32, reg: u32, to_rm: bool, b_imm: bool, imm: u32) {
    let regs = mm & 0x0C == 0x0C;
    let rm = mm >> 7 & 7;
    let keeps = aop != 7 && !test;
    let store = keeps && to_rm && !regs;     // the result goes to memory
    if !regs {
        j_operand(mm, disp, p, cnt, 4, store);
        a_load(4, T4);
    }
    // The operands into the record. (The value from memory is in w5; nothing below can leave
    // the block any more.)
    if to_rm {
        if regs { a_mov(R_A, g(rm)); } else { a_mov(R_A, T4); }
        if b_imm { a_movi(R_B, imm); } else { a_mov(R_B, g(reg)); }
    } else {
        a_mov(R_A, g(reg));
        if regs { a_mov(R_B, g(rm)); } else { a_mov(R_B, T4); }
    }
    let op: u32 = match aop { 0 => 0, 1 => 5, 4 => 4, 6 => 6, _ => 2 };
    a_op(op, R_R, R_A, R_B, 0);
    jf = match aop { 0 => F_ADD, 5, 7 => F_SUB, _ => F_LOGIC };
    if !keeps { return; }
    if store { a_store(4, R_R); }
    else if to_rm { a_mov(g(rm), R_R); jd |= 1 << rm; }
    else { a_mov(g(reg), R_R); jd |= 1 << reg; }
}

// The 8-bit arithmetic, CMP and TEST, the same way; a_al is for the forms on AL. For ADD,
// SUB and CMP the record holds the operands shifted to the top byte, so that the 32-bit
// rules give the 8-bit flags; for the others, the result sign-extended.
fn j_alu8(aop: u8, test: bool, mm: u32, disp: u32, p: u32, cnt: u32, reg: u32, to_rm: bool, b_imm: bool, imm: u32, a_al: bool) {
    let regs = mm & 0x0C == 0x0C || a_al;
    let rm = if a_al { 0 } else { mm >> 7 & 7 };
    let keeps = aop != 7 && !test;
    let store = keeps && to_rm && !regs;
    if !regs {
        j_operand(mm, disp, p, cnt, 1, store);
        a_load(1, T4);
    }
    if to_rm {
        if regs { j_get8(R_A, rm); } else { a_mov(R_A, T4); }
        if b_imm { a_movi(R_B, imm & 0xFF); } else { j_get8(R_B, reg); }
    } else {
        j_get8(R_A, reg);
        if regs { j_get8(R_B, rm); } else { a_mov(R_B, T4); }
    }
    if aop == 0 || aop == 5 || aop == 7 {
        a_lsl(R_A, R_A, 24);
        a_lsl(R_B, R_B, 24);
        a_op(if aop == 0 { 0 } else { 2 }, R_R, R_A, R_B, 0);
        jf = if aop == 0 { F_ADD8 } else { F_SUB8 };
        if keeps { a_lsr(T4, R_R, 24); }
    } else {
        a_op(if aop == 1 { 5 } else if aop == 4 { 4 } else { 6 }, T4, R_A, R_B, 0);
        e(0x13001C00 | T4 << 5 | R_R);       // sxtb w3, w5
        jf = F_LOGIC;
    }
    if !keeps { return; }
    if store { a_store(1, T4); }
    else if to_rm { j_set8(rm, T4); }
    else { j_set8(reg, T4); }
}

// ADC and SBB, 32-bit. The carry comes from EFLAGS and the flags go straight back to it.
fn j_adc(sbb: bool, mm: u32, disp: u32, p: u32, cnt: u32, reg: u32, to_rm: bool, b_imm: bool, imm: u32) {
    let regs = mm & 0x0C == 0x0C;
    let rm = mm >> 7 & 7;
    let store = to_rm && !regs;
    j_settle();
    if !regs {
        j_operand(mm, disp, p, cnt, 4, store);
        a_load(4, T4);
    }
    if to_rm {
        if regs { a_mov(R_A, g(rm)); } else { a_mov(R_A, T4); }
        if b_imm { a_movi(R_B, imm); } else { a_mov(R_B, g(reg)); }
    } else {
        a_mov(R_A, g(reg));
        if regs { a_mov(R_B, g(rm)); } else { a_mov(R_B, T4); }
    }
    a_ldr(T1, FLAGS_AT);
    e(0x12000000 | T1 << 5 | T2);            // and w17, w16, #1: CF
    if sbb {
        a_op(3, 31, 31, T2, 0);              // the host's carry is the opposite of a borrow
        e(0x7A000000 | R_B << 16 | R_A << 5 | R_R);      // sbcs
    } else {
        a_subsi(31, T2, 1);                  // the host's carry is CF
        e(0x3A000000 | R_B << 16 | R_A << 5 | R_R);      // adcs
    }
    // The result to memory now: its place is in x6, which the flags below use as scratch.
    // (A store leaves the host's flags alone.)
    if store { a_store(4, R_R); }
    a_cset(T2, if sbb { C_LO } else { C_HS });
    a_cset(T3, C_VS);
    a_movi(T4, 0xFFFFF72A);
    a_op(4, T1, T1, T4, 0);
    a_op(5, T1, T1, T2, 0);                  // CF
    a_op(5, T1, T1, T3, 11);                 // OF
    a_op(6, T2, R_A, R_B, 0);                // AF
    a_op(6, T2, T2, R_R, 0);
    e(0x121C0000 | T2 << 5 | T2);
    a_op(5, T1, T1, T2, 0);
    j_szp(T1, R_R, T2, false);
    a_str(T1, FLAGS_AT);
    if store { return; }
    if to_rm { a_mov(g(rm), R_R); jd |= 1 << rm; }
    else { a_mov(g(reg), R_R); jd |= 1 << reg; }
}

// A shift of a 32-bit operand by a constant from 1 to 31: which is 4 or 6 SHL, 5 SHR, 7 SAR.
// AF, and OF unless the count is one, stay as they were, so what was in the record is
// written out first.
fn j_shift(which: u32, n: u32, mm: u32, disp: u32, p: u32, cnt: u32) {
    let regs = mm & 0x0C == 0x0C;
    let rm = mm >> 7 & 7;
    j_settle();
    var v = g(rm);
    if !regs {
        j_operand(mm, disp, p, cnt, 4, true);
        a_load(4, T4);
        v = T4;
    }
    if which == 5 { a_lsr(R_R, v, n); }
    else if which == 7 { e(0x13007C00 | n << 16 | v << 5 | R_R); }      // asr
    else { a_lsl(R_R, v, n); }
    // CF: the last bit shifted out.
    a_lsr(R_A, v, if which == 5 || which == 7 { n - 1 } else { 32 - n });
    e(0x12000000 | R_A << 5 | R_A);
    jf = F_SH;
    if n == 1 {
        if which == 5 { a_lsr(R_B, v, 31); }
        else if which == 7 { a_movi(R_B, 0); }
        else { a_lsr(R_B, R_R, 31); a_op(6, R_B, R_B, R_A, 0); }
        jf = F_SH1;
    }
    if regs { a_mov(g(rm), R_R); jd |= 1 << rm; } else { a_store(4, R_R); }
}

// A shift of a register by CL. The count is known only when it runs: nothing changes for a
// count of zero, and OF only for a count of one. So the flags go straight to EFLAGS.
fn j_shift_cl(which: u32, rm: u32) {
    j_settle();
    e(0x12001000 | g(1) << 5 | T1);          // and w16, w9, #31: the count
    let skip = jc.len;
    e(0x34000000 | T1);                      // cbz w16
    a_mov(7, g(rm));
    let shv: u32 = if which == 5 { 0x1AC02400 } else if which == 7 { 0x1AC02800 } else { 0x1AC02000 };
    e(shv | T1 << 16 | 7 << 5 | R_R);
    // CF: the last bit shifted out. (A shift by a register takes its count modulo 32.)
    if which == 5 || which == 7 { a_subi(T2, T1, 1); } else { e(0x4B0003E0 | T1 << 16 | T2); }
    e(0x1AC02400 | T2 << 16 | 7 << 5 | T2);
    e(0x12000000 | T2 << 5 | T2);
    a_mov(g(rm), R_R);
    jd |= 1 << rm;
    a_ldr(T3, FLAGS_AT);
    a_movi(T4, 0xFFFFFF3A);
    a_op(4, T3, T3, T4, 0);
    a_op(5, T3, T3, T2, 0);
    j_szp(T3, R_R, T4, false);
    a_subsi(31, T1, 1);                      // OF, for a count of one
    let not_one = jc.len;
    e(0x54000000 | C_NE);
    a_movi(T4, 0xFFFFF7FF);
    a_op(4, T3, T3, T4, 0);
    if which == 5 { a_lsr(T4, 7, 31); a_op(5, T3, T3, T4, 11); }
    else if which != 7 { a_lsr(T4, R_R, 31); a_op(6, T4, T4, T2, 0); a_op(5, T3, T3, T4, 11); }
    a_patch(not_one, jc.len);
    a_str(T3, FLAGS_AT);
    a_patch(skip, jc.len);
}

// ROL (left) or ROR of a register by a constant from 1 to 31. CF, and OF for ROL at every
// count and for ROR at a count of one; the rest of EFLAGS stays.
fn j_rotate(left: bool, n: u32, rm: u32) {
    j_settle();
    let by = if left { 32 - n } else { n };
    e(0x13800000 | g(rm) << 16 | by << 10 | g(rm) << 5 | R_R);          // ror
    a_mov(g(rm), R_R);
    jd |= 1 << rm;
    a_ldr(T3, FLAGS_AT);
    let both = left || n == 1;
    a_movi(T4, if both { 0xFFFFF7FE } else { 0xFFFFFFFE });
    a_op(4, T3, T3, T4, 0);
    if left {
        e(0x12000000 | R_R << 5 | T2);       // CF: the bit that came round to the bottom
        a_op(5, T3, T3, T2, 0);
        a_lsr(T4, R_R, 31);
        a_op(6, T4, T4, T2, 0);
        a_op(5, T3, T3, T4, 11);
    } else {
        a_lsr(T2, R_R, 31);                  // CF: the bit that came round to the top
        a_op(5, T3, T3, T2, 0);
        if n == 1 {
            a_op(6, T4, R_R, R_R, 1);        // OF: the top two bits differ
            a_lsr(T4, T4, 31);
            a_op(5, T3, T3, T4, 11);
        }
    }
    a_str(T3, FLAGS_AT);
}

// Generates one such instruction, which is at address p and the block's cnt-th (from 0).
fn jit_one(kind: u8, slot: i64, p: u32, cnt: u32) {
    let mm = dc[slot].m;
    let imm = dc[slot].imm;
    let disp = dc[slot].disp;
    let op = dc[slot].pre.op;
    let reg = mm >> 4 & 7;
    let rm = mm >> 7 & 7;
    let regs = mm & 0x0C == 0x0C;
    if kind == K_MOV_R_R { a_mov(g(reg), g(rm)); jd |= 1 << reg; }
    else if kind == K_MOV_R_R_89 { a_mov(g(rm), g(reg)); jd |= 1 << rm; }
    else if kind == K_MOV_R_I { a_movi(g(op & 7), imm); jd |= 1 << (op & 7); }
    else if kind == K_NOP { }
    else if kind == K_LEA { j_ea(mm, disp); a_mov(g(reg), T1); jd |= 1 << reg; }
    else if kind == K_MOV_R_RM { j_operand(mm, disp, p, cnt, 4, false); a_load(4, g(reg)); jd |= 1 << reg; }
    else if kind == K_MOV_RM_R { j_operand(mm, disp, p, cnt, 4, true); a_store(4, g(reg)); }
    else if kind == K_MOV_RM_I {
        if regs { a_movi(g(rm), imm); jd |= 1 << rm; }
        else { j_operand(mm, disp, p, cnt, 4, true); a_movi(T4, imm); a_store(4, T4); }
    }
    else if kind == K_MOVZX8 || kind == K_MOVZX16 {
        if !regs {
            let n: u32 = if kind == K_MOVZX8 { 1 } else { 2 };
            j_operand(mm, disp, p, cnt, n, false);
            a_load(n, g(reg));
        }
        else if kind == K_MOVZX16 { e(0x12003C00 | g(rm) << 5 | g(reg)); }                  // and wd, wn, #0xFFFF
        else { j_get8(g(reg), rm); }
        jd |= 1 << reg;
    }
    else if kind == K_MOV8_R_RM {
        if regs { j_get8(T4, rm); } else { j_operand(mm, disp, p, cnt, 1, false); a_load(1, T4); }
        j_set8(reg, T4);
    }
    else if kind == K_MOV8_RM_R {
        if regs { j_get8(T4, reg); j_set8(rm, T4); }
        else { j_operand(mm, disp, p, cnt, 1, true); j_get8(T4, reg); a_store(1, T4); }
    }
    else if kind == K_MOV8_RM_I {
        if regs { a_movi(T4, imm & 0xFF); j_set8(rm, T4); }
        else { j_operand(mm, disp, p, cnt, 1, true); a_movi(T4, imm & 0xFF); a_store(1, T4); }
    }
    else if kind == K_PUSH {
        jit_exit_here(p, cnt);
        a_subi(T1, g(SP), 4);
        j_mem(SS, 4, true);
        a_store(4, g(op & 7));
        a_subi(g(SP), g(SP), 4);
        jd |= 1 << SP;
    }
    else if kind == K_POP {
        jit_exit_here(p, cnt);
        a_mov(T1, g(SP));
        j_mem(SS, 4, false);
        a_load(4, T4);
        a_addi(g(SP), g(SP), 4);
        a_mov(g(op & 7), T4);
        jd |= 1 << SP | 1 << (op & 7);
    }
    else if kind == K_INC || kind == K_DEC || kind == K_INC_RM || kind == K_DEC_RM {
        // CF is the one before: what is in the record is written out first.
        j_settle();
        let up = kind == K_INC || kind == K_INC_RM;
        let in_mem = (kind == K_INC_RM || kind == K_DEC_RM) && !regs;
        let r = if kind == K_INC || kind == K_DEC { (op & 7) as! u32 } else { rm };
        if in_mem { j_operand(mm, disp, p, cnt, 4, true); a_load(4, R_A); } else { a_mov(R_A, g(r)); }
        a_movi(R_B, 1);
        if up { a_addi(R_R, R_A, 1); jf = F_INC; } else { a_subi(R_R, R_A, 1); jf = F_DEC; }
        if in_mem { a_store(4, R_R); } else { a_mov(g(r), R_R); jd |= 1 << r; }
    }
    else if kind == K_NOT {
        if regs { e(0x2A2003E0 | g(rm) << 16 | g(rm)); jd |= 1 << rm; }                     // mvn
        else { j_operand(mm, disp, p, cnt, 4, true); a_load(4, T4); e(0x2A2003E0 | T4 << 16 | T4); a_store(4, T4); }
    }
    else if kind == K_NEG {
        // 0 - operand, with a SUB's flags.
        if !regs { j_operand(mm, disp, p, cnt, 4, true); a_load(4, R_B); } else { a_mov(R_B, g(rm)); }
        a_movi(R_A, 0);
        a_op(2, R_R, R_A, R_B, 0);
        jf = F_SUB;
        if regs { a_mov(g(rm), R_R); jd |= 1 << rm; } else { a_store(4, R_R); }
    }
    else if kind >= K_ALU_RM_R_OP && kind < K_ALU_RM_R_OP + 8 { j_alu32(kind - K_ALU_RM_R_OP, false, mm, disp, p, cnt, reg, true, false, 0); }
    else if kind >= K_ALU_R_RM_OP && kind < K_ALU_R_RM_OP + 8 { j_alu32(kind - K_ALU_R_RM_OP, false, mm, disp, p, cnt, reg, false, false, 0); }
    else if kind >= K_ALU_RM_I_OP && kind < K_ALU_RM_I_OP + 8 { j_alu32(kind - K_ALU_RM_I_OP, false, mm, disp, p, cnt, reg, true, true, imm); }
    else if kind == K_TEST { j_alu32(4, true, mm, disp, p, cnt, reg, true, false, 0); }
    else if kind == K_TEST_I { j_alu32(4, true, mm, disp, p, cnt, reg, true, true, imm); }
    else if kind == K_ALU_A_I { j_alu32(op >> 3, false, 0x0C, 0, p, cnt, 0, true, true, imm); }
    else if kind == K_TEST_A_I { j_alu32(4, true, 0x0C, 0, p, cnt, 0, true, true, imm); }
    else if kind == K_ALU_RM_R { j_adc(op >> 3 == 3, mm, disp, p, cnt, reg, true, false, 0); }
    else if kind == K_ALU_R_RM { j_adc(op >> 3 == 3, mm, disp, p, cnt, reg, false, false, 0); }
    else if kind == K_ALU_RM_I { j_adc(reg == 3, mm, disp, p, cnt, reg, true, true, imm); }
    else if kind == K_ALU8_RM_R { j_alu8(op >> 3, false, mm, disp, p, cnt, reg, true, false, 0, false); }
    else if kind == K_ALU8_R_RM { j_alu8(op >> 3, false, mm, disp, p, cnt, reg, false, false, 0, false); }
    else if kind == K_ALU8_RM_I { j_alu8(reg as! u8, false, mm, disp, p, cnt, reg, true, true, imm, false); }
    else if kind == K_ALU8_A_I { j_alu8(op >> 3, false, mm, disp, p, cnt, 0, true, true, imm, true); }
    else if kind == K_TEST8 { j_alu8(4, true, mm, disp, p, cnt, reg, true, false, 0, false); }
    else if kind == K_TEST8_I { j_alu8(4, true, mm, disp, p, cnt, reg, true, true, imm, false); }
    else if kind == K_TEST8_A_I { j_alu8(4, true, mm, disp, p, cnt, 0, true, true, imm, true); }
    else if kind == K_SHL_I { j_shift(4, imm, mm, disp, p, cnt); }
    else if kind == K_SHR_I { j_shift(5, imm, mm, disp, p, cnt); }
    else if kind == K_SAR_I { j_shift(7, imm, mm, disp, p, cnt); }
    else if kind == K_SHIFT_CL { j_shift_cl(reg, rm); }
    else if kind == K_SHIFT_I { if imm & 31 != 0 { j_rotate(reg == 0, imm & 31, rm); } }
    else if kind == K_SETCC {
        // The condition first: it may write the record out, which has to be before the way out.
        j_cond(imm as! u8);
        if regs { j_set8(rm, T4); }
        else { a_mov(7, T4); j_operand(mm, disp, p, cnt, 1, true); a_store(1, 7); }
    }
}

// The lone instruction a pair's kind begins with; K_NONE for a kind that is no pair.
fn jit_unpair(kind: u8) -> u8 {
    if kind == K_CMP_RM_R_J { return K_ALU_RM_R_OP + 7; }
    if kind == K_CMP_RM_I_J { return K_ALU_RM_I_OP + 7; }
    if kind == K_TEST_J { return K_TEST; }
    if kind == K_DEC_J { return K_DEC; }
    if kind == K_AND_RM_I_J { return K_ALU_RM_I_OP + 4; }
    if kind == K_SUB_RM_I_J { return K_ALU_RM_I_OP + 5; }
    if kind == K_TEST_I_J { return K_TEST_I; }
    if kind == K_TEST8_I_J { return K_TEST8_I; }
    if kind == K_TEST8_J { return K_TEST8; }
    if kind == K_ALU8_RM_I_J { return K_ALU8_RM_I; }
    if kind == K_ALU8_A_I_J { return K_ALU8_A_I; }
    if kind == K_DEC_RM_J { return K_DEC_RM; }
    return K_NONE;
}

// Translates the block that begins at physical address p, whose entry is at slot, if there is
// one worth having, and makes that entry a K_BLOCK.
fn jit_translate(p0: u32, slot0: i64) {
    let s0 = slot0 - DC_HALF;
    dc_hot[s0] = 255;                        // whatever comes of it, this is not tried again
    if jit_used + 65536 > jit_room { jit_flush(); }
    jc = [];
    jb = jit_used;
    jf = F_MEM;
    jd = 0;
    sx_n = 0;
    st_n = 0;
    lk_n = 0;
    // The block's length off the time left; if that is not enough, out. (The length is
    // filled in below.)
    e(0xF10002F7);                           // subs x23, x23, #n
    let short_at = jc.len;
    e(0x54000000 | C_LT);
    var p = p0;
    var n: u32 = 0;
    var last = p0;
    var done = false;
    // Whether what stopped the block may be otherwise later: an instruction not in the decode
    // cache, or in it and not yet classified.
    var again = false;
    while !done && n < JIT_MAX && sx_n < SX_MAX - 2 && st_n < ST_MAX - 8 {
        let slot: i64 = p & (DC_HALF - 1) | DC_HALF;
        if p >> 12 != p0 >> 12 { break; }
        if dc[slot].tag != p { again = true; break; }
        // An instruction that begins another block is taken by its own kind: blocks may
        // overlap.
        var kind = dc[slot].pre.kind;
        if kind == K_BLOCK { kind = jit_kind[slot - DC_HALF]; }
        let mm = dc[slot].m;
        let nx = dc_next[slot];
        if kind == K_JMP {
            jit_leave(nx + dc[slot].imm);
            last = p; n += 1; done = true;
        } else if kind == K_JCC || (kind >= K_JCC_MASK && kind <= K_JCC_LE) {
            jit_jcc(jit_cc(kind, dc[slot].disp), nx, nx + dc[slot].imm);
            last = p; n += 1; done = true;
        } else if kind == K_CALL {
            // The return address is pushed; that it is an instruction pointer, not an address
            // in RAM, is what w22 is for.
            jit_exit_here(p, n);
            a_subi(T1, g(SP), 4);
            j_mem(SS, 4, true);
            a_movi(T4, nx);
            a_op(2, T4, T4, 22, 0);
            a_store(4, T4);
            a_subi(g(SP), g(SP), 4);
            jit_leave(nx + dc[slot].imm);
            last = p; n += 1; done = true;
        } else if kind == K_RET {
            jit_exit_here(p, n);
            a_mov(T1, g(SP));
            j_mem(SS, 4, false);
            a_load(4, T4);
            a_addi(g(SP), g(SP), 4);
            jit_flags(jf);
            a_op(0, T1, T4, 22, 0);                      // where it returns to, as an address
            e(0xD2800011);                               // mov x17, #0: no link slot
            a_out();
            last = p; n += 1; done = true;
        } else if jit_unpair(kind) != K_NONE {
            let first = jit_unpair(kind);
            if !jit_plain(first, mm, dc[slot].pre.op) { break; }
            let b = dc[slot].bytes;
            jit_one(first, slot, p, n);
            jit_jcc(jit_cc(K_JCC_MASK, b as! u32), nx, nx + (b >> 32) as! u32);
            last = p; n += 2; done = true;
        } else if kind - 1 < K_LAST && jit_plain(kind, mm, dc[slot].pre.op) {
            jit_one(kind, slot, p, n);
            last = p; n += 1;
            p = nx;
        } else {
            if kind == 0 { again = true; }
            break;
        }
    }
    if n < 2 {
        // One instruction is not worth a block. If what follows it may be translated later,
        // this address is counted afresh and tried again.
        if again { dc_hot[s0] = 0; }
        return;
    }
    if !done { jit_leave(p); }
    jc[1] = jc[1] | ((n << 2) as! u8);       // the length into the first instruction
    jit_exits(n, p0, short_at);
    jit_write(jit_mem + jit_used, jc[..]);
    jit_code[s0] = jit_mem + jit_used;
    jit_used += jc.len;
    jit_kind[s0] = dc[slot0].pre.kind;
    jit_n[s0] = n as! u8;
    jit_last[s0] = last;
    jit_head[s0] = p0;
    jit_gen[s0] = code_gen[p0 >> 12];
    dc[slot0].pre.kind = K_BLOCK;
    jit_blocks_made += 1;
}

// The code is full: every block is dropped, and translation starts over from an empty map.
// Moving every page's generation on makes each block stale where it is next reached, and
// nothing of the generated code is running now (blocks are translated between runs of them).
fn jit_flush() {
    for i in RAM_SIZE >> 12 { code_gen[i] += 1; }
    jit_used = jit_keep;                     // the way in and out stay (jit_init)
    jit_flushes += 1;
}

// An entry of the decode cache has just been classified. If the slot's block is this very
// instruction's and its page has not been written since, the entry heads that block again:
// entries come and go (two addresses can want one slot), and a block is too dear to make
// twice.
fn jit_reclaim(slot: i64) {
    let s = slot - DC_HALF;
    let p = dc[slot].tag;
    if jit_head[s] != p || jit_gen[s] != code_gen[p >> 12] || dc[slot].pre.kind - 1 >= K_LAST { return; }
    jit_kind[s] = dc[slot].pre.kind;
    dc[slot].pre.kind = K_BLOCK;
    dc_hot[s] = 255;
}

// The run has come to physical address p at its start or from a block, which is where a block
// may begin: counted, and at the eighth time translated.
fn jit_arrive(p: u32) {
    let slot: i64 = p & (DC_HALF - 1) | DC_HALF;
    if dc[slot].tag != p { return; }
    let s = slot - DC_HALF;
    let h = dc_hot[s];
    if h >= JIT_HOT {
        if h != 255 && dc[slot].pre.kind - 1 < K_LAST { jit_translate(p, slot); }
        return;
    }
    dc_hot[s] = h + 1;
}

// Where a run of the interpreter came to a block: the entry's slot, or -1. Set by exec_short,
// taken by jit_blocks.
var jit_at: i64 = -1;

// Runs the block that the run came to and whatever it leads to, for as long as generated code
// can go on. True if anything was executed: the virtual time and the instruction pointer are
// then moved on, and the interpreter goes on from there. False if nothing was: the first
// instruction of the block is then the general path's, by its own kind.
//
// A block is in the page of code the run was on, and code_page, code_phys and run_pmax still
// describe that page and how far the run may go in it. Blocks push and pop with a 32-bit
// stack pointer, so none is run on a 16-bit stack.
//
// Generated code comes back with the address it left for and the link slot it left through,
// if it left through one. If that address begins a good block in this page, the slot is made
// a branch to it, so that the next time generated code goes straight on; and the block is run.
fn jit_blocks() -> bool {
    var slot = jit_at;
    jit_at = -1;
    if !stack32() { return false; }
    let pbase: i64 = cpu.base[CS] - (code_page << 12) + code_phys;
    // Where the code segment's limit cuts into this page, a chain could run past what the
    // run may execute: there, one block at a time, each checked here.
    let whole = run_pmax == code_phys + 0xFF0;
    var ran = false;
    var next: u32 = 0;
    loop {
        let s = slot - DC_HALF;
        let head = dc[slot].tag;
        if jit_gen[s] != code_gen[head >> 12] {
            // A store has been made into this page since: the block is dropped.
            dc[slot].pre.kind = jit_kind[s];
            dc_hot[s] = 0;
            break;
        }
        let n: i64 = jit_n[s];
        // One instruction of the time is left for the general path, as a run leaves it.
        var time = chain_until - vtime - 1;
        if time < n || jit_last[s] > run_pmax { break; }
        if !whole || jit_off & 1024 != 0 { time = n; }
        let r = jit_call(jit_mem, cpu.regs[..], jit_ram, jit_tlb, jit_seg, pbase, jit_code[s], time, vtime);
        let k = r >> 32;
        if k == 0 { break; }                 // nothing was executed
        next = r as! u32;
        vtime += k;
        jit_ran += k;
        jit_calls += 1;
        ran = true;
        // On to the next block, if that is what is there.
        if next < code_phys || next > run_pmax { break; }
        slot = next & (DC_HALF - 1) | DC_HALF;
        if dc[slot].tag != next || dc[slot].pre.kind != K_BLOCK { jit_arrive(next); break; }
        let s2 = slot - DC_HALF;
        let from = jit_slot();
        if from != 0 && whole && jit_off & 1024 == 0 && jit_gen[s2] == code_gen[next >> 12] {
            // The slot it left through becomes a branch to that block.
            let d: u32 = ((jit_code[s2] - from) >> 2) as! u32;
            let w: u32 = 0x14000000 | d & 0x3FFFFFF;
            let b: u8[4] = [w as! u8, (w >> 8) as! u8, (w >> 16) as! u8, (w >> 24) as! u8];
            jit_write(from, b[..]);
            jit_links += 1;
        }
    }
    if ran {
        cpu.ip = next + (code_page << 12) - code_phys - cpu.base[CS];
        saved = cpu;
    }
    return ran;
}
