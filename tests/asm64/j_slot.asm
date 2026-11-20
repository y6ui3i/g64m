; Two instructions that share an entry of the decode cache (E120): the first begins a
; translated block; when the second, which the short front does not run, takes the entry,
; nothing of the block may be left with it.
%include "elf.inc"

    mov r15d, 20
    xor r14d, r14d
    jmp hot
    times 0x1000 - ($ - $$) db 0x90
hot:                                    ; at 401000h
    add eax, 3
    xor ebx, eax
    dec r15d
    jnz hot
    test r14d, r14d
    jnz done
    mov r14d, 1
    jmp other
done:
    EXIT
    times 0x41001 - ($ - $$) db 0x90
other:                                  ; at 441001h: the same entry as 401000h
    cld
    mov r15d, 3
    jmp hot
file_end:
