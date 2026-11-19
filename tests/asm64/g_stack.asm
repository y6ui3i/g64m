; PUSH and POP in their forms, PUSHF and POPF, CALL, RET, the jumps through registers and memory, LOOP, JRCXZ and LEAVE.
; Written by tools/gen64_tests.py: change that, not this.
%include "elf.inc"
    mov rax, 0xDDB34413D4C0CE
    mov rcx, 0x7FFFFFFF
    mov rdx, 0xFFFFFFFFFFFFFF23
    mov rbx, 0x100
    mov rbp, 0xFFFFFFFFFFFFFFFF
    mov rsi, 0x0
    mov rdi, 0xED0296C62F7C4917
    mov r8, 0xF53D42328FDBE68D
    mov r9, 0x81
    mov r10, 0x29E4446558A2931D
    mov r11, 0xE13D6FC7E9BD8376
    mov r12, 0x981B28A628A114FD
    mov r13, 0xF6B432438ACDAAFE
    mov r14, 0x6B352A2808476CD5
    mov r15, 0x8000000000000000
    push rax
    push rcx
    push rdx
    push rbx
    push rbp
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    pop rbp
    pop r12
    pop r13
    pop r8
    pop r14
    pop rdx
    pop rcx
    pop rax
    pop rsi
    pop r9
    pop r10
    pop r11
    pop rbx
    pop r15
    pop rdi
    push ax
    pop bp
    push bx
    pop r8w
    push r9w
    pop r14w
    push r14w
    pop bx
    push 0x7F
    push -0x80
    push 0x12345678
    push -0x12345678
    push word 0x1234
    push word -2
    pop ax
    pop bx
    pop rax
    pop rbx
    pop rcx
    pop rdx
    push rsp
    pop rax
    push qword [buf]
    pop qword [buf + 8]
    push word [buf + 3]
    pop word [buf + 17]
    mov rsi, [buf + 8]
    mov rdi, [buf + 16]
    push 0x55
    push 0x66
    pop qword [rsp]
    pop rax
    mov rax, rsp
    push 0x77
    pop rsp
    mov rsp, rax
    mov rax, 0x202
    push rax
    popfq
    pushfq
    pop rbx
    mov rax, 0xAD7
    push rax
    popfq
    pushfq
    pop rbx
    mov rax, 0x602
    push rax
    popfq
    pushfq
    pop rbx
    mov rax, 0x40202
    push rax
    popfq
    pushfq
    pop rbx
    mov rax, 0x200202
    push rax
    popfq
    pushfq
    pop rbx
    mov rax, 0x4202
    push rax
    popfq
    pushfq
    pop rbx
    mov rax, 0xFFFFFFFFFFFF08D5
    push rax
    popfw
    pushfw
    pop cx
    FLAGS 0x202
    stc
    cmc
    cmc
    clc
    std
    cld
    jmp over
f1:
    inc r8
    ret
f2:
    call f1
    inc r9
    ret 16
f3:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp - 8], r8
    leave
    ret
over:
    call f1
    push 1
    push 2
    call f2
    call f3
    lea rax, [f1]
    call rax
    mov [buf], rax
    call [buf]
    lea r11, [f3]
    call r11
    lea rax, [.j1]
    jmp rax
    inc r10
.j1:
    lea rcx, [.j2]
    mov [buf + 8], rcx
    jmp [buf + 8]
    inc r10
.j2:
    jmp short .j3
    inc r10
.j3:
    jmp near .j4
    inc r10
.j4:
    mov ecx, 3
.l1:
    inc r12
    loop .l1
    mov rcx, 5
    xor eax, eax
.l2:
    inc eax
    cmp eax, 3
    loopne .l2
    mov rcx, 5
.l3:
    cmp rcx, rcx
    loope .l3
    mov rcx, 4
.l4:
    cmp rcx, 2
    loope .l4
    xor ecx, ecx
    jrcxz .l5
    inc r13
.l5:
    mov rcx, 0x100000000
    jrcxz .l6
    inc r13
.l6:
    jecxz .l7
    inc r14
.l7:
    mov rcx, 0xFFFFFFFF00000002
.l8:
    inc r15
    a32 loop .l8
    EXIT
    align 16
buf: times 64 dq 0x0123456789ABCDEF
file_end:
