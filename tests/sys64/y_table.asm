; The table of where blocks are (E165): a jump, call or return that leaves its page asks a
; table by the address jumped to, and the table must not answer with a block the address
; no longer means. Each part calls a short routine often enough for it and its caller to
; be translated and the table to hold both, then changes what the address means and calls
; again: the address made another page and the TLB told by INVLPG, and by CR3 written;
; the page's code written through another address; two addresses that choose the same
; place in the table, in turn; a 2 MB page changed, and INVLPG given another address in
; it (E168); a block made at privilege level 0, asked for at level 3.
%include "sys.inc"
    jmp test
%include "idt.inc"
%include "pt.inc"
%include "ring3.inc"

V equ 0x40000000
P equ 0x400000
ROUNDS equ 24

; (On a page of its own: the page before is written to at every fault, idt.inc.)
    align 4096
; Calls the routine at V ROUNDS times and adds what it leaves in EAX to R12.
run:
    mov r14d, ROUNDS
.l:
    call V
    add r12, rax
    sub r14d, 1
    jnz .l
    ret

test:
    call idt_init
    call ring3_init
    ; Two pages of code, and each seen at an address of its own to be written by.
    MAP V + 0x100000, P, 3
    MAP V + 0x101000, P + 0x1000, 3
    mov rax, V + 0x100000
    mov dword [rax], 0x000001B8                 ; MOV EAX, 1
    mov word [rax + 4], 0xC300                  ; RET
    mov rax, V + 0x101000
    mov dword [rax], 0x000100B8                 ; MOV EAX, 100h
    mov word [rax + 4], 0xC300

    PUTS "an address made another page, the TLB told by INVLPG"
    MAP V, P, 3
    xor r12, r12
    call run
    MAP V, P + 0x1000, 3
    mov rax, V
    invlpg [rax]
    call run
    PRINT r12

    PUTS "and back, by CR3 written"
    MAP V, P, 3
    mov rax, cr3
    mov cr3, rax
    xor r12, r12
    call run
    MAP V, P + 0x1000, 3
    mov rax, cr3
    mov cr3, rax
    call run
    PRINT r12

    PUTS "the page's code written through another address"
    MAP V, P, 3
    mov rax, cr3
    mov cr3, rax
    xor r12, r12
    call run
    mov rax, V + 0x100000
    mov dword [rax], 0x010000B8                 ; MOV EAX, 10000h
    call run
    PRINT r12

    PUTS "two addresses that choose the same place in the table"
    MAP V + 0x10000, P, 3
    MAP V + 0x20000, P + 0x1000, 3
    xor r12, r12
    mov r13d, ROUNDS
.two:
    call V + 0x10000
    add r12, rax
    call V + 0x20000
    add r12, rax
    sub r13d, 1
    jnz .two
    PRINT r12

    PUTS "a 2 MB page made another, INVLPG given an address elsewhere in it"
    mov rax, 0x805000                           ; (memory's first gigabyte is mapped to itself)
    mov dword [rax], 0x000001B8                 ; MOV EAX, 1
    mov word [rax + 4], 0xC300                  ; RET
    mov rax, 0xA05000
    mov dword [rax], 0x000100B8                 ; MOV EAX, 100h
    mov word [rax + 4], 0xC300
    mov rdi, V + 0x200000
    mov ecx, 21
    call entry
    mov r15, rax                                ; the entry for the 2 MB at V + 200000h
    mov qword [r15], 0x800000 + 0x83
    xor r12, r12
    mov r14d, ROUNDS
.big1:
    call V + 0x205000
    add r12, rax
    sub r14d, 1
    jnz .big1
    mov qword [r15], 0xA00000 + 0x83
    mov rax, V + 0x200000
    invlpg [rax]
    mov r14d, ROUNDS
.big2:
    call V + 0x205000
    add r12, rax
    sub r14d, 1
    jnz .big2
    PRINT r12

    PUTS "a block made at level 0, asked for at level 3"
    MAP V + 0xD000, P + 0xD000, 7               ; code for both levels
    MAP V + 0xE000, P + 0xE000, 3               ; data that is level 0's
    mov rax, V + 0xD000
    mov dword [rax], 0x48038B48                 ; MOV RAX, [RBX]
    mov dword [rax + 4], 0xC301C083             ; ADD RAX, 1 and RET
    mov rbx, V + 0xE000
    mov qword [rbx], 5
    xor r12, r12
    mov r14d, ROUNDS
.both:
    call V + 0xD000
    add r12, rax
    sub r14d, 1
    jnz .both
    PRINT r12
    lea rax, [refill2]                          ; (level 0 reads the page again at every
    mov [f_hook], rax                           ; fault: its entry of the TLB is there)
    mov qword [f_count], 0
    USER .g
    PRINT [f_count]
    PRINT r12
    ; Level 3's loop is translated now, and every fault emptied the table: level 0 calls
    ; again, so that the table holds level 0's block when level 3 asks.
    mov rbx, V + 0xE000
    xor r12, r12
    mov r14d, ROUNDS
.again:
    call V + 0xD000
    add r12, rax
    sub r14d, 1
    jnz .again
    PRINT r12
    lea rax, [refill2]
    mov [f_hook], rax
    mov qword [f_count], 0
    USER .g
    PRINT [f_count]
    PRINT r12
    EXIT
.g:
    xor r12, r12
    mov r14d, ROUNDS
.gl:
    mov rbx, V + 0xE000
    lea rax, [.g1]
    mov [f_resume], rax
    call V + 0xD000                             ; the read in it faults at this level, every
    add r12, rax                                ; time (not reached)
.g1:
    mov rsp, USER_STACK                         ; (the call's return address is left behind)
    sub r14d, 1
    jnz .gl
    LEAVE_USER

refill2:
    push rbx
    mov rbx, V + 0xE000
    mov rbx, [rbx]
    pop rbx
    ret
file_end:
