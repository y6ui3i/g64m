; Self-check for blocks of the JIT that lead to one another (E065; the same answer with --jit
; and without). The body of the loop is a handful of blocks, each ending in a conditional jump,
; a CALL or a RET, all in one page: once each has been made, generated code goes from one to
; the next without leaving, counting the time down as it goes. One CLD at the top of the loop
; is where a run of the interpreter begins, which is where the first block is counted. The
; sum is a trace run's; and tools/difftest.sh stops this program after each of 400 instruction
; counts, late in it, where it must be at the address the trace has: a chain of blocks has to
; stop where the time runs out, wherever in the chain that is. Prints "OK".
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
    xor  edi, edi
    mov  eax, 1
    mov  ebp, 400
again:
    cld
    add  eax, 0x9E3779B1
    test eax, 1
    jz   .a
    add  edi, eax
.a:
    test eax, 2
    jnz  .b
    xor  edi, eax
.b:
    cmp  eax, edi
    jb   .c
    inc  edi
.c:
    call mix
    lea  edi, [edi+eax*2]               ; where the RET comes back to: a block of its own
    sub  eax, edi
    dec  ebp
    jnz  again
    jmp  0x18:leave
mix:
    mov  ecx, eax
    shr  ecx, 7
    xor  edi, ecx
    ret
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
    cmp  edi, 0x37CDB30C                ; from a trace run, one instruction at a time
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
