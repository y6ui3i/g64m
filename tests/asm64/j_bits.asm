; BT, BTS, BTR and BTC of registers, SHLD and SHRD, and the 16-bit forms, in a run that goes
; round often enough to be translated (E138). The trace holds the interpreter to the real
; CPU; difftest64.sh runs every test again with --jit-check and with --jit. A jump to `bad`
; is never taken.
%include "elf.inc"

    mov r15d, 14
    lea rbp, [data]
top:
    ; BT of a register: the jump right behind reads CF from the host's flags
    mov rax, 0x8000000000000001
    mov r14d, 63
    bt rax, r14                         ; set
    jae bad
    bt rax, 1                           ; clear
    jb bad
    mov ecx, 0x100
    bt ecx, 8
    jnc bad
    mov r9d, 72                         ; 72 and 31: 8
    bt ecx, r9d
    jnc bad
    mov r8w, 0x8000
    mov dx, 15
    bt r8w, dx
    jnc bad
    bt r8w, 31                          ; 31 and 15: set
    jnc bad
    bt r8w, 14
    jc bad
    ; CF kept for a later reader: the record
    mov rbx, 4
    bt rbx, 2
    mov r10d, 0
    adc r10d, 0                         ; 1
    cmp r10d, 1
    jne bad
    ; BTS, BTR, BTC
    mov rax, 0
    bts rax, 40
    jc bad
    mov rcx, 40
    bts rax, rcx                        ; set already
    jnc bad
    mov rdx, 0x10000000000
    cmp rax, rdx
    jne bad
    btr eax, 3                          ; 0, the upper half cleared by a 32-bit operation
    jc bad
    test rax, rax
    jne bad
    mov eax, 0xFFFFFFFF
    mov esi, 5
    btc eax, esi
    jnc bad
    cmp eax, 0xFFFFFFDF
    jne bad
    mov r11, 0x123456789ABCDEF0
    btc r11w, 4                         ; DEE0h: the rest of the register stays
    jnc bad
    mov rdx, 0x123456789ABCDEE0
    cmp r11, rdx
    jne bad
    mov cx, 1
    bts r11w, cx                        ; DEE2h
    jc bad
    mov rdx, 0x123456789ABCDEE2
    cmp r11, rdx
    jne bad
    ; SHLD and SHRD, by a constant and by CL
    mov rax, 0x1122334455667788
    mov rbx, 0xAABBCCDDEEFF0011
    shld rax, rbx, 8
    mov rdx, 0x22334455667788AA
    cmp rax, rdx
    jne bad
    mov rax, 0x1122334455667788
    shrd rax, rbx, 4
    mov rdx, 0x1112233445566778
    cmp rax, rdx
    jne bad
    mov eax, 0x80000000
    mov ebx, 1
    shld eax, ebx, 1                    ; 0, and a carry
    jnc bad
    jnz bad
    mov cl, 12
    mov eax, 0x12345678
    mov ebx, 0x9ABCDEF0
    shld eax, ebx, cl
    cmp eax, 0x456789AB
    jne bad
    mov rax, 0x1122334455667788
    mov rbx, 0xAABBCCDDEEFF0011
    mov cl, 64 + 16                     ; 16 after the mask
    shrd rax, rbx, cl
    mov rdx, 0x0011112233445566
    cmp rax, rdx
    jne bad
    mov cl, 0
    cmp ecx, 1                          ; a borrow
    shrd rax, rbx, cl                   ; by zero: nothing, and the flags stay
    jnc bad
    ; Sixteen bits: the ALU operations, with registers, memory and constants
    mov rax, 0x11223344FFFF0000
    mov rbx, 0x55667788AAAA0001
    add ax, bx                          ; 1, no carry
    jc bad
    mov rdx, 0x11223344FFFF0001
    cmp rax, rdx
    jne bad
    mov ax, 0xFFFF
    add ax, bx                          ; 0: a carry, zero
    jnc bad
    jnz bad
    sub ax, 1                           ; FFFFh, a borrow
    jnc bad
    cmp ax, 0xFFFF
    jne bad
    mov r9d, 0x12348000
    cmp r9w, 0x7FFF                     ; 8000h less 7FFFh: 1, with overflow
    jno bad
    jge bad
    test r9w, 0x8000
    jz bad
    jns bad
    and r9w, 0x0FFF                     ; 0
    jnz bad
    mov r10w, 0x8001
    or r10w, 0x0010                     ; 8011h
    jns bad
    xor r10w, r10w
    jnz bad
    mov r12, 0x0102030405060708
    mov word [rbp], 0x1234
    add [rbp], r12w                     ; 193Ch
    mov cx, [rbp]
    cmp cx, 0x193C
    jne bad
    add r12w, [rbp]                     ; 2044h
    cmp r12w, 0x2044
    jne bad
    mov rdx, 0x0102030405062044
    cmp r12, rdx
    jne bad
    cmp word [rbp], 0x193C
    jne bad
    sub word [rbp], 0x3C                ; 1900h
    test word [rbp], 0x0100
    jz bad
    mov r13w, 0xFFF0
    test r13w, 0x000F
    jnz bad
    ; Sixteen bits: the shifts by a constant, NOT and NEG
    mov r13, 0xAAAAAAAAAAAA8001
    shr r13w, 1                         ; 4000h, a carry
    jnc bad
    mov rdx, 0xAAAAAAAAAAAA4000
    cmp r13, rdx
    jne bad
    sar r13w, 14                        ; 1
    cmp r13w, 1
    jne bad
    mov si, 0x8000
    sar si, 15                          ; FFFFh
    cmp si, 0xFFFF
    jne bad
    shl si, 4                           ; FFF0h, a carry
    jnc bad
    mov di, 0x0F0F
    not di                              ; F0F0h
    cmp di, 0xF0F0
    jne bad
    neg di                              ; 0F10h, a borrow
    jnc bad
    cmp di, 0x0F10
    jne bad
    mov ax, 0x1234
    test ax, ax
    jz bad
    mov ax, 0x00FF
    add ax, 0x0001                      ; the A register and a constant
    cmp ax, 0x0100
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
