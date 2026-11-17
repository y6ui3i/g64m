; Self-check for the JIT's blocks (E059; run with --jit, and without it the same answer). A
; block is instructions that touch no memory, from where a run begins to a jump or to an
; instruction the translator leaves alone. Each case here is such a block between a CLD, which
; the general path runs, so that a run begins after it, and either a PUSHFD, where the block
; ends and EFLAGS has to have been written out, or a conditional jump on flags that the block
; itself set. EFLAGS and EBX after each case, and whether its jump was taken, are summed in
; EDI over three pairs of operands and twelve passes (a block is made at the eighth
; arrival). The sum expected is a trace run's, one instruction at a time. Prints "OK".
%define CPU386
%include "common.inc"
%assign CASES 0
%macro CASE 1+                          ; an instruction (after a NOP: a block is two at least)
    cld
    nop
    %1
    pushfd
    push ebx
%assign CASES CASES + 1
%endmacro
%macro JCASE 2+                         ; a condition, and the instruction that sets it
    cld
    %2
    j%1  %%over
    inc  edi
%%over:
    pushfd
    push ebx
%assign CASES CASES + 1
%endmacro
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
    mov  ss, ax
    mov  esp, 0x7000
    xor  edi, edi
    mov  ebp, 12
pass:
    mov  esi, vals
each:
    lodsd
    xchg eax, edx
    lodsd                               ; EDX and EAX: this pair of operands
    CASE mov ebx, eax
    CASE add ebx, edx
    CASE sub ebx, edx
    CASE and ebx, edx
    CASE or  ebx, edx
    CASE xor ebx, edx
    CASE cmp ebx, edx
    CASE test ebx, edx
    cld                                 ; a block more than fifteen bytes long, whose last
    mov  ecx, 0x11111111                ; instruction is changed in place half way: the store
    mov  ecx, 0x22222222                ; is too far from the block's first instruction to
    mov  ecx, 0x33333333                ; empty its entry, and the block has to go all the same
patch:
    add  ebx, 0x7FFFFFF0
    pushfd
    push ebx
%assign CASES CASES + 1
    CASE sub ebx, 0x21
    CASE inc ebx
    CASE dec ebx
    CASE lea ebx, [eax+edx*4+0x11]
    CASE lea ebx, [edx*4]
    CASE mov ecx, 0x80000000
    CASE add ebx, ecx
    stc
    CASE inc ebx                        ; INC and DEC leave CF, here set
    stc
    CASE dec ebx
    cld                                 ; INC after a SUB in one block: CF is the SUB's
    sub  ebx, edx
    inc  ebx
    pushfd
    push ebx
%assign CASES CASES + 1
    mov  eax, [esi-4]
    JCASE c,  add ebx, edx
    JCASE o,  add ebx, ebx
    JCASE s,  add ebx, edx
    JCASE le, add ebx, edx
    JCASE z,  inc ebx
    JCASE l,  inc ebx
    JCASE s,  xor ebx, edx
    JCASE le, or  ebx, eax
    JCASE a,  sub ebx, edx
    JCASE b,  sub ebx, eax
    JCASE ge, sub ebx, edx
    JCASE be, add ebx, edx              ; not to be had from an ADD: the block ends before the jump
    JCASE p,  and ebx, edx              ; nor parity
    mov  ecx, 2 * CASES                 ; EFLAGS and EBX after each case, folded into EDI
.fold:
    pop  eax
    lea  edi, [edi+edi*2]
    add  edi, eax
    dec  ecx
    jnz  .fold
    cmp  esi, vals + 24
    jne  each
    cmp  ebp, 3
    jne  .same
    mov  byte [patch+2], 0x35           ; ADD EBX, 7FFFFFF0h becomes ADD EBX, 7FFFFF35h
.same:
    dec  ebp
    jnz  pass
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
    cmp  edi, 0x8F57E25D                ; from a trace run, one instruction at a time
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
vals:
    dd 0x7FFFFFFF, 1, 0x80000000, 0xFFFFFFFF, 0x12345678, 0x12345678
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
