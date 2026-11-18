#!/usr/bin/env python3
"""Writes tests/asm/v_sseNN.asm: trace tests of MMX and SSE2 against rustx86 (E077).

The trace has no XMM or MMX state, so each case leaves its result in XMM0 (or MM0) and calls
`show`, which stores it and loads it into EAX, EBX, ECX and EDX. The cases are packed into as
many boot sectors as it takes; this script only writes the sources, and is run again when the
list below changes:

    tools/gen_sse_tests.py && ORACLE-made traces for the new files (see tools/difftest.sh)
"""
import os, subprocess, sys, tempfile

HEAD = """; MMX and SSE2, part {n} of {total}: {what}. Written by tools/gen_sse_tests.py; change the list
; there, not this file. The trace has no XMM or MMX state: each case leaves its result in XMM0
; or MM0, and `show` stores it and loads it into EAX, EBX, ECX and EDX. Runs on the i686
; (--cpu i686).
%define CPU686
%include "common.inc"
cpu prescott
buf equ 0x1000
start:
    HDR
"""
TAIL = """    hlt
load:                                   ; the operands: XMM0 and MM0 from a, XMM1 and MM1 from b
    movdqu xmm0, [a]
    movdqu xmm1, [b]
    movq mm0, [a]
    movq mm1, [b]
    ret
showm:                                  ; MM0, by way of XMM0
    movq2dq xmm0, mm0
show:                                   ; XMM0 into EAX, EBX, ECX, EDX
    movdqu [buf], xmm0
    mov  eax, [buf]
    mov  ebx, [buf+4]
    mov  ecx, [buf+8]
    mov  edx, [buf+12]
    ret
align 4
a:  {a}
b:  {b}
c:  dq 3, 0x1111111111111111            ; a shift count
d:  dq 40, 0                            ; and one that is too many for some lanes
    TAIL
"""
INT_A = "db 0x7F, 0xFF, 0x80, 0x00, 0x01, 0xFE, 0x81, 0x7E, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0"
INT_B = "db 0x01, 0x80, 0xFF, 0x7F, 0x02, 0x03, 0xFF, 0x80, 0x0F, 0x1E, 0x2D, 0x3C, 0x4B, 0x5A, 0x69, 0x78"
SNG_A = "dd 1.5, -2.25, 1.0e10, 0.1"
SNG_B = "dd 3.0, 0.5, -7.0, 0.1"
DBL_A = "dq 1.5, -1.0e100"
DBL_B = "dq 0.75, 3.0"
# Only the conversions that cut off are here, and no MOVHLPS above: rustx86 cuts off where the
# instruction rounds, and takes the wrong word for MOVHLPS. Those are in s_sse, against the manual.
CVT_A = "dd 2.25, -3.75, 100000.75, -0.4"
CVT_B = "dq 2.75, -1234567.25"

two = """paddb paddw paddd paddq psubb psubw psubd psubq paddusb paddusw psubusb psubusw paddsb paddsw
psubsb psubsw pcmpeqb pcmpeqw pcmpeqd pcmpgtb pcmpgtw pcmpgtd pmullw pmulhw pmulhuw pmaddwd pminub
pmaxub pminsw pmaxsw pavgb pavgw psadbw pmuludq pand pandn por pxor punpcklbw punpcklwd punpckldq
punpckhbw punpckhwd punpckhdq packsswb packuswb packssdw""".split()
shifts = "psrlw psrld psrlq psraw psrad psllw pslld psllq".split()

def X(*lines): return ["call load"] + list(lines) + ["call show"]
def M(*lines): return ["call load"] + list(lines) + ["call showm"]

groups = []
g = []
for op in two:
    g.append(M(f"{op} mm0, mm1"))
for op in shifts:
    g.append(M(f"{op} mm0, [c]"))
    g.append(M(f"{op} mm0, [d]"))
g += [M("psrlq mm0, 7"), M("psraw mm0, 20"), M("pslld mm0, 9"), M("pshufw mm0, mm1, 0x2D"),
      M("mov eax, 0xBEEF", "pinsrw mm0, eax, 2"), M("pextrw eax, mm1, 1", "movd mm0, eax"),
      M("pmovmskb eax, mm1", "movd mm0, eax"), M("movd eax, mm1", "movd mm0, eax"),
      M("movq [buf+16], mm1", "movq mm0, [buf+16]"), M("movq mm0, mm1"), M("movntq [buf+16], mm1", "movq mm0, [buf+16]")]
groups.append(("MMX: the packed integers on 64 bits, shifts, shuffles and moves", INT_A, INT_B, g))

g = []
for op in two + ["punpcklqdq", "punpckhqdq"]:
    g.append(X(f"{op} xmm0, xmm1"))
for op in two[:4] + ["pxor", "pmuludq", "punpckhbw", "packssdw"]:
    g.append(X(f"{op} xmm0, [b]"))
for op in shifts:
    g.append(X(f"{op} xmm0, [c]"))
    g.append(X(f"{op} xmm0, [d]"))
g += [X("psrlw xmm0, 5"), X("psrad xmm0, 31"), X("psllq xmm0, 13"), X("psrlq xmm0, 64"), X("psraw xmm0, 16"),
      X("psrldq xmm0, 3"), X("pslldq xmm0, 9"), X("psrldq xmm0, 8"), X("pslldq xmm0, 16"),
      X("pshufd xmm0, xmm1, 0x1B"), X("pshuflw xmm0, xmm1, 0x39"), X("pshufhw xmm0, xmm1, 0x93"), X("pshufd xmm0, [b], 0x4E"),
      X("mov eax, 0xBEEF", "pinsrw xmm0, eax, 5"), X("pinsrw xmm0, [b], 2"), X("pextrw eax, xmm1, 6", "movd xmm0, eax"),
      X("pmovmskb eax, xmm1", "movd xmm0, eax"), X("movmskps eax, xmm1", "movd xmm0, eax"), X("movmskpd eax, xmm1", "movd xmm0, eax")]
groups.append(("SSE2: the packed integers on 128 bits, shifts and shuffles", INT_A, INT_B, g))

g = [X("movd eax, xmm1", "movd xmm0, eax"), X("movq xmm0, xmm1"), X("movq [buf+16], xmm1", "movq xmm0, [buf+16]"),
     X("movdqa xmm0, xmm1"), X("movaps xmm0, xmm1"), X("movups xmm0, xmm1"), X("movapd xmm0, xmm1"),
     X("movdqa [buf+16], xmm1", "movdqa xmm0, [buf+16]"), X("movdqu [buf+16], xmm1", "movdqu xmm0, [buf+16]"),
     X("movaps [buf+16], xmm1", "movups xmm0, [buf+16]"), X("movntdq [buf+16], xmm1", "movapd xmm0, [buf+16]"),
     X("movntps [buf+16], xmm1", "movaps xmm0, [buf+16]"),
     X("movss xmm0, xmm1"), X("movss xmm0, [b]"), X("movss [buf+16], xmm1", "movd xmm0, [buf+16]"),
     X("movsd xmm0, xmm1"), X("movsd xmm0, [b]"), X("movsd [buf+16], xmm1", "movq xmm0, [buf+16]"),
     X("movlps xmm0, [b]"), X("movhps xmm0, [b]"), X("movlpd xmm0, [b+8]"), X("movhpd xmm0, [b]"),
     X("movlps [buf+16], xmm1", "movhps [buf+24], xmm1", "movdqu xmm0, [buf+16]"),
     X("movlhps xmm0, xmm1"), X("movq2dq xmm0, mm1"), X("movdq2q mm0, xmm1", "movq2dq xmm0, mm0"),
     X("mov eax, 0x12345678", "movnti [buf+16], eax", "movd xmm0, [buf+16]"),
     X("unpcklps xmm0, xmm1"), X("unpckhps xmm0, xmm1"), X("unpcklpd xmm0, xmm1"), X("unpckhpd xmm0, xmm1"),
     X("shufps xmm0, xmm1, 0x4E"), X("shufps xmm0, xmm1, 0xB1"), X("shufpd xmm0, xmm1, 1"), X("shufpd xmm0, xmm1, 2"),
     X("andps xmm0, xmm1"), X("andnps xmm0, xmm1"), X("orps xmm0, xmm1"), X("xorps xmm0, xmm1"), X("andpd xmm0, [b]"), X("xorpd xmm0, [b]"),
     # The state as the kernel saves it: FXSAVE, a change, FXRSTOR; MXCSR; and what MMX does to the FPU's tags.
     X("fxsave [buf+64]", "pxor xmm0, xmm0", "movd xmm0, [buf+64+24]"),
     X("fxsave [buf+64]", "movdqu xmm0, [buf+64+160+16]"),
     X("fxsave [buf+64]", "pxor xmm0, xmm0", "pxor xmm1, xmm1", "fxrstor [buf+64]", "paddb xmm0, xmm1"),
     X("mov dword [buf+16], 0x3F80", "ldmxcsr [buf+16]", "stmxcsr [buf+20]", "movd xmm0, [buf+20]", "mov dword [buf+16], 0x1F80", "ldmxcsr [buf+16]"),
     X("fninit", "movq mm2, [a]", "o32 fnstenv [buf+16]", "movd xmm0, [buf+16+8]", "emms"),
     X("movq mm2, [a]", "emms", "o32 fnstenv [buf+16]", "movd xmm0, [buf+16+8]"),
     X("fninit", "fld1", "fldpi", "fxsave [buf+64]", "movdqu xmm0, [buf+64+32]", "fninit"),
     X("fninit", "fldpi", "movq2dq xmm0, mm7", "fninit"),
     X("fninit", "movq mm5, [a]", "fxsave [buf+64]", "fninit", "fxrstor [buf+64]", "movq2dq xmm0, mm5", "emms"),
     X("fninit", "fld1", "fxsave [buf+64]", "movd xmm0, [buf+64+4]", "fninit"),
     X("fninit", "movq mm5, [a]", "fxsave [buf+64]", "movd xmm0, [buf+64+32+5*16+8]", "emms"),
     X("fninit", "fld1", "movq mm2, [a]", "fnstsw ax", "movd xmm0, eax", "emms")]
groups.append(("SSE and SSE2: moves, unpacks and shuffles of floats, logic, FXSAVE and FXRSTOR, MXCSR, the FPU's tags", INT_A, INT_B, g))

g = []
for op in "add mul sub div min max".split():
    g += [X(f"{op}ps xmm0, xmm1"), X(f"{op}ss xmm0, xmm1"), X(f"{op}ss xmm0, [b+4]")]
# (The square root of a negative number is in s_sse: its sign is the host's in rustx86.)
g += [X("mulps xmm1, xmm1", "sqrtps xmm0, xmm1"), X("sqrtss xmm0, [a]")]
for pred in range(8):
    g.append(X(f"cmpps xmm0, xmm1, {pred}"))
g += [X("cmpss xmm0, xmm1, 1"), X("cmpss xmm0, [b+12], 0")]
g += [["call load", "ucomiss xmm0, xmm1", "pushf", "pop ax"], ["call load", "comiss xmm1, xmm0", "pushf", "pop ax"],
      ["call load", "ucomiss xmm0, [b+12]", "pushf", "pop ax"], ["call load", "shufps xmm0, xmm0, 0xFF", "comiss xmm0, [b+12]", "pushf", "pop ax"]]
groups.append(("SSE: single-precision arithmetic and comparison", SNG_A, SNG_B, g))

g = []
for op in "add mul sub div min max".split():
    g += [X(f"{op}pd xmm0, xmm1"), X(f"{op}sd xmm0, xmm1"), X(f"{op}sd xmm0, [b+8]")]
g += [X("sqrtpd xmm0, [b]"), X("sqrtsd xmm0, xmm1")]
for pred in range(8):
    g.append(X(f"cmppd xmm0, xmm1, {pred}"))
g += [X("cmpsd xmm0, xmm1, 2"), X("cmpsd xmm0, [a], 0")]
g += [["call load", "ucomisd xmm0, xmm1", "pushf", "pop ax"], ["call load", "comisd xmm1, xmm0", "pushf", "pop ax"],
      ["call load", "comisd xmm0, [a]", "pushf", "pop ax"], ["call load", "xorpd xmm1, xmm1", "divsd xmm1, xmm1", "ucomisd xmm0, xmm1", "pushf", "pop ax"]]
groups.append(("SSE2: double-precision arithmetic and comparison", DBL_A, DBL_B, g))

g = [X("mov eax, -7", "cvtsi2sd xmm0, eax"), X("mov eax, 123456789", "cvtsi2ss xmm0, eax"), X("cvtsi2sd xmm0, dword [b+8]"),
     X("cvttss2si eax, xmm0", "movd xmm0, eax"), X("cvttss2si eax, [a+4]", "movd xmm0, eax"),
     X("cvttsd2si eax, xmm1", "movd xmm0, eax"), X("cvttsd2si eax, [b+8]", "movd xmm0, eax"),
     X("cvtps2pd xmm0, xmm0"), X("cvtpd2ps xmm0, xmm1"), X("cvtss2sd xmm0, [a+8]"), X("cvtsd2ss xmm0, xmm1"),
     X("cvtdq2ps xmm0, [b]"), X("cvttps2dq xmm0, xmm0"),
     X("cvtdq2pd xmm0, [b]"), X("cvttpd2dq xmm0, xmm1"),
     X("cvtpi2ps xmm0, [b]"), X("cvtpi2pd xmm0, [b]"),
     X("cvttps2pi mm0, xmm0", "movq2dq xmm0, mm0", "emms"),
     X("cvttpd2pi mm0, xmm1", "movq2dq xmm0, mm0", "emms")]
groups.append(("SSE and SSE2: conversions between integers, singles and doubles", CVT_A, CVT_B, g))

def source(n, total, what, a, b, cases):
    body = "".join("    " + l + "\n" for c in cases for l in c)
    return HEAD.format(n=n, total=total, what=what) + body + TAIL.format(a=a, b=b)

def fits(src):
    with tempfile.TemporaryDirectory() as t:
        p = os.path.join(t, "x.asm")
        open(p, "w").write(src)
        r = subprocess.run(["nasm", "-w-other", "-I", "tests/asm/", "-f", "bin", "-o", os.path.join(t, "x.bin"), p], capture_output=True, text=True)
        if r.returncode != 0 and "TIMES value" not in r.stderr:
            sys.exit(r.stderr)
        return r.returncode == 0

files = []
for what, a, b, cases in groups:
    while cases:
        n = len(cases)
        while not fits(source(0, 0, what, a, b, cases[:n])):
            n -= 1
        files.append((what, a, b, cases[:n]))
        cases = cases[n:]
for old in os.listdir("tests/asm"):
    if old.startswith("v_sse"):
        os.remove(os.path.join("tests/asm", old))
for i, (what, a, b, cases) in enumerate(files):
    open(f"tests/asm/v_sse{i + 1:02d}.asm", "w").write(source(i + 1, len(files), what, a, b, cases))
print(len(files), "files,", sum(len(f[3]) for f in files), "cases")
