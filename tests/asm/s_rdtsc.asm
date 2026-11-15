; Self-check for RDTSC in 32-bit protected mode, where it has a short executor. The counter is the
; number of instructions completed, so two readings with four instructions between them differ by
; exactly 5, whichever path ran them; and the first reading of each pass is the same distance from
; the one before. The first pass is the general path, the other three the executor, so a counter
; that one of them gets wrong shows in the distances. Prints "OK".
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
    mov  ecx, 4
    mov  bl, 1
    mov  edi, 0x8000
.pass:
    rdtsc
    mov  [edi], eax
    add  edi, 4
    mov  esi, eax
    nop
    rdtsc
    sub  eax, esi
    cmp  eax, 5
    je   .ok
    mov  bl, 0
.ok:
    dec  ecx
    jnz  .pass
    mov  eax, [0x8004]          ; the distances between passes
    sub  eax, [0x8000]
    mov  edx, [0x8008]
    sub  edx, [0x8004]
    cmp  eax, edx
    jne  .bad
    mov  edx, [0x800C]
    sub  edx, [0x8008]
    cmp  eax, edx
    je   .done
.bad:
    mov  bl, 0
.done:
    jmp  0x18:leave
bits 16
leave:                              ; back to real mode, where the BIOS can print
    mov  eax, cr0
    and  al, 0xFE
    mov  cr0, eax
    jmp  0:real
real:
    xor  ax, ax
    mov  ds, ax
    mov  ss, ax
    test bl, bl
    jz   .no
    mov  al, 'O'
    call put
    mov  al, 'K'
    call put
    hlt
.no:
    mov  al, 'N'
    call put
    hlt
put:
    mov  ah, 0x0E
    int  0x10
    ret
align 8
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
    dq 0x00009A000000FFFF           ; 16-bit code, for the way back to real mode
gdtr:
    dw 31
    dd gdt
    TAIL
