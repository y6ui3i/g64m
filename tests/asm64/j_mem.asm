; Loads, stores and the stack in runs that go round often enough to be translated (E121).
; The trace holds the interpreter to the real CPU; difftest64.sh runs every test again with
; --jit-check and with --jit. Each stretch is one a wrong build of the translator passed
; before this test was there.
%include "elf.inc"

    mov r15d, 26
    lea rbp, [data + 64]
    lea rsi, [data + 128]               ; where the stores below go: data at first, so that
top:                                    ; their blocks are translated before the page of
    cmp r15d, 12                        ; `other` has been written to; then other's constant
    jne .go
    lea rsi, [other + 2]
.go:
    call other                          ; its page holds remembered instructions again
    mov [rsi], r15d                     ; a block that begins with a store into such a page:
    mov r13d, r10d                      ; left before its first instruction. (The store
    call other                          ; changes the constant of other's MOV.)
    mov r14d, r10d
    mov eax, [other + 2]                ; what other gave is the constant it has now: a run
    cmp r10d, eax                       ; with the JIT and no check is held by the exit code
    jne bad
    mov qword [rbp - 8], 100            ; a displacement below the base
    mov qword [rbp - 16], -3            ; a constant of 32 bits, sign-extended to 64
    mov eax, 30
    sub [rbp - 8], rax                  ; memory less register: 70
    mov rbx, 1000
    sub rbx, [rbp - 8]                  ; register less memory: 930
    cmp [rbp - 8], rax                  ; 70 against 30
    ja .a1
    mov r8d, 1
.a1:
    cmp dword [rbp - 8], 70             ; equal, and nothing stored
    jne .a2
    mov r9, [rbp - 8]
.a2:
    add qword [rbp - 16], -1            ; a constant of 8 bits, sign-extended: -4
    mov r11, [rbp - 16]
    mov rax, 0x1122334455667788
    mov al, [rbp - 16]                  ; one byte, the rest of RAX as it was
    mov r12, rax
    mov rcx, 5
    cmp ebx, ebx
    cmove rcx, [rbp - 8]                ; moved
    mov rdi, rsp
    push rdi
    pop rsp                             ; RSP takes what was popped, not that and eight
    mov eax, r15d
    add eax, 100
    mov [rsi], eax                      ; and one in the middle of a block: left before it,
    add ebx, eax                        ; and gone on with after
    call other
    add ecx, r10d
    dec r15d
    jnz top
    EXIT
bad:
    mov eax, 60
    mov edi, 1
    syscall

    times 0x2000 - ($ - $$) db 0x90
other:                                  ; at 402000h
    mov r10d, 7
    ret
    times 0x3000 - ($ - $$) db 0
data:
    times 256 db 0
file_end:
