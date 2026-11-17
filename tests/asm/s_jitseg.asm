; Self-check for a segment's limit in the JIT's memory operands (E061; the same answer with
; --jit and without). The short path that a block has inline is for an offset below seg_top;
; an access beyond the segment's limit must leave the block, so that the interpreter raises
; the fault. FS ends at 2FFFFh. A block loads through FS inside the limit, then beyond it:
; the second load takes a general protection fault every time, and the instruction after it
; is never reached. Sixteen passes; a block is made at the eighth. Prints "OK".
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
    lidt [idtr]
    mov  dword [0x8000 + 13*8], 0x00080000 + gp     ; the #GP gate: selector 8, offset gp
    mov  dword [0x8000 + 13*8 + 4], 0x00008E00
    mov  ax, 0x20                       ; FS: a segment that ends at 2FFFFh
    mov  fs, ax
    mov  dword [0x2FFF0], 0x11223344
    xor  edi, edi
    mov  ebp, 16
pass:
    cld                                 ; a run begins after it, and the block with the run
    mov  ebx, .beyond
    mov  esi, 0x2FFF0
    mov  ecx, [0x30000]                 ; (so that the TLB has the page beyond FS's limit)
    mov  eax, [fs:esi]                  ; inside the limit
    add  edi, eax
    mov  edx, [fs:esi+0x10]             ; beyond it: #GP
    add  edi, 0x00010000                ; not reached
.beyond:
    dec  ebp
    jnz  pass
    jmp  0x18:leave
gp:                                     ; counted, and on at the address in EBX
    mov  [esp+4], ebx
    add  esp, 4
    inc  edi
    iretd
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
    lidt [ridtr]
    cmp  edi, 0x12233450                ; sixteen loads inside, sixteen faults, nothing else
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
    dq 0x00C092000000002F               ; data that ends at 2FFFFh
gdtr:
    dw 39
    dd gdt
idtr:
    dw 15*8 - 1
    dd 0x8000
ridtr:
    dw 0x3FF
    dd 0
    TAIL
