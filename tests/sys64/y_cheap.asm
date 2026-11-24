; Five instructions a block does itself since E176, each in a loop that goes round often
; enough to be translated: CLD and STD (seen by which way MOVSB then goes), CLI (seen in
; what PUSHFQ pushes), LEAVE, LFENCE, and SWAPGS (seen in the two bases read back). What
; RDTSC gives is the emulator's own count and no CPU's: it is held to the interpreter by
; the boot's count of instructions with the JIT and without (tools/systest64.sh). Last, a
; routine with CLI in it called at level 0 until it is a block, then at level 3, where CLI
; faults: the block made at level 0 is not level 3's (E178 owed this test).
%include "sys.inc"
    jmp test
%include "idt.inc"
%include "ring3.inc"

ROUNDS equ 24

    align 4096
; A frame made and left: what it returns is its argument and a local.
framed:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp - 8], rdi
    mov rax, [rbp - 8]
    add rax, rsp
    sub rax, rbp
    leave
    ret

; A routine of its own page, so that the call to it leaves the caller's page: CLI in it.
    align 4096
cli_r:
    cli
    mov eax, 5
    ret

    align 4096
test:
    call idt_init
    call ring3_init

    PUTS "CLD and STD"
    xor r12, r12
    mov r14d, ROUNDS
.dir:
    lea rsi, [src + 4]
    lea rdi, [dst + 4]
    std
    movsb
    movsb
    add r12, rsi
    sub r12, rdi
    lea rsi, [src]
    lea rdi, [dst + 8]
    cld
    movsb
    movsb
    add r12, rdi
    sub r12, rsi
    sub r14d, 1
    jnz .dir
    PRINT r12
    PRINT [dst]
    PRINT [dst + 8]

    PUTS "CLI"
    xor r12, r12
    mov r14d, ROUNDS
.cli:
    sti
    nop
    pushfq
    pop rax
    and eax, 0x200
    add r12, rax
    cli
    lfence
    pushfq
    pop rax
    and eax, 0x200
    shl rax, 8
    add r12, rax
    sub r14d, 1
    jnz .cli
    PRINT r12

    PUTS "LEAVE"
    xor r12, r12
    mov r14d, ROUNDS
.leave:
    mov rdi, r14
    call framed
    add r12, rax
    add r12, rsp
    sub r12, rbp
    sub r14d, 1
    jnz .leave
    mov rax, STACK_TOP
    sub r12, rax
    PRINT r12

    PUTS "SWAPGS"
    mov ecx, 0xC0000101                         ; GS's base
    mov eax, 0x11110000
    mov edx, 0x1
    wrmsr
    mov ecx, 0xC0000102                         ; the one kept aside
    mov eax, 0x22220000
    mov edx, 0x2
    wrmsr
    xor r12, r12
    mov r14d, ROUNDS + 1                        ; an odd number of them
.swap:
    swapgs
    add r12, 3
    sub r14d, 1
    jnz .swap
    PRINT r12
    mov ecx, 0xC0000101
    rdmsr
    shl rdx, 32
    or rax, rdx
    PRINT rax
    mov ecx, 0xC0000102
    rdmsr
    shl rdx, 32
    or rax, rdx
    PRINT rax
    xor eax, eax
    xor edx, edx
    mov ecx, 0xC0000101
    wrmsr
    mov ecx, 0xC0000102
    wrmsr

    PUTS "a block with CLI made at level 0, called at level 3"
    xor r12, r12
    mov r14d, ROUNDS
.k:
    call cli_r
    add r12, rax
    sub r14d, 1
    jnz .k
    PRINT r12
    mov qword [f_count], 0
    USER .u
    PRINT [f_count]                             ; CLI faults there every time
    PRINT r12
    EXIT
.u:
    xor r12, r12
    mov r14d, ROUNDS
.ul:
    lea rax, [.u1]
    mov [f_resume], rax
    call cli_r
    add r12, rax                                ; (not reached)
.u1:
    mov rsp, USER_STACK                         ; (the call's return address is left behind)
    sub r14d, 1
    jnz .ul
    LEAVE_USER

; (On a page of its own: a page of code that is written to is not translated from.)
    align 4096
src: db 1, 2, 3, 4, 5, 6, 7, 8
dst: times 16 db 0
file_end:
