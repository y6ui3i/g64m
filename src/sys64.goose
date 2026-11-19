// The system side of the 64-bit CPU (E094): what long mode has beyond a program's view.
//
// When `machine` is true the CPU is a whole one, at a privilege level, and:
// - memory is reached through four levels of page tables (walk): 4 KB, 2 MB and 1 GB
//   pages, the present, write, user and no-execute bits, CR0.WP, the accessed and dirty
//   bits; with a TLB in front (xlate), so that a page's tables are walked once for each
//   kind of access;
// - a fault does not end the run: fault() puts the registers back as the instruction found
//   them, and the next call of exec64 delivers it through the IDT (deliver);
// - the instructions that load and read the tables, the control registers and the MSRs are
//   here, with IRETQ and the far return.
// When it is false (a user-mode program, E091) memory is one block and a fault stops the run.
//
// Privilege level 3 (E095) is reached by IRETQ and SYSRET and left by SYSCALL, by INT
// and by a fault, whose handler gets the stack the TSS names.
//
// Not yet: interrupts from outside, compatibility mode (32-bit code at level 3), a far
// return to level 3, debug registers that do anything, and any check of a descriptor
// beyond what the tests reach.

import std;
import cpu64;
import x64;

let SEG_ES = 0; let SEG_CS = 1; let SEG_SS = 2; let SEG_DS = 3; let SEG_FS = 4; let SEG_GS = 5;

var cr0: u64 = 0;
var cr2: u64 = 0;
var cr3: u64 = 0;
var cr4: u64 = 0;
var cr8: u64 = 0;
var efer: u64 = 0;
var gdt_base: u64 = 0;
var gdt_limit: u64 = 0;
var idt_base: u64 = 0;
var idt_limit: u64 = 0;
var tr_base: u64 = 0;
var tr_limit: u64 = 0;
var msr_star: u64 = 0;
var msr_lstar: u64 = 0;
var msr_cstar: u64 = 0;
var msr_fmask: u64 = 0;
var msr_kernel_gs: u64 = 0;
var dr6: u64 = 0xFFFF0FF0;
var dr7: u64 = 0x400;

// The state the instruction at hand started from, to go back to when it faults.
var saved_reg: u64[16] = [0; 16];
var saved_flags: u64 = 0;
var saved_cpl: u8 = 0;

// A fault waiting to be delivered: its vector, or -1.
var pending: i64 = -1;
var pending_err: u64 = 0;
var pending_has_err = false;
var pending_trap = false;    // it is a trap: nothing is put back, and RF is not set
// True once the instruction at hand has gone to a handler: no single step after that.
var delivered = false;
var by_syscall = false;      // the instruction at hand was SYSCALL or SYSRET
// The vector being delivered, or -1: a fault met while delivering one is a double fault,
// and one met while delivering that ends the run, as it resets a machine.
var delivering: i64 = -1;

var seg: u16[6] = [0; 6];
var tr_sel: u16 = 0;
var ldt_sel: u16 = 0;
var machine = false;
var cpl: u8 = 3;

// ---- Faults ----

fn fault(vec: u8, has_err: bool, err: u64) {
    if !machine { stop64("a fault, which nothing delivers in a user-mode program: vector", vec); }
    for i in 16 { reg[i] = saved_reg[i]; }
    rflags = saved_flags;
    cpl = saved_cpl;
    if delivering == 8 { delivering = -1; stop64("a triple fault, after vector", vec); }
    if delivering >= 0 {
        pending = 8;
        pending_err = 0;
        pending_has_err = true;
    } else {
        pending = vec;
        pending_err = err;
        pending_has_err = has_err;
    }
    pending_trap = false;
    delivering = -1;
    return false from exec64;
}

// Remembers where the instruction starts from. Called at the top of every instruction.
inline fn save_start() {
    for i in 16 { saved_reg[i] = reg[i]; }
    saved_flags = rflags;
    saved_cpl = cpl;
}

// ---- Physical memory ----

// Above the end of memory nothing answers: reads give ones and writes are dropped.
fn phys_rd(p: u64, w: u8) -> u64 {
    if p >= MEM_SIZE - 8 { return mask(w); }
    return mem_rd(p, w);
}

fn phys_wr(p: u64, w: u8, v: u64) {
    if p >= MEM_SIZE - 8 { return; }
    mem_wr(p, w, v);
}

// ---- Paging ----

let ACC_WRITE = 1;
let ACC_EXEC = 2;
let ACC_SYSTEM = 4;     // by the CPU itself (a descriptor table, the TSS): as privilege level 0

let ADDR_BITS: u64 = 0x000FFFFFFFFFF000;

// kind: 0 the page is not there, 1 it is and the access is not allowed, 9 an entry has a bit
// set that must be clear (which is also "there").
fn page_fault(a: u64, acc: u8, kind: u64) {
    cr2 = a;
    var code = kind;
    if acc & ACC_WRITE != 0 { code |= 2; }
    if cpl == 3 && acc & ACC_SYSTEM == 0 { code |= 4; }
    if acc & ACC_EXEC != 0 && efer & 0x800 != 0 { code |= 0x10; }
    fault(14, true, code);
}

// ---- The TLB (E096) ----
//
// Six tables of TLB_SIZE entries: for reads, writes and fetches of instructions, each for
// privilege level 3 and for the rest. An entry is found by the page number's low bits and
// holds the page number and the physical page behind it. It is made only by a walk that
// succeeded for that kind of access at that level, so a hit means: allowed, and the
// accessed bits (and for a write the dirty bit) are already set. Nothing is checked on a
// hit.
//
// What an entry was made under must still hold: a write of CR3 empties everything, as do
// writes of CR0 (WP), CR4 and EFER (NXE); INVLPG empties one page's six entries. A guest
// that makes an entry more permissive without invalidating meets no stale refusal, since
// a refusal is never kept: the access that was refused walks again.

let TLB_BITS = 12;
let TLB_SIZE = 1 << TLB_BITS;
let TLB_EMPTY: u64 = 0xFFFFFFFFFFFFFFFF;       // no page has this number

var tlb_tag: u64[6 * TLB_SIZE] = [0xFFFFFFFFFFFFFFFF; 6 * TLB_SIZE];
var tlb_phys: u64[6 * TLB_SIZE] = [0; 6 * TLB_SIZE];

// An entry stands for 4 KB even when the page is larger, so a large page has many entries.
// This says whether any entry made since the last emptying came from a 1 GB page.
var tlb_has_1g = false;

fn tlb_flush() {
    for i in 6 * TLB_SIZE { tlb_tag[i] = TLB_EMPTY; }
    tlb_has_1g = false;
}

// INVLPG: the page that a is in is forgotten, whatever its size. Every entry in a's 2 MB is
// dropped (512 places in each table), since entries of a 2 MB page may be anywhere in it;
// with entries of 1 GB pages about, everything. More than asked for is always allowed.
fn tlb_forget(a: u64) {
    if tlb_has_1g { tlb_flush(); return; }
    let first = a >> 12 & 0xFFFFFFFFFFFFFE00;
    for k in 512 {
        let i = ((first + (k as! u64)) & (TLB_SIZE - 1)) as! i64;
        for t in 6 {
            if tlb_tag[t * TLB_SIZE + i] >> 9 == first >> 9 { tlb_tag[t * TLB_SIZE + i] = TLB_EMPTY; }
        }
    }
}

// Which table an access of kind acc uses now.
inline fn tlb_table(acc: u8) -> i64 {
    var t = 0;
    if acc & ACC_WRITE != 0 { t = 2; } else if acc & ACC_EXEC != 0 { t = 4; }
    if cpl == 3 && acc & ACC_SYSTEM == 0 { t += 1; }
    return t * TLB_SIZE;
}

// The physical address behind linear address a, for an access of kind acc; or a fault.
inline fn xlate(a: u64, acc: u8) -> u64 {
    let page = a >> 12;
    let i = tlb_table(acc) + ((page & (TLB_SIZE - 1)) as! i64);
    if tlb_tag[i] == page { return tlb_phys[i] | a & 0xFFF; }
    return walk(a, acc);
}

// The walk of the four levels, which fills the TLB when it succeeds.
fn walk(a: u64, acc: u8) -> u64 {
    let top = a >> 47;
    if top != 0 && top != 0x1FFFF { fault(13, true, 0); }
    let user = cpl == 3 && acc & ACC_SYSTEM == 0;
    var table = cr3 & ADDR_BITS;
    var writable = true;
    var for_user = true;
    var no_exec = false;
    var shift: u64 = 39;
    var e: u64 = 0;
    var at: u64[4] = [0; 4];
    var level = 0;
    while true {
        at[level] = table + (a >> shift & 0x1FF) * 8;
        e = phys_rd(at[level], 64);
        if e & 1 == 0 { page_fault(a, acc, 0); }
        if e & 2 == 0 { writable = false; }
        if e & 4 == 0 { for_user = false; }
        // Bit 63 is "may not be executed" once EFER says so, and a bit that must be clear
        // until then.
        if e >> 63 != 0 {
            if efer & 0x800 == 0 { page_fault(a, acc, 9); }
            no_exec = true;
        }
        if shift == 12 || (e & 0x80 != 0 && shift < 39) { break; }
        table = e & ADDR_BITS;
        shift -= 9;
        level += 1;
    }
    if user && !for_user { page_fault(a, acc, 1); }
    if acc & ACC_WRITE != 0 && !writable && (user || cr0 & 0x10000 != 0) { page_fault(a, acc, 1); }
    if acc & ACC_EXEC != 0 && no_exec { page_fault(a, acc, 1); }
    // Accessed at every level, and dirty where the page is, once the access is allowed.
    for i in level {
        let up = phys_rd(at[i], 64);
        if up & 0x20 == 0 { phys_wr(at[i], 64, up | 0x20); }
    }
    let want: u64 = if acc & ACC_WRITE != 0 { 0x60 } else { 0x20 };
    if e & want != want { phys_wr(at[level], 64, e | want); }
    let low: u64 = ((1 as u64) << shift) - 1;
    let p = e & ADDR_BITS & ~low | a & low;
    // One entry, for this 4 KB of it, whatever the page's size.
    let i = tlb_table(acc) + ((a >> 12 & (TLB_SIZE - 1)) as! i64);
    tlb_tag[i] = a >> 12;
    tlb_phys[i] = p & 0xFFFFFFFFFFFFF000;
    if shift == 30 { tlb_has_1g = true; }
    return p;
}

// A read through the page tables. One that crosses a page is done a byte at a time.
fn sys_rd(a: u64, w: u8, acc: u8) -> u64 {
    let n: u64 = w / 8;
    if (a & 0xFFF) + n <= 0x1000 { return phys_rd(xlate(a, acc), w); }
    var v: u64 = 0;
    for i in n as! i64 {
        let k = i as! u64;
        v |= phys_rd(xlate(a + k, acc), 8) << (k * 8);
    }
    return v;
}

fn sys_wr(a: u64, w: u8, v: u64, acc: u8) {
    let n: u64 = w / 8;
    if (a & 0xFFF) + n <= 0x1000 { phys_wr(xlate(a, acc | ACC_WRITE), w, v); return; }
    // Both pages are found before anything is written, so that a fault leaves nothing half done.
    xlate(a, acc | ACC_WRITE);
    xlate((a | 0xFFF) + 1, acc | ACC_WRITE);       // CR2 is the second page's first byte
    for i in n as! i64 {
        let k = i as! u64;
        phys_wr(xlate(a + k, acc | ACC_WRITE), 8, v >> (k * 8) & 0xFF);
    }
}

// What the CPU itself reads and writes: descriptor tables and the TSS.
fn own_rd(a: u64, w: u8) -> u64 { return sys_rd(a, w, ACC_SYSTEM); }
fn own_wr(a: u64, w: u8, v: u64) { sys_wr(a, w, v, ACC_SYSTEM); }

// ---- Delivering an interrupt or a fault ----

// Goes to vector vec's handler, with ret as the address to come back to. soft: by an INT
// instruction, which the gate's privilege level must allow.
fn deliver(vec: u64, has_err: bool, err: u64, ret: u64, soft: bool) {
    let code = vec * 8 + 2;                                // the error code that names the gate
    if vec * 16 + 15 > idt_limit { fault(13, true, code); }
    let lo = own_rd(idt_base + vec * 16, 64);
    let hi = own_rd(idt_base + vec * 16 + 8, 64);
    let kind = lo >> 40 & 0xF;
    if kind != 0xE && kind != 0xF { fault(13, true, code); }
    if soft && (lo >> 45 & 3) < cpl { fault(13, true, code); }
    if lo >> 47 & 1 == 0 { fault(11, true, code); }
    let sel = lo >> 16 & 0xFFFF;
    let target = lo & 0xFFFF | (lo >> 48 & 0xFFFF) << 16 | (hi & 0xFFFFFFFF) << 32;
    let ist = lo >> 32 & 7;
    if sel & 0xFFF8 == 0 { fault(13, true, 0); }
    if (sel | 7) > gdt_limit { fault(13, true, sel & 0xFFFC); }
    let desc = own_rd(gdt_base + (sel & 0xFFF8), 64);
    let level = (desc >> 45 & 3) as! u8;
    if level > cpl { fault(13, true, sel & 0xFFFC); }
    if desc >> 47 & 1 == 0 { fault(11, true, sel & 0xFFFC); }

    delivered = true;
    let old_cpl = cpl;
    let old_ss: u64 = seg[SEG_SS];
    let old_cs: u64 = seg[SEG_CS];
    let old_rsp = reg[RSP];
    let old_flags = rflags;
    var sp = old_rsp;
    if level < cpl { sp = own_rd(tr_base + 4 + level * 8, 64); }
    if ist != 0 { sp = own_rd(tr_base + 0x1C + ist * 8, 64); }
    sp &= 0xFFFFFFFFFFFFFFF0;
    // The frame is written at the handler's privilege level.
    cpl = level;
    wr(sp - 8, 64, old_ss);
    wr(sp - 16, 64, old_rsp);
    wr(sp - 24, 64, old_flags);
    wr(sp - 32, 64, old_cs);
    wr(sp - 40, 64, ret);
    sp -= 40;
    if has_err { sp -= 8; wr(sp, 64, err); }
    reg[RSP] = sp;
    if level < old_cpl { seg[SEG_SS] = level; }
    seg[SEG_CS] = (sel & 0xFFFC | level) as! u16;
    rflags &= ~(TF | 0x4000 | RF | 0x20000);
    if kind == 0xE { rflags &= ~IF; }
    rip = target;
}

// Delivers the fault that is waiting. Called from exec64, since writing the frame can fault.
fn deliver_pending() {
    let vec = pending;
    pending = -1;
    delivering = vec;
    // A fault's return address is the instruction itself, and RF is set in the flags saved
    // with it, so that coming back to it does not meet the same instruction breakpoint. A
    // trap comes after its instruction and has neither.
    if !pending_trap { rflags |= RF; }
    pending_trap = false;
    deliver(vec as! u64, pending_has_err, pending_err, rip, false);
    delivering = -1;
}

// The single step: vector 1 follows an instruction that began with TF set, unless the
// instruction itself went to a handler. So the instruction after a POPF or an IRETQ that
// sets TF is the first to be followed by one, and a POPF that clears it still is. SYSCALL
// and SYSRET are the exception, on the CPU these tests were taken from: for them it is TF
// as they leave it that counts, so SYSRET with TF in R11 is followed by one at once, and
// SYSCALL with TF in FMASK by none. began: TF before the instruction. Called after every
// instruction.
inline fn single_step(began: bool) {
    let tf = if by_syscall { rflags & TF != 0 } else { began };
    by_syscall = false;
    if tf && !delivered && pending < 0 {
        pending = 1;
        pending_has_err = false;
        pending_trap = true;
        dr6 |= 0x4000;
    }
}

// ---- Segment registers ----

// Loads a data segment register. FS and GS take their base from the descriptor (32 bits of
// it; the rest is written by WRMSR), and a null selector leaves it zero.
fn seg_load(i: u8, v: u64) {
    let sel = v & 0xFFFF;
    if sel & 0xFFF8 != 0 && (sel | 7) > gdt_limit { fault(13, true, sel & 0xFFFC); }
    if i == SEG_FS || i == SEG_GS {
        var base: u64 = 0;
        if sel & 0xFFF8 != 0 {
            let desc = own_rd(gdt_base + (sel & 0xFFF8), 64);
            base = desc >> 16 & 0xFFFFFF | (desc >> 56 & 0xFF) << 24;
        }
        if i == SEG_FS { fs_base = base; } else { gs_base = base; }
    }
    seg[i] = sel as! u16;
}

// ---- Control registers and MSRs ----

fn need_level0() {
    if cpl != 0 { fault(13, true, 0); }
}

fn cr_get(n: u8) -> u64 {
    match n {
        0 => { return cr0; },
        2 => { return cr2; },
        3 => { return cr3; },
        4 => { return cr4; },
        8 => { return cr8; },
        _ => { fault(6, false, 0); return 0; },
    }
}

fn cr_set(n: u8, v: u64) {
    match n {
        0 => {
            if v & 0x80000001 != 0x80000001 { stop64("CR0 written without paging or protection: leaving long mode is not written, value", v); }
            cr0 = v;
            tlb_flush();
        },
        2 => { cr2 = v; },
        3 => { cr3 = v; tlb_flush(); },
        4 => {
            if v & 0x20 == 0 { stop64("CR4 written without PAE: leaving long mode is not written, value", v); }
            cr4 = v;
            tlb_flush();
        },
        8 => { cr8 = v & 15; },
        _ => { fault(6, false, 0); },
    }
}

fn msr_get(n: u64) -> u64 {
    match n {
        0x10 => { return steps; },
        0xC0000080 => { return efer; },
        0xC0000081 => { return msr_star; },
        0xC0000082 => { return msr_lstar; },
        0xC0000083 => { return msr_cstar; },
        0xC0000084 => { return msr_fmask; },
        0xC0000100 => { return fs_base; },
        0xC0000101 => { return gs_base; },
        0xC0000102 => { return msr_kernel_gs; },
        _ => { fault(13, true, 0); return 0; },
    }
}

fn msr_set(n: u64, v: u64) {
    match n {
        0x10 => {},
        0xC0000080 => {
            // Long mode stays on and active; SCE and NXE are the program's to set.
            if v & 0x100 == 0 { stop64("EFER written without LME: leaving long mode is not written, value", v); }
            if v & 0xFFFFFFFFFFFFF2FE != 0 { fault(13, true, 0); }
            efer = v & 0x901 | 0x500;
            tlb_flush();
        },
        0xC0000081 => { msr_star = v; },
        0xC0000082 => { msr_lstar = v; },
        0xC0000083 => { msr_cstar = v; },
        0xC0000084 => { msr_fmask = v; },
        0xC0000100 => { fs_base = v; },
        0xC0000101 => { gs_base = v; },
        0xC0000102 => { msr_kernel_gs = v; },
        _ => { fault(13, true, 0); },
    }
}

// ---- The instructions ----

// 0F 00: the task register and the LDT's selector.
fn sys_group6() {
    modrm(0);
    match m_reg & 7 {
        0 => { rm_set(if m_mod == 3 { osz } else { 16 }, ldt_sel); },
        1 => { rm_set(if m_mod == 3 { osz } else { 16 }, tr_sel); },
        2 => { need_level0(); ldt_sel = rm_get(16) as! u16; },
        3 => {
            // LTR: the TSS's descriptor is sixteen bytes; it is marked busy.
            need_level0();
            let sel = rm_get(16);
            if sel & 0xFFF8 == 0 || (sel | 15) > gdt_limit { fault(13, true, sel & 0xFFFC); }
            let at = gdt_base + (sel & 0xFFF8);
            let lo = own_rd(at, 64);
            let hi = own_rd(at + 8, 64);
            if lo >> 40 & 0xF != 9 { fault(13, true, sel & 0xFFFC); }
            if lo >> 47 & 1 == 0 { fault(11, true, sel & 0xFFFC); }
            tr_base = lo >> 16 & 0xFFFFFF | (lo >> 56 & 0xFF) << 24 | (hi & 0xFFFFFFFF) << 32;
            tr_limit = lo & 0xFFFF | (lo >> 48 & 0xF) << 16;
            tr_sel = sel as! u16;
            own_wr(at, 64, lo | (2 as u64) << 40);
        },
        _ => { stop64("an instruction not written yet, 0F 00 field", m_reg); },
    }
}

// 0F 01: the descriptor tables' registers, INVLPG, and the machine status word.
fn sys_group7() {
    modrm(0);
    let field = m_reg & 7;
    if m_mod == 3 {
        if field == 4 { sr(m_rm, osz, cr0); return; }
        if field == 7 && m_rm & 7 == 0 {
            // SWAPGS: GS's base and the one kept aside for the kernel change places.
            need_level0();
            let t = gs_base;
            gs_base = msr_kernel_gs;
            msr_kernel_gs = t;
            return;
        }
        stop64("an instruction not written yet, 0F 01 with a register, field", field);
    }
    match field {
        0 => { wr(m_ea, 16, gdt_limit); wr(m_ea + 2, 64, gdt_base); },
        1 => { wr(m_ea, 16, idt_limit); wr(m_ea + 2, 64, idt_base); },
        2 => { need_level0(); let l = rd(m_ea, 16); let b = rd(m_ea + 2, 64); gdt_limit = l; gdt_base = b; },
        3 => { need_level0(); let l = rd(m_ea, 16); let b = rd(m_ea + 2, 64); idt_limit = l; idt_base = b; },
        4 => { wr(m_ea, 16, cr0); },
        7 => { need_level0(); tlb_forget(m_ea); },
        _ => { stop64("an instruction not written yet, 0F 01 field", field); },
    }
}

// IRET: with a 64-bit operand size IRETQ, which is what 64-bit code uses.
fn iret() {
    let n: u64 = osz / 8;
    let sp = reg[RSP];
    let nrip = rd(sp, osz);
    let ncs = rd(sp + n, osz) & 0xFFFF;
    let nfl = rd(sp + 2 * n, osz);
    let nrsp = rd(sp + 3 * n, osz);
    let nss = rd(sp + 4 * n, osz) & 0xFFFF;
    let level = (ncs & 3) as! u8;
    if ncs & 0xFFF8 == 0 { fault(13, true, 0); }
    if level < cpl || (ncs | 7) > gdt_limit { fault(13, true, ncs & 0xFFFC); }
    // IOPL and IF are for privilege level 0 to change (IF also at a level IOPL allows).
    var can: u64 = 0x254DD5;
    if cpl == 0 { can |= 0x183200; }      // IOPL, IF, and the two virtual-interrupt bits
    else if cpl <= (rflags >> 12 & 3) { can |= 0x200; }
    rflags = rflags & ~can | nfl & can | 2;
    seg[SEG_CS] = ncs as! u16;
    seg[SEG_SS] = nss as! u16;
    if level > cpl {
        // A data segment register that the new level may not use is made null.
        for i: u8 in 6 {
            if i == SEG_CS || i == SEG_SS || seg[i] & 0xFFF8 == 0 { continue; }
            let desc = own_rd(gdt_base + (seg[i] & 0xFFF8), 64);
            if (desc >> 45 & 3) < level { seg[i] = 0; }
        }
    }
    cpl = level;
    reg[RSP] = nrsp;
    rip = nrip;
}

// SYSCALL: to privilege level 0 at the address in LSTAR, on the stack it came with. Where
// it came from is left in RCX and its flags in R11.
fn syscall_enter(ret: u64) {
    if efer & 1 == 0 { fault(6, false, 0); }
    by_syscall = true;
    reg[RCX] = ret;
    reg[11] = rflags;
    rflags &= ~msr_fmask;
    seg[SEG_CS] = (msr_star >> 32 & 0xFFFC) as! u16;
    seg[SEG_SS] = ((msr_star >> 32 & 0xFFFC) + 8) as! u16;
    cpl = 0;
    rip = msr_lstar;
}

// SYSRET with a 64-bit operand size: back to level 3 at the address in RCX with the flags
// in R11.
fn sysret() {
    if efer & 1 == 0 { fault(6, false, 0); }
    need_level0();
    if osz != 64 { stop64("SYSRET to compatibility mode, which is not written, operand bits", osz); }
    let top = reg[RCX] >> 47;
    if top != 0 && top != 0x1FFFF { fault(13, true, 0); }
    by_syscall = true;
    rflags = reg[11] & 0x3C7FD7 | 2;
    seg[SEG_CS] = ((msr_star >> 48) + 16 | 3) as! u16;
    seg[SEG_SS] = ((msr_star >> 48) + 8 | 3) as! u16;
    cpl = 3;
    rip = reg[RCX];
}

// The far return, to the same privilege level.
fn far_ret(extra: u64) {
    let n: u64 = osz / 8;
    let sp = reg[RSP];
    let nrip = rd(sp, osz);
    let ncs = rd(sp + n, osz) & 0xFFFF;
    if ncs & 0xFFF8 == 0 { fault(13, true, 0); }
    if (ncs & 3) as! u8 != cpl { stop64("a far return to another privilege level, which is not written, selector", ncs); }
    if (ncs | 7) > gdt_limit { fault(13, true, ncs & 0xFFFC); }
    seg[SEG_CS] = ncs as! u16;
    reg[RSP] = sp + 2 * n + extra;
    rip = nrip;
}
