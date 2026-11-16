; Self-check for INVLPG in ring 0 on a page that ring 3 has used (E045; s_invlpg is for ring
; 0's own pages). The TLB keeps the two privilege levels apart, and INVLPG has to forget the
; page for both. The first 4 MB are mapped as they lie, for all.
;
; Ring 3 reads 70000h (50000h) and writes what it read to 70008h, stops at HLT (a general protection fault, whose handler changes
;    the entry to 51000h and names the page), and reads and writes again. Ring 0 reads it before and
;    after too, so that its own entry is there to be mistaken for ring 3's.
;
; INVLPG is a 486's, so this runs on the i686. Prints "OK".
%define CPU686
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
    mov  dword [0x9004], 0x6000         ; the TSS at 9000h: the stack for ring 0
    mov  dword [0x9008], 0x10
    mov  ax, 0x30
    ltr  ax
    mov  edi, 0x11000
    mov  eax, 7
    mov  ecx, 1024
.fill:
    stosd
    add  eax, 0x1000
    dec  ecx
    jnz  .fill
    mov  dword [0x10000], 0x11007
    mov  eax, 0x10000
    mov  cr3, eax
    mov  eax, cr0
    or   eax, 0x80000000
    mov  cr0, eax
    mov  dword [0x50000], 0x11111111
    mov  dword [0x51000], 0x22222222
    mov  esi, ucode                     ; ring 3's code, to 30000h
    mov  edi, 0x30000
    mov  ecx, ucode_end - ucode
    rep movsb
    xor  ecx, ecx                       ; the sum
    xor  edi, edi
    mov  dword [0x11000 + 0x70*4], 0x50007
    mov  eax, [0x70000]
    call mix
    mov  ax, 0x2B                       ; to ring 3 with its data segment
    mov  ds, ax
    push dword 0x2B
    push dword 0x5000
    push dword 2
    push dword 0x23
    push dword 0x30000
    iretd
ucode:                                  ; runs at 30000h; nothing in it depends on where it is
    mov  esi, [0x70000]
    mov  [0x70008], esi
    hlt
    mov  edi, [0x70000]
    mov  [0x70008], edi
    hlt
ucode_end:
mix:
    lea  ecx, [ecx + ecx*2]
    add  ecx, eax
    ret
gp:                                     ; at ring 3's HLT
    mov  ax, 0x10
    mov  ds, ax
    test edi, edi
    jnz  .done
    mov  dword [0x11000 + 0x70*4], 0x51007
    invlpg [0x70000]
    mov  eax, [0x70000]
    call mix
    mov  ax, 0x2B
    mov  ds, ax
    add  esp, 4
    inc  dword [ss:esp]                 ; past the HLT
    iretd
.done:
    mov  eax, esi
    call mix
    mov  eax, edi
    call mix
    mov  eax, [0x50008]
    call mix
    mov  eax, [0x51008]
    call mix
    mov  eax, cr0
    and  eax, 0x7FFFFFFF
    mov  cr0, eax
    jmp  0x18:leave
bits 16
leave:
    mov  eax, cr0
    and  al, 0xFE
    mov  cr0, eax
    jmp  0:real
real:
    xor  ax, ax
    mov  ds, ax
    mov  ss, ax
    lidt [ridtr]
    cmp  ecx, 0x55555537
    jne  .no
    mov  ax, 0x0E4F
    int  0x10
    mov  ax, 0x0E4B
    int  0x10
    hlt
.no:
    mov  ax, 0x0E4E
    int  0x10
    hlt
align 8
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
    dq 0x00009A000000FFFF               ; 16-bit code
    dq 0x00CFFA000000FFFF               ; ring 3's code
    dq 0x00CFF2000000FFFF               ; ring 3's data
    dq 0x0000890090000067               ; the TSS at 9000h
gdtr:
    dw 55
    dd gdt
idtr:
    dw 15*8 - 1
    dd 0x8000
ridtr:
    dw 0x3FF
    dd 0
    TAIL
