; Self-check for the PCI bus and the network card on the bare ports (E076), with --net: the
; bridge and the card answer at their devices and nothing answers at another; the card's
; ports are asked for their size and come back as 32 of them; the card's ports do nothing
; until the command register turns them on; then the chip's address PROM is read through
; the data port (the station address, and the two 57h of an NE2000), and a byte written to
; the chip's memory is read back. Prints "OK".
%define CPU386
%include "common.inc"
%macro CFG 2                            ; EAX = the configuration register %2 of device %1
    mov  eax, 0x80000000 | (%1 << 11) | %2
    mov  dx, 0xCF8
    out  dx, eax
    mov  dx, 0xCFC
    in   eax, dx
%endmacro
%macro NE 2                             ; the card's register %1 = %2
    mov  dx, 0xC000 + %1
    mov  al, %2
    out  dx, al
%endmacro
start:
    HDR
    CFG  0, 0
    cmp  eax, 0x12378086                ; the bridge
    jne  no
    CFG  3, 0
    cmp  eax, 0x802910EC                ; the card
    jne  no
    CFG  1, 0
    cmp  eax, 0xFFFFFFFF                ; nothing
    jne  no
    CFG  3, 0x10
    cmp  eax, 0x0000C001                ; ports at C000h
    jne  no
    mov  eax, 0xFFFFFFFF                ; how many?
    out  dx, eax
    in   eax, dx
    cmp  eax, 0xFFFFFFE1                ; 32
    jne  no
    mov  eax, 0x0000C001
    out  dx, eax
    mov  dx, 0xC000                     ; off: nothing is there
    in   al, dx
    cmp  al, 0xFF
    jne  no
    CFG  3, 0x04
    or   al, 1                          ; the ports on
    out  dx, eax
    mov  dx, 0xC000
    in   al, dx
    cmp  al, 0x01                       ; the chip, stopped
    jne  no
    NE   0x0A, 16                       ; sixteen bytes
    NE   0x0B, 0
    NE   0x08, 0                        ; from address 0: the PROM
    NE   0x09, 0
    NE   0x00, 0x0A                     ; read
    mov  dx, 0xC010
    in   ax, dx
    cmp  ax, 0x5452                     ; 52 54
    jne  no
    mov  cx, 7                          ; to the eighth word, bytes 14 and 15
.skip:
    in   ax, dx
    loop .skip
    cmp  ax, 0x5757
    jne  no
    NE   0x0A, 1                        ; one byte at 4100h, written and read back
    NE   0x0B, 0
    NE   0x08, 0
    NE   0x09, 0x41
    NE   0x00, 0x12                     ; write
    NE   0x10, 0xA5
    NE   0x0A, 1
    NE   0x08, 0
    NE   0x09, 0x41
    NE   0x00, 0x0A
    mov  dx, 0xC010
    in   al, dx
    cmp  al, 0xA5
    jne  no
    mov  ax, 0x0E4F                     ; 'O'
    int  0x10
    mov  ax, 0x0E4B                     ; 'K'
    int  0x10
    hlt
no:
    mov  ax, 0x0E4E                     ; 'N'
    int  0x10
    hlt
    TAIL
