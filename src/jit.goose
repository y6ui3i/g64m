// A JIT for arm64 (E059). With --jit, runs of 32-bit instructions that touch no memory are
// translated into host code and run as one executor, K_BLOCK. See docs/experiments.md, E059,
// for the design; this file is the translator, and jit.c the forty lines of C it needs.
//
// Host registers in generated code, all of them ones a C function may overwrite, so a block
// saves and restores nothing:
//   x0        the address of cpu.regs (the flags are at FLAGS_AT from it)
//   w8..w15   EAX ECX EDX EBX ESP EBP ESI EDI, loaded on entry, stored back where changed
//   w3 w4 w5  the operands and the result of the last instruction that set the flags
//   w16 w17 w6  scratch
// A block returns the physical address of the next instruction in w0.

import state;

extern fn jit_alloc(size: i64) -> i64;
extern fn jit_write(at: i64, code: const u8[:]);
extern fn jit_call(f: i64, regs: u32[:]) -> i64;

var jit_on = false;
var jit_mem = 0;             // where the code is mapped
var jit_used = 0;            // how much of it holds code
var jit_blocks = 0;          // blocks translated
var jit_ran = 0;             // guest instructions executed in blocks
var run_pmax: u32 = 0;       // the highest address the current run may execute at (exec_short)
let JIT_SIZE = 33554432;     // 32 MB
let JIT_HOT = 8;             // arrivals at a jump's target before it is translated
let JIT_MAX = 60;            // instructions in a block at most
let FLAGS_AT = 0x78;         // cpu.flags from cpu.regs

fn jit_init() {
    jit_mem = jit_alloc(JIT_SIZE);
    jit_on = jit_mem != 0;
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
let F_DEC = 5;       // w5 = w3 - 1, w4 = 1

// Writes EFLAGS out from the record. What alu(), inc() and dec() leave, bit for bit.
fn jit_flags(ft: u8) {
    if ft == F_MEM { return; }
    a_ldr(16, FLAGS_AT);
    a_movi(17, if ft >= F_INC { 0xFFFFF72B } else { 0xFFFFF72A });
    a_op(4, 16, 16, 17, 0);
    a_subsi(31, 5, 0);                       // ZF
    a_cset(17, C_EQ);
    a_op(5, 16, 16, 17, 6);
    a_lsr(17, 5, 31);                        // SF
    a_op(5, 16, 16, 17, 7);
    a_op_lsr(6, 17, 5, 5, 4);                // PF: the low byte's bits folded into bit 0
    a_op_lsr(6, 17, 17, 17, 2);
    a_op_lsr(6, 17, 17, 17, 1);
    e(0x12000000 | 17 << 5 | 17);            // and w17, w17, #1
    e(0x52000000 | 17 << 5 | 17);            // eor w17, w17, #1
    a_op(5, 16, 16, 17, 2);
    if ft != F_LOGIC {
        if ft == F_ADD {                     // CF: the sum is below an operand
            a_op(3, 31, 5, 3, 0);
            a_cset(17, C_LO);
            a_op(5, 16, 16, 17, 0);
        } else if ft == F_SUB {              // CF: a borrow
            a_op(3, 31, 3, 4, 0);
            a_cset(17, C_LO);
            a_op(5, 16, 16, 17, 0);
        }
        if ft == F_ADD || ft == F_INC {      // OF: both operands differ in sign from the sum
            a_op(6, 17, 3, 5, 0);
            a_op(6, 6, 4, 5, 0);
        } else {                             // OF: the operands differ, and the first from the difference
            a_op(6, 17, 3, 4, 0);
            a_op(6, 6, 3, 5, 0);
        }
        a_op(4, 17, 17, 6, 0);
        a_lsr(17, 17, 31);
        a_op(5, 16, 16, 17, 11);
        a_op(6, 17, 3, 4, 0);                // AF
        a_op(6, 17, 17, 5, 0);
        e(0x121C0000 | 17 << 5 | 17);        // and w17, w17, #0x10
        a_op(5, 16, 16, 17, 0);
    }
    a_str(16, FLAGS_AT);
}

// The host condition for x86 condition cc after an instruction of kind ft, once jit_compare
// has set the host's flags; C_NONE where there is none.
fn jit_cond(ft: u8, cc: u8) -> u8 {
    if ft == F_MEM || cc == 10 || cc == 11 { return C_NONE; }
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
    let carry = ft == F_ADD || ft == F_SUB;
    match cc {
        0 => { return C_VS; },
        1 => { return C_VC; },
        2 => { if !carry { return C_NONE; } return if ft == F_SUB { C_LO } else { C_HS }; },
        3 => { if !carry { return C_NONE; } return if ft == F_SUB { C_HS } else { C_LO }; },
        4 => { return C_EQ; },
        5 => { return C_NE; },
        6 => { return if ft == F_SUB { C_LS } else { C_NONE }; },
        7 => { return if ft == F_SUB { C_HI } else { C_NONE }; },
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
    if ft == F_LOGIC { a_subsi(31, 5, 0); }
    else if ft == F_ADD { a_op(1, 31, 3, 4, 0); }
    else if ft == F_SUB { a_op(3, 31, 3, 4, 0); }
    else if ft == F_INC { a_addsi(31, 3, 1); }
    else { a_subsi(31, 3, 1); }
}

// ---- a block ----

var jf: u8 = 0;              // which instruction set the flags last, so far in the block
var jd: u32 = 0;             // which guest registers the block has written, one bit each

// Leaves the block: the changed registers and the flags written back, the next address returned.
fn jit_leave(next: u32) {
    for k: u32 in 0..4 {
        if jd >> (k * 2) & 3 != 0 { a_stp(8 + k * 2, 9 + k * 2, k * 8); }
    }
    jit_flags(jf);
    a_movi(0, next);
    a_ret();
}

// res = a op b for one of the eight arithmetic operations that reads no carry, the record kept;
// the result goes to guest register dst unless dst is 8.
fn jit_alu(aop: u8, dst: u32) {
    let op: u32 = match aop { 0 => 0, 1 => 5, 4 => 4, 6 => 6, _ => 2 };
    a_op(op, 5, 3, 4, 0);
    jf = match aop { 0 => F_ADD, 5, 7 => F_SUB, _ => F_LOGIC };
    if dst < 8 { a_mov(g(dst), 5); jd |= 1 << dst; }
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

// Ends the block with a conditional jump: to `to` if cc holds, else to `fall`. False, and
// nothing generated, if the condition cannot be had from the record.
fn jit_jcc(cc: u8, fall: u32, to: u32) -> bool {
    let c = jit_cond(jf, cc);
    if c == C_NONE { return false; }
    if c == C_ALWAYS { jit_leave(to); return true; }
    if c == C_NEVER { jit_leave(fall); return true; }
    jit_compare(jf);
    let at = jc.len;
    e(0);                                    // b.cond over the first way out, filled in below
    jit_leave(fall);
    let over: u32 = ((jc.len - at) >> 2) as! u32;
    let w: u32 = 0x54000000 | over << 5 | c;
    jc[at] = w as! u8;
    jc[at + 1] = (w >> 8) as! u8;
    jc[at + 2] = (w >> 16) as! u8;
    jc[at + 3] = (w >> 24) as! u8;
    jit_leave(to);
    return true;
}

// Can this entry's instruction go into a block, as anything but its last? Register forms only.
fn jit_plain(kind: u8, mm: u32, op: u8) -> bool {
    let regs = mm & 0x0C == 0x0C;
    if kind == K_MOV_R_R || kind == K_MOV_R_R_89 || kind == K_MOV_R_I || kind == K_NOP || kind == K_LEA { return true; }
    if kind == K_INC || kind == K_DEC { return true; }
    if kind >= K_ALU_RM_R_OP && kind < K_ALU_RM_I_OP + 8 { return regs; }
    if kind == K_TEST || kind == K_TEST_I { return regs; }
    if kind == K_ALU_A_I { return !carries(op >> 3); }
    if kind == K_TEST_A_I { return true; }
    return false;
}

// Generates one such instruction.
fn jit_one(kind: u8, slot: i64) {
    let mm = dc[slot].m;
    let imm = dc[slot].imm;
    let op = dc[slot].pre.op;
    let reg = mm >> 4 & 7;
    let rm = mm >> 7 & 7;
    if kind == K_MOV_R_R { a_mov(g(reg), g(rm)); jd |= 1 << reg; }
    else if kind == K_MOV_R_R_89 { a_mov(g(rm), g(reg)); jd |= 1 << rm; }
    else if kind == K_MOV_R_I { a_movi(g(op & 7), imm); jd |= 1 << (op & 7); }
    else if kind == K_NOP { }
    else if kind == K_LEA {
        let base = mm >> 14 & 15;
        let index = mm >> 18 & 15;
        let scale = mm >> 22 & 3;
        let disp = dc[slot].disp;
        if base != 0 && index != 0 { a_op(0, 16, g(base - 1), g(index - 1), scale); }
        else if base != 0 { a_mov(16, g(base - 1)); }
        else if index != 0 { a_lsl(16, g(index - 1), scale); }
        else { a_movi(16, disp); }
        if disp != 0 && (base != 0 || index != 0) { a_movi(17, disp); a_op(0, 16, 16, 17, 0); }
        a_mov(g(reg), 16);
        jd |= 1 << reg;
    }
    else if kind == K_INC || kind == K_DEC {
        // CF is the one before: if that is in the record, it is written out first.
        if jf != F_MEM { jit_flags(jf); }
        let r = op & 7;
        a_mov(3, g(r));
        a_movi(4, 1);
        if kind == K_INC { a_addi(5, 3, 1); jf = F_INC; } else { a_subi(5, 3, 1); jf = F_DEC; }
        a_mov(g(r), 5);
        jd |= 1 << r;
    }
    else if kind >= K_ALU_RM_R_OP && kind < K_ALU_RM_R_OP + 8 {
        a_mov(3, g(rm)); a_mov(4, g(reg));
        jit_alu(kind - K_ALU_RM_R_OP, if kind == K_ALU_RM_R_OP + 7 { 8 } else { rm });
    }
    else if kind >= K_ALU_R_RM_OP && kind < K_ALU_R_RM_OP + 8 {
        a_mov(3, g(reg)); a_mov(4, g(rm));
        jit_alu(kind - K_ALU_R_RM_OP, if kind == K_ALU_R_RM_OP + 7 { 8 } else { reg });
    }
    else if kind >= K_ALU_RM_I_OP && kind < K_ALU_RM_I_OP + 8 {
        a_mov(3, g(rm)); a_movi(4, imm);
        jit_alu(kind - K_ALU_RM_I_OP, if kind == K_ALU_RM_I_OP + 7 { 8 } else { rm });
    }
    else if kind == K_TEST { a_mov(3, g(rm)); a_mov(4, g(reg)); jit_alu(4, 8); }
    else if kind == K_TEST_I { a_mov(3, g(rm)); a_movi(4, imm); jit_alu(4, 8); }
    else if kind == K_ALU_A_I { a_mov(3, 8); a_movi(4, imm); jit_alu(op >> 3, if op >> 3 == 7 { 8 } else { 0 }); }
    else { a_mov(3, 8); a_movi(4, imm); jit_alu(4, 8); }             // K_TEST_A_I
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
    return K_NONE;
}

// Translates the block that begins at physical address p, whose entry is at slot, if there is
// one worth having, and makes that entry a K_BLOCK.
fn jit_translate(p0: u32, slot0: i64) {
    let s0 = slot0 - DC_HALF;
    dc_hot[s0] = 255;                        // whatever comes of it, this is not tried again
    if jit_used + 65536 > JIT_SIZE { return; }
    jc = [];
    jf = F_MEM;
    jd = 0;
    a_ldp(8, 9, 0);
    a_ldp(10, 11, 8);
    a_ldp(12, 13, 16);
    a_ldp(14, 15, 24);
    var p = p0;
    var n = 0;
    var last = p0;
    var done = false;
    while !done && n < JIT_MAX {
        let slot: i64 = p & (DC_HALF - 1) | DC_HALF;
        if dc[slot].tag != p || p >> 12 != p0 >> 12 { break; }
        let kind = dc[slot].pre.kind;
        let mm = dc[slot].m;
        let nx = dc_next[slot];
        if kind == K_JMP {
            jit_leave(nx + dc[slot].imm);
            last = p; n += 1; done = true;
        } else if kind == K_JCC || (kind >= K_JCC_MASK && kind <= K_JCC_LE) {
            if !jit_jcc(jit_cc(kind, dc[slot].disp), nx, nx + dc[slot].imm) { break; }
            last = p; n += 1; done = true;
        } else if jit_unpair(kind) != K_NONE {
            let first = jit_unpair(kind);
            if !jit_plain(first, mm, dc[slot].pre.op) { break; }
            let b = dc[slot].bytes;
            // The pair's first instruction decides whether the jump can be had; if it cannot,
            // the block ends before the pair, and nothing of the pair is generated.
            let keep_f = jf;
            let keep_d = jd;
            let keep_len = jc.len;
            jit_one(first, slot);
            if !jit_jcc(jit_cc(K_JCC_MASK, b as! u32), nx, nx + (b >> 32) as! u32) {
                jf = keep_f; jd = keep_d;
                while jc.len > keep_len { jc.pop(); }
                break;
            }
            last = p; n += 2; done = true;
        } else if kind - 1 < K_LAST && jit_plain(kind, mm, dc[slot].pre.op) {
            jit_one(kind, slot);
            last = p; n += 1;
            p = nx;
        } else { break; }
    }
    if n < 2 { return; }
    if !done { jit_leave(p); }
    jit_write(jit_mem + jit_used, jc[..]);
    jit_code[s0] = jit_mem + jit_used;
    jit_used += jc.len;
    jit_kind[s0] = dc[slot0].pre.kind;
    jit_n[s0] = n as! u8;
    jit_last[s0] = last;
    jit_gen[s0] = code_gen[p0 >> 12];
    dc[slot0].pre.kind = K_BLOCK;
    jit_blocks += 1;
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

// Runs the block whose first instruction's entry is at slot, if the block is still good and
// the run has the time (room instructions) and the room for all of it. Returns how many
// instructions it ran, with the next address in jit_next; 0 if it did not run.
var jit_next: u32 = 0;

fn jit_enter(slot: i64, room: i64) -> i64 {
    let s = slot - DC_HALF;
    let head = dc[slot].tag;
    if jit_gen[s] != code_gen[head >> 12] {
        // A store has been made into this page since: the block is dropped.
        dc[slot].pre.kind = jit_kind[s];
        dc_hot[s] = 0;
        return 0;
    }
    let n: i64 = jit_n[s];
    if room < n || jit_last[s] > run_pmax { return 0; }
    jit_next = jit_call(jit_code[s], cpu.regs[..]) as! u32;
    jit_ran += n;
    return n;
}
