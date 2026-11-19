; Page tables for the system tests (E094): entries found and made, pages mapped.
;
; New tables are taken from 300000h up, which is zero. An entry that was in use is to be
; invalidated by the test when it changes it, as a CPU with a TLB needs.

; The address of the entry for linear address RDI at the level whose index starts at bit CL
; (39, 30, 21 or 12), in RAX; tables on the way are made as needed.
entry:
    push rbx
    push rdx
    push rsi
    mov rbx, cr3
    and rbx, -4096
    mov esi, 39
.down:
    mov rax, rdi
    xchg ecx, esi
    shr rax, cl
    xchg ecx, esi
    and eax, 511
    lea rax, [rbx + rax * 8]
    cmp esi, ecx
    je .done
    mov rdx, [rax]
    test dl, 1
    jnz .have
    mov rdx, [next_table]
    add qword [next_table], 4096
    or rdx, 7
    mov [rax], rdx
.have:
    mov rbx, rdx
    and rbx, -4096
    mov rdx, 0x000FFFFFFFFFFFFF
    and rbx, rdx
    sub esi, 9
    jmp .down
.done:
    pop rsi
    pop rdx
    pop rbx
    ret

; Maps the 4 KB page at RDI to physical RSI with the bits in RDX.
map:
    push rax
    push rcx
    mov ecx, 12
    call entry
    mov rcx, rsi
    or rcx, rdx
    mov [rax], rcx
    pop rcx
    pop rax
    ret

%macro MAP 3
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    call map
%endmacro

; Prints the entry of the level whose index starts at bit %2, for address %1.
%macro SHOW_ENTRY 2
    mov rdi, %1
    mov ecx, %2
    call entry
    PRINT [rax]
%endmacro

align 8
next_table: dq 0x300000
