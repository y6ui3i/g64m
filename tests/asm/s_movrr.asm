; Self-check for MOV between two registers by each of its opcodes (E046). An assembler writes
; `mov ecx, eax` with opcode 89, so opcode 8B with a register operand is in no other test; it
; has an executor of its own, and so has 89. The bytes are written out here. Four passes, so
; that the executors run them; every pass starts from EAX and EBX, so a move the wrong way
; round in the last pass shows at the end. Prints "OK".
%define CPU386
%include "common.inc"
start:
    cli
    xor  ax, ax
    mov  ds, ax
    lgdt [gdtr]
    mov  eax, cr0
    or   al, 1
    mov  cr0, eax
    jmp  0x08:pm
bits 32
pm:
    mov  ax, 0x10
    mov  ds, ax
    mov  ss, ax
    mov  esp, 0x7000
    mov  ebp, 4
.pass:
    mov  eax, 0x12345678
    mov  ebx, 0x9ABCDEF0
    xor  ecx, ecx
    xor  edx, edx
    xor  esi, esi
    xor  edi, edi
    db   0x8B, 0xC8                     ; mov ecx, eax by 8B
    db   0x89, 0xDA                     ; mov edx, ebx by 89
    db   0x8B, 0xF2                     ; mov esi, edx by 8B
    db   0x89, 0xCF                     ; mov edi, ecx by 89
    dec  ebp
    jnz  .pass
    mov  ebp, eax
    jmp  0x18:leave
bits 16
leave:                                  ; back to real mode, where the BIOS can print
    mov  eax, cr0
    and  al, 0xFE
    mov  cr0, eax
    jmp  0:real
real:
    xor  ax, ax
    mov  ds, ax
    mov  ss, ax
    cmp  ebp, 0x12345678
    jne  .no
    cmp  ebx, 0x9ABCDEF0
    jne  .no
    cmp  ecx, 0x12345678
    jne  .no
    cmp  edx, 0x9ABCDEF0
    jne  .no
    cmp  esi, 0x9ABCDEF0
    jne  .no
    cmp  edi, 0x12345678
    jne  .no
    mov  ax, 0x0E4F                     ; 'O'
    int  0x10
    mov  ax, 0x0E4B                     ; 'K'
    int  0x10
    hlt
.no:
    mov  ax, 0x0E4E                     ; 'N'
    int  0x10
    hlt
align 8
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
    dq 0x00009A000000FFFF               ; 16-bit code
gdtr:
    dw 31
    dd gdt
    TAIL
