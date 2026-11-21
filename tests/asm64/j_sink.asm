; A flag-setting instruction with a conditional jump right behind it, where the flags are
; read again on one side of the jump or the other (E130): the record is not made at the
; instruction but on that side, from what the registers hold there. The trace holds the
; interpreter to the real CPU; difftest64.sh runs every test again with --jit-check and
; with --jit. A jump to `bad` is never taken.
%include "elf.inc"

    mov r15d, 14
top:
    mov eax, 5
    sub eax, 3                          ; the side taken reads the flags: the first operand
    jnz .a1                             ; is the result with the constant put back
    jmp bad
.a1:
    jmp .a2
.a2:
    mov ebp, 1
    jb bad
    jz bad
    js bad
    cmp eax, 2
    jne bad
    mov eax, 5
    sub eax, 5                          ; the side not taken reads them
    jnz bad
    jmp .b1
.b1:
    mov ebp, 2
    jnz bad
    jc bad
    mov eax, 0xF0F0
    mov ebx, 0x0F0F
    xor eax, ebx                        ; a logic instruction: its flags are its result's
    jnz .c1
    jmp bad
.c1:
    jmp .c2
.c2:
    mov ebp, 3
    jz bad
    js bad
    mov eax, 0x80000000
    add eax, eax                        ; both operands are the result's register: not put off
    jnz bad
    jmp .d1
.d1:
    mov ebp, 4
    jnc bad
    jno bad
    mov eax, 3
    cmp eax, 2                          ; odd parity, where the ADD above left it even
    jnp .e1                             ; a condition the host's flags do not give: the
    jmp bad                             ; block ends in front of the jump, with the record
.e1:
    jz bad
    mov eax, 1
    cmp eax, 2                          ; a constant for the second operand
    jb .f1
    jmp bad
.f1:
    jmp .f2
.f2:
    mov ebp, 5
    jae bad
    jz bad
    mov ecx, 9
    mov edx, 4
    sub ecx, edx                        ; a register for it
    ja .g1
    jmp bad
.g1:
    jmp .g2
.g2:
    mov ebp, 6
    jbe bad
    cmp ecx, 5
    jne bad
    mov esi, 5
    cmp esi, 1                          ; "above", left in RFLAGS for the block below
    jmp .h0
.h0:
    xor edi, edi
    mov eax, 0xFFFFFFF0
    mov ebx, 0x20
    add eax, ebx                        ; a carry: not above. After an ADD the host's flags
    ja .h1                              ; do not give "above", and the flags are dead on
    mov edi, 1                          ; both sides: the record is made all the same,
.h1:                                    ; since the jump cannot be in the block
    cmp edi, 1
    jne bad
    dec r15d
    jnz top
    EXIT
bad:
    mov eax, 60
    mov edi, 1
    syscall
file_end:
