; The short executors for string instructions without REP: MOVSD, MOVSW, MOVSB, LODSB, SCASB,
; STOSB and STOSD. Each is run forwards and backwards (DF), MOVS and LODS also with the source
; in an overridden segment (FS has a base of 1000h, so an override that is ignored shows), and
; MOVSW and MOVSD with the destination one byte above the source, where the element must be
; read whole before any of it is written. Four passes, so that each instruction is met by the
; general path, then by its executor three times.
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
.pass:
    mov  dword [0x8000], 0x44332211
    mov  dword [0x8004], 0x88776655
    mov  dword [0x9000], 0xDDCCBBAA     ; what FS:8000h is
    mov  dword [0x9004], 0x0A0B0C0D
    cld
    mov  esi, 0x8000
    mov  edi, 0x8100
    movsd                               ; A5
    movsw                               ; 66 A5
    movsb                               ; A4
    mov  eax, [0x8100]
    mov  ebx, [0x8104]
    mov  esi, 0x8000
    fs movsd                            ; 64 A5: the source is FS:8000h
    fs movsb
    mov  edx, [0x8108]                  ; the last three bytes of the MOVSD and the MOVSB
    mov  esi, 0x8000
    lodsb                               ; AC
    fs lodsb
    mov  edi, 0x8001
    scasb                               ; AE: AL against 22h
    mov  al, 0x22
    mov  edi, 0x8001
    scasb                               ; equal
    mov  eax, 0xCAFEF00D
    mov  edi, 0x8200
    stosd                               ; AB
    stosb                               ; AA
    mov  ecx, [0x8200]
    mov  ebx, [0x8204]
    mov  esi, 0x8000                    ; the destination one byte above the source
    mov  edi, 0x8001
    movsw
    movsd
    mov  eax, [0x8000]
    mov  edx, [0x8004]
    std                                 ; and the same going down
    mov  esi, 0x9004
    mov  edi, 0x8304
    movsd
    movsw
    movsb
    mov  eax, [0x8304]
    mov  edx, [0x8300]
    mov  esi, 0x9003
    lodsb
    mov  edi, 0x9003
    scasb
    mov  edi, 0x8404
    stosd
    stosb
    mov  ecx, [0x8404]
    mov  ebx, [0x8400]
    cld
    dec  ebp
    jnz  near .pass
    hlt
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
