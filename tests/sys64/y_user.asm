; Privilege level 3: getting there by IRETQ and by SYSRET, coming back by SYSCALL, by INT
; and by a fault, and what level 3 may not do.
;
; USER label, flags goes to label at level 3 with those flags; the code there ends with
; SYSCALL, which comes back to the line after USER at level 0 on the stack it left. A fault
; is written to a log by the handler's hook, and the log is printed at level 0.
%include "sys.inc"
    jmp test
%include "idt.inc"
%include "pt.inc"

USER_STACK equ 0x1D0000
KERNEL_STACK equ 0x1B0000
TSS_AT equ 0x2345000
V equ 0x40000000
P equ 0x400000

%macro USER 2
    lea rax, [%%back]
    mov [k_cont], rax
    mov [k_rsp], rsp
    push 0x1B
    push USER_STACK
    push %2
    push 0x23
    lea rax, [%1]
    push rax
    iretq
%%back:
%endmacro

; Where SYSCALL arrives: at level 0, still on the caller's stack.
sys_entry:
    mov [u_rcx], rcx
    mov [u_r11], r11
    mov [u_rsp], rsp
    pushfq
    pop rcx
    mov [u_inside], rcx
    mov ecx, cs
    mov [u_cs], rcx
    mov ecx, ss
    mov [u_ss], rcx
    mov rsp, [k_rsp]
    jmp [k_cont]

; The handler's hook: one line of the log for each fault.
log_fault:
    push rbx
    mov rbx, [log_n]
    shl rbx, 6
    lea rax, [log]
    add rbx, rax
    mov rax, [f_vec]
    mov [rbx], rax
    mov rax, [f_err]
    mov [rbx + 8], rax
    mov rax, [f_cs]
    mov [rbx + 16], rax
    mov rax, [f_ss]
    mov [rbx + 24], rax
    mov rax, [f_rsp]
    mov [rbx + 32], rax
    mov rax, [f_frame]
    mov [rbx + 40], rax
    mov rax, [f_flags]
    mov [rbx + 48], rax
    ; The last number is CR2 for a page fault and the address pushed for anything else.
    mov rax, [f_rip]
    cmp qword [f_vec], 14
    jne .put
    mov rax, [f_cr2]
.put:
    mov [rbx + 56], rax
    inc qword [log_n]
    mov eax, ss
    mov [h_ss], rax
    ; A single step: the one that brings tf_left to zero takes TF out of the flags it
    ; returns with.
    cmp qword [f_vec], 1
    jne .out
    dec qword [tf_left]
    jnz .out
    mov rax, [f_frame]
    and qword [rax + 16], ~0x100
.out:
    pop rbx
    ret

; Prints the log, eight numbers to a fault, and empties it.
print_log:
    push rax
    push rbx
    push rcx
    PRINT [log_n]
    mov rcx, [log_n]
    shl rcx, 3
    lea rbx, [log]
.next:
    test rcx, rcx
    jz .done
    PRINT [rbx]
    add rbx, 8
    dec rcx
    jmp .next
.done:
    mov qword [log_n], 0
    pop rcx
    pop rbx
    pop rax
    ret

; At level 3: the next fault goes on at the label.
%macro RESUME 1
    lea rax, [%1]
    mov [f_resume], rax
%endmacro

test:
    call idt_init
    mov al, 0xFF
    out 0x21, al
    out 0xA1, al
    lea rax, [log_fault]
    mov [f_hook], rax
    ; A TSS: the stack for handlers of faults that come from level 3, and one for gate 6.
    mov rax, TSS_AT
    mov qword [rax + 4], KERNEL_STACK
    mov qword [rax + 0x24], 0x1A0000
    mov word [rax + 0x66], 0x68
    mov [gdt + 0x28 + 2], ax
    shr rax, 16
    mov [gdt + 0x28 + 4], al
    mov byte [gdt + 0x28 + 5], 0x89
    mov [gdt + 0x28 + 7], ah
    mov word [gdt + 0x28], 0x67
    mov eax, 0x28
    ltr ax

    PUTS "SYSCALL before EFER allows it"
    mov qword [f_resume], .s0
    syscall
.s0:
    call print_log
    ; SYSCALL goes to code 08h and stack 10h; SYSRET to code 20h+3 and stack 18h+3.
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1
    wrmsr
    mov ecx, 0xC0000081
    xor eax, eax
    mov edx, 0x00100008
    wrmsr
    mov ecx, 0xC0000082
    lea rax, [sys_entry]
    mov rdx, rax
    shr rdx, 32
    wrmsr
    mov ecx, 0xC0000084
    mov eax, 0x700
    xor edx, edx
    wrmsr
    mov ecx, 0xC0000081
    rdmsr
    PRINT rdx

    PUTS "to level 3 by IRETQ, back by SYSCALL"
    mov ecx, 0xC0000100
    mov eax, 0x12345000
    xor edx, edx
    wrmsr
    ; ES is given a selector that level 3 may use: it is left alone, where the others,
    ; which are level 0's, are made null.
    mov eax, 0x1B
    mov es, eax
    USER .u1, 0x0C96
    mov eax, 0x10
    mov es, eax
    PRINT r8
    PRINT r9
    PRINT r10
    PRINT r12
    PRINT r13
    PRINT r14
    PRINT r15
    PRINT [u_rcx]
    PRINT [u_r11]
    PRINT [u_rsp]
    PRINT [u_inside]
    PRINT [u_cs]
    PRINT [u_ss]
    mov ecx, 0xC0000100
    rdmsr
    PRINT rax
    mov eax, ds
    PRINT rax
    push 2
    popfq
    jmp .k2
.u1:
    mov r8d, cs
    mov r9d, ss
    mov r10d, ds
    mov r12d, es
    mov r13d, fs
    mov r14d, gs
    pushfq
    pop r15
    std
    syscall

.k2:
    PUTS "to level 3 by SYSRET"
    lea rax, [.k3]
    mov [k_cont], rax
    mov [k_rsp], rsp
    lea rcx, [.u2]
    mov r11, 0x3F7ED7
    mov rbp, rsp
    mov rsp, USER_STACK
    o64 sysret
.u2:
    mov r8d, cs
    mov r9d, ss
    pushfq
    pop r15
    mov r10, rsp
    syscall
.k3:
    PRINT r8
    PRINT r9
    PRINT r15
    PRINT r10
    PRINT [u_inside]
    push 2
    popfq
    PUTS "SYSRET to an address that is not canonical"
    mov qword [f_resume], .k4
    mov rcx, 0x0000800000000000
    mov r11, 2
    o64 sysret
.k4:
    call print_log
    mov eax, cs
    PRINT rax

    PUTS "what level 3 may not do"
    USER .u3, 2
    call print_log
    jmp .k5
.u3:
    RESUME .p1
    hlt
.p1:
    RESUME .p2
    cli
.p2:
    RESUME .p3
    sti
.p3:
    RESUME .p4
    mov rax, cr0
.p4:
    RESUME .p5
    mov cr3, rax
.p5:
    RESUME .p6
    mov ecx, 0xC0000080
    rdmsr
.p6:
    RESUME .p7
    wrmsr
.p7:
    RESUME .p8
    lgdt [scratch]
.p8:
    RESUME .p9
    lidt [scratch]
.p9:
    RESUME .p10
    mov eax, 0x28
    ltr ax
.p10:
    RESUME .p11
    in al, 0x80
.p11:
    RESUME .p12
    out 0x80, al
.p12:
    RESUME .p13
    invlpg [scratch]
.p13:
    RESUME .p14
    swapgs
.p14:
    RESUME .p15
    o64 sysret
.p15:
    RESUME .p16
    clts
.p16:
    ; A frame for IRETQ that asks for level 0.
    RESUME .p17
    mov rax, rsp
    push 0x10
    push rax
    push 2
    push 0x08
    push rax
    iretq
.p17:
    mov rsp, USER_STACK
    ; What it may do, and what it is given without a fault.
    sgdt [scratch]
    sidt [scratch]
    str eax
    mov r8, rax
    smsw r9
    ; POPF cannot turn IF on or change IOPL, and says nothing.
    push 0x3202
    popfq
    pushfq
    pop r10
    ; Nor can IRETQ.
    mov rax, rsp
    push 0x1B
    push rax
    push 0x3202
    push 0x23
    lea rax, [.p18]
    push rax
    iretq
.p18:
    pushfq
    pop r12
    syscall

.k5:
    PRINT r8
    PRINT r9
    PRINT r10
    PRINT r12
    PUTS "with IOPL 3"
    USER .u4, 0x3002
    call print_log
    PRINT r8
    PRINT r9
    push 2
    popfq
    jmp .k6
.u4:
    sti
    pushfq
    pop r8
    cli
    in al, 0x80
    out 0x80, al
    RESUME .q1
    hlt
.q1:
    push 0x0202
    popfq
    pushfq
    pop r9
    syscall

.k6:
    PUTS "INT from level 3"
    ; From here on the IDT and the TSS are in pages that level 3 may not use: the CPU
    ; reads them as itself.
    and qword [pd + 1 * 8], ~4
    and qword [pd + 17 * 8], ~4
    mov rax, cr3
    mov cr3, rax
    USER .u5, 2
    call print_log
    PRINT [f_inside]
    PRINT [h_ss]
    jmp .k7
.u5:
    int 0x80
    int3
    RESUME .i1
    int 0x21
.i1:
    sub rsp, 0x24
    int 0x80
    add rsp, 0x24
    syscall

.k7:
    PUTS "pages that level 3 may not use"
    MAP V, P, 3
    MAP V + 0x1000, P + 0x1000, 5
    MAP V + 0x2000, P + 0x2000, 7
    mov rbx, V
    mov qword [rbx], 0x1111
    USER .u6, 2
    call print_log
    PRINT r8
    PRINT [abs P + 0x2000]
    jmp .k8
.u6:
    RESUME .g1
    mov rbx, V
    mov rax, [rbx]
.g1:
    RESUME .g2
    mov [rbx], rax
.g2:
    RESUME .g3
    mov rax, [rbx + 0x1000]
    mov [rbx + 0x1000], rax
.g3:
    RESUME .g4
    mov rax, [rbx + 0x5000]
.g4:
    RESUME .g5
    call rbx
.g5:
    mov rsp, USER_STACK
    mov qword [rbx + 0x2000], 0x2222
    mov r8, [rbx + 0x2000]
    ; An address that is not canonical, from level 3.
    RESUME .g6
    mov rcx, 0x0000800000000000
    mov rax, [rcx]
.g6:
    RESUME .g7
    ud2
.g7:
    RESUME .g8
    xor ecx, ecx
    div ecx
.g8:
    syscall

.k8:
    PUTS "a stack of its own for one gate, from level 3"
    mov byte [abs IDT_AT + 6 * 16 + 4], 1
    USER .u7, 2
    call print_log
    mov byte [abs IDT_AT + 6 * 16 + 4], 0
    jmp .k9
.u7:
    RESUME .t1
    ud2
.t1:
    syscall

.k9:
    PUTS "single steps: TF set by POPF at level 0"
    mov qword [tf_left], 3
    push 0x102
    popfq
    nop
    nop
    nop
    nop
    call print_log
    PUTS "by IRETQ, at level 3, until SYSCALL takes it away"
    mov qword [tf_left], 100
    USER .ut, 0x102
    call print_log
    PRINT [u_r11]
    PRINT [u_inside]
    push 2
    popfq
    mov rax, dr6
    PRINT rax
    jmp .k10
.ut:
    nop
    mov eax, 1
    syscall

.k10:
    PUTS "by SYSRET, and a POPF that takes TF away"
    mov qword [tf_left], 100
    lea rax, [.k11]
    mov [k_cont], rax
    mov [k_rsp], rsp
    lea rcx, [.us]
    mov r11, 0x102
    mov rsp, USER_STACK
    o64 sysret
.us:
    nop
    push 2
    popfq
    nop
    syscall
.k11:
    call print_log
    push 2
    popfq

    PUTS "TF set by POPF straight after STI, and straight after SYSRET"
    ; The first single step is after the instruction that follows the POPF, whatever came
    ; just before the POPF.
    mov qword [tf_left], 2
    push 0x102
    sti
    popfq
    nop
    nop
    nop
    call print_log
    mov qword [tf_left], 2
    lea rax, [.k12]
    mov [k_cont], rax
    mov [k_rsp], rsp
    lea rcx, [.ur]
    mov r11, 2
    mov rsp, USER_STACK
    o64 sysret
.ur:
    push 0x102
    popfq
    nop
    nop
    nop
    syscall
.k12:
    call print_log
    push 2
    popfq

    PUTS "SWAPGS, and FS and GS at level 3"
    mov ecx, 0xC0000101
    lea rax, [gs_here]
    xor edx, edx
    wrmsr
    mov ecx, 0xC0000102
    lea rax, [gs_there]
    wrmsr
    mov ecx, 0xC0000100
    lea rax, [fs_here]
    wrmsr
    PRINT [gs:0]
    swapgs
    PRINT [gs:0]
    mov ecx, 0xC0000101
    rdmsr
    PRINT rax
    mov ecx, 0xC0000102
    rdmsr
    PRINT rax
    USER .u8, 2
    PRINT r8
    PRINT r9
    PRINT r10
    mov ecx, 0xC0000100
    rdmsr
    PRINT rax
    mov ecx, 0xC0000101
    rdmsr
    PRINT rax
    PRINT [f_count]
    EXIT
.u8:
    mov r8, [gs:0]
    mov r9, [fs:8]
    ; Loading a null selector at level 3.
    xor eax, eax
    mov fs, eax
    mov r10d, fs
    syscall

align 16
scratch: dq 0, 0
gs_here: dq 0x1111111111111111, 0
gs_there: dq 0x2222222222222222, 0
fs_here: dq 0x3333333333333333, 0x4444444444444444
k_cont: dq 0
k_rsp: dq 0
u_rcx: dq 0
u_r11: dq 0
u_rsp: dq 0
u_inside: dq 0
u_cs: dq 0
u_ss: dq 0
log_n: dq 0
tf_left: dq 0
h_ss: dq 0
log: times 8 * 40 dq 0
file_end:
