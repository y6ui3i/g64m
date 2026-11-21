; The scalar SSE instructions in runs that go round often enough to be translated (E132).
; The trace, with the XMM registers, holds the interpreter to the real CPU; difftest64.sh
; runs every test again with --jit-check and with --jit. Where the host's arithmetic is
; not the chip's (a result that is not a number, a conversion out of range) the block is
; left or the chip's answer made: those are here too. A jump to `bad` is never taken.
%include "elf.inc"

    mov r15d, 40
    lea rbp, [data]
top:
    movsd xmm0, [d_three]               ; a scalar from memory clears the rest
    movsd xmm1, [d_half]
    movaps xmm2, [v_ones]
    movsd xmm2, xmm0                    ; between registers the rest stays
    movss xmm3, [s_two]
    movaps xmm4, [v_ones]
    movss xmm4, xmm3
    addsd xmm0, xmm1                    ; 3.5
    mulsd xmm0, [d_three]               ; 10.5
    subsd xmm0, xmm1                    ; 10
    divsd xmm0, [d_three]
    sqrtsd xmm5, xmm0
    movss xmm6, [s_two]
    addss xmm6, xmm3
    mulss xmm6, [s_third]
    divss xmm6, xmm3
    sqrtss xmm7, xmm6
    movsd [rbp], xmm0
    movss [rbp + 8], xmm6
    movups [rbp + 16], xmm2
    movdqu xmm8, [rbp + 16]
    movdqa xmm9, xmm8
    movdqa [rbp + 32], xmm9
    movq rax, xmm0
    movd ebx, xmm6
    movq xmm10, rax
    mov rbx, 0x1122334455667788
    movd xmm11, ebx                     ; 32 bits of the register
    mov rcx, -1
    movd ecx, xmm2                      ; 32 bits of the XMM register, the upper half of RCX cleared
    movaps xmm12, [v_ones]
    db 0x66, 0x41, 0x0F, 0xD6, 0xD4     ; MOVQ XMM12, XMM2 by its other opcode: the rest cleared
    movaps xmm13, [v_ones]
    movq xmm13, xmm0                    ; and by this one
    movsd xmm14, [rbp + 88]             ; what the round before left
    addsd xmm14, [d_three]
    movaps xmm15, [v_ones]
    movaps [rbp + 80], xmm15            ; sixteen bytes over it
    movsd [rbp + 88], xmm14             ; and the sum back
    movq [rbp + 48], xmm5
    movd [rbp + 56], xmm7
    jmp .c0
.c0:
    ; Each of these leaves its block (the result is not a finite number), and what is
    ; behind it in the block would be interpreted: so each is a block's last.
    xorpd xmm0, xmm0
    divsd xmm0, xmm0                    ; 0 / 0: not a number, the chip's own
    jmp .n1
.n1:
    movsd xmm1, [d_minus]
    sqrtsd xmm1, xmm1                   ; the root of -1
    jmp .n2
.n2:
    movsd xmm2, [d_huge]
    mulsd xmm2, xmm2                    ; too large: infinity
    jmp .n3
.n3:
    movsd xmm3, [d_nan]
    addsd xmm3, [d_three]               ; an operand that is not a number comes out
    jmp .n4
.n4:
    movss xmm4, [s_two]
    xorps xmm13, xmm13
    divss xmm4, xmm13                   ; 2 / 0: infinity
    jmp .n5
.n5:
    xorps xmm14, xmm14
    divss xmm14, xmm14                  ; 0 / 0 in singles
    jmp .n6
.n6:
    movss xmm15, [s_minus]
    sqrtss xmm15, xmm15
    jmp .n7
.n7:
    movsd xmm9, [d_three]
    sqrtsd xmm10, xmm9                  ; the root of the second operand, whatever the first holds
    jmp .c1
.c1:
    mov eax, -7
    cvtsi2sd xmm0, eax
    mov rbx, 0x7FFFFFFFFFFFFFFF
    cvtsi2sd xmm1, rbx                  ; rounded to 2^63
    cvtsi2ss xmm2, rbx
    cvtsi2ss xmm3, dword [i_big]
    cvttsd2si ecx, xmm0                 ; -7
    cvttsd2si rdx, xmm1                 ; out of range: the smallest integer
    movsd xmm4, [d_three]
    cvttsd2si esi, xmm4
    movsd xmm5, [d_huge]
    cvttsd2si edi, xmm5                 ; out of range in 32 bits
    cvttsd2si r8, [d_nan]               ; not a number
    cvttss2si r9d, xmm3
    cvttsd2si r10d, [d_minus_big]       ; just inside
    cvtss2sd xmm6, [s_third]
    cvtsd2ss xmm7, [d_half]
    cvtsd2ss xmm8, [d_huge]             ; too large for a single: infinity
    jmp .c2
.c2:
    movsd xmm0, [d_half]
    movsd xmm1, [d_three]
    ucomisd xmm0, xmm1                  ; less
    jae bad
    jp bad
    ucomisd xmm1, xmm0                  ; greater
    jbe bad
    ucomisd xmm0, [d_nan]               ; unordered
    jnp bad
    ja bad
    comisd xmm1, xmm1                   ; equal, read from the record by the next block
    jmp .c3
.c3:
    mov ebp, 1
    jne bad
    jc bad
    lea rbp, [data]
    movss xmm2, [s_two]
    ucomiss xmm2, [s_third]
    jbe bad
    movsd xmm3, [d_half]
    minsd xmm3, [d_three]               ; the first is less: it stays
    movsd xmm4, [d_three]
    minsd xmm4, [d_half]
    movsd xmm5, [d_half]
    maxsd xmm5, [d_nan]                 ; not a number: the second
    movsd xmm6, [d_nan]
    maxsd xmm6, [d_half]
    movsd xmm9, [d_half]
    minsd xmm9, [d_nan]                 ; not a number: the second, for the smaller too
    ucomisd xmm9, xmm9                  ; (and it is not a number: a run with --jit alone is held)
    jnp bad
    movsd xmm10, [d_nan]
    minsd xmm10, [d_half]
    xorpd xmm7, xmm7
    movsd xmm8, [d_negzero]
    minsd xmm7, xmm8                    ; zeros of both signs are equal: the second
    maxss xmm2, [s_third]
    movaps xmm9, [v_ones]
    andps xmm9, [v_mask]
    movaps xmm10, [v_mask]
    andnps xmm10, [v_ones]
    orps xmm10, xmm9
    xorps xmm9, [v_ones]
    movdqa xmm11, [v_mask]
    pxor xmm11, xmm9
    por xmm11, [v_ones]
    pand xmm11, [v_mask]
    dec r15d
    jnz top
    EXIT
bad:
    mov eax, 60
    mov edi, 1
    syscall

    align 16
v_ones:     dq 0x1111111122222222, 0x3333333344444444
v_mask:     dq 0x00FF00FF00FF00FF, 0xFFFF0000FFFF0000
d_three:    dq 3.0
d_half:     dq 0.5
d_minus:    dq -1.0
d_huge:     dq 1.0e300
d_nan:      dq 0x7FF4000000000001
d_negzero:  dq 0x8000000000000000
d_minus_big: dq -2147483648.5
s_two:      dd 2.0
s_third:    dd 0.33333334
s_minus:    dd -1.0
i_big:      dd 0x7FFFFFFF
    times 0x3000 - ($ - $$) db 0
data:
    times 128 db 0
file_end:
