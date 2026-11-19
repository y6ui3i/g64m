; Faults for the system tests (E094): an IDT whose every gate goes to one handler, which
; writes down what it was given and returns.
;
;   call idt_init          once, before anything that may fault
;   mov qword [f_resume], label
;                          the next fault returns to label and not to where it came from
;   mov qword [f_hook], routine
;                          called from the handler (it may change RAX only), for a test
;                          that puts right what faulted and lets the instruction run again
;   SHOW_FAULT             prints the vector, the error code, the address, the flags and
;                          the stack pointer that were pushed
;
; Gates 3 and 80h may be called from privilege level 3; 80h is a trap gate (IF is left as it
; is), the rest are interrupt gates. Gates 20h to 2Fh are where the tests put the interrupt
; controllers' sixteen lines. Gate 30h is marked not present. The IDT has 82h gates.

IDT_AT equ 0x200000
IDT_GATES equ 0x82

%macro STUB 1
stub%1:
%if %1 == 8 || (%1 >= 10 && %1 <= 14) || %1 == 17
%else
    push 0
%endif
    push %1
    jmp f_common
%endmacro

%assign v 0
%rep 48
    STUB v
%assign v v + 1
%endrep
    STUB 48
    STUB 128

f_common:
    push rax
    mov rax, [rsp + 8]
    mov [f_vec], rax
    mov rax, [rsp + 16]
    mov [f_err], rax
    mov rax, [rsp + 24]
    mov [f_rip], rax
    mov rax, [rsp + 32]
    mov [f_cs], rax
    mov rax, [rsp + 40]
    mov [f_flags], rax
    mov rax, [rsp + 48]
    mov [f_rsp], rax
    mov rax, [rsp + 56]
    mov [f_ss], rax
    mov rax, cr2
    mov [f_cr2], rax
    lea rax, [rsp + 24]
    mov [f_frame], rax
    lea rax, [f_common]
    mov [f_where], rax
    pushfq
    pop rax
    mov [f_inside], rax
    inc qword [f_count]
    mov rax, [f_hook]
    test rax, rax
    jz .nohook
    call rax
.nohook:
    mov rax, [f_resume]
    test rax, rax
    jz .back
    mov [rsp + 24], rax
    mov qword [f_resume], 0
.back:
    pop rax
    add rsp, 16
    iretq

; Writes gate RCX of the IDT: handler RAX, type and privilege DL (8Eh, EEh, EFh ...).
set_gate:
    push rdi
    mov rdi, rcx
    shl rdi, 4
    add rdi, IDT_AT
    mov [rdi], ax
    mov word [rdi + 2], 0x08
    mov byte [rdi + 4], 0
    mov [rdi + 5], dl
    shr rax, 16
    mov [rdi + 6], ax
    shr rax, 16
    mov [rdi + 8], eax
    mov dword [rdi + 12], 0
    pop rdi
    ret

idt_init:
    push rax
    push rcx
    push rdx
    push rsi
    xor ecx, ecx
    lea rsi, [stub0]
.all:
    ; Until a gate is given a stub of its own, every one goes to vector 31's.
    lea rax, [stub31]
    mov dl, 0x8E
    call set_gate
    inc ecx
    cmp ecx, IDT_GATES
    jb .all
%assign v 0
%rep 48
    mov ecx, v
    lea rax, [stub %+ v]
    mov dl, 0x8E
    call set_gate
%assign v v + 1
%endrep
    mov ecx, 3
    lea rax, [stub3]
    mov dl, 0xEE
    call set_gate
    mov ecx, 0x30
    lea rax, [stub48]
    mov dl, 0x0E
    call set_gate
    mov ecx, 0x80
    lea rax, [stub128]
    mov dl, 0xEF
    call set_gate
    lidt [idt_ptr]
    pop rsi
    pop rdx
    pop rcx
    pop rax
    ret

%macro SHOW_FAULT 0
    PRINT [f_vec]
    PRINT [f_err]
    PRINT [f_rip]
    PRINT [f_flags]
    PRINT [f_rsp]
%endmacro

align 8
idt_ptr:
    dw IDT_GATES * 16 - 1
    dq IDT_AT
align 8
f_vec: dq 0
f_err: dq 0
f_rip: dq 0
f_cs: dq 0
f_flags: dq 0
f_rsp: dq 0
f_ss: dq 0
f_cr2: dq 0
f_frame: dq 0
f_where: dq 0
f_inside: dq 0
f_count: dq 0
f_hook: dq 0
f_resume: dq 0
