; Prefixes end with their instruction (E109): the instruction after one with a prefix 67h,
; 66h, F3h or REX.W is met for the first time just then, and has none of it. And REX in
; front of the x87, which names no other register of its stack and no other operation.
%include "elf.inc"

    mov rbx, 0x100000010
    mov rsi, 0x2FFFFFFF0
    lea eax, [ebx + esi]                ; 67h: an address of 32 bits
    lea rdx, [rbx + rsi + 8]            ; and none here: the sum has bits above 32
    lea eax, [ebx]
    lea rdi, [rbx * 2 + 4]
    mov eax, 0x12345678
    add ax, 0x9000                      ; 66h
    add eax, 0x00010001                 ; and none
    mov rax, 0x1122334455667788         ; REX.W
    mov eax, eax                        ; and none: the upper half goes
    lea rsi, [buf]
    lea rdi, [buf + 32]
    mov ecx, 3
    rep movsb                           ; F3h
    movsb                               ; and none: one byte, RCX as it is
    mov rdx, [buf + 32]

    fninit
    db 0x41, 0xD9, 0xE8                 ; REX.B, FLD1: the field is part of the opcode here
    fldz
    fld dword [three]                   ; ST0 3, ST1 0, ST2 1
    db 0x41, 0xD8, 0xC2                 ; REX.B, FADD ST0, ST2
    db 0x44, 0xD8, 0x05                 ; REX.R, FADD dword [relative to RIP]
    dd three - $ - 4
    db 0x41, 0xD9, 0xCA                 ; REX.B, FXCH ST2
    db 0x45, 0xDD, 0xD9                 ; REX.R and B, FSTP ST1
    fstp tword [buf]
    mov rax, [buf]
    movzx edx, word [buf + 8]
    fstp tword [buf]
    mov rax, [buf]
    movzx edx, word [buf + 8]
    EXIT

    align 16
three: dd 3.0
    align 16
buf: dq 0x0807060504030201, 0, 0, 0, 0, 0, 0, 0
file_end:
