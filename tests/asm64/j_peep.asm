; What E163 changed in the generated code: AND, OR, XOR and TEST by constants the host
; takes as constants (and by ones it does not), at 32 and 64 bits; a record left out where
; only the CMOVcc or SETcc behind reads the flags, and kept where something later does;
; LEA into its own register, with it as the base and as the index, and an index alone;
; shifts by constants with the flags dead and alive; loads and stores through a register
; alone. In a run that goes round often enough to be translated, on values that change
; every round. All of it is added into R13, which is compared at the end with what the
; interpreter (held to the real CPU by the trace) gives: a wrong translation under --jit
; leaves by `bad`. difftest64.sh runs it again with --jit-check and with --jit.
%include "elf.inc"

EXPECTED equ 0xC437DEA7E66D81FE          ; R13 at the end, as the interpreter and the real CPU have it

    mov r15d, 14
    lea rbp, [data]
    xor r13d, r13d
    mov rbx, 0x8123456789ABCDEF
top:
    mov rax, rbx
    and eax, 0x7                        ; constants the host encodes
    add r13, rax
    mov rax, rbx
    and rax, -8
    add r13, rax
    mov rax, rbx
    and eax, 0x3FFF
    add r13, rax
    mov rax, rbx
    and rax, 0x7FFFFFF0
    add r13, rax
    mov rax, rbx
    and eax, 0x00FF00FF
    add r13, rax
    mov rax, rbx
    and eax, 0x80000001                 ; a run that goes round the end
    add r13, rax
    mov rax, rbx
    and eax, 0x12345                    ; one it does not
    add r13, rax
    mov rax, rbx
    or eax, 0x00F00000
    add r13, rax
    mov rax, rbx
    or rax, 0x55555555
    add r13, rax
    mov rax, rbx
    xor eax, 0xFFFF0000
    add r13, rax
    mov rax, rbx
    xor rax, -2
    add r13, rax
    mov rcx, rbx
    xor ecx, 0x1FF                      ; XOR and the jump on it
    js .neg
    add r13, 3
.neg:
    mov rcx, rbx
    and ecx, 0x20000                    ; AND and the jump on it
    jz .none
    add r13, 5
.none:
    ; TEST by a constant, its flags read by the CMOVcc only (the record left out)
    mov rax, rbx
    mov edx, 11
    mov esi, 22
    test eax, 0x20000
    cmovne edx, esi
    add r13, rdx
    ; and read again behind it (the record kept)
    mov edx, 11
    test eax, 0x40
    cmovne edx, esi
    setz cl
    movzx ecx, cl
    add r13, rdx
    add r13, rcx
    ; and read behind it by an instruction no block holds, which gets them from the record
    mov edx, 11
    test eax, 0x1000
    cmovne edx, esi
    pushfq
    pop rcx
    and ecx, 0x8C5                      ; OF, SF, ZF, PF, CF (TEST leaves AF undefined)
    add r13, rdx
    add r13, rcx
    ; a comparison, a SETcc, and the flags dead behind it
    cmp rax, r13
    setb dl
    movzx edx, dl
    add r13, rdx
    ; a SETcc of AH's kind is not taken: the record stays
    test eax, 0x8000
    setnz ch
    movzx edx, ch
    add r13, rdx
    ; a CMOVcc from memory is not one of these either
    mov edx, 7
    test eax, 0x10
    cmovz edx, [rbp + 16]
    add r13, rdx
    ; LEA: into its register, which is its base; which is its index; an index alone
    mov rsi, rbx
    lea rsi, [rsi + 0x1234]
    add r13, rsi
    mov rdi, rbx
    lea rdi, [rax + rdi*4 + 9]
    add r13, rdi
    lea rdx, [rbx*8]
    add r13, rdx
    lea edx, [rbx*8]
    add r13, rdx
    lea edx, [rbx]
    add r13, rdx
    lea ecx, [rax + rbx*2 - 77]
    add r13, rcx
    lea r8, [rel data]
    sub r8, rbp
    add r13, r8
    ; shifts by constants: the flags dead, and read
    mov rax, rbx
    shl eax, 15
    sar eax, 23
    add r13, rax
    mov rax, rbx
    shr rax, 3
    setc dl
    movzx edx, dl
    add r13, rax
    add r13, rdx
    mov eax, ebx
    shl ax, 5
    add r13, rax
    ; loads and stores through a register alone
    mov rsi, rbp
    mov [rsi], rbx
    mov eax, [rsi]
    add r13, rax
    movzx eax, byte [rsi]
    add r13, rax
    movzx eax, word [rsi]
    add r13, rax
    movsx rax, byte [rsi]
    add r13, rax
    mov [rsi], bl
    mov [rsi], bx
    mov ax, [rsi]
    add r13, rax
    mov [rsi], r13d
    mov rsi, [rsi]                      ; the base is the register loaded
    add r13, rsi
    ; the next round's value
    mov rax, 0x9E3779B97F4A7C15
    imul rbx, rax
    add rbx, r13
    dec r15d
    jnz top
    mov rax, EXPECTED
    cmp r13, rax
    jne bad
    EXIT
bad:
    mov eax, 60
    mov edi, 1
    syscall
    times 0x3000 - ($ - $$) db 0
data:
    times 2 dq 0
    dd 99
    times 14 dq 0

file_end:
