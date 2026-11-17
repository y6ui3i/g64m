; Self-check for generated code going on into another page (E069; the same answer with --jit
; and without). A CALL to another page and the RET back do not come back to the interpreter:
; code they share (the far way) finds the block at the address, by the tests a run of the
; interpreter makes when it changes page and the ones made before a block is entered. Each
; test is taken here once the blocks exist. A loop at 7Cxxh calls a function at 31010h, which
; is mapped to 40010h: two INC ESI and a RET. Forty passes; then
;   - the function is changed by a store through another address (40010h): one INC ESI. The
;     block made of the old one must not be run;
;   - 31000h is mapped to 41000h, where the function is two INC EDI, and 131000h to 40000h.
;     Each pass reads at 131000h first, which takes the TLB's place for 31000h: the far way
;     finds another page's tag there, and must not take that page's block for the function;
;   - the loop runs in a code segment whose limit is 31011h: the RET, at 31012h, is beyond it
;     and faults. The block must not be run to its end. The handler counts in EDX and returns
;     for the function.
; ESI 120, EDI 160 and EDX 40. Prints "OK".
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
    mov  dword [0x8000 + 13*8], 0x00080000 + gp     ; the #GP gate: selector 8, offset gp
    mov  dword [0x8000 + 13*8 + 4], 0x00008E00
    mov  dword [0x40010], 0x00C34646    ; 40010h (31010h when mapped): inc esi / inc esi / ret
    mov  dword [0x41010], 0x00C34747    ; 41010h (31010h later): inc edi / inc edi / ret
    mov  edi, 0x11000                   ; one page table: the first 4 MB as they lie
    mov  eax, 3
    mov  ecx, 1024
.fill:
    stosd
    add  eax, 0x1000
    dec  ecx
    jnz  .fill
    mov  dword [0x11000 + 0x31*4], 0x40003  ; but 31000h is at 40000h
    mov  dword [0x10000], 0x11003       ; the page directory's first entry
    mov  eax, 0x10000
    mov  cr3, eax
    mov  eax, cr0
    or   eax, 0x80000000
    mov  cr0, eax
    xor  esi, esi
    xor  edi, edi
    xor  edx, edx
    mov  ecx, 0x9000                    ; what each pass reads: nothing that matters, at first
    mov  ebx, 4                         ; four times forty passes
again:
    mov  ebp, 40
pass:
    mov  eax, [ecx]
    jmp  short .call                    ; the CALL in a block of its own, entered whatever the read did
.call:
    call 0x31010
    dec  ebp
    jnz  pass
    dec  ebx
    jz   done
    cmp  ebx, 3
    jne  .two
    mov  dword [0x40010], 0x00C39046    ; the function is now inc esi / nop / ret
    jmp  again
.two:
    cmp  ebx, 2
    jne  .three
    mov  dword [0x11000 + 0x31*4], 0x41003  ; 31000h is now at 41000h
    mov  dword [0x11000 + 0x131*4], 0x40003 ; and 131000h where the function was
    mov  ecx, 0x131000
    mov  eax, cr3
    mov  cr3, eax
    jmp  again
.three:
    mov  ecx, 0x9000
    jmp  0x20:again                     ; a code segment that ends inside the function
done:
    jmp  0x08:.flat
.flat:
    mov  eax, cr0
    and  eax, 0x7FFFFFFF
    mov  cr0, eax
    jmp  0x18:leave
gp:                                     ; counts a fault at the RET, and returns for the function
    cmp  dword [esp+4], 0x31012
    jne  .other
    inc  edx
.other:
    mov  eax, [esp+16]                  ; where the function was called from
    mov  [esp+4], eax
    mov  eax, [esp+12]                  ; the frame, four bytes up, over the return address
    mov  [esp+16], eax
    mov  eax, [esp+8]
    mov  [esp+12], eax
    mov  eax, [esp+4]
    mov  [esp+8], eax
    add  esp, 8
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
    cmp  esi, 120
    jne  .no
    cmp  edi, 160
    jne  .no
    cmp  edx, 40
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
    dq 0x00439A0000001011               ; 32-bit code, limit 31011h
gdtr:
    dw 39
    dd gdt
idtr:
    dw 15*8 - 1
    dd 0x8000
ridtr:
    dw 0x3FF
    dd 0
    TAIL
