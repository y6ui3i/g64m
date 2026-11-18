; MMX and SSE2, part 9 of 11: SSE: single-precision arithmetic and comparison. Written by tools/gen_sse_tests.py; change the list
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
    addps xmm0, xmm1
    call show
    call load
    addss xmm0, xmm1
    call show
    call load
    addss xmm0, [b+4]
    call show
    call load
    mulps xmm0, xmm1
    call show
    call load
    mulss xmm0, xmm1
    call show
    call load
    mulss xmm0, [b+4]
    call show
    call load
    subps xmm0, xmm1
    call show
    call load
    subss xmm0, xmm1
    call show
    call load
    subss xmm0, [b+4]
    call show
    call load
    divps xmm0, xmm1
    call show
    call load
    divss xmm0, xmm1
    call show
    call load
    divss xmm0, [b+4]
    call show
    call load
    minps xmm0, xmm1
    call show
    call load
    minss xmm0, xmm1
    call show
    call load
    minss xmm0, [b+4]
    call show
    call load
    maxps xmm0, xmm1
    call show
    call load
    maxss xmm0, xmm1
    call show
    call load
    maxss xmm0, [b+4]
    call show
    call load
    mulps xmm1, xmm1
    sqrtps xmm0, xmm1
    call show
    call load
    sqrtss xmm0, [a]
    call show
    call load
    cmpps xmm0, xmm1, 0
    call show
    call load
    cmpps xmm0, xmm1, 1
    call show
    call load
    cmpps xmm0, xmm1, 2
    call show
    call load
    cmpps xmm0, xmm1, 3
    call show
    call load
    cmpps xmm0, xmm1, 4
    call show
    call load
    cmpps xmm0, xmm1, 5
    call show
    call load
    cmpps xmm0, xmm1, 6
    call show
    call load
    cmpps xmm0, xmm1, 7
    call show
    call load
    cmpss xmm0, xmm1, 1
    call show
    call load
    cmpss xmm0, [b+12], 0
    call show
    call load
    ucomiss xmm0, xmm1
    pushf
    pop ax
    call load
    comiss xmm1, xmm0
    pushf
    pop ax
    call load
    ucomiss xmm0, [b+12]
    pushf
    pop ax
    call load
    shufps xmm0, xmm0, 0xFF
    comiss xmm0, [b+12]
    pushf
    pop ax
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
a:  dd 1.5, -2.25, 1.0e10, 0.1
b:  dd 3.0, 0.5, -7.0, 0.1
c:  dq 3, 0x1111111111111111            ; a shift count
d:  dq 40, 0                            ; and one that is too many for some lanes
    TAIL
