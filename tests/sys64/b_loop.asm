; Not a test: a loop to time the 64-bit machine with (E096). It sums and rewrites 1 MB of
; memory a qword at a time through a called routine, sixty times over, and prints the sum:
; about 63 million instructions, each of them a fetch through the page tables and most of
; them a read or a write of data.
%include "sys.inc"
    mov r8d, 60
    xor ebx, ebx
.pass:
    mov rsi, 0x800000
    mov ecx, 131072
.next:
    call step
    add rsi, 8
    dec ecx
    jnz .next
    dec r8d
    jnz .pass
    PRINT rbx
    EXIT
step:
    mov rax, [rsi]
    add rbx, rax
    add rax, rsi
    mov [rsi], rax
    ret
file_end:
