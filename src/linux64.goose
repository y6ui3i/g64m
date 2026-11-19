// Booting a 64-bit Linux kernel (E099) the way a boot loader for the 64-bit boot protocol
// does: no firmware and none of the kernel's own real-mode or 32-bit code. The kernel is
// put where it would like to be and entered 200h past that, in long mode, with what the
// protocol asks of whoever enters it there:
//   - paging on, with the kernel, the zero page and the command line mapped to themselves
//     (here: the whole first 4 GB, by 2 MB pages);
//   - a GDT with flat 64-bit code at selector 10h and flat data at 18h, loaded;
//   - interrupts off;
//   - RSI pointing at the zero page: a copy of the kernel's setup header with the boot
//     loader's fields filled in, and the memory map.
// (Documentation/arch/x86/boot.rst in the kernel's sources, "64-bit Boot Protocol".)

import std;
import cpu64;
import sys64;

let ZERO_PAGE = 0x10000;
let CMDLINE_AT = 0x20000;
let GDT_AT = 0x1000;
let TABLES_AT = 0x30000;         // six pages: one PML4, one PDPT, four page directories

// True if img is a Linux bzImage that may be entered in 64-bit mode.
fn is_kernel64(img: u8[:]) -> bool {
    return img.len > 0x268 && img[0x202] == 'H' && img[0x203] == 'd' && img[0x204] == 'r' && img[0x205] == 'S'
        && img[0x236] & 1 != 0;
}

fn put(at: u64, data: const u8[:]) {
    let base = at as! i64;
    for b, i in data { mem[base + i] = b; }
}

// One line of the memory map: base, size, and 1 for usable RAM or 2 for reserved.
fn map_line(index: u64, base: u64, size: u64, kind: u64) {
    let at = ZERO_PAGE + 0x2D0 + index * 20;
    mem_wr(at, 64, base);
    mem_wr(at + 8, 64, size);
    mem_wr(at + 16, 32, kind);
}

// Sets the machine up to run the kernel in img. Returns a message on failure, "" on success.
fn linux64_boot(img: u8[:], initrd: u8[:], cmdline: const u8[:]) -> const u8[:] {
    var setup_sects: i64 = img[0x1F1];
    if setup_sects == 0 { setup_sects = 4; }
    let body = (setup_sects + 1) * 512;
    if body >= img.len { return "the kernel image is shorter than its header says"; }
    var load: u64 = 0;
    for i in 8 { let b: u64 = img[0x258 + i]; load |= b << ((i * 8) as! u64); }       // where it would like to be
    var init_size: u64 = 0;
    for i in 4 { let b: u64 = img[0x260 + i]; init_size |= b << ((i * 8) as! u64); }  // what it needs there
    let top: u64 = MEM_SIZE;
    if load < 0x100000 || load + init_size + 0x200000 > top { return "the kernel does not fit in memory"; }
    put(load, img[body..]);
    put(CMDLINE_AT, cmdline);
    mem[CMDLINE_AT + cmdline.len] = 0;

    // The initramfs goes near the top of memory, page-aligned, with a megabyte to spare above.
    var initrd_at: u64 = 0;
    if initrd.len > 0 {
        let len = initrd.len as! u64;
        if load + init_size + len + 0x200000 > top { return "the initramfs does not fit in memory"; }
        initrd_at = (top - len - 0x100000) & 0xFFFFFFFFFFFFF000;
        put(initrd_at, initrd);
    }

    // The zero page: a copy of the setup header, then the fields a boot loader fills in.
    put(ZERO_PAGE + 0x1F1, img[0x1F1..0x268]);
    mem_wr(ZERO_PAGE + 0x06, 8, 0x03);           // video mode 3,
    mem_wr(ZERO_PAGE + 0x07, 8, 80);             // 80 columns,
    mem_wr(ZERO_PAGE + 0x0E, 8, 25);             // 25 lines,
    mem_wr(ZERO_PAGE + 0x0F, 8, 1);              // a VGA,
    mem_wr(ZERO_PAGE + 0x10, 16, 16);            // 16-pixel font
    mem_wr(ZERO_PAGE + 0x210, 8, 0xFF);          // boot loader type: none of the known ones
    mem_wr(ZERO_PAGE + 0x218, 32, initrd_at);
    mem_wr(ZERO_PAGE + 0x21C, 32, initrd.len as! u64);
    mem_wr(ZERO_PAGE + 0x228, 32, CMDLINE_AT);
    map_line(0, 0x00000000, 0x0009FC00, 1);
    map_line(1, 0x0009FC00, 0x00000400, 2);
    map_line(2, 0x000F0000, 0x00010000, 2);
    map_line(3, 0x00100000, top - 0x100000, 1);
    mem_wr(ZERO_PAGE + 0x1E8, 8, 4);

    mem_wr(GDT_AT + 16, 64, 0x00AF9A000000FFFF); // 10h: 64-bit code
    mem_wr(GDT_AT + 24, 64, 0x00CF92000000FFFF); // 18h: data
    gdt_base = GDT_AT;
    gdt_limit = 31;

    // The first 4 GB mapped to themselves: one entry of the top table, four of the next,
    // and four directories of 512 pages of 2 MB.
    mem_wr(TABLES_AT, 64, TABLES_AT + 0x1000 | 3);
    for i: u64 in 4 {
        mem_wr(TABLES_AT + 0x1000 + i * 8, 64, TABLES_AT + 0x2000 + i * 0x1000 | 3);
        for j: u64 in 512 { mem_wr(TABLES_AT + 0x2000 + i * 0x1000 + j * 8, 64, i << 30 | j << 21 | 0x83); }
    }
    machine = true;
    cpl = 0;
    cr0 = 0x80000011;
    cr3 = TABLES_AT;
    cr4 = 0x20;
    efer = 0x500;
    seg = [0x18, 0x10, 0x18, 0x18, 0x18, 0x18];
    rflags = 2;
    reg[RSI] = ZERO_PAGE;
    rip = load + 0x200;
    return "";
}
