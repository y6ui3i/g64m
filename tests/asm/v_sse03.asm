; MMX and SSE2, part 3 of 11: SSE2: the packed integers on 128 bits, shifts and shuffles. Written by tools/gen_sse_tests.py; change the list
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
    paddb xmm0, xmm1
    call show
    call load
    paddw xmm0, xmm1
    call show
    call load
    paddd xmm0, xmm1
    call show
    call load
    paddq xmm0, xmm1
    call show
    call load
    psubb xmm0, xmm1
    call show
    call load
    psubw xmm0, xmm1
    call show
    call load
    psubd xmm0, xmm1
    call show
    call load
    psubq xmm0, xmm1
    call show
    call load
    paddusb xmm0, xmm1
    call show
    call load
    paddusw xmm0, xmm1
    call show
    call load
    psubusb xmm0, xmm1
    call show
    call load
    psubusw xmm0, xmm1
    call show
    call load
    paddsb xmm0, xmm1
    call show
    call load
    paddsw xmm0, xmm1
    call show
    call load
    psubsb xmm0, xmm1
    call show
    call load
    psubsw xmm0, xmm1
    call show
    call load
    pcmpeqb xmm0, xmm1
    call show
    call load
    pcmpeqw xmm0, xmm1
    call show
    call load
    pcmpeqd xmm0, xmm1
    call show
    call load
    pcmpgtb xmm0, xmm1
    call show
    call load
    pcmpgtw xmm0, xmm1
    call show
    call load
    pcmpgtd xmm0, xmm1
    call show
    call load
    pmullw xmm0, xmm1
    call show
    call load
    pmulhw xmm0, xmm1
    call show
    call load
    pmulhuw xmm0, xmm1
    call show
    call load
    pmaddwd xmm0, xmm1
    call show
    call load
    pminub xmm0, xmm1
    call show
    call load
    pmaxub xmm0, xmm1
    call show
    call load
    pminsw xmm0, xmm1
    call show
    call load
    pmaxsw xmm0, xmm1
    call show
    call load
    pavgb xmm0, xmm1
    call show
    call load
    pavgw xmm0, xmm1
    call show
    call load
    psadbw xmm0, xmm1
    call show
    call load
    pmuludq xmm0, xmm1
    call show
    call load
    pand xmm0, xmm1
    call show
    call load
    pandn xmm0, xmm1
    call show
    call load
    por xmm0, xmm1
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
