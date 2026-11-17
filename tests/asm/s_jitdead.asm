; Self-check for the flags the JIT does not make (E071; the same answer with --jit and
; without). An instruction that keeps some of the old flags or reads the carry (a shift, a
; rotate, INC, DEC, IMUL, ADC, SBB) makes no flags at all where the block goes on to set all
; six before anything can see them, takes only the carry from the record of the instruction
; before where that is all it needs, and otherwise has EFLAGS written out first. Each case
; is one block between a CLD, after which a run begins, and a PUSHFD: the carry kept by INC
; and DEC, the carry read by ADC and SBB, flags that are never seen, and flags that are seen
; after an instruction that touches none. EFLAGS and EBX are pushed after each and summed in
; EDI with the word at `cell`. Then four blocks in which the instruction after the shift,
; the rotate, the INC or the ADC faults (ES ends below its operand): what the handler finds
; as EFLAGS has to be the shift's, not what was there before it. Three pairs of operands,
; twelve passes. The sum expected is a trace run's. Prints "OK".
%define CPU386
%include "common.inc"
cell equ 0x5000                         ; not in this page: a store into a page of code drops its blocks
%assign CASES 0
%macro CASE 2-3
    cld
    %1
    %2
    %3
    pushfd
    push ebx
%assign CASES CASES + 1
%endmacro
%macro FAULT 1
    mov  eax, %%after
    cmp  esi, esi                       ; ZF and PF, and the block ends
    jmp  short %%next
%%next:
    %1
    add  edx, [es:0x20000]              ; #GP: the handler sums EFLAGS and resumes at EAX
%%after:
%endmacro
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
    mov  ss, ax
    mov  al, 0x20
    mov  es, ax                         ; 64 KB
    mov  esp, 0x7000
    mov  dword [0x8000 + 13*8], 0x00080000 + gp     ; the #GP gate: selector 8, offset gp
    mov  dword [0x8000 + 13*8 + 4], 0x00008E00
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
    mov  ecx, eax
    CASE {sub ebx, edx}, {inc ebx}                  ; the carry kept
    CASE {add bl, dh}, {dec ebx}
    CASE {shr ebx, 1}, {inc ebx}
    CASE {add ebx, edx}, {adc ebx, edx}             ; the carry read
    CASE {sub ebx, edx}, {sbb ebx, edx}
    CASE {shr ebx, 1}, {adc ebx, edx}
    CASE {xor ebx, edx}, {adc ebx, edx}
    CASE {dec ebx}, {sbb ebx, edx}
    CASE {rol ebx, 3}, {add ebx, edx}               ; flags never seen
    CASE {shl ebx, 3}, {mov eax, eax}, {sub ebx, edx}
    CASE {shl ebx, cl}, {xor ebx, edx}
    CASE {inc ebx}, {rol eax, 1}, {add ebx, edx}
    CASE {imul ebx, edx}, {add ebx, edx}
    CASE {adc ebx, edx}, {add ebx, edx}
    CASE {shl ebx, 1}, {adc ebx, edx}, {add ebx, edx}   ; seen by the ADC, whose own are not
    CASE {shr dword [cell], 3}, {add ebx, edx}
    CASE {dec dword [cell]}, {sub ebx, edx}
    CASE {shl ebx, 3}, {mov eax, ebx}, {xchg cl, dl} ; flags seen after an instruction that touches none, and after one with no executor
    FAULT {shl ebx, 1}
    FAULT {rol ebx, 1}
    FAULT {inc ebx}
    FAULT {adc ebx, edx}
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
gp:                                     ; sums the arithmetic flags in its frame, resumes at EAX
    add  esp, 4
    mov  [esp], eax
    mov  eax, [esp+8]
    and  eax, 0x8D5
    lea  edi, [edi+edi*2]
    add  edi, eax
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
    cmp  edi, 0x9045FD50                ; from a trace run, one instruction at a time
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
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
    dq 0x00009A000000FFFF               ; 16-bit code
    dq 0x000092000000FFFF               ; data, 64 KB
gdtr:
    dw 39
    dd gdt
idtr:
    dw 15*8 - 1
    dd 0x8000
ridtr:
    dw 0x3FF
    dd 0
    TAIL
