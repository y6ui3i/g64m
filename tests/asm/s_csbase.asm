; Self-check for a run in a 32-bit code segment whose base is not zero. Inside a run the emulator
; carries the linear address of the next instruction, not the instruction pointer, so every place
; where one is turned into the other (a jump, a CALL's return address, a RET's target) has to
; mind the base. It has to be a self-check and not a trace test: tracing stops after every
; instruction, and then nothing is carried.
;
; The trap for a RET that forgets the base: `fa` is run first with a flat code segment, so the
; decode cache knows the instruction at the linear address fa; then, in the segment based at
; 100h, a RET goes to the offset fa, which is the linear address fa+100h, where `fb` is. Each
; part is run four times, so that the general path meets it, then its executor three times.
; Prints "OK".
%define CPU386
%include "common.inc"
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
    mov  bl, 1
    mov  ebp, 4
.flat:
    call fa
    dec  ebp
    jnz  .flat
    mov  ebp, 4
    jmp  0x18:based - 0x100
based:                                  ; from here CS has a base of 100h
    mov  ecx, fa                        ; as an offset in this segment, that is fb
    push ecx
    ret                                 ; C3 to the offset fa
back:
    cmp  eax, 0x22222222                ; fb ran, not fa
    jne  .bad
    call near sub1                      ; E8: pushes an offset, not a linear address
.ret:
    cmp  esi, .ret - 0x100
    je   .next
.bad:
    mov  bl, 0
.next:
    dec  ebp
    jnz  based                          ; taken three times
    jmp  0x20:leave
sub1:
    mov  esi, [esp]                     ; the return address that CALL pushed
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
    mov  ax, 0x0E4F                     ; 'O'
    test bl, bl
    jnz  .first
    mov  al, 'N'
.first:
    int  0x10
    test bl, bl
    jz   .end
    mov  ax, 0x0E4B                     ; 'K'
    int  0x10
.end:
    hlt
bits 32
    times 0xC0-($-$$) db 0x90
fa:                                     ; linear 7CC0h
    mov  eax, 0x11111111
    ret
align 8
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
    dq 0x00CF9A000100FFFF               ; 32-bit code, base 100h
    dq 0x00009A000000FFFF               ; 16-bit code
gdtr:
    dw 39
    dd gdt

    times 0x1C0-($-$$) db 0x90
fb:                                     ; linear 7DC0h = offset 7CC0h in the based segment
    mov  eax, 0x22222222
    jmp  near back
    TAIL
