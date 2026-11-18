; MMX and SSE2, part 1 of 11: MMX: the packed integers on 64 bits, shifts, shuffles and moves. Written by tools/gen_sse_tests.py; change the list
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
    paddb mm0, mm1
    call showm
    call load
    paddw mm0, mm1
    call showm
    call load
    paddd mm0, mm1
    call showm
    call load
    paddq mm0, mm1
    call showm
    call load
    psubb mm0, mm1
    call showm
    call load
    psubw mm0, mm1
    call showm
    call load
    psubd mm0, mm1
    call showm
    call load
    psubq mm0, mm1
    call showm
    call load
    paddusb mm0, mm1
    call showm
    call load
    paddusw mm0, mm1
    call showm
    call load
    psubusb mm0, mm1
    call showm
    call load
    psubusw mm0, mm1
    call showm
    call load
    paddsb mm0, mm1
    call showm
    call load
    paddsw mm0, mm1
    call showm
    call load
    psubsb mm0, mm1
    call showm
    call load
    psubsw mm0, mm1
    call showm
    call load
    pcmpeqb mm0, mm1
    call showm
    call load
    pcmpeqw mm0, mm1
    call showm
    call load
    pcmpeqd mm0, mm1
    call showm
    call load
    pcmpgtb mm0, mm1
    call showm
    call load
    pcmpgtw mm0, mm1
    call showm
    call load
    pcmpgtd mm0, mm1
    call showm
    call load
    pmullw mm0, mm1
    call showm
    call load
    pmulhw mm0, mm1
    call showm
    call load
    pmulhuw mm0, mm1
    call showm
    call load
    pmaddwd mm0, mm1
    call showm
    call load
    pminub mm0, mm1
    call showm
    call load
    pmaxub mm0, mm1
    call showm
    call load
    pminsw mm0, mm1
    call showm
    call load
    pmaxsw mm0, mm1
    call showm
    call load
    pavgb mm0, mm1
    call showm
    call load
    pavgw mm0, mm1
    call showm
    call load
    psadbw mm0, mm1
    call showm
    call load
    pmuludq mm0, mm1
    call showm
    call load
    pand mm0, mm1
    call showm
    call load
    pandn mm0, mm1
    call showm
    call load
    por mm0, mm1
    call showm
    call load
    pxor mm0, mm1
    call showm
    call load
    punpcklbw mm0, mm1
    call showm
    call load
    punpcklwd mm0, mm1
    call showm
    call load
    punpckldq mm0, mm1
    call showm
    call load
    punpckhbw mm0, mm1
    call showm
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
