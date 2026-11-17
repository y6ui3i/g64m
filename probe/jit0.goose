// E058: can a Goose program run arm64 code it wrote into a buffer, and what does a call cost?
// Not part of g86m. Build: goose build -o build/jit0 probe/jit0.goose
import std;
import os;

extern fn jit_alloc(size: i64) -> i64;
extern fn jit_write(at: i64, code: const u8[:]);
extern fn jit_call(f: i64, st: u32[:], n: i64) -> i64;

var regs: u32[8] = [0; 8];
var code: u8[>..];

fn emit(w: u32) {
    code.push(w as! u8);
    code.push((w >> 8) as! u8);
    code.push((w >> 16) as! u8);
    code.push((w >> 24) as! u8);
}

fn main() {
    let mem = jit_alloc(65536);
    if mem == 0 { print("jit_alloc failed"); return; }

    // stub: regs[0] += 1; return regs[0]
    //   ldr w2, [x0]; add w2, w2, #1; str w2, [x0]; mov x0, x2; ret
    emit(0xB9400002);
    emit(0x11000442);
    emit(0xB9000002);
    emit(0xAA0203E0);
    emit(0xD65F03C0);
    let stub = mem;
    // loop: do that n times (n in x1), return regs[0]
    //   ldr w2, [x0]
    // again: add w2, w2, #1; str w2, [x0]; subs x1, x1, #1; b.ne again
    //   mov x0, x2; ret
    let looped = mem + code.len;
    emit(0xB9400002);
    emit(0x11000442);
    emit(0xB9000002);
    emit(0xF1000421);
    emit(0x54FFFFA1);
    emit(0xAA0203E0);
    emit(0xD65F03C0);
    jit_write(mem, code[..]);

    let n = 100000000;
    regs[0] = 41;
    print("one call returns ", jit_call(stub, regs[..], 0), ", regs[0] = ", regs[0]);

    regs[0] = 0;
    var t = clock_ns();
    for i in n { jit_call(stub, regs[..], 0); }
    let called = clock_ns() - t;
    print("called ", n, " times: regs[0] = ", regs[0], ", ", called / 1000000, " ms, ", called * 10 / n, " tenths of a ns a call");

    regs[0] = 0;
    t = clock_ns();
    for i in n { regs[0] += 1; }
    let plain = clock_ns() - t;
    print("the same in Goose: regs[0] = ", regs[0], ", ", plain / 1000000, " ms");

    regs[0] = 0;
    t = clock_ns();
    jit_call(looped, regs[..], n);
    let inside = clock_ns() - t;
    print("one call, a generated loop: regs[0] = ", regs[0], ", ", inside / 1000000, " ms");
}
