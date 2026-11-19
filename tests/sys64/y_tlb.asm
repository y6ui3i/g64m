; What a program can see of a TLB (E096): not what one keeps, which a CPU is free in, but
; what one may not do. Each part first uses a page in one way, so that a TLB has it, and
; then in a way the first use must not stand for.
%include "sys.inc"
    jmp test
%include "idt.inc"
%include "pt.inc"

V equ 0x40000000
P equ 0x400000
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

; Goes to label at level 3. The code there ends with INT3, which comes back after USER.
%macro USER 1
    lea rax, [%%back]
    mov [k_cont], rax
    lea rax, [rsp]
    mov [k_rsp], rax
    push 0x1B
    push USER_STACK
    push 2
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

; Code for a page: MOV EAX, n and RET.
%macro CODE_AT 2
    mov rax, %1
    mov byte [rax], 0xB8
    mov dword [rax + 1], %2
    mov byte [rax + 5], 0xC3
%endmacro

test:
    call idt_init
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
    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x800
    wrmsr

    PUTS "a write after a read sets the dirty bit"
    MAP V, P, 3
    mov rbx, V
    mov rax, [rbx]
    SHOW_ENTRY V, 12
    mov qword [rbx], 0x1111
    SHOW_ENTRY V, 12

    PUTS "level 3 after level 0, on a page that is level 0's"
    mov rax, [rbx]
    mov [rbx], rax
    USER .u1
    SHOW_FAULT
    PRINT [f_cr2]
    jmp .k1
.u1:
    lea rax, [.u1b]
    mov [f_resume], rax
    mov rbx, V
    mov rax, [rbx]
.u1b:
    LEAVE_USER
.k1:
    USER .u2
    PRINT [f_err]
    jmp .k2
.u2:
    lea rax, [.u2b]
    mov [f_resume], rax
    mov rbx, V
    mov [rbx], rax
.u2b:
    LEAVE_USER

.k2:
    PUTS "level 3 writing after level 3 read, on a page it may only read"
    MAP V + 0x1000, P + 0x1000, 5
    USER .u3
    PRINT r8
    PRINT [f_err]
    SHOW_ENTRY V + 0x1000, 12
    jmp .k3
.u3:
    mov rbx, V + 0x1000
    mov r8, [rbx]
    lea rax, [.u3b]
    mov [f_resume], rax
    mov [rbx], rax
.u3b:
    LEAVE_USER

.k3:
    PUTS "level 3 reading the table the CPU has just read for it"
    ; The IDT's 2 MB are level 0's. A fault from level 3 has the CPU read the IDT, as
    ; itself; level 3 reading the same address afterwards is still refused.
    and qword [pd + 1 * 8], ~4
    mov rax, cr3
    mov cr3, rax
    USER .u4
    PRINT [f_vec]
    PRINT [f_err]
    PRINT [f_cr2]
    or qword [pd + 1 * 8], 4
    mov rax, cr3
    mov cr3, rax
    jmp .k4
.u4:
    lea rax, [.u4a]
    mov [f_resume], rax
    ud2
.u4a:
    lea rax, [.u4b]
    mov [f_resume], rax
    mov rax, [abs IDT_AT + 6 * 16]
.u4b:
    LEAVE_USER

.k4:
    PUTS "executing after reading, on a page that may not be executed"
    MAP V + 0x2000, P + 0x2000, 3
    CODE_AT V + 0x2000, 0x77
    mov rdi, V + 0x2000
    mov ecx, 12
    call entry
    bts qword [rax], 63
    mov rbx, V + 0x2000
    invlpg [rbx]
    PRINT [rbx]
    mov qword [rbx + 8], 0x2222
    mov qword [f_resume], .x1
    call rbx
.x1:
    SHOW_FAULT
    add rsp, 8
    PUTS "and reading after executing, when it is taken away"
    MAP V + 0x3000, P + 0x3000, 3
    CODE_AT V + 0x3000, 0x88
    mov rbx, V + 0x3000
    call rbx
    PRINT rax
    mov rdi, V + 0x3000
    mov ecx, 12
    call entry
    bts qword [rax], 63
    invlpg [rbx]
    mov qword [f_resume], .x2
    call rbx
.x2:
    PRINT [f_err]
    add rsp, 8
    PRINT [rbx]

    PUTS "CR0.WP turned on after a write that it would have refused"
    MAP V + 0x4000, P + 0x4000, 1
    mov rbx, V + 0x4000
    mov qword [rbx], 0x3333
    mov rax, cr0
    or eax, 0x10000
    mov cr0, rax
    mov qword [f_resume], .w1
    mov qword [rbx], 0x4444
.w1:
    PRINT [f_err]
    PRINT [rbx]
    mov rax, cr0
    and eax, ~0x10000
    mov cr0, rax
    mov qword [rbx], 0x5555
    PRINT [rbx]

    PUTS "EFER.NXE turned off after a read through an entry with bit 63"
    mov rbx, V + 0x2000
    PRINT [rbx]
    mov ecx, 0xC0000080
    rdmsr
    and eax, ~0x800
    wrmsr
    mov qword [f_resume], .n1
    mov rax, [rbx]
.n1:
    PRINT [f_err]
    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x800
    wrmsr
    PRINT [rbx]

    PUTS "one page invalidated: read, written and executed through the new entry"
    MAP V + 0x5000, P + 0x5000, 3
    CODE_AT V + 0x5000, 1
    CODE_AT P + 0x6000, 2
    mov rbx, V + 0x5000
    call rbx
    PRINT rax
    PRINT [rbx]
    mov byte [rbx + 16], 0xAA
    MAP V + 0x5000, P + 0x6000, 3
    invlpg [rbx]
    PRINT [rbx]
    mov byte [rbx + 16], 0xBB
    call rbx
    PRINT rax
    PRINT [abs P + 0x5010]
    PRINT [abs P + 0x6010]
    PUTS "and by a write of CR3"
    MAP V + 0x5000, P + 0x5000, 3
    mov rax, cr3
    mov cr3, rax
    PRINT [rbx]
    mov byte [rbx + 16], 0xCC
    call rbx
    PRINT rax
    PRINT [abs P + 0x5010]

    PUTS "two pages that a table would put in one place"
    MAP V + 0x8000, P + 0x8000, 3
    MAP V + 0x1008000, P + 0x9000, 3
    MAP V + 0x10008000, P + 0xA000, 3
    mov rbx, V + 0x8000
    mov r12, V + 0x1008000
    mov r13, V + 0x10008000
    mov qword [rbx], 0xA1
    mov qword [r12], 0xB2
    mov qword [r13], 0xC3
    mov rax, [rbx]
    add rax, [r12]
    add rax, [r13]
    add rax, [rbx]
    PRINT rax
    ; Invalidating one of them leaves the others.
    MAP V + 0x1008000, P + 0x8000, 3
    invlpg [r12]
    PRINT [r12]
    PRINT [rbx]
    PRINT [r13]

    PUTS "a page of 2 MB invalidated by any address in it"
    mov rdi, V + 0x400000
    mov ecx, 21
    call entry
    mov r12, rax
    mov qword [r12], 0x800000 + 0x83
    mov rbx, V + 0x400000
    mov qword [rbx + 0x1000], 0x61
    mov qword [rbx + 0x155008], 0x62
    mov qword [abs 0xA00000 + 0x1000], 0x71
    mov qword [abs 0xA00000 + 0x155008], 0x72
    mov rax, [rbx + 0x1000]
    add rax, [rbx + 0x155008]
    PRINT rax
    mov qword [r12], 0xA00000 + 0x83
    invlpg [rbx + 0x1000]
    PRINT [rbx + 0x155008]
    PRINT [rbx + 0x1000]
    PRINT [f_count]
    EXIT

align 8
k_cont: dq 0
k_rsp: dq 0
file_end:
