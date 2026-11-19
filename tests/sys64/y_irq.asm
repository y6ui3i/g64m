; Interrupts from outside (E097): the timer through the interrupt controller, and the serial
; port. What is printed does not depend on how long anything takes: how many came, in what
; order, with what vector, and what the CPU had done when one arrived.
%include "sys.inc"
    jmp test
%include "idt.inc"
%include "ring3.inc"

; The hook: counts timer interrupts (vector 20h), writes down what was being run, and tells
; the controller it is done unless told not to. The serial port's (24h) is answered by
; reading what it is about. Every vector goes into the order log.
irq_hook:
    push rbx
    push rdx
    mov rbx, [order_n]
    mov rax, [f_vec]
    lea rdx, [order]
    mov [rdx + rbx], al
    inc qword [order_n]
    cmp qword [f_vec], 0x20
    jne .serial
    inc qword [ticks]
    mov rax, [marker]
    mov [seen_marker], rax
    mov rax, [f_cs]
    mov [irq_cs], rax
    mov rax, [f_flags]
    mov [irq_flags], rax
    mov rax, [f_inside]
    mov [irq_inside], rax
    cmp qword [no_eoi], 0
    jne .out
    mov al, 0x20
    out 0x20, al
    jmp .out
.serial:
    cmp qword [f_vec], 0x24
    jne .out
    mov dx, 0x3FA
    in al, dx
    mov [serial_why], al
    mov dx, 0x3F9
    mov al, 0
    out dx, al
    mov al, 0x20
    out 0x20, al
.out:
    pop rdx
    pop rbx
    ret

; Waits, with whatever IF is, until the controller has the timer's request (line 0) waiting.
wait_request:
    push rax
    mov al, 0x0A
    out 0x20, al
.again:
    in al, 0x20
    test al, 1
    jz .again
    pop rax
    ret

; The timer's counter, in AX.
read_count:
    mov al, 0
    out 0x43, al
    in al, 0x40
    mov ah, al
    in al, 0x40
    xchg al, ah
    ret

; Waits until the timer's counter has started again from the top.
wait_wrap:
    push rax
    push rbx
    call read_count
    movzx ebx, ax
.again:
    call read_count
    movzx eax, ax
    cmp eax, ebx
    mov ebx, eax
    jbe .again
    pop rbx
    pop rax
    ret

test:
    call idt_init
    call ring3_init
    lea rax, [irq_hook]
    mov [f_hook], rax
    ; The controllers: lines 0 to 7 at vectors 20h to 27h, 8 to 15 at 28h to 2Fh; only the
    ; timer's line open.
    mov al, 0x11
    out 0x20, al
    out 0xA0, al
    mov al, 0x20
    out 0x21, al
    mov al, 0x28
    out 0xA1, al
    mov al, 4
    out 0x21, al
    mov al, 2
    out 0xA1, al
    mov al, 1
    out 0x21, al
    out 0xA1, al
    mov al, 0xFE
    out 0x21, al
    mov al, 0xFF
    out 0xA1, al
    ; The timer: channel 0, rate generator, a count of 11932 (a hundredth of a second).
    mov al, 0x34
    out 0x43, al
    mov al, 0x9C
    out 0x40, al
    mov al, 0x2E
    out 0x40, al

    PUTS "five ticks, asleep between them"
    sti
.sleep:
    hlt
    cmp qword [ticks], 5
    jb .sleep
    cli
    PRINT [ticks]
    PRINT [f_vec]
    PRINT [irq_cs]
    ; Of the flags pushed: IF was set, and RF is not (it is with a fault).
    mov rax, [irq_flags]
    and eax, 0x10200
    PRINT rax
    mov rax, [irq_inside]
    and eax, 0x200
    PRINT rax

    PUTS "one HLT ends with one interrupt"
    mov r12, [ticks]
    sti
    hlt
    cli
    mov rax, [ticks]
    sub rax, r12
    PRINT rax

    PUTS "STI straight after the timer is set again: still not before the instruction that follows"
    ; (The write to the timer is itself something the machine looks up after.)
    mov r12, [ticks]
    call wait_request
    mov qword [marker], 0
    mov al, 0x34
    out 0x43, al
    mov al, 0x9C
    out 0x40, al
    mov al, 0x2E
    out 0x40, al
    sti
    mov qword [marker], 1
    mov qword [marker], 2
    cli
    PRINT [seen_marker]

    PUTS "held while IF is clear, and taken after the instruction that follows STI"
    mov r12, [ticks]
    call wait_request
    mov rax, [ticks]
    sub rax, r12
    PRINT rax
    mov qword [marker], 0
    sti
    mov qword [marker], 1
    mov qword [marker], 2
    cli
    PRINT [seen_marker]
    mov rax, [ticks]
    sub rax, r12
    PRINT rax

    PUTS "nothing more until the controller is told the first is done"
    mov qword [no_eoi], 1
    mov r12, [ticks]
    sti
.one:
    hlt
    cmp [ticks], r12
    je .one
    ; Two more of the timer's periods go by, seen in its counter starting again.
    call wait_wrap
    call wait_wrap
    mov rax, [ticks]
    sub rax, r12
    PRINT rax
    mov qword [no_eoi], 0
    mov qword [marker], 7
    mov al, 0x20
    out 0x20, al
    ; Not asleep here: whether a request was kept while the first was in service is the
    ; controller's and the timer's business, and a HLT would wait one tick longer where
    ; one was.
.two:
    mov rax, [ticks]
    sub rax, r12
    cmp rax, 2
    jb .two
    cli
    PRINT rax

    PUTS "a line that is masked"
    mov al, 0xFF
    out 0x21, al
    mov r12, [ticks]
    sti
    call wait_request
    nop
    nop
    mov rax, [ticks]
    sub rax, r12
    PRINT rax
    mov al, 0xFE
    out 0x21, al
    nop
    nop
    cli
    mov rax, [ticks]
    sub rax, r12
    PRINT rax

    PUTS "at level 3"
    mov r12, [ticks]
    USER .u1, 0x202
    PRINT [irq_cs]
    mov rax, [ticks]
    sub rax, r12
    PRINT rax
    jmp .k1
.u1:
    ; IF came on with the flags IRETQ loaded; level 3 cannot set it.
    mov r8, [ticks]
.spin:
    cmp [ticks], r8
    je .spin
    LEAVE_USER
.k1:
    PUTS "two lines at once: the lower number first"
    cli
    ; (Coming back from level 3 took the hook away.)
    lea rax, [irq_hook]
    mov [f_hook], rax
    mov al, 0xEE
    out 0x21, al
    mov qword [order_n], 0
    call wait_request
    ; The serial port asks to be heard when it has room to send, which is now.
    mov dx, 0x3FC
    mov al, 0x08
    out dx, al
    mov dx, 0x3F9
    mov al, 0x02
    out dx, al
    mov al, 0x0A
    out 0x20, al
    in al, 0x20
    and eax, 0x11
    PRINT rax
    sti
    nop
    nop
    nop
    cli
    PRINT [order_n]
    movzx eax, byte [order]
    PRINT rax
    movzx eax, byte [order + 1]
    PRINT rax
    movzx eax, byte [serial_why]
    and eax, 0x0F
    PRINT rax
    EXIT

align 8
ticks: dq 0
marker: dq 0
seen_marker: dq 0
irq_cs: dq 0
irq_flags: dq 0
irq_inside: dq 0
no_eoi: dq 0
serial_why: dq 0
order_n: dq 0
order: times 64 db 0
file_end:
