; MMX and SSE2, part 5 of 11: SSE2: the packed integers on 128 bits, shifts and shuffles. Written by tools/gen_sse_tests.py; change the list
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
    pslld xmm0, [d]
    call show
    call load
    psllq xmm0, [c]
    call show
    call load
    psllq xmm0, [d]
    call show
    call load
    psrlw xmm0, 5
    call show
    call load
    psrad xmm0, 31
    call show
    call load
    psllq xmm0, 13
    call show
    call load
    psrlq xmm0, 64
    call show
    call load
    psraw xmm0, 16
    call show
    call load
    psrldq xmm0, 3
    call show
    call load
    pslldq xmm0, 9
    call show
    call load
    psrldq xmm0, 8
    call show
    call load
    pslldq xmm0, 16
    call show
    call load
    pshufd xmm0, xmm1, 0x1B
    call show
    call load
    pshuflw xmm0, xmm1, 0x39
    call show
    call load
    pshufhw xmm0, xmm1, 0x93
    call show
    call load
    pshufd xmm0, [b], 0x4E
    call show
    call load
    mov eax, 0xBEEF
    pinsrw xmm0, eax, 5
    call show
    call load
    pinsrw xmm0, [b], 2
    call show
    call load
    pextrw eax, xmm1, 6
    movd xmm0, eax
    call show
    call load
    pmovmskb eax, xmm1
    movd xmm0, eax
    call show
    call load
    movmskps eax, xmm1
    movd xmm0, eax
    call show
    call load
    movmskpd eax, xmm1
    movd xmm0, eax
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
