; The frame of a 64-bit test (E091): a static ELF with one segment, readable, writable and
; executable, of 2 MB at 400000h, built with `nasm -f bin`. No linker and no library.
;
; A test includes this, goes on from `start:`'s first instruction (which loads RSP, the one
; register a real kernel does not start at a known value), and ends with EXIT and then
; `file_end:`. The memory from the file's end to stack_top is zero.
bits 64
default rel
org 0x400000

MEM_TOP equ 0x600000
stack_top equ MEM_TOP - 0x100

ehdr:
    db 0x7F, "ELF", 2, 1, 1, 0
    times 8 db 0
    dw 2                    ; an executable
    dw 62                   ; x86_64
    dd 1
    dq start
    dq phdr - $$
    dq 0
    dd 0
    dw 64, 56, 1, 0, 0, 0
phdr:
    dd 1                    ; loaded
    dd 7                    ; read, write, execute
    dq 0
    dq $$
    dq $$
    dq file_end - $$
    dq MEM_TOP - $$
    dq 0x1000

%macro EXIT 0
    mov eax, 60
    xor edi, edi
    syscall
%endmacro

; Sets the arithmetic flags and DF from a constant, through the stack.
%macro FLAGS 1
    push %1
    popfq
%endmacro

start:
    mov rsp, stack_top
