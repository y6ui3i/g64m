; MMX and SSE2, part 11 of 11: SSE and SSE2: conversions between integers, singles and doubles. Written by tools/gen_sse_tests.py; change the list
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
    mov eax, -7
    cvtsi2sd xmm0, eax
    call show
    call load
    mov eax, 123456789
    cvtsi2ss xmm0, eax
    call show
    call load
    cvtsi2sd xmm0, dword [b+8]
    call show
    call load
    cvttss2si eax, xmm0
    movd xmm0, eax
    call show
    call load
    cvttss2si eax, [a+4]
    movd xmm0, eax
    call show
    call load
    cvttsd2si eax, xmm1
    movd xmm0, eax
    call show
    call load
    cvttsd2si eax, [b+8]
    movd xmm0, eax
    call show
    call load
    cvtps2pd xmm0, xmm0
    call show
    call load
    cvtpd2ps xmm0, xmm1
    call show
    call load
    cvtss2sd xmm0, [a+8]
    call show
    call load
    cvtsd2ss xmm0, xmm1
    call show
    call load
    cvtdq2ps xmm0, [b]
    call show
    call load
    cvttps2dq xmm0, xmm0
    call show
    call load
    cvtdq2pd xmm0, [b]
    call show
    call load
    cvttpd2dq xmm0, xmm1
    call show
    call load
    cvtpi2ps xmm0, [b]
    call show
    call load
    cvtpi2pd xmm0, [b]
    call show
    call load
    cvttps2pi mm0, xmm0
    movq2dq xmm0, mm0
    emms
    call show
    call load
    cvttpd2pi mm0, xmm1
    movq2dq xmm0, mm0
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
a:  dd 2.25, -3.75, 100000.75, -0.4
b:  dq 2.75, -1234567.25
c:  dq 3, 0x1111111111111111            ; a shift count
d:  dq 40, 0                            ; and one that is too many for some lanes
    TAIL
