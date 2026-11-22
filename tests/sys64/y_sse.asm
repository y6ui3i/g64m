; SSE in a machine (E139): moves through the XMM registers, to and from memory and the general
; registers, and PXOR, POR and PAND, in a loop that goes round often enough to be translated;
; the same with CR0.TS set, when every one of them must trap; and again after CLTS.
%include "sys.inc"
    jmp test
%include "idt.inc"

ROUNDS equ 24

    align 4096
test:
    call idt_init
    mov rax, cr4
    or eax, 0x600
    mov cr4, rax

    PUTS "moves through XMM registers, in a loop translated"
    lea rsi, [buf]
    mov rax, 0x1122334455667788
    mov [rsi], rax
    mov rax, 0x99AABBCCDDEEFF00
    mov [rsi + 8], rax
    mov ecx, ROUNDS
    xor ebx, ebx
.l1:
    movdqu xmm0, [rsi]
    movdqa xmm1, xmm0
    movq xmm2, rbx
    por xmm1, xmm2
    movdqa [rsi + 16], xmm1
    movups xmm3, [rsi + 16]
    movaps [rsi + 32], xmm3
    movq rax, xmm3
    add rbx, rax
    movsd xmm4, [rsi + 8]
    movsd [rsi + 48], xmm4
    movd eax, xmm4
    add rbx, rax
    movq [rsi + 56], xmm0
    pand xmm0, xmm3
    pxor xmm5, xmm5
    por xmm5, xmm0
    movq rdx, xmm5
    xor rbx, rdx
    dec ecx
    jnz .l1
    PRINT rbx
    PRINT [rsi + 16]
    PRINT [rsi + 24]
    PRINT [rsi + 32]
    PRINT [rsi + 48]
    PRINT [rsi + 56]

    PUTS "the same with CR0.TS set: every one of them traps"
    mov rax, cr0
    or eax, 8
    mov cr0, rax
    mov r12, [f_count]
    mov ecx, ROUNDS
.l2:
    mov qword [f_resume], .r2
    movdqu xmm0, [rsi]
.r2:
    mov qword [f_resume], .r3
    movq rax, xmm3
.r3:
    mov qword [f_resume], .r4
    pxor xmm1, xmm1
.r4:
    dec ecx
    jnz .l2
    mov rax, [f_count]
    sub rax, r12
    PRINT rax
    PRINT [f_vec]

    PUTS "and after CLTS"
    clts
    mov ecx, ROUNDS
.l3:
    movdqu xmm0, [rsi]
    movq rax, xmm0
    pxor xmm0, xmm3
    movq rdx, xmm0
    dec ecx
    jnz .l3
    PRINT rax
    PRINT rdx
    mov rax, [f_count]
    sub rax, r12
    PRINT rax
    EXIT

; The buffer on a page of its own: a store to the page that holds the loop would drop its
; entries from the decode cache, and after enough of them the page would be given up.
    align 4096
buf: times 64 dq 0
file_end:
