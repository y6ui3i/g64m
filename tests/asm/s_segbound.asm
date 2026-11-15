; Self-check for the bound that lets an access skip the segment tests (seg_top). The bound has
; to follow the segment register: after DS has held a flat segment, loading one with a limit of
; FFh must make an access at 200h fault, and loading a null selector into FS must make any
; access through it fault. A bound left over from the segment before would let both through.
; The instructions that read an operand and write it back (ADD to memory, INC of memory) find
; their place in memory by a path of their own, so they are tried against the small segment too.
; Four passes, so that the accesses are made by the general path and then by their executors.
; Prints "OK".
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
    mov  esp, 0x7000
    mov  dword [0x8000 + 13*8], 0x00080000 + gp     ; the #GP gate: selector 8, offset gp
    mov  dword [0x8000 + 13*8 + 4], 0x00008E00
    xor  edx, edx                       ; counts the faults
    mov  ebp, 4
pass:
    mov  ax, 0x10
    mov  ds, ax
    mov  fs, ax
    mov  eax, [0x9000]                  ; flat: no fault
    mov  eax, [fs:0x9000]
    mov  ax, 0x18                       ; a data segment with a limit of FFh
    mov  ds, ax
    mov  eax, [0x80]                    ; inside it: no fault
    mov  [0x80], eax                    ; and a write, so that the write TLB has the page
    mov  ebx, .r1
    mov  eax, [0x200]                   ; beyond it: #GP
.r1:
    mov  ebx, .r2
    mov  [0x200], eax                   ; and a write: #GP
.r2:
    mov  ebx, .r2a
    add  [0x200], eax                   ; an instruction that reads and writes it: #GP
.r2a:
    mov  ebx, .r2b
    inc  dword [0x200]                  ; #GP
.r2b:
    xor  eax, eax
    mov  fs, ax                         ; a null selector
    mov  ebx, .r3
    mov  eax, [fs:0x9000]               ; #GP
.r3:
    dec  ebp
    jnz  pass
    mov  ax, 0x10
    mov  ds, ax
    jmp  0x20:leave
gp:                                     ; counts, and resumes at the address in EBX
    inc  edx
    mov  [esp+4], ebx
    add  esp, 4
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
    cmp  edx, 20                        ; five faults a pass
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
    dq 0x00409200000000FF               ; data, base 0, limit FFh
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
