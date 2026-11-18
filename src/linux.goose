// Booting a Linux kernel the way QEMU's -kernel does: no BIOS and no real-mode setup code. The
// kernel is placed at 1 MB and entered at its 32-bit entry point, with what the setup code would
// have gathered handed over in the "zero page". (Linux boot protocol, 32-bit entry.)

import std;
import state;
import dev;

let ZERO_PAGE = 0x10000;
let CMDLINE_AT = 0x20000;
let GDT_AT = 0x800;
let KERNEL_AT = 0x100000;

// True if img looks like a Linux bzImage: the setup header's magic is in place.
fn is_bzimage(img: u8[:]) -> bool {
    return img.len > 0x268 && img[0x202] == 'H' && img[0x203] == 'd' && img[0x204] == 'r' && img[0x205] == 'S';
}

fn copy_to(at: u32, data: u8[:]) {
    for b, i in data { set_mem8(at + (i as! u32), b); }
}

// One line of the memory map: base, size, and 1 for usable RAM or 2 for reserved.
fn e820(index: u32, base: u32, size: u32, kind: u32) {
    let at = ZERO_PAGE + 0x2D0 + index * 20;
    set_mem32(at, base);
    set_mem32(at + 4, 0);
    set_mem32(at + 8, size);
    set_mem32(at + 12, 0);
    set_mem32(at + 16, kind);
}

// The frame buffer the kernel is told of (E078): fb_w by fb_h pixels of four bytes (nothing,
// red, green, blue) at fb_base, which is the top of RAM, kept out of the memory map. There
// is no device behind it: the boot parameters say it is there, as a boot loader that had
// asked the firmware would, and the kernel's efifb draws on it. 0 by 0 for none.
var fb_w: u32 = 0;
var fb_h: u32 = 0;
var fb_base: u32 = 0;

// Sets the machine up to run the kernel in img. Returns a message on failure, "" on success.
fn linux_boot(img: u8[:], initrd: u8[:], cmdline: const u8[:]) -> const u8[:] {
    if img[0x211] & 1 == 0 { return "the kernel is not loaded high (a zImage, not a bzImage)"; }
    var setup_sects: i64 = img[0x1F1];
    if setup_sects == 0 { setup_sects = 4; }
    let body = (setup_sects + 1) * 512;
    if body >= img.len { return "the kernel image is shorter than its header says"; }
    let lo: u32 = img[0x214];
    let b1: u32 = img[0x215];
    let b2: u32 = img[0x216];
    let b3: u32 = img[0x217];
    let entry = lo | b1 << 8 | b2 << 16 | b3 << 24;

    // The 32-bit machine: all of memory, no wrap at 1 MB, no BIOS, nothing set up for it.
    phys_mask = 0xFFFFFFFF;
    copy_to(KERNEL_AT, img[body..]);
    copy_to(CMDLINE_AT, cmdline);
    set_mem8(CMDLINE_AT + (cmdline.len as! u32), 0);

    // The frame buffer takes whole megabytes off the top of memory.
    var top: u32 = RAM_SIZE;
    if fb_w != 0 {
        top -= (fb_w * fb_h * 4 + 0xFFFFF) & 0xFFF00000;
        fb_base = top;
    }

    // The initramfs goes near the top of memory, page-aligned, with a megabyte to spare above.
    var initrd_at: u32 = 0;
    if initrd.len > 0 {
        if initrd.len + 0x200000 > top - KERNEL_AT { return "the initramfs does not fit in memory"; }
        initrd_at = (top - (initrd.len as! u32) - 0x100000) & 0xFFFFF000;
        copy_to(initrd_at, initrd);
    }

    // The zero page: a copy of the setup header, then the fields a boot loader fills in.
    copy_to(ZERO_PAGE + 0x1F1, img[0x1F1..0x268]);
    set_mem8(ZERO_PAGE + 0x06, 0x03);            // video mode 3,
    set_mem8(ZERO_PAGE + 0x07, 80);              // 80 columns,
    set_mem8(ZERO_PAGE + 0x0E, 25);              // 25 lines,
    set_mem8(ZERO_PAGE + 0x0F, 1);               // a VGA,
    set_mem8(ZERO_PAGE + 0x10, 16);              // 16-pixel font
    set_mem8(ZERO_PAGE + 0x210, 0xFF);           // boot loader type: none of the known ones
    set_mem32(ZERO_PAGE + 0x218, initrd_at);
    set_mem32(ZERO_PAGE + 0x21C, initrd.len as! u32);
    set_mem32(ZERO_PAGE + 0x228, CMDLINE_AT);
    e820(0, 0x00000000, 0x0009FC00, 1);
    e820(1, 0x0009FC00, 0x00000400, 2);
    e820(2, 0x000A0000, 0x00060000, 2);
    e820(3, KERNEL_AT, top - KERNEL_AT, 1);
    set_mem8(ZERO_PAGE + 0x1E8, 4);
    if fb_w != 0 {
        e820(4, top, RAM_SIZE - top, 2);
        set_mem8(ZERO_PAGE + 0x1E8, 5);
        // screen_info: a linear frame buffer of the kind a UEFI boot loader reports (70h),
        // which is the kind this kernel has a driver for. Red at bit 8, green at 16, blue at
        // 24: an order the kernel's table of "simple" frame buffers does not list, so that
        // the EFI driver gets it and not a driver the kernel has not. (rustx86's finding.)
        set_mem8(ZERO_PAGE + 0x0F, 0x70);
        set_mem32(ZERO_PAGE + 0x12, fb_w | fb_h << 16);                  // width and height, 16 bits each
        set_mem32(ZERO_PAGE + 0x16, 32 | (fb_base & 0xFFFF) << 16);      // bits to a pixel; the base's low half
        set_mem32(ZERO_PAGE + 0x1A, fb_base >> 16 | ((fb_w * fb_h * 4 + 0xFFFF) >> 16 & 0xFFFF) << 16);   // its high half; the size in 64 KB
        set_mem32(ZERO_PAGE + 0x24, fb_w * 4 | 8 << 16 | 8 << 24);       // bytes to a line; red: 8 bits at 8
        set_mem32(ZERO_PAGE + 0x28, 8 | 16 << 8 | 8 << 16 | 24 << 24);   // green: 8 at 16; blue: 8 at 24
        set_mem32(ZERO_PAGE + 0x2C, 8);                                  // nothing: 8 at 0
    }

    // The protocol wants flat 4 GB segments: selector 10h for code, 18h for data. The kernel
    // reloads its segment registers early on, so the table has to be in memory, not only in
    // the caches.
    set_mem32(GDT_AT + 16, 0x0000FFFF);
    set_mem32(GDT_AT + 20, 0x00CF9A00);
    set_mem32(GDT_AT + 24, 0x0000FFFF);
    set_mem32(GDT_AT + 28, 0x00CF9200);
    gdtr_base = GDT_AT;
    gdtr_limit = 31;
    cr[0] |= 1;                                  // protected mode, paging off
    cpu.cpl = 0;
    for s in [ES, CS, SS, DS, FS, GS] {
        cpu.segs[s] = if s == CS { 0x10 } else { 0x18 };
        cpu.base[s] = 0;
        cpu.limit[s] = 0xFFFFFFFF;
        cpu.attr[s] = if s == CS { 0x1C09B } else { 0x1C093 };
    }
    seg_bounds();
    set_r32(SI, ZERO_PAGE);                      // the protocol: ESI points at the zero page
    cpu.ip = entry;
    cpu.flags = 2;                               // interrupts off until the kernel turns them on
    return "";
}
