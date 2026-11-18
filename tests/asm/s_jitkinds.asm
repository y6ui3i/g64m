; Self-check for the instructions that have no executor in the interpreter and that the JIT
; translates all the same (E073; the same answer with --jit and without): MOV between EAX and
; an address, LEAVE, PUSH of a constant and of a register or memory, XCHG between registers,
; BSWAP, CDQ, CLD and STD, a rotate by one, MOVSX, and MUL, IMUL, DIV and IDIV of EDX:EAX. A
; division by zero and one whose quotient does not fit fault, and the handler finds the
; registers as they were. The cases run on from one another in a few long blocks; EAX, EBX,
; EDX and EFLAGS are pushed after each and summed in EDI, with the word at `cell`, over three
; pairs of operands and twelve passes. BSWAP is the i686's. The sum expected is a trace
; run's. Prints "OK".
%define CPU686
%include "common.inc"
cell equ 0x5000                         ; not in this page: a store into a page of code drops its blocks
%assign CASES 0
%macro CASE 1-3
    mov  eax, ebp
    mov  edx, esi
    %1
    %2
    %3
    pushfd
    push eax
    push ebx
    push edx
%assign CASES CASES + 1
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
    mov  esp, 0x7000
    mov  dword [0x8000], 0x00080000 + de            ; the divide error's gate: selector 8, offset de
    mov  dword [0x8004], 0x00008E00
    xor  edi, edi
    mov  ecx, 12
pass:
    push ecx
    mov  ecx, vals
each:
    mov  ebp, [ecx]
    mov  esi, [ecx+4]                   ; EBP and ESI: this pair of operands
    mov  ebx, esi
    mov  [cell], ebp
    CASE {mov eax, [cell]}, {xchg eax, ebx}
    CASE {mov [cell], eax}, {xchg ebx, edx}
    CASE {bswap eax}, {cdq}
    CASE {push 0x12345678}, {push byte -3}          ; what these four push is summed with the rest
    CASE {db 0xFF, 0xF0}, {push dword [cell]}       ; push eax, the long way
    CASE {std}, {rol ebx, 1}
    CASE {cld}, {ror eax, 1}
    CASE {movsx ebx, ah}, {movsx edx, word [cell]}
    CASE {movsx eax, dx}, {movsx ebx, byte [cell+1]}
    CASE {mul ebx}
    CASE {imul dword [cell]}
    CASE {xor edx, edx}, {or ebx, 1}, {div ebx}
    CASE {cdq}, {or ebx, 1}, {idiv ebx}
    CASE {xor ebx, ebx}, {div ebx}      ; by zero: faults
    CASE {mov ebx, esi}, {mov edx, esi}, {div ebx}  ; EDX not below the divisor: the quotient does not fit
    CASE {mov ebx, esi}, {mov edx, esi}, {idiv ebx} ; nor does this one
    push ebp                            ; LEAVE: EBP from what is pushed here, ESP from EBP
    mov  ebp, esp
    sub  esp, 12
    leave
    lea  edi, [edi+edi*2]
    add  edi, ebp
    add  edi, [cell]
    mov  edx, 4 * CASES + 4
.fold:
    pop  eax
    lea  edi, [edi+edi*2]
    add  edi, eax
    dec  edx
    jnz  .fold
    add  ecx, 8
    cmp  ecx, vals + 24
    jne  each
    pop  ecx
    dec  ecx
    jnz  pass
    jmp  0x18:leave16
de:                                     ; sums EAX and EDX as it finds them, and goes on after the two-byte division
    lea  edi, [edi+edi*2]
    add  edi, eax
    add  edi, edx
    add  dword [esp], 2
    iretd
bits 16
leave16:                                ; back to real mode, where the BIOS can print
    mov  eax, cr0
    and  al, 0xFE
    mov  cr0, eax
    jmp  0:real
real:
    xor  ax, ax
    mov  ds, ax
    mov  ss, ax
    lidt [ridtr]
    cmp  edi, 0x7298AD28                ; from a trace run, one instruction at a time
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
    dd 0x7FFFFF81, 0x00000003, 0x80000104, 0xFFFFFF7F, 0x12345678, 0x9ABCDE1F
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
