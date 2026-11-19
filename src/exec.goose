// Instruction execution: a 386, in real mode, protected mode and virtual-8086 mode. The default
// operand and address size come from the code segment (16 bits in real mode); the 66h and 67h
// prefixes switch to the other. To software that asks, the 16-bit machine is a 386 with no FPU and no
// CPUID: FLAGS bits 12-14 can be written and PUSH SP pushes the value from before the decrement.
//
// exec_one runs one instruction and returns false when a fault cut it short (see raise in
// state.goose). step wraps it: it restores the state the instruction started from and delivers
// the fault.

import std;
import os;
import state;
import alu;
import prot;
import bios;
import dev;
import fpu;
import sse;

// ---- Decode state that lives for one instruction ----

// What the prefixes and the opcode of the instruction being executed say (see Pre in state.goose).
// Padding: Goose packs globals, and what follows is to sit at a multiple of 8 (E050;
// tools/layout.sh shows where each global is, and tools/difftest.sh checks these).
var pad_ins: u8[6] = [0; 6];
var ins: Pre = Pre { op: 0, plen: 0, osz: 16, asz32: false, lock: false, rep: 0, seg: -1, kind: 0 };
var ea_seg = 3;              // segment register of the effective address (starts as DS)
var dc_cur = -1;             // this instruction's entry in the decode cache, or -1 when it has none
var ea_off: u32 = 0;
var dc_ip0: u32 = 0;         // the instruction pointer at the instruction's first byte
var pending_err: u32 = 0;
var shadow = false;          // the instruction just executed holds interrupts off for one more
var m_mod: u8 = 0;
var m_reg: u8 = 0;
var m_rm: u8 = 0;

// ---- Fetch ----

// The code segment decides the default operand and address size, and the width of EIP.
inline fn code32() -> bool { return cpu.attr[CS] & A_BIG != 0; }

// An instruction that has an entry in the decode cache (dc_cur, further down) has had its
// bytes checked: they are in the translated page (its next 16, or in the page's last fifteen
// bytes the instruction's own, E088), inside the segment and in RAM. Its fetches are plain
// loads.
inline fn fetch8() -> u8 {
    if dc_cur >= 0 {
        let q: i64 = code_phys | (cpu.base[CS] + cpu.ip) & 0xFFF;
        cpu.ip += 1;
        if q < RAM_SIZE { return ram[q]; }
        return 0xFF;
    }
    if cpu.ip > cpu.limit[CS] { raise_gp(0); }
    let a = cpu.base[CS] + cpu.ip;
    // Translate once per page of code, not once per byte.
    if a >> 12 != code_page {
        code_phys = page_read(a);
        code_page = a >> 12;
        code_ok = code_phys < RAM_SIZE - 4096 && code_phys + 0xFFF <= phys_mask;
    }
    let b = mem8(code_phys | a & 0xFFF);
    cpu.ip += 1;
    if !code32() { cpu.ip &= 0xFFFF; }
    return b;
}

// The wider fetches take their bytes at once when all of them lie in the page of code already
// translated and inside the segment; otherwise byte by byte, which also finds the fault.
inline fn fetch16() -> u32 {
    if dc_cur >= 0 {
        let q: i64 = code_phys | (cpu.base[CS] + cpu.ip) & 0xFFF;
        cpu.ip += 2;
        if q < RAM_SIZE - 1 {
            let b0: u32 = ram[q];
            let b1: u32 = ram[q + 1];
            return b0 | b1 << 8;
        }
        return 0xFFFF;
    }
    let a = cpu.base[CS] + cpu.ip;
    let lim = cpu.limit[CS];
    if a >> 12 == code_page && a & 0xFFF <= 0xFFE && lim >= 1 && cpu.ip <= lim - 1 {
        cpu.ip += 2;
        if !code32() { cpu.ip &= 0xFFFF; }
        return mem16(code_phys | a & 0xFFF);
    }
    let lo: u32 = fetch8();
    let hi: u32 = fetch8();
    return lo | hi << 8;
}

inline fn fetch32() -> u32 {
    if dc_cur >= 0 {
        let q: i64 = code_phys | (cpu.base[CS] + cpu.ip) & 0xFFF;
        cpu.ip += 4;
        if q < RAM_SIZE - 3 {
            let b0: u32 = ram[q];
            let b1: u32 = ram[q + 1];
            let b2: u32 = ram[q + 2];
            let b3: u32 = ram[q + 3];
            return b0 | b1 << 8 | b2 << 16 | b3 << 24;
        }
        return 0xFFFFFFFF;
    }
    let a = cpu.base[CS] + cpu.ip;
    let lim = cpu.limit[CS];
    if a >> 12 == code_page && a & 0xFFF <= 0xFFC && lim >= 3 && cpu.ip <= lim - 3 {
        cpu.ip += 4;
        if !code32() { cpu.ip &= 0xFFFF; }
        return mem32(code_phys | a & 0xFFF);
    }
    let lo = fetch16();
    let hi = fetch16();
    return lo | hi << 16;
}

// An immediate or displacement of the operand size.
inline fn fetchv() -> u32 {
    if ins.osz == 16 { return fetch16(); }
    return fetch32();
}

inline fn fetchw(w: u8) -> u32 {
    if w == 8 { return fetch8(); }
    if w == 16 { return fetch16(); }
    return fetch32();
}

// A byte, sign-extended to 32 bits.
inline fn fetch_s8() -> u32 { return (fetch8() as! i8) as! u32; }

// ---- Operands ----

// The default segment def, replaced by an override prefix when there is one.
inline fn seg_of(def: i64) -> i64 {
    if ins.seg >= 0 { return ins.seg; }
    return def;
}

// ---- The decode cache ----
//
// How an instruction decodes depends only on its bytes and on whether the code segment is a
// 16-bit or a 32-bit one, so it is remembered: per instruction address, the prefixes, the opcode,
// and the operand that the ModRM, SIB and displacement bytes describe. The next time the
// instruction runs, the parsing is skipped and the remembered fields are used.
//
// An entry is trusted only if the instruction's bytes are still the ones it was made from: its
// first eight bytes are compared, under a mask of the bytes the entry depends on. So nothing has
// to watch writes to memory, and code that changes itself, or a different program at the same
// address, simply fails the comparison and is decoded again. An instruction whose prefixes,
// opcode and operand take more than eight bytes has only its prefixes and opcode cached.
// Immediate operands are never cached: they are fetched each time.
//
// Entries for 16-bit and for 32-bit code segments are kept apart, in two halves of the table,
// since the same bytes decode differently in the two.
// The fields of Decoded.m, from bit 0: 1 when the operand is cached and 2 when it never will be
// (2 bits), mod, reg and r/m (2, 3, 3), the length of the operand's bytes (4), the base register
// plus one and the index register plus one (4 each, 0 for none), the scale (2), whether the
// default segment is SS, and whether the address is a 16-bit one.
let M_SS = 0x01000000;
let M_A16 = 0x02000000;

var dc_on = true;

// Eight bytes of RAM at p, or zero where they are not all there. The range test is here, and
// written against the constant, so that the compiler can see the eight indexes are in range:
// without their bounds checks the eight loads become one.
inline fn code64(p: u32) -> u64 {
    if p < RAM_SIZE - 8 {
        // A 64-bit index: with a 32-bit one the compiler cannot tell that q + 1 follows q.
        let q: i64 = p;
        let b0: u64 = ram[q];
        let b1: u64 = ram[q + 1];
        let b2: u64 = ram[q + 2];
        let b3: u64 = ram[q + 3];
        let b4: u64 = ram[q + 4];
        let b5: u64 = ram[q + 5];
        let b6: u64 = ram[q + 6];
        let b7: u64 = ram[q + 7];
        return b0 | b1 << 8 | b2 << 16 | b3 << 24 | b4 << 32 | b5 << 40 | b6 << 48 | b7 << 56;
    }
    return 0;
}

// The mask for the first n bytes, n from 1 to 8.
inline fn byte_mask(n: u32) -> u64 {
    if n >= 8 { return 0xFFFFFFFFFFFFFFFF; }
    let one: u64 = 1;
    return (one << (n * 8)) - 1;
}

// The effective address from a decoded operand and the registers as they are now.
inline fn ea_from(mm: u32, disp: u32) {
    if mm & M_A16 != 0 {
        var def = DS;
        var o: u16 = disp as! u16;
        match m_rm {
            0 => { o += r16(BX) + r16(SI); },
            1 => { o += r16(BX) + r16(DI); },
            2 => { o += r16(BP) + r16(SI); def = SS; },
            3 => { o += r16(BP) + r16(DI); def = SS; },
            4 => { o += r16(SI); },
            5 => { o += r16(DI); },
            6 => { if m_mod != 0 { o += r16(BP); def = SS; } },
            _ => { o += r16(BX); },
        }
        ea_off = o;
        ea_seg = seg_of(def);
        return;
    }
    var off = disp;
    let base = mm >> 14 & 15;
    if base != 0 { off += r32((base - 1) as! u8); }
    let index = mm >> 18 & 15;
    if index != 0 { off += r32((index - 1) as! u8) << (mm >> 22 & 3); }
    ea_off = off;
    ea_seg = seg_of(if mm & M_SS != 0 { SS } else { DS });
}

// The operand of the instruction: from the cache when it is there, inline, since that is a
// handful of loads; otherwise parsed from the bytes, by a call.
inline fn decode_modrm() {
    if dc_cur >= 0 {
        let mm = dc[dc_cur].m;
        if mm & 3 == 1 {
            m_mod = (mm >> 2 & 3) as! u8;
            m_reg = (mm >> 4 & 7) as! u8;
            m_rm = (mm >> 7 & 7) as! u8;
            cpu.ip += mm >> 10 & 15;
            if m_mod != 3 { ea_from(mm, dc[dc_cur].disp); }
            return;
        }
    }
    parse_modrm();
}

fn parse_modrm() {
    let ip0 = cpu.ip;
    let m = fetch8();
    m_mod = m >> 6;
    m_reg = m >> 3 & 7;
    m_rm = m & 7;
    let m32: u32 = m;
    var mm: u32 = (m32 >> 6) << 2 | (m32 >> 3 & 7) << 4 | (m32 & 7) << 7;
    var disp: u32 = 0;
    if m_mod != 3 {
        if !ins.asz32 {
            mm |= M_A16;
            if m_rm == 6 && m_mod == 0 { disp = fetch16(); }
            if m_mod == 1 { disp = fetch_s8() & 0xFFFF; } else if m_mod == 2 { disp = fetch16(); }
        } else {
            if m_rm == 4 {
                let sib: u32 = fetch8();
                let index = sib >> 3 & 7;
                let base = sib & 7;
                if base == 5 && m_mod == 0 { disp = fetch32(); }
                else {
                    mm |= (base + 1) << 14;
                    if base == 4 || base == 5 { mm |= M_SS; }
                }
                if index != 4 { mm |= (index + 1) << 18 | (sib >> 6) << 22; }
            }
            else if m_rm == 5 && m_mod == 0 { disp = fetch32(); }
            else {
                mm |= ((m32 & 7) + 1) << 14;
                if m_rm == 5 { mm |= M_SS; }
            }
            if m_mod == 1 { disp += fetch_s8(); } else if m_mod == 2 { disp += fetch32(); }
        }
    }
    if dc_cur >= 0 && dc[dc_cur].m == 0 {
        // Remember the operand, if the whole instruction up to here fits in the eight bytes
        // that are compared.
        let total = cpu.ip - dc_ip0;
        if total <= 8 {
            dc[dc_cur].m = mm | 1 | (cpu.ip - ip0) << 10;
            dc[dc_cur].disp = disp;
            dc[dc_cur].mask = byte_mask(total);
        } else {
            dc[dc_cur].m = 2;
        }
    }
    if m_mod != 3 { ea_from(mm, disp); }
}

inline fn rm_read(w: u8) -> u32 {
    if m_mod == 3 { return regw(m_rm, w); }
    return seg_read(ea_seg, ea_off, w);
}

inline fn rm_write(w: u8, v: u32) {
    if m_mod == 3 { set_regw(m_rm, w, v); } else { seg_write(ea_seg, ea_off, w, v); }
}

// The width of an instruction whose low opcode bit selects byte or word.
inline fn width(op: u8) -> u8 { if op & 1 == 0 { return 8; } return ins.osz; }

inline fn cond(c: u8) -> bool {
    let r = match c >> 1 {
        0 => flag(OF),
        1 => flag(CF),
        2 => flag(ZF),
        3 => flag(CF) || flag(ZF),
        4 => flag(SF),
        5 => flag(PF),
        6 => flag(SF) != flag(OF),
        _ => flag(ZF) || (flag(SF) != flag(OF)),
    };
    if c & 1 != 0 { return !r; }
    return r;
}

// ---- Stack and control transfer, at the operand size ----

inline fn pushv(v: u32) { push_w(v, ins.osz); }
inline fn popv() -> u32 { return pop_w(ins.osz); }

// A jump target is cut to 16 bits when the operand size is 16.
inline fn set_ip(v: u32) { cpu.ip = if ins.osz == 16 { v & 0xFFFF } else { v }; }

inline fn jump_rel8(taken: bool) {
    let d = fetch_s8();
    if taken { set_ip(cpu.ip + d); }
}

// A fault with no error code: divide error (0), bound range (5), invalid opcode (6).
fn fault(n: u8) { raise(n, false, 0); }

// Instructions only the most privileged level may execute.
fn need_ring0() { if protected() && cpu.cpl != 0 { raise_gp(0); } }

// Instructions that need the I/O privilege level: CLI, STI, and in virtual-8086 mode also
// PUSHF, POPF, INT n and IRET.
fn io_sensitive() {
    if !protected() { return; }
    if v86() { if iopl() < 3 { raise_gp(0); } }
    else if cpu.cpl > iopl() { raise_gp(0); }
}

// ---- Registers used as addresses and counters: 16 or 32 bits by the address size ----

inline fn addr_reg(i: u8) -> u32 { if ins.asz32 { return r32(i); } return r16(i); }

fn addr_reg_add(i: u8, d: u32) {
    if ins.asz32 { set_r32(i, r32(i) + d); } else { set_r16(i, r16(i) + (d as! u16)); }
}

// ---- String instructions (A4..A7, AA..AF, 6C..6F) ----

// A data segment that is valid, writable, starts anywhere and covers all 4 GB: no access to it
// can fail the segment check.
inline fn flat_data(sg: i64) -> bool {
    return cpu.limit[sg] == 0xFFFFFFFF && (cpu.attr[sg] & (A_VALID | A_CODE | A_DOWN_CONF | A_RW)) == (A_VALID | A_RW);
}

// REP MOVS and REP STOS going upward, as many elements at once as lie within one page of the
// source and one page of the destination, with one translation for each. Element by element, in
// order, exactly as the instruction does it, so that overlapping regions come out the same; what
// is saved is the segment check, the translation and the bookkeeping per element. Stops, having
// done what it could, at anything it does not handle: an element that straddles a page, memory
// outside RAM or where physical addresses wrap, a segment that is not flat. The caller's loop then does one element the ordinary
// way and tries this again. A page fault here leaves the registers at the last whole run.
fn string_bulk(movs: bool, src: i64, w: u8) {
    if !flat_data(ES) || (movs && !flat_data(src)) { return; }
    let nb: u32 = ((w as u32) >> 3);
    let sh: u32 = if w == 8 { 0 } else if w == 16 { 1 } else { 2 };
    loop {
        var n = cpu.regs[CX];
        if n == 0 { return; }
        let dl = cpu.base[ES] + cpu.regs[DI];
        let room_d = (0x1000 - (dl & 0xFFF)) >> sh;
        if room_d < n { n = room_d; }
        var sl: u32 = 0;
        if movs {
            sl = cpu.base[src] + cpu.regs[SI];
            let room_s = (0x1000 - (sl & 0xFFF)) >> sh;
            if room_s < n { n = room_s; }
        }
        if n == 0 { return; }
        // The page must be in RAM and below the point where physical addresses wrap.
        let dpage = page_write(dl);
        if dpage >= RAM_SIZE - 4096 || dpage > phys_mask - 0xFFF { return; }
        let dp: i64 = dpage | dl & 0xFFF;
        if code_mark[dpage >> 12] != 0 { code_written(dpage | dl & 0xFFF, n << sh); }
        let v = cpu.regs[AX];
        if movs {
            let spage = page_read(sl);
            if spage >= RAM_SIZE - 4096 || spage > phys_mask - 0xFFF { return; }
            let sp: i64 = spage | sl & 0xFFF;
            if w == 32 {
                for k in n {
                    let at = k << 2;
                    let b0 = ram[sp + at]; let b1 = ram[sp + at + 1]; let b2 = ram[sp + at + 2]; let b3 = ram[sp + at + 3];
                    ram[dp + at] = b0; ram[dp + at + 1] = b1; ram[dp + at + 2] = b2; ram[dp + at + 3] = b3;
                }
            } else if w == 16 {
                for k in n {
                    let at = k << 1;
                    let b0 = ram[sp + at]; let b1 = ram[sp + at + 1];
                    ram[dp + at] = b0; ram[dp + at + 1] = b1;
                }
            } else {
                for k in n { ram[dp + k] = ram[sp + k]; }
            }
            cpu.regs[SI] += n << sh;
        } else if w == 32 {
            for k in n {
                let at = k << 2;
                ram[dp + at] = v as! u8; ram[dp + at + 1] = (v >> 8) as! u8; ram[dp + at + 2] = (v >> 16) as! u8; ram[dp + at + 3] = (v >> 24) as! u8;
            }
        } else if w == 16 {
            for k in n { let at = k << 1; ram[dp + at] = v as! u8; ram[dp + at + 1] = (v >> 8) as! u8; }
        } else {
            for k in n { ram[dp + k] = v as! u8; }
        }
        cpu.regs[DI] += n << sh;
        cpu.regs[CX] -= n;
        // A repeated instruction that faults part-way resumes from where it got to.
        saved.regs = cpu.regs;
    }
}

// REPNE SCASB and REPE SCASB going upward through a flat ES, the bytes of one page at a time
// with one translation, stopping where the instruction stops: after the first byte that is
// (REPNE) or is not (REPE) AL, or when ECX runs out. The flags are those of the last byte
// compared, set once. True when a byte ended it; false when ECX ran out, or at anything this
// does not handle, and then the caller's loop goes on as before. A page fault leaves the
// registers at the last whole page.
fn scas_bulk() -> bool {
    if !flat_data(ES) { return false; }
    let al = r8(0);
    let until_equal = ins.rep == 1;
    loop {
        var n = cpu.regs[CX];
        if n == 0 { return false; }
        let dl = cpu.base[ES] + cpu.regs[DI];
        let room = 0x1000 - (dl & 0xFFF);
        if room < n { n = room; }
        let dpage = page_read(dl);
        if dpage >= RAM_SIZE - 4096 || dpage > phys_mask - 0xFFF { return false; }
        let dp: i64 = dpage | dl & 0xFFF;
        var done: u32 = 0;
        var last: u8 = 0;
        var ended = false;
        for k in n {
            last = ram[dp + k];
            done = k + 1;
            if (last == al) == until_equal { ended = true; break; }
        }
        cpu.regs[DI] += done;
        cpu.regs[CX] -= done;
        let a: u32 = al;
        let b: u32 = last;
        alu(7, a, b, 8);
        // A repeated instruction that faults part-way resumes from where it got to.
        saved.regs = cpu.regs;
        saved.flags = cpu.flags;
        if ended { return true; }
    }
}

fn string_op(op: u8) {
    let w = width(op);
    let n: u32 = ((w as u32) >> 3);
    let d: u32 = if flag(DF) { 0 - n } else { n };
    let kind = op & 0xFE;
    let src = seg_of(DS);
    let bulk = ins.rep == 2 && ins.asz32 && !flag(DF) && (kind == 0xA4 || kind == 0xAA);
    let scan = ins.rep != 0 && ins.asz32 && !flag(DF) && op == 0xAE;
    loop {
        if bulk { string_bulk(kind == 0xA4, src, w); }
        if scan && scas_bulk() { break; }
        if ins.rep != 0 && addr_reg(CX) == 0 { break; }
        match kind {
            0xA4 => {
                seg_write(ES, addr_reg(DI), w, seg_read(src, addr_reg(SI), w));
                addr_reg_add(SI, d);
                addr_reg_add(DI, d);
            },
            0xA6 => {
                let a = seg_read(src, addr_reg(SI), w);
                let b = seg_read(ES, addr_reg(DI), w);
                alu(7, a, b, w);
                addr_reg_add(SI, d);
                addr_reg_add(DI, d);
            },
            0xAA => {
                seg_write(ES, addr_reg(DI), w, regw(0, w));
                addr_reg_add(DI, d);
            },
            0xAC => {
                set_regw(0, w, seg_read(src, addr_reg(SI), w));
                addr_reg_add(SI, d);
            },
            0xAE => {
                alu(7, regw(0, w), seg_read(ES, addr_reg(DI), w), w);
                addr_reg_add(DI, d);
            },
            0x6C => {
                io_check(r16(DX), w);
                seg_write(ES, addr_reg(DI), w, port_read(r16(DX), w));
                addr_reg_add(DI, d);
            },
            _ => {
                io_check(r16(DX), w);
                port_write(r16(DX), w, seg_read(src, addr_reg(SI), w));
                addr_reg_add(SI, d);
            },
        }
        if ins.rep == 0 { break; }
        addr_reg_add(CX, 0xFFFFFFFF);
        // A repeated instruction that faults part-way resumes from where it got to.
        saved.regs = cpu.regs;
        saved.flags = cpu.flags;
        if kind == 0xA6 || kind == 0xAE {
            if ins.rep == 2 && !flag(ZF) { break; }
            if ins.rep == 1 && flag(ZF) { break; }
        }
    }
}

// ---- I/O at a width ----

fn port_read(port: u16, w: u8) -> u32 {
    if w == 8 { return port_in8(port); }
    if w == 16 { return port_in(port); }
    let lo: u32 = port_in(port);
    let hi: u32 = port_in(if port == 0x1F0 { port } else { port + 2 });      // the disk's data port
    return lo | hi << 16;
}

fn port_write(port: u16, w: u8, v: u32) {
    if w == 8 { port_out8(port, v as! u8); }
    else if w == 16 { port_out(port, v as! u16); }
    else { port_out(port, v as! u16); port_out(if port == 0x1F0 { port } else { port + 2 }, (v >> 16) as! u16); }
}

// ---- Multiply and divide ----

// Signed multiply of two values of width w; stores nothing. Returns the product and sets CF and OF
// when the product does not fit in w bits.
fn imul(a: u32, b: u32, w: u8) -> i64 {
    let p = sx(a, w) * sx(b, w);
    let low = sx(p as! u32, w);
    set_flag(CF, p != low);
    set_flag(OF, p != low);
    return p;
}

// F6 / F7: TEST NOT NEG MUL IMUL DIV IDIV
fn group3(op: u8) {
    let w = width(op);
    decode_modrm();
    let v = rm_read(w);
    match m_reg {
        0, 1 => { alu(4, v, fetchw(w), w); },
        2 => { rm_write(w, ~v & mask(w)); },
        3 => { rm_write(w, alu(5, 0, v, w)); },
        4 => {
            // Never multiply a call that returns a narrower type by a wider value directly
            // (docs/goose-notes.md, item 1): operands go through typed locals first.
            let a: u64 = regw(0, w);
            let b: u64 = v;
            let p = a * b;
            let high: u64 = if w == 8 { p >> 8 } else if w == 16 { p >> 16 } else { p >> 32 };
            if w == 8 { set_r16(AX, p as! u16); }
            else { set_regw(AX, w, (p & 0xFFFFFFFF) as! u32); set_regw(DX, w, (high & 0xFFFFFFFF) as! u32); }
            let m: u64 = mask(w);
            set_flag(CF, high & m != 0);
            set_flag(OF, high & m != 0);
        },
        5 => {
            let p = imul(regw(0, w), v, w);
            if w == 8 { set_r16(AX, p as! u16); }
            else if w == 16 { set_r16(AX, p as! u16); set_r16(DX, (p >> 16) as! u16); }
            else { set_r32(AX, p as! u32); set_r32(DX, (p >> 32) as! u32); }
        },
        6 => {
            if v == 0 { fault(0); return; }
            let d: u64 = v;
            var n: u64 = 0;
            if w == 8 { n = r16(AX); }
            else if w == 16 { let hi: u64 = r16(DX); let lo: u64 = r16(AX); n = hi << 16 | lo; }
            else { let hi: u64 = r32(DX); let lo: u64 = r32(AX); n = hi << 32 | lo; }
            let q = n / d;
            let limit: u64 = mask(w);
            if q > limit { fault(0); return; }
            let r = n - q * d;
            if w == 8 { set_r8(0, q as! u8); set_r8(4, r as! u8); }
            else { set_regw(AX, w, q as! u32); set_regw(DX, w, r as! u32); }
        },
        _ => {
            if v == 0 { fault(0); return; }
            let d = sx(v, w);
            var n: i64 = 0;
            if w == 8 { n = sx(r16(AX), 16); }
            else if w == 16 { let hi = sx(r16(DX), 16); let lo: i64 = r16(AX); n = hi * 65536 + lo; }
            else {
                let hi: u64 = r32(DX);
                let lo: u64 = r32(AX);
                // The one quotient that does not fit in i64 either.
                if hi == 0x80000000 && lo == 0 && d == -1 { fault(0); return; }
                n = (hi << 32 | lo) as! i64;
            }
            let q = n / d;
            let top: i64 = msb(w);
            if q < 0 - top || q >= top { fault(0); return; }
            let r = n - q * d;
            if w == 8 { set_r8(0, q as! u8); set_r8(4, r as! u8); }
            else { set_regw(AX, w, q as! u32); set_regw(DX, w, r as! u32); }
        },
    }
}

// FE / FF: INC DEC CALL CALLF JMP JMPF PUSH
fn group45(op: u8) {
    let w = width(op);
    decode_modrm();
    if m_reg == 0 { rm_write(w, inc(rm_read(w), w)); return; }
    if m_reg == 1 { rm_write(w, dec(rm_read(w), w)); return; }
    if w == 8 { fault(6); return; }
    match m_reg {
        2 => { let t = rm_read(ins.osz); pushv(cpu.ip); set_ip(t); },
        3 => {
            if m_mod == 3 { fault(6); return; }
            let off = seg_read(ea_seg, ea_off, ins.osz);
            far_call(seg_read(ea_seg, ea_off + ((ins.osz as u32) >> 3), 16) as! u16, off, ins.osz);
        },
        4 => { set_ip(rm_read(ins.osz)); },
        5 => {
            if m_mod == 3 { fault(6); return; }
            let off = seg_read(ea_seg, ea_off, ins.osz);
            far_jump(seg_read(ea_seg, ea_off + ((ins.osz as u32) >> 3), 16) as! u16, off);
        },
        6 => { pushv(rm_read(ins.osz)); },
        _ => { fault(6); },
    }
}

// ---- BCD adjustment ----

fn daa_das(sub: bool) {
    let old = r8(0);
    let old_cf = flag(CF);
    var al = old;
    var cf = false;
    if old & 0x0F > 9 || flag(AF) {
        if sub { cf = old_cf || al < 6; al -= 6; } else { cf = old_cf || al > 0xF9; al += 6; }
        set_flag(AF, true);
    } else {
        set_flag(AF, false);
    }
    if old > 0x99 || old_cf {
        if sub { al -= 0x60; } else { al += 0x60; }
        cf = true;
    }
    set_r8(0, al);
    set_flag(CF, cf);
    set_szp(al, 8);
}

fn aaa_aas(sub: bool) {
    if r8(0) & 0x0F > 9 || flag(AF) {
        if sub { set_r16(AX, r16(AX) - 6); set_r8(4, r8(4) - 1); }
        else { set_r16(AX, r16(AX) + 6); set_r8(4, r8(4) + 1); }
        set_flag(AF, true);
        set_flag(CF, true);
    } else {
        set_flag(AF, false);
        set_flag(CF, false);
    }
    set_r8(0, r8(0) & 0x0F);
}

// ---- Two-byte instructions (0Fh) ----

// Loads a far pointer from memory into a general register and a segment register (LES LDS LSS LFS LGS).
fn load_far(s: i64) {
    decode_modrm();
    if m_mod == 3 { fault(6); return; }
    let off = seg_read(ea_seg, ea_off, ins.osz);
    let sel = seg_read(ea_seg, ea_off + ((ins.osz as u32) >> 3), 16) as! u16;
    load_seg(s, sel);
    set_regw(m_reg, ins.osz, off);
    if s == SS { shadow = true; }
}

// BT BTS BTR BTC. action: 0 test only, 1 set, 2 reset, 3 complement.
fn bit_op(action: u8, bit: u32, from_register: bool) {
    let w = ins.osz;
    var index = bit & ((w as u32) - 1);
    if m_mod != 3 && from_register {
        // A bit offset in a register reaches outside the operand: the address moves by whole
        // operands, signed.
        let words = sx(bit, w) >> (if w == 16 { 4 } else { 5 });
        ea_off += (words * ((w as i64) / 8)) as! u32;
        if !ins.asz32 { ea_off &= 0xFFFF; }
    }
    let v = rm_read(w);
    let m: u32 = 1 << index;
    set_flag(CF, v & m != 0);
    if action == 1 { rm_write(w, v | m); }
    else if action == 2 { rm_write(w, v & ~m); }
    else if action == 3 { rm_write(w, v ^ m); }
}

fn two_byte() {
    let op = fetch8();
    // MMX and SSE2 (sse.goose): a third of the two-byte opcodes, on the i686 only.
    if i686 && sse_is(op) { sse_op(op); return; }
    match op >> 4 {
        0x0 => {
            match op {
                0x00 => {
                    decode_modrm();
                    if !protected() || v86() { fault(6); }
                    match m_reg {
                        0 => { rm_write(if m_mod == 3 { ins.osz } else { 16 }, ldtr_sel); },         // SLDT
                        1 => { rm_write(if m_mod == 3 { ins.osz } else { 16 }, tr_sel); },           // STR
                        2 => {                                                                    // LLDT
                            need_ring0();
                            let sel = rm_read(16) as! u16;
                            if sel & 0xFFFC == 0 { ldtr_sel = sel; ldtr_base = 0; ldtr_limit = 0; return; }
                            if sel & 4 != 0 { raise_gp(sel & 0xFFFC); }
                            let at, lo, hi = read_desc(sel, 0);
                            if hi >> 8 & 0x1F != 2 { raise_gp(sel & 0xFFFC); }
                            if hi & 0x8000 == 0 { raise_np(sel & 0xFFFC); }
                            ldtr_sel = sel;
                            ldtr_base = d_base(lo, hi);
                            ldtr_limit = d_limit(lo, hi);
                        },
                        3 => {                                                                    // LTR
                            need_ring0();
                            let sel = rm_read(16) as! u16;
                            if sel & 0xFFFC == 0 { raise_gp(0); }
                            if sel & 4 != 0 { raise_gp(sel & 0xFFFC); }
                            let at, lo, hi = read_desc(sel, 0);
                            let kind = hi >> 8 & 0x1F;
                            if kind != 1 && kind != 9 { raise_gp(sel & 0xFFFC); }
                            if hi & 0x8000 == 0 { raise_np(sel & 0xFFFC); }
                            tr_sel = sel;
                            tr_base = d_base(lo, hi);
                            tr_limit = d_limit(lo, hi);
                            tr_32 = kind == 9;
                            sys_write(at + 5, 8, hi >> 8 & 0xFF | 2);                             // now busy
                        },
                        4, 5 => {                                                                 // VERR, VERW
                            let sel = rm_read(16) as! u16;
                            let at, ok = desc_at(sel);
                            var good = ok && sel & 0xFFFC != 0;
                            if good {
                                let hi = sys_read(at + 4, 32);
                                let acc = hi >> 8;
                                let rpl: u8 = (sel & 3) as! u8;
                                if acc & A_S == 0 { good = false; }
                                else if m_reg == 4 && acc & A_CODE != 0 && acc & A_RW == 0 { good = false; }
                                else if m_reg == 5 && (acc & A_CODE != 0 || acc & A_RW == 0) { good = false; }
                                else if (acc & A_CODE == 0 || acc & A_DOWN_CONF == 0) && (d_dpl(hi) < cpu.cpl || d_dpl(hi) < rpl) { good = false; }
                            }
                            set_flag(ZF, good);
                        },
                        _ => { fault(6); },
                    }
                },
                0x01 => {
                    decode_modrm();
                    match m_reg {
                        0, 1 => {                                    // SGDT, SIDT
                            if m_mod == 3 { fault(6); }
                            seg_write(ea_seg, ea_off, 16, if m_reg == 0 { gdtr_limit } else { idtr_limit });
                            seg_write(ea_seg, ea_off + 2, 32, if m_reg == 0 { gdtr_base } else { idtr_base });
                        },
                        2, 3 => {                                    // LGDT, LIDT
                            if m_mod == 3 { fault(6); }
                            need_ring0();
                            let limit = seg_read(ea_seg, ea_off, 16);
                            var base = seg_read(ea_seg, ea_off + 2, 32);
                            if ins.osz == 16 { base &= 0x00FFFFFF; }
                            if m_reg == 2 { gdtr_limit = limit; gdtr_base = base; }
                            else { idtr_limit = limit; idtr_base = base; }
                        },
                        4 => { rm_write(if m_mod == 3 { ins.osz } else { 16 }, if m_mod == 3 && ins.osz == 32 { cr[0] } else { cr[0] & 0xFFFF }); },
                        6 => {                                       // LMSW: can set PE, cannot clear it
                            need_ring0();
                            cr[0] = cr[0] & 0xFFFFFFF1 | rm_read(16) & 0x0F;
                            flush_tlb();
                        },
                        7 => {                                       // INVLPG
                            if !i686 || m_mod == 3 { fault(6); }
                            need_ring0();
                            forget_page(cpu.base[ea_seg] + ea_off);
                        },
                        _ => { fault(6); },
                    }
                },
                0x02, 0x03 => {                                      // LAR, LSL
                    decode_modrm();
                    if !protected() || v86() { fault(6); }
                    let sel = rm_read(16) as! u16;
                    let at, ok = desc_at(sel);
                    var good = ok && sel & 0xFFFC != 0;
                    var lo: u32 = 0;
                    var hi: u32 = 0;
                    if good {
                        lo = sys_read(at, 32);
                        hi = sys_read(at + 4, 32);
                        let acc = hi >> 8;
                        let rpl: u8 = (sel & 3) as! u8;
                        let kind = acc & 0x0F;
                        if acc & A_S == 0 {
                            // System segments: LAR takes task segments, LDTs and gates; LSL only those with a limit.
                            let with_limit = kind == 1 || kind == 2 || kind == 3 || kind == 9 || kind == 11;
                            let gate = kind == 4 || kind == 5 || kind == 12;
                            if !(with_limit || (op == 0x02 && gate)) { good = false; }
                            else if d_dpl(hi) < cpu.cpl || d_dpl(hi) < rpl { good = false; }
                        }
                        else if (acc & A_CODE == 0 || acc & A_DOWN_CONF == 0) && (d_dpl(hi) < cpu.cpl || d_dpl(hi) < rpl) { good = false; }
                    }
                    set_flag(ZF, good);
                    if good {
                        if op == 0x02 { set_regw(m_reg, ins.osz, if ins.osz == 32 { hi & 0x00F0FF00 } else { hi & 0xFF00 }); }
                        else { set_regw(m_reg, ins.osz, d_limit(lo, hi)); }
                    }
                },
                0x06 => { need_ring0(); cr[0] &= 0xFFFFFFF7; },      // CLTS
                0x08, 0x09 => { if !i686 { fault(6); } need_ring0(); },                  // INVD, WBINVD: no cache
                0x0B => { fault(6); },                               // UD2
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode 0F", op); },
            }
        },
        0x1 => {
            match op {
                // The long NOP (0F 1F) and the prefetch hints (0F 18): an operand, and no effect.
                0x18, 0x1F => { if !i686 { fault(6); } decode_modrm(); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode 0F", op); },
            }
        },
        0x2 => {
            match op {
                0x20 => { decode_modrm(); need_ring0(); set_r32(m_rm, cr[m_reg]); },
                0x22 => {
                    decode_modrm();
                    need_ring0();
                    cr[m_reg] = r32(m_rm);
                    if i686 && m_reg == 0 { cr[0] |= 0x10; }          // ET: the FPU is a 387 or later, always
                    flush_tlb();
                    if !protected() { set_cpl(0); }
                },
                0x21, 0x23 => { decode_modrm(); need_ring0(); if op == 0x21 { set_r32(m_rm, 0); } },     // debug registers
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode 0F", op); },
            }
        },
        0x3 => {
            match op {
                // Instructions from the 486 on (CPUID, CMPXCHG, XADD, BSWAP, RDTSC ...) are invalid here.
                0x30, 0x32 => {                                      // WRMSR, RDMSR: no model-specific registers
                    if !i686 { fault(6); }
                    raise_gp(0);
                },
                0x31 => {                                            // RDTSC: the instruction count
                    if !i686 { fault(6); }
                    set_r32(AX, vtime as! u32);
                    set_r32(DX, (vtime >> 32) as! u32);
                },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode 0F", op); },
            }
        },
        0x4 => {
            // CMOVcc: a move that happens only if the condition holds. The source is read either way.
            if !i686 { fault(6); }
            decode_modrm();
            let v = rm_read(ins.osz);
            if cond(op & 0x0F) { set_regw(m_reg, ins.osz, v); }
        },
        0x8 => {
            match op {
                0x80..0x90 => {
                    let d = if ins.osz == 16 { ((fetch16() as! u16) as! i16) as! u32 } else { fetch32() };
                    if cond(op & 0x0F) { set_ip(cpu.ip + d); }
                },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode 0F", op); },
            }
        },
        0x9 => {
            match op {
                0x90..0xA0 => { decode_modrm(); rm_write(8, if cond(op & 0x0F) { 1 } else { 0 }); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode 0F", op); },
            }
        },
        0xA => {
            match op {
                0xA0 => { pushv(cpu.segs[FS]); },
                0xA1 => { load_seg(FS, popv() as! u16); },
                0xA8 => { pushv(cpu.segs[GS]); },
                0xA9 => { load_seg(GS, popv() as! u16); },
                0xA3 => { decode_modrm(); bit_op(0, regw(m_reg, ins.osz), true); },
                0xAB => { decode_modrm(); bit_op(1, regw(m_reg, ins.osz), true); },
                0xA4, 0xAC => {
                    decode_modrm();
                    let n = fetch8();
                    rm_write(ins.osz, shift_double(op == 0xA4, rm_read(ins.osz), regw(m_reg, ins.osz), n, ins.osz));
                },
                0xA5, 0xAD => {
                    decode_modrm();
                    rm_write(ins.osz, shift_double(op == 0xA5, rm_read(ins.osz), regw(m_reg, ins.osz), r8(1), ins.osz));
                },
                0xAF => {
                    decode_modrm();
                    let p = imul(regw(m_reg, ins.osz), rm_read(ins.osz), ins.osz);
                    set_regw(m_reg, ins.osz, p as! u32);
                },
                0xA2 => {                                            // CPUID
                    if !i686 { fault(6); }
                    let leaf = r32(AX);
                    set_r32(AX, 0);
                    set_r32(BX, 0);
                    set_r32(CX, 0);
                    set_r32(DX, 0);
                    if leaf == 0 {
                        set_r32(AX, 1);                              // the highest leaf
                        set_r32(BX, 0x756E6547);                     // "GenuineIntel"
                        set_r32(DX, 0x49656E69);
                        set_r32(CX, 0x6C65746E);
                    } else if leaf == 1 {
                        // Family 6, the P6. Only what is implemented is claimed: the FPU, the
                        // timestamp counter, CMPXCHG8B, CMOV, and (E077) MMX, FXSAVE and
                        // FXRSTOR, SSE and SSE2.
                        set_r32(AX, 0x0633);
                        set_r32(DX, 1 | 1 << 4 | 1 << 8 | 1 << 15 | 1 << 23 | 1 << 24 | 1 << 25 | 1 << 26);
                    }
                },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode 0F", op); },
            }
        },
        0xB => {
            match op {
                0xB3 => { decode_modrm(); bit_op(2, regw(m_reg, ins.osz), true); },
                0xBB => { decode_modrm(); bit_op(3, regw(m_reg, ins.osz), true); },
                0xBA => {
                    decode_modrm();
                    let bit: u32 = fetch8();
                    if m_reg < 4 { fault(6); return; }
                    bit_op(m_reg - 4, bit, false);
                },
                0xB2 => { load_far(SS); },
                0xB4 => { load_far(FS); },
                0xB5 => { load_far(GS); },
                0xB6 => { decode_modrm(); set_regw(m_reg, ins.osz, rm_read(8)); },
                0xB7 => { decode_modrm(); set_regw(m_reg, ins.osz, rm_read(16)); },
                0xBE => { decode_modrm(); set_regw(m_reg, ins.osz, sx(rm_read(8), 8) as! u32); },
                0xBF => { decode_modrm(); set_regw(m_reg, ins.osz, sx(rm_read(16), 16) as! u32); },
                0xBC, 0xBD => {                                      // BSF, BSR
                    decode_modrm();
                    let v = rm_read(ins.osz);
                    set_flag(ZF, v == 0);
                    if v != 0 {
                        var i: u32 = if op == 0xBC { 0 } else { (ins.osz as u32) - 1 };
                        loop {
                            if v >> i & 1 != 0 { break; }
                            if op == 0xBC { i += 1; } else { i -= 1; }
                        }
                        set_regw(m_reg, ins.osz, i);
                    }
                },
                0xB0, 0xB1 => {                                      // CMPXCHG
                    if !i686 { fault(6); }
                    let w = width(op);
                    decode_modrm();
                    let dst = rm_read(w);
                    let acc = regw(AX, w);
                    alu(7, acc, dst, w);
                    if acc == dst { rm_write(w, regw(m_reg, w)); } else { set_regw(AX, w, dst); }
                },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode 0F", op); },
            }
        },
        0xC => {
            match op {
                0xC0, 0xC1 => {                                      // XADD
                    if !i686 { fault(6); }
                    let w = width(op);
                    decode_modrm();
                    let dst = rm_read(w);
                    let src = regw(m_reg, w);
                    let sum = alu(0, dst, src, w);
                    set_regw(m_reg, w, dst);
                    rm_write(w, sum);
                },
                0xC7 => {                                            // CMPXCHG8B
                    if !i686 { fault(6); }
                    decode_modrm();
                    if m_mod == 3 || m_reg != 1 { fault(6); }
                    let lo = seg_read(ea_seg, ea_off, 32);
                    let hi = seg_read(ea_seg, ea_off + 4, 32);
                    if lo == r32(AX) && hi == r32(DX) {
                        seg_write(ea_seg, ea_off, 32, r32(BX));
                        seg_write(ea_seg, ea_off + 4, 32, r32(CX));
                        set_flag(ZF, true);
                    } else {
                        set_r32(AX, lo);
                        set_r32(DX, hi);
                        set_flag(ZF, false);
                    }
                },
                0xC8..0xD0 => {                                      // BSWAP
                    if !i686 { fault(6); }
                    let v = r32(op);
                    set_r32(op, v >> 24 | v >> 8 & 0xFF00 | (v & 0xFF00) << 8 | v << 24);
                },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode 0F", op); },
            }
        },
        _ => { cpu.ip = saved.ip; stop("unimplemented opcode 0F", op); },
    }
}

// ---- Short executors ----
//
// The instructions a 32-bit program runs most, each with a few lines of its own, reached
// straight from the decode cache instead of through the general dispatch. Only instructions of
// a 32-bit code segment with no prefix qualify, so the operand is 32 bits wide and addresses
// are 32-bit; everything else, and every instruction the first time it is met, takes the general
// path. What an instruction means is still said once: the executors call the same alu, shift,
// cond and segment access as the general code.
//
// For these the entry holds, besides the operand: the immediate or branch offset (imm), and in
// bits 26 to 29 of m the length of the whole instruction, which the mask then covers.
let K_NONE = 255;
let K_MOV_R_RM = 1;      // 8B from memory
let K_MOV_RM_R = 2;      // 89 to memory
let K_ALU_RM_R = 3;      // 01 09 11 19 21 29 31 39
let K_ALU_R_RM = 4;      // 03 0B 13 1B 23 2B 33 3B
let K_ALU_RM_I = 5;      // 83 and 81
let K_LEA = 6;           // 8D
let K_TEST = 7;          // 85
let K_SHIFT_I = 8;       // C1
let K_SHIFT_CL = 9;      // D3
let K_JCC = 10;          // 70 to 7F, and 0F 80 to 0F 8F; the condition is in disp
let K_JMP = 11;          // EB, E9
let K_CALL = 12;         // E8
let K_RET = 13;          // C3
let K_NOP = 14;          // 90
let K_PUSH = 15;         // 50 to 57
let K_POP = 16;          // 58 to 5F
let K_INC = 17;          // 40 to 47
let K_DEC = 18;          // 48 to 4F
let K_MOV_R_I = 19;      // B8 to BF
let K_MOVZX8 = 20;       // 0F B6
let K_MOVZX16 = 21;      // 0F B7
let K_MOV8_R_RM = 22;    // 8A
let K_MOV8_RM_R = 23;    // 88
let K_ALU8_RM_R = 24;    // 00 08 10 18 20 28 30 38
let K_ALU8_R_RM = 25;    // 02 0A 12 1A 22 2A 32 3A
let K_ALU8_RM_I = 26;    // 80
let K_TEST8 = 27;        // 84
let K_TEST8_I = 28;      // F6 /0 and /1
let K_TEST_I = 29;       // F7 /0 and /1
let K_IMUL = 30;         // 0F AF
let K_SETCC = 31;        // 0F 90 to 0F 9F; the condition is in imm
// An executor that knows which operation it is does not have to find out each time it runs.
let K_JCC_MASK = 32;     // Jcc on O, B, Z, BE, S or P and their opposites: taken when (flags & mask) != 0, or not
let K_JCC_L = 33;        // Jcc on L or GE: SF and OF differ, or not
let K_JCC_LE = 34;       // Jcc on LE or G
let K_SHL_I = 35;        // C1 /4 and /6 with a count from 1 to 31
let K_SHR_I = 36;        // C1 /5
let K_SAR_I = 37;        // C1 /7
let K_MOV_R_R = 38;      // 8B between registers: an executor that does not ask which form it has (E046)
let K_MOV_R_R_89 = 39;   // 89 between registers
let K_ALU_RM_R_OP = 40;  // 40 to 47: K_ALU_RM_R for one operation (ADC and SBB stay general)
let K_ALU_R_RM_OP = 48;  // 48 to 55
let K_ALU_RM_I_OP = 56;  // 56 to 63
let K_INC_RM = 64;       // FF /0
let K_DEC_RM = 65;       // FF /1
let K_NOT = 66;          // F7 /2
let K_NEG = 67;          // F7 /3
let K_MOV_RM_I = 68;     // C7 /0
let K_MOV8_RM_I = 69;    // C6 /0
let K_MOV16_R_RM = 70;   // 66 8B
let K_MOV16_RM_R = 71;   // 66 89
let K_ALU_A_I = 72;      // 05 0D 15 1D 25 2D 35 3D: eAX with a 32-bit immediate
let K_ALU8_A_I = 73;     // 04 0C 14 1C 24 2C 34 3C: AL with an 8-bit immediate
let K_TEST_A_I = 74;     // A9
let K_TEST8_A_I = 75;    // A8
let K_RDTSC = 76;        // 0F 31
let K_MOVS = 77;         // A5: MOVSD without REP
let K_MOVSW = 78;        // 66 A5
let K_MOVSB = 79;        // A4
let K_LODSB = 80;        // AC
let K_SCASB = 81;        // AE
let K_STOSB = 82;        // AA
let K_STOS = 83;         // AB: STOSD
// A flag-setting instruction and the conditional jump after it, as one executor (E053). The
// entry is the first instruction's; imm is the jump's offset, bytes what jcc_fused keeps of
// its condition, and dc_next the address after the jump. A pair counts as two instructions,
// so it is run only when there is time for two; otherwise, and from the general path, the
// executor is told to run the first instruction by itself.
let K_CMP_RM_R_J = 84;   // CMP r/m, r and Jcc
let K_CMP_RM_I_J = 85;   // CMP r/m, imm and Jcc
let K_TEST_J = 86;       // TEST r/m, r and Jcc
let K_TEST8_I_J = 87;    // TEST r/m8, imm8 and Jcc
let K_TEST8_J = 88;      // TEST r/m8, r8 and Jcc
let K_DEC_J = 89;        // DEC of a register and Jcc
let K_DEC_RM_J = 90;     // DEC r/m and Jcc
let K_ALU8_RM_I_J = 91;  // 80 and Jcc
let K_AND_RM_I_J = 92;   // AND r/m, imm and Jcc
let K_SUB_RM_I_J = 93;   // SUB r/m, imm and Jcc
let K_ALU8_A_I_J = 94;   // 8-bit arithmetic on AL and Jcc
let K_TEST_I_J = 95;     // TEST r/m, imm32 and Jcc
let K_LAST = 95;         // the largest kind with an executor
// Kinds with no executor, which only the JIT's translator knows (E073): classify gives them
// when the JIT is on, and a run leaves them to the general path as it does K_NONE.
let K_J_MOV_A_M = 96;    // A1: MOV EAX, [address]
let K_J_MOV_M_A = 97;    // A3: MOV [address], EAX
let K_J_LEAVE = 98;      // C9
let K_J_PUSH_I = 99;     // 68 and 6A
let K_J_PUSH_RM = 100;   // FF /6
let K_J_XCHG_A = 101;    // 91 to 97
let K_J_XCHG = 102;      // 87, between registers
let K_J_BSWAP = 103;     // 0F C8 to 0F CF
let K_J_CDQ = 104;       // 99
let K_J_DF = 105;        // FC and FD
let K_J_ROT1 = 106;      // D1 /0 and /1, of a register
let K_J_MOVSX8 = 107;    // 0F BE
let K_J_MOVSX16 = 108;   // 0F BF
let K_J_MULDIV = 109;    // F7 /4 to /7
let K_J_CALL_RM = 110;   // FF /2: CALL through a register or memory
let K_J_JMP_RM = 111;    // FF /4: JMP through one
let K_J_CMOV = 112;      // 0F 40 to 0F 4F
let K_JLAST = 112;       // the largest kind the translator knows
// The first instruction of a block the JIT has translated (jit.goose). It is above K_LAST on
// purpose: the run finds it where it finds a kind with no executor, off the path every other
// instruction takes, and no executor has to know about blocks.
let K_BLOCK = 254;

// Byte k of the instruction, from its first eight.
inline fn raw8(raw: u64, k: u32) -> u32 { return (raw >> (k * 8) & 0xFF) as! u32; }
inline fn raw32(raw: u64, k: u32) -> u32 { return (raw >> (k * 8) & 0xFFFFFFFF) as! u32; }
inline fn sext8(v: u32) -> u32 { return ((v as! u8) as! i8) as! u32; }

// ---- What the x87 and SSE files need of this CPU (see fpu.goose's head) ----

fn ea(k: u32) -> u32 {
    let o = ea_off + k;
    if ins.asz32 { return o; }
    return o & 0xFFFF;
}

fn frd(k: u32, w: u8) -> u32 { return seg_read(ea_seg, ea(k), w); }
fn fwr(k: u32, w: u8, v: u32) { seg_write(ea_seg, ea(k), w, v); }
fn fp_env32() -> bool { return ins.osz == 32; }
fn fp_set_ax(v: u16) { set_r16(AX, v); }
// OF, SF and AF are cleared with it (E098: the real CPU).
fn fp_set_zpc(bits: u32) { cpu.flags = cpu.flags & 0xFFFFF72A | bits; }

fn fp_stop(code: i64) {
    cpu.ip = saved.ip;
    stop("unimplemented x87 opcode, with its ModRM byte", code);
}

// How many bytes the operand that begins with the ModRM byte at raw's byte i takes, with
// 32-bit addressing: that byte, a SIB byte, a displacement.
fn modrm_len(raw: u64, i: u32) -> u32 {
    let m = raw8(raw, i);
    let md = m >> 6;
    if md == 3 { return 1; }
    var n: u32 = 1;
    if m & 7 == 4 {
        n = 2;
        if md == 0 && raw8(raw, i + 1) & 7 == 5 { n = 6; }
    } else if m & 7 == 5 && md == 0 { n = 5; }
    if md == 1 { n += 1; } else if md == 2 { n += 4; }
    return n;
}

// The length of an instruction from its first eight bytes, or 0 for "not known": pl is the
// length of its prefixes and opcode byte, op that byte, osz the operand size. For 32-bit
// addressing only. An instruction that begins in a page's last fifteen bytes gets an entry
// in the decode cache when this says it ends in the page (E088), and so what is said here
// must never be less than what the general path fetches; 0 costs only the entry. Every byte
// looked at lies inside the length that comes back.
fn ins_len(op: u8, raw: u64, pl: u32, osz: u8) -> u32 {
    let iz: u32 = if osz == 16 { 2 } else { 4 };
    if op == 0x0F {
        let op2 = raw8(raw, pl);
        let l = pl + 1;
        if op2 >= 0x80 && op2 <= 0x8F { return l + iz; }
        if (op2 >= 0x40 && op2 <= 0x4F) || (op2 >= 0x90 && op2 <= 0x9F) { return l + modrm_len(raw, l); }
        match op2 {
            0xA3, 0xAB, 0xB3, 0xBB, 0xA5, 0xAD, 0xAF, 0xB0, 0xB1, 0xB6, 0xB7, 0xBC, 0xBD, 0xBE, 0xBF, 0xC0, 0xC1 => { return l + modrm_len(raw, l); },
            0xA4, 0xAC, 0xBA => { return l + modrm_len(raw, l) + 1; },
            0x00, 0x01, 0x02, 0x03, 0x1F, 0x20, 0x21, 0x22, 0x23, 0xC7 => { return l + modrm_len(raw, l); },
            0x06, 0x08, 0x09, 0x0B, 0x30, 0x31, 0x32, 0x34, 0x35, 0xA0, 0xA1, 0xA2, 0xA8, 0xA9,
            0xC8, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xCF => { return l; },
            _ => { return 0; },
        }
    }
    if op < 0x40 {
        if op & 7 < 4 { return pl + modrm_len(raw, pl); }
        if op & 7 == 4 { return pl + 1; }
        if op & 7 == 5 { return pl + iz; }
        return pl;
    }
    if op < 0x60 { return pl; }
    match op >> 4 {
        0x6 => {
            match op {
                0x68 => { return pl + iz; },
                0x69 => { return pl + modrm_len(raw, pl) + iz; },
                0x6A => { return pl + 1; },
                0x6B => { return pl + modrm_len(raw, pl) + 1; },
                _ => { return 0; },
            }
        },
        0x7 => { return pl + 1; },
        0x8 => {
            if op == 0x81 { return pl + modrm_len(raw, pl) + iz; }
            if op < 0x84 { return pl + modrm_len(raw, pl) + 1; }
            return pl + modrm_len(raw, pl);
        },
        0x9 => {
            if op == 0x9A { return 0; }
            return pl;
        },
        0xA => {
            if op < 0xA4 { return pl + 4; }
            if op == 0xA8 { return pl + 1; }
            if op == 0xA9 { return pl + iz; }
            return pl;
        },
        0xB => {
            if op < 0xB8 { return pl + 1; }
            return pl + iz;
        },
        0xC => {
            match op {
                0xC0, 0xC1, 0xC6 => { return pl + modrm_len(raw, pl) + 1; },
                0xC7 => { return pl + modrm_len(raw, pl) + iz; },
                0xC2 => { return pl + 2; },
                0xC4, 0xC5 => { return pl + modrm_len(raw, pl); },
                0xCA => { return pl + 2; },
                0xCD => { return pl + 1; },
                0xC3, 0xC9, 0xCB, 0xCC, 0xCF => { return pl; },
                _ => { return 0; },
            }
        },
        0xD => {
            if op < 0xD4 || op >= 0xD8 { return pl + modrm_len(raw, pl); }
            return 0;
        },
        0xE => {
            if op == 0xE8 || op == 0xE9 { return pl + iz; }
            if op == 0xEB || op < 0xE8 { return pl + 1; }
            if op >= 0xEC { return pl; }
            return 0;
        },
        _ => {
            match op {
                0xF6 => { return pl + modrm_len(raw, pl) + (if raw8(raw, pl) >> 3 & 7 < 2 { 1 } else { 0 }); },
                0xF7 => { return pl + modrm_len(raw, pl) + (if raw8(raw, pl) >> 3 & 7 < 2 { iz } else { 0 }); },
                0xF4, 0xF5, 0xF8, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD => { return pl; },
                0xFE, 0xFF => { return pl + modrm_len(raw, pl); },
                _ => { return 0; },
            }
        },
    }
}

// ADC and SBB read the carry: they keep the general arithmetic executor.
inline fn carries(aop: u8) -> bool { return aop == 2 || aop == 3; }

// The kind for 83 and 81, whose operation is the reg field of the operand.
fn imm_kind(mm: u32) -> u8 {
    let aop = (mm >> 4 & 7) as! u8;
    if carries(aop) { return K_ALU_RM_I; }
    return K_ALU_RM_I_OP + aop;
}

// A condition code as a kind, and as what that kind keeps in disp: for the mask kind, the flags
// to test, with bit 31 set when the jump is taken on none of them being set; for the other two,
// 1 when the sense is the opposite one.
fn jcc_kind(cc: u8) -> u8 {
    if cc >> 1 <= 5 { return K_JCC_MASK; }
    if cc >> 1 == 6 { return K_JCC_L; }
    return K_JCC_LE;
}

// A condition code as a fused pair keeps it: the flags to test, with bit 31 set when the jump
// is taken on none of them being set. Bit 1, which EFLAGS does not use, stands for "SF and OF
// differ"; jcc_fused puts that there before it tests.
fn fuse_data(cc: u8) -> u32 {
    let neg: u32 = cc & 1;
    if cc >> 1 == 6 { return 2 | neg << 31; }
    if cc >> 1 == 7 { return 2 | ZF | neg << 31; }
    return jcc_data(cc);
}

// The pair's kind for an instruction that a conditional jump can be fused to; K_NONE for
// any other.
fn fuse_kind(kind: u8) -> u8 {
    if kind == K_ALU_RM_R_OP + 7 { return K_CMP_RM_R_J; }
    if kind == K_ALU_RM_I_OP + 7 { return K_CMP_RM_I_J; }
    if kind == K_TEST { return K_TEST_J; }
    if kind == K_TEST8_I { return K_TEST8_I_J; }
    if kind == K_TEST8 { return K_TEST8_J; }
    if kind == K_DEC { return K_DEC_J; }
    if kind == K_DEC_RM { return K_DEC_RM_J; }
    if kind == K_ALU8_RM_I { return K_ALU8_RM_I_J; }
    if kind == K_ALU_RM_I_OP + 4 { return K_AND_RM_I_J; }
    if kind == K_ALU_RM_I_OP + 5 { return K_SUB_RM_I_J; }
    if kind == K_ALU8_A_I { return K_ALU8_A_I_J; }
    if kind == K_TEST_I { return K_TEST_I_J; }
    return K_NONE;
}

inline fn jcc_fused(d: u32) -> bool {
    let f = cpu.flags;
    let g = f & 0xFFFFFFFD | ((f ^ f >> 4) >> 6 & 2);
    return (g & d & 0xFFF != 0) != (d >> 31 != 0);
}

fn jcc_data(cc: u8) -> u32 {
    let neg: u32 = cc & 1;
    match cc >> 1 {
        0 => { return OF | neg << 31; },
        1 => { return CF | neg << 31; },
        2 => { return ZF | neg << 31; },
        3 => { return CF | ZF | neg << 31; },
        4 => { return SF | neg << 31; },
        5 => { return PF | neg << 31; },
        _ => { return neg; },
    }
}

// Decides whether the instruction in this entry has a short executor. Called the second time
// the instruction is met: by then the first, general, execution has recorded its operand.
fn classify(slot: i64, raw: u64) {
    var kind: u8 = K_NONE;
    var len: u32 = 0;
    var imm: u32 = 0;
    var cc: u32 = 0;
    let op = ins.op;
    let mm = dc[slot].m;
    let has_m = mm & 3 == 1;
    let pl: u32 = ins.plen;                  // the prefixes and the opcode byte
    let after_m = pl + (mm >> 10 & 15);      // where the operand's bytes end, for a one-byte opcode
    // A short executor works with 32-bit operands and addresses. The prefixes it can do without:
    // a segment override, which is resolved here into the entry; 66 on the two MOVs, which have
    // 16-bit executors; and F3 on RET and on NOP, where it changes nothing ("rep ret", PAUSE).
    let plain = !ins.lock && ins.rep == 0 && ins.asz32;
    let p32 = plain && ins.osz == 32 && (pl == 1 || (pl == 2 && ins.seg >= 0));
    let p16 = plain && ins.osz == 16 && pl == 2 && ins.seg < 0;
    let prep = !ins.lock && ins.rep == 2 && ins.asz32 && ins.osz == 32 && ins.seg < 0 && pl == 2;
    if p32 && has_m {
        len = after_m;
        if op == 0x8B { kind = if mm & 0x0C == 0x0C { K_MOV_R_R } else { K_MOV_R_RM }; }
        else if op == 0x89 { kind = if mm & 0x0C == 0x0C { K_MOV_R_R_89 } else { K_MOV_RM_R }; }
        else if op < 0x40 && op & 7 == 1 { kind = if carries(op >> 3) { K_ALU_RM_R } else { K_ALU_RM_R_OP + (op >> 3) }; }
        else if op < 0x40 && op & 7 == 3 { kind = if carries(op >> 3) { K_ALU_R_RM } else { K_ALU_R_RM_OP + (op >> 3) }; }
        else if op == 0x83 { kind = imm_kind(mm); imm = sext8(raw8(raw, after_m)); len = after_m + 1; }
        else if op == 0x81 && after_m <= 4 { kind = imm_kind(mm); imm = raw32(raw, after_m); len = after_m + 4; }
        else if op == 0x8D && mm & 0x0C != 0x0C { kind = K_LEA; }
        else if op == 0x85 { kind = K_TEST; }
        else if op == 0xC1 || op == 0xD1 {
            kind = K_SHIFT_I;
            if op == 0xC1 { imm = raw8(raw, after_m); len = after_m + 1; } else { imm = 1; }
            let which = mm >> 4 & 7;
            if which >= 4 && imm & 0x1F != 0 {
                // A shift by a count that does something: its own executor, with the count.
                imm = imm & 0x1F;
                kind = if which == 5 { K_SHR_I } else if which == 7 { K_SAR_I } else { K_SHL_I };
            } else if op == 0xD1 {
                // A rotate by one: the general path, or the JIT's own kind.
                kind = if jit_on && which < 2 && mm & 0x0C == 0x0C { K_J_ROT1 } else { K_NONE };
            }
        }
        else if op == 0xD3 { kind = K_SHIFT_CL; }
        else if op == 0x8A { kind = K_MOV8_R_RM; }
        else if op == 0x88 { kind = K_MOV8_RM_R; }
        else if op < 0x40 && op & 7 == 0 { kind = K_ALU8_RM_R; }
        else if op < 0x40 && op & 7 == 2 { kind = K_ALU8_R_RM; }
        else if op == 0x80 { kind = K_ALU8_RM_I; imm = raw8(raw, after_m); len = after_m + 1; }
        else if op == 0x84 { kind = K_TEST8; }
        else if op == 0xF6 && mm >> 4 & 7 < 2 { kind = K_TEST8_I; imm = raw8(raw, after_m); len = after_m + 1; }
        else if op == 0xF7 && mm >> 4 & 7 < 2 && after_m <= 4 { kind = K_TEST_I; imm = raw32(raw, after_m); len = after_m + 4; }
        else if op == 0xF7 && mm >> 4 & 7 == 2 { kind = K_NOT; }
        else if op == 0xF7 && mm >> 4 & 7 == 3 { kind = K_NEG; }
        else if op == 0xF7 && mm >> 4 & 7 >= 4 && jit_on { kind = K_J_MULDIV; }
        else if op == 0xFF && mm >> 4 & 7 == 6 && jit_on { kind = K_J_PUSH_RM; }
        else if op == 0xFF && mm >> 4 & 7 == 2 && jit_on { kind = K_J_CALL_RM; }
        else if op == 0xFF && mm >> 4 & 7 == 4 && jit_on { kind = K_J_JMP_RM; }
        else if op == 0x87 && mm & 0x0C == 0x0C && jit_on { kind = K_J_XCHG; }
        else if op == 0xFF && mm >> 4 & 7 == 0 { kind = K_INC_RM; }
        else if op == 0xFF && mm >> 4 & 7 == 1 { kind = K_DEC_RM; }
        else if op == 0xC7 && mm >> 4 & 7 == 0 && after_m <= 4 { kind = K_MOV_RM_I; imm = raw32(raw, after_m); len = after_m + 4; }
        else if op == 0xC6 && mm >> 4 & 7 == 0 { kind = K_MOV8_RM_I; imm = raw8(raw, after_m); len = after_m + 1; }
        else if op == 0x0F {
            // A two-byte opcode: the operand's bytes start one later, and its recorded length
            // was counted from after the second opcode byte.
            let op2 = raw8(raw, pl);
            len = after_m + 1;
            if op2 == 0xB6 { kind = K_MOVZX8; } else if op2 == 0xB7 { kind = K_MOVZX16; }
            else if op2 == 0xAF { kind = K_IMUL; }
            else if op2 >= 0x90 && op2 <= 0x9F { kind = K_SETCC; imm = op2 & 15; }
            else if op2 >= 0x40 && op2 <= 0x4F && i686 && jit_on { kind = K_J_CMOV; imm = op2 & 15; }
            else if op2 == 0xBE && jit_on { kind = K_J_MOVSX8; }
            else if op2 == 0xBF && jit_on { kind = K_J_MOVSX16; }
        }
    } else if p16 && has_m {
        len = after_m;
        if op == 0x8B { kind = K_MOV16_R_RM; }
        else if op == 0x89 { kind = K_MOV16_RM_R; }
    } else if p32 && mm == 0 {
        if op >= 0x70 && op <= 0x7F { kind = jcc_kind(op & 15); cc = jcc_data(op & 15); imm = sext8(raw8(raw, pl)); len = pl + 1; }
        else if op == 0xEB { kind = K_JMP; imm = sext8(raw8(raw, pl)); len = pl + 1; }
        else if op == 0xE9 { kind = K_JMP; imm = raw32(raw, pl); len = pl + 4; }
        else if op == 0xE8 { kind = K_CALL; imm = raw32(raw, pl); len = pl + 4; }
        else if op == 0xC3 { kind = K_RET; len = pl; }
        else if op == 0x90 { kind = K_NOP; len = pl; }
        else if op >= 0x50 && op <= 0x57 { kind = K_PUSH; len = pl; }
        else if op >= 0x58 && op <= 0x5F { kind = K_POP; len = pl; }
        else if op >= 0x40 && op <= 0x47 { kind = K_INC; len = pl; }
        else if op >= 0x48 && op <= 0x4F { kind = K_DEC; len = pl; }
        else if op >= 0xB8 && op <= 0xBF { kind = K_MOV_R_I; imm = raw32(raw, pl); len = pl + 4; }
        else if op < 0x40 && op & 7 == 5 { kind = K_ALU_A_I; imm = raw32(raw, pl); len = pl + 4; }
        else if op < 0x40 && op & 7 == 4 { kind = K_ALU8_A_I; imm = raw8(raw, pl); len = pl + 1; }
        else if op == 0xA9 { kind = K_TEST_A_I; imm = raw32(raw, pl); len = pl + 4; }
        else if op == 0xA8 { kind = K_TEST8_A_I; imm = raw8(raw, pl); len = pl + 1; }
        // The string instructions without REP: loops are written with them (E035). A segment
        // override, resolved below as for a memory operand, is the source's segment.
        else if op == 0xA5 { kind = K_MOVS; len = pl; }
        else if op == 0xA4 { kind = K_MOVSB; len = pl; }
        else if op == 0xAC { kind = K_LODSB; len = pl; }
        else if op == 0xAE { kind = K_SCASB; len = pl; }
        else if op == 0xAA { kind = K_STOSB; len = pl; }
        else if op == 0xAB { kind = K_STOS; len = pl; }
        else if op == 0x0F {
            let op2 = raw8(raw, pl);
            if op2 >= 0x80 && op2 <= 0x8F { kind = jcc_kind((op2 & 15) as! u8); cc = jcc_data((op2 & 15) as! u8); imm = raw32(raw, pl + 1); len = pl + 5; }
            else if op2 == 0x31 && i686 { kind = K_RDTSC; len = pl + 1; }
            else if op2 >= 0xC8 && op2 <= 0xCF && i686 && jit_on { kind = K_J_BSWAP; imm = op2 & 7; len = pl + 1; }
        }
        else if jit_on {
            if op == 0xA1 { kind = K_J_MOV_A_M; imm = raw32(raw, pl); len = pl + 4; }
            else if op == 0xA3 { kind = K_J_MOV_M_A; imm = raw32(raw, pl); len = pl + 4; }
            else if op == 0xC9 { kind = K_J_LEAVE; len = pl; }
            else if op == 0x68 { kind = K_J_PUSH_I; imm = raw32(raw, pl); len = pl + 4; }
            else if op == 0x6A { kind = K_J_PUSH_I; imm = sext8(raw8(raw, pl)); len = pl + 1; }
            else if op >= 0x91 && op <= 0x97 { kind = K_J_XCHG_A; len = pl; }
            else if op == 0x99 { kind = K_J_CDQ; len = pl; }
            else if op == 0xFC || op == 0xFD { kind = K_J_DF; imm = op & 1; len = pl; }
        }
    } else if p16 && mm == 0 {
        if op == 0xA5 { kind = K_MOVSW; len = pl; }
    } else if prep && mm == 0 {
        if op == 0xC3 { kind = K_RET; len = pl; }
        else if op == 0x90 { kind = K_NOP; len = pl; }
    }
    var jl: u32 = 0;                         // the length of a conditional jump fused to this one
    var fd: u64 = 0;                         // its condition, and its offset in the upper half
    if fuse_kind(kind) != K_NONE && len <= 8 {
        // Is the next instruction a conditional jump with no prefix? Its bytes are in this
        // page when the entry begins at least sixteen bytes before the page's end; nearer
        // the end than that, the pair is made only if the jump ends in the page too.
        let r2 = code64(dc[slot].tag + len);
        let b0 = raw8(r2, 0);
        let b1 = raw8(r2, 1);
        var jo: u64 = 0;
        if b0 >= 0x70 && b0 <= 0x7F { jl = 2; fd = fuse_data((b0 & 15) as! u8); jo = sext8(b1); }
        else if b0 == 0x0F && b1 >= 0x80 && b1 <= 0x8F { jl = 6; fd = fuse_data((b1 & 15) as! u8); jo = raw32(r2, 2); }
        if (dc[slot].tag & 0xFFF) + len + jl > 0x1000 { jl = 0; }
        if jl != 0 { kind = fuse_kind(kind); fd |= jo << 32; }
    }
    if kind != K_NONE && len >= 1 && len <= 8 && (dc[slot].tag & 0xFFF) + len <= 0x1000 {
        // The segment of the memory operand, resolved now: an override if there is one, else
        // SS for an address based on ESP or EBP, else DS.
        var sg: u32 = DS;
        if ins.seg >= 0 { sg = ins.seg as! u32; } else if mm & M_SS != 0 { sg = SS; }
        // The bytes this entry depends on now run to the end of the instruction, immediate
        // included; record them as they are now, which is where imm was read from.
        dc[slot].bytes = raw;
        dc[slot].imm = imm;
        if kind == K_JCC || (kind >= K_JCC_MASK && kind <= K_JCC_LE) { dc[slot].disp = cc; }
        dc[slot].m = mm | (len - 1) << 26 | sg << 29;
        dc_next[slot] = dc[slot].tag + len + jl;
        dc[slot].mask = byte_mask(len);
        if jl != 0 { dc[slot].bytes = fd; }
        dc[slot].pre.kind = kind;
        if jit_on && slot >= DC_HALF { jit_reclaim(slot); }
    } else {
        dc[slot].pre.kind = K_NONE;
    }
}

// The 32-bit operand of a short instruction: a register, or memory at the address the entry
// describes. short_ea must have run first for the memory case.
// The effective address of a short instruction's memory operand. As ea_from, for the one case
// there is here: 32-bit addressing and no segment override, so nothing of the decode state is
// consulted.
inline fn ea_short(mm: u32, disp: u32) {
    var off = disp;
    let base = mm >> 14 & 15;
    if base != 0 { off += cpu.regs[base - 1]; }
    let index = mm >> 18 & 15;
    if index != 0 { off += cpu.regs[index - 1] << (mm >> 22 & 3); }
    ea_off = off;
    let sg: i64 = mm >> 29;               // resolved by classify
    ea_seg = sg;
}

inline fn short_ea(mm: u32, slot: i64) {
    if mm & 0x0C != 0x0C { ea_short(mm, dc[slot].disp); }
}

inline fn short_read(mm: u32) -> u32 {
    if mm & 0x0C == 0x0C { return cpu.regs[mm >> 7 & 7]; }
    return seg_read(ea_seg, ea_off, 32);
}

inline fn short_write(mm: u32, v: u32) {
    if mm & 0x0C == 0x0C { cpu.regs[mm >> 7 & 7] = v; }
    else { seg_write(ea_seg, ea_off, 32, v); }
}

// Stores the result of an instruction that has set the flags already. A store to memory can
// fault, and a faulting instruction leaves the flags as it found them, which nothing else puts
// back for a short executor (E049): so the old flags, f0, are in place while the store is made.
inline fn short_write_fl(mm: u32, v: u32, f0: u32) {
    if mm & 0x0C == 0x0C { cpu.regs[mm >> 7 & 7] = v; return; }
    let f1 = cpu.flags;
    cpu.flags = f0;
    seg_write(ea_seg, ea_off, 32, v);
    cpu.flags = f1;
}

inline fn short_write8_fl(mm: u32, v: u32, f0: u32) {
    if mm & 0x0C == 0x0C { set_r8((mm >> 7 & 7) as! u8, v as! u8); return; }
    let f1 = cpu.flags;
    cpu.flags = f0;
    seg_write(ea_seg, ea_off, 8, v);
    cpu.flags = f1;
}

// Where in RAM the 32-bit memory operand of the instruction is, if writing it can take
// seg_write's short path: the same tests, and the write TLB, which for a page it holds says
// that the page may be read as well. FFFFFFFFh when it cannot (and then nothing is known).
// An instruction that reads the operand, changes it and writes it back asks once instead of
// going through seg_read and then seg_write (E038). short_ea must have run first.
inline fn rmw_place() -> u32 {
    let s = ea_seg;
    let a = cpu.base[s] + ea_off;
    if ea_off < seg_top[s] && (a & 0xFFF) + 4 <= 0x1000 {
        let page = a >> 12;
        let i = page & (TLB_HALF - 1) | (if cpu.cpl == 3 { TLB_HALF } else { 0 });
        if tlb_wtag[i] == page { return tlb_wphys[i] | a & 0xFFF; }
    }
    return 0xFFFFFFFF;
}

// op the 32-bit operand with b, in a register or in memory, and store the result. The flags
// are set before the store only on the path where the store cannot fault.
inline fn short_alu_rm(mm: u32, aop: u8, b: u32) {
    if mm & 0x0C == 0x0C {
        let k = mm >> 7 & 7;
        cpu.regs[k] = alu(aop, cpu.regs[k], b, 32);
        return;
    }
    let q: i64 = rmw_place();
    if q < RAM_SIZE - 3 {
        let b0: u32 = ram[q]; let b1: u32 = ram[q + 1]; let b2: u32 = ram[q + 2]; let b3: u32 = ram[q + 3];
        let r = alu(aop, b0 | b1 << 8 | b2 << 16 | b3 << 24, b, 32);
        ram[q] = r as! u8; ram[q + 1] = (r >> 8) as! u8; ram[q + 2] = (r >> 16) as! u8; ram[q + 3] = (r >> 24) as! u8;
    } else {
        let f0 = cpu.flags;
        let r = alu(aop, seg_read(ea_seg, ea_off, 32), b, 32);
        let f1 = cpu.flags;
        cpu.flags = f0;
        seg_write(ea_seg, ea_off, 32, r);
        cpu.flags = f1;
    }
}

// INC (up) or DEC of the 32-bit operand, the same way.
inline fn short_step_rm(mm: u32, up: bool) {
    if mm & 0x0C == 0x0C {
        let k = mm >> 7 & 7;
        cpu.regs[k] = if up { inc(cpu.regs[k], 32) } else { dec(cpu.regs[k], 32) };
        return;
    }
    let q: i64 = rmw_place();
    if q < RAM_SIZE - 3 {
        let b0: u32 = ram[q]; let b1: u32 = ram[q + 1]; let b2: u32 = ram[q + 2]; let b3: u32 = ram[q + 3];
        let v = b0 | b1 << 8 | b2 << 16 | b3 << 24;
        let r = if up { inc(v, 32) } else { dec(v, 32) };
        ram[q] = r as! u8; ram[q + 1] = (r >> 8) as! u8; ram[q + 2] = (r >> 16) as! u8; ram[q + 3] = (r >> 24) as! u8;
    } else {
        let v = seg_read(ea_seg, ea_off, 32);
        let f0 = cpu.flags;
        let r = if up { inc(v, 32) } else { dec(v, 32) };
        let f1 = cpu.flags;
        cpu.flags = f0;
        seg_write(ea_seg, ea_off, 32, r);
        cpu.flags = f1;
    }
}

inline fn short_read8(mm: u32) -> u32 {
    if mm & 0x0C == 0x0C { return r8((mm >> 7 & 7) as! u8); }
    return seg_read(ea_seg, ea_off, 8);
}

inline fn short_write8(mm: u32, v: u32) {
    if mm & 0x0C == 0x0C { set_r8((mm >> 7 & 7) as! u8, v as! u8); }
    else { seg_write(ea_seg, ea_off, 8, v); }
}

// ip0 is the instruction pointer at the instruction's first byte.
inline fn short_read16(mm: u32) -> u32 {
    if mm & 0x0C == 0x0C { return cpu.regs[mm >> 7 & 7] & 0xFFFF; }
    return seg_read(ea_seg, ea_off, 16);
}

inline fn short_write16(mm: u32, v: u32) {
    if mm & 0x0C == 0x0C { let k = mm >> 7 & 7; cpu.regs[k] = cpu.regs[k] & 0xFFFF0000 | v & 0xFFFF; }
    else { seg_write(ea_seg, ea_off, 16, v); }
}

// The second half of a pair, once the first instruction has set the flags: the conditional
// jump, if there is time for two instructions; if not, nothing, and the next instruction is
// the jump itself. Gives back the next address, as run_short does, with PAIR_RAN set above
// it when both instructions were run. The run counts one instruction for each executor; it
// finds that bit where it tests the address anyway, as an address that is not on the page,
// and counts the second there, so that an executor that is not a pair pays nothing for there
// being pairs. nx is the address after the jump. The store of cpu.ip on the taken path is
// what keeps the jump a branch for the host (see run_short).
let PAIR_RAN = 0x100000000;

inline fn pair_end(slot: i64, mm: u32, nx: u32, base: u32, room: i64) -> u64 {
    if room < 2 { return dc[slot].tag + (mm >> 26 & 7) + 1; }
    let b = dc[slot].bytes;
    var to = nx;
    if jcc_fused(b as! u32) { to += (b >> 32) as! u32; cpu.ip = to - base; }
    let both: u64 = to;
    return both | PAIR_RAN;
}

// Returns the linear address at which the next instruction begins; base is the code segment's.
// The caller keeps that in a local for the whole run, so that finding the next instruction does
// not wait on a load of cpu.ip that this one has just stored (E026), nor on this instruction's
// entry (E028: the address comes from dc_next). cpu.ip is not kept up here, nor by the run:
// exec_short notes in saved.ip where each instruction begins and sets cpu.ip from it when the
// run ends or faults (E049).
//
// The conditional jumps store cpu.ip when they are taken all the same, and that store is not
// to be tidied away. With nothing but `nx += imm` on the taken path the compiler makes a
// conditional select of it; the next instruction's address is then data that waits for the
// flags, where a branch is predicted and the host runs ahead. Without the store the Linux
// boot takes 14% more cycles (E049; E031 looked for this and could not see it, because the
// store was there).
inline fn run_short(kind: u8, slot: i64, base: u32, room: i64) -> u64 {
    let mm = dc[slot].m;
    let imm = dc[slot].imm;
    let reg = mm >> 4 & 7;
    var nx = dc_next[slot];
    match kind {
        1 => { ea_short(mm, dc[slot].disp); cpu.regs[reg] = seg_read(ea_seg, ea_off, 32); },
        2 => { ea_short(mm, dc[slot].disp); seg_write(ea_seg, ea_off, 32, cpu.regs[reg]); },
        3 => {
            let aop = dc[slot].pre.op >> 3;
            short_ea(mm, slot);
            let f0 = cpu.flags;
            let r = alu(aop, short_read(mm), cpu.regs[reg], 32);
            if aop != 7 { short_write_fl(mm, r, f0); }
        },
        4 => {
            let aop = dc[slot].pre.op >> 3;
            short_ea(mm, slot);
            let r = alu(aop, cpu.regs[reg], short_read(mm), 32);
            if aop != 7 { cpu.regs[reg] = r; }
        },
        5 => {
            let aop = reg as! u8;
            short_ea(mm, slot);
            let f0 = cpu.flags;
            let r = alu(aop, short_read(mm), imm, 32);
            if aop != 7 { short_write_fl(mm, r, f0); }
        },
        6 => { ea_short(mm, dc[slot].disp); cpu.regs[reg] = ea_off; },
        7 => { short_ea(mm, slot); alu(4, short_read(mm), cpu.regs[reg], 32); },
        8 => { short_ea(mm, slot); let f0 = cpu.flags; short_write_fl(mm, shift(reg as! u8, short_read(mm), imm as! u8, 32), f0); },
        9 => {
            // By CL. The three shifts by a count from 1 to 31 in one step, as for a constant
            // count; a count of zero (which changes nothing) and the rotates as before.
            short_ea(mm, slot);
            let n: u32 = r8(1) & 31;
            let f0 = cpu.flags;
            if n == 0 || reg < 4 { short_write_fl(mm, shift(reg as! u8, short_read(mm), r8(1), 32), f0); }
            else if reg == 5 { short_write_fl(mm, shr32(short_read(mm), n), f0); }
            else if reg == 7 { short_write_fl(mm, sar32(short_read(mm), n), f0); }
            else { short_write_fl(mm, shl32(short_read(mm), n), f0); }
        },
        10 => { if cond(dc[slot].disp as! u8) { nx += imm; cpu.ip = nx - base; } },
        11 => { nx += imm; },
        12 => { push_w(nx - base, 32); nx += imm; },
        13 => { let to = pop_w(32); nx = to + base; },
        14 => {},
        15 => { push_w(cpu.regs[dc[slot].pre.op & 7], 32); },
        16 => { let v = pop_w(32); cpu.regs[dc[slot].pre.op & 7] = v; },
        17 => { cpu.regs[dc[slot].pre.op & 7] = inc(cpu.regs[dc[slot].pre.op & 7], 32); },
        18 => { cpu.regs[dc[slot].pre.op & 7] = dec(cpu.regs[dc[slot].pre.op & 7], 32); },
        19 => { cpu.regs[dc[slot].pre.op & 7] = imm; },
        20 => {
            if mm & 0x0C == 0x0C { cpu.regs[reg] = r8((mm >> 7 & 7) as! u8); }
            else { ea_short(mm, dc[slot].disp); cpu.regs[reg] = seg_read(ea_seg, ea_off, 8); }
        },
        21 => {
            if mm & 0x0C == 0x0C { cpu.regs[reg] = cpu.regs[mm >> 7 & 7] & 0xFFFF; }
            else { ea_short(mm, dc[slot].disp); cpu.regs[reg] = seg_read(ea_seg, ea_off, 16); }
        },
        22 => { short_ea(mm, slot); set_r8(reg as! u8, short_read8(mm) as! u8); },
        23 => { short_ea(mm, slot); let v: u32 = r8(reg as! u8); short_write8(mm, v); },
        24 => {
            let aop = dc[slot].pre.op >> 3;
            short_ea(mm, slot);
            let b: u32 = r8(reg as! u8);
            let f0 = cpu.flags;
            let r = alu(aop, short_read8(mm), b, 8);
            if aop != 7 { short_write8_fl(mm, r, f0); }
        },
        25 => {
            let aop = dc[slot].pre.op >> 3;
            short_ea(mm, slot);
            let a: u32 = r8(reg as! u8);
            let r = alu(aop, a, short_read8(mm), 8);
            if aop != 7 { set_r8(reg as! u8, r as! u8); }
        },
        26 => {
            let aop = reg as! u8;
            short_ea(mm, slot);
            let f0 = cpu.flags;
            let r = alu(aop, short_read8(mm), imm, 8);
            if aop != 7 { short_write8_fl(mm, r, f0); }
        },
        27 => { short_ea(mm, slot); let b: u32 = r8(reg as! u8); alu(4, short_read8(mm), b, 8); },
        28 => { short_ea(mm, slot); alu(4, short_read8(mm), imm, 8); },
        29 => { short_ea(mm, slot); alu(4, short_read(mm), imm, 32); },
        30 => {
            short_ea(mm, slot);
            let p = imul(cpu.regs[reg], short_read(mm), 32);
            cpu.regs[reg] = p as! u32;
        },
        31 => { short_ea(mm, slot); short_write8(mm, if cond(imm as! u8) { 1 } else { 0 }); },
        32 => { let d = dc[slot].disp; if (cpu.flags & d & 0xFFF != 0) != (d >> 31 != 0) { nx += imm; cpu.ip = nx - base; } },
        33 => { let lt = (cpu.flags >> 7 ^ cpu.flags >> 11) & 1; if lt != dc[slot].disp { nx += imm; cpu.ip = nx - base; } },
        34 => { let le = ((cpu.flags >> 7 ^ cpu.flags >> 11) | cpu.flags >> 6) & 1; if le != dc[slot].disp { nx += imm; cpu.ip = nx - base; } },
        35 => { short_ea(mm, slot); let f0 = cpu.flags; short_write_fl(mm, shl32(short_read(mm), imm), f0); },
        36 => { short_ea(mm, slot); let f0 = cpu.flags; short_write_fl(mm, shr32(short_read(mm), imm), f0); },
        37 => { short_ea(mm, slot); let f0 = cpu.flags; short_write_fl(mm, sar32(short_read(mm), imm), f0); },
        38 => { cpu.regs[reg] = cpu.regs[mm >> 7 & 7]; },
        39 => { cpu.regs[mm >> 7 & 7] = cpu.regs[reg]; },
        // The numbers with no executor are named, so that the kinds are one unbroken range and
        // the compiler makes one jump table of them, not two with a test between.
        42, 43, 50, 51, 58, 59 => {},
        40 => { short_ea(mm, slot); short_alu_rm(mm, 0, cpu.regs[reg]); },
        41 => { short_ea(mm, slot); short_alu_rm(mm, 1, cpu.regs[reg]); },
        44 => { short_ea(mm, slot); short_alu_rm(mm, 4, cpu.regs[reg]); },
        45 => { short_ea(mm, slot); short_alu_rm(mm, 5, cpu.regs[reg]); },
        46 => { short_ea(mm, slot); short_alu_rm(mm, 6, cpu.regs[reg]); },
        47 => { short_ea(mm, slot); let r = alu(7, short_read(mm), cpu.regs[reg], 32); },
        48 => { short_ea(mm, slot); let r = alu(0, cpu.regs[reg], short_read(mm), 32); cpu.regs[reg] = r; },
        49 => { short_ea(mm, slot); let r = alu(1, cpu.regs[reg], short_read(mm), 32); cpu.regs[reg] = r; },
        52 => { short_ea(mm, slot); let r = alu(4, cpu.regs[reg], short_read(mm), 32); cpu.regs[reg] = r; },
        53 => { short_ea(mm, slot); let r = alu(5, cpu.regs[reg], short_read(mm), 32); cpu.regs[reg] = r; },
        54 => { short_ea(mm, slot); let r = alu(6, cpu.regs[reg], short_read(mm), 32); cpu.regs[reg] = r; },
        55 => { short_ea(mm, slot); let r = alu(7, cpu.regs[reg], short_read(mm), 32); },
        56 => { short_ea(mm, slot); short_alu_rm(mm, 0, imm); },
        57 => { short_ea(mm, slot); short_alu_rm(mm, 1, imm); },
        60 => { short_ea(mm, slot); short_alu_rm(mm, 4, imm); },
        61 => { short_ea(mm, slot); short_alu_rm(mm, 5, imm); },
        62 => { short_ea(mm, slot); short_alu_rm(mm, 6, imm); },
        63 => { short_ea(mm, slot); let r = alu(7, short_read(mm), imm, 32); },
        64 => { short_ea(mm, slot); short_step_rm(mm, true); },
        65 => { short_ea(mm, slot); short_step_rm(mm, false); },
        66 => { short_ea(mm, slot); short_write(mm, ~short_read(mm)); },
        67 => { short_ea(mm, slot); let f0 = cpu.flags; short_write_fl(mm, alu(5, 0, short_read(mm), 32), f0); },
        68 => { short_ea(mm, slot); short_write(mm, imm); },
        69 => { short_ea(mm, slot); short_write8(mm, imm); },
        70 => { short_ea(mm, slot); cpu.regs[reg] = cpu.regs[reg] & 0xFFFF0000 | short_read16(mm); },
        71 => { short_ea(mm, slot); short_write16(mm, cpu.regs[reg]); },
        72 => { let aop = dc[slot].pre.op >> 3; let r = alu(aop, cpu.regs[0], imm, 32); if aop != 7 { cpu.regs[0] = r; } },
        73 => { let aop = dc[slot].pre.op >> 3; let a: u32 = r8(0); let r = alu(aop, a, imm, 8); if aop != 7 { set_r8(0, r as! u8); } },
        74 => { alu(4, cpu.regs[0], imm, 32); },
        75 => { let a: u32 = r8(0); alu(4, a, imm, 8); },
        76 => { let t = vtime + run_from - run_left; cpu.regs[0] = t as! u32; cpu.regs[2] = (t >> 32) as! u32; },
        // The string instructions without REP. Each reads before it writes memory and moves
        // ESI and EDI last, so a fault leaves the registers as they were. The source's segment
        // is the entry's (DS, or an override); the destination's is always ES.
        77 => {
            let v = seg_read(mm >> 29, cpu.regs[SI], 32);
            seg_write(ES, cpu.regs[DI], 32, v);
            let d: u32 = if flag(DF) { 0xFFFFFFFC } else { 4 };
            cpu.regs[SI] += d; cpu.regs[DI] += d;
        },
        78 => {
            let v = seg_read(mm >> 29, cpu.regs[SI], 16);
            seg_write(ES, cpu.regs[DI], 16, v);
            let d: u32 = if flag(DF) { 0xFFFFFFFE } else { 2 };
            cpu.regs[SI] += d; cpu.regs[DI] += d;
        },
        79 => {
            let v = seg_read(mm >> 29, cpu.regs[SI], 8);
            seg_write(ES, cpu.regs[DI], 8, v);
            let d: u32 = if flag(DF) { 0xFFFFFFFF } else { 1 };
            cpu.regs[SI] += d; cpu.regs[DI] += d;
        },
        80 => {
            let v = seg_read(mm >> 29, cpu.regs[SI], 8);
            set_r8(0, v as! u8);
            cpu.regs[SI] += if flag(DF) { 0xFFFFFFFF } else { 1 };
        },
        81 => {
            let b = seg_read(ES, cpu.regs[DI], 8);
            let a: u32 = r8(0);
            alu(7, a, b, 8);
            cpu.regs[DI] += if flag(DF) { 0xFFFFFFFF } else { 1 };
        },
        82 => {
            let v: u32 = r8(0);
            seg_write(ES, cpu.regs[DI], 8, v);
            cpu.regs[DI] += if flag(DF) { 0xFFFFFFFF } else { 1 };
        },
        83 => {
            seg_write(ES, cpu.regs[DI], 32, cpu.regs[0]);
            cpu.regs[DI] += if flag(DF) { 0xFFFFFFFC } else { 4 };
        },
        84 => { short_ea(mm, slot); alu(7, short_read(mm), cpu.regs[reg], 32); return pair_end(slot, mm, nx, base, room); },
        85 => { short_ea(mm, slot); alu(7, short_read(mm), imm, 32); return pair_end(slot, mm, nx, base, room); },
        86 => { short_ea(mm, slot); alu(4, short_read(mm), cpu.regs[reg], 32); return pair_end(slot, mm, nx, base, room); },
        87 => { short_ea(mm, slot); alu(4, short_read8(mm), imm, 8); return pair_end(slot, mm, nx, base, room); },
        88 => { short_ea(mm, slot); let b: u32 = r8(reg as! u8); alu(4, short_read8(mm), b, 8); return pair_end(slot, mm, nx, base, room); },
        89 => { cpu.regs[dc[slot].pre.op & 7] = dec(cpu.regs[dc[slot].pre.op & 7], 32); return pair_end(slot, mm, nx, base, room); },
        90 => { short_ea(mm, slot); short_step_rm(mm, false); return pair_end(slot, mm, nx, base, room); },
        91 => {
            let aop = reg as! u8;
            short_ea(mm, slot);
            let f0 = cpu.flags;
            let r = alu(aop, short_read8(mm), imm, 8);
            if aop != 7 { short_write8_fl(mm, r, f0); }
            return pair_end(slot, mm, nx, base, room);
        },
        92 => { short_ea(mm, slot); short_alu_rm(mm, 4, imm); return pair_end(slot, mm, nx, base, room); },
        93 => { short_ea(mm, slot); short_alu_rm(mm, 5, imm); return pair_end(slot, mm, nx, base, room); },
        94 => {
            let aop = dc[slot].pre.op >> 3;
            let a: u32 = r8(0);
            let r = alu(aop, a, imm, 8);
            if aop != 7 { set_r8(0, r as! u8); }
            return pair_end(slot, mm, nx, base, room);
        },
        95 => { short_ea(mm, slot); alu(4, short_read(mm), imm, 32); return pair_end(slot, mm, nx, base, room); },
        _ => {},
    }
    return nx;
}

// May the instruction with opcode op carry a LOCK prefix? Only a short list may, and only with a
// memory destination: the ALU operations that write, NOT, NEG, INC, DEC, XCHG, and the bit
// instructions that write. Anything else with LOCK is an invalid opcode. This looks at the bytes
// after the opcode without consuming them.
fn lockable(op: u8) -> bool {
    var at = cpu.base[CS] + cpu.ip;
    var two = false;
    var code = op;
    if op == 0x0F {
        code = lin_read(at, 8, cpu.cpl == 3) as! u8;
        at += 1;
        two = true;
    }
    let m = lin_read(at, 8, cpu.cpl == 3) as! u8;
    if m >> 6 == 3 { return false; }
    let r = m >> 3 & 7;
    if two {
        if code == 0xAB || code == 0xB3 || code == 0xBB { return true; }
        if i686 && (code == 0xB0 || code == 0xB1 || code == 0xC0 || code == 0xC1) { return true; }      // CMPXCHG, XADD
        if i686 && code == 0xC7 { return r == 1; }                                                      // CMPXCHG8B
        return code == 0xBA && r >= 5;
    }
    if code < 0x38 && code & 7 < 2 { return true; }
    match code {
        0x80, 0x81, 0x83 => { return r != 7; },
        0x86, 0x87 => { return true; },
        0xF6, 0xF7 => { return r == 2 || r == 3; },
        0xFE, 0xFF => { return r < 2; },
        _ => { return false; },
    }
}

// ---- One instruction ----

// A fault waiting to be delivered: exec_one delivers it instead of executing an instruction.
var pending = false;
var pending_vec: u8 = 0;
var pending_has_err = false;

// One instruction, or the delivery of a pending fault. False when a fault cut it short.
// One instruction, or a run of them. Most of the time the instruction is one of 32-bit code that
// the decode cache knows and has a short executor for, with no fault or interrupt waiting. That
// case is handled here, in a function kept small; everything else is exec_general's.
//
// After a short executor the function does not return if the next instruction can be taken the
// same way: it counts the one just done, notes where the next begins, and goes on. Short
// executors touch no device and change no segment, so nothing that the run loop watches for can
// happen in between, except that virtual time reaches chain_until, the moment the run loop
// worked out that something else is due. A run stops one instruction short of that moment, and
// the instruction it stops at is the general path's, as is any instruction a run cannot take:
// so a run never ends the step, and what it executed is counted here, not by the caller.
// Padding: Goose packs globals, and what follows is to sit at a multiple of 8 (E050;
// tools/layout.sh shows where each global is, and tools/difftest.sh checks these).
var pad_chain: u8[4] = [0; 4];
var chain_until = 0;
var run_from = 0;        // how many instructions the current run could execute when it began,
var run_left = 0;        // and how many it still can; both zero outside a run (see exec_short)

// Adds to the virtual time the instructions the current run has executed, and closes the
// run's count.
fn run_time() {
    vtime += run_from - run_left;
    run_from = 0;
    run_left = 0;
}

// Runs short executors for as long as it can, and adds what it ran to the virtual time. It
// leaves the instruction it could not run, or would not for want of time, to exec_general.
// Within a run only the instruction pointer is noted at the start of each instruction, in
// saved.ip, and cpu.ip is left behind until the run ends (E049). Nothing else needs putting
// back: a short executor changes nothing before the last point at which it can fault. It reads
// before it writes a register, writes memory before it moves the stack pointer, and has the old
// flags in place while it stores a result to memory (short_write_fl). light_save tells step,
// which undoes a faulting instruction, that `saved` holds the instruction pointer and no more.
//
// It is a 64-bit number, 0 or 1, and not a bool, on purpose. Goose packs globals with no
// padding, so one more byte here moves every global declared after it, in this file and in the
// files imported later, by one byte. Among those is the virtual time, a 64-bit counter written
// after every instruction; moved off its alignment it costs the host a fifth more cycles on
// 16-bit code (E021). Eight bytes leave everything behind where it was.
var light_save = 0;

fn exec_short() {
    var ran = false;
    // What does not change during a run is worked out once. No short executor loads the code
    // segment, so its base and limit stand; and the run may go on for one instruction less
    // than there is virtual time before the next event.
    let base = cpu.base[CS];
    let lim = cpu.limit[CS];
    if lim < 15 { return; }
    let ip_max = lim - 15;
    var left = chain_until - vtime;
    // With time for one instruction only, or with interrupts held off for one (after which
    // one may be due), the general path runs that one.
    if shadow || left < 2 { return; }
    // From here on `left` is how many instructions the run itself may execute: one less,
    // because the last instruction before the time is up is the general path's.
    left -= 1;
    var a = base + cpu.ip;
    // The virtual time stands still during a run. What the run keeps up is how many
    // instructions it may still execute, in a local, and stored in run_left after each one;
    // run_from is what that was at the start. The time is put right when the run ends, by
    // run_time(), and by whoever wants it in between (RDTSC) or after a fault (step).
    run_from = left;
    run_left = left;
    // From here until this function returns, `saved` is good for the instruction pointer
    // only: a short executor that faults has changed nothing else (see light_save).
    light_save = 1;
    // One pass for each page of code the run is on (E042). What follows is worked out anew
    // for each page and is constant inside it.
    loop {
        // The page of code last translated, and where it is in RAM: no short executor
        // translates code or changes the paging, so these stand for the whole page (E029). A
        // page number that is not one (nothing translated yet) is no page to run on.
        if code_page > 0xFFFFF || !code_ok { break; }
        let page_at = code_page << 12;
        // code_ok says the whole page is in RAM; said again here as a test of the address
        // itself.
        if code_phys >= RAM_SIZE - 4096 { break; }
        // A run stays on that page (what has an entry in its last 15 bytes ends in the page,
        // E088) and within the code segment's limit less 15. Both are one bound on the offset
        // from the start of the page
        // (E030): the instruction pointer at the start of the page is ip_lo, and it rises
        // with the offset. A page on which it wraps, or that begins beyond the limit, is left
        // to the general path.
        let ip_lo = page_at - base;
        if ip_lo > ip_max || ip_lo > 0xFFFFF000 { break; }
        var off_max: u32 = 0xFFF;
        if ip_max - ip_lo < off_max { off_max = ip_max - ip_lo; }
        var moved = false;
        // Inside the page the run reckons in physical addresses, which is what an entry is
        // found by (E044): p is where the next instruction is in RAM. A linear address is
        // lin_of above it, the same for the whole page, so the executors are given the code
        // segment's base less that, and what they work out with it (the instruction pointer
        // to store, a return address to push, where a RET goes) comes out as before.
        let phys32: u32 = code_phys;
        let lin_of = page_at - phys32;
        let pbase = base - lin_of;
        var p = a - lin_of;
        // The same address as the executor gave it, which for a pair has PAIR_RAN above it.
        var pr: u64 = p;
        run_pmax = phys32 + off_max;
        // Where a run begins is where a block may begin: the JIT counts the arrival (E059).
        if jit_on && !moved { jit_arrive(a - lin_of); }
        let phys64: u64 = phys32;
        let off_max64: u64 = off_max;
        loop {
            let off = pr - phys64;
            if off > off_max64 {
                if pr >= PAIR_RAN {
                    // Not an address off the page: a pair was run, and its second
                    // instruction is still to be counted.
                    pr = p;
                    left -= 1;
                    run_left = left;
                    saved.ip = p - pbase;
                    if left <= 0 { break; }
                    continue;
                }
                // Off this page, or too near the segment's limit. If it is another page and the TLB has
                // it, that is the page of code from here on, as the general path would make
                // it, and the run starts over there. A TLB entry says the page is in RAM.
                // Without one the general path translates it, and raises the page fault if
                // there is to be one.
                a = p + lin_of;
                let page = a >> 12;
                if page != code_page {
                    let t = page & (TLB_HALF - 1) | (if cpu.cpl == 3 { TLB_HALF } else { 0 });
                    if tlb_rtag[t] == page {
                        code_phys = tlb_rphys[t];
                        code_page = page;
                        code_ok = true;
                        moved = true;
                    }
                }
                break;
            }
            let slot: i64 = p & (DC_HALF - 1) | DC_HALF;
            if dc[slot].tag != p { break; }
            var kind = dc[slot].pre.kind;
            // One test for the usual case, a kind with an executor (1 to K_LAST). What is left
            // is 0, an instruction met for the second time, whose first, general, execution
            // recorded the operand: classify it now and, if it has an executor, run it with
            // that this time already. Or K_NONE.
            if kind - 1 >= K_LAST {
                // A block of the JIT's: the run ends here and says so, and exec_one has the
                // block run. Nothing of that is done in this function: the code for it,
                // wherever in the function it was put, cost every instruction one to three
                // percent, block or not (E060).
                if kind == K_BLOCK { jit_at = slot; break; }
                if kind != 0 { break; }
                ins = dc[slot].pre;
                classify(slot, code64(p));
                kind = dc[slot].pre.kind;
                // No executor (K_NONE, or a kind only the JIT knows), or (the JIT took the
                // entry back for a block it had, jit_reclaim) a block: either way the general
                // path runs this one.
                if kind - 1 >= K_LAST { break; }
            }
            pr = run_short(kind, slot, pbase, left);
            p = pr as! u32;
            left -= 1;
            run_left = left;
            saved.ip = p - pbase;
            ran = true;
            // No time left: the run ends, and the general path runs the next one. (Not after
            // a pair: that is run only with time for two.)
            if left <= 0 { break; }
        }
        if !moved { break; }
    }
    // The instruction at hand is for the general path, which wants the whole CPU saved.
    light_save = 0;
    run_time();
    if ran { cpu.ip = saved.ip; saved = cpu; }
}

// This function only chooses, so that it needs no registers of its own and costs next to nothing
// to enter: 16-bit code goes straight to exec_general.
fn exec_one() -> bool {
    if code32() && dc_on && !pending && !(irq_line && flag(IF) && !shadow) {
        exec_short();
        // The run ended at a block: the blocks are run, and then a run again, for as long
        // as that goes on.
        while jit_at >= 0 && jit_blocks() {
            if jit_stop { break; }
            exec_short();
        }
    }
    return exec_general();
}

fn exec_general() -> bool {
    if pending {
        pending = false;
        deliver(pending_vec, false, pending_has_err, pending_err);
        return true;
    }
    // A hardware interrupt is taken between instructions, then its handler's first one runs.
    if irq_line && flag(IF) && !shadow { deliver(pic_ack(), false, false, 0); }

    // At a BIOS entry: perform the service instead of fetching an instruction, then IRET.
    if bios_on && cpu.ip < 256 && cpu.segs[CS] == BIOS_SEG {
        bios_call(cpu.ip as! u8);
        do_iret(16);
        if bios_idle {
            // The service is waiting for an interrupt. A real BIOS waits with interrupts on,
            // whatever the caller's IF was.
            bios_idle = false;
            set_flag(IF, true);
            cpu.halted = true;
        }
        return true;
    }

    shadow = false;

    // Is this instruction in the decode cache? It can be when its next 16 bytes (an instruction
    // is at most 15) lie in the page of code already translated, inside the segment and in RAM.
    let c32 = code32();
    let a = cpu.base[CS] + cpu.ip;
    let lim = cpu.limit[CS];
    // On a page of code other than the one last translated, translate it now, as the fetch of
    // the first byte would in a moment (and with the same page fault, if there is to be one):
    // otherwise the cache counts as unusable for the first instruction on every new page, and
    // an instruction it holds is decoded from its bytes all over again (E034).
    // Only for 32-bit code, where runs are: 16-bit code would pay for the test on every
    // instruction, and its first fetch does the same thing.
    if c32 && a >> 12 != code_page && dc_on && cpu.ip <= lim {
        code_phys = page_read(a);
        code_page = a >> 12;
        code_ok = code_phys < RAM_SIZE - 4096 && code_phys + 0xFFF <= phys_mask;
    }
    // In the page's last fifteen bytes an entry is there only for 32-bit code, and only for an
    // instruction that ends in the page: the test is made when the entry is, below (E088).
    let poff = a & 0xFFF;
    let usable = dc_on && a >> 12 == code_page && code_ok && (poff <= 0xFF0 || c32) && lim >= 15 && cpu.ip <= lim - 15
        && (c32 || cpu.ip <= 0xFFF0);
    // An entry is found by the instruction's physical address. For 32-bit code the entry is
    // then good as it stands, because a store into its bytes would have emptied it (E044);
    // for 16-bit code, where code and data share pages as a rule, its bytes are compared.
    let key = code_phys | a & 0xFFF;
    let slot: i64 = key & (DC_HALF - 1) | (if c32 { DC_HALF } else { 0 });
    var op: u8 = 0;
    var raw: u64 = 0;
    var hit = false;
    dc_cur = -1;
    dc_ip0 = cpu.ip;
    if usable {
        raw = code64(code_phys | a & 0xFFF);
        if dc[slot].tag == key && (c32 || (raw ^ dc[slot].bytes) & dc[slot].mask == 0) {
            hit = true;
            dc_cur = slot;
            ins = dc[slot].pre;
            op = ins.op;
            // An instruction with a short executor is run here and now, and that is all of it.
            let kind = ins.kind;
            if kind < K_NONE {
                // The executor reckons in physical addresses: the base it is given is the
                // code segment's, less what a linear address is above the physical one.
                // One instruction is wanted here: of a pair, the first.
                // Of a block, its first instruction by its own kind.
                let k1 = if kind == K_BLOCK { jit_kind[slot - DC_HALF] } else { kind };
                if k1 - 1 < K_LAST {
                    let pb = cpu.base[CS] - (a - key);
                    cpu.ip = (run_short(k1, slot, pb, 0) as! u32) - pb;
                    return true;
                }
                // Not classified yet; or a kind only the JIT knows, which is decoded below
                // like any other.
                if k1 == 0 { classify(slot, raw); }
            }
            cpu.ip += ins.plen;
        }
    }
    if !hit {
        ins.lock = false;
        ins.seg = -1;
        ins.rep = 0;
        ins.osz = if c32 { 32 } else { 16 };
        ins.asz32 = c32;
        op = fetch8();
        // Most instructions have no prefix: three tests rule that out before the prefix loop.
        // (26 2E 36 3E are segment overrides, 64-67 FS GS and the size prefixes, F0 F2 F3 LOCK and REP.)
        if op & 0xE7 == 0x26 || op & 0xFC == 0x64 || op & 0xFC == 0xF0 {
            loop {
                match op {
                    0x26 => { ins.seg = ES; },
                    0x2E => { ins.seg = CS; },
                    0x36 => { ins.seg = SS; },
                    0x3E => { ins.seg = DS; },
                    0x64 => { ins.seg = FS; },
                    0x65 => { ins.seg = GS; },
                    0x66 => { ins.osz = if code32() { 16 } else { 32 }; },
                    0x67 => { ins.asz32 = !code32(); },
                    0xF2 => { ins.rep = 1; },
                    0xF3 => { ins.rep = 2; },
                    0xF0 => { ins.lock = true; },
                    _ => { break; },
                }
                op = fetch8();
            }
        }
        if ins.lock && !lockable(op) { fault(6); }
        let plen = cpu.ip - dc_ip0;
        // No more than three prefixes: then the longest instruction that can follow still ends
        // within the 16 bytes that were checked, which the fetches of a cached instruction rely on.
        // And in the page's last fifteen bytes, only an instruction known to end in the page:
        // its prefixes and opcode were fetched the long way just now, the rest will not be.
        var fits = true;
        if poff > 0xFF0 {
            let il = if ins.asz32 && plen <= 4 { ins_len(op, raw, plen, ins.osz) } else { 0 };
            fits = il != 0 && poff + il <= 0x1000;
        }
        if usable && plen <= 4 && fits {
            ins.op = op;
            ins.plen = plen as! u8;
            dc[slot].bytes = raw;
            dc[slot].mask = byte_mask(plen);
            ins.kind = 0;
            dc[slot].pre = ins;
            dc[slot].tag = key;
            if c32 && code_mark[key >> 12] == 0 { code_mark_page(key >> 12); }
            // A new entry in this slot: whatever the JIT had counted or decided for the
            // slot was about another instruction, or about this one before it was rewritten.
            if c32 { dc_hot[slot - DC_HALF] = 0; }
            dc[slot].m = 0;
            dc[slot].disp = 0;
            dc_cur = slot;
        }
    }

    // In 00..3F, opcodes whose low 3 bits are 0..5 are the 8 operations in 6 forms.
    if op < 0x40 && op & 7 < 6 {
        let aop = op >> 3;
        let w = width(op);
        match op & 7 {
            0, 1 => {
                decode_modrm();
                let r = alu(aop, rm_read(w), regw(m_reg, w), w);
                if aop != 7 { rm_write(w, r); }
            },
            2, 3 => {
                decode_modrm();
                let r = alu(aop, regw(m_reg, w), rm_read(w), w);
                if aop != 7 { set_regw(m_reg, w, r); }
            },
            _ => {
                let r = alu(aop, regw(0, w), fetchw(w), w);
                if aop != 7 { set_regw(0, w, r); }
            },
        }
        return true;
    }

    // Dispatch in two steps: first on the opcode's high four bits, then within that row of the
    // opcode map. Goose compiles an integer match to a chain of comparisons, and the C compiler
    // turns such a chain into a jump table only when the arms are plain values with no ranges.
    // One match over all the opcodes cost a hundred-odd comparisons for those near its end.
    match op >> 4 {
        0x0 => {
            match op {
                0x06 => { pushv(cpu.segs[ES]); },
                0x07 => { load_seg(ES, popv() as! u16); },
                0x0E => { pushv(cpu.segs[CS]); },
                0x0F => { two_byte(); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0x1 => {
            match op {
                0x16 => { pushv(cpu.segs[SS]); },
                0x17 => { load_seg(SS, popv() as! u16); shadow = true; },
                0x1E => { pushv(cpu.segs[DS]); },
                0x1F => { load_seg(DS, popv() as! u16); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0x2 => {
            match op {
                0x27 => { daa_das(false); },
                0x2F => { daa_das(true); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0x3 => {
            match op {
                0x37 => { aaa_aas(false); },
                0x3F => { aaa_aas(true); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0x4 => {
            match op {
                0x40..0x48 => { set_regw(op, ins.osz, inc(regw(op, ins.osz), ins.osz)); },
                0x48..0x50 => { set_regw(op, ins.osz, dec(regw(op, ins.osz), ins.osz)); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0x5 => {
            match op {
                0x50..0x58 => { pushv(regw(op, ins.osz)); },
                0x58..0x60 => { let v = popv(); set_regw(op, ins.osz, v); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0x6 => {
            match op {
                0x60 => {
                    let sp0 = regw(SP, ins.osz);
                    for i: u8 in 0..8 { if i == 4 { pushv(sp0); } else { pushv(regw(i, ins.osz)); } }
                },
                0x61 => {
                    for k: u8 in 0..8 {
                        let i = 7 - k;
                        let v = popv();
                        if i != 4 { set_regw(i, ins.osz, v); }
                    }
                },
                0x62 => {                                            // BOUND
                    decode_modrm();
                    if m_mod == 3 { fault(6); }
                    let index = sx(regw(m_reg, ins.osz), ins.osz);
                    let lower = sx(seg_read(ea_seg, ea_off, ins.osz), ins.osz);
                    let upper = sx(seg_read(ea_seg, ea_off + ((ins.osz as u32) >> 3), ins.osz), ins.osz);
                    if index < lower || index > upper { fault(5); }
                },
                0x63 => {                                            // ARPL
                    if !protected() || v86() { fault(6); }
                    decode_modrm();
                    let dst = rm_read(16);
                    let src: u32 = r16(m_reg);
                    if dst & 3 < src & 3 { rm_write(16, dst & 0xFFFC | src & 3); set_flag(ZF, true); }
                    else { set_flag(ZF, false); }
                },
                0x68 => { pushv(fetchv()); },
                0x6A => { pushv(fetch_s8()); },
                0x69, 0x6B => {
                    decode_modrm();
                    let a = rm_read(ins.osz);
                    let b = if op == 0x69 { fetchv() } else { fetch_s8() };
                    let p = imul(a, b, ins.osz);
                    set_regw(m_reg, ins.osz, p as! u32);
                },
                0x6C..0x70 => { string_op(op); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0x7 => {
            match op {
                0x70..0x80 => { jump_rel8(cond(op & 0x0F)); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0x8 => {
            match op {
                0x80..0x84 => {
                    let w = width(op);
                    decode_modrm();
                    let a = rm_read(w);
                    var b: u32 = 0;
                    if op == 0x81 { b = fetchv(); } else if op == 0x83 { b = fetch_s8() & mask(w); } else { b = fetch8(); }
                    let r = alu(m_reg, a, b, w);
                    if m_reg != 7 { rm_write(w, r); }
                },
                0x84, 0x85 => {
                    let w = width(op);
                    decode_modrm();
                    alu(4, rm_read(w), regw(m_reg, w), w);
                },
                0x86, 0x87 => {
                    let w = width(op);
                    decode_modrm();
                    let a = rm_read(w);
                    rm_write(w, regw(m_reg, w));
                    set_regw(m_reg, w, a);
                },
                0x88, 0x89 => { let w = width(op); decode_modrm(); rm_write(w, regw(m_reg, w)); },
                0x8A, 0x8B => { let w = width(op); decode_modrm(); set_regw(m_reg, w, rm_read(w)); },
                0x8C => {
                    decode_modrm();
                    if m_reg > 5 { fault(6); }
                    // To a register the selector is zero-extended to the operand size; to memory it is 16 bits.
                    rm_write(if m_mod == 3 { ins.osz } else { 16 }, cpu.segs[m_reg]);
                },
                0x8D => { decode_modrm(); set_regw(m_reg, ins.osz, ea_off); },
                0x8E => {
                    decode_modrm();
                    if m_reg > 5 || m_reg == CS { fault(6); }
                    load_seg(m_reg, rm_read(16) as! u16);
                    if m_reg == SS { shadow = true; }
                },
                0x8F => { let v = popv(); decode_modrm(); rm_write(ins.osz, v); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0x9 => {
            match op {
                0x90..0x98 => { let t = regw(AX, ins.osz); set_regw(AX, ins.osz, regw(op, ins.osz)); set_regw(op, ins.osz, t); },
                0x98 => {
                    if ins.osz == 16 { set_r16(AX, (r8(0) as! i8) as! u16); }
                    else { set_r32(AX, (r16(AX) as! i16) as! u32); }
                },
                0x99 => {
                    if ins.osz == 16 { set_r16(DX, if r16(AX) & 0x8000 != 0 { 0xFFFF } else { 0 }); }
                    else { set_r32(DX, if r32(AX) & 0x80000000 != 0 { 0xFFFFFFFF } else { 0 }); }
                },
                0x9A => { let off = fetchv(); let seg = fetch16() as! u16; far_call(seg, off, ins.osz); },
                0x9B => { if i686 && cr[0] & 0x0A == 0x0A { fault(7); } },      // FWAIT: traps when MP and TS are set
                0x9C => { if v86() { io_sensitive(); } pushv(cpu.flags & 0x00FCFFFF); },
                0x9D => {
                    if v86() { io_sensitive(); }
                    // IF changes only if the level may do I/O; IOPL only at level 0 (always, in real mode).
                    var m: u32 = 0x4DD5;
                    if ins.osz == 32 { m |= AC | ID; }
                    if !protected() || cpu.cpl == 0 { m |= IOPL; }
                    if !protected() || (if v86() { iopl() == 3 } else { cpu.cpl <= iopl() }) { m |= IF; }
                    write_flags(popv(), m);
                },
                0x9E => { cpu.flags = cpu.flags & 0xFFFFFF00 | (r8(4) & 0xD5) | 2; },
                0x9F => { set_r8(4, cpu.flags as! u8); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0xA => {
            match op {
                0xA0 => { let off = if ins.asz32 { fetch32() } else { fetch16() }; set_r8(0, seg_read(seg_of(DS), off, 8) as! u8); },
                0xA1 => { let off = if ins.asz32 { fetch32() } else { fetch16() }; set_regw(AX, ins.osz, seg_read(seg_of(DS), off, ins.osz)); },
                0xA2 => { let off = if ins.asz32 { fetch32() } else { fetch16() }; seg_write(seg_of(DS), off, 8, r8(0)); },
                0xA3 => { let off = if ins.asz32 { fetch32() } else { fetch16() }; seg_write(seg_of(DS), off, ins.osz, regw(AX, ins.osz)); },
                0xA4..0xA8 => { string_op(op); },
                0xA8, 0xA9 => { let w = width(op); alu(4, regw(0, w), fetchw(w), w); },
                0xAA..0xB0 => { string_op(op); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0xB => {
            match op {
                0xB0..0xB8 => { let v = fetch8(); set_r8(op, v); },
                0xB8..0xC0 => { let v = fetchv(); set_regw(op, ins.osz, v); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0xC => {
            match op {
                0xC0, 0xC1 => {
                    let w = width(op);
                    decode_modrm();
                    let n = fetch8();
                    rm_write(w, shift(m_reg, rm_read(w), n, w));
                },
                0xC2 => { let n = fetch16(); set_ip(popv()); sp_set(sp_get() + n); },
                0xC3 => { set_ip(popv()); },
                0xC4 => { load_far(ES); },
                0xC5 => { load_far(DS); },
                0xC6, 0xC7 => { let w = width(op); decode_modrm(); rm_write(w, fetchw(w)); },
                0xC8 => {
                    // Two widths are in play: what is pushed is as wide as the operand size, while BP and
                    // SP move at the width of the stack segment. The frame pointer is the raw ESP, so
                    // with a 16-bit stack and a 32-bit operand its upper half shows whatever ESP had.
                    // The last step probes the new top of the stack for writing without writing it.
                    // (rustx86 worked these out against test386, stage 1A.)
                    let size = fetch16();
                    let level = fetch8() & 0x1F;
                    let big = stack32();
                    pushv(regw(BP, ins.osz));
                    let frame = r32(SP);
                    if level > 0 {
                        for i in 1..level {
                            if big { set_r32(BP, r32(BP) - ((ins.osz as u32) >> 3)); } else { set_r16(BP, r16(BP) - (ins.osz as u16) / 8); }
                            pushv(seg_read(SS, if big { r32(BP) } else { r16(BP) }, ins.osz));
                        }
                        pushv(frame);
                    }
                    if big { set_r32(BP, frame); } else { set_r16(BP, frame as! u16); }
                    var top = sp_get() - size;
                    if !big { top &= 0xFFFF; }
                    let probe = translate(cpu.base[SS] + top, true, cpu.cpl == 3);
                    sp_set(top);
                },
                0xC9 => { sp_set(if stack32() { r32(BP) } else { r16(BP) }); let v = popv(); set_regw(BP, ins.osz, v); },
                0xCA => { let n = fetch16(); far_ret(ins.osz, n); if ins.osz == 16 { cpu.ip &= 0xFFFF; } },
                0xCB => { far_ret(ins.osz, 0); if ins.osz == 16 { cpu.ip &= 0xFFFF; } },
                0xCC => { deliver(3, true, false, 0); },
                0xCD => { let n = fetch8(); if v86() { io_sensitive(); } deliver(n, true, false, 0); },
                0xCE => { if flag(OF) { deliver(4, true, false, 0); } },
                0xCF => { do_iret(ins.osz); if ins.osz == 16 { cpu.ip &= 0xFFFF; } },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0xD => {
            match op {
                0xD0..0xD4 => {
                    let w = width(op);
                    decode_modrm();
                    let n: u8 = if op < 0xD2 { 1 } else { r8(1) };
                    rm_write(w, shift(m_reg, rm_read(w), n, w));
                },
                0xD4 => {
                    let base = fetch8();
                    if base == 0 { fault(0); }
                    let al = r8(0);
                    set_r8(4, al / base);
                    set_r8(0, al % base);
                    set_szp(r8(0), 8);
                },
                0xD5 => {
                    let base = fetch8();
                    let lo = r8(0);
                    let hi = r8(4);
                    let al = lo + hi * base;
                    set_r16(AX, al);
                    set_szp(al, 8);
                },
                0xD6 => { set_r8(0, if flag(CF) { 0xFF } else { 0 }); },
                0xD7 => { let index: u32 = r8(0); set_r8(0, seg_read(seg_of(DS), (addr_reg(BX) + index) & (if ins.asz32 { 0xFFFFFFFF } else { 0xFFFF }), 8) as! u8); },
                // The i686 has an FPU. The 386 has none and lets the escape opcodes pass.
                0xD8..0xE0 => {
                    decode_modrm();
                    if i686 {
                        // With EM or TS set in CR0 the unit is not available: the operating
                        // system wants the trap.
                        if cr[0] & 0x0C != 0 { raise(7, false, 0); }
                        fpu_escape(op);
                    }
                },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0xE => {
            match op {
                0xE0 => { addr_reg_add(CX, 0xFFFFFFFF); jump_rel8(addr_reg(CX) != 0 && !flag(ZF)); },
                0xE1 => { addr_reg_add(CX, 0xFFFFFFFF); jump_rel8(addr_reg(CX) != 0 && flag(ZF)); },
                0xE2 => { addr_reg_add(CX, 0xFFFFFFFF); jump_rel8(addr_reg(CX) != 0); },
                0xE3 => { jump_rel8(addr_reg(CX) == 0); },
                0xE4 => { let port = fetch8(); io_check(port, 8); set_r8(0, port_in8(port)); },
                0xE5 => { let port = fetch8(); io_check(port, ins.osz); set_regw(AX, ins.osz, port_read(port, ins.osz)); },
                0xE6 => { let port = fetch8(); io_check(port, 8); port_out8(port, r8(0)); },
                0xE7 => { let port = fetch8(); io_check(port, ins.osz); port_write(port, ins.osz, regw(AX, ins.osz)); },
                0xE8 => { let d = fetchv(); pushv(cpu.ip); set_ip(cpu.ip + d); },
                0xE9 => { let d = fetchv(); set_ip(cpu.ip + d); },
                0xEA => { let off = fetchv(); let seg = fetch16() as! u16; far_jump(seg, off); },
                0xEB => { jump_rel8(true); },
                0xEC => { io_check(r16(DX), 8); set_r8(0, port_in8(r16(DX))); },
                0xED => { io_check(r16(DX), ins.osz); set_regw(AX, ins.osz, port_read(r16(DX), ins.osz)); },
                0xEE => { io_check(r16(DX), 8); port_out8(r16(DX), r8(0)); },
                0xEF => { io_check(r16(DX), ins.osz); port_write(r16(DX), ins.osz, regw(AX, ins.osz)); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        0xF => {
            match op {
                0xF4 => { need_ring0(); cpu.halted = true; },
                0xF5 => { set_flag(CF, !flag(CF)); },
                0xF6, 0xF7 => { group3(op); },
                0xF8 => { set_flag(CF, false); },
                0xF9 => { set_flag(CF, true); },
                0xFA => { io_sensitive(); set_flag(IF, false); },
                0xFB => { io_sensitive(); if !flag(IF) { shadow = true; } set_flag(IF, true); },
                0xFC => { set_flag(DF, false); },
                0xFD => { set_flag(DF, true); },
                0xFE, 0xFF => { group45(op); },
                _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
            }
        },
        _ => { cpu.ip = saved.ip; stop("unimplemented opcode", op); },
    }
    return true;
}

// With --faults, every fault is reported on standard error: its vector and error code, where it
// happened and the bytes there. Page faults are left out unless they come from the kernel
// itself going wrong (they are how demand paging works).
var log_faults = false;
var faults_logged = 0;

fn note_fault(vec: u8, has_err: bool, err: u32) {
    if vec == 14 || faults_logged >= 40 { return; }
    faults_logged++;
    var msg: u8[>..] = [];
    format(msg, "g86m: fault ", vec);
    if has_err { format(msg, " error "); format_int(msg, err, 16, 4, '0'); }
    format(msg, " at ");
    format_int(msg, cpu.segs[CS], 16, 4, '0');
    format(msg, ":");
    format_int(msg, cpu.ip, 16, 8, '0');
    format(msg, "  bytes:");
    for i: u32 in 0..10 {
        format(msg, " ");
        format_int(msg, mem8(translate_quiet(cpu.base[CS] + cpu.ip + i)), 16, 2, '0');
    }
    format(msg, "\n");
    write_stderr(msg);
}

// Runs one instruction; if it faults, puts the state back and delivers the fault. A fault while
// delivering a fault becomes a double fault, and a fault while delivering that stops the machine
// (a real one would reset).
fn step() {
    saved = cpu;
    if exec_one() { return; }
    var vec = fault_vec;
    var has_err = fault_has_err;
    var err = fault_err;
    for attempt in 3 {
        if light_save != 0 {
            // The fault was in a run of short instructions. The executor that faulted had
            // changed nothing yet, so there is only the instruction pointer to set, which a
            // run does not keep up. `saved` is made whole again.
            cpu.ip = saved.ip;
            run_time();
            shadow = false;
            saved = cpu;
            light_save = 0;
        } else {
            cpu = saved;
            seg_bounds();                // the segments may have gone back with the rest
        }
        forget_last();                   // the privilege level may have gone back with the rest
        if log_faults { note_fault(vec, has_err, err); }
        if attempt == 2 { stop("triple fault; the last vector was", vec); return; }
        pending = true;
        pending_vec = vec;
        pending_has_err = has_err;
        pending_err = err;
        if exec_one() { return; }
        vec = 8;
        has_err = true;
        err = 0;
    }
}
