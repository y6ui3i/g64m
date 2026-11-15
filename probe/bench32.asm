; A loop of one instruction (or a few) in 32-bit protected mode, to count what the interpreter
; spends on it. Assemble with the body given on the command line:
;   nasm -f bin -DBODY="mov eax, [ebx+8]" -o build/bench32.bin probe/bench32.asm
; and run it under /usr/bin/time -l, which reports the host instructions retired. The loop is
; ITER times: BODY, DEC ECX, JNZ. An empty BODY gives the cost of the loop itself. BODY2 and BODY3
; are two more lines for the body, for when it takes more than one instruction. INIT and INIT2
; are lines run before the loop; with OUTER the whole thing, INIT and INIT2 included, is done
; OUTER times, for a body that moves a pointer and has to stay inside the first megabyte (this
; machine's addresses wrap there). They are lines run once before the loop (the registers it starts with are set just above the loop).
%ifndef ITER
%define ITER 20000000
%endif
org 0x7C00
bits 16
    cli
    xor  ax, ax
    mov  ds, ax
    lgdt [gdtr]
    mov  eax, cr0
    or   al, 1
    mov  cr0, eax
    jmp  0x08:start32
bits 32
start32:
    mov  ax, 0x10
    mov  ds, ax
    mov  es, ax
    mov  ss, ax
    mov  esp, 0x7000
    mov  ebx, 0x8000
    mov  esi, 0x9000
    mov  edi, 0xA000
%ifdef OUTER
    mov  edx, OUTER
.outer:
%endif
    mov  ecx, ITER
%ifdef INIT
    INIT
%endif
%ifdef INIT2
    INIT2
%endif
    align 16
.loop:
%ifdef BODY
    BODY
%endif
%ifdef BODY2
    BODY2
%endif
%ifdef BODY3
    BODY3
%endif
    dec  ecx
    jnz  .loop
%ifdef OUTER
    dec  edx
    jnz  near .outer
%endif
    hlt
fn:
    ret
align 8
gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
gdtr:
    dw 23
    dd gdt
    times 510-($-$$) db 0
    dw 0xAA55
