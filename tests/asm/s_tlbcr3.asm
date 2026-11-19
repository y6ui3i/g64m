; Self-check that a write of CR3 forgets every page, for a page whose number does not fit in
; eight bits (E090: the TLB has 4,096 entries for each privilege level, found by the page
; number's low bits, and emptying it has to reach all of them). The first 4 MB are mapped as
; they lie. 370000h is pointed at 50000h and read and written; its entry is changed to
; 51000h and CR3 is written; it is read and written again. Twelve times over, for the JIT.
; What is read is summed, and what was written is looked for where it should have landed.
; In the same passes 372000h (52000h) is written with an instruction, called, written with
; another and called: a page that comes to hold code is taken out of the TLB for writes, at
; whatever index it is, so that the store into it is seen.
; Prints "OK".
%define CPU386
%include "common.inc"
start:
    cli
    xor  ax, ax
    mov  ds, ax
    mov  es, ax
    lgdt [gdtr]
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
    mov  edi, 0x11000                   ; a page table for the first 4 MB, as they are
    mov  eax, 7
.pt:
    stosd
    add  eax, 0x1000
    cmp  edi, 0x12000
    jb   .pt
    mov  dword [0x10000], 0x11007       ; and the directory
    mov  eax, 0x10000
    mov  cr3, eax
    mov  eax, cr0
    or   eax, 0x80000000
    mov  cr0, eax
    mov  dword [0x50000], 0x13579BDF
    mov  dword [0x51000], 0x2468ACE1
    mov  esi, 0x11000 + 0x370*4         ; the entry for 370000h
    mov  dword [esi + 8], 0x52007       ; 372000h
    xor  edx, edx
    xor  ebx, ebx
    mov  ebp, 0x372000
    xor  edi, edi                       ; the sum
    mov  ecx, 12
again:
    mov  dword [esi], 0x50007
    mov  eax, cr3
    mov  cr3, eax
    add  edi, [0x370000]                ; 50000h
    mov  [0x370004], ecx
    mov  dword [esi], 0x51007
    mov  eax, cr3
    mov  cr3, eax
    rol  edi, 1
    add  edi, [0x370000]                ; 51000h
    mov  [0x370008], ecx
    add  edi, [0x50004]                 ; what was written first: the count
    add  edi, [0x51008]                 ; and second
    add  edi, [0x50008]                 ; nothing was written here
    add  edi, [0x51004]                 ; nor here
    mov  word [ebp], 0xC342             ; inc edx / ret
    call ebp
    mov  byte [ebp], 0x43               ; inc ebx
    call ebp
    lea  edi, [edi + edx*4]
    add  edi, ebx
    dec  ecx
    jnz  again
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
    cmp  edi, 0x33340D4A                ; from a trace run, one instruction at a time
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
align 4
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
    dq 0x00009A000000FFFF               ; 16-bit code
gdtr:
    dw 31
    dd gdt
    TAIL
