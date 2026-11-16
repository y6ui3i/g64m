; Self-check for a run that goes on into another page of code (E042). When the next instruction
; is on a page other than the one being run, the run looks in the read TLB for it, and goes on
; only if the TLB has that page for the current privilege level. Two ways to get that wrong,
; neither of which a trace can show (tracing stops after every instruction, and no run goes
; anywhere):
;
; 1. Taking the TLB's slot without comparing its tag. `fa` at 40000h and `fb` at 140000h share
;    a slot. Called in turn, each must run its own bytes: ESI and EDI count them.
; 2. Taking the supervisor's entry in user mode. `fs` at 31000h is a supervisor's page, and
;    ring 0 runs it first, so that the supervisor's TLB and the decode cache have it. Then ring
;    3 calls it six times from 30000h: each call must take a page fault, and `fs` must not run.
;
; Each part goes round at least four times, so that the general path meets every instruction,
; then its executor. The first 4 MB are mapped as they lie, but for 140000h. Prints "OK".
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
    mov  dword [0x8000 + 14*8], 0x00080000 + pf     ; the #PF gate: selector 8, offset pf
    mov  dword [0x8000 + 14*8 + 4], 0x00008E00
    mov  dword [0x9004], 0x6000         ; the TSS at 9000h: the stack for ring 0
    mov  dword [0x9008], 0x10
    mov  ax, 0x30
    ltr  ax
    mov  edi, 0x11000                   ; one page table: the first 4 MB as they lie, for all
    mov  eax, 7
    mov  ecx, 1024
.fill:
    stosd
    add  eax, 0x1000
    dec  ecx
    jnz  .fill
    and  dword [0x11000 + 0x31*4], ~4   ; 31000h: the supervisor's
    mov  dword [0x11000 + 0x140*4], 0x50007  ; 140000h is at 50000h: address line 20 is off
    mov  dword [0x10000], 0x11007       ; the page directory's first entry
    mov  eax, 0x10000
    mov  cr3, eax
    mov  eax, cr0
    or   eax, 0x80000000
    mov  cr0, eax
    mov  word [0x40000], 0xC347         ; fa: inc edi / ret
    mov  word [0x140000], 0xC346        ; fb: inc esi / ret
    mov  word [0x31000], 0xC347         ; fs: inc edi / ret
    mov  dword [0x30000], 0x000FFBE8    ; ring 3's code: call 31000h / jmp to the call again
    mov  dword [0x30004], 0x00F9EB00
    xor  esi, esi
    xor  edi, edi
    xor  edx, edx                       ; counts the faults
    mov  ebp, 4
part1:
    mov  eax, 0x140000
    call eax                            ; fb
    mov  eax, 0x40000
    call eax                            ; fa: the slot is its page's now
    dec  ebp
    jnz  part1
    mov  ebp, 4
part2:
    mov  eax, 0x31000
    call eax                            ; fs in ring 0
    dec  ebp
    jnz  part2
    mov  ebp, 6
    push dword 0x2B                     ; to ring 3: SS, ESP, the flags, CS, EIP
    push dword 0x5000
    push dword 2
    push dword 0x23
    push dword 0x30000
    iretd
pf:                                     ; counts; goes back to ring 3's call, six times in all
    inc  edx
    dec  ebp
    jz   .done
    add  esp, 4
    mov  dword [esp], 0x30000
    iretd
.done:
    mov  ax, 0x10                       ; DS was emptied on the way to ring 3
    mov  ds, ax
    mov  eax, cr0
    and  eax, 0x7FFFFFFF
    mov  cr0, eax
    jmp  0x18:leave
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
    cmp  edx, 6                         ; a fault for every call from ring 3
    jne  .no
    cmp  esi, 4                         ; fb four times
    jne  .no
    cmp  edi, 8                         ; fa four times and fs four times, all in ring 0
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
