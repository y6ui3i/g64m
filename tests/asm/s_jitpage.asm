; Self-check for the JIT going from one block to the next (E059, E060; the same answer with
; --jit and without). Blocks are found by the physical address of their first instruction,
; and when one block ends the next is looked for at the address it jumped to. That address is
; a physical one only inside the page the run is on: beyond it, it is the linear address less
; what this page's linear address is above its physical one, and whatever block is at that
; number is some other code. Here a block at 32001h jumps back to 31010h, which is mapped to
; 40010h; at 31010h in RAM, reached through 50010h, is a block of other instructions, made
; and run before. (Back, not forward: a block in a page above is refused anyway, for lying
; beyond where the run may go.) After the first block the second must not be run: ESI is counted at 40010h
; and EDI at 31010h, and each has to come out twice the passes. Prints "OK".
%define CPU386
%include "common.inc"
start:
    cli
    xor  ax, ax
    mov  ds, ax
    lgdt [gdtr]
    lidt [idtr]
    mov  eax, cr0
    or   al, 1
    mov  cr0, eax
    jmp  0x08:pm
bits 32
pm:
    mov  ax, 0x10
    mov  ds, ax
    mov  es, ax
    mov  ss, ax
    mov  esp, 0x7000
    mov  dword [0x32000], 0xE9C089FC    ; 32000h: cld / mov eax, eax / jmp 31010h
    mov  dword [0x32004], 0xFFFFF008
    mov  dword [0x40010], 0x00C34646    ; 40010h (31010h when mapped): inc esi / inc esi / ret
    mov  dword [0x3100C], 0xFC909090    ; 3100Fh in RAM (5000Fh when mapped): cld /
    mov  dword [0x31010], 0x00C34747    ; inc edi / inc edi / ret
    mov  edi, 0x11000                   ; one page table: the first 4 MB as they lie
    mov  eax, 3
    mov  ecx, 1024
.fill:
    stosd
    add  eax, 0x1000
    dec  ecx
    jnz  .fill
    mov  dword [0x11000 + 0x31*4], 0x40003  ; but 31000h is at 40000h
    mov  dword [0x11000 + 0x50*4], 0x31003  ; and 50000h at 31000h
    mov  dword [0x10000], 0x11003       ; the page directory's first entry
    mov  eax, 0x10000
    mov  cr3, eax
    mov  eax, cr0
    or   eax, 0x80000000
    mov  cr0, eax
    xor  esi, esi
    xor  edi, edi
    mov  ebp, 12
pass:
    mov  eax, 0x5000F
    call eax                            ; the block in RAM at 31010h: EDI twice
    mov  eax, 0x32000
    call eax                            ; the block at 32001h, then on to 31010h: ESI twice
    dec  ebp
    jnz  pass
    xor  edx, edx
    cmp  esi, 24
    jne  .bad
    cmp  edi, 24
    jne  .bad
    mov  edx, 4
.bad:
    mov  eax, cr0
    and  eax, 0x7FFFFFFF
    mov  cr0, eax
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
    lidt [ridtr]
    cmp  edx, 4                         ; both counts right
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
idtr:
    dw 15*8 - 1
    dd 0x8000
ridtr:
    dw 0x3FF
    dd 0
    TAIL
