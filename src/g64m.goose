// g64m: the 64-bit CPU of M10, run as a user-mode emulator (E091).
//
//   g64m [options] program
//
// program is a static x86_64 ELF for Linux, or a system test's image (tests/sys64), which is
// run as a machine in long mode at privilege level 0: see sys64.goose.
// An ELF is loaded where its headers say and run from its entry point, in user mode, with three system calls answered here: write (to standard
// output and standard error), exit and exit_group. This is the stage before there is a
// machine around the CPU: its instructions are compared one at a time with a real CPU's
// (tools/oracle/step64.c, tools/difftest64.sh).
//
//   --trace        print the registers and flags after every instruction, one line each, in
//                  the same format as step64; what the program writes is then not printed
//   --trace-xmm    the same, and on each line MXCSR (without its six status bits) and the XMM
//                  registers that the instruction changed, as step64 -x prints them
//   --max N        stop after N instructions (2 billion unless given; 60 billion for a kernel)
//
// program may also be a Linux kernel for x86_64 (a bzImage), which is entered at its 64-bit
// entry point (linux64.goose), with the serial port as its console; what it prints is
// printed as it comes.
//   --initrd FILE  the initramfs
//   --no-decode-cache  decode every instruction every time (for finding a fault in the cache)
//   --faults       report every fault on standard error (but not page faults from level 3)
//   --append TEXT  the kernel's command line (default: console=ttyS0 tsc=reliable)
//   --wait TEXT    script step: run until TEXT has been printed on the serial port
//   --type TEXT    script step: send TEXT to the serial port (\n is Enter)
// Script steps run in the order given, and the run ends when the last one is done.
// Started from a terminal with a kernel, no script and no trace, the terminal is the serial
// port: what is typed goes to the guest, and Ctrl-] leaves. The machine then keeps to the
// clock: it sleeps while the guest is idle.
//   --headless     never take the terminal
//   --disk FILE    the image of an IDE disk. What the guest writes is kept in memory for this
//                  run only, and the image is never changed, unless:
//   --keep         with --disk: the guest's writes go to the image, in place
//   --rtc WHEN     what the guest's clock starts at: host, or seconds since 1970. Without it,
//                  the host's time in a terminal and 2026-01-01 in a scripted or headless run
//   --fb WxH       a frame buffer of W by H pixels for the kernel to draw on (1024x768 is
//                  usual); from a terminal, a window shows it and takes keyboard and mouse (SDL2)
//   --shot FILE    write the frame buffer to FILE as a PPM image when the run ends
//   --keys TEXT    script step: type TEXT at the keyboard (what a console on the frame
//                  buffer reads), as --type types at the serial port
//   --mouse X,Y,B  script step: the mouse moves X to the right and Y up, with buttons B held
//   --net          a network card (an NE2000 on PCI) behind which the host answers as a gateway,
//                  a DHCP server and a name server, and connects for the guest (libslirp)

import std;
import os;
import cpu64;
import sse64;
import sys64;
import jit64;
import dev;
import linux64;

var out: u8[>..];
var trace_buf: u8[>..];
let HEX = "0123456789ABCDEF";
var trace_xmm = false;
var seen_xmm: u64[32] = [0; 32];
var seen_mxcsr: u32 = 0x1F80;

fn hex(v: u64, digits: i64) {
    for i in digits { trace_buf.push(HEX[v >> (((digits - 1 - i) * 4) as! u64) & 15]); }
}

fn field(name: const u8[:], v: u64) {
    trace_buf.append(name);
    hex(v, 16);
}

fn trace_line() {
    field("RIP=", rip);
    field(" RAX=", reg[0]); field(" RCX=", reg[1]); field(" RDX=", reg[2]); field(" RBX=", reg[3]);
    field(" RSP=", reg[4]); field(" RBP=", reg[5]); field(" RSI=", reg[6]); field(" RDI=", reg[7]);
    field(" R8=", reg[8]); field(" R9=", reg[9]); field(" R10=", reg[10]); field(" R11=", reg[11]);
    field(" R12=", reg[12]); field(" R13=", reg[13]); field(" R14=", reg[14]); field(" R15=", reg[15]);
    trace_buf.append(" F=");
    hex(rflags, 8);
    if trace_xmm {
        // MXCSR without its status bits, and the XMM registers, each when it has changed.
        if mxcsr & 0xFFC0 != seen_mxcsr {
            seen_mxcsr = mxcsr & 0xFFC0;
            trace_buf.append(" MXCSR=");
            hex(seen_mxcsr, 4);
        }
        for i in 16 {
            if xmm[i * 2] != seen_xmm[i * 2] || xmm[i * 2 + 1] != seen_xmm[i * 2 + 1] {
                seen_xmm[i * 2] = xmm[i * 2];
                seen_xmm[i * 2 + 1] = xmm[i * 2 + 1];
                trace_buf.append(" X");
                if i > 9 { trace_buf.push('1'); }
                trace_buf.push(HEX[i % 10]);
                trace_buf.push('=');
                hex(xmm[i * 2 + 1], 16);
                trace_buf.push(':');
                hex(xmm[i * 2], 16);
            }
        }
    }
    trace_buf.push('\n');
    if trace_buf.len > 60000 { write_stdout(trace_buf); trace_buf.clear(); }
}

// SYSCALL in user mode: the kernel's part is done here. The number is in RAX and the
// arguments in RDI, RSI and RDX; the answer goes to RAX.
fn syscall64() {
    let n = reg[0];
    if n == 1 {
        let fd = reg[7];
        let at = reg[6];
        let len = reg[2];
        if fd != 1 && fd != 2 { reg[0] = 0xFFFFFFFFFFFFFFF7; return; }          // EBADF
        if at >= MEM_SIZE || len > MEM_SIZE - at { reg[0] = 0xFFFFFFFFFFFFFFF2; return; }   // EFAULT
        for i in len as! i64 { out.push(mem[(at as! i64) + i]); }
        reg[0] = len;
    } else if n == 60 || n == 231 {
        exit_code = (reg[7] & 0xFF) as! i64;
        stopped = true;
    } else {
        reg[0] = 0xFFFFFFFFFFFFFFDA;                                             // ENOSYS
    }
}

// ---- The machine around the CPU (E097) ----
//
// The devices are the 32-bit machine's (dev.goose): the interrupt controllers, the timer, the
// serial port and the rest, reached by I/O ports. They keep time by `vtime`, the count of
// instructions. One port is this file's: a write to F4h stops the machine, as QEMU's
// isa-debug-exit device does. What the guest sends to the serial port is printed when the
// run ends.

var vtime = 0;                               // virtual time, in instructions: what the devices read
var unknown_ports: u8[65536] = [0; 65536];   // how often each port that nothing answers was used

fn io_in(port: u64, w: u8) -> u64 {
    vtime = steps as! i64;                   // the devices' time is now
    let p = port as! u16;
    if w == 8 { return port_in8(p); }
    let lo: u64 = port_in(p);
    if w == 16 { return lo; }
    // (The disk's data port is one port at every width: its next two bytes, not port 1F2h.)
    let hi: u64 = port_in(if p == 0x1F0 { p } else { p + 2 });
    return lo | hi << 16;
}

fn io_out(port: u64, w: u8, v: u64) {
    vtime = steps as! i64;
    if port == 0xF4 { stopped = true; attn = true; return; }
    let p = port as! u16;
    if w == 8 { port_out8(p, v as! u8); return; }
    port_out(p, v as! u16);
    if w == 32 { port_out(if p == 0x1F0 { p } else { p + 2 }, (v >> 16) as! u16); }
}

// What the machine does between two instructions: the timer, a halt, and an interrupt from
// outside when IF allows one. False when nothing can ever wake a halted machine.
fn between() -> bool {
    if timer_on && vtime >= timer_at { timer_fire(); }
    if halted {
        if !irq_line || rflags & IF == 0 {
            // Asleep. With interrupts off nothing can wake it. Else time passes: to the
            // timer's next tick, or, with the timer stopped (a kernel with nothing to wait
            // for stops it), a hundredth of a second, for a key to come in.
            if rflags & IF == 0 { return false; }
            if timer_on { steps = timer_at as! u64; } else { steps += (insns_per_second() / 100) as! u64; }
            return true;
        }
        halted = false;
    }
    if irq_line && rflags & IF != 0 && !sti_shadow && pending < 0 {
        // Delivered like a trap: the address pushed is the next instruction's, without RF.
        pending = pic_ack();
        pending_has_err = false;
        pending_trap = true;
    }
    return true;
}

fn le(img: u8[:], at: i64, n: i64) -> u64 {
    var v: u64 = 0;
    for i in n { let b: u64 = img[at + i]; v |= b << ((i * 8) as! u64); }
    return v;
}

// Puts the program's segments in memory. A message on failure, "" on success.
fn load_elf(img: u8[:]) -> const u8[:] {
    if img.len < 64 || img[0] != 0x7F || img[1] != 'E' || img[2] != 'L' || img[3] != 'F' { return "not an ELF file"; }
    if img[4] != 2 || le(img, 18, 2) != 62 { return "not an x86_64 ELF"; }
    if le(img, 16, 2) != 2 { return "not a static executable"; }
    let phoff = le(img, 32, 8) as! i64;
    let phentsize = le(img, 54, 2) as! i64;
    let phnum = le(img, 56, 2) as! i64;
    for i in phnum {
        let ph = phoff + i * phentsize;
        if ph + 56 > img.len { return "a program header is past the end of the file"; }
        if le(img, ph, 4) != 1 { continue; }
        let offset = le(img, ph + 8, 8);
        let vaddr = le(img, ph + 16, 8);
        let filesz = le(img, ph + 32, 8);
        let memsz = le(img, ph + 40, 8);
        if vaddr >= MEM_SIZE || memsz > MEM_SIZE - vaddr { return "a segment does not fit in memory"; }
        if offset > (img.len as! u64) || filesz > (img.len as! u64) - offset || filesz > memsz { return "a segment is past the end of the file"; }
        for j in filesz as! i64 { mem[(vaddr as! i64) + j] = img[(offset as! i64) + j]; }
    }
    rip = le(img, 24, 8);
    // The stack is at the top of memory, with a count of zero arguments on it.
    reg[4] = MEM_SIZE - 0x1000;
    return "";
}

// A system test's image (tests/sys64/sys.inc): a multiboot header for QEMU, then "G64T" and
// where the 64-bit code, the top page table and the GDT's pointer are.
fn is_test_image(img: u8[:]) -> bool {
    return img.len > 64 && le(img, 0, 4) == 0x1BADB002 && img[32] == 'G' && img[33] == '6' && img[34] == '4' && img[35] == 'T';
}

// Puts the image at 1 MB and sets the CPU as the image's own 32-bit beginning would leave
// it: long mode on, paging through the image's tables, privilege level 0.
fn load_test_image(img: u8[:]) -> const u8[:] {
    let base = 0x100000;
    if base + img.len > MEM_SIZE { return "the image does not fit in memory"; }
    for b, i in img { mem[base + i] = b; }
    machine = true;
    cpl = 0;
    cr0 = 0x80000011;
    cr4 = 0x20;
    efer = 0x500;
    cr3 = le(img, 48, 8);
    let gp = (le(img, 56, 8) as! i64) - base;
    if gp < 0 || gp + 10 > img.len { return "the image's GDT pointer is outside it"; }
    gdt_limit = le(img, gp, 2);
    gdt_base = le(img, gp + 2, 8);
    seg = [0x10, 0x08, 0x10, 0x10, 0x10, 0x10];
    rflags = 2;
    rip = le(img, 40, 8);
    return "";
}

// ---- The terminal as the serial port (E100) ----

extern fn con_is_tty() -> i32;
extern fn con_raw() -> i32;
extern fn con_close();
extern fn con_read() -> i32;
extern fn con_sleep_us(us: i32);
extern fn con_time() -> i64;

// The guest counts this many instructions to one of its seconds: the timer's 1,193,182
// ticks, tick_insns instructions each.
fn insns_per_second() -> i64 { return 1193182 * tick_insns; }

var pace_t0 = 0;                 // the clock, and
var pace_v0 = 0;                 // virtual time, when the two were last set level

// Holds guest time to the clock: if it is ahead (it is whenever the guest sleeps) the
// difference is slept, 50 ms at most at once.
fn pace() {
    let guest_ns = (vtime - pace_v0) * 1000000000 / insns_per_second();
    let ahead = guest_ns - (clock_ns() - pace_t0);
    if ahead > 0 {
        let nap = if ahead > 50000000 { 50000000 } else { ahead };
        con_sleep_us((nap / 1000) as! i32);
    } else if ahead < -200000000 {
        // Far behind, as while the guest computes: the two are set level again, so that
        // what was lost is not made up later by running ahead.
        pace_t0 = clock_ns();
        pace_v0 = vtime;
    }
}

// Called every hundredth of a second of guest time: what was typed goes to the serial
// port, what it sent is written, and the machine is held to the clock. False when Ctrl-]
// was typed.
fn terminal_step() -> bool {
    loop {
        let b = con_read();
        if b < 0 { break; }
        if b == 0x1D { return false; }
        com_receive(b as! u8);
    }
    com_flush();
    if screen_on && !screen_tick() { return false; }
    pace();
    return true;
}

let NET_EVERY = 40000;           // instructions between looks at the network: half a millisecond of guest time

// ---- The frame buffer's window, and the keyboard (E103) ----
//
// As on the 32-bit machine (g86m.goose): screen.c shows the frame buffer's memory in a
// window and gives back what happens there, which goes to the keyboard controller.

extern fn screen_open(w: i32, h: i32) -> i32;
extern fn screen_show(pixels: const u8[:]);
extern fn screen_poll(out: u32[:]) -> i32;
extern fn screen_close();
var screen_on = false;
var screen_n = 0;
var screen_buttons: u8 = 0;
var keys_next = 0;               // the virtual time before which the script types no further key

fn screen_tick() -> bool {
    var ev: u32[64] = [0; 64];
    let n = screen_poll(ev[..]);
    var dx = 0;
    var dy = 0;
    var moved = false;
    var open = true;
    for k in n {
        let e = ev[k];
        let kind = e >> 24;
        if kind == 1 {
            if e & 0x100 != 0 { kbd_push(0xE0); }
            kbd_push((e & 0x7F | (if e & 0x200 != 0 { 0x80 } else { 0 })) as! u8);
        } else if kind == 2 {
            let x: i64 = e & 0xFFF;
            let y: i64 = e >> 12 & 0xFFF;
            dx += if x >= 2048 { x - 4096 } else { x };
            dy -= if y >= 2048 { y - 4096 } else { y };      // the mouse's "up" is the window's "down"
            moved = true;
        } else if kind == 3 {
            screen_buttons = (e & 7) as! u8;
            moved = true;
        } else if kind == 4 {
            open = false;
        }
    }
    if moved { mouse_move(dx, dy, screen_buttons); }
    screen_n += 1;
    if screen_n % 3 == 0 {
        let from = fb_base as! i64;
        let size = (fb_w * fb_h * 4) as! i64;
        screen_show(mem[from..from + size]);
    }
    return open;
}

// The frame buffer as a PPM image: a header, then red, green and blue for each pixel.
fn shot_write(path: const u8[:]) -> bool {
    var img: u8[>..] = [];
    format(img, "P6\n", fb_w as! i64, " ", fb_h as! i64, "\n255\n");
    let from = fb_base as! i64;
    let n = (fb_w * fb_h) as! i64;
    for k in n {
        let at = from + k * 4;
        img.push(mem[at + 1]);
        img.push(mem[at + 2]);
        img.push(mem[at + 3]);
    }
    return write_file(path, img);
}

// The scancodes (set 1) of the US keyboard's rows, unshifted and shifted, from the key "1"
// on; as console.goose has them for the 32-bit machine.
let ROW_PLAIN = "1234567890-=\0\0qwertyuiop[]\0\0asdfghjkl;'`\0\\zxcvbnm,./";
let ROW_SHIFT = "!@#$%^&*()_+\0\0QWERTYUIOP{}\0\0ASDFGHJKL:\"~\0|ZXCVBNM<>?";

// Queues the scancodes that produce the character c. Unknown characters are ignored.
fn type_char(c: u8) {
    var scan: u8 = 0;
    var shift = false;
    if c == '\n' || c == '\r' { scan = 0x1C; }
    else if c == ' ' { scan = 0x39; }
    else if c == '\t' { scan = 0x0F; }
    else {
        for p, i in ROW_PLAIN { if p == c && p != 0 { scan = (i + 2) as! u8; } }
        for p, i in ROW_SHIFT { if p == c && p != 0 { scan = (i + 2) as! u8; shift = true; } }
    }
    if scan == 0 { return; }
    if shift { kbd_push(0x2A); }
    kbd_push(scan);
    kbd_push(scan | 0x80);
    if shift { kbd_push(0xAA); }
}

// ---- The script (for a kernel) ----

var step_kind: i64[>..];         // each step: 1 wait for its text, 2 type it at the serial port,
                                 // 3 type it at the keyboard, 4 move the mouse
var step_arg: i64[>..];          // where its text is in args()
var step_at = 0;                 // the step being done
var searched = 0;                // how much of the serial output earlier waits have used up
var typed = 0;                   // how much of the text being typed has been sent
var shown = 0;                   // how much of the serial output has been printed

// Prints what the guest has sent since last time, and moves the script on. True when the
// script's last step is done.
fn script_step(a: u8[:][>..]&) -> bool {
    if com_out.len > shown { write_stdout(com_out[shown..]); shown = com_out.len; }
    while step_at < step_kind.len {
        let text = a[step_arg[step_at]];
        let kind = step_kind[step_at];
        if kind == 3 {
            // One character at a time, once the guest has taken the last one, and no more
            // than fifty a second of the guest's time.
            if typed < text.len {
                if kbd_queued() > 0 || kbd_full || vtime < keys_next { return false; }
                keys_next = vtime + insns_per_second() / 50;
                var c = text[typed];
                typed += 1;
                if c == 0x5C && typed < text.len && text[typed] == 'n' { c = '\n'; typed += 1; }
                type_char(c);
                return false;
            }
            if kbd_queued() > 0 || kbd_full { return false; }
            typed = 0;
        } else if kind == 4 {
            // "DX,DY,BUTTONS".
            var v: i64[3] = [0; 3];
            var k = 0;
            var from = 0;
            for j in text.len + 1 {
                if j == text.len || text[j] == ',' {
                    let n, ok = parse_int(text[from..j]);
                    if ok && k < 3 { v[k] = n; }
                    k += 1;
                    from = j + 1;
                }
            }
            mouse_move(v[0], v[1], v[2] as! u8);
        } else if kind == 1 {
            let at = find(com_out[searched..], text);
            if at < 0 { return false; }
            searched += at + text.len;
        } else {
            // One character at a time, each when the guest has taken the one before.
            if typed < text.len {
                if com_has_input() { return false; }
                var c = text[typed];
                typed += 1;
                if c == 0x5C && typed < text.len && text[typed] == 'n' { c = 13; typed += 1; }
                com_receive(c);
                return false;
            }
            typed = 0;
        }
        step_at += 1;
    }
    return step_kind.len > 0;
}

fn main() {
    let a = args();
    var trace = false;
    var initrd_arg = 0;
    var append_arg = 0;
    var max_given = false;
    var headless = false;
    var disk_arg = 0;
    var shot_arg = 0;
    var rtc_given = false;
    var disk_scratch: i32 = 1;   // the disk's writes are not kept, unless --keep says so
    var max: u64 = 2000000000;
    var path: const u8[:] = "";
    var i = 1;
    while i < a.len {
        if a[i] == "--trace" { trace = true; }
        else if a[i] == "--trace-xmm" { trace = true; trace_xmm = true; }
        else if a[i] == "--max" && i + 1 < a.len {
            i++;
            let n, ok = parse_int(a[i]);
            guard ok else { write_stderr("g64m: --max needs a number\n"); exit(2); }
            max = n as! u64;
            max_given = true;
        }
        else if a[i] == "--faults" { show_faults = true; }
        else if a[i] == "--no-decode-cache" { dc_on = false; }
        else if a[i] == "--jit" { jit_on = true; }
        else if a[i] == "--jit-check" { jit_on = true; jit_check = true; }
        else if a[i] == "--jit-stats" { jit_stats = true; }
        else if a[i] == "--jit-dump" && i + 1 < a.len { i++; jit_on = true; jit_dump_arg = i; }
        else if a[i] == "--jit-hot" && i + 1 < a.len { i++; let n, ok = parse_int(a[i]); guard ok && n >= 1 && n <= 200 else { write_stderr("g64m: --jit-hot needs a number from 1 to 200\n"); exit(2); } J_HOT = n as! u8; }
        else if a[i] == "--jit-why" { jit_on = true; jit_stats = true; jit_why = true; }
        else if a[i] == "--jit-time" { jit_on = true; jit_stats = true; jit_time = true; }
        else if a[i] == "--jit-off" && i + 1 < a.len {
            i++;
            let n, ok = parse_int(a[i]);
            guard ok else { write_stderr("g64m: --jit-off needs a number\n"); exit(2); }
            jit_no = n as! u64;
        }
        else if a[i] == "--jit-off2" && i + 1 < a.len {
            i++;
            let n, ok = parse_int(a[i]);
            guard ok else { write_stderr("g64m: --jit-off2 needs a number\n"); exit(2); }
            jit_no2 = n as! u64;
        }
        else if a[i] == "--headless" { headless = true; }
        else if a[i] == "--disk" && i + 1 < a.len { i++; disk_arg = i; }
        else if a[i] == "--keep" { disk_scratch = 0; }
        else if a[i] == "--cpu-open" { cpu_open = true; }
        else if a[i] == "--rtc" && i + 1 < a.len {
            i++;
            if a[i] == "host" { rtc_base = con_time(); rtc_given = true; }
            else {
                let n, ok = parse_int(a[i]);
                guard ok else { write_stderr("g64m: --rtc takes host or a number of seconds\n"); exit(2); }
                rtc_base = n;
                rtc_given = true;
            }
        }
        else if a[i] == "--net" {
            if net_open() != 0 { write_stderr("g64m: --net needs libslirp, which was not found (brew install libslirp)\n"); exit(2); }
            net_on = true;
            pci_setup();
            ne_setup();
        }
        else if a[i] == "--initrd" && i + 1 < a.len { i++; initrd_arg = i; }
        else if a[i] == "--append" && i + 1 < a.len { i++; append_arg = i; }
        else if (a[i] == "--wait" || a[i] == "--type" || a[i] == "--keys" || a[i] == "--mouse") && i + 1 < a.len {
            step_kind.push(if a[i] == "--wait" { 1 } else if a[i] == "--type" { 2 } else if a[i] == "--keys" { 3 } else { 4 });
            i++;
            step_arg.push(i);
        }
        else if a[i] == "--fb" && i + 1 < a.len {
            i++;
            let t = a[i];
            var x = -1;
            for k in t.len { if t[k] == 'x' { x = k; } }
            if x > 0 {
                let w, okw = parse_int(t[..x]);
                let h, okh = parse_int(t[x + 1..]);
                if okw && okh && w >= 320 && w <= 1920 && h >= 200 && h <= 1200 { fb_w = w as! u64; fb_h = h as! u64; }
            }
            if fb_w == 0 { write_stderr("g64m: --fb wants a size, as in 1024x768\n"); exit(2); }
        }
        else if a[i] == "--shot" && i + 1 < a.len { i++; shot_arg = i; }
        else { path = a[i]; }
        i++;
    }
    guard path.len > 0 else { write_stderr("usage: g64m [--trace] [--max N] program\n"); exit(2); }
    var img: u8[>..] = [];
    guard read_file(path, img) else { write_stderr("g64m: cannot read the program\n"); exit(2); }
    var problem: const u8[:] = "";
    let kernel = is_kernel64(img);
    if kernel {
        var initrd: u8[>..] = [];
        if initrd_arg > 0 {
            guard read_file(a[initrd_arg], initrd) else { write_stderr("g64m: cannot read the initramfs\n"); exit(2); }
        }
        // tsc=reliable: the TSC here is the instruction count, which is what the timer runs
        // on, so there is nothing to check it against (E080).
        let cmdline: const u8[:] = if append_arg > 0 { a[append_arg] } else { "console=ttyS0 tsc=reliable" };
        problem = linux64_boot(img, initrd, cmdline);
        if !max_given { max = 60000000000; }
    }
    else if is_test_image(img) { problem = load_test_image(img); }
    else { problem = load_elf(img); }
    guard problem.len == 0 else { write_stderr(str("g64m: ", problem, "\n")); exit(2); }

    if disk_arg > 0 {
        ide_sectors = disk_open(a[disk_arg], disk_scratch);
        if ide_sectors < 1 { write_stderr("g64m: cannot open the disk image, or it has no sector\n"); exit(2); }
    }
    tick_insns = 64;
    timer_on = false;
    if jit_on && !(dc_on && jit64_init()) { jit_on = false; }
    var asleep = false;
    var scripted = false;
    // A kernel started from a terminal, with no script and no trace: the terminal is its
    // serial port, the guest's clock starts at the host's, and nothing limits the run.
    var terminal = kernel && !trace && step_kind.len == 0 && !headless && con_is_tty() != 0;
    if terminal {
        write_stdout("g64m: Ctrl-] to quit\r\n");
        terminal = con_raw() != 0;
    }
    if terminal {
        com_live = true;
        if !rtc_given { rtc_base = con_time(); }
        if !max_given { max = 4000000000000000000; }
        pace_t0 = clock_ns();
        if fb_w != 0 && screen_open(fb_w as! i32, fb_h as! i32) == 0 { screen_on = true; }
    }
    // How often the terminal, or the script, is looked at: a hundredth of a second of guest
    // time for the terminal, 16,384 instructions for a script.
    let slice: u64 = if terminal { (insns_per_second() / 100) as! u64 } else { 16384 };
    var next_look = slice;
    var quit = false;
    var net_next: u64 = 0;
    if net_on { pace_t0 = clock_ns(); }
    // A string instruction goes on by itself (E113) in a program run without a trace, to the
    // end of the run; in a machine only inside the run below, which says how far. With a
    // trace, and in a machine outside that run, every repetition may be followed by a line
    // of trace or a single step.
    rep_until = if machine || trace { 0 } else { max };
    while !stopped && steps < max {
        // The devices' time is the instruction count. Only when the timer is due, the
        // machine is asleep or a request is waiting is there anything to do between two
        // instructions.
        vtime = steps as! i64;
        if kernel && steps >= next_look {
            next_look = steps + slice;
            if terminal { if !terminal_step() { quit = true; break; } }
            else {
                if script_step(a) { scripted = true; break; }
                // The network is the host's and runs on the host's time: with a script and
                // no terminal, the guest is held to the clock for it.
                if net_on { pace(); }
            }
        }
        if net_on && steps >= net_next {
            net_tick();
            net_next = steps + NET_EVERY;
        }
        if machine && ((timer_on && vtime >= timer_at) || halted || irq_line) {
            if !between() { asleep = true; break; }
            if halted { continue; }
        }
        let tf = rflags & 0x100 != 0;
        let shadow = sti_shadow;
        if exec64() && machine { single_step(tf); }
        if shadow { sti_shadow = false; }
        steps += 1;
        if jit_left != 0 { jit_tick(); }
        if trace && !stopped { trace_line(); }

        // The run (E106). What is above does one instruction with every question asked. Most
        // instructions need none of them: how many may go by before the first timed thing
        // is due is worked out here, and they are run with one test after each: has anything
        // asked for attention (a halt, a stop, STI, SYSCALL and SYSRET set `attn`; a write to
        // the timer sets `replan`), is TF set, is a request waiting with IF set.
        if machine && !trace && !stopped && jit_left == 0 {
            var stop_at = max;
            if kernel && next_look < stop_at { stop_at = next_look; }
            if net_on && net_next < stop_at { stop_at = net_next; }
            if timer_on && (timer_at as! u64) < stop_at { stop_at = timer_at as! u64; }
            replan = false;
            if !(attn || halted || sti_shadow || rflags & 0x100 != 0 || (irq_line && rflags & IF != 0)) {
                rep_until = stop_at;
                while steps < stop_at {
                    exec64();
                    steps += 1;
                    let f = rflags;
                    if attn || replan || f & 0x100 != 0 || (irq_line && f & IF != 0) {
                        // SYSCALL and SYSRET are followed by a single step if they leave TF set.
                        if by_syscall { single_step(false); }
                        break;
                    }
                }
            }
            rep_until = 0;
            attn = false;
            if jit_left != 0 { jit_tick(); }
        }
    }
    if jit_dump_arg != 0 {
        if !write_file(a[jit_dump_arg], jit_dump()[..]) { write_stderr("g64m: cannot write the generated code\n"); }
    }
    if jit_stats {
        var msg: u8[>..] = [];
        format(msg, "g64m: jit: ", j_blocks, " blocks, ", j_used, " bytes (", j_bytes as! i64, " written in all), entered ", j_entered as! i64, " times, ", j_ran as! i64, " of ", steps as! i64, " instructions in blocks, ", j_flushes, " flushes, ", jit_links as! i64, " links, ", j_evicted as! i64, " blocks lost to the cache, the TLB emptied ", tlb_flushes as! i64, " times\n");
        write_stderr(msg);
        if jit_why {
            var m3: u8[>..] = [];
            format(m3, "g64m: jit-why: another page ", jw[0], ", not in the cache ", jw[1], ", cold ", jw[2], ", hot and no block ", jw[3], ", inside a block ", jw[4], ", a block with no time left ", jw[5], ", a block ", jw[6], "\n");
            format(m3, "g64m: jit-why: on another page: not in the TLB ", jw2[0], ", not in the cache ", jw2[1], ", cold ", jw2[2], ", hot and no block ", jw2[3], ", inside a block ", jw2[4], ", a block with no time left ", jw2[5], ", a block ", jw2[6], " (of another level ", jw2[7], ")\n");
            format(m3, "g64m: jit-why: a block that reads RFLAGS met with a record waiting: ", jw_rec[0], " on the page, ", jw_rec[1], " on another\n");
            format(m3, "g64m: jit-why: interpreted: not in the cache ", ji[0], ", a block's first instruction ", ji[1], ", inside a block ", ji[2], ", cold ", ji[3], ", hot and refused ", ji[4], "\n");
            format(m3, "g64m: jit-why: a block not run: no time left ", jq[0], ", of another level ", jq[1], ", left at its first instruction ", jq[2], ", turned away before it ", jq[3], " (of the last two, blocks that read RFLAGS ", jq[4], ")\n");
            format(m3, "g64m: jit-why: the table of blocks asked ", jx[27] as! i64, " (", jx[37] as! i64, " at level 0; ", jx[38] as! i64, " for a constant address); the far way taken ", jx[31] as! i64, " (", jx[35] as! i64, " at level 0, ", jx[36] as! i64, " at level 3), found a block ", jx[28] as! i64, "; pages with blocks written to ", jq[5], ", the TLB emptied ", tlb_flushes as! i64, "\n");
            format(m3, "g64m: jit-why: blocks ended at an instruction the decode cache does not hold ", jq[6], ", at one not translated ", jq[7], "; blocks given back to a new entry ", bt_back as! i64, ", lost from their own table ", bt_lost as! i64, "\n");
            format(m3, "g64m: jit-why: with no entry: an address's first time ", jm_hist[0], ", its 2nd to 8th ", jm_hist[1], ", 9th to 32nd ", jm_hist[2], ", 33rd to 128th ", jm_hist[3], ", later ", jm_hist[4], "; of all, no block to give back ", jm_hist[5], "; blocks made at the eighth time ", jh_made as! i64, "\n");
            format(m3, "g64m: jit-why: not remembered: on a page given up ", jm_why[0], ", across a page's end ", jm_why[1], "\n");
            format(m3, "g64m: jit-why: the look for dead flags: dead ", jf[0], ", the page's end ", jf[1], ", no entry ", jf[2], ", other ", jf[3], ", a conditional jump ", jf[4], ", CALL or JMP ", jf[5], ", RET or through an operand ", jf[6], ", CMOVcc or SETcc ", jf[7], ", twelve ", jf[8], "\n");
            for i in 8192 { if jn_n[i] > 150000 { format(m3, "g64m: jit-why: hot ", jn_n[i], " "); hex64(m3, mem_rd(jn_ph[i], 64)); format(m3, " "); hex64(m3, mem_rd(jn_ph[i] + 8, 64)); format(m3, " at "); hex64(m3, jn_ph[i]); format(m3, "\n"); } }
            for i in 64 { if jq_k[i] != 0 { format(m3, "g64m: jit-why: not run, first of kind ", i, " ", jq_k[i], "\n"); } }
            format(m3, "g64m: jit-why: refused with a kind: in the page's last fifteen bytes with no operand remembered ", ji[5], ", there with one ", ji[6], ", elsewhere ", ji[7], "\n");
            for i in 64 { if ji_kind[i] != 0 { format(m3, "g64m: jit-why: interpreted kind ", i, " ", ji_kind[i], "\n"); } }
            for i in 512 { if ji_op[i] != 0 { format(m3, "g64m: jit-why: interpreted op ", i, " ", ji_op[i], "\n"); } }
            for i in 1024 { if ji_grp[i] != 0 { format(m3, "g64m: jit-why: interpreted group ", i / 256, " byte ", i % 256, " ", ji_grp[i], "\n"); } }
            for i in 257 { if ji_0f[i] != 0 { format(m3, "g64m: jit-why: interpreted 0F ", i, " ", ji_0f[i], "\n"); } }
            for i in 256 { if jw_rk[i] != 0 { format(m3, "g64m: jit-why: record ", i, " ", jw_rk[i], "\n"); } }
            for i in 4096 { if jw_form[i] != 0 { format(m3, "g64m: jit-why: form ", i / 64, " ", i % 64, " ", jw_form[i], "\n"); } }
            for i in 64 { if jw_kind[i] != 0 { format(m3, "g64m: jit-why: kind ", i, " ", jw_kind[i], "\n"); } }
            for i in 256 { if jw_0f[i] != 0 { format(m3, "g64m: jit-why: 0F ", i, " ", jw_0f[i], "\n"); } }
            for i in 256 { if jw_op[i] != 0 { format(m3, "g64m: jit-why: op ", i, " ", jw_op[i], "\n"); } }
            write_stderr(m3);
        }
        if jit_time {
            jit_tally();
            var m2: u8[>..] = [];
            format(m2, "g64m: jit-time: translating ", jt_translate / 1000000, " ms, entries ", jt_enter / 1000000, " ms of which in the blocks' code ", jt_body / 1000000, " ms, a clock reading ", jt_clock, " ns (four for each entry, two for each translation); blocks never run ", jr_never, ", run under eight times ", jr_few, ", eight or more ", jr_many, "\n");
            write_stderr(m2);
        }
    }
    if screen_on { screen_close(); }
    if shot_arg > 0 && fb_w != 0 {
        if !shot_write(a[shot_arg]) { write_stderr("g64m: cannot write the image\n"); }
    }
    if terminal {
        com_flush();
        con_close();
        write_stdout("\n");
        if quit { exit(0); }
    }
    if trace { write_stdout(trace_buf); } else if !terminal { write_stdout(out); write_stdout(com_out[shown..]); }
    if kernel {
        var msg: u8[>..] = [];
        format(msg, "\nx64: ", steps as! i64, " instructions, at ");
        hex64(msg, rip);
        format(msg, if scripted { ", the script done\n" } else { "\n" });
        write_stderr(msg);
        if scripted { exit(0); }
    }
    if asleep { write_stderr("g64m: halted, with nothing to wake it\n"); exit(3); }
    if !stopped { write_stderr("g64m: stopped at the limit of --max\n"); exit(1); }
    if faulted { exit(1); }
    exit(exit_code as! i32);
}
