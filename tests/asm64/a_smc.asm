; Code that changes (E107): an instruction is run three times, so that whatever remembers
; what it decoded has it, then some of its bytes are written and it is run three times
; more. The opcode, the ModRM byte, a displacement, a prefix put in front, the REX prefix,
; an address relative to RIP; a store that begins on the page before the code's, which
; holds no code; code far into its page; an instruction that lies on two pages, changed on
; the second (its opcode there, then its displacement); instructions with a constant after
; an address relative to RIP, and with an address of 32 bits, run three times on a page that nothing is stored to; and last, a
; store beside the code that changes none of it, forty times over.
%include "elf.inc"

spot equ $$ + 0x100000                       ; memory past the file's end, with no code near it

%macro RUNAT 1
    mov ecx, 3
%%again:
    call %1
    dec ecx
    jnz %%again
%endmacro
%define RUN RUNAT area

    mov eax, 100
    mov ebx, 7
    mov r11d, 5
    lea rsi, [buf]
    RUN
    mov byte [area], 0x29               ; ADD EAX, EBX becomes SUB EAX, EBX
    RUN
    mov byte [area + 1], 0x1E           ; SUB [RSI], EBX
    RUN
    mov rdx, [buf]
    mov word [area + 1], 0x085E         ; SUB [RSI + 8], EBX
    RUN
    mov rdx, [buf + 8]
    mov byte [area + 2], 16             ; SUB [RSI + 16], EBX
    RUN
    mov rdx, [buf + 16]
    mov dword [area], 0x90D82966        ; SUB AX, BX
    RUN
    mov dword [area], 0x90D82948        ; SUB RAX, RBX
    RUN
    mov byte [area], 0x4C               ; SUB RAX, R11
    RUN
    mov dword [area], 0x90068B67        ; MOV EAX, [ESI], with the prefix 67h
    RUN
    mov word [area], 0x058B             ; MOV EAX, [the first word of buf, by RIP]
    mov dword [area + 2], buf - (area + 6)
    RUN
    add dword [area + 2], 8             ; the second word
    RUN
    RUNAT area2
    mov rdi, 0x9090D82900000000         ; four bytes on the page before, then SUB EAX, EBX
    mov [area2 - 4], rdi
    RUNAT area2
    mov word [area2 - 1], 0x3100        ; one byte before, then XOR EAX, EBX
    RUNAT area2
    mov rdi, 0x90D8210000000000         ; five bytes before, then AND EAX, EBX
    mov [area2 - 5], rdi
    RUNAT area2
    mov rdx, [area2 - 8]
    RUNAT area3
    mov byte [area3], 0x29              ; far into the page: SUB EAX, EBX
    RUNAT area3
    RUNAT area4
    mov byte [area4 + 1], 0x29          ; the opcode, on the page after the prefix's: SUB AX, BX
    RUNAT area4
    RUNAT area5
    mov byte [area5 + 2], 16            ; the displacement, on the page after the opcode's
    RUNAT area5
    mov rdi, 0x1111111122222222
    mov [spot], rdi
    mov [spot + 8], rdi
    mov [spot + 16], rdi
    call thrice
    mov rdx, [spot]
    mov rdi, [spot + 8]
    mov dword [area], 0x90D80148        ; ADD RAX, RBX
    mov word [area + 4], 0x9090
    mov ecx, 40
.beside:
    inc dword [beside]                  ; a store on the code's page that is not into code
    call area
    dec ecx
    jnz .beside
    mov edx, [beside]
    EXIT

    align 16
area:
    db 0x01, 0xD8, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90
    ret
    align 4
beside: dd 0
    align 16
buf: dq 0x1111111122222222, 0x3333333344444444, 0x5555555566666666, 0x7777777788888888
    align 4096
    times 4096 db 0                     ; a page with no code on it
area2:
    db 0x01, 0xD8, 0x90, 0x90           ; ADD EAX, EBX
    ret
    times 0xC00 - ($ - area2) db 0
area3:
    db 0x01, 0xD8                       ; ADD EAX, EBX
    ret
    times 0xFFF - ($ - area2) db 0
area4:
    db 0x66, 0x01, 0xD8                 ; ADD AX, BX, its prefix the page's last byte
    ret
    times 0x1FFE - ($ - area2) db 0
area5:
    db 0x03, 0x46, 0x08                 ; ADD EAX, [RSI + 8], its displacement on the next page
    ret
    align 4096
thrice:
    mov r8d, 0xFFFFFFF0
    mov r9d, 0x20
    mov ecx, 3
.again:
    add dword [spot], 5                  ; relative to RIP, with a constant after the address
    add dword [spot + 4], 0x12345
    cmp byte [spot + 1], 0x22
    mov word [spot + 8], 0x1234
    imul edx, [spot + 16], 3
    lea rdi, [r8d + r9d * 2]            ; an address of 32 bits that wraps
    lea r10, [spot]
    dec ecx
    jnz .again
    ret
file_end:
