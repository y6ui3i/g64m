; REPNE SCASB and REPE SCASB, which scan a page at a time: a match in the first page, in the
; page after it, at the last byte the count allows, none at all, a count of zero, and the
; opposite condition; and, with paging on, a match on a page that follows in linear addresses
; and not in memory. The registers and flags after each are what the trace compares.
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
    cld
    mov  edi, 0x8F00                    ; 8F00h..90FFh: 'a', with marks placed below
    mov  ecx, 0x200
    mov  al, 'a'
    rep  stosb
    mov  byte [0x8F10], 'x'             ; in the first page
    mov  byte [0x9003], 'y'             ; in the next
    mov  byte [0x8FFF], 'z'             ; the last byte of the first page
    mov  byte [0x9000], 'w'             ; the first byte of the next

    mov  al, 'x'
    mov  edi, 0x8F00
    mov  ecx, 0x200
    repne scasb                         ; stops after 8F10h
    mov  al, 'y'
    mov  edi, 0x8FF0
    mov  ecx, 0x200
    repne scasb                         ; crosses into the next page, stops after 9003h
    mov  al, 'z'
    mov  edi, 0x8FF0
    mov  ecx, 0x10
    repne scasb                         ; the match is the last byte the count allows
    mov  al, 'w'
    mov  edi, 0x8FF0
    mov  ecx, 0x11
    repne scasb                         ; the match is the first byte of the next page
    mov  al, 'q'
    mov  edi, 0x8F20
    mov  ecx, 0x40
    repne scasb                         ; no match: the count runs out
    mov  al, 'x'
    mov  edi, 0x8F00
    xor  ecx, ecx
    cmp  al, al                         ; ZF set, to see that nothing changes it
    repne scasb                         ; a count of zero: nothing happens
    mov  al, 'a'
    mov  edi, 0x8F00
    mov  ecx, 0x200
    repe scasb                          ; stops after the first byte that is not 'a': 8F10h
    mov  al, 'a'
    mov  edi, 0x8F11
    mov  ecx, 0x20
    repe scasb                          ; all equal: the count runs out
    mov  al, 0x80
    mov  edi, 0x8F00
    mov  ecx, 3
    repne scasb                         ; the flags of 80h against 'a' (61h): overflow

    ; With paging: the page after 8000h is somewhere else in memory, so a scan that ran on
    ; through physical memory, and not page by page, would look at the wrong bytes.
    mov  edi, 0x11000                   ; one page table: the first 4 MB as they lie
    mov  eax, 3
    mov  ecx, 1024
.fill:
    stosd
    add  eax, 0x1000
    dec  ecx
    jnz  .fill
    mov  byte [0x30002], 'p'            ; what will be at 9002h
    mov  dword [0x11000 + 9*4], 0x30003 ; 9000h is the page at 30000h
    mov  dword [0x10000], 0x11003       ; the page directory's first entry
    mov  eax, 0x10000
    mov  cr3, eax
    mov  eax, cr0
    or   eax, 0x80000000
    mov  cr0, eax
    mov  al, 'p'
    mov  edi, 0x8FF0
    mov  ecx, 0x200
    repne scasb                         ; stops after 9002h
    hlt
align 8
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
gdtr:
    dw 23
    dd gdt
    TAIL
