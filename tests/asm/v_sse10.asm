; MMX and SSE2, part 10 of 11: SSE2: double-precision arithmetic and comparison. Written by tools/gen_sse_tests.py; change the list
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
    addpd xmm0, xmm1
    call show
    call load
    addsd xmm0, xmm1
    call show
    call load
    addsd xmm0, [b+8]
    call show
    call load
    mulpd xmm0, xmm1
    call show
    call load
    mulsd xmm0, xmm1
    call show
    call load
    mulsd xmm0, [b+8]
    call show
    call load
    subpd xmm0, xmm1
    call show
    call load
    subsd xmm0, xmm1
    call show
    call load
    subsd xmm0, [b+8]
    call show
    call load
    divpd xmm0, xmm1
    call show
    call load
    divsd xmm0, xmm1
    call show
    call load
    divsd xmm0, [b+8]
    call show
    call load
    minpd xmm0, xmm1
    call show
    call load
    minsd xmm0, xmm1
    call show
    call load
    minsd xmm0, [b+8]
    call show
    call load
    maxpd xmm0, xmm1
    call show
    call load
    maxsd xmm0, xmm1
    call show
    call load
    maxsd xmm0, [b+8]
    call show
    call load
    sqrtpd xmm0, [b]
    call show
    call load
    sqrtsd xmm0, xmm1
    call show
    call load
    cmppd xmm0, xmm1, 0
    call show
    call load
    cmppd xmm0, xmm1, 1
    call show
    call load
    cmppd xmm0, xmm1, 2
    call show
    call load
    cmppd xmm0, xmm1, 3
    call show
    call load
    cmppd xmm0, xmm1, 4
    call show
    call load
    cmppd xmm0, xmm1, 5
    call show
    call load
    cmppd xmm0, xmm1, 6
    call show
    call load
    cmppd xmm0, xmm1, 7
    call show
    call load
    cmpsd xmm0, xmm1, 2
    call show
    call load
    cmpsd xmm0, [a], 0
    call show
    call load
    ucomisd xmm0, xmm1
    pushf
    pop ax
    call load
    comisd xmm1, xmm0
    pushf
    pop ax
    call load
    comisd xmm0, [a]
    pushf
    pop ax
    call load
    xorpd xmm1, xmm1
    divsd xmm1, xmm1
    ucomisd xmm0, xmm1
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
a:  dq 1.5, -1.0e100
b:  dq 0.75, 3.0
c:  dq 3, 0x1111111111111111            ; a shift count
d:  dq 40, 0                            ; and one that is too many for some lanes
    TAIL
