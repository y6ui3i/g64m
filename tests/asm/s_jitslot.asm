; Self-check for a block whose entry in the decode cache is lost and comes back (E063; the
; same answer with --jit and without). Two instructions whose addresses are 20000h apart want
; the same slot of the decode cache, and each drives the other out. A block is made for the
; code at 30001h; the code at 50001h is then run, which takes the slot; when 30001h is run
; again its entry is made anew, and when that entry is classified the JIT gives it its block
; back. The run that classified it must not go on to execute the entry by its kind, which is
; now "a block". ESI and EDI count what each piece of code did. Prints "OK".
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
    mov  dword [0x30000], 0xC34646FC    ; 30000h: cld / inc esi / inc esi / ret
    mov  dword [0x50000], 0xC34747FC    ; 50000h: cld / inc edi / inc edi / ret
    xor  esi, esi
    xor  edi, edi
    mov  ebx, 0x30000
    mov  ecx, 0x50000
    mov  ebp, 12
.first:                                 ; twelve times: the block at 30001h is made
    call ebx
    dec  ebp
    jnz  .first
    mov  ebp, 3
.turns:                                 ; then, three times over: the other code takes the slot,
    call ecx
    call ecx
    call ebx                            ; the first code's entry is made anew,
    call ebx                            ; classified, and given its block back,
    call ebx                            ; and the block is run
    dec  ebp
    jnz  .turns
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
    cmp  esi, 42                        ; twenty-one calls of the first code
    jne  .no
    cmp  edi, 12                        ; six of the second
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
