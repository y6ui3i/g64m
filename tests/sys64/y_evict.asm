; A block that has lost its first instruction's entry in the decode cache (E166). Four
; short routines lie at physical addresses that choose the same set of the cache (two
; entries: 400000h, 500001h, 600002h, 700003h under `p ^ p >> 20`), so that the third to
; be run takes the entry of one that is a block already. The block is kept, and comes
; back when its routine is run again; but not if its page was written in between, and
; not at another privilege level as if it had been made there. And the three run in turn:
; each comes to the interpreter with no entry every time.
%include "sys.inc"
    jmp test
%include "idt.inc"
%include "pt.inc"
%include "ring3.inc"

V equ 0x40000000
ROUNDS equ 24

%macro RUN 1
    mov r14d, ROUNDS
%%l:
    call %1
    add r12, rax
    sub r14d, 1
    jnz %%l
%endmacro

; (On a page of its own: the page before is written to at every fault, idt.inc.)
    align 4096
test:
    call idt_init
    call ring3_init
    MAP V, 0x400000, 3
    MAP V + 0x1000, 0x500000, 3
    MAP V + 0x2000, 0x600000, 3
    MAP V + 0x3000, 0x700000, 7                 ; code for both levels
    MAP V + 0x4000, 0x800000, 3                 ; data that is level 0's
    MAP V + 0x10000, 0x400000, 3                ; the first routine's page, to write it by
    mov rax, V
    mov dword [rax], 0x000001B8                 ; MOV EAX, 1
    mov word [rax + 4], 0xC300                  ; RET
    mov rax, V + 0x1001
    mov dword [rax], 0x000100B8                 ; MOV EAX, 100h
    mov word [rax + 4], 0xC300
    mov rax, V + 0x2002
    mov dword [rax], 0x010000B8                 ; MOV EAX, 10000h
    mov word [rax + 4], 0xC300
    mov rax, V + 0x3003
    mov dword [rax], 0x48038B48                 ; MOV RAX, [RBX]
    mov dword [rax + 4], 0xC301C083             ; ADD RAX, 1 and RET
    mov rbx, V + 0x4000
    mov qword [rbx], 5

    PUTS "three routines for two entries, and the first again"
    xor r12, r12
    RUN V
    RUN V + 0x1001
    RUN V + 0x2002
    RUN V
    PRINT r12

    PUTS "the first routine's page written while its block has no entry"
    xor r12, r12
    RUN V + 0x1001
    RUN V + 0x2002
    mov rax, V + 0x10000
    mov dword [rax + 1], 7                      ; MOV EAX, 7
    RUN V
    PRINT r12

    PUTS "the three in turn: none is ever run from an entry (a block at the eighth time, E167)"
    xor r12, r12
    mov r14d, ROUNDS
.turn:
    call V
    add r12, rax
    call V + 0x1001
    add r12, rax
    call V + 0x2002
    add r12, rax
    sub r14d, 1
    jnz .turn
    PRINT r12
    mov rax, V + 0x10000
    mov dword [rax + 1], 9                      ; and the first one's page written again
    xor r12, r12
    mov r14d, ROUNDS
.turn2:
    call V
    add r12, rax
    call V + 0x1001
    add r12, rax
    call V + 0x2002
    add r12, rax
    sub r14d, 1
    jnz .turn2
    PRINT r12

    PUTS "a block made at level 0 that has no entry, run at level 3"
    xor r12, r12
    RUN V + 0x3003
    RUN V + 0x1001
    RUN V + 0x2002
    PRINT r12
    lea rax, [refill]                           ; (level 0 reads the page again at every
    mov [f_hook], rax                           ; fault: its entry of the TLB is there)
    mov qword [f_count], 0
    USER .g
    PRINT [f_count]
    PRINT r12
    EXIT
.g:
    xor r12, r12
    mov r14d, ROUNDS
.gl:
    mov rbx, V + 0x4000
    lea rax, [.g1]
    mov [f_resume], rax
    call V + 0x3003                             ; the read in it faults at this level, every
    add r12, rax                                ; time (not reached)
.g1:
    mov rsp, USER_STACK                         ; (the call's return address is left behind)
    sub r14d, 1
    jnz .gl
    LEAVE_USER

refill:
    push rbx
    mov rbx, V + 0x4000
    mov rbx, [rbx]
    pop rbx
    ret
file_end:
