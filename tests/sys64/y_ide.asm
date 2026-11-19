; The IDE disk (E101): identify it, read sectors, write one and read it back, with the
; words moved by IN, OUT and their repeated string forms at 16 and 32 bits, and an
; interrupt on line 14 for each block. The image is 2,048 sectors, word i of sector n
; holding n * 257 + i * 3 (tools/systest64.sh makes it). Under QEMU the disk is QEMU's
; model of one: what is printed is what any ATA disk gives a driver.
%include "sys.inc"
    jmp test
%include "idt.inc"

; The hook: an interrupt on line 14 (vector 2Eh) is counted, the disk's status read (which
; is what tells the disk it was heard), and both controllers told it is done.
ide_hook:
    cmp qword [f_vec], 0x2E
    jne .out
    push rdx
    inc qword [irqs]
    mov dx, 0x1F7
    in al, dx
    mov al, 0x20
    out 0xA0, al
    out 0x20, al
    pop rdx
.out:
    ret

; Waits until the disk is not busy, and has data to give or take if AL says so (8), with
; the alternate status port, which does not answer the interrupt. The status, in RAX.
wait_disk:
    push rdx
    push rbx
    movzx ebx, al
    mov dx, 0x3F6
.again:
    in al, dx
    test al, 0x80
    jnz .again
    test al, 1
    jnz .done
    and al, bl
    cmp al, bl
    jne .again
.done:
    in al, dx
    movzx eax, al
    pop rbx
    pop rdx
    ret

; Sets the disk's registers for a command on RCX sectors from LBA RBX, and gives the command
; in AL.
command:
    push rdx
    push rax
    mov dx, 0x1F2
    mov al, cl
    out dx, al
    mov dx, 0x1F3
    mov al, bl
    out dx, al
    mov dx, 0x1F4
    mov al, bh
    out dx, al
    mov dx, 0x1F5
    mov eax, ebx
    shr eax, 16
    out dx, al
    mov dx, 0x1F6
    mov eax, ebx
    shr eax, 24
    and al, 0x0F
    or al, 0xE0
    out dx, al
    pop rax
    mov dx, 0x1F7
    out dx, al
    pop rdx
    ret

; The sum of the 256 words at RSI, each turned by its place, in RAX.
checksum:
    push rcx
    push rsi
    push rdx
    xor eax, eax
    mov ecx, 256
.next:
    movzx edx, word [rsi]
    add rax, rdx
    rol rax, 7
    add rsi, 2
    dec ecx
    jnz .next
    pop rdx
    pop rsi
    pop rcx
    ret

test:
    call idt_init
    lea rax, [ide_hook]
    mov [f_hook], rax
    ; The controllers at vectors 20h and 28h; only the cascade and line 14 open.
    mov al, 0x11
    out 0x20, al
    out 0xA0, al
    mov al, 0x20
    out 0x21, al
    mov al, 0x28
    out 0xA1, al
    mov al, 4
    out 0x21, al
    mov al, 2
    out 0xA1, al
    mov al, 1
    out 0x21, al
    out 0xA1, al
    mov al, 0xFB
    out 0x21, al
    mov al, 0xBF
    out 0xA1, al
    mov dx, 0x3F6
    mov al, 0
    out dx, al
    sti

    PUTS "the disk, at rest"
    mov dx, 0x1F6
    mov al, 0xE0
    out dx, al
    xor eax, eax
    call wait_disk
    PRINT rax

    PUTS "what it says of itself"
    mov al, 0xEC
    xor ebx, ebx
    xor ecx, ecx
    call command
    mov al, 8
    call wait_disk
    PRINT rax
    lea rdi, [block]
    mov dx, 0x1F0
    mov ecx, 256
    cld
    rep insw
    xor eax, eax
    call wait_disk
    PRINT rax
    movzx eax, word [block]
    and eax, 0x8000
    PRINT rax
    movzx eax, word [block + 49 * 2]
    and eax, 0x200
    PRINT rax
    mov eax, [block + 60 * 2]
    PRINT rax
    PRINT [irqs]

    PUTS "two sectors read, the first by single words and the second four bytes at a time"
    mov qword [irqs], 0
    mov ebx, 5
    mov ecx, 2
    mov al, 0x20
    call command
    mov al, 8
    call wait_disk
    PRINT rax
    lea rdi, [block]
    mov dx, 0x1F0
    in ax, dx
    mov [rdi], ax
    add rdi, 2
    mov ecx, 255
    rep insw
    lea rsi, [block]
    call checksum
    PRINT rax
    PRINT [block]
    mov al, 8
    call wait_disk
    PRINT rax
    lea rdi, [block]
    mov dx, 0x1F0
    mov ecx, 128
    rep insd
    lea rsi, [block]
    call checksum
    PRINT rax
    PRINT [block + 504]
    xor eax, eax
    call wait_disk
    PRINT rax
    PRINT [irqs]

    PUTS "one sector written and read back"
    mov qword [irqs], 0
    lea rdi, [block]
    mov ecx, 256
    mov eax, 0xA5A5
.fill:
    mov [rdi], ax
    add eax, 0x1357
    add rdi, 2
    dec ecx
    jnz .fill
    lea rsi, [block]
    call checksum
    PRINT rax
    mov ebx, 9
    mov ecx, 1
    mov al, 0x30
    call command
    mov al, 8
    call wait_disk
    PRINT rax
    PRINT [irqs]
    lea rsi, [block]
    mov dx, 0x1F0
    mov ax, [rsi]
    out dx, ax
    add rsi, 2
    mov ecx, 255
    rep outsw
    xor eax, eax
    call wait_disk
.w1:
    cmp qword [irqs], 1
    jb .w1
    xor eax, eax
    call wait_disk
    PRINT rax
    PRINT [irqs]
    ; The buffer is cleared, and the sector read again.
    lea rdi, [block]
    mov ecx, 64
    xor eax, eax
    rep stosq
    mov ebx, 9
    mov ecx, 1
    mov al, 0x20
    call command
    mov al, 8
    call wait_disk
    lea rdi, [block]
    mov dx, 0x1F0
    mov ecx, 256
    rep insw
    lea rsi, [block]
    call checksum
    PRINT rax
    ; Its neighbours are as they were.
    mov ebx, 8
    mov ecx, 3
    mov al, 0x20
    call command
    mov r12d, 3
.three:
    mov al, 8
    call wait_disk
    lea rdi, [block]
    mov dx, 0x1F0
    mov ecx, 256
    rep insw
    PRINT [block]
    dec r12d
    jnz .three

    PUTS "a sector past the end"
    mov ebx, 5000
    mov ecx, 1
    mov al, 0x20
    call command
    xor eax, eax
    call wait_disk
    and eax, 0x89
    PRINT rax
    cli
    ; And a string of bytes to a port: the serial port's.
    lea rsi, [said]
    mov ecx, said_len
    mov dx, 0x3F8
    rep outsb
    EXIT

said: db "sent by OUTSB", 10
said_len equ $ - said

align 16
irqs: dq 0
block: times 512 db 0
file_end:
