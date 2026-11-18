; Self-check for the IDE disk (E075), on the bare ports, with --disk on an image of 2,048
; sectors: the signature after a reset, an absent slave, IDENTIFY (the count of sectors, the
; model's first letters), a sector written and read back, two sectors in one command, the
; registers' earlier bytes read with the control register's top bit, and a sector beyond
; the end refused. Interrupts are off; the status is polled. Prints "OK".
%include "common.inc"
buf equ 0x1000
%macro OUTB 2
    mov  dx, %1
    mov  al, %2
    out  dx, al
%endmacro
%macro INB 1
    mov  dx, %1
    in   al, dx
%endmacro
start:
    HDR
    cld
    OUTB 0x3F6, 0x06                    ; reset, no interrupts
    OUTB 0x3F6, 0x02
    INB  0x1F2                          ; the signature of an ATA device
    cmp  al, 1
    jne  no
    INB  0x1F4
    or   al, al
    jnz  no
    INB  0x1F7
    cmp  al, 0x50                       ; ready
    jne  no
    OUTB 0x1F6, 0xB0                    ; the slave: nothing
    INB  0x1F7
    or   al, al
    jnz  no
    OUTB 0x1F6, 0xE0                    ; the master, by LBA
    OUTB 0x1F7, 0xEC                    ; IDENTIFY
    call read256
    cmp  word [buf + 60*2], 2048        ; sectors
    jne  no
    cmp  word [buf + 27*2], 'g' << 8 | '8'
    jne  no
    mov  di, buf                        ; a sector of words that count up from 5A00h
    mov  ax, 0x5A00
    mov  cx, 512                        ; two sectors' worth
.fill:
    stosw
    inc  ax
    loop .fill
    OUTB 0x1F2, 2                       ; two sectors
    OUTB 0x1F3, 7                       ; from sector 7
    OUTB 0x1F4, 0
    OUTB 0x1F5, 0
    OUTB 0x1F7, 0x30                    ; WRITE SECTORS
    mov  si, buf
    call write256
    call write256
    INB  0x1F7
    cmp  al, 0x50                       ; done, no error
    jne  no
    OUTB 0x1F2, 1
    OUTB 0x1F3, 8                       ; the second of the two
    OUTB 0x1F7, 0x20                    ; READ SECTORS
    call read256
    cmp  word [buf], 0x5B00
    jne  no
    cmp  word [buf + 510], 0x5BFF
    jne  no
    OUTB 0x1F3, 0x12                    ; the byte before stays behind the new one
    OUTB 0x1F3, 0x34
    OUTB 0x3F6, 0x82
    INB  0x1F3
    cmp  al, 0x12
    jne  no
    OUTB 0x3F6, 0x02
    INB  0x1F3
    cmp  al, 0x34
    jne  no
    OUTB 0x1F3, 0                       ; sector 2048: one past the end
    OUTB 0x1F4, 8
    OUTB 0x1F7, 0x20
    INB  0x1F7
    test al, 1                          ; an error
    jz   no
    INB  0x1F1
    cmp  al, 0x14                       ; no such sector; the command aborted
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
read256:                                ; a sector from the data port to buf, once the disk asks
    INB  0x1F7
    cmp  al, 0x58
    jne  no
    mov  di, buf
    mov  cx, 256
    mov  dx, 0x1F0
    rep  insw
    ret
write256:                               ; a sector from SI to the data port
    INB  0x1F7
    cmp  al, 0x58
    jne  no
    mov  cx, 256
    mov  dx, 0x1F0
    rep  outsw
    ret
    TAIL
