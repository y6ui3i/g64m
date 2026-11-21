; What a machine's memory looks like to translated code (E133): each part is a loop that
; goes round often enough to be translated, and then does what the TLB's look-up in
; generated code must not take for a hit, or must leave to the interpreter: a level's own
; table, a page that may not be written, eight bytes across two pages, FS and GS, a jump
; to a page that is not the next in memory, a block made at one privilege level and met
; at another.
%include "sys.inc"
    jmp test
%include "idt.inc"
%include "pt.inc"
%include "ring3.inc"

V equ 0x40000000
P equ 0x400000
ROUNDS equ 24

test:
    call idt_init
    call ring3_init

    PUTS "eight bytes across two pages that are not neighbours in memory"
    MAP V, P, 3
    MAP V + 0x1000, P + 0x5000, 3
    MAP V + 0x10000, P + 0x1000, 3              ; what lies behind P in memory
    mov rbx, V
    mov dword [rbx + 0xFFC], 0x11111111
    mov dword [rbx + 0x1000], 0x22222222
    mov rax, V + 0x10000
    mov dword [rax], 0x33333333
    xor r12, r12
    mov ecx, ROUNDS
.across:
    mov rax, [rbx + 0xFFC]
    add r12, rax
    dec ecx
    jnz .across
    PRINT r12

    PUTS "level 3: a page it may only read, written; and level 0's page, read"
    MAP V + 0x3000, P + 0x3000, 3               ; level 0's
    MAP V + 0x4000, P + 0x4000, 5               ; level 3 may read it
    MAP V + 0x5000, P + 0x4000, 3               ; the same page, for writing here
    mov rbx, V + 0x5000
    mov qword [rbx], 7
    mov rbx, V + 0x3000
    mov qword [rbx], 9
    mov rax, [rbx]                              ; level 0 has read and written it
    mov qword [f_count], 0
    USER .u
    PRINT [f_count]
    PRINT r12
    mov rbx, V + 0x5000
    PRINT [rbx]
    jmp .k1
.u:
    xor r12, r12
    mov ecx, ROUNDS
.ul:
    mov rbx, V + 0x4000
    mov rax, [rbx]                              ; allowed
    add r12, rax
    lea rax, [.u1]
    mov [f_resume], rax
    mov [rbx], rcx                              ; not allowed
    add r12, 0x100000                           ; (not reached)
.u1:
    lea rax, [.u2]
    mov [f_resume], rax
    mov rbx, V + 0x3000
    mov rax, [rbx]                              ; not allowed
    add r12, 0x1000                             ; (not reached)
.u2:
    dec ecx
    jnz .ul
    LEAVE_USER

.k1:
    PUTS "FS and GS, where the address without them is another page"
    MAP V + 0x6000, P + 0x6000, 3
    mov rbx, V + 0x6000
    mov qword [rbx + 0x800], 0xAAAA
    mov qword [rbx + 0x900], 0xBBBB
    mov ecx, 0xC0000101                         ; GS's base
    mov rax, V + 0x6000
    mov rdx, rax
    shr rdx, 32
    wrmsr
    mov ecx, 0xC0000100                         ; FS's
    mov rax, V + 0x6100
    mov rdx, rax
    shr rdx, 32
    wrmsr
    xor r12, r12
    xor r13, r13
    mov r14d, ROUNDS
.seg:
    mov rax, [gs:abs 0x800]
    add r12, rax
    mov rax, [fs:abs 0x800]
    add r13, rax
    mov rsi, 0x100
    db 0x64
    lea rdx, [rsi + 8]                          ; LEA takes no base
    add r12, rdx
    dec r14d
    jnz .seg
    PRINT r12
    PRINT r13
    xor eax, eax
    xor edx, edx
    mov ecx, 0xC0000101
    wrmsr
    mov ecx, 0xC0000100
    wrmsr

    PUTS "a jump to the next page, which is not the next in memory"
    MAP V + 0x8000, P + 0x8000, 3
    MAP V + 0x9000, P + 0xC000, 3               ; the page behind, somewhere else in memory
    MAP V + 0xA000, P + 0x9000, 3               ; what lies behind P + 8000h in memory
    mov rax, V + 0x8FF0
    mov dword [rax], 0x000001B8                 ; MOV EAX, 1
    mov dword [rax + 4], 0x900BEB00             ; and JMP to 2 bytes into the next page
    mov rax, V + 0x9000
    mov dword [rax], 0xC0839090                 ; ADD EAX, 10
    mov word [rax + 4], 0xC30A                  ; RET
    mov rax, V + 0xA000
    mov dword [rax], 0xC0839090                 ; ADD EAX, 100, where memory's next page is
    mov word [rax + 4], 0xC364
    xor r12, r12
    mov r14d, ROUNDS
.hot:
    xor eax, eax
    mov rdx, V + 0xA002
    call rdx                                    ; that one run until it is translated
    add r12, rax
    dec r14d
    jnz .hot
    PRINT r12
    xor r12, r12
    mov r14d, ROUNDS
.page:
    mov rdx, V + 0x8FF0
    call rdx
    add r12, rax
    dec r14d
    jnz .page
    PRINT r12

    PUTS "a block made at level 0, met at level 3"
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
    mov rdx, V + 0xD000
    call rdx
    add r12, rax
    dec r14d
    jnz .both
    PRINT r12
    mov qword [f_count], 0
    USER .g
    PRINT [f_count]
    PRINT r12

    PUTS "code written while it is run"
    MAP V + 0x12000, P + 0x12000, 3
    mov rbx, V + 0x12000
    mov dword [rbx], 0x000005B8                 ; MOV EAX, 5
    mov word [rbx + 4], 0xC300                  ; RET
    xor r12, r12
    mov r14d, ROUNDS
.w1:
    call rbx
    add r12, rax
    dec r14d
    jnz .w1
    PRINT r12
    mov dword [rbx + 1], 6                      ; the constant, with the code translated
    xor r12, r12
    mov r14d, ROUNDS
.w2:
    call rbx
    add r12, rax
    dec r14d
    jnz .w2
    PRINT r12

    PUTS "a page written often, then run for long, then written again"
    xor r12, r12
    mov r14d, 40
.w3:
    mov [rbx + 1], r14d                         ; written and run in turns, more often than
    call rbx                                    ; a decode cache keeps up with
    add r12, rax
    dec r14d
    jnz .w3
    PRINT r12
    xor r12, r12
    mov r14d, 6000
.w4:
    call rbx                                    ; then only run
    add r12, rax
    dec r14d
    jnz .w4
    PRINT r12
    mov dword [rbx + 1], 9                      ; and written once more
    xor r12, r12
    mov r14d, ROUNDS
.w5:
    call rbx
    add r12, rax
    dec r14d
    jnz .w5
    PRINT r12
    EXIT
.g:
    mov rbx, V + 0xE000
    lea rax, [.g1]
    mov [f_resume], rax
    xor r12, r12
    mov rdx, V + 0xD000
    call rdx                                    ; the read in it faults at this level
    mov r12, rax                                ; (not reached)
.g1:
    LEAVE_USER

file_end:
