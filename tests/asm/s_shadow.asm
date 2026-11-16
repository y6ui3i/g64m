; Self-check for the instruction after STI in 32-bit code. STI holds interrupts off for one more
; instruction, and a run of short executors must stop after that one: an interrupt that was
; waiting is taken between the first INC after STI and the second, not later and not never
; (E049 moved the place where a run forgets that it began behind an STI). The timer is set
; going and left to become due with interrupts off; its handler notes EAX. Four passes, so that
; the last ones run from the decode cache. Prints "OK".
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
    mov  es, ax
    mov  ss, ax
    mov  esp, 0x7000
    mov  dword [0x8000 + 8*8], 0x00080000 + tick    ; IRQ 0 is vector 8: selector 8, offset tick
    mov  dword [0x8000 + 8*8 + 4], 0x00008E00
    mov  al, 0xFE                       ; only the timer's line open
    out  0x21, al
    mov  al, 0x34                       ; channel 0, a period of 256 ticks
    out  0x43, al
    xor  al, al
    out  0x40, al
    mov  al, 1
    out  0x40, al
    xor  edx, edx                       ; counts the passes that went right
    mov  ebp, 4
pass:
    mov  ecx, 20000                     ; longer than the period: the interrupt is waiting
.wait:
    dec  ecx
    jnz  .wait
    xor  ebx, ebx
    xor  eax, eax
    sti
    inc  eax                            ; held off for this one
    inc  eax                            ; taken before this one, with EAX = 1
    inc  eax
    cli
    cmp  ebx, 1
    jne  .next
    inc  edx
.next:
    dec  ebp
    jnz  pass
    jmp  0x18:leave
tick:
    mov  ebx, eax
    push eax
    mov  al, 0x20
    out  0x20, al
    pop  eax
    iretd
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
    cmp  edx, 4
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
align 8
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
    dq 0x00009A000000FFFF               ; 16-bit code
gdtr:
    dw 31
    dd gdt
idtr:
    dw 15*8 - 1
    dd 0x8000
ridtr:
    dw 0x3FF
    dd 0
    TAIL
