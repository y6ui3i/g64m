; Self-check for an access that crosses from one page into the next, where the two pages are
; not next to each other in RAM. The short path of a memory access finds the page in the TLB
; and then reads or writes RAM directly, which is only right when the whole access is in that
; page; it tells by comparing the TLB's tag with the page of the access's last byte (E051).
; 31000h is mapped to 40000h, so an access at 30FFEh has its first two bytes at 30FFEh in
; RAM and its last two at 40000h, not at 31000h. A 32-bit load, a 32-bit store, an ADD to
; memory and a 16-bit load and store, each checked against loads that do not cross. Four
; passes, so that the last ones run from the decode cache. Prints "OK".
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
    mov  dword [0x30FFC], 0x11223344
    mov  dword [0x31000], 0xAAAAAAAA    ; behind 30000h in RAM; never to be read or written again
    mov  dword [0x40000], 0x55667788
    mov  edi, 0x11000                   ; one page table: the first 4 MB as they lie
    mov  eax, 3
    mov  ecx, 1024
.fill:
    stosd
    add  eax, 0x1000
    dec  ecx
    jnz  .fill
    mov  dword [0x11000 + 0x31*4], 0x40003  ; but 31000h is at 40000h
    mov  dword [0x10000], 0x11003       ; the page directory's first entry
    mov  eax, 0x10000
    mov  cr3, eax
    mov  eax, cr0
    or   eax, 0x80000000
    mov  cr0, eax
    xor  edx, edx                       ; counts the passes that went right
    mov  esi, 0x30FFE
    mov  ecx, 0x01020304
    mov  ebp, 4
pass:
    mov  eax, [0x30000]                 ; the TLB has the page, for reading
    mov  [0x30000], eax                 ; and for writing
    mov  eax, [esi]                     ; a load that crosses
    call halves
    cmp  eax, ebx
    jne  .bad
    mov  [esi], ecx                     ; a store that crosses
    call halves
    cmp  ebx, ecx
    jne  .bad
    add  [esi], ecx                     ; read, add, write
    call halves
    lea  eax, [ecx+ecx]
    cmp  ebx, eax
    jne  .bad
    mov  ax, [esi+1]                    ; 16 bits across the boundary
    shr  ebx, 8
    cmp  ax, bx
    jne  .bad
    not  ax
    mov  [esi+1], ax
    call halves
    shr  ebx, 8
    cmp  ax, bx
    jne  .bad
    inc  edx
.bad:
    add  ecx, 0x10101010
    dec  ebp
    jnz  pass
    mov  eax, cr0
    and  eax, 0x7FFFFFFF
    mov  cr0, eax
    cmp  dword [0x31000], 0xAAAAAAAA    ; the page that lies behind 30000h in RAM: untouched
    je   .out
    xor  edx, edx
.out:
    jmp  0x18:leave
halves:                                 ; EBX = the four bytes at 30FFEh, by loads that do not cross
    mov  ebx, [0x30FFC]
    shr  ebx, 16
    mov  edi, [0x40000]
    shl  edi, 16
    or   ebx, edi
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
    lidt [ridtr]
    cmp  edx, 4                         ; four passes, every comparison right, 31000h in RAM untouched
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
