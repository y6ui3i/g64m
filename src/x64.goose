// x64: the 64-bit CPU of M10, run as a user-mode emulator (E091).
//
//   x64 [options] program
//
// program is a static x86_64 ELF for Linux. It is loaded where its headers say and run from
// its entry point, in user mode, with three system calls answered here: write (to standard
// output and standard error), exit and exit_group. This is the stage before there is a
// machine around the CPU: its instructions are compared one at a time with a real CPU's
// (tools/oracle/step64.c, tools/difftest64.sh).
//
//   --trace        print the registers and flags after every instruction, one line each, in
//                  the same format as step64; what the program writes is then not printed
//   --trace-xmm    the same, and on each line MXCSR (without its six status bits) and the XMM
//                  registers that the instruction changed, as step64 -x prints them
//   --max N        stop after N instructions (2 billion unless given)

import std;
import os;
import cpu64;
import sse64;

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

fn main() {
    let a = args();
    var trace = false;
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
        }
        else { path = a[i]; }
        i++;
    }
    guard path.len > 0 else { write_stderr("usage: x64 [--trace] [--max N] program\n"); exit(2); }
    var img: u8[>..] = [];
    guard read_file(path, img) else { write_stderr("x64: cannot read the program\n"); exit(2); }
    let problem = load_elf(img);
    guard problem.len == 0 else { write_stderr(str("x64: ", problem, "\n")); exit(2); }

    while !stopped && steps < max {
        exec64();
        steps += 1;
        if trace && !stopped { trace_line(); }
    }
    if trace { write_stdout(trace_buf); } else { write_stdout(out); }
    if !stopped { write_stderr("x64: stopped at the limit of --max\n"); exit(1); }
    if faulted { exit(1); }
    exit(exit_code as! i32);
}
