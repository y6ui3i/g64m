; The short executors added for what used to take the general path: accesses through a segment
; override (FS has a base of 1000h, so an override that is ignored shows), INC and DEC on memory,
; NOT and NEG, MOV of an immediate to memory, 16-bit MOVs with an operand-size prefix, shifts by
; one, the AL and EAX forms with an immediate, and REP on RET and NOP. Four passes, so that each
; instruction is met by the general path, then by its executor three times.
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
    mov  es, ax
    mov  ss, ax
    mov  esp, 0x7000
    mov  ax, 0x18
    mov  fs, ax
    mov  ebp, 4
    mov  dword [0x9000], 0x11111111     ; what FS:8000h is
    mov  dword [0x8000], 0x22222222     ; what DS:8000h is
.pass:
    mov  ebx, 0x8000
    mov  eax, [fs:ebx]                  ; 64 8B
    mov  ecx, [ebx]
    inc  dword [fs:ebx]                 ; 64 FF /0
    dec  dword [fs:ebx+4]               ; 64 FF /1
    inc  dword [ebx]                    ; FF /0
    dec  dword [ebx]
    mov  [fs:ebx+8], eax                ; 64 89
    lea  esi, [fs:ebx+ecx*2+3]          ; 64 8D
    add  eax, [fs:ebx+8]
    cmp  [fs:ebx], eax
    not  eax                            ; F7 /2
    not  dword [fs:ebx+12]
    neg  ecx                            ; F7 /3
    neg  dword [ebx+16]
    mov  dword [ebx+20], 0x89ABCDEF     ; C7 /0
    mov  dword [fs:ebx+24], 0x7FFFFFFF
    mov  byte [ebx+21], 0x5A            ; C6 /0
    mov  ax, [ebx+20]                   ; 66 8B
    mov  dx, si
    mov  dword [ebx+28], 0xAAAAAAAA
    mov  [ebx+28], cx                   ; 66 89: the upper half must stay
    mov  edx, [ebx+28]
    mov  [fs:ebx+30], si
    mov  edx, [fs:ebx+28]
    mov  di, [fs:ebx+24]                ; 66 64 8B: not a short executor (two prefixes)
    mov  eax, [ebx+20]
    shl  eax, 1                         ; D1 /4
    shr  dword [ebx+20], 1              ; D1 /5
    sar  eax, 1                         ; D1 /7
    rol  eax, 1                         ; D1 /0: stays general
    add  eax, 0x7FFFFFFF                ; 05
    adc  eax, 0x12345678                ; 15
    sub  eax, 1                         ; 2D, if the assembler keeps the long form
    cmp  eax, 0x80000000                ; 3D
    mov  al, 0x7F
    add  al, 1                          ; 04
    sbb  al, 0x10                       ; 1C
    and  al, 0x0F                       ; 24
    cmp  al, 0x0E                       ; 3C
    test eax, 0x80000001                ; A9
    test al, 0x81                       ; A8
    call fn                             ; returns with F3 C3
    pause                               ; F3 90
    dec  ebp
    jnz  near .pass
    hlt
fn:
    inc  ebx
    rep  ret
align 8
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
    dq 0x00CF92001000FFFF               ; data, base 1000h
gdtr:
    dw 31
    dd gdt
    TAIL
