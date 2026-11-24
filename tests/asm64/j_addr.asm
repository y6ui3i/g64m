; An operand's address made once (E184): the same operand used again with nothing changed
; between (a load, then a store to it), with its base changed between, with its index
; changed between, and with something between that uses the stack; operands that differ
; only in their constant, up and down; base and index with no constant. In a run that goes
; round often enough to be translated, on values that change every round. All of it is
; added into R13, which is compared at the end with what the interpreter (held to the real
; CPU by the trace) gives: a wrong translation under --jit leaves by `bad`. difftest64.sh
; runs it again with --jit-check and with --jit.
%include "elf.inc"

EXPECTED equ 0xDCD305930D8CFCAE                         ; R13 at the end, as the interpreter and the real CPU have it

    mov r15d, 24
    lea rbp, [data]
    xor r13d, r13d
    mov rbx, 0x8123456789ABCDEF
top:
    mov esi, r15d
    and esi, 7
    ; the same operand: read, then written
    mov eax, [rbp + rsi*4]
    add eax, ebx
    mov [rbp + rsi*4], eax
    add r13, rax
    ; the base changed between
    mov rdi, rbp
    mov rax, [rdi + rsi*8 + 64]
    add rdi, 8
    add rax, [rdi + rsi*8 + 64]
    add r13, rax
    mov [rdi + rsi*8 + 64], rbx
    ; the index changed between
    mov rax, [rbp + rsi*8 + 64]
    add esi, 1
    add rax, [rbp + rsi*8 + 64]
    add r13, rax
    sub esi, 1
    ; the stack used between
    mov rax, [rbp + rsi*8 + 64]
    push rbx
    pop rcx
    add rcx, [rbp + rsi*8 + 64]
    add r13, rcx
    add r13, rax
    ; the same base, index and constant at another scale
    mov eax, [rbp + rsi*4 + 600]
    add rax, [rbp + rsi*8 + 600]
    add r13, rax
    mov [rbp + rsi*8 + 600], rbx
    mov [rbp + rsi*4 + 600], ebx
    ; neighbours: the constant alone differs, up and down
    lea rdx, [rsi*8]
    movzx eax, word [rbp + rdx + 200]
    add r13, rax
    movzx eax, byte [rbp + rdx + 202]
    add r13, rax
    mov eax, [rbp + rdx + 204]
    add r13, rax
    mov rax, [rbp + rdx + 192]
    add r13, rax
    xor byte [rbp + rdx + 203], 0x5A
    add word [rbp + rdx + 200], bx
    mov rax, [rbp + rdx + 200]
    add r13, rax
    ; far neighbours: more than the difference an add takes
    mov rax, [rbp + rdx + 200]
    add rax, [rbp + rdx + 200 + 8192]
    add r13, rax
    mov [rbp + rdx + 200 + 8192], rbx
    ; a store, then a load of it, then a store of another width
    mov [rbp + rsi*4 + 400], ebx
    mov eax, [rbp + rsi*4 + 400]
    add r13, rax
    mov [rbp + rsi*4 + 400], bl
    mov [rbp + rsi*4 + 400], rbx
    add r13, [rbp + rsi*4 + 400]
    ; relative to RIP, twice and next to it
    mov rax, [rel data + 512]
    add rax, [rel data + 512]
    add rax, [rel data + 520]
    add r13, rax
    mov [rel data + 512], r13
    ; the next round's value
    mov rax, 0x9E3779B97F4A7C15
    imul rbx, rax
    add rbx, r13
    sub r15d, 1
    jnz top
    mov rax, EXPECTED
    cmp r13, rax
    jne bad
    EXIT
bad:
    mov eax, 60
    mov edi, 1
    syscall
    times 0x3000 - ($ - $$) db 0
data:
    times 2048 dq 0
file_end:
