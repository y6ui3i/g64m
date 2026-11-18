; MMX and SSE2, part 2 of 11: MMX: the packed integers on 64 bits, shifts, shuffles and moves. Written by tools/gen_sse_tests.py; change the list
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
    punpckhwd mm0, mm1
    call showm
    call load
    punpckhdq mm0, mm1
    call showm
    call load
    packsswb mm0, mm1
    call showm
    call load
    packuswb mm0, mm1
    call showm
    call load
    packssdw mm0, mm1
    call showm
    call load
    psrlw mm0, [c]
    call showm
    call load
    psrlw mm0, [d]
    call showm
    call load
    psrld mm0, [c]
    call showm
    call load
    psrld mm0, [d]
    call showm
    call load
    psrlq mm0, [c]
    call showm
    call load
    psrlq mm0, [d]
    call showm
    call load
    psraw mm0, [c]
    call showm
    call load
    psraw mm0, [d]
    call showm
    call load
    psrad mm0, [c]
    call showm
    call load
    psrad mm0, [d]
    call showm
    call load
    psllw mm0, [c]
    call showm
    call load
    psllw mm0, [d]
    call showm
    call load
    pslld mm0, [c]
    call showm
    call load
    pslld mm0, [d]
    call showm
    call load
    psllq mm0, [c]
    call showm
    call load
    psllq mm0, [d]
    call showm
    call load
    psrlq mm0, 7
    call showm
    call load
    psraw mm0, 20
    call showm
    call load
    pslld mm0, 9
    call showm
    call load
    pshufw mm0, mm1, 0x2D
    call showm
    call load
    mov eax, 0xBEEF
    pinsrw mm0, eax, 2
    call showm
    call load
    pextrw eax, mm1, 1
    movd mm0, eax
    call showm
    call load
    pmovmskb eax, mm1
    movd mm0, eax
    call showm
    call load
    movd eax, mm1
    movd mm0, eax
    call showm
    call load
    movq [buf+16], mm1
    movq mm0, [buf+16]
    call showm
    call load
    movq mm0, mm1
    call showm
    call load
    movntq [buf+16], mm1
    movq mm0, [buf+16]
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
