; BSF, BSR, BSWAP, CMPXCHG, INC and DEC of memory and TEST of memory with a constant, in a
; run that goes round often enough to be translated (E147). The trace holds the interpreter
; to the real CPU; difftest64.sh runs it again with --jit-check and with --jit. A jump to
; `bad` is never taken.
%include "elf.inc"

    mov r15d, 14
    xor r13d, r13d
    lea rbp, [data]
top:
    ; BSF and BSR
    mov rax, 0x0000100000000100
    bsf rcx, rax
    cmp rcx, 8
    jne bad
    bsr rdx, rax
    cmp rdx, 44
    jne bad
    mov ebx, 0x80000001
    bsf esi, ebx
    test esi, esi
    jnz bad
    bsr edi, ebx
    cmp edi, 31
    jne bad
    xor eax, eax
    mov rcx, 0x1122334455667788
    bsf ecx, eax                        ; of zero: ZF, and the register as it was, upper half and all
    jnz bad
    mov rdx, 0x1122334455667788
    cmp rcx, rdx
    jne bad
    mov eax, 16
    bsf ecx, eax                        ; not zero: ZF clear, read from the record
    jz bad
    mov eax, 0x20
    tzcnt ecx, eax                      ; F3h in front: BSF on a CPU without TZCNT
    cmp ecx, 5
    jne bad
    mov qword [rbp + 48], 0x4000
    bsf rcx, [rbp + 48]
    cmp rcx, 14
    jne bad
    bsr ecx, [rbp + 48]
    cmp ecx, 14
    jne bad
    ; BSWAP
    mov rax, 0x1122334455667788
    bswap rax
    mov rdx, 0x8877665544332211
    cmp rax, rdx
    jne bad
    bswap eax                           ; the lower half, the upper cleared
    cmp rax, 0x11223344
    jne bad
    mov r9, 0x0102030405060708
    bswap r9
    mov rdx, 0x0807060504030201
    cmp r9, rdx
    jne bad
    ; CMPXCHG
    mov eax, 5
    mov ebx, 5
    mov ecx, 9
    cmpxchg rbx, rcx                    ; equal: the operand takes the register
    jnz bad
    cmp rbx, 9
    jne bad
    cmp rax, 5
    jne bad
    mov eax, 6
    mov ebx, 5
    cmpxchg rbx, rcx                    ; not equal: A takes the operand
    jz bad
    jb bad                              ; 6 less 5: no borrow
    cmp rax, 5
    jne bad
    cmp rbx, 5
    jne bad
    mov qword [rbp], 77
    mov eax, 77
    mov ecx, 99
    lock cmpxchg [rbp], ecx
    jnz bad
    cmp dword [rbp], 99
    jne bad
    mov rax, 0xFFFFFFFF00000001
    lock cmpxchg [rbp], ecx             ; 1 and 99: A takes 99, its upper half cleared
    jz bad
    cmp rax, 99
    jne bad
    mov qword [rbp + 8], 0
    mov eax, 99
    mov edx, 123
    lock cmpxchg [rbp + 8], rdx         ; 99 and 0: A takes 0
    jz bad
    test rax, rax
    jnz bad
    lock cmpxchg [rbp + 8], rdx         ; 0 and 0: memory takes 123
    jnz bad
    cmp qword [rbp + 8], 123
    jne bad
    ; INC and DEC of memory
    mov dword [rbp + 16], 0x7FFFFFFF
    inc dword [rbp + 16]                ; overflow, and the sign
    jno bad
    jns bad
    mov qword [rbp + 24], 1
    dec qword [rbp + 24]
    jnz bad
    mov eax, 1
    cmp eax, 2                          ; a borrow, which INC leaves
    inc dword [rbp + 16]
    jnc bad
    cmp dword [rbp + 16], 0x80000001
    jne bad
    inc qword [rbp + 32]                ; flags no one reads
    cmp eax, eax
    dec dword [rbp + 40]
    mov ecx, [rbp + 40]
    add ecx, [rbp + 32]                 ; one up and one down each round: nothing
    jnz bad
    ; TEST of memory with a constant
    mov dword [rbp + 56], 0x00F00000
    test dword [rbp + 56], 0x00100000
    jz bad
    test dword [rbp + 56], 0x0000000F
    jnz bad
    mov rax, 0x8000000000000000
    mov [rbp + 56], rax
    test qword [rbp + 56], -1
    jns bad
    jz bad
    ; A TEST whose flags no one reads but the jump behind it, behind a shift by CL in the
    ; same block (E147): the jump must go by the TEST and not by the shift's record. The
    ; jump is taken in the first round only, so that both its sides are known.
    mov eax, 5
    xor esi, esi
    cmp r15d, 14
    cmove eax, esi                      ; 0 in the first round
    mov edx, 1
    mov cl, 1
    shr rdx, cl                         ; 0: ZF
    movq xmm0, rdx                      ; (the look ahead for dead flags stops here)
    test eax, eax
    je .zero
    cmp eax, eax
    jmp .counted
.zero:
    cmp eax, eax
    add r13d, 1
.counted:
    dec r15d
    jnz top
    cmp r13d, 1                         ; the jump on the TEST was taken once
    jne bad
    EXIT
bad:
    mov eax, 60
    mov edi, 1
    syscall
    times 0x3000 - ($ - $$) db 0
data:
    times 16 dq 0
file_end:
