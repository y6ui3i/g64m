; Self-check for the JIT's memory operands (E061; the same answer with --jit and without). A
; block reads and writes memory by the short path generated inline, and leaves, before the
; instruction, where an access is not on that path. Blocks, each begun by a CLD, with loads,
; stores, arithmetic and a comparison from memory, MOVZX, PUSH and POP, and a CALL to a
; routine that ends in RET; among their accesses
;   - two that cross from 30000h into the next page, which is mapped elsewhere (40000h):
;     the block must leave for each, with what it has done so far in place;
;   - a store (from a second block) into a page of code, 50000h, into the operand of an
;     instruction there that is run next: the block must leave for it, so that the store is
;     noticed and the instruction decoded again;
;   - a load from 60000h, which half way through the passes is made not present: the page
;     fault's handler makes it present again, and the load is done over.
; Everything is summed in EDI over sixteen passes; the sum expected is a trace run's, one
; instruction at a time. Prints "OK".
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
    mov  dword [0x30FF8], 0x11223344
    mov  dword [0x30FFC], 0x55667788
    mov  dword [0x40000], 0x99AABBCC
    mov  dword [0x60000], 0x0BADF00D
    mov  dword [0x50000], 0x345678B8    ; 50000h: mov eax, 12345678h / ret
    mov  dword [0x50004], 0x0000C312
    mov  edi, 0x11000                   ; one page table: the first 4 MB as they lie
    mov  eax, 3
    mov  ecx, 1024
.fill:
    stosd
    add  eax, 0x1000
    dec  ecx
    jnz  .fill
    mov  dword [0x11000 + 0x31*4], 0x40003  ; but 31000h is at 40000h
    mov  dword [0x11000 + 0x130*4], 0x50003 ; and 130000h at 50000h
    mov  dword [0x10000], 0x11003       ; the page directory's first entry
    mov  eax, 0x10000
    mov  cr3, eax
    mov  eax, cr0
    or   eax, 0x80000000
    mov  cr0, eax
    xor  edi, edi
    mov  ebp, 16
pass:
    cld                                 ; a run begins after each CLD, and a block with the run
    mov  esi, 0x30FF8
    mov  eax, [esi]                     ; loads, arithmetic from memory, a store, in one page
    add  eax, [esi+4]
    add  eax, [0x40000]                 ; (what the store that crosses left in the next page)
    mov  [esi], eax
    movzx ecx, byte [esi+7]
    movzx edx, word [esi+5]
    add  ecx, edx
    push eax                            ; the stack
    push ecx
    pop  edx
    pop  ecx
    add  eax, edx
    cld
    cmp  [esi+4], eax                   ; flags from memory, then a load that crosses into the
    mov  ebx, [esi+6]                   ; next page: the block leaves, with the CMP's flags
    cld
    add  ecx, eax
    add  ecx, ebx
    mov  [esi+6], ecx                   ; a store that crosses, after a register was changed
    cld
    mov  edx, [0x130000]                ; a page that shares 30000h's place in the TLB, read
    cld                                 ; (by the interpreter: one instruction is no block)
    add  ecx, edx                       ; so the read TLB has that page there and the write
    mov  [esi], ecx                     ; TLB has 30000h: the store goes by the write TLB's
    cld
    mov  edx, [0x60000]                 ; not present from the eighth pass on
    add  eax, edx
    call tail
    mov  dword [esi+4], 0x0F0F0F0F      ; (two instructions after the RET: a block, which the
    nop                                 ; RET does not leave for through a link slot)
    pushfd                              ; the block ends here, the CMP's flags written out
    pop  ebx
    add  ebx, eax
    add  ebx, ecx
    add  ebx, edx
    lea  edi, [edi+edi*2]
    add  edi, ebx
    cld                                 ; a second block: a store into a page of code, the
    mov  ecx, ebp                       ; operand of the instruction at 50000h, then that
    mov  [0x50001], ecx                 ; instruction run
    mov  eax, 0x50000
    call eax
    add  edi, eax
    cmp  ebp, 9
    jne  .same
    and  dword [0x11000 + 0x60*4], ~1   ; 60000h: not present, and the TLB emptied
    mov  eax, cr3
    mov  cr3, eax
.same:
    dec  ebp
    jnz  pass
    mov  eax, cr0
    and  eax, 0x7FFFFFFF
    mov  cr0, eax
    jmp  0x18:leave
tail:
    add  edx, [esp]                     ; the return address, as the CALL pushed it
    xor  eax, edx
    cmp  eax, ecx                       ; flags for the PUSHFD after the return
    ret
pf:                                     ; makes 60000h present, and the instruction is done over
    or   dword [0x11000 + 0x60*4], 1
    push eax
    mov  eax, cr3
    mov  cr3, eax
    pop  eax
    add  esp, 4
    add  edi, 0x01000000                ; counted
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
    cmp  edi, 0xA32C523D                ; from a trace run, one instruction at a time
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
