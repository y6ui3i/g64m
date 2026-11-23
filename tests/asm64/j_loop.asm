; What E164 changed in the generated code: a loop's way back in line (with a record owed
; at its head, and without); constants built from all ones; a record left out where a move
; stands between a comparison and its CMOVcc; ADD, SUB, AND, CMP and TEST with no host
; flags where the guest's are dead; shifts of 8 and 16 bits right and left by constants
; under the width, at it and over it; a second access through a register tested before,
; with the register written between, loaded into itself, and stored through; a store over
; a page's end. All of it is added into R13, which is compared at the end with what the
; interpreter (held to the real CPU by the trace) gives: a wrong translation under --jit
; leaves by `bad`. difftest64.sh runs it again with --jit-check and with --jit.
%include "elf.inc"

EXPECTED equ 0x338BE166A0C03E0D          ; R13 at the end, as the interpreter and the real CPU have it

    mov r15d, 12
    lea rbp, [data]
    xor r13d, r13d
    mov rbx, 0x8123456789ABCDEF
top:
    ; a loop that is one block, its flags dead at its head
    mov ecx, 40
    xor eax, eax
.spin:
    add rax, rbx
    lea rax, [rax + rcx*8 + 3]
    sub ecx, 1
    jnz .spin
    add r13, rax
    ; one whose head reads the flags the jump at its end left (ADC)
    mov ecx, 9
    xor eax, eax
    stc
.carry:
    adc rax, rbx
    sub ecx, 1
    cmp ecx, 3
    jne .carry
    add r13, rax
    ; constants near -1, and others
    mov r9, -1000
    add r13, r9
    mov r9, 0xFFFFFFFF00001234
    add r13, r9
    mov r9, 0xFFFF1234FFFFFFFF
    add r13, r9
    mov r9d, 0xFFFF8000
    add r13, r9
    mov r9, 0x0000FFFF00000000
    add r13, r9
    mov r9, -1
    add r13, r9
    ; a move between the comparison and the CMOVcc; then the flags read, and not
    mov rax, rbx
    mov rdx, r13
    cmp rax, rdx
    mov rsi, rdx
    cmovg rsi, rax
    add r13, rsi
    cmp rax, rdx
    mov rsi, rdx
    mov rdi, rax
    cmovb rsi, rdi
    pushfq
    pop rcx
    and ecx, 0x8D5
    add r13, rsi
    add r13, rcx
    cmp rax, rdx
    mov sil, dl                         ; a move of a byte is not looked past
    cmovg rsi, rax
    add r13, rsi
    ; arithmetic whose flags nothing reads, and whose flags something does
    mov rax, rbx
    add rax, 77
    sub rax, r13
    and rax, 0x7FFFFFF0
    cmp rax, 5
    test rax, rax
    add eax, ebx
    sub eax, 9
    and eax, r13d
    add r13, rax
    sub rax, rbx
    setc dl
    movzx edx, dl
    add r13, rdx
    ; shifts of 16 and 8 bits by constants
    mov eax, ebx
    shr ax, 2
    add r13, rax
    mov eax, ebx
    sar ax, 7
    add r13, rax
    mov eax, ebx
    shl ax, 5
    add r13, rax
    mov eax, ebx
    shr al, 3
    add r13, rax
    mov eax, ebx
    sar al, 7
    add r13, rax
    mov eax, ebx
    shl al, 1
    add r13, rax
    mov eax, ebx
    shr ax, 16                          ; the width: nothing left
    add r13, rax
    mov eax, ebx
    sar ax, 20                          ; over it: the sign
    add r13, rax
    mov eax, ebx
    shr al, 9
    add r13, rax
    mov eax, ebx
    sar ax, 15
    setc dl
    movzx edx, dl
    add r13, rax
    add r13, rdx
    ; a register read through twice, written between, and loaded into itself
    mov rsi, rbp
    mov [rsi], rbx
    mov rax, [rsi]
    mov edx, [rsi]
    add r13, rax
    add r13, rdx
    add rsi, 8
    mov [rsi], r13
    mov rax, [rsi]
    add r13, rax
    lea rdi, [rbp + 24]
    mov [rsi], rdi
    mov rsi, [rsi]                      ; RSI is what was loaded
    mov [rsi], rbx
    mov rax, [rsi]
    add r13, rax
    ; a store over a page's end, and what is read back from both pages
    mov rsi, edge - 3
    mov [rsi], r13
    mov rax, [rsi]
    add r13, rax
    mov eax, [edge]
    add r13, rax
    ; the next round's value
    mov rax, 0x9E3779B97F4A7C15
    imul rbx, rax
    add rbx, r13
    dec r15d
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
    times 0x1000 - 8 db 0
    dq 0
edge:
    times 64 db 0
file_end:
