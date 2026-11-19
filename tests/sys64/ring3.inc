; Privilege level 3 for the system tests that only visit it (E096): USER label goes to the
; label at level 3 (USER label, flags with flags other than 2); the code there ends with LEAVE_USER, which comes back to the line after
; USER at level 0. `call ring3_init` once first: it gives the TSS a stack for handlers.
; (y_user, which is about level 3, has its own way with SYSCALL.)

USER_STACK equ 0x1D0000
KERNEL_STACK equ 0x1B0000
TSS_AT equ 0x2345000

; The hook that brings level 3 back: the frame is rewritten to return to level 0 at k_cont.
to_kernel:
    push rbx
    mov rbx, [f_frame]
    mov rax, [k_cont]
    mov [rbx], rax
    mov qword [rbx + 8], 0x08
    mov qword [rbx + 16], 2
    mov rax, [k_rsp]
    mov [rbx + 24], rax
    mov qword [rbx + 32], 0x10
    mov qword [f_hook], 0
    pop rbx
    ret

; Goes to label at level 3, with the flags given (2 if none). The code there ends with
; LEAVE_USER, which comes back after USER.
%macro USER 1-2 2
    lea rax, [%%back]
    mov [k_cont], rax
    lea rax, [rsp]
    mov [k_rsp], rax
    push 0x1B
    push USER_STACK
    push %2
    push 0x23
    lea rax, [%1]
    push rax
    iretq
%%back:
%endmacro

%macro LEAVE_USER 0
    lea rax, [to_kernel]
    mov [f_hook], rax
    int3
%endmacro

ring3_init:
    push rax
    mov rax, TSS_AT
    mov qword [rax + 4], KERNEL_STACK
    mov word [rax + 0x66], 0x68
    mov [gdt + 0x28 + 2], ax
    shr rax, 16
    mov [gdt + 0x28 + 4], al
    mov byte [gdt + 0x28 + 5], 0x89
    mov [gdt + 0x28 + 7], ah
    mov word [gdt + 0x28], 0x67
    mov eax, 0x28
    ltr ax
    pop rax
    ret

align 8
k_cont: dq 0
k_rsp: dq 0
