; Byte operations, ADC and SBB in runs that go round often enough to be translated (E124).
; The trace holds the interpreter to the real CPU; difftest64.sh runs every test again with
; --jit-check and with --jit. Each stretch is one a wrong build of the translator passed
; before this test was there. A jump to `bad` is never taken.
%include "elf.inc"

    mov r15d, 14
    lea rbp, [data]
top:
    mov byte [rbp], 100
    mov bl, 30
    sub [rbp], bl                       ; memory less register, bytes: 70
    movzx r8d, byte [rbp]
    mov eax, 0x1234
    mov al, 0x56                        ; one byte of the register: 1256h
    mov r13d, eax
    mov eax, 0x1F0
    mov ebx, 0x120
    add al, bl                          ; F0h and 20h: a carry out of the byte, none out of 32 bits
    jmp .w1
.w1:
    mov ecx, 1
    jnc bad                             ; from RFLAGS in memory: the record's width is 8
    mov ecx, 5
    mov eax, 0x80
    mov ebx, 1
    cmp ecx, 5                          ; ZF, which the JZ below must not see
    or al, bl
    jz bad
    jns bad
    mov ebx, 7
    mov ecx, 1
    and eax, 0xFF                       ; a logic instruction leaves no carry
    adc ebx, ecx                        ; 8
    mov r9d, ebx
    mov eax, 0xFFFFFFFF
    xor edx, edx
    mov esi, 1
    add esi, 0xFFFFFFFF                 ; a carry
    adc eax, edx                        ; FFFFFFFFh and 0 and 1: zero, and a carry out
    jmp .w2
.w2:
    mov ecx, 2
    jnc bad                             ; the ADC's flags, with the carry that went in
    jnz bad
    mov eax, 1
    cmp eax, 2                          ; CF
    jmp .w3
.w3:
    mov ecx, 3
    adc ecx, ecx                        ; the first to set flags in its block: the carry is
    mov r10d, ecx                       ; RFLAGS': 7
    mov eax, 2
    cmp eax, 1                          ; no CF
    jmp .w4
.w4:
    inc eax                             ; CF stays clear, whatever the host's carry is
    mov edx, 10
    adc edx, 0                          ; 10
    mov r11d, edx
    mov eax, 5
    cmp eax, 9                          ; a borrow
    sbb eax, 1                          ; 5 less 1 less 1
    mov r12d, eax
    mov rax, 0x1122334455667788
    mov word [rbp + 16], 0xBEEF         ; sixteen bits to memory, a constant (E133)
    mov ax, [rbp + 16]                  ; and from it: the rest of the register stays
    mov rbx, 0x0102030405060708
    mov bx, ax                          ; and between registers
    mov [rbp + 20], bx
    mov rcx, 0x1122334455667788
    mov cx, [rbp + 20]
    mov rdx, 0x112233445566BEEF
    cmp rax, rdx
    jne bad
    cmp rcx, rdx
    jne bad
    mov rdx, 0x010203040506BEEF
    cmp rbx, rdx
    jne bad
    mov eax, 0x4180
    test al, 0x80                       ; a byte and a constant
    jz bad
    test al, 0x7F
    jnz bad
    test ah, 0x40                       ; the second byte
    jz bad
    mov byte [rbp + 24], 0x21
    test byte [rbp + 24], 0x20          ; and a byte of memory
    jz bad
    test byte [rbp + 24], 0x5E
    jnz bad
    xor eax, eax
    mov ebx, 5
    cmp ebx, 9                          ; a borrow
    jmp .s1
.s1:
    adc eax, 0                          ; a block that takes its carry from RFLAGS, and goes
    sub ebx, 1                          ; back to itself with the SUB's record waiting
    jnz .s1                             ; (E129): by its entry each time, not by its body
    cmp eax, 1                          ; the one carry of the first round
    jne bad
    dec r15d
    jnz top
    EXIT
bad:
    mov eax, 60
    mov edi, 1
    syscall
    times 0x3000 - ($ - $$) db 0
data:
    times 64 db 0
file_end:
