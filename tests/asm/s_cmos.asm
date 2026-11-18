; Self-check for the CMOS clock (E074). In a run that no one watches the clock starts at
; 2026-01-01 00:00:00, a Thursday. Read: the status registers, the date in BCD, the date in
; binary once status B says so. Written: a date and a time just before a leap day ends,
; which then read back, and (after a wait of over a second of the guest's time, which is
; 1,193,182 of the timer's ticks) roll over into March. A register that is not the clock's
; keeps what is written. Prints "OK".
%include "common.inc"
%macro RD 1                             ; AL = register %1
    mov  al, %1
    out  0x70, al
    in   al, 0x71
%endmacro
%macro WR 2                             ; register %1 = %2
    mov  al, %1
    out  0x70, al
    mov  al, %2
    out  0x71, al
%endmacro
%macro EXPECT 2                         ; register %1 reads %2
    RD   %1
    cmp  al, %2
    jne  no
%endmacro
start:
    HDR
    EXPECT 0x0B, 0x02                   ; 24 hours, BCD
    EXPECT 0x0D, 0x80                   ; the battery is good
    RD   0x0A
    test al, 0x80                       ; no update in progress
    jnz  no
    EXPECT 0x32, 0x20
    EXPECT 0x09, 0x26
    EXPECT 0x08, 0x01
    EXPECT 0x07, 0x01
    EXPECT 0x06, 0x05                   ; Thursday
    EXPECT 0x04, 0x00
    EXPECT 0x02, 0x00
    WR   0x0B, 0x06                     ; binary
    EXPECT 0x09, 26
    EXPECT 0x32, 20
    WR   0x0B, 0x02
    WR   0x09, 0x28                     ; 2028-02-29 23:59:59
    WR   0x08, 0x02
    WR   0x07, 0x29
    WR   0x04, 0x23
    WR   0x02, 0x59
    WR   0x00, 0x59
    EXPECT 0x07, 0x29
    EXPECT 0x04, 0x23
    EXPECT 0x06, 0x03                   ; a Tuesday
    WR   0x3F, 0xA5                     ; not the clock's
    mov  cx, 0x30                       ; 30 0000h times round: over 1.2 million ticks at 4 instructions each
    xor  bx, bx
.wait:
    dec  bx
    jnz  .wait
    dec  cx
    jnz  .wait
    EXPECT 0x08, 0x03                   ; March
    EXPECT 0x07, 0x01
    EXPECT 0x04, 0x00
    EXPECT 0x09, 0x28
    EXPECT 0x06, 0x04                   ; Wednesday
    EXPECT 0x3F, 0xA5
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
