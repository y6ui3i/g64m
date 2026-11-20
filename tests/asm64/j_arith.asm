; Rotations, MUL and IMUL with one operand and byte shifts in runs that go round often
; enough to be translated (E125). The trace holds the interpreter to the real CPU;
; difftest64.sh runs every test again with --jit-check and with --jit. Each stretch is one
; a wrong build of the translator passed before this test was there. A jump to `bad` is
; never taken.
%include "elf.inc"

    mov r15d, 14
top:
    mov eax, 0x80000001
    mov ecx, 4
    rol eax, cl                         ; by CL, left: its flags are dead, an ADD follows
    add eax, 1
    mov r8d, eax
    mov ebx, 0x80000001
    ror ebx, cl                         ; and right
    add ebx, 1
    mov r9d, ebx
    mov eax, 0x80000000
    xor edx, edx
    rol eax, 1                          ; CF, which the ADC reads: not dead
    adc edx, edx
    mov r10d, edx
    mov eax, 0x80000000
    xor edi, edi
    rol eax, 1                          ; and the form with a constant
    adc edi, 0
    mov eax, 1
    ror eax, 1                          ; CF, which the jump reads: not dead
    jnc bad
    mov eax, 0x7FFFFFFF
    add eax, 1                          ; OF
    jmp .r1
.r1:
    mov ebp, 1
    mov ebx, 1
    rol ebx, 3                          ; of a register by a constant over one: OF stays
    jmp .r2
.r2:
    mov ebp, 2
    jno bad
    mov eax, 0xFFFFFFFF
    mov ecx, 0xFFFFFFFF
    mul ecx                             ; FFFFFFFE:00000001, and the upper half is not empty
    mov r11d, edx
    mov r12d, eax
    jmp .m1
.m1:
    mov ebp, 3
    jnc bad
    mov eax, 0xFFFFFFFF
    mov ecx, 2
    imul ecx                            ; -1 by 2: FFFFFFFF:FFFFFFFE, which fits
    mov r13d, edx
    jmp .m2
.m2:
    mov ebp, 4
    jc bad
    mov eax, 0x40000000
    mov ecx, 4
    imul ecx                            ; and one that does not fit
    jmp .m3
.m3:
    mov ebp, 5
    jnc bad
    mov eax, 0x1280
    sar al, 3                           ; a byte right with its sign: 12F0h
    mov r14d, eax
    shr al, 2                           ; and without: 123Ch
    mov esi, eax
    dec r15d
    jnz top
    EXIT
bad:
    mov eax, 60
    mov edi, 1
    syscall
file_end:
