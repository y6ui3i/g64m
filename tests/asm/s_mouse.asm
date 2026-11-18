; Self-check for the keyboard controller's second port and the PS/2 mouse on it (E078), on
; the bare ports, interrupts off: the port can be turned off and on (bit 5 of the command
; byte); a byte sent round the second port (D3h) comes back marked as the mouse's; the mouse
; answers a reset with its acknowledgement, "passed" and its kind, each marked as the
; mouse's, and acknowledges the command that turns reporting on. Prints "OK".
%include "common.inc"
%macro CTL 1                            ; a command to the controller
    mov  al, %1
    out  0x64, al
%endmacro
%macro DATA 1                           ; a byte to port 60h
    mov  al, %1
    out  0x60, al
%endmacro
%macro MOUSE 1                          ; the next byte from port 60h is the mouse's, and is %1
    in   al, 0x64
    and  al, 0x21
    cmp  al, 0x21
    jne  no
    in   al, 0x60
    cmp  al, %1
    jne  no
%endmacro
start:
    HDR
    CTL  0xA7                           ; the second port off
    CTL  0x20
    in   al, 0x60
    test al, 0x20
    jz   no
    CTL  0xA8                           ; and on
    CTL  0x20
    in   al, 0x60
    test al, 0x20
    jnz  no
    CTL  0xA9                           ; its test: 0, and not the mouse's
    in   al, 0x64
    and  al, 0x21
    cmp  al, 0x01
    jne  no
    in   al, 0x60
    or   al, al
    jnz  no
    CTL  0xD3                           ; round the second port
    DATA 0x5A
    MOUSE 0x5A
    CTL  0xD4                           ; to the mouse: reset
    DATA 0xFF
    MOUSE 0xFA
    MOUSE 0xAA
    MOUSE 0x00
    CTL  0xD4                           ; which kind
    DATA 0xF2
    MOUSE 0xFA
    MOUSE 0x00
    CTL  0xD4                           ; the sample rate, and its argument
    DATA 0xF3
    MOUSE 0xFA
    CTL  0xD4
    DATA 100
    MOUSE 0xFA
    CTL  0xD4                           ; report
    DATA 0xF4
    MOUSE 0xFA
    in   al, 0x64                       ; and nothing more waits
    test al, 1
    jnz  no
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
