; Division of 128 bits by 64 (E114): the upper half empty, holding one, holding all it may
; (one less than the divisor), and for IDIV the same with each sign.
%include "elf.inc"

%macro UDIV 3               ; upper half, lower half, divisor
    mov rdx, %1
    mov rax, %2
    mov rcx, %3
    div rcx
%endmacro
%macro SDIV 3
    mov rdx, %1
    mov rax, %2
    mov rcx, %3
    idiv rcx
%endmacro

    UDIV 0, 0x123456789ABCDEF0, 0x1001
    UDIV 0, 0xFFFFFFFFFFFFFFFF, 1
    UDIV 0, 5, 0xFFFFFFFFFFFFFFFF
    UDIV 1, 0, 2
    UDIV 1, 0x123456789ABCDEF0, 0x1001
    UDIV 1, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF
    UDIV 2, 7, 3
    UDIV 0x1000, 0xFFFFFFFFFFFFFFFF, 0x1001
    UDIV 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF
    SDIV 0, 0x123456789ABCDEF0, 0x1001
    SDIV 0, 0x123456789ABCDEF0, -0x1001
    SDIV -1, -0x123456789ABCDEF0, 0x1001
    SDIV -1, -0x123456789ABCDEF0, -0x1001
    SDIV -1, 0x8000000000000000, 1
    SDIV 0, 0x7FFFFFFFFFFFFFFF, -1
    SDIV 1, 0, 4
    SDIV 1, 0x123456789ABCDEF0, -0x1001
    SDIV -2, 0x123456789ABCDEF0, 0x1001
    SDIV -2, 5, -7
    SDIV 0x3FF, 0xFFFFFFFFFFFFFFFF, 0x1001
    SDIV -0x400, 1, 0x1001
    EXIT
file_end:
