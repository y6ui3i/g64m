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
    jmp .i1
.i1:
    mov ebx, 10
    inc ebx                             ; INC and DEC with their flags dead (E127): an ADD follows
    dec ebx
    dec ebx
    add ebx, 1
    jmp .i2
.i2:
    mov eax, 0xFFFFFFFF
    xor ecx, ecx
    xor edx, edx
    inc eax                             ; ZF, which the jump reads past a shift by zero: not dead
    shl edx, cl
    jnz bad
    mov eax, 0x80000000
    xor edx, edx
    rol eax, 1                          ; CF, which RCL reads: not dead
    rcl edx, 1
    cmp edx, 1
    jne bad
    mov eax, 0x80000000
    xor edx, edx
    rol eax, 1                          ; and RCL by a constant
    rcl edx, 2
    cmp edx, 2
    jne bad
    lea rax, [.j1]
    cmp r15d, 14
    jne .jgo
    lea rax, [.j0]                      ; the first time round, through the ADD
.jgo:
    mov ebx, 0xFFFFFFFF
    inc ebx                             ; ZF, read where the jump through RAX goes: the ADD
    jmp rax                             ; behind the jump is not where it goes after the
.j0:                                    ; first round, and does not make the flags dead
    add ebx, 0
.j1:
    jnz bad
    mov eax, 0x1234
    or ah, 1                            ; the second byte of a register: 1334h
    add ah, 0x10                        ; 2334h
    cmp ah, 0x23
    jne bad
    cmp eax, 0x2334
    jne bad
    mov eax, 5
    cmp eax, 9
    je bad                              ; two jumps on one comparison: the second in the
    jae bad                             ; same block, on the host's flags
    mov eax, 5
    mov ebx, 1
    cmp eax, 5
    not ebx                             ; NOT sets no flag: the comparison's are not dead (E128),
    jmp .i3                             ; and the next block reads them from the record
.i3:
    mov ebp, 6
    jne bad
    cmp r15d, 0                         ; no carry into the next round, so that the ADC at
    dec r15d                            ; the top takes its carry from the rotation
    jnz top
    EXIT
bad:
    mov eax, 60
    mov edi, 1
    syscall
file_end:
