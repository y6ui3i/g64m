; Self-check for stores into code (E044). An instruction of 32-bit code that the decode cache
; holds is run from its entry with no look at its bytes, so every way of storing into RAM has
; to take the entry away. `f` at 40000h is ADD EDX, 1 or ADD EBX, 1, and a RET; the two differ
; in the instruction's second byte. It is called four times, so that the cache has it and its
; executor runs it, then that byte is changed and it is called four times again; EDX and EBX
; count which one ran, and after every four calls both go into a sum in EDI that depends on
; the order (three times the sum, plus EDX, plus twice EBX), so that two wrong steps cannot
; make up for each other. The ways:
;
; a. a plain 32-bit store (the short path for a write, which a page with code is kept out of;
;    a store into a page not written before comes first, so that the translation for f's
;    page is not simply remembered from the last store but looked up, and must then not be
;    kept)
; b. an instruction that reads and writes its operand in place (XOR)
; b2. a store of one byte, the instruction's second
; c. a repeated string store, which is done a page at a time
; d. a store that begins in the page before
; e. twenty stores elsewhere in the page, after which the page counts as data and is written
;    by the short path again; then `f` runs again, and the next store has to be noticed again
;
; A trace cannot show this: tracing stops after every instruction and no entry is reused
; without the general path. Prints "OK".
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
    mov  es, ax
    mov  ss, ax
    mov  esp, 0x7000
    xor  edx, edx
    xor  ebx, ebx
    xor  esi, esi
    mov  dword [0x40000], 0xC301C283    ; f: add edx, 1 / ret
    call four                           ; EDX 4
    mov  eax, 0xC301C383                ; f with EBX
    mov  [0x41000], eax                 ; another page
    mov  [0x40000], eax                 ; a
    call four                           ; EBX 4
    xor  dword [0x40000], 0x100         ; b
    call four                           ; EDX 8
    mov  byte [0x40001], 0xC3           ; b2
    call four                           ; EBX 8
    mov  byte [0x40001], 0xC2
    call four                           ; EDX 12
    mov  eax, 0xC301C383
    mov  edi, 0x40000
    mov  ecx, 1
    rep stosd                           ; c
    call four                           ; EBX 12
    mov  dword [0x3FFFE], 0xC2830000    ; d: the last two bytes are f's first two
    call four                           ; EDX 16
    mov  ecx, 20
.e:
    mov  [0x40040], eax                 ; e: in f's page, away from f
    dec  ecx
    jnz  .e
    mov  [0x42000], eax                 ; another page again, then f's: by the short path now
    mov  [0x40040], eax
    call four                           ; EDX 20
    mov  eax, 0xC301C383
    mov  [0x40000], eax
    call four                           ; EBX 16
    jmp  0x18:leave
four:                                   ; calls f four times, then EDX and EBX go into the sum
    mov  ecx, 4
.l:
    mov  ebp, 0x40000
    call ebp
    dec  ecx
    jnz  .l
    lea  esi, [esi + esi*2]
    add  esi, edx
    lea  esi, [esi + ebx*2]
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
    cmp  esi, 0x12028                  ; the sum for 4:0 4:4 8:4 8:8 12:8 12:12 16:12 20:12 20:16
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
