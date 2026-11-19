; Faults at privilege level 0: which vector, which error code, what is pushed and where,
; and coming back with IRETQ.
%include "sys.inc"
    jmp test
%include "idt.inc"

test:
    call idt_init
    ; Nothing from outside: both interrupt controllers masked.
    mov al, 0xFF
    out 0x21, al
    out 0xA1, al

    PUTS "divide by zero"
    mov qword [f_resume], .a1
    mov eax, 5
    xor ecx, ecx
    div ecx
.a1:
    SHOW_FAULT
    PUTS "quotient too large"
    mov qword [f_resume], .a2
    mov edx, 7
    mov ecx, 3
    div ecx
.a2:
    SHOW_FAULT
    PUTS "undefined"
    mov qword [f_resume], .a3
    ud2
.a3:
    SHOW_FAULT
    PUTS "int3"
    int3
    SHOW_FAULT
    PRINT [f_inside]
    PUTS "int 80h with IF set"
    sti
    int 0x80
    cli
    SHOW_FAULT
    PRINT [f_inside]
    PUTS "int3 with IF set"
    sti
    int3
    cli
    PRINT [f_flags]
    PRINT [f_inside]
    PUTS "a gate not present"
    mov qword [f_resume], .a4
    int 0x30
.a4:
    SHOW_FAULT
    PUTS "a vector past the table"
    ; What lies past the table's end looks like a good gate, and is not one.
    mov rax, [abs IDT_AT + 3 * 16]
    mov [abs IDT_AT + 0x90 * 16], rax
    mov rax, [abs IDT_AT + 3 * 16 + 8]
    mov [abs IDT_AT + 0x90 * 16 + 8], rax
    mov qword [f_resume], .a5
    int 0x90
.a5:
    SHOW_FAULT
    PUTS "an address that is not canonical"
    mov qword [f_resume], .a6
    mov rbx, 0x0000800000000000
    mov rax, [rbx]
.a6:
    SHOW_FAULT
    mov qword [f_resume], .a7
    mov rbx, 0xFFFF7FFFFFFFFFF8
    mov [rbx], rax
.a7:
    SHOW_FAULT
    PUTS "an MSR that is not there"
    mov qword [f_resume], .a8
    mov ecx, 0xC0000099
    rdmsr
.a8:
    SHOW_FAULT
    PUTS "a reserved bit of EFER"
    mov qword [f_resume], .a9
    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x2
    wrmsr
.a9:
    SHOW_FAULT
    PUTS "a selector past the GDT"
    mov qword [f_resume], .a10
    mov eax, 0x100
    mov ds, eax
.a10:
    SHOW_FAULT
    PUTS "the stack is aligned for the handler"
    mov rbp, rsp
    sub rsp, 0x1C
    mov qword [f_resume], .a11
    ud2
.a11:
    PRINT [f_rsp]
    PRINT [f_frame]
    PRINT [f_ss]
    PRINT [f_cs]
    mov rsp, rbp
    PUTS "a fault that puts back what the instruction changed"
    ; POP to memory that is not there: RSP must be as before the POP.
    mov qword [f_resume], .a12
    mov rbx, 0x0000800000000000
    push 0x1234
    pop qword [rbx]
.a12:
    PRINT [f_vec]
    PRINT [f_rsp]
    add rsp, 8
    PUTS "a stack from the TSS for one gate"
    ; The TSS is put above 16 MB, so that every part of its address in the descriptor counts.
    mov rax, TSS_AT
    mov qword [rax + 4], 0x180000
    mov qword [rax + 0x24], 0x1A0000 + 8
    mov word [rax + 0x66], 0x68
    mov [gdt + 0x28 + 2], ax
    shr rax, 16
    mov [gdt + 0x28 + 4], al
    mov byte [gdt + 0x28 + 5], 0x89
    mov [gdt + 0x28 + 7], ah
    mov word [gdt + 0x28], 0x67
    mov eax, 0x28
    ltr ax
    str ebx
    PRINT rbx
    PRINT [gdt + 0x28]
    mov byte [abs IDT_AT + 6 * 16 + 4], 1
    mov qword [f_resume], .a13
    ud2
.a13:
    PRINT [f_rsp]
    PRINT [f_frame]
    mov byte [abs IDT_AT + 6 * 16 + 4], 0
    PUTS "RF from a fault's frame ends with the instruction come back to"
    ; The fault's handler sets TF in the flags it returns with, so that the instruction it
    ; returns to is followed by a single step: the flags pushed for that have no RF.
    mov qword [f_resume], .rf1
    mov qword [f_hook], rf_hook
    mov ebx, 5
    ud2
.rf1:
    mov eax, ebx
    mov qword [f_hook], 0
    PRINT [f_vec]
    PRINT [f_flags]
    PRINT rax
    PUTS "flags that privilege level 0 may change"
    push 0x3202
    popfq
    pushfq
    pop rax
    PRINT rax
    push 2
    popfq
    PUTS "IRETQ gives back IF and IOPL at privilege level 0"
    mov rax, rsp
    push 0x10
    push rax
    push 0x3202
    push 0x08
    lea rax, [.i1]
    push rax
    iretq
.i1:
    pushfq
    pop rax
    PRINT rax
    push 2
    popfq
    PUTS "VERR and VERW: could this selector's segment be read, or written, from here"
%macro VER 1
    mov eax, %1
    push 2
    popfq
    verr ax
    pushfq
    pop rbx
    push 2
    popfq
    verw ax
    pushfq
    pop rcx
    shl rbx, 16
    or rbx, rcx
    PRINT rbx
%endmacro
    VER 0x08
    VER 0x10
    VER 0x18
    VER 0x1B
    VER 0x20
    VER 0x28
    VER 0x00
    VER 0x100
    VER 0x13
    VER 0x30
    ; (A selector that names the LDT is not asked about: there is none, and the real CPU
    ; then reads whatever lies where one was last.)
    PUTS "the tables' registers"
    sgdt [scratch]
    PRINT [scratch]
    sidt [scratch]
    PRINT [scratch]
    mov eax, ds
    PRINT rax
    mov rbx, 0xFFFFFFFFFFFFFFFF
    mov bx, gs
    PRINT rbx
    mov rbx, 0xFFFFFFFFFFFFFFFF
    mov ebx, gs
    PRINT rbx
    mov qword [scratch], -1
    mov [scratch], cs
    PRINT [scratch]
    PRINT [f_count]
    EXIT

; Called from the handler: sets TF in the flags of a fault's frame, and takes it out of a
; single step's.
rf_hook:
    mov rax, [f_frame]
    cmp qword [f_vec], 1
    je .off
    or qword [rax + 16], 0x100
    ret
.off:
    and qword [rax + 16], ~0x100
    ret

align 16
scratch: dq 0, 0
TSS_AT equ 0x2345000
file_end:
