; Self-check for code whose linear and physical addresses differ (E044). The decode cache
; finds an instruction of 32-bit code by its physical address, and a run reckons in physical
; addresses; what the guest sees must still be linear. Two cases, each run four times and
; more, so that the executors run them:
;
; 1. One physical page at two linear addresses. `g` at 40000h is CALL to the next instruction,
;    POP EAX, RET: it returns its own linear address plus 5. The same page is also at 60000h.
;    EDI adds up what it returns: four times 40005h, then four times 60005h. (In case 2 EAX
;    is CR3's value, 10000h, sixteen times.)
; 2. Two physical pages in turn at one linear address. 70000h is 50000h (INC EDX, RET), then
;    51000h (INC EBX, RET), then each again: the entries for one must not run for the other.
;
; Prints "OK".
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
    mov  dword [0x40000], 0x000000E8    ; g: call +0 / pop eax / ret
    mov  dword [0x40004], 0x00C35800
    mov  word [0x50000], 0xC342         ; inc edx / ret
    mov  word [0x51000], 0xC343         ; inc ebx / ret
    mov  edi, 0x11000                   ; one page table: the first 4 MB as they lie
    mov  eax, 3
    mov  ecx, 1024
.fill:
    stosd
    add  eax, 0x1000
    dec  ecx
    jnz  .fill
    mov  dword [0x11000 + 0x60*4], 0x40003  ; 60000h is 40000h too
    mov  dword [0x10000], 0x11003       ; the page directory's first entry
    mov  eax, 0x10000
    mov  cr3, eax
    mov  eax, cr0
    or   eax, 0x80000000
    mov  cr0, eax
    xor  edi, edi
    xor  edx, edx
    xor  ebx, ebx
    mov  esi, 0x40000
    call four
    mov  esi, 0x60000
    call four
    mov  ebp, 0x50003
    mov  esi, 0x70000
again:
    mov  [0x11000 + 0x70*4], ebp        ; 70000h is the page in EBP
    mov  eax, cr3
    mov  cr3, eax
    call four
    xor  ebp, 0x1000                    ; the other page
    cmp  edx, ebx
    jne  again                          ; 4:0, 4:4 (go on), 8:4, 8:8
    cmp  edx, 8
    jne  again
    mov  eax, cr0
    and  eax, 0x7FFFFFFF
    mov  cr0, eax
    jmp  0x18:leave
four:                                   ; calls the code at ESI four times, adds EAX to EDI
    mov  ecx, 4
.l:
    call esi
    add  edi, eax
    dec  ecx
    jnz  .l
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
    cmp  ebx, 8
    jne  .no
    cmp  edi, 0x380028                  ; 4 * 40005h, 4 * 60005h, and 16 * 10000h from EAX in case 2
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
