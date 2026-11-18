; Self-check for the SSE2 instructions that rustx86 does not do as the manual says, so that
; the trace tests (v_sse*) cannot hold them (E077): the conversions that round, which round
; to the nearest integer and a half to the even one; MOVHLPS, which takes the source's high
; half; and arithmetic where an operand or a result is not a number. The values expected
; are the manual's. Runs on the i686. Prints "OK".
%define CPU686
%include "common.inc"
cpu prescott
%macro EXPECT 1
    cmp  eax, %1
    jne  no
%endmacro
start:
    HDR
    cvtss2si eax, [s1]                  ; -3.75
    EXPECT -4
    cvtss2si eax, [s1+4]                ; 2.5: a half goes to the even number
    EXPECT 2
    cvtss2si eax, [s1+8]                ; 3.5
    EXPECT 4
    cvtsd2si eax, [d1]                  ; -1234567.5
    EXPECT -1234568
    cvtsd2si eax, [d1+8]                ; 2.75
    EXPECT 3
    cvtps2dq xmm0, [s1]                 ; -3.75 2.5 3.5 0.5
    movd eax, xmm0
    EXPECT -4
    psrldq xmm0, 4
    movd eax, xmm0
    EXPECT 2
    psrldq xmm0, 8
    movd eax, xmm0
    EXPECT 0
    cvtpd2dq xmm0, [d1]
    movd eax, xmm0
    EXPECT -1234568
    cvtps2pi mm0, [s1]
    movd eax, mm0
    EXPECT -4
    cvtpd2pi mm0, [d1]
    psrlq mm0, 32
    movd eax, mm0
    EXPECT 3
    emms
    movdqu xmm1, [d1]                   ; MOVHLPS: the low half from the source's high half
    pxor xmm0, xmm0
    movhlps xmm0, xmm1
    movd eax, xmm0
    EXPECT 0                            ; the low dword of 2.75
    psrldq xmm0, 4
    movd eax, xmm0
    EXPECT 0x40060000                   ; and its high one
    xorps xmm1, xmm1                    ; 0 / 0: the real indefinite, quiet and with the sign set
    divps xmm1, xmm1
    movd eax, xmm1
    EXPECT 0xFFC00000
    sqrtss xmm0, [s1]                   ; the square root of -3.75: the same
    movd eax, xmm0
    EXPECT 0xFFC00000
    movups xmm0, [s1]                   ; the smaller of a number and not a number: the second operand
    minps xmm0, xmm1
    movd eax, xmm0
    EXPECT 0xFFC00000
    maxss xmm1, [s1]                    ; and here the second is the number
    movd eax, xmm1
    EXPECT 0xC0700000
    movsd xmm0, [d1]                    ; a number plus not a number: that one, made quiet
    addsd xmm0, [d2]
    psrlq xmm0, 32
    movd eax, xmm0
    EXPECT 0x7FFC0000
    mov  ax, 0x0E4F                     ; 'O'
    int  0x10
    mov  ax, 0x0E4B                     ; 'K'
    int  0x10
    hlt
no:
    mov  ax, 0x0E4E                     ; 'N'
    int  0x10
    hlt
align 4
s1: dd -3.75, 2.5, 3.5, 0.5
d1: dq -1234567.5, 2.75
d2: dq 0x7FF4000000000001             ; not a number, and not quiet
    TAIL
