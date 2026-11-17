; Self-check for the flags' record kept from one block of the JIT's to the next (E070; the
; same answer with --jit and without). A block that ends leaves the operands and result of
; the instruction that set the flags last in host registers, with their kind, and EFLAGS is
; written out from them only where something needs it: where generated code is left (here,
; for PUSHFD), or where the next block has an instruction that keeps some of the old flags
; (INC, a shift, a rotate), reads one (ADC, SETcc, a conditional jump), or just goes on. Each
; case is an instruction that sets the flags, a JMP that ends its block, and what follows in
; the next; one of every kind of record, alone and before each kind of reader. EFLAGS and
; EBX are pushed after each and summed in EDI, over three pairs of operands and twelve
; passes. The sum expected is a trace run's. Prints "OK".
%define CPU386
%include "common.inc"
%assign CASES 0
%macro CASE 2-3 nop
    cld
    nop
    %1
    jmp  short %%next
%%next:
    %2
    %3
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
    CASE {xor ebx, edx}, {nop}              ; each kind of record, then out for PUSHFD
    CASE {add ebx, edx}, {nop}
    CASE {sub ebx, edx}, {nop}
    CASE {inc ebx}, {nop}
    CASE {dec ebx}, {nop}
    CASE {add bl, dh}, {nop}
    CASE {sub bl, dh}, {nop}
    CASE {shl ebx, 3}, {nop}
    CASE {shr ebx, 1}, {nop}
    CASE {add ebx, edx}, {adc ebx, edx}     ; the carry read
    CASE {sub bl, dh}, {adc ebx, edx}
    CASE {xor ebx, edx}, {sbb ebx, edx}
    CASE {sub ebx, edx}, {inc ebx}          ; the carry kept
    CASE {shr ebx, 1}, {dec ebx}
    CASE {add bl, dh}, {setc bl}, {mov eax, eax}
    CASE {dec ebx}, {seto bl}, {mov eax, eax}
    CASE {inc ebx}, {rol ebx, 3}            ; all but the carry and the overflow kept
    CASE {sub ebx, edx}, {ror ebx, 1}
    CASE {add ebx, edx}, {shl ebx, 4}       ; the overflow and the auxiliary carry kept
    CASE {shl ebx, 3}, {jnc short $+3}, {inc ebx} ; a conditional jump at the head of a block
    CASE {sub ebx, edx}, {jge short $+3}, {inc ebx}
    CASE {add ebx, edx}, {call back}, {mov eax, eax}  ; through a RET, which finds its block by the far way
    CASE {xor ebx, edx}, {add ebx, edx}, {rol ebx, 3} ; a record made and written out in the second block: none is left
    CASE {xor ebx, edx}, {sub ebx, edx}, {mov ecx, [0x4FFE]} ; a way out (a read across two pages) with the second block's record
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
back:
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
    cmp  edi, 0xED4E6EB0                ; from a trace run, one instruction at a time
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
