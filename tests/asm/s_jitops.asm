; Self-check for the instructions the JIT's blocks know beyond MOV and the 32-bit arithmetic
; between registers (E062; the same answer with --jit and without): the 8-bit moves, tests and
; arithmetic, shifts by a constant and by CL, rotates, the arithmetic to memory, INC, DEC, NOT
; and NEG of memory, ADC and SBB, SETCC, and a conditional jump on flags that only EFLAGS has.
; Each case is a block between a CLD, after which a run begins, and a PUSHFD; EFLAGS and EBX
; are pushed after each and summed in EDI, with the word of memory at `cell` that the cases
; change one after another, over three pairs of operands and twelve passes. The sum expected is a trace run's. Prints "OK".
%define CPU386
%include "common.inc"
cell equ 0x5000                         ; not in this page: a store into a page of code drops its blocks
%assign CASES 0
%macro CASE 1+
    cld
    nop
    %1
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
    mov  ebx, eax
    mov  [cell], edx
    mov  ecx, edx
    CASE mov bh, al
    CASE mov bl, dh
    CASE mov [cell+1], bl
    CASE mov bl, [cell+2]
    CASE test bl, dh
    CASE test bh, 0x81
    CASE add bl, dh
    CASE sub bh, dl
    CASE add [cell], bl
    CASE shl ebx, 3
    CASE shr ebx, 1
    CASE sar ebx, 6
    CASE shl ebx, cl
    CASE sar ebx, cl
    test eax, eax                       ; OF clear, then a shift by CL that sets it when CL is one
    cld
    mov  ebx, 0x40000000
    shl  ebx, cl
    pushfd
    push ebx
%assign CASES CASES + 1
    cld                                 ; a rotate that sets OF
    mov  ebx, 0x02000000
    rol  ebx, 7
    pushfd
    push ebx
%assign CASES CASES + 1
    CASE rol ebx, 1
    CASE ror ebx, 1
    CASE add [cell], ebx
    CASE sub dword [cell], 0x1234567
    CASE xor [cell], edx
    CASE inc dword [cell]
    CASE not dword [cell]
    CASE neg dword [cell]
    CASE shr dword [cell], 3
    stc
    CASE adc ebx, edx
    stc
    CASE sbb ebx, [cell]
    stc
    CASE adc [cell], ebx
    CASE setc bl
    CASE setle [cell+3]
    CASE setns bh
    cld                                 ; a condition from the block's own flags
    cmp  ebx, edx
    setl bl
    pushfd
    push ebx
%assign CASES CASES + 1
    cld
    test ebx, edx
    setnz bh
    pushfd
    push ebx
%assign CASES CASES + 1
    cmp  ebx, edx                       ; flags that only EFLAGS has when the block begins
    cld
    mov  ecx, ecx
    jl   .over
    inc  edi
.over:
    lea  edi, [edi+edi*2]
    add  edi, [cell]
    mov  ecx, 2 * CASES
.fold:
    pop  eax
    lea  edi, [edi+edi*2]
    add  edi, eax
    dec  ecx
    jnz  .fold
    cmp  esi, vals + 24
    jne  each
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
    cmp  edi, 0x814F34F0                ; from a trace run, one instruction at a time
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
    dd 0x7FFFFF81, 0x00000001, 0x80000104, 0xFFFFFF7F, 0x12345678, 0x9ABCDE1F
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
