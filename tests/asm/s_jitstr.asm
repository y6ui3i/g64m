; Self-check for the string instructions without REP, MOV with a 16-bit operand and IMUL in
; the JIT's blocks (E066; the same answer with --jit and without). Each block is between a CLD
; or an STD, after which a run begins, and the next; the string instructions are run with the
; direction flag clear and set. Bytes, words and doublewords are moved between two buffers
; and scanned, and the registers and the buffers are summed in EDI over sixteen passes. The
; sum expected is a trace run's. Prints "OK".
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
    mov  es, ax
    xor  edi, edi
    mov  ebp, 16
pass:
    push edi
    mov  esi, 0x5000                    ; a buffer that changes with the pass
    mov  eax, ebp
    imul eax, eax, 0x01010101
    mov  [esi], eax
    mov  [esi+4], ebp
    mov  edi, 0x5100
    cld                                 ; forwards
    movsd
    movsw
    movsb
    lodsb
    stosb
    stosd
    mov  ebx, esi
    add  ebx, edi
    std                                 ; and backwards
    mov  esi, 0x5007
    mov  edi, 0x5207
    movsb
    movsw
    movsd
    lodsb
    stosb
    mov  al, 0x55
    scasb                               ; AL against a smaller byte: no borrow
    setb cl
    pushfd                              ; and the flags it leaves, all of them
    pop  edx
    add  ebx, edx
    add  ebx, esi
    add  ebx, edi
    cld                                 ; 16-bit moves and IMUL
    mov  dx, [0x5100]
    mov  [0x5104], dx
    mov  ecx, 0xABCD0000                ; (so that CX's register has an upper half to keep)
    db   0x66, 0x8B, 0xCA               ; mov cx, dx by opcode 8B (an assembler uses 89)
    imul edx, [0x5100]
    imul ecx, edx
    mov  ax, cx                         ; by opcode 89, into a register with an upper half
    seto al
    add  ebx, edx
    add  ebx, ecx
    add  ebx, eax
    add  ebx, [0x5100]
    add  ebx, [0x5104]
    add  ebx, [0x5200]
    add  ebx, [0x5204]
    pop  edi
    lea  edi, [edi+edi*2]
    add  edi, ebx
    dec  ebp
    jnz  pass
    cld
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
    cmp  edi, 0x383CFB58                ; from a trace run, one instruction at a time
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
