; Self-check that ring 3 does not get a page through ring 0's entry in the TLB (E090). The
; TLB keeps the two privilege levels in two halves, and where the user's half begins moved
; when the TLB grew: an index into it made the old way lands, for a page whose number has
; bit 8 set, on ring 0's entry for the same page. The first 4 MB are mapped as they lie,
; for all, but 370000h, which is the supervisor's. Ring 0 reads it. Ring 3 then runs a loop
; forty times (enough for the JIT) that reads a page of its own, and on the last pass reads
; 370000h: that must be a page fault with error code 5 and CR2 = 370000h. If it is not,
; ring 3 comes to a HLT, which is a general protection fault. Prints "OK".
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
    mov  dword [0x8000 + 13*8], 0x00080000 + gp     ; the #GP gate: selector 8, offset gp
    mov  dword [0x8000 + 13*8 + 4], 0x00008E00
    mov  dword [0x8000 + 14*8], 0x00080000 + pf     ; the #PF gate
    mov  dword [0x8000 + 14*8 + 4], 0x00008E00
    mov  dword [0x9004], 0x6000         ; the TSS at 9000h: the stack for ring 0
    mov  dword [0x9008], 0x10
    mov  ax, 0x30
    ltr  ax
    mov  edi, 0x11000
    mov  eax, 7
    mov  ecx, 1024
.fill:
    stosd
    add  eax, 0x1000
    dec  ecx
    jnz  .fill
    mov  dword [0x10000], 0x11007
    mov  dword [0x11000 + 0x370*4], 0x50003         ; 370000h: the supervisor's
    mov  eax, 0x10000
    mov  cr3, eax
    mov  eax, cr0
    or   eax, 0x80000000
    mov  cr0, eax
    mov  esi, ucode                     ; ring 3's code, to 30000h
    mov  edi, 0x30000
    mov  ecx, ucode_end - ucode
    rep movsb
    mov  eax, [0x370000]                ; ring 0's entry for the page
    mov  ax, 0x2B                       ; to ring 3 with its data segment
    mov  ds, ax
    push dword 0x2B
    push dword 0x5000
    push dword 2
    push dword 0x23
    push dword 0x30000
    iretd
ucode:                                  ; runs at 30000h; nothing in it depends on where it is
    mov  ecx, 40
    mov  esi, 0x40000
    jmp  short .l
.b:
    cld                                 ; for the general path: what follows begins a run,
    jmp  short .l                       ; and so the JIT comes to count arrivals at .l
.l:
    mov  eax, [esi]
    add  ebx, eax
    cmp  ecx, 2
    jne  .s
    mov  esi, 0x370000                  ; the last pass reads what it may not
.s:
    dec  ecx
    jnz  .b
    hlt
ucode_end:
pf:
    mov  ax, 0x10
    mov  ds, ax
    pop  eax                            ; the error code
    mov  edx, cr2
    cmp  eax, 5                         ; a user's read of a page that is there
    jne  gp
    cmp  edx, 0x370000
    jne  gp
    cmp  ecx, 1                         ; on the last pass
    jne  gp
    mov  ecx, 0x600D
    jmp  out
gp:                                     ; ring 3's HLT, or a fault that is not the one
    mov  ax, 0x10
    mov  ds, ax
    xor  ecx, ecx
out:
    mov  eax, cr0
    and  eax, 0x7FFFFFFF
    mov  cr0, eax
    jmp  0x18:leave
bits 16
leave:
    mov  eax, cr0
    and  al, 0xFE
    mov  cr0, eax
    jmp  0:real
real:
    xor  ax, ax
    mov  ds, ax
    mov  ss, ax
    lidt [ridtr]
    cmp  ecx, 0x600D
    jne  .no
    mov  ax, 0x0E4F
    int  0x10
    mov  ax, 0x0E4B
    int  0x10
    hlt
.no:
    mov  ax, 0x0E4E
    int  0x10
    hlt
align 8
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
    dq 0x00009A000000FFFF               ; 16-bit code
    dq 0x00CFFA000000FFFF               ; ring 3's code
    dq 0x00CFF2000000FFFF               ; ring 3's data
    dq 0x0000890090000067               ; the TSS at 9000h
gdtr:
    dw 55
    dd gdt
idtr:
    dw 15*8 - 1
    dd 0x8000
ridtr:
    dw 0x3FF
    dd 0
    TAIL
