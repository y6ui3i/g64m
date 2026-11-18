; MMX and SSE2, part 7 of 11: SSE and SSE2: moves, unpacks and shuffles of floats, logic, FXSAVE and FXRSTOR, MXCSR, the FPU's tags. Written by tools/gen_sse_tests.py; change the list
; there, not this file. The trace has no XMM or MMX state: each case leaves its result in XMM0
; or MM0, and `show` stores it and loads it into EAX, EBX, ECX and EDX. Runs on the i686
; (--cpu i686).
%define CPU686
%include "common.inc"
cpu prescott
buf equ 0x1000
start:
    HDR
    call load
    unpcklps xmm0, xmm1
    call show
    call load
    unpckhps xmm0, xmm1
    call show
    call load
    unpcklpd xmm0, xmm1
    call show
    call load
    unpckhpd xmm0, xmm1
    call show
    call load
    shufps xmm0, xmm1, 0x4E
    call show
    call load
    shufps xmm0, xmm1, 0xB1
    call show
    call load
    shufpd xmm0, xmm1, 1
    call show
    call load
    shufpd xmm0, xmm1, 2
    call show
    call load
    andps xmm0, xmm1
    call show
    call load
    andnps xmm0, xmm1
    call show
    call load
    orps xmm0, xmm1
    call show
    call load
    xorps xmm0, xmm1
    call show
    call load
    andpd xmm0, [b]
    call show
    call load
    xorpd xmm0, [b]
    call show
    call load
    fxsave [buf+64]
    pxor xmm0, xmm0
    movd xmm0, [buf+64+24]
    call show
    call load
    fxsave [buf+64]
    movdqu xmm0, [buf+64+160+16]
    call show
    call load
    fxsave [buf+64]
    pxor xmm0, xmm0
    pxor xmm1, xmm1
    fxrstor [buf+64]
    paddb xmm0, xmm1
    call show
    call load
    mov dword [buf+16], 0x3F80
    ldmxcsr [buf+16]
    stmxcsr [buf+20]
    movd xmm0, [buf+20]
    mov dword [buf+16], 0x1F80
    ldmxcsr [buf+16]
    call show
    call load
    fninit
    movq mm2, [a]
    o32 fnstenv [buf+16]
    movd xmm0, [buf+16+8]
    emms
    call show
    call load
    movq mm2, [a]
    emms
    o32 fnstenv [buf+16]
    movd xmm0, [buf+16+8]
    call show
    call load
    fninit
    fld1
    fldpi
    fxsave [buf+64]
    movdqu xmm0, [buf+64+32]
    fninit
    call show
    call load
    fninit
    fldpi
    movq2dq xmm0, mm7
    fninit
    call show
    call load
    fninit
    movq mm5, [a]
    fxsave [buf+64]
    fninit
    fxrstor [buf+64]
    movq2dq xmm0, mm5
    emms
    call show
    hlt
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
a:  db 0x7F, 0xFF, 0x80, 0x00, 0x01, 0xFE, 0x81, 0x7E, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0
b:  db 0x01, 0x80, 0xFF, 0x7F, 0x02, 0x03, 0xFF, 0x80, 0x0F, 0x1E, 0x2D, 0x3C, 0x4B, 0x5A, 0x69, 0x78
c:  dq 3, 0x1111111111111111            ; a shift count
d:  dq 40, 0                            ; and one that is too many for some lanes
    TAIL
