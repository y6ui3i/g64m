; The first 64-bit test: a little of everything, to see that the oracle and the CPU agree
; on where a program starts and ends.
%include "elf.inc"
    mov rax, 0x1122334455667788
    mov ebx, eax
    add rax, rbx
    lea rsi, [msg]
    mov edx, msg_len
    mov edi, 1
    mov eax, 1
    syscall
    pushfq
    pop r9
    mov ecx, 3
.l: dec ecx
    jnz .l
    lea rdi, [buf]
    mov ecx, 4
    mov al, 0x5A
    rep stosb
    mov r10, [buf]
    EXIT
msg: db "ok", 10
msg_len equ $ - msg
buf: dq 0
file_end:
