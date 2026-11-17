; Self-check for a flag-setting instruction and the conditional jump after it run as one
; executor (E054). CMP r/m, r with each of the sixteen conditions; CMP r/m, imm, TEST r/m, r,
; TEST r/m8, imm8 and TEST r/m8, r8 with two each; CMP from memory with a near jump. Every
; jump that is not taken sets a bit in EBX, and the bits are summed in EDI over four pairs of
; operands and four passes, so that the last passes run from the decode cache as pairs. The
; sum expected is what the instructions give one at a time (a trace run, which never fuses).
; Then the last jump's condition is changed in place, from JNE to JE: the pair's entry begins
; at the CMP before it and must not go on running the old jump. Prints "OK".
%define CPU386
%include "common.inc"
%macro PAIR 2+                          ; a condition, then the instruction before the jump
    %2
    j%1  %%over
    inc  ebx
%%over:
    add  ebx, ebx
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
    mov  ebp, 8                         ; four passes, then four with the last jump changed
pass:
    mov  esi, vals
    mov  ecx, 4
each:
    lodsd
    xchg eax, edx
    lodsd                               ; EDX and EAX: this pair of operands
    xor  ebx, ebx
    PAIR o,   cmp eax, edx
    PAIR no,  cmp eax, edx
    PAIR b,   cmp eax, edx
    PAIR nb,  cmp eax, edx
    PAIR z,   cmp eax, edx
    PAIR nz,  cmp eax, edx
    PAIR be,  cmp eax, edx
    PAIR nbe, cmp eax, edx
    PAIR s,   cmp eax, edx
    PAIR ns,  cmp eax, edx
    PAIR p,   cmp eax, edx
    PAIR np,  cmp eax, edx
    PAIR l,   cmp eax, edx
    PAIR nl,  cmp eax, edx
    PAIR le,  cmp eax, edx
    PAIR nle, cmp eax, edx
    PAIR b,   cmp eax, 6
    PAIR g,   cmp eax, 6
    PAIR z,   test eax, edx
    PAIR s,   test eax, edx
    PAIR s,   test dl, 0x80               ; (with AL the assembler would use the short form, which is no pair)
    PAIR p,   test dl, 4
    PAIR z,   test al, dh
    PAIR ns,  test al, dh
    cmp  [esi-8], eax                   ; from memory, and a near jump
patch:
    jne  near .over
    inc  ebx
.over:
    lea  edi, [edi+edi*2]
    add  edi, ebx
    dec  ecx
    jnz  each
    cmp  ebp, 5
    jne  .same
    mov  byte [patch+1], 0x84           ; JNE becomes JE, for the last four passes
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
    cmp  edi, 0xA66C3110                ; from a trace run, one instruction at a time
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
    dd 0x8107, 0x4185, 0x4185, 0x8107, 0x85, 0x85, 0x0301, 0x80000084
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
