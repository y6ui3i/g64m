; Self-check for INVLPG (E045): it forgets the translation of one page, and it has to forget
; all of it: for a read, for a write and for the fetch of code. (s_invlpgu is for ring 3.)
; Each part uses a page, points its page table entry at another physical page, names the page
; to INVLPG and uses it again; what comes back goes into a sum that depends on the order
; (three times the sum, plus the value). The first 4 MB are mapped as they lie, for all.
;
; 1. a read of 70000h: 50000h, then 51000h
; 2. a write to 70008h: lands in 51000h, then in 50000h
; 3. code at 72000h, called four times: 52000h (INC EDX), then 53000h (INC EBX)
; 4. code at 72010h that names its own page and goes on: INVLPG, then INC EDX in 52000h and
;    INC EBX in 53000h. Called once with the entry at 52000h, then once more after the entry
;    is changed: it starts in 52000h, which the TLB still has (a read in between sees to
;    that: the first call's own INVLPG had taken it out), and must go on in 53000h.
;
; The sum is fed once before anything, so that the stack's page has been read and the read
; in part 1 is the last page read when INVLPG comes.
; INVLPG is a 486's, so this runs on the i686. Prints "OK".
%define CPU686
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
    mov  word [0x52000], 0xC342         ; inc edx / ret
    mov  word [0x53000], 0xC343         ; inc ebx / ret
    mov  dword [0x52010], 0x003D010F    ; invlpg [72000h] / inc edx / ret
    mov  dword [0x52014], 0x42000720
    mov  byte [0x52018], 0xC3
    mov  dword [0x53010], 0x003D010F    ; invlpg [72000h] / inc ebx / ret
    mov  dword [0x53014], 0x43000720
    mov  byte [0x53018], 0xC3
    xor  ecx, ecx                       ; the sum
    xor  edx, edx
    xor  ebx, ebx
    xor  eax, eax
    call mix
    mov  esi, 0x11000 + 0x70*4          ; the entry for 70000h
    mov  dword [esi], 0x50007           ; 1
    mov  eax, [0x70000]
    call mix
    mov  dword [esi], 0x51007
    invlpg [0x70000]
    mov  eax, [0x70000]
    call mix
    mov  dword [0x70008], 0xAAAAAAAA    ; 2
    mov  dword [esi], 0x50007
    invlpg [0x70000]
    mov  dword [0x70008], 0xBBBBBBBB
    mov  eax, [0x51008]
    call mix
    mov  eax, [0x50008]
    call mix
    mov  dword [esi + 8], 0x52007       ; 3: the entry for 72000h
    call four
    mov  dword [esi + 8], 0x53007
    invlpg [0x72000]
    call four
    mov  eax, edx
    call mix
    mov  eax, ebx
    call mix
    mov  dword [esi + 8], 0x52007       ; 4
    invlpg [0x72000]
    mov  ebp, 0x72010
    call ebp
    mov  eax, [0x72000]                 ; the TLB has the page again, as 52000h
    mov  dword [esi + 8], 0x53007
    call ebp
    mov  eax, edx
    call mix
    mov  eax, ebx
    call mix
    mov  eax, cr0
    and  eax, 0x7FFFFFFF
    mov  cr0, eax
    jmp  0x18:leave
four:
    mov  ebp, 4
.l:
    mov  eax, 0x72000
    call eax
    dec  ebp
    jnz  .l
    ret
mix:
    lea  ecx, [ecx + ecx*2]
    add  ecx, eax
    ret
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
    cmp  ecx, 0x6666653a
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
gdtr:
    dw 31
    dd gdt
    TAIL
