// The large arrays. Nothing imports this file except g86m.goose, which imports it last, and that
// is the point: Goose lays globals out in the order their files are first imported, and generated
// code reaches a global by its offset from the start of that block. With 1 MB of RAM in the
// middle, everything declared after it sat more than a megabyte away, which costs extra
// instructions on every access to the CPU state. Declared here, the big arrays come last and the
// state every instruction touches stays near the start. (Names are visible program-wide, so the
// other files use these without importing this one.)

import state;

// Padding: Goose packs globals, and what follows is to sit at a multiple of 8 (E050;
// tools/layout.sh shows where each global is, and tools/difftest.sh checks these).
var pad_ram: u8[3] = [0; 3];
var ram: u8[RAM_SIZE];

// The decode cache: one entry per instruction address, by its low bits.
var dc: Decoded[DC_SIZE] = [Decoded { bytes: 0, mask: 0, pre: Pre { op: 0, plen: 0, osz: 16, asz32: false, lock: false, rep: 0, seg: -1, kind: 0 },
                                     tag: 0xFFFFFFFF, m: 0, disp: 0, imm: 0 }; DC_SIZE];

// For each entry with a short executor, the physical address of the instruction after it. It is
// apart from the entry so that a run gets from one instruction to the next by one load indexed
// by the slot, and does not wait for the entry itself (E028). Meaningful only when the entry's
// tag has matched.
var dc_next: u32[DC_SIZE];

// For each physical page of RAM: whether the decode cache holds an instruction of 32-bit code
// that begins in it (code_mark), and how many stores have had to look for such instructions
// since it was marked (code_hits). See code_written in state.goose.
var code_mark: u8[RAM_SIZE >> 12] = [0; RAM_SIZE >> 12];
var code_hits: u8[RAM_SIZE >> 12] = [0; RAM_SIZE >> 12];

// The JIT's (jit.goose). For each physical page, a number that moves on whenever a store may
// have changed an instruction in it; and for each entry of 32-bit code, how often a jump has
// arrived at it and, once it heads a block, the block: where its code is, its entry's own
// kind, how many instructions it is, where its last instruction begins, the page's number when it
// was made, and (the slot may come to hold another instruction) the address it begins at.
var code_gen: u32[RAM_SIZE >> 12] = [0; RAM_SIZE >> 12];
var dc_hot: u8[DC_HALF] = [0; DC_HALF];
var jit_code: i64[DC_HALF] = [0; DC_HALF];
var jit_kind: u8[DC_HALF] = [0; DC_HALF];
var jit_n: u8[DC_HALF] = [0; DC_HALF];
var jit_last: u32[DC_HALF] = [0; DC_HALF];
var jit_head: u32[DC_HALF] = [0xFFFFFFFF; DC_HALF];   // the address the slot's block begins at
var jit_gen: u32[DC_HALF] = [0; DC_HALF];

// Ports nothing answers: counted per port so a run can report what the guest probed.
var unknown_ports: u8[65536] = [0; 65536];

// How often each BIOS service was called, by interrupt number and AH. Reported by --ports.
var bios_calls: u32[65536] = [0; 65536];

// What the terminal currently shows, for the console; FFh forces a redraw.
var shown: u8[4000] = [0xFF; 4000];
