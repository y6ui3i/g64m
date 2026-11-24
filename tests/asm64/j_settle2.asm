; The records E172 settles in generated code at the way into a block that reads RFLAGS in
; memory: SHL, SHR and SAR at 32 and 64 bits (16 and 8 are left to the interpreter, and
; are here too), BT, and INC and DEC at each width; BT and the two that keep CF also with
; CF set before. As j_settle: each case sets the flags twice from the same operands, once
; with PUSHFQ right behind (the interpreter settles the record) and once with a jump to a
; block that begins with a conditional jump; the two RFLAGS must be the same. The count
; in CL comes from the table too, and is nothing in one round of eight. Written by a few
; lines of Python in E172's commit.
%include "elf.inc"


%macro BOTH 1+
    mov rax, r8
    mov rbx, r9
    mov ecx, r10d
    %1
    pushfq
    pop r11
    mov rax, r8
    mov rbx, r9
    mov ecx, r10d
    %1
    jmp %%b
%%b:
    jc %%c
%%c:
    pushfq
    pop rdx
    cmp r11, rdx
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
    mov r10, r9
    BOTH shr rax, 1
    BOTH shr rax, 3
    BOTH shr rax, 31
    BOTH shr rax, cl
    BOTH shr eax, 1
    BOTH shr eax, 3
    BOTH shr eax, 31
    BOTH shr eax, cl
    BOTH shr ax, 1
    BOTH shr ax, 3
    BOTH shr ax, 7
    BOTH shr ax, cl
    BOTH shr al, 1
    BOTH shr al, 3
    BOTH shr al, 7
    BOTH shr al, cl
    BOTH shr rax, 63
    BOTH shl rax, 1
    BOTH shl rax, 3
    BOTH shl rax, 31
    BOTH shl rax, cl
    BOTH shl eax, 1
    BOTH shl eax, 3
    BOTH shl eax, 31
    BOTH shl eax, cl
    BOTH shl ax, 1
    BOTH shl ax, 3
    BOTH shl ax, 7
    BOTH shl ax, cl
    BOTH shl al, 1
    BOTH shl al, 3
    BOTH shl al, 7
    BOTH shl al, cl
    BOTH shl rax, 63
    BOTH sar rax, 1
    BOTH sar rax, 3
    BOTH sar rax, 31
    BOTH sar rax, cl
    BOTH sar eax, 1
    BOTH sar eax, 3
    BOTH sar eax, 31
    BOTH sar eax, cl
    BOTH sar ax, 1
    BOTH sar ax, 3
    BOTH sar ax, 7
    BOTH sar ax, cl
    BOTH sar al, 1
    BOTH sar al, 3
    BOTH sar al, 7
    BOTH sar al, cl
    BOTH sar rax, 63
    BOTH bt rax, rbx
    stc
    BOTH bt rax, rbx
    BOTH bt rax, 5
    stc
    BOTH bt rax, 5
    BOTH bts rax, rbx
    stc
    BOTH bts rax, rbx
    BOTH bt eax, ebx
    stc
    BOTH bt eax, ebx
    BOTH bt eax, 5
    stc
    BOTH bt eax, 5
    BOTH bts eax, ebx
    stc
    BOTH bts eax, ebx
    BOTH bt ax, bx
    stc
    BOTH bt ax, bx
    BOTH bt ax, 5
    stc
    BOTH bt ax, 5
    BOTH bts ax, bx
    stc
    BOTH bts ax, bx
    BOTH inc rax
    stc
    BOTH inc rax
    BOTH inc eax
    stc
    BOTH inc eax
    BOTH inc ax
    stc
    BOTH inc ax
    BOTH inc al
    stc
    BOTH inc al
    BOTH dec rax
    stc
    BOTH dec rax
    BOTH dec eax
    stc
    BOTH dec eax
    BOTH dec ax
    stc
    BOTH dec ax
    BOTH dec al
    stc
    BOTH dec al
    dec r15d
    jnz top
    EXIT
bad:
    mov eax, 60
    mov edi, 1
    syscall
    times 0x6000 - ($ - $$) db 0
pairs:
    dq 0x7FFFFFFFFFFFFFFF, 1
    dq 0xFFFFFFFFFFFFFFFF, 33
    dq 0x8000000080008080, 0x8000000080008080
    dq 0x123456789ABCDEF0, 0x0FEDCBA987654321
    dq 0, 0
    dq 0x00000000FFFF00FF, 0x000000010001011F
    dq 5, 7
    dq 0xC0000000C000C0C0, 63
file_end:
