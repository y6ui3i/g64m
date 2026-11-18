; Self-check for the jumps the JIT cannot see the end of, and for CMOV (E087; the same answer
; with --jit and without). A CALL or a JMP through a register or through memory ends its
; block at the far way, which finds the block at the address when it runs: here to two
; functions in this page, to one in another page, and over instructions that must not run.
; The code segment's base is 1000h, so that an instruction pointer is not an address: what
; is called and jumped to are instruction pointers, 1000h below where the code is.
; CMOVcc on all sixteen conditions after a CMP, from a register and from memory, over three
; pairs of operands so that each is taken and not. Everything is summed in EDI, twelve
; passes. CMOV is the i686's. The sum expected is a trace run's. Prints "OK".
%define CPU686
%include "common.inc"
cell equ 0x5000
%define IP(x) ((x) - 0x1000)             ; an address in the code segment, as its instruction pointer
start:
    cli
    xor  ax, ax
    mov  ds, ax
    lgdt [gdtr]
    mov  eax, cr0
    or   al, 1
    mov  cr0, eax
    jmp  0x20:IP(pm)
bits 32
pm:
    mov  ax, 0x10
    mov  ds, ax
    mov  ss, ax
    mov  esp, 0x7000
    mov  dword [0x31010], 0x00C34747    ; a function in another page: inc edi / inc edi / ret
    xor  edi, edi
    mov  ebp, esp                       ; what CMOV from memory replaces, with the 0 at `cell`
    push 12                             ; the passes left
pass:
    push vals                           ; where this pass is in the operands
each:
    mov  esi, [esp]
    mov  eax, [esi]
    mov  edx, [esi+4]                   ; EAX and EDX: this pair of operands
    mov  esi, cell
    mov  ecx, esp
    mov  ebx, IP(f1)
    call ebx                            ; through a register
    call [tbl]                          ; through memory
    mov  ebx, IP(.j1)
    jmp  ebx
    add  edi, 100                       ; not run
.j1:
    jmp  [tbl+4]
    add  edi, 1000                      ; not run
j2:
    call [tbl+8]                        ; into another page and back
%macro CM 1
    cmp  eax, edx
    cmov%1 ebx, ecx
    cmov%1 ebp, [esi]
    add  edi, ebx
    add  edi, ebp
    rol  edi, 1
%endmacro
    CM o
    CM no
    CM b
    CM ae
    CM e
    CM ne
    CM be
    CM a
    CM s
    CM ns
    CM p
    CM np
    CM l
    CM ge
    CM le
    CM g
    add  dword [esp], 8
    cmp  dword [esp], vals + 24
    jne  each
    pop  eax
    dec  dword [esp]
    jnz  pass
    jmp  0x18:leave
f1:
    add  edi, eax
    ret
f2:
    xor  edi, edx
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
    cmp  edi, 0x02E86C01                ; from a trace run, one instruction at a time
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
tbl:
    dd IP(f2), IP(j2), IP(0x31010)
vals:
    dd 0x7FFFFF81, 0x00000003, 0x80000104, 0xFFFFFF7F, 0x12345678, 0x12345678
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
    dq 0x00009A000000FFFF               ; 16-bit code
    dq 0x00CF9A001000FFFF               ; 32-bit code from 1000h
gdtr:
    dw 39
    dd gdt
    TAIL
