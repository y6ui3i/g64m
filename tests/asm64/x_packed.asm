; The packed integer forms in blocks (E147): the shifts of an XMM register by a constant, by
; bits and by bytes; PANDN; the interleavings; PSHUFD; the sums, differences and comparisons.
; In a run that goes round often enough to be translated, on data that changes every round.
; The trace (with the XMM registers) holds the interpreter to the real CPU; difftest64.sh runs
; it again with --jit-check and with --jit.
%include "elf.inc"

    mov r15d, 14
    lea rbp, [data]
top:
    movdqu xmm0, [rbp]
    movdqu xmm1, [rbp + 16]
    movdqa xmm2, xmm0
    psrlq xmm2, 5
    movdqa xmm3, xmm0
    psllq xmm3, 63
    movdqa xmm4, xmm1
    psrldq xmm4, 3
    movdqa xmm5, xmm1
    pslldq xmm5, 9
    movdqa xmm6, xmm0
    psrldq xmm6, 16                     ; all of it gone
    movdqa xmm7, xmm0
    psrlq xmm7, 64
    movdqa xmm8, xmm0
    psllq xmm8, 0                       ; nothing
    pandn xmm8, xmm1
    movdqa xmm9, xmm0
    punpcklqdq xmm9, xmm1
    movdqa xmm10, xmm0
    punpckhqdq xmm10, [rbp + 16]
    pshufd xmm11, xmm1, 0x1B
    pshufd xmm12, [rbp], 0x4E
    movdqa xmm13, xmm0
    punpckldq xmm13, xmm1
    movdqa xmm14, xmm0
    punpcklbw xmm14, xmm1
    movdqa xmm15, xmm0
    punpcklwd xmm15, xmm1
    movdqa xmm2, xmm0
    punpckhbw xmm2, xmm1
    movdqa xmm3, xmm0
    punpckhwd xmm3, xmm1
    movdqa xmm4, xmm0
    punpckhdq xmm4, xmm1
    movdqa xmm5, xmm0
    paddb xmm5, xmm1
    movdqa xmm6, xmm0
    paddw xmm6, xmm1
    movdqa xmm7, xmm0
    paddd xmm7, [rbp + 16]
    movdqa xmm8, xmm0
    paddq xmm8, xmm1
    movdqa xmm9, xmm0
    psubb xmm9, xmm1
    movdqa xmm10, xmm0
    psubw xmm10, xmm1
    movdqa xmm13, xmm0
    psubd xmm13, xmm1
    movdqa xmm14, xmm0
    psubq xmm14, xmm1
    movdqa xmm2, xmm0
    pcmpeqb xmm2, xmm1
    movdqa xmm3, xmm0
    pcmpeqw xmm3, xmm11
    movdqa xmm4, xmm0
    pcmpeqd xmm4, xmm0
    movdqa xmm5, xmm0
    pcmpgtb xmm5, xmm1
    movdqa xmm6, xmm0
    pcmpgtw xmm6, xmm1
    movdqa xmm7, xmm0
    pcmpgtd xmm7, xmm1
    paddq xmm0, xmm11                   ; the data for the next round
    pxor xmm1, xmm12
    paddd xmm1, xmm15
    movdqu [rbp], xmm0
    movdqu [rbp + 16], xmm1
    dec r15d
    jnz top
    EXIT
    times 0x3000 - ($ - $$) db 0
data:
    dq 0x8123456789ABCDEF, 0x0FEDCBA987654321
    dq 0x00FF7F8001020304, 0x8000000180FF7F00
file_end:
