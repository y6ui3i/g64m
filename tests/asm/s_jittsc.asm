; Self-check for RDTSC in the JIT's blocks (E066; the same answer with --jit and without).
; The virtual time is the count of instructions executed, and RDTSC reads it. In a block it is
; what the time was when generated code was entered plus what has run since, the block's own
; instructions so far included. Two RDTSCs with a known number of instructions between them,
; in one block and across a jump into the next; sixteen passes. RDTSC is the i686's.
; Prints "OK".
%define CPU686
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
    mov  ebp, 16
pass:
    cld                                 ; a run begins after it, and the block with the run
    rdtsc
    mov  esi, eax
    nop
    nop
    nop
    rdtsc                               ; five instructions after the first
    sub  eax, esi
    add  edi, eax
    jmp  short .next                    ; into another block
.next:
    nop
    rdtsc                               ; five after the second
    sub  eax, esi
    add  edi, eax
    dec  ebp
    jnz  pass
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
    cmp  edi, 16 * (5 + 10)             ; sixteen passes, five and ten instructions on
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
