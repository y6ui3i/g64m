; The packed forms p_simd was left with, in blocks (E159): the shifts of words and
; doublewords by a constant (right, right keeping the sign, left; by nothing, by the width
; and by more), PMULUDQ, SHUFPS and SHUFPD, from a register and from memory.
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
    psrld xmm2, 7
    movdqa xmm3, xmm0
    pslld xmm3, 31
    movdqa xmm4, xmm1
    psrad xmm4, 9
    movdqa xmm5, xmm1
    psrad xmm5, 32                      ; the sign in every bit
    movdqa xmm6, xmm0
    psrld xmm6, 32                      ; all of it gone
    movdqa xmm7, xmm0
    pslld xmm7, 200
    movdqa xmm8, xmm0
    psrld xmm8, 0                       ; nothing
    movdqa xmm9, xmm1
    psrlw xmm9, 3
    movdqa xmm10, xmm1
    psllw xmm10, 15
    movdqa xmm11, xmm0
    psraw xmm11, 5
    movdqa xmm12, xmm0
    psraw xmm12, 77
    movdqa xmm13, xmm1
    psllw xmm13, 16
    movdqa xmm14, xmm0
    pmuludq xmm14, xmm1
    movdqa xmm15, xmm1
    pmuludq xmm15, [rbp]
    movdqa xmm2, xmm0
    pmuludq xmm2, xmm2
    movaps xmm3, xmm0
    shufps xmm3, xmm1, 0x1B
    movaps xmm4, xmm0
    shufps xmm4, [rbp + 16], 0xE4
    movaps xmm5, xmm1
    shufps xmm5, xmm5, 0x72
    movaps xmm6, xmm0
    shufps xmm6, xmm1, 0x88
    movapd xmm7, xmm0
    shufpd xmm7, xmm1, 1
    movapd xmm9, xmm0
    shufpd xmm9, [rbp + 16], 2
    movapd xmm10, xmm1
    shufpd xmm10, xmm10, 3
    paddq xmm0, xmm14                   ; the data for the next round
    pxor xmm1, xmm3
    paddd xmm1, xmm11
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
