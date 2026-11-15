; Self-check for an instruction that reads its operand and writes it back, on a page that may
; be read and not written. Such an instruction finds its place in memory with one look in the
; TLB, and that has to be the look a write makes: after a plain read of the page has put it in
; the read TLB, ADD to it and INC of it must still take a page fault. The write-protect bit in
; CR0 makes that true in ring 0, so this runs on the i686. The page at 20000h is read-only;
; everything else in the first 4 MB is mapped as it lies. Four passes. Prints "OK".
%define CPU686
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
    mov  dword [0x8000 + 14*8], 0x00080000 + pf     ; the #PF gate: selector 8, offset pf
    mov  dword [0x8000 + 14*8 + 4], 0x00008E00
    mov  edi, 0x11000                   ; one page table: the first 4 MB as they lie
    mov  eax, 3
    mov  ecx, 1024
.fill:
    stosd
    add  eax, 0x1000
    dec  ecx
    jnz  .fill
    and  dword [0x11000 + 0x20*4], ~2   ; 20000h: not writable
    mov  dword [0x10000], 0x11003       ; the page directory's first entry
    mov  eax, 0x10000
    mov  cr3, eax
    mov  eax, cr0
    or   eax, 0x80010000                ; paging, and write protection in ring 0
    mov  cr0, eax
    xor  edx, edx                       ; counts the faults
    mov  esi, 0x20000
    mov  ebp, 4
pass:
    mov  eax, [esi]                     ; a read: no fault, and the read TLB has the page
    mov  ebx, .r1
    add  [esi], eax                     ; #PF
.r1:
    mov  ebx, .r2
    inc  dword [esi+4]                  ; #PF
.r2:
    mov  ebx, .r3
    sub  dword [esi+8], 1               ; #PF
.r3:
    add  [0x21000], eax                 ; the next page is writable: no fault
    dec  ebp
    jnz  pass
    mov  eax, cr0
    and  eax, 0x7FFEFFFF
    mov  cr0, eax
    jmp  0x18:leave
pf:                                     ; counts, and resumes at the address in EBX
    inc  edx
    mov  [esp+4], ebx
    add  esp, 4
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
    cmp  edx, 12                        ; three faults a pass
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
