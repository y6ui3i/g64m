; Self-check for the flags of an instruction that faults on its store. An instruction that
; works out a result, sets the flags and then stores the result to memory must leave the flags
; as it found them when the store takes a page fault, and inside a run of short executors
; nothing puts them back afterwards (E049): the executor has the old flags in place while it
; stores. Thirteen instructions, one for each executor that sets flags before a store, each on
; a page that may be read and not written, each after a CMP that leaves ZF and PF set and the
; rest clear, and each with an operand that would set a flag the CMP left clear. The fault
; handler looks at the flags in its frame, and at the address: a run does not keep the
; instruction pointer up, and the fault must be reported against the instruction all the same. Four passes, so that the last ones run from the
; decode cache. Write protection in ring 0, so this runs on the i686. Prints "OK".
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
    mov  dword [0x8000 + 14*8], 0x00080000 + pf     ; the #PF gate: selector 8, offset pf
    mov  dword [0x8000 + 14*8 + 4], 0x00008E00
    mov  edi, 0x11000                   ; one page table: the first 4 MB as they lie
    mov  eax, 3
    mov  ecx, 1024
.fill:
    stosd
    add  eax, 0x1000
    dec  ecx
    jnz  .fill
    mov  esi, 0x20000
    mov  dword [esi], 0xFFFFFFFF        ; every operand but INC's: nothing is ever stored
    mov  dword [esi+4], 0x7FFFFFFF      ; INC's
    and  dword [0x11000 + 0x20*4], ~2   ; 20000h: not writable
    mov  dword [0x10000], 0x11003       ; the page directory's first entry
    mov  eax, 0x10000
    mov  cr3, eax
    mov  eax, cr0
    or   eax, 0x80010000                ; paging, and write protection in ring 0
    mov  cr0, eax
    xor  edx, edx                       ; counts the faults; bit 16 says one had the wrong flags
    mov  eax, 0x80
    mov  ecx, 4
    mov  ebp, 4
pass:
    mov  edi, [esi]                     ; a read: no fault, and the read TLB has the page
    mov  ebx, .r1
    cmp  esi, esi
    adc  [esi], eax                 ; #PF: ADC r/m, r
.r1:
    mov  ebx, .r2
    cmp  esi, esi
    sbb  dword [esi], 5             ; #PF: SBB r/m, imm
.r2:
    mov  ebx, .r3
    cmp  esi, esi
    rol  dword [esi], 3             ; #PF: a rotate by a constant
.r3:
    mov  ebx, .r4
    cmp  esi, esi
    shl  dword [esi], cl            ; #PF: a shift by CL
.r4:
    mov  ebx, .r5
    cmp  esi, esi
    add  [esi], al                  ; #PF: 8-bit r/m, r
.r5:
    mov  ebx, .r6
    cmp  esi, esi
    add  byte [esi], 0x7F           ; #PF: 8-bit r/m, imm
.r6:
    mov  ebx, .r7
    cmp  esi, esi
    shl  dword [esi], 4             ; #PF: SHL by a constant
.r7:
    mov  ebx, .r8
    cmp  esi, esi
    shr  dword [esi], 4             ; #PF: SHR by a constant
.r8:
    mov  ebx, .r9
    cmp  esi, esi
    sar  dword [esi], 4             ; #PF: SAR by a constant
.r9:
    mov  ebx, .r10
    cmp  esi, esi
    neg  dword [esi]                ; #PF: NEG
.r10:
    mov  ebx, .r11
    cmp  esi, esi
    add  [esi], eax                 ; #PF: ADD r/m, r
.r11:
    mov  ebx, .r12
    cmp  esi, esi
    inc  dword [esi+4]              ; #PF: INC r/m
.r12:
    mov  ebx, .r13
    cmp  esi, esi
    sub  dword [esi], 1             ; #PF: SUB r/m, imm
.r13:
    dec  ebp
    jnz  pass
    mov  eax, cr0
    and  eax, 0x7FFEFFFF
    mov  cr0, eax
    jmp  0x18:leave
pf:                                     ; counts, checks the address and the flags, and resumes at the address in EBX
    mov  edi, ebx                       ; the fault is reported against the instruction itself:
    sub  edi, [esp+4]                   ; its length, summed in EDX from bit 20 up
    shl  edi, 20
    add  edx, edi
    inc  edx
    mov  edi, [esp+12]
    and  edi, 0x8D5                     ; OF SF ZF AF PF CF
    cmp  edi, 0x44                      ; as the CMP left them
    je   .good
    or   edx, 0x10000
.good:
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
    cmp  edx, 52 + (4*34 << 20)         ; thirteen faults a pass, 34 bytes of instructions, no wrong flags
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
gdtr:
    dw 31
    dd gdt
idtr:
    dw 15*8 - 1
    dd 0x8000
ridtr:
    dw 0x3FF
    dd 0
    TAIL
