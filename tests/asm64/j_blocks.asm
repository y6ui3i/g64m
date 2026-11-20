; Runs of register-only instructions that go round often enough to be translated (E120).
; The trace holds the interpreter to the real CPU; difftest64.sh runs every test once more
; with --jit-check, which holds each block to the interpreter. Each stretch is one a wrong
; build of the translator passed before this test was there.
%include "elf.inc"

    mov r15d, 12
top:
    mov eax, 0xF0000000
    mov ebx, 0x20000000
    add eax, ebx                        ; a carry out: B after ADD
    jb .c1
    mov r8d, 1
.c1:
    mov eax, 5
    add eax, ebx                        ; none: AE
    jae .c2
    mov r8d, 2
.c2:
    mov eax, 0x80000001
    test eax, eax                       ; negative: LE after TEST
    jle .l1
    mov r9d, 1
.l1:
    mov eax, 1
    and eax, 1                          ; positive: G after AND
    jg .l2
    mov r9d, 2
.l2:
    mov eax, 0x7FFFFFFF
    inc eax                             ; overflow: SF and OF both, so not L
    jl .i1
    mov r10d, 1
.i1:
    mov eax, 0x80000000
    dec eax                             ; OF without SF: L
    jge .i2
    mov r10d, 2
.i2:
    ; The flags one block leaves, read by the next from RFLAGS.
    mov eax, 1
    cmp eax, 2                          ; CF without ZF: BE
    jmp .m1
.m1:
    mov ebp, 1                          ; (a block is two instructions at least)
    jbe .m2
    mov r11d, 1
.m2:
    mov eax, 0x80000000
    cmp eax, 1                          ; OF without SF: L
    jmp .m3
.m3:
    mov ebp, 1                          ; (a block is two instructions at least)
    jl .m4
    mov r11d, 2
.m4:
    mov eax, 7
    cmp eax, 7                          ; ZF, SF and OF equal: LE
    jmp .m5
.m5:
    mov ebp, 1                          ; (a block is two instructions at least)
    jle .m6
    mov r11d, 3
.m6:
    mov eax, 0x80000000
    mov ebx, 1
    or eax, ebx                         ; SF after OR, with the flags of the CMP before stale
    js .o1
    mov r12d, 1
.o1:
    xor eax, eax
    jnz .o2
    mov r12d, 2
.o2:
    lea rsi, [rel top]                  ; an address relative to RIP
    mov ebx, 0x80
    mov rax, -1
    movsx eax, bl                       ; the sign into 32 bits, the upper half cleared
    mov r8, rax                         ; (kept to the block's end)
    mov rcx, -1
    mov ebx, 0x80000000                 ; a constant of 32 bits is not sign-extended
    db 0x63, 0xCB                       ; MOVSXD ECX, EBX without REX.W: a plain MOV
    mov rdx, -1
    db 0xC7, 0xC2                       ; MOV EDX, a constant, the long form
    dd 0x80000000
    neg eax                             ; CF, read by the next block
    jmp .n1
.n1:
    mov ebp, 1                          ; (a block is two instructions at least)
    jnc .n2
    mov r13d, 1
.n2:
    mov eax, 0x12348080
    cwde
    mov r9, rax
    mov rdi, 0x1122334455667788
    cmp eax, eax
    sete dil                            ; one byte written
    mov rax, -1
    mov ebx, 5
    cmp ebx, 6
    cmove eax, ebx                      ; not moved: the upper half goes all the same
    mov ecx, 0
    add ebx, 0xFFFFFFFF                 ; CF
    shl edx, cl                         ; by zero: the flags of the ADD stay
    jmp .s1
.s1:
    mov ebp, 1                          ; (a block is two instructions at least)
    jnc .s2
    mov r14d, 1
.s2:
    dec r15d
    jnz top
    EXIT
file_end:
