; Self-check for instructions in a page's last fifteen bytes (E088; the same answer with
; --jit and without). An instruction that begins there has an entry in the decode cache only
; when it ends in the page, and then its fetches are plain loads from the page: one that
; crosses into the next page and is taken for one that does not would read its last bytes
; from the start of its own page. A function of two dozen instructions (immediates of one and
; four bytes, a displacement, both conditional jumps after a compare, instructions with
; short executors and without) is copied to end 1 byte to its own length and 2 past the end of a page, so
; that each of its instructions in turn ends at the page's last byte, crosses it, and
; begins the next page; and is called twelve times at each place, enough for the JIT.
; Paging is on, and the page after is elsewhere in RAM (31000h): what lies after the first
; page in RAM is zeros, and so is that page's start, neither of which is what the next page
; holds.
; Everything is summed in EDI. The sum expected is a trace run's. Prints "OK".
%define CPU386
%include "common.inc"
page equ 0x21000                        ; the function is copied to end a little after this
start:
    cli
    xor  ax, ax
    mov  ds, ax
    mov  es, ax
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
    mov  edi, 0x10000                   ; a page table for the first 4 MB, as they are
    mov  eax, 7
.pt:
    stosd
    add  eax, 0x1000
    cmp  edi, 0x11000
    jb   .pt
    mov  dword [edi], 0x10007           ; and the directory after it
    mov  dword [0x10000 + 0x21*4], 0x31007  ; but the page after the function's first is elsewhere
    mov  cr3, edi
    mov  eax, cr0
    or   eax, 0x80000000
    mov  cr0, eax
    mov  ebp, 1                         ; how far past the page's end the function ends
place:
    mov  esi, blob
    mov  edi, page - blob_len
    add  edi, ebp
    mov  ebx, edi                       ; where the function is now
    mov  ecx, blob_len
    cld
    rep movsb
    mov  edi, [sum]
    mov  ecx, 12
again:
    mov  eax, edi
    add  eax, ecx
    mov  esi, cell
    push ecx
    call ebx
    pop  ecx
    add  edi, eax
    rol  edi, 1
    dec  ecx
    jnz  again
    mov  [sum], edi
    inc  ebp
    cmp  ebp, blob_len + 2
    jbe  place
    jmp  0x18:leave
blob:
    add  eax, 0x11223344
    mov  ebx, 0x55667788
    add  eax, ebx
    db   0x81, 0xF8                     ; cmp eax, 0x81020304 in its long form, which is
    dd   0x81020304                     ; made a pair with the jump after it
    jb   .a
    xor  eax, 0x0F0F0F0F
.a:
    lea  ecx, [eax+ebx*2+0x41021234]
    add  eax, ecx
    jmp  short .t
.back:
    rol  eax, 3
    jmp  short .b
.t:
    test ecx, 0x01010101                ; a pair with the jump after it, which goes backwards
    jnz  near .back
    ror  eax, 5
.b:
    imul edx, eax, 0x77
    add  eax, edx
    push eax
    pop  edx
    mov  [esi], edx
    add  eax, [esi]
    cmc
    adc  eax, 0x7F
    mov  ebx, page - blob_len           ; EBX back: where the function is
    add  ebx, ebp
    ret
blob_len equ $ - blob
bits 16
leave:                                  ; back to real mode, where the BIOS can print
    mov  eax, cr0
    and  eax, 0x7FFFFFFE
    mov  cr0, eax
    jmp  0:real
real:
    xor  ax, ax
    mov  ds, ax
    mov  ss, ax
    cmp  edi, 0x27633B86                ; from a trace run, one instruction at a time
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
align 4
sum:
    dd 0
cell equ 0x5000
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
    dq 0x00009A000000FFFF               ; 16-bit code
gdtr:
    dw 31
    dd gdt
    TAIL
