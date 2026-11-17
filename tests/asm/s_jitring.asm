; Self-check for the privilege level in the JIT's memory operands (E061; the same answer with
; --jit and without). The TLB has entries for the supervisor and entries for the user, and a
; block's inline path has to look at the half that the current level uses. 31000h is the
; supervisor's page. Ring 0 reads it, so the supervisor's half of the TLB has it; then ring 3
; runs a block that loads from it, which must leave for the interpreter and take a page
; fault, every time: twelve times, the block being made at the eighth. Prints "OK".
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
    mov  dword [0x8000 + 14*8], 0x00080000 + pf     ; the #PF gate: selector 8, offset pf
    mov  dword [0x8000 + 14*8 + 4], 0x00008E00
    mov  dword [0x8000 + 13*8], 0x00080000 + gp     ; the #GP gate
    mov  dword [0x8000 + 13*8 + 4], 0x00008E00
    mov  dword [0x9004], 0x6000         ; the TSS at 9000h: the stack for ring 0
    mov  dword [0x9008], 0x10
    mov  ax, 0x30
    ltr  ax
    mov  edi, 0x11000                   ; one page table: the first 4 MB as they lie, for all
    mov  eax, 7
    mov  ecx, 1024
.fill:
    stosd
    add  eax, 0x1000
    dec  ecx
    jnz  .fill
    and  dword [0x11000 + 0x31*4], ~4   ; 31000h: the supervisor's
    mov  dword [0x10000], 0x11007       ; the page directory's first entry
    mov  eax, 0x10000
    mov  cr3, eax
    mov  eax, cr0
    or   eax, 0x80000000
    mov  cr0, eax
    mov  dword [0x30000], 0x36C089FC    ; ring 3's code: cld / mov eax, eax /
    mov  dword [0x30004], 0x1000158B    ; mov edx, [ss:31000h] / hlt
    mov  dword [0x30008], 0x00F40003    ; (through SS: DS is emptied on the way to ring 3)
    xor  edx, edx                       ; counts the page faults from ring 3
    mov  ebp, 12
again:
    mov  ax, 0x10                       ; DS was emptied on the way to ring 3
    mov  ds, ax
    mov  esp, 0x7000
    mov  eax, [0x31000]                 ; ring 0 reads its page: the supervisor's TLB has it
    push dword 0x2B                     ; to ring 3: SS, ESP, the flags, CS, EIP
    push dword 0x5000
    push dword 2
    push dword 0x23
    push dword 0x30000
    iretd
gp:                                     ; ring 3 got as far as its HLT: the load did not fault
    mov  edx, 0x100
    jmp  done
pf:
    inc  edx
    dec  ebp
    jnz  again
done:
    mov  ax, 0x10
    mov  ds, ax
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
    cmp  edx, 12                        ; ring 3's load faulted every time
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
