; Two instructions that share an entry of the decode cache (E120, E123): `hot` begins a
; translated block, and `other`, whose first instruction the short front does not run,
; takes the entry each time round. Nothing of the block may be left with the entry then;
; and a jump through a register to `other`, from a block, while the entry is hot's, must
; not go into hot's block.
%include "elf.inc"

    mov r13d, 12
    lea rsi, [hot]
outer:
    mov r15d, 20
    jmp rsi
back:
    dec r13d
    jnz outer
    EXIT
    times 0x1000 - ($ - $$) db 0x90
hot:                                    ; at 401000h
    add eax, 3
    xor ebx, eax
    dec r15d
    jz .out
    jmp rsi                             ; round again through a register: after `other` has
.out:                                   ; had the entry, these arrivals are the interpreter's,
    mov ecx, 1                          ; and hot is translated again each time
    lea rax, [other]
    jmp rax                             ; looked up in generated code: the entry is hot's
    times 0x41001 - ($ - $$) db 0x90
other:                                  ; at 441001h: the same entry as 401000h
    cld
    mov edx, 3
    jmp back
file_end:
