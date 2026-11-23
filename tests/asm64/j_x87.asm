; The x87 in blocks (E161): each instruction a call from the block to the interpreter's own
; routine, its operand in memory read or stored by the block. Loads and stores of every
; size (reals of 32, 64 and 80 bits, integers of 16, 32 and 64), arithmetic with a
; register and with memory, the register stack's moves, the control word, and FCOMI and
; FUCOMIP with a jump, a SETcc and a CMOVcc behind them (one with an instruction between
; that keeps the flags). In a run that goes round often enough to be translated, on data
; that changes every round. What the x87 gives is stored and read back into general
; registers, which the trace holds to the real CPU; difftest64.sh runs it again with
; --jit-check and with --jit.
%include "elf.inc"

    fninit
    mov r15d, 14
    lea rbp, [data]
    xor r14d, r14d
top:
    fld tword [rbp]                     ; a
    fld qword [rbp + 16]                ; b a
    fld st1                             ; a b a
    fmul st0, st1                       ; a*b b a
    fadd dword [rbp + 24]               ; a*b+c
    fild dword [rbp + 28]               ; i  a*b+c  b  a
    faddp st1, st0
    fxch st2                            ; a b x
    fdivr st0, st1                      ; b/a b x
    fsubp st2, st0                      ; b x-b/a
    fild qword [rbp + 32]
    fmul qword [rbp + 16]
    fiadd word [rbp + 40]
    fsqrt
    fstp tword [rbp + 64]               ; b y
    fld st1
    fistp dword [rbp + 80]
    fld st1
    fistp qword [rbp + 88]
    fld st1
    fistp word [rbp + 96]
    fst dword [rbp + 100]
    fst qword [rbp + 104]
    fnstcw [rbp + 112]
    fcomi st0, st1
    fld st0                             ; between the comparison and the jump
    fstp st0
    ja above
    inc r14d
above:
    setb r8b
    cmovp r9d, r15d
    fxch st1
    fucomip st0, st1
    jp odd
    jbe below
    add r14d, 16
below:
odd:
    fstp tword [rbp]                    ; the data for the next round
    mov rax, [rbp + 64]
    movzx ebx, word [rbp + 72]
    mov ecx, [rbp + 80]
    mov rdx, [rbp + 88]
    movzx esi, word [rbp + 96]
    mov edi, [rbp + 100]
    mov r10, [rbp + 104]
    movzx r11d, word [rbp + 112]
    mov r12, [rbp]
    movzx r13d, word [rbp + 8]
    add dword [rbp + 28], 7
    add qword [rbp + 32], 1000003
    dec r15d
    jnz top
    EXIT
    times 0x3000 - ($ - $$) db 0
data:
    dt 3.25                             ; +0
    times 6 db 0
    dq 1.75                             ; +16
    dd 0.5                              ; +24
    dd 12345                            ; +28
    dq 99999999999                      ; +32
    dw -321                             ; +40
    times 86 db 0
file_end:
