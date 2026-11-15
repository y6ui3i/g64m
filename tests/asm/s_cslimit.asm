; Self-check for a run that reaches the limit of its code segment. A run of short executors
; stops 15 bytes short of the limit and leaves the rest to the general path, which checks each
; instruction exactly; a run that forgets the limit goes on executing what lies beyond it.
;
; The segment at selector 18h is 32-bit code with a base of 7000h (a page boundary: a run is
; not attempted on a page that begins below the segment's base) and a byte-granular limit that
; ends 30h bytes after `lim`. From `lim` on there are one-byte INC EDX instructions, 30h of
; them inside the limit and more beyond. Jumping to `lim` must run exactly 30h of them and then
; fault with #GP at the first one beyond. Four passes, so that the executors run on the later ones.
;
; A run only executes instructions the decode cache knows, and those beyond the limit would
; never get there through this segment, so first they are run four times through the flat one
; (a CALL to the linear address of offset 30h; a RET ends them). It has to be a self-check:
; tracing ends a run after every instruction. Prints "OK".
%define CPU386
%include "common.inc"
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
    mov  dword [0x8000 + 13*8], 0x00080000 + gp     ; the #GP gate: selector 8, offset gp
    mov  dword [0x8000 + 13*8 + 4], 0x00008E00
    mov  esp, 0x7000
    mov  bl, 1
    mov  ebp, 4
warm:
    call lim + 0x30                     ; flat: the cache learns what lies beyond the limit
    dec  ebp
    jnz  warm
    mov  ebp, 4
again:
    mov  esp, 0x7000
    push dword lim - 0x7000 + 0x30      ; should the RET beyond the limit be reached
    xor  edx, edx
    jmp  0x18:lim - 0x7000
gp:
    cmp  edx, 0x30                      ; every INC inside the limit, none beyond
    jne  .bad
    cmp  dword [esp+4], lim - 0x7000 + 0x30 ; the faulting instruction's offset
    je   .next
.bad:
    mov  bl, 0
.next:
    dec  ebp
    jnz  again
    jmp  0x20:leave
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
    lidt [ridtr]
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
lim:
    times 0x50 inc edx                  ; 30h inside the limit, 20h beyond
    ret
align 8
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
    dw lim - 0x7000 + 0x2F, 0x7000      ; 32-bit code, base 7000h, limit 2Fh past lim
    db 0, 0x9A, 0x40, 0
    dq 0x00009A000000FFFF               ; 16-bit code
gdtr:
    dw 39
    dd gdt
idtr:
    dw 14*8 - 1
    dd 0x8000
ridtr:
    dw 0x3FF
    dd 0
    TAIL
