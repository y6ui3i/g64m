; The first system test: that the image starts in long mode, prints, and stops; and what
; the control registers hold.
%include "sys.inc"
    PUTS "long mode"
    mov rax, cr0
    PRINT rax
    mov rax, cr3
    PRINT rax
    mov rax, cr4
    PRINT rax
    mov ecx, 0xC0000080
    rdmsr
    shl rdx, 32
    or rax, rdx
    PRINT rax
    mov eax, cs
    PRINT rax
    mov eax, ss
    PRINT rax
    lea rax, [rel start64]
    PRINT rax
    pushfq
    pop rax
    PRINT rax
    EXIT
file_end:
