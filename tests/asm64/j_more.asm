; Five instructions a block does itself since E177: XADD (registers and memory, 32 and 64
; bits, with LOCK and of a register with itself), BT, BTS, BTR and BTC of memory by a
; constant (16, 32 and 64 bits; the carry is taken up behind each), SETcc into memory,
; PUSH of memory, XCHG (registers and memory). In a run that goes round often enough to be
; translated, on values that change every round. All of it is added into R13, which is
; compared at the end with what the interpreter (held to the real CPU by the trace)
; gives: a wrong translation under --jit leaves by `bad`. difftest64.sh runs it again with
; --jit-check and with --jit.
%include "elf.inc"

EXPECTED equ 0x4E943D5FAAC2F85E                          ; R13 at the end, as the interpreter and the real CPU have it

    mov r15d, 24
    lea rbp, [data]
    xor r13d, r13d
    mov rbx, 0x8123456789ABCDEF
top:
    ; XADD
    mov rax, rbx
    mov rcx, r13
    xadd rax, rcx
    adc r13, rax
    add r13, rcx
    mov rax, rbx
    mov ecx, r15d
    xadd eax, ecx
    adc r13, rax
    add r13, rcx
    mov [rbp], rbx
    mov rax, r13
    xadd [rbp], rax
    adc r13, rax
    add r13, [rbp]
    mov ecx, 0x7FFFFFFF
    lock xadd [rbp + 8], ecx
    seto dl
    movzx edx, dl
    add r13, rdx
    add r13, rcx
    add r13, [rbp + 8]
    mov rax, rbx
    xadd rax, rax
    add r13, rax
    ; BT, BTS, BTR, BTC of memory by a constant
    mov [rbp + 16], rbx
    bt qword [rbp + 16], 5
    adc r13, 0
    bts qword [rbp + 16], 62
    adc r13, 0
    btr qword [rbp + 16], 0
    adc r13, 0
    btc qword [rbp + 16], 33
    adc r13, 0
    lock bts dword [rbp + 16], 31
    adc r13, 0
    btr dword [rbp + 20], 7
    adc r13, 0
    bts word [rbp + 16], 3
    adc r13, 0
    btc word [rbp + 18], 15
    adc r13, 0
    bt dword [rbp + 16], 95                 ; a number over the width: its low bits
    adc r13, 0
    add r13, [rbp + 16]
    ; SETcc into memory
    mov qword [rbp + 24], -1
    cmp rbx, r13
    setb [rbp + 24]
    setl [rbp + 25]
    cmp ebx, r13d
    setne [rbp + 26]
    setg [rbp + 27]
    test bl, 1
    setz [rbp + 28]
    sets [rbp + 29]
    add r13, [rbp + 24]
    ; PUSH of memory
    push qword [rbp + 16]
    push qword [rbp]
    pop rax
    add r13, rax
    pop rax
    xor r13, rax
    ; XCHG
    mov rax, rbx
    mov rcx, r13
    xchg rax, rcx
    add r13, rax
    sub r13, rcx
    xchg rax, [rbp + 32]
    add r13, rax
    mov eax, r15d
    xchg eax, [rbp + 40]
    add r13, rax
    add r13, [rbp + 40]
    ; the next round's value
    mov rax, 0x9E3779B97F4A7C15
    imul rbx, rax
    add rbx, r13
    sub r15d, 1
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
    times 16 dq 0
file_end:
