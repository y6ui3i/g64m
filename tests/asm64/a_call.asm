; CALL, JMP and PUSH of an operand in memory that is found from RSP (E118): the operand's
; address is worked out with RSP as it was, and the operand is read before the return
; address is written: a CALL through the very place the address goes to calls what was there.
%include "elf.inc"

    lea rax, [one]
    lea rbx, [two]
    push rbx                            ; [rsp + 8]: two
    push rax                            ; [rsp]: one
    xor eax, eax
    call [rsp + 8]                      ; two, and not what is 8 above the pushed address
    mov rdx, rax
    call [rsp]                          ; one
    mov [rsp - 8], rbx                  ; two, where the return address is about to go
    call [rsp - 8]
    lea rcx, [.back]
    push rcx
    jmp [rsp + 16]                      ; two, which returns to .back
.back:
    push qword [rsp]                    ; one, again
    push qword [rsp + 16]               ; two: 16 above before the push
    pop rsi
    pop rdi
    push word [rsp + 8]                 ; 66h: two bytes of it, RSP down by 2
    pop cx
    mov r8, rsp
    lea rsp, [rsp + 16]
    mov r9, 0x1122334455667788
    push r9
    inc qword [rsp]                     ; the group's other fields, on the stack
    dec dword [rsp + 4]
    inc byte [rsp + 7]
    pop r10
    EXIT

one:
    mov eax, 1
    ret
two:
    lea eax, [rax + 2]
    ret
file_end:
