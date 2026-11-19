; The x87 and SSE as a machine has them (E098): not there until the operating system says
; so, a trap when it has set the task-switched bit, and FXSAVE and FXRSTOR at privilege
; level 0.
%include "sys.inc"
    jmp test
%include "idt.inc"

test:
    call idt_init
    PUTS "SSE before CR4.OSFXSR"
    mov qword [f_resume], .a1
    movaps xmm0, xmm1
.a1:
    SHOW_FAULT
    mov rax, cr4
    or eax, 0x600
    mov cr4, rax
    mov rax, 0x4010000000000000
    movq xmm1, rax
    movaps xmm0, xmm1
    movq rbx, xmm0
    PRINT rbx

    PUTS "the x87 with CR0.TS set"
    fninit
    mov rax, cr0
    or eax, 8
    mov cr0, rax
    mov qword [f_resume], .b1
    fld1
.b1:
    SHOW_FAULT
    PUTS "SSE with it set"
    mov qword [f_resume], .b2
    addsd xmm0, xmm1
.b2:
    PRINT [f_vec]
    mov qword [f_resume], .b3
    fxsave [area]
.b3:
    PRINT [f_vec]
    PUTS "FWAIT traps only when CR0.MP is set too"
    mov r12, [f_count]
    fwait
    mov rax, [f_count]
    sub rax, r12
    PRINT rax
    mov rax, cr0
    or eax, 2
    mov cr0, rax
    mov qword [f_resume], .b4
    fwait
.b4:
    PRINT [f_vec]
    mov rax, [f_count]
    sub rax, r12
    PRINT rax
    PUTS "a fence does not"
    mfence
    mov rax, [f_count]
    sub rax, r12
    PRINT rax
    PUTS "after CLTS"
    clts
    mov rax, cr0
    PRINT rax
    fld1
    fldpi
    faddp st1, st0
    fstp tword [area]
    PRINT [area]
    movzx eax, word [area + 8]
    PRINT rax
    addsd xmm0, xmm1
    movq rbx, xmm0
    PRINT rbx

    PUTS "the x87 with CR0.EM set"
    mov rax, cr0
    or eax, 4
    mov cr0, rax
    mov qword [f_resume], .c1
    fld1
.c1:
    PRINT [f_vec]
    mov qword [f_resume], .c2
    addsd xmm0, xmm1
.c2:
    PRINT [f_vec]
    mov rax, cr0
    and eax, ~4
    mov cr0, rax

    PUTS "saved and brought back"
    fninit
    fldpi
    fld1
    mov rax, 0x1122334455667788
    movq xmm7, rax
    fxsave [area]
    fninit
    pxor xmm7, xmm7
    fxrstor [area]
    fstp tword [area + 512]
    PRINT [area + 512]
    fstp tword [area + 512]
    PRINT [area + 512]
    movq rbx, xmm7
    PRINT rbx
    movzx eax, word [area]
    PRINT rax
    mov eax, [area + 24]
    PRINT rax
    EXIT

align 16
area: times 80 dq 0
file_end:
