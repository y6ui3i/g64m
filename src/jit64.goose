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
extern fn jit_now() -> i64;
extern fn jit_write(at: i64, code: const u8[:]);
extern fn jit_addr_u64(a: const u64[:]) -> i64;
extern fn jit_addr8(a: const u8[:]) -> i64;
extern fn jit_addr32(a: const u32[:]) -> i64;
extern fn jit_addr_any(a: const Entry[:]) -> i64;
extern fn jit_peek64(at: i64) -> i64;
extern fn jit_x87_addr() -> i64;
extern fn jit_call4(enter: i64, a: i64, b: i64, c: i64, d: i64) -> i64;

var jit_on = false;
var jit_check = false;       // --jit-check: every block is run both ways and compared
var jit_dump_arg = 0;        // --jit-dump FILE: which argument names the file, or 0
var jit_stats = false;       // --jit-stats: what the JIT did, on standard error at the end
var jit_hold = false;        // blocks are not entered (the check's second way)
var jit_no: u64 = 0;         // --jit-off: a bit for each group of kinds not to translate
var j_mem = 0;               // where the code is mapped
var j_used = 0;              // how much of it holds code
var j_keep = 0;              // how much of that is the way in and out
var j_out_at = 0;
var j_fark_at: i64[2] = [0; 2];      // the far way in a machine, for privilege levels 0 and 3; 0 if not built
var j_far_at = 0;            // the far way: to the block at the address in x1, if there is one; 0 if not built
// The blocks' own table (E166): every block by its first instruction's physical address,
// in sets of four: where its code is, and its length, level and whether it reads RFLAGS
// in memory. A block is entered through its first instruction's entry in the decode
// cache, and that entry is given up when another instruction wants it; the block is
// still right, and when its first instruction is next decoded the new entry gets the
// block back from here (decode, cpu64.goose), where before the address was interpreted
// eight times over and translated again. Emptied when the blocks are forgotten; a page
// written to loses its own.
let BT_BITS = 19;
let BT_SIZE = 4 << BT_BITS;
var bt_back: u64 = 0;        // blocks given back to a new entry
var bt_lost: u64 = 0;        // blocks that lost their place in this table to another

inline fn bt_set(ph: u64) -> i64 { return (((ph ^ ph >> BT_BITS) & ((1 << BT_BITS) - 1)) as! i64) * 4; }

// The place of the block that begins at ph, or -1.
fn bt_find(ph: u64) -> i64 {
    let s = bt_set(ph);
    for k in 4 { if bt_tag[s + k] == ph { return s + k; } }
    return -1;
}

fn bt_put(ph: u64, code: u32, n: u8, level: u8, needs: bool) {
    let s = bt_set(ph);
    var at = -1;
    for k in 4 { if bt_tag[s + k] == ph { at = s + k; } }
    if at < 0 { for k in 4 { if at < 0 && bt_tag[s + k] == 0xFFFFFFFFFFFFFFFF { at = s + k; } } }
    if at < 0 { at = s + (code >> 2 & 3); bt_lost += 1; }
    bt_tag[at] = ph;
    bt_code[at] = code;
    bt_what[at] = n | (level as u32) << 8 | (if needs { 0x10000 } else { 0 });
}

// The decode cache's entry `slot` has just been made for the instruction at the block's
// first: the block is the entry's again.
// The place of the block that begins at ph and was made at this level, or -1.
fn bt_at(ph: u64, level: u8) -> i64 {
    let at = bt_find(ph);
    if at >= 0 && (bt_what[at] >> 8 & 0xFF) as! u8 == level { return at; }
    return -1;
}

fn bt_attach(at: i64, slot: i64) {
    let w = bt_what[at];
    // The exits that came to wait for this address while its block had no entry are
    // made branches to it now (E180), as they are when a block is made: they were left
    // waiting for good, and each use of one was a trip through the interpreter.
    if jit_no2 & 1024 == 0 { j_wake(dc[slot].tag, bt_code[at], (w >> 8 & 0xFF) as! u8); }
    dc_code[slot] = bt_code[at];
    dc_n[slot] = (w & 0xFF) as! u8;
    dc_cpl[slot] = (w >> 8 & 0xFF) as! u8;
    dc_needs[slot] = (w >> 16 & 1) as! u8;
    dc_k0[slot] = dc[slot].ins.kind;
    dc[slot].ins.kind = 0;
    bt_back += 1;
}

fn bt_drop_page(page: i64) {
    let base = (page << 12) as! u64;
    for k in 4096 {
        let at = bt_find(base + (k as! u64));
        if at >= 0 { bt_tag[at] = 0xFFFFFFFFFFFFFFFF; }
    }
}

fn bt_clear() {
    for i in BT_SIZE { bt_tag[i] = 0xFFFFFFFFFFFFFFFF; }
}

// The table of where blocks are (E165): JT_SIZE pairs for each privilege level of a machine
// (a program uses the first), the address jumped to and where its block's code is, chosen
// by the address's low bits. An exit that would take the far way calls jt_at's routine,
// which leaves the block's address in x29 and comes back for the exit's own `br` (so the
// host learns each exit's jumps by itself); an address the table does not hold goes on to
// the far way, which puts what it finds in the table. Emptied (jt_clear) when the TLB is,
// when a page with blocks is written to and when the blocks are forgotten: an address may
// then mean another page, or the code there be wrong. A block whose entry the decode cache
// gave up stays in the table: it is right code for its page until the page is written.
let JT_BITS = 12;
let JT_SIZE = 1 << JT_BITS;
var jt_at: i64[3] = [0; 3];          // the routines: a machine's levels 0 and 3, a program
// A cell for each exit to a constant address on another page (E178): where its block is,
// or where the exit's own instructions that ask the far way are (jcell_home). The cells
// filled since the table of blocks was last emptied are on jdirty (their count is jx[39],
// which generated code moves on), and jt_clear puts those back: a cell is right for as
// long as a pair of the table is. The arrays are at the end of cpu64.goose.
let JC_SIZE = 1 << 20;
let JD_SIZE = 262144;       // (as many as there can be cells in an afternoon of the build: 162 thousand)
var jcell_n = 0;
var jcell_far: i64[2] = [0; 2];      // the far way that fills a cell, for levels 0 and 3
var jit_no2: u64 = 0;                // --jit-off2: bit 0 the table of where blocks are

// x2: which pair the address in x1 chooses.
let JT_FOLD = 0;
fn jt_idx() {
    if JT_FOLD == 0 { e(0x92400000 | ((JT_BITS - 1) as! u32) << 10 | S1 << 5 | S2); return; }     // and x2, x1, #(JT_SIZE - 1)
    e(0xCA400000 | S1 << 16 | (JT_FOLD as! u32) << 10 | S1 << 5 | S2);                             // eor x2, x1, x1, lsr #JT_FOLD
    e(0x92400000 | ((JT_BITS - 1) as! u32) << 10 | S2 << 5 | S2);
}

// No pair holds an address: each tag is one its own place is not chosen by.
var jt_clears: i64[4] = [0; 4];
var jh_bytes: i64[2] = [0; 2];        // --jit-why: bytes of blocks made, and of them before the first way out behind the block       // --jit-why: emptied with something in it; and the cells put back, in all
fn jt_clear() {
    if jit_why && (jx[39] != 0 || jx[32] != 0) { jt_clears[0] += 1; jt_clears[1] += jx[39] as! i64; }
    // The cells filled since the last time (E178) ask again.
    let nd = jx[39] as! i64;
    for i in nd { let c: i64 = jdirty[i]; jcell[c] = (j_mem + jcell_home[c]) as! u64; }
    jx[39] = 0;
    // (Only if the far way has put something in since the last time: jx[32].)
    if jx[32] == 0 { return; }
    jx[32] = 0;
    for i in 2 * JT_SIZE { jt[i * 2] = 0; }
    // (Place 0 is chosen by 0 with or without the fold; 1 chooses place 1.)
    jt[0] = 1;
    jt[JT_SIZE * 2] = 1;
}
var j_regs = 0;
var j_ctx = 0;
var j_blocks = 0;            // blocks translated
var j_entered: u64 = 0;      // times one was entered
var j_ran: u64 = 0;          // guest instructions executed in blocks
var j_flushes = 0;
// --jit-time (E141): the clock around the translator, around the entry and around the
// block's own run; what one reading of the clock costs; and how often each block was run,
// counted by the block itself, tallied at each flush and at the end.
var jit_time = false;
var jt_translate: i64 = 0;
var jt_enter: i64 = 0;
var jt_body: i64 = 0;
var jt_clock: i64 = 0;
var jr_never: i64 = 0;
var jr_few: i64 = 0;
var jr_many: i64 = 0;
// --jit-why (E144): where each block went when it was left, by the standing of that
// address: 0 another page, 1 not in the decode cache, 2 in it and cold, 3 in it, hot and
// no block (by kind in jw_kind, and for no kind by the byte behind 0Fh in jw_0f, 256 for
// one not behind 0Fh), 4 inside a block, 5 a block's first instruction with no time left
// for it, 6 the same with time.
var jit_why = false;
var jw: i64[8] = [0; 8];
var jw_kind: i64[64] = [0; 64];

// The same for an address on another page, found as the far way finds it (the TLB's table
// for fetches at this level): jw2, with 0 for one not in the TLB; and of the blocks that
// were there with time left, how many read RFLAGS in memory and had a record waiting
// (jw_rec), for this page and for another.
var jw2: i64[8] = [0; 8];
// What the interpreter itself runs (E151): 0 not in the decode cache (a first run, or an
// entry lost), 1 a block's first instruction (the block refused, or left at once), 2
// inside a block, 3 in no block and cold, 4 in no block and hot (refused: by kind in
// ji_kind, for no kind by the byte behind 0Fh in ji_0f, 256 for one not behind 0Fh).
var ji: i64[8] = [0; 8];
var ji_kind: i64[64] = [0; 64];

fn jit_ran_one(slot: i64, ph: u64) {
    if dc_n[slot] != 0 { ji[1] += 1; return; }
    if dc_cov[slot] != 0 { ji[2] += 1; return; }
    if dc_heat[slot] < J_HOT { ji[3] += 1; return; }
    ji[4] += 1;
    // (Of those with a kind: how many lie across the page's end, by whether their
    // operand's length was ever remembered and where they begin; and by the last
    // fifteen bytes of the page.)
    if dc[slot].ins.kind != 0 {
        if dc[slot].ins.mlen == 0 && (ph & 0xFFF) >= 0xFF1 { ji[5] += 1; }
        else if (ph & 0xFFF) >= 0xFF1 { ji[6] += 1; }
        else { ji[7] += 1; }
    }
    let k: i64 = dc[slot].ins.kind;
    ji_kind[k & 63] += 1;
    if k == 0 {
        if dc[slot].ins.op == 0x0F {
            let o2 = mem_rd(ph + dc[slot].ins.plen, 8) as! i64;
            ji_0f[o2] += 1;
            // (The byte behind, for the groups: 0F 01, 0F AE, 0F BA, 0F C7.)
            if o2 == 0x01 || o2 == 0xAE || o2 == 0xBA || o2 == 0xC7 { ji_grp[(if o2 == 0x01 { 0 } else if o2 == 0xAE { 256 } else if o2 == 0xBA { 512 } else { 768 }) + (mem_rd(ph + dc[slot].ins.plen + 1, 8) as! i64)] += 1; }
        }
        else { ji_0f[256] += 1; ji_op[dc[slot].ins.op as i64 + (if dc[slot].ins.rep != 0 { 256 } else { 0 })] += 1; }
    }
}
// How often each address has come to the interpreter with no entry (E167), by a hash of
// the address with no tag: at the J_HOT-th time a block is made there, once the
// instruction has been run and its entry knows its operand. An instruction is otherwise an
// arrival only when it is run from its entry, and one that shares its set of the cache
// with two that are run as often never is. (Two addresses with one count: the block is
// made for whichever comes at that time, and the other's is made when it is run from its
// entry, as before.) Counted from nothing when the blocks are forgotten.
let JH_BITS = 22;
var jit_miss_hot = false;    // the instruction just decoded is at its J_HOT-th time
var jh_made: u64 = 0;        // blocks made that way
var jw_rec: i64[2] = [0; 2];
// --jit-why: where the look for dead flags ended, as blocks were translated: 0 dead, 1 the
// page's end, 2 an instruction with no entry, 3 one that is neither (it reads flags, or
// is not known), 4 a conditional jump, 5 CALL or JMP, 6 RET or a jump through an
// operand, 7 CMOVcc or SETcc, 8 twelve instructions.
var jf: i64[9] = [0; 9];
// --jit-why: how often each address has come to the interpreter with no entry (by a hash
// of the address, with no tag: a count, not a proof), and the arrivals by that number; and
// of those, how many got a block back (E166).
var jm_hist: i64[6] = [0; 6];
var jm_why: i64[2] = [0; 2];
fn jit_missed(ph: u64) {
    let h = ((ph ^ ph >> 22) & 4194303) as! i64;
    let c = jm_n[h];
    jm_hist[if c == 0 { 0 } else if c < 8 { 1 } else if c < 32 { 2 } else if c < 128 { 3 } else { 4 }] += 1;
    if c < 255 { jm_n[h] = c + 1; }
}
var jq: i64[8] = [0; 8];
var jq_k: i64[64] = [0; 64];

fn jit_went() {
    var ph = rip - code_delta;
    var far = 0;
    if rip >> 12 != code_page {
        far = 1;
        if !machine || (cpl != 0 && cpl != 3) { jw[0] += 1; return; }
        let page = rip >> 12;
        let at = (((if cpl == 0 { 4 } else { 5 }) << 12) | (page & 0xFFF)) as! i64;
        if tlb_tag[2 * at] != page { jw[0] += 1; jw2[0] += 1; return; }
        ph = rip + tlb_tag[2 * at + 1];
        jw[0] += 1;
    }
    let s = dc_find(ph);
    if dc[s].tag != ph { if far == 1 { jw2[1] += 1; } else { jw[1] += 1; } return; }
    if dc_n[s] != 0 {
        let late = steps + dc_n[s] > rep_until;
        if far == 1 { if late { jw2[5] += 1; } else { jw2[6] += 1; } }
        else if late { jw[5] += 1; } else { jw[6] += 1; }
        if !late && dc_needs[s] != 0 && jx[3] != 0 { jw_rec[far] += 1; jw_rk[(if jx[3] >> 16 != 0 { 255 } else { jx[3] & 0xFF }) as! i64] += 1; }
        if !late && dc_cpl[s] != cpl { jw2[7] += 1; }
        return;
    }
    if far == 1 {
        if dc_cov[s] != 0 { jw2[4] += 1; return; } else if dc_heat[s] < J_HOT { jw2[2] += 1; return; } else { jw2[3] += 1; }
    } else {
        if dc_cov[s] != 0 { jw[4] += 1; return; }
        if dc_heat[s] < J_HOT { jw[2] += 1; return; }
        jw[3] += 1;
    }
    // (By kind and form for both, this page's and another's.)
    if dc[s].ins.kind != 0 {
        let h = ((ph ^ ph >> 13) & 8191) as! i64;
        if jn_ph[h] != ph { jn_ph[h] = ph; jn_n[h] = 0; }
        jn_n[h] += 1;
    }
    let k: i64 = dc[s].ins.kind;
    jw_kind[k & 63] += 1;
    if k != 0 && k < 64 { jw_form[k * 64 + ((dc[s].ins.reg & 7) as i64) * 8 + (if dc[s].ins.mod == 3 { 4 } else { 0 }) + (if dc[s].ins.p66 { 2 } else { 0 }) + (if dc[s].ins.rep != 0 { 1 } else { 0 })] += 1; }
    if k == 0 {
        let op: i64 = dc[s].ins.op;
        if op == 0x0F { jw_0f[mem_rd(ph + dc[s].ins.plen, 8) as! i64] += 1; }
        else { jw_0f[256] += 1; jw_op[op] += 1; }
    }
}
var j_bytes: u64 = 0;        // bytes of code written in all, flushed or not (E137)
let J_SIZE = 134217728;      // 128 MB: as far as a `b` reaches (E137)
var J_HOT: u8 = 8;           // arrivals at an instruction (runs of it from the decode cache) before a block is made there; --jit-hot
let J_MAX = 60;              // instructions in a block at most
let J_MIN = 2;               // and at least
var cv_slot: i64[J_MAX] = [0; J_MAX];    // the entries of the block being made (for dc_cov)

// What a block is given and gives back: [0] RFLAGS in, [1] [2] [3] the flags' record,
// [4] the next RIP, [5] where the memory is, [6] where dc_mark is, [7] how many stores
// are in the log and [8] where the log is, [9] the time left, in and out, [10] where the
// guest's registers are, [11] the decode cache, [12] dc_n, [13] dc_code and [14] the
// mapping, for the far way, [15] whether the flags are stale (--jit-check), [16] where the
// XMM registers are, [17] and [18] the bases of FS and GS, [19] and [20] where the TLB's
// tags and its physical pages are (a machine's loads and stores), [21] dc_cpl, [22] not
// zero when the SSE unit is not to be used (E139: a machine's CR0.TS or EM set, or
// CR4.OSFXSR clear; the interpreter faults), [23] dc_runs (--jit-time), [24] set by a way
// out that leaves an instruction to the interpreter (E155).
// [33] the GS base kept aside (SWAPGS in a block) and [34] the count of instructions the run
// may come to (RDTSC in a block), E176; [32] not zero when the far way has put something
// in the table of blocks since it was emptied (E165).
var pad_jx: u8[6] = [0; 6];      // (jx at a multiple of 8 in the block: tools/layout.sh, E173)
var jx: u64[48] = [0; 48];
// --jit-check: each store's address and the eight bytes that were there.

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

// The host registers whose value has been found to be an address a block may read eight
// bytes at (ck_r), or store eight bytes at (ck_w), since the block's start (E164): a
// plain move through such a register again needs no test. Every instruction generated
// takes the register in its low five bits out of both, which is the one it writes if it
// writes one (and LDP's second is taken out there); a block is one straight line, and
// the pages' marks do not change while it runs.
// The operand whose address x1 is known to be (E184): its base, index, scale and constant,
// the host registers of the first two (32 for none), whether it has been tested for a
// read, and for a write of how many bytes.
var ma_ok = false;
var ma_base: u8 = 16;
var ma_index: u8 = 16;
var ma_scale: u8 = 0;
var ma_rd = false;
var pad_ma: u8[3] = [0; 3];     // (eight bytes with the five above: tools/layout.sh)
var ma_disp: u64 = 0;
var ma_hb: u32 = 32;
var ma_hi: u32 = 32;
var ma_wn: u32 = 0;
var pad_ma2: u32 = 0;
var ck_r: u32 = 0;
var ck_w: u32 = 0;

fn e(w: u32) {
    let gone: u32 = ~((1 as u32) << (w & 31));
    ck_r &= gone;
    ck_w &= gone;
    // (E184: x1 is no longer the address of the operand last made if x1, the operand's
    // base or its index is written; a call leaves nothing known.)
    if ma_ok {
        let rd = w & 31;
        if rd == S1 || rd == ma_hb || rd == ma_hi || w & 0xFC000000 == 0x94000000 { ma_ok = false; }
    }
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
    // From all ones (MOVN) where more of its four parts are FFFFh than are zero (E164:
    // a small negative number is one instruction, not four).
    var ones = 0;
    var zeros = 0;
    for h in 4 {
        let part = v >> ((h as! u64) * 16) & 0xFFFF;
        if part == 0xFFFF { ones += 1; } else if part == 0 { zeros += 1; }
    }
    if ones > zeros {
        e(0x92800000 | ((~v & 0xFFFF) as! u32) << 5 | rd);                   // movn
        for h in 3 {
            let hw = (h as! u64) + 1;
            let part = (v >> (hw * 16) & 0xFFFF) as! u32;
            if part != 0xFFFF { e(0xF2800000 | (hw as! u32) << 21 | part << 5 | rd); }
        }
        return;
    }
    e(0xD2800000 | ((v & 0xFFFF) as! u32) << 5 | rd);
    for h in 3 {
        let hw = (h as! u64) + 1;
        let part = (v >> (hw * 16) & 0xFFFF) as! u32;
        if part != 0 { e(0xF2800000 | (hw as! u32) << 21 | part << 5 | rd); }
    }
}
// One run of ones in x, which is not zero: where it begins and how long it is; a length
// of 0 if the ones are not one run.
fn a_run(x: u64) -> u64, u64 {
    var tz: u64 = 0;
    while (x >> tz) & 1 == 0 { tz += 1; }
    var n: u64 = 0;
    while tz + n < 64 && (x >> (tz + n)) & 1 == 1 { n += 1; }
    if tz + n < 64 && (x >> (tz + n)) != 0 { return 0, 0; }
    return tz, n;
}

// The constant v as the host's AND, ORR and EOR take one (E163): N, immr and imms as they
// stand at bit 10 of the instruction, or 0xFFFFFFFF if v is not one the host can encode
// (a run of ones, turned round, repeated at 2, 4, 8, 16, 32 or 64 bits). For a 32-bit
// operation only v's low half counts.
fn a_logimm(v0: u64, sf: u32) -> u32 {
    var v = v0;
    if sf == 0 { v = v & 0xFFFFFFFF; v |= v << 32; }
    if v == 0 || v == 0xFFFFFFFFFFFFFFFF { return 0xFFFFFFFF; }
    var size: u64 = 64;
    while size > 2 {
        let half = size >> 1;
        let hm: u64 = ((1 as u64) << half) - 1;
        if (v & hm) != ((v >> half) & hm) { break; }
        size = half;
    }
    let mask: u64 = if size == 64 { 0xFFFFFFFFFFFFFFFF } else { ((1 as u64) << size) - 1 };
    let elt = v & mask;
    var start, ones = a_run(elt);
    if ones == 0 {
        // The run goes round the end: the zeros are one run.
        let zs, zn = a_run(~elt & mask);
        if zn == 0 { return 0xFFFFFFFF; }
        start = zs + zn;
        ones = size - zn;
    }
    let immr = (size - start) & (size - 1);
    let nimms = ((~(size - 1) << 1) | (ones - 1)) & 0x7F;
    let n = ((nimms >> 6) & 1) ^ 1;
    return (n << 12 | immr << 6 | (nimms & 0x3F)) as! u32;
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
fn a_ldp(r1: u32, r2: u32, rn: u32, off: u32) { e(0xA9400000 | (off >> 3) << 15 | r2 << 10 | rn << 5 | r1); ck_r = 0; ck_w = 0; ma_ok = false; }
fn a_stp(r1: u32, r2: u32, rn: u32, off: u32) { e(0xA9000000 | (off >> 3) << 15 | r2 << 10 | rn << 5 | r1); }

// Branches to a place already generated: b, b.cond, cbnz.
fn e_b(to: i64) { e(0x14000000 | (((to - jc.len) >> 2) as! u32) & 0x3FFFFFF); }
fn e_bc(c: u32, to: i64) { e(0x54000000 | ((((to - jc.len) >> 2) as! u32) & 0x7FFFF) << 5 | c); }

// The record settled in generated code (E146): called (bl) from the way into a block that
// reads RFLAGS in memory, when a record is waiting. For a record of ADD, SUB, CMP, AND,
// TEST, OR or XOR at any width it makes the six flags as alu (cpu64.goose) does, puts
// them into RFLAGS in memory, clears the record and returns; for any other it goes out,
// as such an entry always did. x2, x3, x4 and x29 are used; x0 (the time), x1 (RIP) and
// the guest's registers are not touched.
var j_settle_at = 0;
var j_leave_at: i64 = 0;      // the routine a way out that leaves an instruction to the interpreter calls (E179)
var j_mark_at: u64 = 0;
fn j_settle_make() {
    let fail = jc.len;
    e_b(j_out_at);
    // The end: the parity of the result's low byte (in x2), the flags (in x7) into
    // RFLAGS, the record cleared.
    let parity = jc.len;
    e(0xCA400000 | S2 << 16 | 4 << 10 | S2 << 5 | S3);       // eor x3, x2, x2, lsr #4
    e(0xCA400000 | S3 << 16 | 2 << 10 | S3 << 5 | S3);       // eor x3, x3, x3, lsr #2
    e(0xCA400000 | S3 << 16 | 1 << 10 | S3 << 5 | S3);       // eor x3, x3, x3, lsr #1
    e(0xD2400000 | S3 << 5 | S3);                            // eor x3, x3, #1: PF is set for an even count
    e(0x92400000 | S3 << 5 | S3);                            // and x3, x3, #1
    e(0xAA000000 | S3 << 16 | 2 << 10 | FK << 5 | FK);       // orr x7, x7, x3, lsl #2
    a_ldr(29, CTX, 0);
    a_imm(S3, 0x8D5);
    a_rrr(0x0A200000, 1, 29, 29, S3);                        // bic
    a_rrr(A_ORR, 1, 29, 29, FK);
    a_str(29, CTX, 0);
    a_mov(1, FK, ZR);
    e(0xD65F03C0);                                           // ret
    // After ADDS or SUBS of the operands shifted up (x2 the result, x7 the carry, x4 the
    // shift): OF, ZF and SF from the host's flags, AF from bit 4 of the three values.
    let arith = jc.len;
    e(0x1A9F07E0 | (C_VS ^ 1) << 12 | S3);                   // cset w3, vs
    e(0xAA000000 | S3 << 16 | 11 << 10 | FK << 5 | FK);
    e(0x1A9F07E0 | (C_EQ ^ 1) << 12 | S3);
    e(0xAA000000 | S3 << 16 | 6 << 10 | FK << 5 | FK);
    e(0x1A9F07E0 | (C_MI ^ 1) << 12 | S3);
    e(0xAA000000 | S3 << 16 | 7 << 10 | FK << 5 | FK);
    a_shiftv(5, 1, S2, S2, S4);                              // the result, down again
    a_rrr(A_EOR, 1, S3, FA, FB);
    a_rrr(A_EOR, 1, S3, S3, S2);
    e(0x927C0000 | S3 << 5 | S3);                            // and x3, x3, #0x10
    a_rrr(A_ORR, 1, FK, FK, S3);
    e_b(parity);
    // After AND, OR or XOR (x2 the result): ZF and SF of it at its width; no carry.
    let logic = jc.len;
    a_shiftv(4, 1, S3, S2, S4);
    a_rrr(A_ANDS, 1, ZR, S3, S3);
    e(0x1A9F07E0 | (C_EQ ^ 1) << 12 | FK);
    a_shifti(4, 1, FK, FK, 6);
    e(0x1A9F07E0 | (C_MI ^ 1) << 12 | S3);
    e(0xAA000000 | S3 << 16 | 7 << 10 | FK << 5 | FK);
    e_b(parity);
    let add = jc.len;
    a_rrr(A_ADDS, 1, S2, 29, S3);
    e(0x1A9F07E0 | (C_HS ^ 1) << 12 | FK);                   // cset w7, cs: a carry out
    e_b(arith);
    let sub = jc.len;
    a_rrr(A_SUBS, 1, S2, 29, S3);
    e(0x1A9F07E0 | (C_LO ^ 1) << 12 | FK);                   // cset w7, cc: a borrow
    e_b(arith);
    let and = jc.len;
    a_rrr(A_AND, 1, S2, FA, FB);
    e_b(logic);
    let or = jc.len;
    a_rrr(A_ORR, 1, S2, FA, FB);
    e_b(logic);
    let xor = jc.len;
    a_rrr(A_EOR, 1, S2, FA, FB);
    e_b(logic);
    // E172: the records of SHL, SHR and SAR at 32 and 64 bits, of BT, and of INC and DEC,
    // as shift, the BT arm of j_settle and incdec (cpu64.goose) make their flags.
    //
    // ZF and SF of the result in x2 at its width, onto what x7 holds; then the parity.
    let zs = jc.len;
    a_shiftv(4, 1, S3, S2, S4);
    a_rrr(A_ANDS, 1, ZR, S3, S3);
    e(0x1A9F07E0 | (C_EQ ^ 1) << 12 | S3);
    e(0xAA000000 | S3 << 16 | 6 << 10 | FK << 5 | FK);
    e(0x1A9F07E0 | (C_MI ^ 1) << 12 | S3);
    e(0xAA000000 | S3 << 16 | 7 << 10 | FK << 5 | FK);
    e_b(parity);
    // A count of nothing changes no flag: the record is cleared.
    let none = jc.len;
    a_mov(1, FK, ZR);
    e(0xD65F03C0);
    // The shifts' way in (x2 the kind, x4 64 less the width): the count in x6, of the
    // width's bits; and by the kind. 16 and 8 bits are the interpreter's.
    var sh_at: i64[3] = [0; 3];
    for k in 3 {
        sh_at[k] = jc.len;
        a_addi(0x71, 1, ZR, S4, 32);
        e_bc(C_HI, fail);
        a_imm(S3, 63);
        a_rrr(A_SUB, 1, S3, S3, S4);                         // the width less one
        a_rrr(A_AND, 1, FB, FB, S3);
        e(0xB4000000 | ((((none - jc.len) >> 2) as! u32) & 0x7FFFF) << 5 | FB);  // cbz x6, none
        a_shiftv(4, 1, 29, FA, S4);
        if k == 2 { a_shiftv(7, 1, 29, 29, S4); } else { a_shiftv(5, 1, 29, 29, S4); }      // the operand, at its width (SAR: with its sign)
        if k == 0 {
            // SHL: CF the last bit out at the top; OF the top two bits differing.
            a_addi(0x11, 1, S2, S3, 1);
            a_rrr(A_SUB, 1, S2, S2, FB);                     // the width less the count
            a_shiftv(5, 1, S2, 29, S2);
            e(0x92400000 | S2 << 5 | FK);                    // and x7, x2, #1
            e(0xCA000000 | 29 << 16 | 1 << 10 | 29 << 5 | S2);       // eor x2, x29, x29, lsl #1
            a_shiftv(5, 1, S2, S2, S3);
            e(0x92400000 | S2 << 5 | S2);
            e(0xAA000000 | S2 << 16 | 11 << 10 | FK << 5 | FK);
            a_shiftv(4, 1, S2, 29, FB);
        } else {
            // SHR and SAR: CF the last bit out at the bottom; OF the top bit for SHR,
            // clear for SAR.
            a_addi(0x51, 1, S2, FB, 1);
            a_shiftv(5, 1, S2, 29, S2);
            e(0x92400000 | S2 << 5 | FK);                    // and x7, x2, #1
            if k == 1 {
                a_shiftv(5, 1, S2, 29, S3);
                e(0xAA000000 | S2 << 16 | 11 << 10 | FK << 5 | FK);
                a_shiftv(5, 1, S2, 29, FB);
            } else { a_shiftv(7, 1, S2, 29, FB); }
        }
        e_b(zs);
    }
    // BT: CF is the bit, and no other flag changes.
    let bt = jc.len;
    a_imm(S3, 63);
    a_rrr(A_SUB, 1, S3, S3, S4);
    a_rrr(A_AND, 1, S3, FB, S3);
    a_shiftv(5, 1, S3, FA, S3);
    e(0x92400000 | S3 << 5 | S3);
    a_ldr(29, CTX, 0);
    e(0x927FF800 | 29 << 5 | 29);                            // and x29, x29, #~1
    a_rrr(A_ORR, 1, 29, 29, S3);
    a_str(29, CTX, 0);
    a_mov(1, FK, ZR);
    e(0xD65F03C0);
    // INC and DEC: ADD and SUB of one, with CF as it was (x29 the operand shifted up).
    var id_at: i64[2] = [0; 2];
    for k in 2 {
        id_at[k] = jc.len;
        a_imm(FB, 1);
        a_shiftv(4, 1, S3, FB, S4);
        a_rrr(if k == 0 { A_ADDS } else { A_SUBS }, 1, S2, 29, S3);
        a_ldr(S3, CTX, 0);                                   // (neither changes the host's flags)
        e(0x92400000 | S3 << 5 | FK);                        // and x7, x3, #1
        e_b(arith);
    }
    // The way in: nothing above the width (ADC's carry, a count); the shift that brings
    // the width's top bit to bit 63; the operands shifted up; and by the record's kind.
    j_settle_at = jc.len;
    a_shifti(5, 1, S2, FK, 16);
    e(0xB5000000 | ((((fail - jc.len) >> 2) as! u32) & 0x7FFFF) << 5 | S2);      // cbnz x2, fail
    e(0x92401C00 | FK << 5 | S2);                            // and x2, x7, #0xFF: the kind
    e(0xD3400000 | 8 << 16 | 15 << 10 | FK << 5 | S3);       // ubfx x3, x7, #8, #8: the width
    a_imm(S4, 64);
    a_rrr(A_SUB, 1, S4, S4, S3);
    a_shiftv(4, 1, 29, FA, S4);
    a_shiftv(4, 1, S3, FB, S4);
    a_addi(0x71, 1, ZR, S2, 8); e_bc(C_EQ, sub);             // CMP
    a_addi(0x71, 1, ZR, S2, 5); e_bc(C_EQ, and);             // AND, TEST
    a_addi(0x71, 1, ZR, S2, 6); e_bc(C_EQ, sub);
    a_addi(0x71, 1, ZR, S2, 1); e_bc(C_EQ, add);
    a_addi(0x71, 1, ZR, S2, 2); e_bc(C_EQ, or);
    a_addi(0x71, 1, ZR, S2, 7); e_bc(C_EQ, xor);
    if jit_no2 & 32 == 0 {
        a_addi(0x71, 1, ZR, S2, 0x25); e_bc(C_EQ, sh_at[1]);
        a_addi(0x71, 1, ZR, S2, 0x24); e_bc(C_EQ, sh_at[0]);
        a_addi(0x71, 1, ZR, S2, 0x27); e_bc(C_EQ, sh_at[2]);
        a_addi(0x71, 1, ZR, S2, 0x50); e_bc(C_EQ, bt);
        a_addi(0x71, 1, ZR, S2, 17); e_bc(C_EQ, id_at[1]);
        a_addi(0x71, 1, ZR, S2, 16); e_bc(C_EQ, id_at[0]);
    }
    e_b(fail);
}

// Maps the room for code and writes the way in and the way out. False if there is none
// (a host that is not arm64).
fn jit64_init() -> bool {
    j_mem = jit_alloc(J_SIZE);
    if j_mem == 0 { return false; }
    j_regs = jit_addr_u64(reg[..]);
    j_ctx = jit_addr_u64(jx[..]);
    jx[5] = jit_addr8(mem[..]) as! u64;
    j_mark_at = jit_addr8(dc_mark[..]) as! u64;
    jx[6] = j_mark_at;
    jx[8] = jit_addr_u64(jlog[..]) as! u64;
    jx[10] = j_regs as! u64;
    jx[16] = jit_addr_u64(xmm[..]) as! u64;
    jx[19] = jit_addr_u64(tlb_tag[..]) as! u64;
    jx[23] = jit_addr32(dc_runs[..]) as! u64;
    jx[25] = jit_x87_addr() as! u64;
    if jit_time {
        let t0 = jit_now();
        for i in 1000000 { jit_now(); }
        jt_clock = (jit_now() - t0) / 1000000;
    }
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
    if laid {
        jx[11] = dc_at as! u64;
        jx[12] = jit_addr8(dc_n[..]) as! u64;
        jx[13] = jit_addr32(dc_code[..]) as! u64;
        jx[14] = j_mem as! u64;
        let out_back: u32 = (((j_out_at - jc.len) >> 2) as! u32) & 0x3FFFFFF;
        let to_out = jc.len;
        e(0x14000000 | out_back);                            // b the way out
        j_far_at = jc.len;
        e(0xCA400000 | S1 << 16 | (DC_BITS as! u32) << 10 | S1 << 5 | S2);       // eor x2, x1, x1, lsr #DC_BITS
        e(0x92400000 | ((DC_BITS - 1) as! u32) << 10 | S2 << 5 | S2);            // and x2, x2, #(DC_SIZE - 1)
        // Either way of the set (E142): the slot, then its neighbour.
        a_ldr(S4, CTX, 88);
        e(0x8B001400 | S2 << 16 | S4 << 5 | S3);             // add x3, x4, x2, lsl #5
        a_ldr(S3, S3, 0);
        a_rrr(A_SUBS, 1, ZR, S3, S1);                        // cmp x3, x1
        e(0x54000000 | 6 << 5);                              // b.eq found, six on
        e(0xD2400000 | S2 << 5 | S2);                        // eor x2, x2, #1
        e(0x8B001400 | S2 << 16 | S4 << 5 | S3);
        a_ldr(S3, S3, 0);
        a_rrr(A_SUBS, 1, ZR, S3, S1);
        e(0x54000001 | ((((to_out - jc.len) >> 2) as! u32) & 0x7FFFF) << 5);     // b.ne out
        a_ldr(S3, CTX, 96);
        e(0x38606800 | S2 << 16 | S3 << 5 | S3);             // ldrb w3, [x3, x2]
        e(0x34000000 | ((((to_out - jc.len) >> 2) as! u32) & 0x7FFFF) << 5 | S3);    // cbz w3, out
        a_ldr(S3, CTX, 104);
        e(0xB8607800 | S2 << 16 | S3 << 5 | S3);             // ldr w3, [x3, x2, lsl #2]
        a_ldr(S4, CTX, 112);
        a_rrr(A_ADD, 1, S3, S4, S3);
        if jit_no2 & 1 == 0 {
            // Into the table, and back to the exit that called (x30 is still its).
            a_ldr(29, CTX, 232);
            jt_idx();
            e(0x8B001000 | S2 << 16 | 29 << 5 | 29);                             // add x29, x29, x2, lsl #4
            a_stp(S1, S3, 29, 0);
            a_str(S3, CTX, 256);                             // the table holds something
            a_mov(1, 29, S3);
            e(0xD65F03C0);                                   // ret
        } else { e(0xD61F0000 | S3 << 5); }                  // br x3
        // The far way in a machine (E134), one for privilege level 0 and one for 3: the
        // address in x1 is a linear one. The TLB's entry for fetching instructions at
        // that level gives its page (a miss goes out, and the interpreter finds it);
        // then the look-up above by the physical address, and the block must be one
        // made at this level.
        jx[21] = jit_addr8(dc_cpl[..]) as! u64;
        // Made twice for each level: the far way the table's routine goes on to, and the
        // one a cell's few instructions go to (E178), which ends by filling the cell
        // named in x30.
        for pass in 4 {
            let lv = pass & 1;
            let cells = pass >= 2;
            let out2 = jc.len;
            e(0x14000000 | (((j_out_at - jc.len) >> 2) as! u32) & 0x3FFFFFF);
            if cells { jcell_far[lv] = jc.len; } else { j_fark_at[lv] = jc.len; }
            // (x30 is the exit's that called the table's routine: x4 and x29 are used.)
            if jit_why && !cells { a_ldr(29, CTX, 248); a_addi(0x11, 1, 29, 29, 1); a_str(29, CTX, 248); }
            if jit_why && !cells { a_ldr(29, CTX, (280 + lv * 8) as! u32); a_addi(0x11, 1, 29, 29, 1); a_str(29, CTX, (280 + lv * 8) as! u32); }
            if jit_why && cells { a_ldr(29, CTX, 336); a_addi(0x11, 1, 29, 29, 1); a_str(29, CTX, 336); }
            a_shifti(5, 1, S2, S1, 12);
            e(0x92402C00 | S2 << 5 | S3);                    // and x3, x2, #0xFFF
            e(0x91400000 | ((4 + lv) as! u32) << 10 | S3 << 5 | S3);         // the table for fetches
            a_ldr(29, CTX, 152);
            e(0x8B001000 | S3 << 16 | 29 << 5 | 29);         // add x29, x29, x3, lsl #4: the place's pair (E171)
            a_ldp(S4, 29, 29, 0);
            a_rrr(A_SUBS, 1, ZR, S4, S2);
            e(0x54000001 | ((((out2 - jc.len) >> 2) as! u32) & 0x7FFFF) << 5);
            a_rrr(A_ADD, 1, S2, S1, 29);                     // the physical address: the entry's addend on
            e(0xCA400000 | S2 << 16 | (DC_BITS as! u32) << 10 | S2 << 5 | S3);       // eor x3, x2, x2, lsr #DC_BITS
            e(0x92400000 | ((DC_BITS - 1) as! u32) << 10 | S3 << 5 | S3);
            a_ldr(S4, CTX, 88);
            e(0x8B001400 | S3 << 16 | S4 << 5 | 29);         // add x29, x4, x3, lsl #5
            a_ldr(29, 29, 0);
            a_rrr(A_SUBS, 1, ZR, 29, S2);
            e(0x54000000 | 6 << 5);                          // b.eq found, six on
            e(0xD2400000 | S3 << 5 | S3);                    // eor x3, x3, #1: the other way
            e(0x8B001400 | S3 << 16 | S4 << 5 | 29);
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
            a_ldr(S4, CTX, 112);
            a_rrr(A_ADD, 1, 29, S4, 29);
            if jit_why { a_ldr(S4, CTX, 224); a_addi(0x11, 1, S4, S4, 1); a_str(S4, CTX, 224); }
            if cells && jit_why { a_ldr(S4, CTX, 344); a_addi(0x11, 1, S4, S4, 1); a_str(S4, CTX, 344); }
            if cells {
                // The cell (its number in x30) is given the block's address, and its
                // number put on the list of cells filled since the table was emptied;
                // with the list full, the cell is left to ask again.
                a_ldr(S2, CTX, 312);
                e(0xF1400000 | (JD_SIZE >> 12) << 10 | S2 << 5 | ZR);            // cmp x2, #JD_SIZE
                e(0x54000002 | 7 << 5);                                          // b.hs seven on: the br
                a_ldr(S4, CTX, 320);
                e(0xF8207800 | 30 << 16 | S4 << 5 | 29);                         // str x29, [x4, x30, lsl #3]
                a_ldr(S4, CTX, 328);
                e(0xB8207800 | S2 << 16 | S4 << 5 | 30);                         // str w30, [x4, x2, lsl #2]
                a_addi(0x11, 1, S2, S2, 1);
                a_str(S2, CTX, 312);
                e(0xD61F0000 | 29 << 5);                                         // br x29
            } else if jit_no2 & 1 == 0 {
                a_ldr(S4, CTX, (232 + lv * 8) as! u32);
                jt_idx();
                e(0x8B001000 | S2 << 16 | S4 << 5 | S4);                         // add x4, x4, x2, lsl #4
                a_stp(S1, 29, S4, 0);
                a_str(29, CTX, 256);
                e(0xD65F03C0);                               // ret: to the exit's `br x29`
            } else { e(0xD61F0000 | 29 << 5); }
        }
        // The table's routines (E165): x1 the address jumped to; x29 comes back the
        // block's, from the table or from the far way.
        if jit_no2 & 1 == 0 {
            jx[32] = 1;
            jt_clear();
            jx[40] = jit_addr_u64(jcell[..]) as! u64;
            jx[41] = jit_addr32(jdirty[..]) as! u64;
            jx[29] = jit_addr_u64(jt[..]) as! u64;
            jx[30] = (jit_addr_u64(jt[..]) + JT_SIZE * 16) as! u64;
            for k in 3 {
                jt_at[k] = jc.len;
                if jit_why { a_ldr(29, CTX, 216); a_addi(0x11, 1, 29, 29, 1); a_str(29, CTX, 216); }
                if jit_why && k == 0 { a_ldr(29, CTX, 296); a_addi(0x11, 1, 29, 29, 1); a_str(29, CTX, 296); }
                a_ldr(29, CTX, if k == 1 { 240 } else { 232 });
                jt_idx();
                e(0x8B001000 | S2 << 16 | 29 << 5 | 29);                         // add x29, x29, x2, lsl #4
                a_ldp(S2, 29, 29, 0);
                a_rrr(A_SUBS, 1, ZR, S2, S1);
                e_bc(C_NE, if k == 2 { j_far_at } else { j_fark_at[k] });
                e(0xD65F03C0);                               // ret
            }
        }
    }
    // The routine for a way out that leaves an instruction to the interpreter (E179): the
    // word behind the call (x30) holds the instructions run in its upper half and how far
    // from the block's first the instruction left is in its lower.
    j_leave_at = jc.len;
    e(0xB9400000 | 30 << 5 | S2);                            // ldr w2, [x30]
    e(0xCB400000 | S2 << 16 | 16 << 10 | 0 << 5 | 0);        // sub x0, x0, x2, lsr #16
    e(0x92403C00 | S2 << 5 | S2);                            // and x2, x2, #0xFFFF
    a_rrr(A_ADD, 1, S1, RIPB, S2);
    a_imm(30, 1);
    a_str(30, CTX, 192);
    e_b(j_out_at);
    j_settle_make();
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
let HF_BT = 6;               // a TST of the bit BT chose (E138): zero when CF is clear
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
// The exits of the block being translated that could be linked later: where, and to what.
let TP_MAX = 128;
var tp_n = 0;
var tp_pos: i64[TP_MAX] = [0; TP_MAX];
var tp_to: u64[TP_MAX] = [0; TP_MAX];
var jp: u8[>..];
// The block's branches back to its own first instruction, to be filled in.
let SS_MAX = 16;
// The conditional jumps back to the block's own first instruction whose way back is in
// line (E164): which way out each is (so_pos is the jump, so_at the way out behind the
// block). Round the loop is then one taken branch: the jump's condition turned round
// over `sub x0, #cnt; cmp x0, #n; b.hs the body`, where it was a branch to the way out
// and that one from there.
var sl_n = 0;
var sl_so: i64[SS_MAX] = [0; SS_MAX];
var so_at: i64[SO_MAX] = [0; SO_MAX];
var ss_n = 0;
var ss_pos: i64[SS_MAX] = [0; SS_MAX];
// A block begins with what an entry from another block needs (BODY_AT bytes), and the
// interpreter enters behind it.
let BODY_AT = 24;
// How far before the body the entry from another block is: three instructions, or five
// in a block that reads RFLAGS in memory (E170).
inline fn j_lead(needs: bool) -> i64 { return if needs { 20 } else { 12 }; }
let SH_MAX = 64;
var sh_n = 0;
var sh_pos: i64[SH_MAX] = [0; SH_MAX];

// The exits that wait for a block at `head` made at `level` are made branches to `code`;
// the others of the chain stay on it.
fn j_wake(head: u64, code: i64, level: u8) {
    let wk = dc_slot(head);
    var w = dc_wait[wk];
    var kept: u32 = 0;
    while w != 0 {
        let site = (w - 1) as! i64;
        let next = (jit_peek64(j_mem + site + 4) & 0xFFFFFFFF) as! u32;
        let to = jit_peek64(j_mem + site + 8) as! u64;
        let lv = (jit_peek64(j_mem + site + 16) & 0xFF) as! u8;
        if to == head && lv == level { j_patch(site, code); }
        else {
            if next != kept { j_poke32(site + 4, kept); }
            kept = w;
        }
        w = next;
    }
    dc_wait[wk] = kept;
}

// Makes the branch at `site` in the mapping go to `to`.
// Writes the word w at `site` in the mapping.
fn j_poke32(site: i64, w: u32) {
    jp = [];
    jp.push(w as! u8);
    jp.push((w >> 8) as! u8);
    jp.push((w >> 16) as! u8);
    jp.push((w >> 24) as! u8);
    jit_write(j_mem + site, jp[..]);
}

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
var j_eslot: i64 = 0;        // the entry j_entry found
fn j_entry(q: u64) -> bool {
    let slot = dc_find(q);
    if dc[slot].tag != q { return false; }
    j_eslot = slot;
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
        if op >= 0xD8 && op <= 0xDF { return m; }                // the x87 (E161): ModRM and nothing behind it
        // CLI, CLD, STD and LEAVE (E176): the opcode is all of them.
        if op == 0xFA || op == 0xFC || op == 0xFD || op == 0xC9 { return p; }
        if op == 0x87 { return m; }                          // XCHG (E177)
        if op != 0x0F { return 0; }
        let op2 = mem_rd(j_at + p, 8) as! u8;
        // RDTSC; LFENCE, MFENCE and SFENCE; SWAPGS (E176).
        if op2 == 0x31 { return p + 1; }
        if op2 == 0xAE && mem_rd(j_at + p + 1, 8) >= 0xE8 { return p + 2; }
        if op2 == 0x01 && mem_rd(j_at + p + 1, 8) == 0xF8 { return p + 2; }
        if op2 >= 0xC8 && op2 <= 0xCF { return p + 1; }      // BSWAP (E147): no operand's bytes
        if m == 0 { return 0; }
        if op2 == 0xBC || op2 == 0xBD || op2 == 0xB1 || op2 == 0xC1 { return m; }        // BSF, BSR, CMPXCHG, XADD
        // BT, BTS, BTR, BTC and the double shifts (E138), a constant behind some.
        if op2 == 0xA3 || op2 == 0xAB || op2 == 0xB3 || op2 == 0xBB || op2 == 0xA5 || op2 == 0xAD { return m; }
        if op2 == 0xBA || op2 == 0xA4 || op2 == 0xAC { return m + 1; }
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
    // stays, as stale as the flags are dead. The host's flags are this instruction's
    // from here, whatever a shift by CL before it left undecided (E147: with j_dyn left
    // set, the jump behind a TEST whose record was left out found no condition, ended the
    // block, and was interpreted on the record of the shift).
    if j_dead { j_stale = true; j_dyn = false; return; }
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
    if j_dead { j_stale = true; j_dyn = false; return; }
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
    // Where nothing can read the flags the host's are not set either (E164: the host has
    // fewer places to run an instruction that sets flags than one that does not, and a
    // loop of ADDS, CMP and CSEL waits for them). CMP and TEST are then nothing at all.
    if j_nohost && jit_no >> 40 & 1 == 0 {
        j_hf = 0;
        if test || k == 7 { return; }
        a_rrr(if k == 0 { A_ADD } else if k == 5 { A_SUB } else if k == 4 { 0x0A000000 } else if k == 1 { A_ORR } else { A_EOR }, sf, dst, a, b);
        return;
    }
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
        if j_nohost && jit_no >> 40 & 1 == 0 {
            // (No flags wanted, E164: ADD and SUB as they are, and no CMP.)
            j_hf = 0;
            if k != 7 { a_addi(if k == 0 { 0x11 } else { 0x51 }, sf, dst, a, v as! u32); }
            return;
        }
        a_addi(if k == 0 { 0x31 } else { 0x71 }, sf, if k == 7 { ZR } else { dst }, a, v as! u32);
        j_hf = if k == 0 { HF_ADD } else { HF_SUB };
        return;
    }
    if (k == 1 || k == 4 || k == 6) && jit_no >> 34 & 1 == 0 {
        // OR, AND and XOR by a constant the host takes as one (E163).
        let sf: u32 = if je.osz == 64 { 1 } else { 0 };
        let c = a_logimm(v, sf);
        if c != 0xFFFFFFFF {
            j_rec_alu((k as u32) + 1, je.osz, dst, a, 255, v);
            if k == 4 && j_nohost && jit_no >> 40 & 1 == 0 { e(0x12000000 | sf << 31 | c << 10 | a << 5 | dst); j_hf = 0; }      // and
            else if k == 4 { e(0x72000000 | sf << 31 | c << 10 | a << 5 | dst); j_hf = HF_LOGIC; }  // ands
            else {
                e((if k == 1 { 0x32000000 } else { 0x52000000 }) | sf << 31 | c << 10 | a << 5 | dst);   // orr, eor
                if j_nohost { j_hf = 0; }
                else { a_rrr(A_ANDS, sf, ZR, dst, dst); j_hf = HF_LOGIC; }
            }
            return;
        }
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
fn j_alu8(k: u8, test: bool, a: u32, b: u32, v: u64) { j_alu_n(k, test, a, b, v, 8); }

// The same on nb bits, 8 or 16 (E138): the operands are shifted up 32 - nb bits.
fn j_alu_n(k: u8, test: bool, a: u32, b: u32, v: u64, nb: u8) {
    let up: u32 = 32 - (nb as u32);
    if b == ZR { a_imm(S4, v & (((1 as u64) << nb) - 1)); } else { a_mov(0, S4, b); }
    j_rec_w(if test { 5 } else { (k as u32) + 1 }, nb, a, S4);
    a_shifti(4, 0, S2, a, up);
    a_shifti(4, 0, S4, S4, up);
    if test || k == 4 { a_rrr(A_ANDS, 0, S4, S2, S4); j_hf = HF_LOGIC; }
    else if k == 0 { a_rrr(A_ADDS, 0, S4, S2, S4); j_hf = HF_ADD; }
    else if k == 5 || k == 7 { a_rrr(A_SUBS, 0, S4, S2, S4); j_hf = HF_SUB; }
    else {
        a_rrr(if k == 1 { A_ORR } else { A_EOR }, 0, S4, S2, S4);
        if j_nohost { j_hf = 0; }
        else { a_rrr(A_ANDS, 0, ZR, S4, S4); j_hf = HF_LOGIC; }
    }
    a_shifti(5, 0, S4, S4, up);
}

// The low nb bits (8 or 16) of host register rs into the low nb bits of rd: bfi.
fn a_bfi_low(rd: u32, rs: u32, nb: u8) { e((if nb == 8 { 0xB3401C00 } else { 0xB3403C00 }) | rs << 5 | rd); }

// Whether the register i can be an operand of nb bits: any for 16, for 8 one whose low
// byte is its byte (j_byte_ok).
fn j_nok(i: u8, nb: u8) -> bool { return nb == 16 || j_byte_ok(i); }

// ---- BT, BTS, BTR, BTC and the double shifts (E138) ----

// Which bit instruction je is: 0 BT, 1 BTS, 2 BTR, 3 BTC; 255 for none.
fn j_bt_op() -> u8 {
    if je.op != 0x0F { return 255; }
    let op2 = mem_rd(j_at + je.plen, 8) as! u8;
    if op2 == 0xA3 || op2 == 0xAB || op2 == 0xB3 || op2 == 0xBB { return op2 >> 3 & 3; }
    if op2 == 0xBA && je.reg & 7 >= 4 { return je.reg & 3; }
    return 255;
}

// tst of bit n of host register rn: ands zr, rn, #(1 << n).
fn a_tst_bit(sf: u32, rn: u32, n: u32) {
    let top: u32 = if sf == 1 { 63 } else { 31 };
    e((if sf == 1 { 0xF2400000 } else { 0x72000000 }) | ((top + 1 - n) & top) << 16 | rn << 5 | ZR);
}

// BT, BTS, BTR or BTC of a register, at q and len bytes long. CF alone is set, which is
// handled as INC and DEC's flags are: nothing made of it where it is dead (the host's TST
// serves a jump right behind), else only as the block's first to set flags, on RFLAGS in
// memory. The record (50h) is the value and the bit's number.
fn j_bt(q: u64, len: u64, which: u8) -> bool {
    let imm = (mem_rd(q + je.plen, 8) as! u8) == 0xBA;
    // Of memory (E177): by a constant only, where the bit is in the operand named (a
    // register's number reaches outside it); the operand is loaded into S4, and stored
    // from there.
    let inmem = je.mod != 3;
    if jit_no >> 54 & 1 != 0 { return false; }
    if inmem && (!imm || jit_no2 & 128 != 0 || je.asz32 || machine && jit_no >> 56 & 1 != 0) { return false; }
    let w: u32 = je.osz;
    let sf: u32 = if w == 64 { 1 } else { 0 };
    if !j_dead && j_set { return false; }
    var m = hg(je.rm);
    if inmem { j_addr(); j_chk(which != 0); j_load(je.osz, S4); m = S4; }
    let n: u32 = if imm { (mem_rd(q + len - 1, 8) & ((w as u64) - 1)) as! u32 } else { 0 };
    let r = hg(je.reg);
    if !j_dead {
        j_needs = true;
        if imm { a_imm(29, n); j_rec_w(0x50, w, m, 29); } else { j_rec_w(0x50, w, m, r); }
    } else { j_stale = true; j_dyn = false; }
    // The bit, as one in S2 for BTS, BTR and BTC; and the host's flags from it.
    if imm {
        if !j_nohost { a_tst_bit(sf, m, n); j_hf = HF_BT; }
        if which != 0 { a_imm(S2, (1 as u64) << n); }
    } else {
        var by = r;
        if w == 16 { e(0x12000C00 | r << 5 | S2); by = S2; }          // and w2, wr, #15
        if !j_nohost || which != 0 { a_shiftv(5, sf, S3, m, by); }     // lsr x3, xm, x(by)
        if !j_nohost { a_tst_bit(sf, S3, 0); j_hf = HF_BT; }
        if which != 0 { a_imm(S3, 1); a_shiftv(4, sf, S2, S3, by); }
    }
    if which == 0 { return true; }
    let op: u32 = if which == 1 { A_ORR } else if which == 2 { 0x0A200000 } else { A_EOR };     // orr, bic, eor
    if inmem { a_rrr(op, sf, S4, S4, S2); j_store(je.osz, S4); }
    else if w == 16 { a_rrr(op, 0, S4, m, S2); a_bfi_low(m, S4, 16); }
    else { a_rrr(op, sf, m, m, S2); }
    return true;
}

// XADD of 32 or 64 bits (E177): the operand and the register added into the operand, and
// the register given what the operand was. The flags are ADD's, recorded at once.
fn j_xadd() -> bool {
    if jit_no2 & 128 != 0 || je.osz == 16 { return false; }
    let sf: u32 = if je.osz == 64 { 1 } else { 0 };
    let r = hg(je.reg);
    let regs = je.mod == 3;
    if regs { a_mov(sf, S3, hg(je.rm)); }
    else {
        if machine && jit_no >> 56 & 1 != 0 { return false; }
        j_addr(); j_chk(true); j_load(je.osz, S3);
    }
    j_rec_w(1, je.osz, S3, r);
    a_rrr(A_ADDS, sf, S4, S3, r);
    j_hf = HF_ADD;
    a_mov(sf, r, S3);
    if regs { a_mov(sf, hg(je.rm), S4); } else { j_store(je.osz, S4); }
    return true;
}

// CMPXCHG of 32 or 64 bits (E147): the A register compared with the operand, which takes
// the register named if they are equal, and A takes the operand if not. The flags are a
// CMP's, recorded at once (the operands do not stay as they are for a record put off).
fn j_cmpxchg() -> bool {
    if jit_no >> 49 & 1 != 0 || je.osz == 16 { return false; }
    let sf: u32 = if je.osz == 64 { 1 } else { 0 };
    let ax = hg(0);
    let r = hg(je.reg);
    let regs = je.mod == 3;
    if regs { if je.rm == 0 { return false; } a_mov(sf, S3, hg(je.rm)); }
    else {
        if machine && jit_no >> 56 & 1 != 0 { return false; }
        j_addr(); j_chk(true); j_load(je.osz, S3);
    }
    j_rec_w(8, je.osz, ax, S3);
    a_rrr(A_SUBS, sf, ZR, ax, S3);
    j_hf = HF_SUB;
    if regs { a_csel(sf, hg(je.rm), r, S3, C_EQ); }
    else { a_csel(sf, S4, r, S3, C_EQ); j_store(je.osz, S4); }
    a_csel(1, ax, ax, S3, C_EQ);
    return true;
}

// BSF or BSR of 32 or 64 bits (E147): RBIT and CLZ, or CLZ taken from the top bit's number;
// of zero the register is left as it was, upper half and all. The record (52h, 53h) is the
// operand.
fn j_bsf(low: bool) -> bool {
    if jit_no >> 49 & 1 != 0 || je.osz == 16 { return false; }
    let sf: u32 = if je.osz == 64 { 1 } else { 0 };
    if je.mod == 3 { a_mov(sf, S3, hg(je.rm)); }
    else {
        if machine && jit_no >> 56 & 1 != 0 { return false; }
        j_addr(); j_chk(false); j_load(je.osz, S3);
    }
    j_rec_w(if low { 0x52 } else { 0x53 }, je.osz, S3, ZR);
    if low {
        e((if sf == 1 { 0xDAC00000 } else { 0x5AC00000 }) | S3 << 5 | S2);       // rbit
        e((if sf == 1 { 0xDAC01000 } else { 0x5AC01000 }) | S2 << 5 | S2);       // clz
    } else {
        e((if sf == 1 { 0xDAC01000 } else { 0x5AC01000 }) | S3 << 5 | S2);
        a_imm(S4, (je.osz as u64) - 1);
        a_rrr(A_SUB, sf, S2, S4, S2);
    }
    a_addi(0x71, sf, ZR, S3, 0);                             // cmp x3, #0
    a_csel(1, hg(je.reg), S2, hg(je.reg), C_NE);
    j_hf = 0;
    return true;
}

// SHLD or SHRD of a register by a constant or by CL, 32 or 64 bits. The record (60h, 61h)
// is the two operands with the count above the width; by CL it is made only if the count
// is not zero, as a shift's is.
fn j_shd(q: u64, len: u64, op2: u8) -> bool {
    if jit_no >> 53 & 1 != 0 || je.mod != 3 || je.osz == 16 { return false; }
    let left = op2 == 0xA4 || op2 == 0xA5;
    let w: u32 = je.osz;
    let sf: u32 = if w == 64 { 1 } else { 0 };
    let m = hg(je.rm);
    let r = hg(je.reg);
    let what: u32 = if left { 0x60 } else { 0x61 };
    if op2 == 0xA4 || op2 == 0xAC {
        let n: u32 = (mem_rd(q + len - 1, 8) & (if sf == 1 { 63 } else { 31 })) as! u32;
        if n == 0 { return true; }
        if j_dead { j_stale = true; }
        else {
            a_mov(1, FA, m);
            a_mov(1, FB, r);
            a_imm(FK, what | w << 8 | n << 16);
            j_set = true;
            j_dyn = false;
            j_stale = false;
        }
        // extr: left, dst:src down by w - n; right, src:dst down by n.
        let base: u32 = if sf == 1 { 0x93C00000 } else { 0x13800000 };
        if left { e(base | r << 16 | (w - n) << 10 | m << 5 | m); }
        else { e(base | m << 16 | n << 10 | r << 5 | m); }
        j_hf = 0;
        return true;
    }
    e((if sf == 1 { 0x92401400 } else { 0x12001000 }) | hg(1) << 5 | S1);    // and x1, xCL, #63 or #31
    a_addi(0x71, 1, ZR, S1, 0);                                              // cmp x1, #0
    if j_dead { j_stale = true; }
    else {
        a_csel(1, FA, m, FA, C_NE);
        a_csel(1, FB, r, FB, C_NE);
        a_imm(S2, what | w << 8);
        e(0xAA000000 | S1 << 16 | 16 << 10 | S2 << 5 | S2);                 // orr x2, x2, x1, lsl #16
        a_csel(1, FK, S2, FK, C_NE);
        j_set = true;
        j_dyn = true;
    }
    // By a count that is not zero: the other operand's bits come in from the far side,
    // shifted by w - n, which is -n in the low bits the shift looks at.
    a_rrr(A_SUB, 1, S4, ZR, S1);
    if left { a_shiftv(4, sf, S3, m, S1); a_shiftv(5, sf, S4, r, S4); }
    else { a_shiftv(5, sf, S3, m, S1); a_shiftv(4, sf, S4, r, S4); }
    a_rrr(A_ORR, sf, S3, S3, S4);
    a_csel(sf, m, S3, m, C_NE);
    j_hf = 0;
    return true;
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
    // After BT's TST (E138): B is "the bit is set", NE; AE is EQ. Nothing else.
    let bt: u8[16] = [255, 255, 1, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255];
    let c: u8 = if hf == HF_SUB { sub[cc] } else if hf == HF_ADD { add[cc] } else if hf == HF_LOGIC { logic[cc] } else if hf == HF_FCMP { fcmp[cc] } else if hf == HF_BT { bt[cc] } else { incdec[cc] };
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
    var waits = false;
    var own = false;
    // The way out that leaves an instruction to the interpreter (E179): two words, a
    // call of the routine that does it and what it is to know behind the call. There is
    // one such way out for every load and store of a block, and they are almost never
    // taken: five words each made the blocks lie a fifth further apart.
    if !link && !jit_check && j_leave_at != 0 && off < 0x10000 && cnt < 0x10000 && jit_no2 & 512 == 0 {
        e(0x94000000 | (((j_leave_at - (j_used + jc.len)) >> 2) as! u32) & 0x3FFFFFF);
        e((cnt as! u32) << 16 | (off as! u32));
        return;
    }
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
        let slot = dc_find(t);
        if t == j_head && sh_n < SH_MAX { own = true; jit_links += 1; }
        else if dc[slot].tag == t && dc_n[slot] != 0 && dc_cpl[slot] == cpl { to = dc_code[slot]; jit_links += 1; }
        else if jit_no2 & 1024 == 0 && bt_at(t, cpl) >= 0 { to = bt_code[bt_at(t, cpl)]; jit_links += 1; }       // (a block whose entry was given up, E180)
        else if tp_n < TP_MAX { tp_pos[tp_n] = jc.len; tp_to[tp_n] = t; tp_n += 1; waits = true; }
    }
    // In a machine, an address on another page: looked up as it is jumped to.
    let far = link && machine && !linked;
    // A way out that leaves the instruction it stands at to the interpreter says so
    // (E155): what lies behind that instruction is where a block is wanted.
    if !link { a_imm(30, 1); a_str(30, CTX, 192); }
    if far { e_far_direct = true; e_far(); e_far_direct = false; }
    else if own {
        // (To this block's own entry, which is known when the block is whole.)
        sh_pos[sh_n] = jc.len;
        sh_n += 1;
        e(0x14000000);
    } else {
        let d: u32 = ((to - (j_used + jc.len)) >> 2) as! u32;
        e(0x14000000 | d & 0x3FFFFFF);
    }
    // An exit that waits for a block carries its own entry behind the branch (E145), which
    // nothing runs into: the next in the chain (filled in when the block is written), the
    // address waited for, and the privilege level.
    if waits {
        let t = j_head + off;
        e(0);
        e(t as! u32);
        e((t >> 32) as! u32);
        e(cpl);
    }
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

// The jump to the block at the address in x1, if there is one: through the table (E165:
// the routine leaves the block's address, or the way out's, in x29), or by the far way.
var pad_far: u8[7] = [0; 7];    // (with e_far_direct, eight bytes: tools/layout.sh)
var e_far_direct = false;     // the exit being made is to a constant address (--jit-why counts them)
fn e_far() {
    let to = j_far();
    if jit_why && e_far_direct { a_ldr(29, CTX, 304); a_addi(0x11, 1, 29, 29, 1); a_str(29, CTX, 304); }
    var k = 2;
    if machine { k = if cpl == 0 { 0 } else { 1 }; }
    if to != j_out_at && e_far_direct && machine && jcell_far[k] != 0 && jcell_n < JC_SIZE && jit_no2 & 256 == 0 {
        // To a constant address (E178): the exit's own cell holds where the block is, or
        // where the instructions behind this `br` are, which name the cell and go to
        // the far way that fills it.
        let c = jcell_n;
        jcell_n += 1;
        let hi: u32 = ((c * 8) >> 12) as! u32;
        a_ldr(S2, CTX, 320);
        if hi != 0 { e(0x91400000 | hi << 10 | S2 << 5 | S2); }                            // add x2, x2, #hi, lsl #12
        a_ldr(29, S2, ((c * 8) & 0xFFF) as! u32);
        e(0xD61F0000 | 29 << 5);                                                           // br x29
        jcell_home[c] = (j_used + jc.len) as! u32;
        jcell[c] = (j_mem + j_used + jc.len) as! u64;
        a_imm(30, c as! u64);
        e(0x14000000 | (((jcell_far[k] - (j_used + jc.len)) >> 2) as! u32) & 0x3FFFFFF);
        return;
    }
    if to != j_out_at && jt_at[k] != 0 {
        e(0x94000000 | (((jt_at[k] - (j_used + jc.len)) >> 2) as! u32) & 0x3FFFFFF);        // bl the routine
        e(0xD61F0000 | 29 << 5);                                                           // br x29
        return;
    }
    let d: u32 = ((to - (j_used + jc.len)) >> 2) as! u32;
    e(0x14000000 | d & 0x3FFFFFF);
}

// The way out to the address in host register r.
fn j_exit_to(r: u32, cnt: u64) {
    a_mov(1, S1, r);
    j_tell();
    a_addi(0x51, 1, 0, 0, cnt as! u32);
    e_far();
}

// What the host's flags are from behind the instruction in je, as j_one will translate it:
// HF_ADD, HF_SUB or HF_LOGIC, or 0 for an instruction that leaves them no use to a jump.
fn j_regime() -> u8 {
    let f = je.reg & 7;
    var ak: u8 = 255;
    if jk == 0 { return if j_bt_op() != 255 { HF_BT } else { 0 }; }
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
    // (Sixteen ways out left, not twelve: the instruction being translated may add some
    // before the jump is asked whether it has twelve, and a jump refused then would be
    // interpreted on a record that was left out. E163.)
    if hf == 0 || cnt + 2 > J_MAX || so_n + 16 > SO_MAX || q >= page_end { return false; }
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
            && !je.asz32 && !je.p66 && je.sg == 0 && je.rep == 0 && (k >= 32 || jit_no >> k & 1 == 0) {
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

// The same behind a CMOVcc of registers or a SETcc of a register (E163): the instruction
// behind the one being translated is one, the host's flags serve its condition, it is
// one this translator takes (so that the interpreter never meets it with the record left
// out), and nothing reads the flags behind it before they are set again.
fn j_dead_past_use(q: u64, page_end: u64, cnt: u64) -> bool {
    if jit_no >> 33 & 1 != 0 { return false; }
    let hf = j_regime();
    if hf == 0 || cnt + 2 > J_MAX || so_n + 16 > SO_MAX || q >= page_end { return false; }
    let keep = je;
    let keep_k = jk;
    let keep_at = j_at;
    var ok = false;
    var after: u64 = 0;
    var at = q;
    // Past up to two moves between registers of 32 or 64 bits (E164: `cmp; mov; cmovg`),
    // which are one host MOV each: no flag changed, no way out, and always taken.
    for step in 3 {
        if at >= page_end || !j_entry(at) { break; }
        let k = jk;
        let len = j_len();
        if len == 0 || len > page_end - at || je.asz32 || je.p66 || je.rep != 0 || je.mod != 3 { break; }
        if k >= K_CMOV && k < K_SETCC + 16 {
            if (k < K_SETCC || j_byte_ok(je.rm)) && j_cond_of(hf, k & 15) != C_NONE { ok = true; after = at + len; }
            break;
        }
        if step == 2 || k != K_MOV || je.op & 1 == 0 || jit_no >> K_MOV & 1 != 0 || cnt + 3 + (step as! u64) > J_MAX { break; }
        at += len;
    }
    je = keep;
    jk = keep_k;
    j_at = keep_at;
    return ok && j_flags_dead(after, page_end);
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
    var why = 1;
    for i in 12 {
        if at >= page_end { why = 1; break; }
        if !j_entry(at) { why = 2; break; }
        let len = j_len();
        let k = jk;
        if k == K_JCC8 || (k >= K_JCC32 && k < K_CMOV) { why = 4; }
        else if k == K_CALL || k == K_JMP8 || k == K_JMP32 { why = 5; }
        else if k == K_RET || (k == K_GRP5 && je.reg & 7 >= 2) { why = 6; }
        else if k >= K_CMOV { why = 7; }
        else { why = 3; }
        if len == 0 { break; }
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
        if full { dead = true; why = 0; break; }
        if !neutral { break; }
        at += len;
        why = 8;
    }
    if jit_why { jf[why] += 1; }
    je = keep;
    jk = keep_k;
    j_at = keep_at;
    return dead;
}

// The address of je's operand in memory, into S1.
fn j_addr() {
    // E184, in a program without a kernel: x1 is kept known as the address of the operand
    // last made here (its base, index, scale and constant), with what has been tested of
    // it, until x1 or one of its registers is written (the emitter sees to that, as for
    // E164's sets). The same operand again is nothing; one that differs in its constant
    // by less than 4,096 is an `add` or `sub` of the difference, to be tested anew.
    let keep = !machine && je.sg == 0 && !je.asz32 && jit_no2 & 2048 == 0;
    let disp = if je.base == 17 { j_off + j_ilen + je.disp } else { je.disp };
    if keep && ma_ok && ma_base == je.base && ma_index == je.index && (je.index >= 16 || ma_scale == je.scale) {
        let d = disp - ma_disp;
        if d == 0 { return; }
        if d < 4096 || 0 - d < 4096 {
            if d < 4096 { a_addi(0x11, 1, S1, S1, d as! u32); } else { a_addi(0x51, 1, S1, S1, (0 - d) as! u32); }
            ma_ok = true;
            ma_disp = disp;
            ma_rd = false;
            ma_wn = 0;
            return;
        }
    }
    j_lea();
    // FS's or GS's base, which a block is given as it is entered.
    if je.sg != 0 {
        a_ldr(29, CTX, if je.sg == 1 { 136 } else { 144 });
        a_rrr(A_ADD, 1, S1, S1, 29);
    }
    ma_ok = keep;
    if keep {
        ma_base = je.base;
        ma_index = je.index;
        ma_scale = je.scale;
        ma_disp = disp;
        ma_hb = if je.base < 16 { hg(je.base) } else { 32 };
        ma_hi = if je.index < 16 { hg(je.index) } else { 32 };
        ma_rd = false;
        ma_wn = 0;
    }
}

// The operand's offset, which is what LEA gives: no segment's base.
fn j_lea() { j_lea_into(S1); }

// The same into host register t, which may be the base's but not the index's. (An index
// alone is a shift, E163.)
fn j_lea_into(t: u32) {
    if je.base == 17 { a_add_const(t, RIPB, j_off + j_ilen + je.disp); }
    else if je.base < 16 && je.index < 16 && je.disp == 0 && jit_no2 & 2048 == 0 {
        // (Base and index and no constant: one instruction, E184.)
        e(0x8B000000 | hg(je.index) << 16 | (je.scale as u32) << 10 | hg(je.base) << 5 | t);
        return;
    }
    else if je.base < 16 { a_add_const(t, hg(je.base), je.disp); }
    else if je.index < 16 && je.disp == 0 && jit_no >> 32 & 1 == 0 {
        if je.scale == 0 { a_mov(1, t, hg(je.index)); }
        else { a_shifti(4, 1, t, hg(je.index), je.scale); }
        return;
    }
    else { a_imm(t, je.disp); }
    if je.index < 16 { e(0x8B000000 | hg(je.index) << 16 | (je.scale as u32) << 10 | t << 5 | t); }
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
        //
        // Since E150 in nine host instructions: the entry's tag is compared with the
        // page of the access's last byte, which differs for a page not in the table and
        // for an access that crosses into the next page alike; what the entry holds
        // behind its tag is added to the address; and the tables' address is in a host
        // register (x28, which a program without a kernel uses for dc_mark). A page that
        // is not plain memory is never in these tables, nor in those for writes a page
        // with remembered instructions (sys64.goose), so neither is looked for here.
        //
        // Since E171 in seven for a load and eight for a store: a place's tag and addend
        // lie side by side and are read by one `ldp`, and x28 is this level's table for
        // reads (jit_enter), the table for writes two tables on.
        e(0xD3400000 | 12 << 16 | 23 << 10 | S1 << 5 | S3);  // ubfx x3, x1, #12, #12
        e(0x8B001000 | S3 << 16 | MARK << 5 | S3);           // add x3, x28, x3, lsl #4: the place's pair
        if write { e(0x91400000 | 0x20 << 10 | S3 << 5 | S3); }              // add x3, x3, #0x20, lsl #12: the table for writes
        a_ldp(30, S3, S3, 0);                                // the tag, the addend
        if n > 1 {
            a_addi(0x11, 1, S2, S1, n - 1);
            e(0xCA400000 | S2 << 16 | 12 << 10 | 30 << 5 | S2);              // eor x2, x30, x2, lsr #12
        } else { e(0xCA400000 | S1 << 16 | 12 << 10 | 30 << 5 | S2); }
        j_leave(S2, false);
        a_rrr(A_ADD, 1, S1, S1, S3);
    } else {
        // (What has been tested of the operand whose address x1 is known to be, E184.)
        if ma_ok && n <= 8 {
            if write {
                if ma_wn >= n { return; }
                if ma_rd { j_chk_mark_at(S1, n); ma_wn = n; return; }
            } else if ma_rd || ma_wn != 0 { return; }
        }
        j_chk_at(S1, write, n);
        if ma_ok && n <= 8 { ma_rd = true; if write { ma_wn = n; } }
    }
}

// The same for a program without a kernel, of the address in host register ar. Up to
// eight bytes: the address is under MEM_SIZE, one shift (E163; rd and wr test the same,
// and the array has sixteen bytes more). Sixteen: both halves are, as the interpreter's
// two accesses want it.
fn j_chk_at(ar: u32, write: bool, n: u32) {
    if n <= 8 && jit_no >> 32 & 1 == 0 { a_shifti(5, 1, S2, ar, 28); }
    else {
        a_addi(0x11, 1, S2, ar, n);
        a_rrr(A_ORR, 1, S2, S2, ar);
        a_shifti(5, 1, S2, S2, 28);
    }
    j_leave_if();
    if write { j_chk_mark_at(ar, n); }
}

// A store of n bytes at the address in ar, which is inside memory, changes no remembered
// instruction.
fn j_chk_mark_at(ar: u32, n: u32) {
    if jit_no >> 41 & 1 == 0 {
        // Its page holds no remembered instructions, and it does not run into the next
        // page (E164: one look in the table, and a store over a page's end is the
        // interpreter's, where it was a look for each page).
        a_shifti(5, 1, S2, ar, 12);
        e(0x38606800 | S2 << 16 | MARK << 5 | S2);           // ldrb w2, [x28, x2]
        a_addi(0x11, 1, S3, ar, n - 1);
        a_rrr(A_EOR, 1, S3, S3, ar);
        e(0xAA400000 | S3 << 16 | 12 << 10 | S2 << 5 | S2);  // orr x2, x2, x3, lsr #12
        j_leave_if();
    } else {
        a_shifti(5, 1, S2, ar, 12);
        e(0x38606800 | S2 << 16 | MARK << 5 | S2);           // ldrb w2, [x28, x2]
        a_addi(0x11, 1, S3, ar, n - 1);
        a_shifti(5, 1, S3, S3, 12);
        e(0x38606800 | S3 << 16 | MARK << 5 | S3);
        a_rrr(A_ORR, 0, S2, S2, S3);
        j_leave_if();
    }
}

// For the plain moves (E163): the host register the operand's address is in, which is the
// guest's own base register when the operand is that register and nothing more (a program
// without a kernel, and not under --jit-check, whose log of stores wants S1); with the
// checks made on it. A load or a store through it follows.
fn j_ea(write: bool) -> u32 {
    if !machine && !jit_check && je.sg == 0 && je.base < 16 && je.index >= 16 && je.disp == 0 && jit_no >> 32 & 1 == 0 {
        let ar = hg(je.base);
        let bit: u32 = (1 as u32) << ar;
        // (Tested already in this block, and not written since: E164.)
        if jit_no >> 42 & 1 == 0 && (ck_w & bit != 0 || (!write && ck_r & bit != 0)) { return ar; }
        if jit_no >> 42 & 1 == 0 && ck_r & bit != 0 { j_chk_mark_at(ar, 8); }     // (read here before: only the store's own test)
        else { j_chk_at(ar, write, 8); }
        ck_r |= bit;
        if write { ck_w |= bit; }
        return ar;
    }
    j_addr();
    j_chk(write);
    return S1;
}
fn j_load_at(ar: u32, n: u8, rt: u32) {
    let op: u32 = if n == 64 { 0xF8606800 } else if n == 32 { 0xB8606800 } else if n == 16 { 0x78606800 } else { 0x38606800 };
    e(op | ar << 16 | MEMR << 5 | rt);
}
fn j_store_at(ar: u32, n: u8, rt: u32) {
    if ar == S1 { j_store(n, rt); return; }
    let op: u32 = if n == 64 { 0xF8206800 } else if n == 32 { 0xB8206800 } else if n == 16 { 0x78206800 } else { 0x38206800 };
    e(op | ar << 16 | MEMR << 5 | rt);
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
fn x_ld_raw(n: u32, vt: u32, i: u8) {
    let at: u32 = (i as u32) * 16;
    e((if n == 64 { 0xFD400000 | (at >> 3) << 10 } else if n == 32 { 0xBD400000 | (at >> 2) << 10 } else { 0x3DC00000 | (at >> 4) << 10 }) | 29 << 5 | vt);
}
fn x_st_raw(n: u32, vt: u32, i: u8) {
    let at: u32 = (i as u32) * 16;
    e((if n == 64 { 0xFD000000 | (at >> 3) << 10 } else if n == 32 { 0xBD000000 | (at >> 2) << 10 } else { 0x3D800000 | (at >> 4) << 10 }) | 29 << 5 | vt);
}
// Since E160 XMM register i is in host vector 16 + i from its first use in a block to the
// block's end (xv_in: which are; a block is one straight line, so what the translator has
// loaded stays loaded). A result is stored to the context at once as well, so the context
// is right at every way out. --jit-off's bit 36 loads every time.
var xv_in: u32 = 0;
fn x_mov(d: u32, s: u32) { if d != s { e(0x4EA01C00 | s << 16 | s << 5 | d); } }     // mov vd.16b, vs.16b
// The host vector XMM register i is in, loaded if it was not.
fn x_get(i: u8) -> u32 {
    let h: u32 = 16 + (i as u32);
    if xv_in >> i & 1 == 0 {
        x_base();
        x_ld_raw(128, h, i);
        if jit_no >> 36 & 1 == 0 { xv_in |= 1 << i; }
    }
    return h;
}
// XMM register i has been given a new value in its host vector: stored.
fn x_put(i: u8) {
    x_base();
    x_st_raw(128, 16 + (i as u32), i);
    if jit_no >> 36 & 1 == 0 { xv_in |= 1 << i; }
}
// For the forms that work in the scratch vectors: a copy from the register's vector if it
// is in one, and the copy given back with the store.
fn x_ld(n: u32, vt: u32, i: u8) {
    let h: u32 = 16 + (i as u32);
    if xv_in >> i & 1 == 0 { x_ld_raw(n, vt, i); return; }
    if n == 128 { x_mov(vt, h); }
    else { e((if n == 64 { 0x1E604000 } else { 0x1E204000 }) | h << 5 | vt); }      // fmov d or s: the rest cleared
}
fn x_st(n: u32, vt: u32, i: u8) {
    let h: u32 = 16 + (i as u32);
    x_st_raw(n, vt, i);
    if xv_in >> i & 1 == 0 { return; }
    if n == 128 { x_mov(h, vt); }
    else { e((if n == 64 { 0x6E080400 } else { 0x6E040400 }) | vt << 5 | h); }      // mov vh.d[0] or .s[0], vt's
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
// The 128-bit operand in r/m: its host vector, or vt loaded from memory.
fn x_srcv(vt: u32) -> u32 {
    if je.mod == 3 { return x_get(je.rm); }
    j_addr();
    j_chk_n(false, 16);
    m_ld(128, vt);
    return vt;
}
// The 128-bit moves to XMM register r, and from it.
fn x_mov_in(r: u8) {
    let h: u32 = 16 + (r as u32);
    let s = x_srcv(h);
    x_mov(h, s);
    x_put(r);
}
fn x_mov_out(r: u8) {
    if je.mod == 3 {
        let s = x_get(r);
        x_mov(16 + (je.rm as u32), s);
        x_put(je.rm);
    } else {
        j_addr();
        j_chk_n(true, 16);
        let s = x_get(r);
        m_st(128, s);
    }
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
            if p < 2 { x_mov_in(r); }
            else {
                let n: u32 = if p == 2 { 32 } else { 64 };
                x_src(n, 0);
                x_base();
                x_st(if regs { n } else { 128 }, 0, r);
            }
        },
        0x11 => {
            if p < 2 { x_mov_out(r); return true; }
            let n: u32 = if p == 2 { 32 } else { 64 };
            if regs { x_base(); x_ld(n, 0, r); x_st(n, 0, je.rm); }
            else { j_addr(); j_chk_n(true, if n == 128 { 16 } else { 8 }); x_base(); x_ld(n, 0, r); m_st(n, 0); }
        },
        0x28 => { x_mov_in(r); },
        0x29 => { x_mov_out(r); },
        0x6F => {
            if p == 0 || p == 3 { return false; }
            x_mov_in(r);
        },
        0x7F => {
            if p == 0 || p == 3 { return false; }
            x_mov_out(r);
        },
        0x6E => {
            // MOVD and MOVQ from a general register or memory: the rest cleared.
            if p != 1 { return false; }
            let h: u32 = 16 + (r as u32);
            if regs { e((if wide { 0x9E670000 } else { 0x1E270000 }) | gr << 5 | h); }  // fmov d or s
            else { j_addr(); j_chk(false); m_ld(if wide { 64 } else { 32 }, h); }
            x_put(r);
        },
        0x7E => {
            if p == 2 { x_src(64, 0); x_base(); x_st(128, 0, r); }
            else if p == 1 {
                // To a general register or memory.
                let h = x_get(r);
                if regs { e((if wide { 0x9E660000 } else { 0x1E260000 }) | h << 5 | gr); }      // fmov x or w
                else {
                    j_addr(); j_chk(true);
                    e((if wide { 0x9E660000 } else { 0x1E260000 }) | h << 5 | S3);
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
            if j_dead { j_stale = true; j_dyn = false; }
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
        0x54, 0x55, 0x56, 0x57, 0xDB, 0xDF, 0xEB, 0xEF => {
            // The 128-bit AND, ANDN, OR and XOR, on floats' bits or integers'.
            if (op2 < 0x58 && p > 1) || (op2 >= 0xDB && p != 1) { return false; }
            if op2 == 0xDF && jit_no >> 43 & 1 != 0 { return false; }
            if regs && r == je.rm && (op2 == 0x57 || op2 == 0xEF) {
                e(0x4F000400 | (16 + (r as u32)));           // a register XORed with itself: movi #0
                x_put(r);
                return true;
            }
            let s = x_srcv(1);
            let d = x_get(r);
            if op2 == 0x54 || op2 == 0xDB { e(0x4E201C00 | s << 16 | d << 5 | d); }     // and d, d, s
            else if op2 == 0x55 || op2 == 0xDF { e(0x4E601C00 | d << 16 | s << 5 | d); }               // bic d, s, d
            else if op2 == 0x56 || op2 == 0xEB { e(0x4EA01C00 | s << 16 | d << 5 | d); }               // orr
            else { e(0x6E201C00 | s << 16 | d << 5 | d); }                              // eor
            x_put(r);
        },
        0x73 => {
            // The shifts of an XMM register by a constant (E147): of its two halves by
            // bits (/2 right, /6 left), of the whole by bytes (/3 right, /7 left).
            if p != 1 || !regs || jit_no >> 48 & 1 != 0 { return false; }
            let f = je.reg & 7;
            if f != 2 && f != 3 && f != 6 && f != 7 { return false; }
            let n = mem_rd(q + len - 1, 8) as! u32;
            if n == 0 { return true; }
            if n > (if f == 2 || f == 6 { 63 } else { 15 }) {
                e(0x4F000400 | (16 + (je.rm as u32)));       // movi #0
                x_put(je.rm);
                return true;
            }
            let d = x_get(je.rm);
            if f == 2 { e(0x6F000400 | (128 - n) << 16 | d << 5 | d); }      // ushr d.2d, d.2d, #n
            else if f == 6 { e(0x4F005400 | (64 + n) << 16 | d << 5 | d); }  // shl d.2d, d.2d, #n
            else {
                e(0x4F000400 | 1);                           // movi v1, #0
                if f == 3 { e(0x6E000000 | 1 << 16 | n << 11 | d << 5 | d); }        // ext d, d, v1, #n
                else { e(0x6E000000 | d << 16 | (16 - n) << 11 | 1 << 5 | d); }      // ext d, v1, d, #(16 - n)
            }
            x_put(je.rm);
        },
        0x71, 0x72 => {
            // The shifts of words and doublewords by a constant (E159): /2 right, /4 right
            // keeping the sign, /6 left. A count of the width or more leaves nothing, or
            // with the sign kept, the sign in every bit.
            if p != 1 || !regs || jit_no >> 37 & 1 != 0 { return false; }
            let f = je.reg & 7;
            if f != 2 && f != 4 && f != 6 { return false; }
            let w: u32 = if op2 == 0x71 { 16 } else { 32 };
            var n = mem_rd(q + len - 1, 8) as! u32;
            if n == 0 { return true; }
            if n >= w {
                if f != 4 {
                    e(0x4F000400 | (16 + (je.rm as u32)));   // movi #0
                    x_put(je.rm);
                    return true;
                }
                n = w - 1;
            }
            let d = x_get(je.rm);
            if f == 2 { e(0x6F000400 | (2 * w - n) << 16 | d << 5 | d); }            // ushr d, d, #n
            else if f == 4 { e(0x4F000400 | (2 * w - n) << 16 | d << 5 | d); }       // sshr d, d, #n
            else { e(0x4F005400 | (w + n) << 16 | d << 5 | d); }                     // shl d, d, #n
            x_put(je.rm);
        },
        0xF4 => {
            // PMULUDQ (E159): the low halves of the two quadwords, multiplied to 64 bits.
            if p != 1 || jit_no >> 37 & 1 != 0 { return false; }
            let s = x_srcv(1);
            let d = x_get(r);
            e(0x0EA12800 | d << 5 | 0);                      // xtn v0.2s, d.2d
            e(0x0EA12800 | s << 5 | 1);                      // xtn v1.2s, s.2d
            e(0x2EA0C000 | 1 << 16 | 0 << 5 | d);            // umull d.2d, v0.2s, v1.2s
            x_put(r);
        },
        0xC6 => {
            // SHUFPS: two of the four from the destination, two from the source; SHUFPD:
            // one of the two from each (E159).
            if p > 1 || jit_no >> 37 & 1 != 0 { return false; }
            let imm = mem_rd(q + len - 1, 8) as! u32;
            let s = x_srcv(1);
            let d = x_get(r);
            if p == 0 {
                for i in 4 {
                    let sel = imm >> ((i as! u32) * 2) & 3;
                    let from: u32 = if i < 2 { d } else { s };
                    e(0x6E000400 | ((i as! u32) << 3 | 4) << 16 | (sel << 2) << 11 | from << 5 | 2);      // mov v2.s[i], v.s[sel]
                }
            } else {
                for i in 2 {
                    let sel = imm >> (i as! u32) & 1;
                    e(0x6E000400 | ((i as! u32) << 4 | 8) << 16 | (sel << 3) << 11 | (if i == 0 { d } else { s }) << 5 | 2);   // mov v2.d[i], v.d[sel]
                }
            }
            x_mov(d, 2);
            x_put(r);
        },
        0x70 => {
            // PSHUFD: each of the four from the one the constant names.
            if p != 1 || jit_no >> 47 & 1 != 0 { return false; }
            let imm = mem_rd(q + len - 1, 8) as! u32;
            let s = x_srcv(1);
            for i in 4 {
                let sel = imm >> ((i as! u32) * 2) & 3;
                e(0x6E000400 | ((i as! u32) << 3 | 4) << 16 | (sel << 2) << 11 | s << 5 | 2);     // mov v2.s[i], s.s[sel]
            }
            x_mov(16 + (r as u32), 2);
            x_put(r);
        },
        0x60, 0x61, 0x62, 0x6C, 0x68, 0x69, 0x6A, 0x6D, 0xFC, 0xFD, 0xFE, 0xD4, 0xF8, 0xF9, 0xFA, 0xFB, 0x74, 0x75, 0x76, 0x64, 0x65, 0x66 => {
            // The packed integers' interleaving, sums, differences and comparisons (E147).
            if p != 1 { return false; }
            if jit_no >> 46 & 1 != 0 && op2 <= 0x6D && op2 != 0x64 && op2 != 0x65 && op2 != 0x66 { return false; }
            if jit_no >> 45 & 1 != 0 && (op2 == 0xD4 || op2 >= 0xF8) { return false; }
            if jit_no >> 44 & 1 != 0 && ((op2 >= 0x74 && op2 <= 0x76) || (op2 >= 0x64 && op2 <= 0x66)) { return false; }
            let s = x_srcv(1);
            let d = x_get(r);
            var w: u32 = 0;
            if op2 == 0x6C || op2 == 0x6D || op2 == 0xD4 || op2 == 0xFB { w = 3; }
            else if op2 >= 0x60 && op2 <= 0x62 { w = op2 - 0x60; }
            else if op2 >= 0x68 && op2 <= 0x6A { w = op2 - 0x68; }
            else if op2 >= 0xFC { w = op2 - 0xFC; }
            else if op2 >= 0xF8 { w = op2 - 0xF8; }
            else if op2 >= 0x74 { w = op2 - 0x74; }
            else { w = op2 - 0x64; }
            var base: u32 = 0;
            if op2 <= 0x62 || op2 == 0x6C { base = 0x4E003800; }             // zip1
            else if op2 <= 0x6D && op2 >= 0x68 { base = 0x4E007800; }        // zip2
            else if op2 == 0xD4 || op2 >= 0xFC { base = 0x4E208400; }        // add
            else if op2 >= 0xF8 { base = 0x6E208400; }                       // sub
            else if op2 >= 0x74 { base = 0x6E208C00; }                       // cmeq
            else { base = 0x4E203400; }                                      // cmgt
            e(base | w << 22 | s << 16 | d << 5 | d);
            x_put(r);
        },
        _ => { return false; },
    }
    return true;
}

// An x87 instruction (E161): a call to the interpreter's own routine (jit_x87, cpu64.goose),
// in a program without a kernel. The block reads the operand in memory and passes it, or
// stores what comes back, so the call touches none of the guest's memory or registers;
// the fourteen host registers a call may change that hold the guest's are kept on the
// stack round it. FCOMI and its kin get a record as UCOMISD's is, of a double that
// compares with 1.0 as the two registers do, and the host's flags from the same.
// FNSTSW AX, FCMOVcc and the forms that save or load the whole unit are not taken.
// --jit-off's bit 35 leaves all of it to the interpreter.
fn j_x87() -> bool {
    if machine || je.asz32 || je.sg != 0 || je.p66 || je.rep != 0 || jit_no >> 35 & 1 != 0 { return false; }
    let op = je.op;
    let r = je.reg & 7;
    var w: u64 = op;
    w |= (je.mod as u64) << 8 | (r as u64) << 10 | ((je.rm & 7) as u64) << 13;
    var n: u32 = 0;
    var store = false;
    var cmp = false;
    if je.mod == 3 {
        if op == 0xDF && r == 4 { return false; }                    // FNSTSW AX
        if (op == 0xDA || op == 0xDB) && r < 4 { return false; }     // FCMOVcc
        if (op == 0xDB || op == 0xDF) && (r == 5 || r == 6) {
            cmp = true;
            w |= 1 << 16;
            if op == 0xDF { w |= 1 << 17; }
        }
    } else {
        let bytes, st = fp_shape(op & 7, r, true);
        if bytes == 0 || bytes > 10 { return false; }
        n = bytes;
        store = st;
        w |= if st { 1 << 19 } else { 1 << 18 };
        j_addr();
        j_chk_n(st, 16);
    }
    e(0xA9800000 | 0x72 << 15 | 5 << 10 | 31 << 5 | 0);          // stp x0, x5, [sp, #-112]!
    a_stp(6, 7, 31, 16);
    for i in 5 { a_stp(8 + (i as! u32) * 2, 9 + (i as! u32) * 2, 31, 32 + (i as! u32) * 16); }
    if n != 0 && !store {
        a_rrr(A_ADD, 1, S3, MEMR, S1);
        a_ldp(1, 2, S3, 0);                                      // the sixteen bytes at the operand
    }
    a_imm(0, w);
    a_ldr(30, CTX, 200);
    // The host's flags, if a jump behind this may use them (FCOMI, FSTP, JA): kept in
    // x29, which a function gives back as it found it.
    let keep = j_hf != 0 && !cmp;
    if keep { e(0xD53B4200 | 29); }                              // mrs x29, nzcv
    e(0xD63F0000 | 30 << 5);                                     // blr x30
    if keep { e(0xD51B4200 | 29); }                              // msr nzcv, x29
    a_mov(1, S4, 0);
    for i in 5 { a_ldp(8 + (i as! u32) * 2, 9 + (i as! u32) * 2, 31, 32 + (i as! u32) * 16); }
    a_ldp(6, 7, 31, 16);
    e(0xA8C00000 | 14 << 15 | 5 << 10 | 31 << 5 | 0);            // ldp x0, x5, [sp], #112
    // The call may have changed the host's vectors (E160).
    xv_in = 0;
    ck_r = 0;
    ck_w = 0;
    ma_ok = false;
    if store {
        j_addr();
        j_store(if n == 2 { 16 } else if n == 4 { 32 } else { 64 }, S4);
        if n == 10 {
            a_ldr(S4, CTX, 208);
            a_addi(0x11, 1, S1, S1, 8);
            j_store(16, S4);
        }
    }
    if cmp {
        if j_dead { j_stale = true; j_dyn = false; }
        else {
            a_mov(1, FA, S4);
            a_imm(FB, 0x3FF0000000000000);
            a_imm(FK, 0x41);
            j_set = true;
            j_dyn = false;
            j_stale = false;
        }
        a_imm(S3, 0x3FF0000000000000);
        e(0x9E670000 | S4 << 5 | 0);                             // fmov d0, x4
        e(0x9E670000 | S3 << 5 | 1);                             // fmov d1, x3
        e(0x1E602000 | 1 << 16 | 0 << 5);                        // fcmp d0, d1
        j_hf = HF_FCMP;
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
    if len == 0 || len > room || so_n + 12 > SO_MAX { return 0; }
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
    j_dead = j_nohost || (jit_no >> 60 & 1 == 0 && (j_dead_past_jump(q + len, q + room, cnt) || j_dead_past_use(q + len, q + room, cnt)));
    let op = je.op;
    let k = jk;
    if k == 0 {
        // E176: six instructions with no operand in memory but LEAVE's, that a block was
        // left for some twelve million times in three files of the build.
        let plain = !je.asz32 && je.sg == 0 && je.rep == 0 && !je.p66 && jit_no2 & 64 == 0;
        if op == 0xFC || op == 0xFD {
            // CLD and STD: DF, in RFLAGS as the blocks have it in memory.
            if !plain { return 0; }
            a_ldr(29, CTX, 0);
            e((if op == 0xFC { 0x12000000 } else { 0x32000000 }) | 1 << 31 | a_logimm(if op == 0xFC { ~(0x400 as u64) } else { 0x400 }, 1) << 10 | 29 << 5 | 29);
            a_str(29, CTX, 0);
            return len;
        }
        if op == 0xFA {
            // CLI, at level 0 (no I/O privilege level stands above it): IF cleared.
            if !plain || !machine || cpl != 0 { return 0; }
            a_ldr(29, CTX, 0);
            e(0x12000000 | 1 << 31 | a_logimm(~(0x200 as u64), 1) << 10 | 29 << 5 | 29);
            a_str(29, CTX, 0);
            return len;
        }
        if op == 0xC9 {
            // LEAVE: RBP's word is read before anything is changed.
            if !plain || je.rex != 0 || machine && jit_no >> 56 & 1 != 0 { return 0; }
            a_mov(1, S1, hg(5));
            j_chk(false);
            j_load(64, S3);
            a_addi(0x11, 1, hg(4), hg(5), 8);
            a_mov(1, hg(5), S3);
            return len;
        }
        if op == 0x0F && plain {
            let op2 = mem_rd(q + je.plen, 8) as! u8;
            let b = mem_rd(q + je.plen + 1, 8) as! u8;
            if op2 == 0x31 {
                // RDTSC is the count of instructions (cpu64.goose): the time the block was
                // given is what was left of the run's (jx[34]) when it was entered, so
                // the count before this instruction is that less x0, and the instructions
                // of the block before this one. Not under --jit-check, whose blocks are
                // given their own length for time.
                if jit_check { return 0; }
                a_ldr(29, CTX, 272);
                a_rrr(A_SUB, 1, 29, 29, 0);
                if cnt != 0 { a_addi(0x11, 1, 29, 29, cnt as! u32); }
                e(0x2A0003E0 | 29 << 16 | hg(0));            // mov w(RAX), w29
                a_shifti(5, 1, hg(2), 29, 32);
                return len;
            }
            if op2 == 0xAE && b >= 0xE8 { return len; }      // LFENCE, MFENCE, SFENCE: nothing here
            if op2 == 0x01 && b == 0xF8 {
                // SWAPGS, at level 0: GS's base as the block has it (jx[18]) and the one
                // kept aside (jx[33]) change places; jit_enter takes both back.
                if !machine || cpl != 0 { return 0; }
                a_ldr(29, CTX, 144);
                a_ldr(30, CTX, 264);
                a_str(30, CTX, 144);
                a_str(29, CTX, 264);
                return len;
            }
        }
        if op == 0x87 {
            // XCHG of a register with a register or memory, 32 or 64 bits (E177).
            if !plain || jit_no2 & 128 != 0 { return 0; }
            let sf: u32 = if je.osz == 64 { 1 } else { 0 };
            let r = hg(je.reg);
            if je.mod == 3 {
                a_mov(sf, S3, hg(je.rm));
                a_mov(sf, hg(je.rm), r);
                a_mov(sf, r, S3);
            } else {
                if machine && jit_no >> 56 & 1 != 0 { return 0; }
                j_addr(); j_chk(true); j_load(je.osz, S3);
                j_store(je.osz, r);
                a_mov(sf, r, S3);
            }
            return len;
        }
        if op == 0xFA || op == 0xC9 { return 0; }
        if op == 0x0F {
            let o2 = mem_rd(q + je.plen, 8) as! u8;
            if o2 == 0x31 || (o2 == 0xAE && mem_rd(q + je.plen + 1, 8) >= 0xE8) || (o2 == 0x01 && mem_rd(q + je.plen + 1, 8) == 0xF8) { return 0; }
        }
        // BT, BTS, BTR, BTC and the double shifts (E138), in a machine too.
        if op == 0x0F && !je.asz32 && je.sg == 0 && je.rep == 0 {
            let op2 = mem_rd(q + je.plen, 8) as! u8;
            let bt = j_bt_op();
            if bt != 255 { return if j_bt(q, len, bt) { len } else { 0 }; }
            if op2 == 0xA4 || op2 == 0xAC || op2 == 0xA5 || op2 == 0xAD { return if j_shd(q, len, op2) { len } else { 0 }; }
            if op2 == 0xB1 { return if j_cmpxchg() { len } else { 0 }; }
            if op2 == 0xC1 { return if j_xadd() { len } else { 0 }; }
            if op2 >= 0xC8 && op2 <= 0xCF {
                // BSWAP of 32 or 64 bits: REV.
                if je.p66 || jit_no >> 49 & 1 != 0 { return 0; }
                let i = hg(op2 & 7 | (je.rex & 1) << 3);
                e((if je.osz == 64 { 0xDAC00C00 } else { 0x5AC00800 }) | i << 5 | i);
                return len;
            }
        }
        if op >= 0xD8 && op <= 0xDF { return if j_x87() { len } else { 0 }; }
        // BSF and BSR, with F3h in front or not (the interpreter's CPU has no TZCNT).
        if op == 0x0F && !je.asz32 && je.sg == 0 {
            let op2 = mem_rd(q + je.plen, 8) as! u8;
            if op2 == 0xBC || op2 == 0xBD { return if j_bsf(op2 == 0xBC) { len } else { 0 }; }
        }
        // An SSE instruction. In a machine (E139) the operating system may have taken the
        // unit away (CR0.TS, CR0.EM, CR4.OSFXSR): the block is told on entry, and leaves
        // before the instruction, for the interpreter to fault. The two instructions of
        // that are put in first and made NOPs if the instruction is not taken after all
        // (the code's array only grows).
        if je.asz32 || je.sg != 0 || jit_no >> 57 & 1 != 0 { return 0; }
        if machine && jit_no >> 51 & 1 != 0 { return 0; }
        let at = jc.len;
        if machine { a_ldr(29, CTX, 176); j_leave(29, false); }
        if j_sse(q, len) { return len; }
        if machine { e_at(at, 0xD503201F); e_at(at + 4, 0xD503201F); so_n -= 1; }
        return 0;
    }
    // (A NOP may have the prefix 66h: the compiler's padding in front of a loop.)
    // (And MOV is taken with it: 16 bits moved.) Since E138 the ALU operations, CMP,
    // TEST, the shifts by a constant, NOT, NEG and MOV of a constant are too, on 16 bits
    // as the byte forms are on 8: shifted up in a 32-bit host register, and the low bits
    // of the guest's register put back.
    if je.asz32 || (je.p66 && je.osz != 16) { return 0; }
    let n16 = je.p66 && (jit_no >> 52 & 1 == 0) && (k == K_ALU || k == K_GRP1 || k == K_ALUA || k == K_TEST || k == K_TESTA || k == K_GRP3 || k == K_SHIFTI || k == K_SHIFT || k == K_MOVI);
    if je.p66 && !n16 && k != K_NOP && k != K_NOPM && k != K_MOV && k != K_MOVMI { return 0; }
    if je.rep != 0 && k != K_NOP && k != K_NOPM { return 0; }
    // (--jit-off's low 32 bits are kinds; the bits above are the translator's parts, and
    // were taken for the kinds of the conditional jumps and moves as well until E155.)
    if k < 32 && jit_no >> k & 1 != 0 { return 0; }
    let sf: u32 = if je.osz == 64 { 1 } else { 0 };
    let r = hg(je.reg);
    let m = hg(je.rm);
    let regs = je.mod == 3;
    let wide = op & 1 == 1;              // not a byte, for the opcodes whose low bit says so
    let narrow = !wide || n16;           // a byte, or 16 bits (E138)
    let nb: u8 = if wide { 16 } else { 8 };    // and which, where narrow
    // An operand in memory, a push or a pop: in a machine through the TLB (E133), which
    // --jit-off's bit 56 leaves to the interpreter as before.
    let inmem = !regs && (!machine || jit_no >> 56 & 1 == 0);
    let stack = !machine || jit_no >> 56 & 1 == 0;
    let wb: u8 = if wide { je.osz } else { 8 };

    if k >= K_SETCC {
        if regs && !j_byte_ok(je.rm) { return 0; }
        if !regs && (!inmem || jit_no2 & 128 != 0) { return 0; }
        let c = j_cond(k & 15);
        if c == C_NONE { return 0; }
        if !regs {
            // Into memory (E177): the address and its checks change no host flag.
            j_addr(); j_chk_n(true, 1);
            e(0x1A9F07E0 | (c ^ 1) << 12 | S4);              // cset w4, c
            j_store(8, S4);
            return len;
        }
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
            // To this block's own first instruction, with no record owed there (E164): room
            // for the way back in line, which is filled in when the block is whole.
            if off + len + d == 0 && so_how[so_n] == 0 && !jit_check && jit_no >> 63 == 0 && jit_no >> 39 & 1 == 0 && sl_n < SS_MAX {
                sl_so[sl_n] = so_n;
                sl_n += 1;
                so_n += 1;
                e(0);
                for i in 5 { e(0xD503201F); }
            } else {
                so_n += 1;
                e(0);
            }
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
            if (ak == 2 || ak == 3) && (narrow || !j_carry_ok()) { return 0; }    // (the carry would go in at bit 0 of the shifted-up operands)
            if narrow {
                // Bytes: both registers must be ones a byte of which is their low byte.
                if !j_nok(je.reg, nb) || (regs && !j_nok(je.rm, nb)) { return 0; }
                if regs {
                    if op & 2 == 0 { j_alu_n(ak, false, m, r, 0, nb); if ak != 7 { a_bfi_low(m, S4, nb); } }
                    else { j_alu_n(ak, false, r, m, 0, nb); if ak != 7 { a_bfi_low(r, S4, nb); } }
                } else if op & 2 != 0 {
                    j_addr(); j_chk(false); j_load(nb, S3);
                    j_alu_n(ak, false, r, S3, 0, nb);
                    if ak != 7 { a_bfi_low(r, S4, nb); }
                } else {
                    j_addr(); j_chk(ak != 7); j_load(nb, S3);
                    j_alu_n(ak, false, S3, r, 0, nb);
                    if ak != 7 { j_store(nb, S4); }
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
            if (ak == 2 || ak == 3) && (narrow || !j_carry_ok()) { return 0; }    // (the carry would go in at bit 0 of the shifted-up operands)
            let v = if op != 0x81 { j_const(q + len - 1, 1) } else if n16 { j_const(q + len - 2, 2) } else { j_const(q + len - 4, 4) };
            if narrow {
                if regs && !j_nok(je.rm, nb) {
                    // AH, CH, DH, BH: the register's second byte out, and the result back.
                    let whole = hg(je.rm - 4);
                    e(0x53083C00 | whole << 5 | S3);                 // ubfx w3, w, #8, #8
                    j_alu8(ak, false, S3, ZR, v);
                    if ak != 7 { e(0xB3781C00 | S4 << 5 | whole); }  // bfi x, x4, #8, #8
                } else if regs {
                    j_alu_n(ak, false, m, ZR, v, nb);
                    if ak != 7 { a_bfi_low(m, S4, nb); }
                } else {
                    j_addr(); j_chk(ak != 7); j_load(nb, S3);
                    j_alu_n(ak, false, S3, ZR, v, nb);
                    if ak != 7 { j_store(nb, S4); }
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
            if (ak == 2 || ak == 3) && (narrow || !j_carry_ok()) { return 0; }    // (the carry would go in at bit 0 of the shifted-up operands)
            if narrow {
                j_alu_n(ak, false, hg(0), ZR, if wide { mem_rd(q + len - 2, 16) } else { mem_rd(q + len - 1, 8) }, nb);
                if ak != 7 { a_bfi_low(hg(0), S4, nb); }
            } else {
                j_alu_i(ak, hg(0), hg(0), j_const(q + len - 4, 4), S1);
            }
        },
        K_TEST => {
            if !(regs || inmem) { return 0; }
            if narrow {
                if !j_nok(je.reg, nb) || (regs && !j_nok(je.rm, nb)) { return 0; }
                if regs { j_alu_n(4, true, m, r, 0, nb); }
                else { j_addr(); j_chk(false); j_load(nb, S3); j_alu_n(4, true, S3, r, 0, nb); }
            } else if regs { j_alu(4, true, 0, m, r); }
            else { j_addr(); j_chk(false); j_load(wb, S3); j_alu(4, true, 0, S3, r); }
        },
        K_TESTA => {
            if narrow { j_alu_n(4, true, hg(0), ZR, if wide { mem_rd(q + len - 2, 16) } else { mem_rd(q + len - 1, 8) }, nb); }
            else {
                let v = j_const(q + len - 4, 4);
                let c = if jit_no >> 34 & 1 == 0 { a_logimm(v, sf) } else { 0xFFFFFFFF };
                if c != 0xFFFFFFFF {
                    j_rec_alu(5, je.osz, ZR, hg(0), 255, v);
                    e(0x72000000 | sf << 31 | c << 10 | hg(0) << 5 | ZR);        // tst by the constant
                    j_hf = HF_LOGIC;
                } else {
                    a_imm(S1, v);
                    j_alu(4, true, 0, hg(0), S1);
                }
            }
        },
        K_MOV => {
            if je.p66 {
                // Sixteen bits: the rest of a register stays.
                if !wide || je.osz != 16 || !(regs || inmem) { return 0; }
                if regs {
                    if op & 2 == 0 { e(0xB3403C00 | r << 5 | m); } else { e(0xB3403C00 | m << 5 | r); }      // bfi #0, #16
                } else if op & 2 == 0 { let ar = j_ea(true); j_store_at(ar, 16, r); }
                else { let ar = j_ea(false); j_load_at(ar, 16, S3); e(0xB3403C00 | S3 << 5 | r); }
                return len;
            }
            if regs {
                if !wide { return 0; }
                if op & 2 == 0 { a_mov(sf, m, r); } else { a_mov(sf, r, m); }
            } else {
                if !inmem || (!wide && !j_byte_ok(je.reg)) { return 0; }
                if op & 2 == 0 { let ar = j_ea(true); j_store_at(ar, wb, r); }
                else {
                    let ar = j_ea(false);
                    if wide { j_load_at(ar, wb, r); }
                    else { j_load_at(ar, 8, S3); e(0xB3401C00 | S3 << 5 | r); }      // bfi xr, x3, #0, #8
                }
            }
        },
        K_LEA => {
            if regs { return 0; }
            // Into its register (E163), unless that is the index, which is read last.
            if sf == 0 && je.base >= 16 && je.base != 17 && je.index < 16 && je.disp == 0 && jit_no >> 32 & 1 == 0 {
                // An index alone, to 32 bits: one shift.
                if je.scale == 0 { a_mov(0, r, hg(je.index)); }
                else { a_shifti(4, 0, r, hg(je.index), je.scale); }
                return len;
            }
            let t = if (je.index < 16 && hg(je.index) == r) || jit_no >> 32 & 1 != 0 { S1 } else { r };
            j_lea_into(t);
            if t != r { a_mov(sf, r, t); }
            else if sf == 0 { a_mov(0, r, r); }
        },
        K_MOVZX8 => {
            if regs {
                if j_byte_ok(je.rm) { e(0x12001C00 | m << 5 | r); }          // and wr, wm, #0xFF
                else { e(0x53083C00 | hg(je.rm - 4) << 5 | r); }             // AH, CH, DH, BH: ubfx wr, w, #8, #8
            }
            else { if !inmem { return 0; } let ar = j_ea(false); j_load_at(ar, 8, r); }
        },
        K_MOVZX16 => {
            if regs { e(0x12003C00 | m << 5 | r); }          // and wr, wm, #0xFFFF
            else { if !inmem { return 0; } let ar = j_ea(false); j_load_at(ar, 16, r); }
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
            if n16 { a_imm(S4, mem_rd(q + len - 2, 16)); a_bfi_low(hg(low), S4, 16); return len; }
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
            // Sixteen bits (E138): of a register, by a constant, a shift.
            if n16 && !(regs && which >= 4 && op != 0xD2 && op != 0xD3) { return 0; }
            if regs && wide && !n16 && which < 2 {
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
            if regs && narrow && which >= 4 && op != 0xD2 && op != 0xD3 {
                // A byte, or 16 bits, shifted by a constant: on 32 bits, and the low
                // bits put back.
                if !j_nok(je.rm, nb) { return 0; }
                let n = if op == 0xD0 || op == 0xD1 { 1 } else { mem_rd(q + len - 1, 8) & 0x1F };
                if n == 0 { return 0; }
                if !j_dead { a_imm(S1, n); }             // (the count, for the record only: E163)
                j_rec_w(0x20 | (which as u32), nb, m, S1);
                let bits: u32 = nb;
                let by = n as! u32;
                if jit_no >> 41 & 1 == 0 && (which == 4 || which == 6) { a_shifti(which, 0, S4, m, by); }       // left: what goes above is not put back
                else if jit_no >> 41 & 1 == 0 && by < bits {
                    // Right (E164): the bits that stay, taken out in one (ubfx, or sbfx with the sign).
                    e((if which == 7 { 0x13000000 } else { 0x53000000 }) | by << 16 | (bits - 1) << 10 | m << 5 | S4);
                } else {
                    if which == 7 { e((if nb == 8 { 0x13001C00 } else { 0x13003C00 }) | m << 5 | S4); }   // sxtb, sxth
                    else { e((if nb == 8 { 0x12001C00 } else { 0x12003C00 }) | m << 5 | S4); }           // and #0xFF, #0xFFFF
                    a_shifti(which, 0, S4, S4, by);
                }
                a_bfi_low(m, S4, nb);
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
                if !j_dead { a_imm(S1, n); }
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
            if narrow {
                // TEST of a byte, or of 16 bits, with a constant; NOT and NEG of a register.
                if field > 3 || (field > 1 && !regs) || !(regs || inmem) { return 0; }
                if field == 2 {
                    if !j_nok(je.rm, nb) { return 0; }
                    e(0x2A2003E0 | m << 16 | S4);            // mvn w4, wm
                    a_bfi_low(m, S4, nb);
                    return len;
                }
                if field == 3 {
                    if !j_nok(je.rm, nb) { return 0; }
                    j_alu_n(5, false, ZR, m, 0, nb);
                    a_bfi_low(m, S4, nb);
                    return len;
                }
                let v = if wide { mem_rd(q + len - 2, 16) } else { mem_rd(q + len - 1, 8) };
                if !regs { j_addr(); j_chk(false); j_load(nb, S3); j_alu_n(4, true, S3, ZR, v, nb); }
                else if j_nok(je.rm, nb) { j_alu_n(4, true, m, ZR, v, nb); }
                else { e(0x53083C00 | hg(je.rm - 4) << 5 | S3); j_alu8(4, true, S3, ZR, v); }       // AH, CH, DH, BH
                return len;
            }
            if !wide { return 0; }
            if !regs {
                // TEST of memory with a constant (E147).
                if field > 1 || !inmem { return 0; }
                j_addr(); j_chk(false); j_load(wb, S3);
                a_imm(S4, j_const(q + len - 4, 4));
                j_alu(4, true, 0, S3, S4);
                return len;
            }
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
            if field == 6 {
                // PUSH of memory (E177): the operand is read before the stack is touched.
                if op != 0xFF || !stack || regs || !inmem || jit_no2 & 128 != 0 { return 0; }
                j_addr(); j_chk(false); j_load(64, S4);
                j_push(S4);
                return len;
            }
            if !wide || field > 1 { return 0; }
            if !regs {
                // INC and DEC of memory (E147): as of a register, the flags dead or the
                // block's first.
                if !inmem { return 0; }
                let dead = j_flags_dead(q + len, q + room);
                if !dead && j_set { return 0; }
                j_addr(); j_chk(true); j_load(wb, S3);
                if dead { a_addi(if field == 0 { 0x11 } else { 0x51 }, sf, S4, S3, 1); j_stale = true; }
                else {
                    j_needs = true;
                    j_rec(16 + (field as u32), S3, ZR);
                    a_addi(if field == 0 { 0x31 } else { 0x71 }, sf, S4, S3, 1);
                    j_hf = HF_INCDEC;
                }
                j_store(wb, S4);
                return len;
            }
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

// --jit-time: the blocks there are, by how often each was run; and the counts cleared.
fn jit_tally() {
    for slot in DC_SIZE {
        if dc_n[slot] != 0 {
            let r = dc_runs[slot];
            if r == 0 { jr_never += 1; } else if r < 8 { jr_few += 1; } else { jr_many += 1; }
        }
        dc_runs[slot] = 0;
    }
}

// Forgets every block: the room for code is full.
fn jit_flush() {
    if jit_time { jit_tally(); }
    for slot in DC_SIZE {
        if dc_n[slot] != 0 { dc[slot].ins.kind = dc_k0[slot]; dc_n[slot] = 0; }
        dc_wait[slot] = 0;
        // Arrivals are counted from nothing again: a count left at its top would never
        // come to J_HOT, and what was translated before would be interpreted for good.
        dc_heat[slot] = 0;
        dc_cov[slot] = 0;
    }
    for i in MEM_SIZE >> 12 { jit_page[i] = 0; }
    bt_clear();
    for i in 1 << JH_BITS { jh[i] = 0; }
    jt_clear();
    jcell_n = 0;
    j_used = j_keep;
    j_flushes += 1;
}

// Translates what begins at physical address ph, and what follows it on the page: a block
// to a jump or to an instruction that is not translated, then the next block after that
// instruction or at the jump's other side, as far as the decode cache knows the
// instructions.
fn jit_translate(ph: u64) {
    if !jit_time { jit_translate_in(ph); return; }
    let t0 = jit_now();
    jit_translate_in(ph);
    jt_translate += jit_now() - t0;
}

fn jit_translate_in(ph: u64) {
    var q = ph;
    let page_end = (ph | 0xFFF) + 1;
    var walked = 0;
    while walked < 200 && q < page_end {
        let head = q;
        let head_slot = dc_find(head);
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
        sl_n = 0;
        ck_r = 0;
        ck_w = 0;
        ma_ok = false;
        j_stale = false;
        xv_in = 0;
        tp_n = 0;
        j_head = head;
        j_needs = false;
        // What an entry from another block needs: time for the whole block, no record
        // waiting if the block reads RFLAGS in memory, and RIP.
        // (Six words, filled in when it is known whether the block reads RFLAGS: below.)
        for i in 6 { e(0); }
        sh_n = 0;
        if jit_time {
            // The block counts its runs (dc_runs, by its entry): x29 and x30 are free here.
            a_ldr(29, CTX, 184);
            a_imm(S2, (head_slot as u64) * 4);
            a_rrr(A_ADD, 1, 29, 29, S2);
            e(0xB9400000 | 29 << 5 | 30);                    // ldr w30, [x29]
            a_addi(0x11, 0, 30, 30, 1);
            e(0xB9000000 | 29 << 5 | 30);                    // str w30, [x29]
        }
        var n = 0;
        while n < J_MAX {
            if !j_entry(q) { if jit_why { jq[6] += 1; } break; }
            let qs = j_eslot;
            let len = j_one(q, q - head, page_end - q, n as! u64);
            if len == 0 { if jit_why { jq[7] += 1; } break; }
            cv_slot[n] = qs;
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
                so_at[i] = jc.len;
                e_at(at, so_op[i] | (((jc.len - at) >> 2) as! u32) << 5);
                j_stale = so_stale[i];
                if so_how[i] != 0 { j_sink_emit(so_how[i], so_ska[i], so_skb[i], so_ski[i], so_skw[i]); }
                j_exit(so_off[i], so_cnt[i], so_link[i]);
            }
            if j_used + jc.len + 64 > J_SIZE { jit_flush(); return; }
            // The way in from another block (E170), right before the body: the branch
            // out, `cmp x0, #n`, `b.lo` back to it, and RIP; and between, in a block that
            // reads RFLAGS in memory, a record that waits is settled (E146), or the block
            // left if it is not of a kind that can be. The entry is the `cmp`.
            let lead = j_lead(j_needs);
            let in_at = BODY_AT - lead;
            e_at(in_at - 4, 0x14000000 | (((j_out_at - (j_used + in_at - 4)) >> 2) as! u32) & 0x3FFFFFF);
            e_at(in_at, 0xF100001F | (n as! u32) << 10);     // cmp x0, #n
            e_at(in_at + 4, 0x54000003 | 0x7FFFE << 5);      // b.lo two back: the branch out
            if j_needs {
                if jit_no >> 50 & 1 == 0 {
                    e_at(in_at + 8, 0xB4000047);             // cbz x7, two on
                    e_at(in_at + 12, 0x94000000 | (((j_settle_at - (j_used + in_at + 12)) >> 2) as! u32) & 0x3FFFFFF);       // bl
                } else {
                    e_at(in_at + 8, 0xB5000007 | 0x7FFFD << 5);          // cbnz x7, three back: the branch out
                    e_at(in_at + 12, 0xD503201F);
                }
            }
            e_at(BODY_AT - 4, 0xAA0003E0 | S1 << 16 | RIPB);  // mov x25, x1
            // The branches back to this block's own entry.
            for i in sh_n { e_at(sh_pos[i], 0x14000000 | (((in_at - sh_pos[i]) >> 2) as! u32) & 0x3FFFFFF); }
            if !j_needs {
                for i in sl_n {
                    let w = sl_so[i];
                    let at = so_pos[w];
                    let c = so_op[w] & 15;
                    let took = so_cnt[w] as! u32;
                    e_at(at, 0x54000000 | 6 << 5 | (c ^ 1));                                         // b.(not c) over the five
                    e_at(at + 4, 0xD1000000 | took << 10);                                           // sub x0, x0, #cnt
                    e_at(at + 8, 0xF100001F | (n as! u32) << 10);                                    // cmp x0, #n
                    e_at(at + 12, 0x54000002 | ((((BODY_AT - (at + 12)) >> 2) as! u32) & 0x7FFFF) << 5);  // b.hs the body
                    e_at(at + 16, 0x91000000 | took << 10);                                          // add x0, x0, #cnt: no time for a round
                    e_at(at + 20, 0x14000000 | (((so_at[w] - (at + 20)) >> 2) as! u32) & 0x3FFFFFF); // b the way out
                }
                for i in ss_n {
                    let at = ss_pos[i];
                    e_at(at, 0xF100001F | (n as! u32) << 10);                                        // cmp x0, #n
                    e_at(at + 4, 0x54000002 | ((((BODY_AT - (at + 4)) >> 2) as! u32) & 0x7FFFF) << 5);    // b.hs the body
                }
            }
            // The exits that wait for a block are chained by the address they wait for,
            // from the first way's slot of that address whichever way its entry is in,
            // through the word behind each (E145: no table, so none is left out).
            for i in tp_n {
                let ws = dc_slot(tp_to[i]);
                e_at(tp_pos[i] + 4, dc_wait[ws]);
                dc_wait[ws] = (j_used + tp_pos[i] + 1) as! u32;
            }
            if jit_why { jh_bytes[0] += jc.len; jh_bytes[1] += if so_n > 0 { so_at[0] } else { jc.len }; }
            jit_write(j_mem + j_used, jc[..]);
            // The ones that waited for this are made branches to it; the ones in the same
            // chain that wait for another address are chained again.
            let wk = dc_slot(head);
            var w = dc_wait[wk];
            var kept: u32 = 0;
            while w != 0 {
                let site = (w - 1) as! i64;
                let next = (jit_peek64(j_mem + site + 4) & 0xFFFFFFFF) as! u32;
                let to = jit_peek64(j_mem + site + 8) as! u64;
                let lv = (jit_peek64(j_mem + site + 16) & 0xFF) as! u8;
                if to == head && lv == cpl { j_patch(site, j_used + in_at); }
                else {
                    if next != kept { j_poke32(site + 4, kept); }
                    kept = w;
                }
                w = next;
            }
            dc_wait[wk] = kept;
            jit_page[(head >> 12) as! i64] = 1;
            dc_code[head_slot] = (j_used + in_at) as! u32;
            dc_n[head_slot] = n as! u8;
            dc_cpl[head_slot] = cpl;
            dc_needs[head_slot] = if j_needs { 1 } else { 0 };
            if jit_no2 & 2 == 0 { bt_put(head, (j_used + in_at) as! u32, n as! u8, cpl, j_needs); }
            dc_k0[head_slot] = dc[head_slot].ins.kind;
            dc[head_slot].ins.kind = 0;
            j_used += jc.len;
            j_bytes += jc.len as! u64;
            j_blocks += 1;
            for i in n { dc_cov[cv_slot[i]] = 1; }
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

// All the code generated so far, for --jit-dump: to be read with a disassembler
// (objdump -D -b binary -m aarch64). The way in and the way out come first.
fn jit_dump() -> u8[>..] {
    var out: u8[>..] = [];
    var at = 0;
    while at < j_used {
        let v = jit_peek64(j_mem + at) as! u64;
        for i in 8 { if at + i < j_used { out.push((v >> ((i * 8) as! u64)) as! u8); } }
        at += 8;
    }
    return out;
}

// The interpreter is about to run the instruction in the decode cache's entry slot, at
// physical address ph, and it is no block's first: an arrival, counted, and translated at
// the J_HOT-th (E137). Until E137 only a jump's landing was one, and an instruction behind
// one the translator could not measure was interpreted for good. An instruction that is
// inside a block already (dc_cov) counts only where a jump lands on it: the interpreter
// runs such an instruction when the block was refused or left for the time slice, and a
// block made from each place it was left at would be the same block again, shorter (the
// first E137 run: twice the blocks and bytes). True if a block begins there now.
inline fn jit_arrive(slot: i64, ph: u64) -> bool {
    if !jit_land && dc_cov[slot] != 0 { return false; }
    if dc_heat[slot] < 255 { dc_heat[slot] += 1; }
    // (Counted on past J_HOT, so that an instruction no block can begin at is tried once.)
    if dc_heat[slot] != J_HOT { return false; }
    jit_translate(ph);
    return dc_n[slot] != 0;
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
    else if what == 0x52 || what == 0x53 {
        // BSF and BSR, as the interpreter has them.
        let v = jx[1] & mask(w);
        if v == 0 { rflags = rflags & ~ARITH | ZF | PF; }
        else {
            var n: u64 = 0;
            if what == 0x52 { while v >> n & 1 == 0 { n += 1; } }
            else { n = (w as u64) - 1; while v >> n & 1 == 0 { n -= 1; } }
            rflags = rflags & ~ARITH | PARITY[n];
        }
    }
    else if what == 0x50 { rflags = rflags & ~CF | jx[1] >> (jx[2] & ((w as u64) - 1)) & 1; }       // BT: CF alone
    else if what == 0x60 || what == 0x61 { shift_double(what == 0x60, jx[1], jx[2], fk >> 16 & 0xFF, w); }
    else if what == 0x40 || what == 0x41 { sse64_comis(what == 0x40, jx[1], jx[2]); }
    else { shift(what & 7, jx[1], jx[2], w, false); }
}

// Runs the block whose first instruction is the one at hand (dc_cur). False if it may not
// be run now: the instruction is then interpreted.
fn jit_enter() -> bool {
    let slot = dc_cur;
    let n: u64 = dc_n[slot];
    if jit_hold || steps + n > rep_until || dc_cpl[slot] != cpl {
        if jit_why { if steps + n > rep_until { jq[0] += 1; } else if dc_cpl[slot] != cpl { jq[1] += 1; } }
        return false;
    }
    jx[17] = fs_base;
    jx[18] = gs_base;
    // (x28 for the blocks: the TLB's tables in a machine, dc_mark in a program, E150.)
    // (In a machine: this level's table for reads, E171; a store's is two tables on.)
    jx[6] = if machine { jx[19] + (if cpl == 3 { 16 * TLB_SIZE } else { 0 }) } else { j_mark_at };
    jx[22] = if machine && (cr4 & 0x200 == 0 || cr0 & 0xC != 0) { 1 } else { 0 };
    // (For SWAPGS and RDTSC in a block, E176.)
    jx[33] = msr_kernel_gs;
    jx[34] = rep_until;
    if jit_check { return jit_both(slot, n); }
    var t0: i64 = 0;
    var t1: i64 = 0;
    var t2: i64 = 0;
    if jit_time { t0 = jit_now(); }
    jx[0] = rflags;
    let time = rep_until - steps;
    jx[9] = time;
    jx[24] = 0;
    if jit_time { t1 = jit_now(); }
    jit_call4(j_mem, j_regs, j_ctx, j_mem + dc_code[slot] + j_lead(dc_needs[slot] != 0), rip as! i64);
    if jit_time { t2 = jit_now(); }
    // (An x87 opcode that is not written, met in a block: stopped at here, E161.)
    if fp_bad != 0 { stop64("an x87 instruction not written yet, opcode and ModRM", fp_bad as! u64); }
    let ran = time - jx[9];
    // An instruction was left to the interpreter (a page not in the TLB, mostly): the
    // one behind it is taken as landed on, so that after eight leavings at one place a
    // block is made for the rest of the run, which was interpreted to the next jump
    // (E155). Not the instruction left itself: a block from there would leave at once.
    let left = jx[24] != 0 && jit_no >> 38 & 1 == 0;
    // Left before its first instruction: that one is interpreted.
    if ran == 0 {
        if jit_time { jt_enter += t2 - t0; jt_body += t2 - t1; }
        if left { jit_land = true; }
        if jit_why { jq[if left { 2 } else { 3 }] += 1; jq_k[(dc_k0[slot] & 63) as i64] += 1; if dc_needs[slot] != 0 { jq[4] += 1; } }
        return false;
    }
    // (RFLAGS as the blocks left it in memory: a record settled on the way into one, E146.)
    rflags = jx[0];
    rip = jx[4];
    gs_base = jx[18];
    msr_kernel_gs = jx[33];
    j_settle();
    // Where the block went is where a jump landed; or, an instruction left, behind it.
    jit_land = !left;
    jit_resume = left;
    steps += ran - 1;
    j_entered += 1;
    j_ran += ran;
    if jit_why { steps += 1; jit_went(); steps -= 1; }
    if jit_time { let t3 = jit_now(); jt_enter += t3 - t0; jt_body += t2 - t1; }
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
    fpu_keep(0);
    let f0 = rflags;
    jx[0] = rflags;
    jx[7] = 0;
    jx[9] = n;
    jit_call4(j_mem, j_regs, j_ctx, j_mem + dc_code[slot] + j_lead(dc_needs[slot] != 0), rip as! i64);
    let ran = n - jx[9];
    if ran == 0 { return false; }
    // (RFLAGS as the block left it in memory: CLI, CLD and STD change it there, E176.)
    rflags = jx[0];
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
    fpu_keep(1);
    fpu_back(0);
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
    let bad_x87 = !fpu_same(1);
    if bad_x87 { bad = true; }
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
