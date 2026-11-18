; MMX and SSE2, part 4 of 11: SSE2: the packed integers on 128 bits, shifts and shuffles. Written by tools/gen_sse_tests.py; change the list
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
    pxor xmm0, xmm1
    call show
    call load
    punpcklbw xmm0, xmm1
    call show
    call load
    punpcklwd xmm0, xmm1
    call show
    call load
    punpckldq xmm0, xmm1
    call show
    call load
    punpckhbw xmm0, xmm1
    call show
    call load
    punpckhwd xmm0, xmm1
    call show
    call load
    punpckhdq xmm0, xmm1
    call show
    call load
    packsswb xmm0, xmm1
    call show
    call load
    packuswb xmm0, xmm1
    call show
    call load
    packssdw xmm0, xmm1
    call show
    call load
    punpcklqdq xmm0, xmm1
    call show
    call load
    punpckhqdq xmm0, xmm1
    call show
    call load
    paddb xmm0, [b]
    call show
    call load
    paddw xmm0, [b]
    call show
    call load
    paddd xmm0, [b]
    call show
    call load
    paddq xmm0, [b]
    call show
    call load
    pxor xmm0, [b]
    call show
    call load
    pmuludq xmm0, [b]
    call show
    call load
    punpckhbw xmm0, [b]
    call show
    call load
    packssdw xmm0, [b]
    call show
    call load
    psrlw xmm0, [c]
    call show
    call load
    psrlw xmm0, [d]
    call show
    call load
    psrld xmm0, [c]
    call show
    call load
    psrld xmm0, [d]
    call show
    call load
    psrlq xmm0, [c]
    call show
    call load
    psrlq xmm0, [d]
    call show
    call load
    psraw xmm0, [c]
    call show
    call load
    psraw xmm0, [d]
    call show
    call load
    psrad xmm0, [c]
    call show
    call load
    psrad xmm0, [d]
    call show
    call load
    psllw xmm0, [c]
    call show
    call load
    psllw xmm0, [d]
    call show
    call load
    pslld xmm0, [c]
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
