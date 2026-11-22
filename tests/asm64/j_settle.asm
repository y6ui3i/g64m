; A record of the flags waiting at the way into a block that reads RFLAGS in memory (E146):
; settled in generated code for ADD, SUB, CMP, AND, TEST, OR and XOR at each width, left to
; the interpreter for the rest. Each case sets the flags twice from the same operands: once
; with PUSHFQ right behind, so that the interpreter settles the record, and once with a jump
; to a block that begins with a conditional jump, so that the block is entered from the
; block before it with the record waiting; the two RFLAGS must be the same. The operands come
; from a table, another pair each round. Written by a few lines of Python in E146's commit;
; the trace holds the interpreter to the real CPU, and difftest64.sh runs it with --jit.
%include "elf.inc"

%macro BOTH 1+
    mov rax, r8
    mov rbx, r9
    %1
    pushfq
    pop rcx
    mov rax, r8
    mov rbx, r9
    %1
    jmp %%b
%%b:
    jc %%c
%%c:
    pushfq
    pop rdx
    cmp rcx, rdx
    jne bad
%endmacro

    mov r15d, 24
    lea rbp, [pairs]
top:
    mov eax, r15d
    and eax, 7
    shl eax, 4
    mov r8, [rbp + rax]
    mov r9, [rbp + rax + 8]
    BOTH add rax, rbx
    BOTH add eax, ebx
    BOTH add ax, bx
    BOTH add al, bl
    BOTH sub rax, rbx
    BOTH sub eax, ebx
    BOTH sub ax, bx
    BOTH sub al, bl
    BOTH cmp rax, rbx
    BOTH cmp eax, ebx
    BOTH cmp ax, bx
    BOTH cmp al, bl
    BOTH and rax, rbx
    BOTH and eax, ebx
    BOTH and ax, bx
    BOTH and al, bl
    BOTH or rax, rbx
    BOTH or eax, ebx
    BOTH or ax, bx
    BOTH or al, bl
    BOTH xor rax, rbx
    BOTH xor eax, ebx
    BOTH xor ax, bx
    BOTH xor al, bl
    BOTH test rax, rbx
    BOTH test eax, ebx
    BOTH test ax, bx
    BOTH test al, bl
    BOTH neg rax
    BOTH neg eax
    BOTH shr eax, 3
    BOTH shl rax, 5
    BOTH imul eax, ebx
    BOTH bt rax, 7
    BOTH add eax, 0x7F
    BOTH cmp rax, 0x100
    BOTH sub al, 0x80
    BOTH test ax, 0x8000
    dec r15d
    jnz top
    EXIT
bad:
    mov eax, 60
    mov edi, 1
    syscall
    times 0x3000 - ($ - $$) db 0
pairs:
    dq 0x7FFFFFFFFFFFFFFF, 1
    dq 0xFFFFFFFFFFFFFFFF, 1
    dq 0x8000000080008080, 0x8000000080008080
    dq 0x123456789ABCDEF0, 0x0FEDCBA987654321
    dq 0, 0
    dq 0x00000000FFFF00FF, 0x0000000100010101
    dq 5, 7
    dq 0x80, 0x80
file_end:
