; Self-check for a fault in the first instruction of a fused pair, and for the virtual time
; across pairs (E054). A flag-setting instruction and the conditional jump after it run as one
; executor. When the first of the two takes a page fault nothing of the pair has happened: the
; fault is reported against the first instruction, with the flags as they were, and the time
; has not moved on for either. One pair of each kind, its operand in a page that is not
; present, each after a CMP that leaves ZF and PF set and the rest clear; then two pairs that
; do not fault, one taken and one not. The handler checks the address and the flags in its
; frame. RDTSC before the first pass and after the last: the difference is the number of
; instructions between, which a trace run (one instruction at a time, no pairs) gives. Four
; passes. RDTSC is the i686's. Prints "OK".
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
    mov  esi, 0x20000
    and  dword [0x11000 + 0x20*4], ~1   ; 20000h: not present
    mov  dword [0x10000], 0x11003       ; the page directory's first entry
    mov  eax, 0x10000
    mov  cr3, eax
    mov  eax, cr0
    or   eax, 0x80010000                ; paging, and write protection in ring 0
    mov  cr0, eax
    xor  edx, edx                       ; counts the faults; bit 16 says something was wrong
    mov  eax, 0x80
    mov  ebp, 4
    rdtsc
    push eax
    mov  eax, 0x80
pass:
    mov  ebx, .r1
    cmp  esi, esi
    cmp  [esi], eax                     ; #PF
    jne  .r1
.r1:
    mov  ebx, .r2
    cmp  esi, esi
    test [esi], eax                     ; #PF
    jz   .r2
.r2:
    mov  ebx, .r3
    cmp  esi, esi
    cmp  dword [esi], 5                 ; #PF
    jb   .r3
.r3:
    mov  ebx, .r4
    cmp  esi, esi
    test byte [esi], 4                  ; #PF
    jnz  .r4
.r4:
    mov  ebx, .r5
    cmp  esi, esi
    test [esi], al                      ; #PF
    jz   .r5
.r5:
    cmp  eax, eax                       ; a pair whose jump is taken
    je   .a
.a:
    cmp  eax, esi                       ; and one whose jump is not
    je   .b
.b:
    dec  ebp
    jnz  pass
    mov  edi, edx                       ; RDTSC writes EDX
    rdtsc
    pop  ecx
    sub  eax, ecx
    mov  edx, edi
    cmp  eax, 0x148                       ; from a trace run, one instruction at a time
    je   .timed
    or   edx, 0x10000
.timed:
    mov  eax, cr0
    and  eax, 0x7FFEFFFF
    mov  cr0, eax
    jmp  0x18:leave
pf:                                     ; counts, checks the address and the flags, and resumes at the address in EBX
    mov  edi, ebx                       ; the fault is reported against the pair's first instruction:
    sub  edi, [esp+4]                   ; the pair's length, summed in EDX from bit 20 up
    shl  edi, 20
    add  edx, edi
    inc  edx
    mov  edi, [esp+12]
    and  edi, 0x8D5                     ; OF SF ZF AF PF CF
    cmp  edi, 0x44                      ; as the CMP left them
    je   .good
    or   edx, 0x10000
.good:
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
    cmp  edx, 20 + (4*22 << 20)         ; five faults a pass, 22 bytes of pairs, nothing wrong
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
