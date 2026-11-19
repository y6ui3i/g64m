// x64: the 64-bit CPU of M10, run as a user-mode emulator (E091).
//
//   x64 [options] program
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
//   --faults       report every fault on standard error (but not page faults from level 3)
//   --append TEXT  the kernel's command line (default: console=ttyS0 tsc=reliable)
//   --wait TEXT    script step: run until TEXT has been printed on the serial port
//   --type TEXT    script step: send TEXT to the serial port (\n is Enter)
// Script steps run in the order given, and the run ends when the last one is done.

import std;
import os;
import cpu64;
import sse64;
import sys64;
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
    let p = port as! u16;
    if w == 8 { return port_in8(p); }
    let lo: u64 = port_in(p);
    if w == 16 { return lo; }
    let hi: u64 = port_in(p + 2);
    return lo | hi << 16;
}

fn io_out(port: u64, w: u8, v: u64) {
    if port == 0xF4 { stopped = true; return; }
    let p = port as! u16;
    if w == 8 { port_out8(p, v as! u8); return; }
    port_out(p, v as! u16);
    if w == 32 { port_out(p + 2, (v >> 16) as! u16); }
}

// What the machine does between two instructions: the timer, a halt, and an interrupt from
// outside when IF allows one. False when nothing can ever wake a halted machine.
fn between() -> bool {
    if timer_on && vtime >= timer_at { timer_fire(); }
    if halted {
        if !irq_line || rflags & IF == 0 {
            // Asleep. Time passes to the timer's next tick, if there is one to wait for.
            if rflags & IF == 0 || !timer_on { return false; }
            steps = timer_at as! u64;
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

// ---- The script (for a kernel) ----

var step_wait: bool[>..];        // each step: true to wait for its text, false to type it
var step_arg: i64[>..];          // where its text is in args()
var step_at = 0;                 // the step being done
var searched = 0;                // how much of the serial output earlier waits have used up
var typed = 0;                   // how much of the text being typed has been sent
var shown = 0;                   // how much of the serial output has been printed

// Prints what the guest has sent since last time, and moves the script on. True when the
// script's last step is done.
fn script_step(a: u8[:][>..]&) -> bool {
    if com_out.len > shown { write_stdout(com_out[shown..]); shown = com_out.len; }
    while step_at < step_wait.len {
        let text = a[step_arg[step_at]];
        if step_wait[step_at] {
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
    return step_wait.len > 0;
}

fn main() {
    let a = args();
    var trace = false;
    var initrd_arg = 0;
    var append_arg = 0;
    var max_given = false;
    var max: u64 = 2000000000;
    var path: const u8[:] = "";
    var i = 1;
    while i < a.len {
        if a[i] == "--trace" { trace = true; }
        else if a[i] == "--trace-xmm" { trace = true; trace_xmm = true; }
        else if a[i] == "--max" && i + 1 < a.len {
            i++;
            let n, ok = parse_int(a[i]);
            guard ok else { write_stderr("x64: --max needs a number\n"); exit(2); }
            max = n as! u64;
            max_given = true;
        }
        else if a[i] == "--faults" { show_faults = true; }
        else if a[i] == "--initrd" && i + 1 < a.len { i++; initrd_arg = i; }
        else if a[i] == "--append" && i + 1 < a.len { i++; append_arg = i; }
        else if (a[i] == "--wait" || a[i] == "--type") && i + 1 < a.len {
            step_wait.push(a[i] == "--wait");
            i++;
            step_arg.push(i);
        }
        else { path = a[i]; }
        i++;
    }
    guard path.len > 0 else { write_stderr("usage: x64 [--trace] [--max N] program\n"); exit(2); }
    var img: u8[>..] = [];
    guard read_file(path, img) else { write_stderr("x64: cannot read the program\n"); exit(2); }
    var problem: const u8[:] = "";
    let kernel = is_kernel64(img);
    if kernel {
        var initrd: u8[>..] = [];
        if initrd_arg > 0 {
            guard read_file(a[initrd_arg], initrd) else { write_stderr("x64: cannot read the initramfs\n"); exit(2); }
        }
        // tsc=reliable: the TSC here is the instruction count, which is what the timer runs
        // on, so there is nothing to check it against (E080).
        let cmdline: const u8[:] = if append_arg > 0 { a[append_arg] } else { "console=ttyS0 tsc=reliable" };
        problem = linux64_boot(img, initrd, cmdline);
        if !max_given { max = 60000000000; }
    }
    else if is_test_image(img) { problem = load_test_image(img); }
    else { problem = load_elf(img); }
    guard problem.len == 0 else { write_stderr(str("x64: ", problem, "\n")); exit(2); }

    tick_insns = 64;
    timer_on = false;
    var asleep = false;
    var scripted = false;
    while !stopped && steps < max {
        // The devices' time is the instruction count. Only when the timer is due, the
        // machine is asleep or a request is waiting is there anything to do between two
        // instructions.
        vtime = steps as! i64;
        if machine && ((timer_on && vtime >= timer_at) || halted || irq_line) {
            if !between() { asleep = true; break; }
            if halted { continue; }
        }
        let tf = rflags & 0x100 != 0;
        let shadow = sti_shadow;
        if exec64() && machine { single_step(tf); }
        if shadow { sti_shadow = false; }
        steps += 1;
        if trace && !stopped { trace_line(); }
        // A kernel's console is printed as it comes, and its script looked at, every 16,384
        // instructions.
        if kernel && steps & 0x3FFF == 0 && script_step(a) { scripted = true; break; }
    }
    if trace { write_stdout(trace_buf); } else { write_stdout(out); write_stdout(com_out[shown..]); }
    if kernel {
        var msg: u8[>..] = [];
        format(msg, "\nx64: ", steps as! i64, " instructions, at ");
        hex64(msg, rip);
        format(msg, if scripted { ", the script done\n" } else { "\n" });
        write_stderr(msg);
        if scripted { exit(0); }
    }
    if asleep { write_stderr("x64: halted, with nothing to wake it\n"); exit(3); }
    if !stopped { write_stderr("x64: stopped at the limit of --max\n"); exit(1); }
    if faulted { exit(1); }
    exit(exit_code as! i32);
}
