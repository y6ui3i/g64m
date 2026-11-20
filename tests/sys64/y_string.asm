; String instructions with a repeat count (E113): fills and copies that run over several
; pages, begin anywhere in an element, overlap, go down, use addresses of 32 bits, and
; meet a page that is not there in the middle, where the fault must find RCX, RSI and
; RDI as the repetitions before it left them. And a copy over code that has run.
;
; The pages are at 1 GB and above; the memory behind them (P) is reached also at its own
; address, which is how the results are read.
%include "sys.inc"
    jmp test
%include "idt.inc"

V equ 0x40000000
P equ 0x400000

%include "pt.inc"

; The hook for a page that is not there: notes where the string instruction had got to and
; what the last eight bytes before the page hold, then maps the page to [hook_phys].
note_and_map:
    mov [at_rcx], rcx
    mov [at_rsi], rsi
    mov [at_rdi], rdi
    mov rax, [f_cr2]
    and rax, -4096
    mov rax, [rax - 8]
    mov [at_mem], rax
    push rdi
    push rsi
    push rdx
    mov rdi, [f_cr2]
    and rdi, -4096
    mov rsi, [hook_phys]
    mov edx, 3
    call map
    pop rdx
    pop rsi
    pop rdi
    ret

; RAX = a sum of the RCX quadwords at RSI that depends on their order.
sum:
    push rsi
    push rcx
    xor eax, eax
.next:
    rol rax, 1
    add rax, [rsi]
    add rsi, 8
    dec rcx
    jnz .next
    pop rcx
    pop rsi
    ret

; Fills the RCX quadwords at RDI with numbers that are all different.
init:
    push rdi
    push rcx
    push rax
    mov rax, 0x0123456789ABCDEF
.next:
    mov [rdi], rax
    add rdi, 8
    mov r8, 0x9E3779B97F4A7C15
    add rax, r8
    dec rcx
    jnz .next
    pop rax
    pop rcx
    pop rdi
    ret

%macro SUM 2            ; the sum of %2 quadwords at physical %1, printed
    mov rsi, %1
    mov ecx, %2
    call sum
    PRINT rax
%endmacro
%macro INIT 2
    mov rdi, %1
    mov ecx, %2
    call init
%endmacro
%macro MAP4 2           ; four pages
    MAP %1, %2, 3
    MAP %1 + 0x1000, %2 + 0x1000, 3
    MAP %1 + 0x2000, %2 + 0x2000, 3
    MAP %1 + 0x3000, %2 + 0x3000, 3
%endmacro

test:
    call idt_init
    MAP4 V, P
    MAP4 V + 0x10000, P + 0x8000

    PUTS "fills over several pages, of each width, beginning anywhere"
    INIT P, 0x800
    mov rdi, V + 5
    mov ecx, 0x2FF0
    mov eax, 0x5A
    rep stosb
    PRINT rdi
    PRINT rcx
    SUM P, 0x800
    mov rdi, V + 0x1003
    mov ecx, 0x300
    mov rax, 0x1122334455667788
    rep stosq
    PRINT rdi
    SUM P, 0x800
    mov rdi, V + 0xFFD
    mov ecx, 0x333
    mov eax, 0xA1B2C3D4
    rep stosd
    mov rdi, V + 0x2FFF
    mov ecx, 0x101
    rep stosw
    PRINT rdi
    SUM P, 0x800

    PUTS "copies over several pages"
    INIT P, 0x800
    INIT P + 0x8000, 0x800
    mov rsi, V + 5
    mov rdi, V + 0x10007
    mov ecx, 0x2F00
    rep movsb
    PRINT rsi
    PRINT rdi
    PRINT rcx
    SUM P + 0x8000, 0x800
    mov rsi, V + 0xFF9
    mov rdi, V + 0x10FFE
    mov ecx, 0x3F0
    rep movsq
    SUM P + 0x8000, 0x800
    mov rsi, V + 0x1FFF
    mov rdi, V + 0x12001
    mov ecx, 0x155
    rep movsd
    mov rsi, V + 0x2FFF
    mov rdi, V + 0x10FFF
    mov ecx, 0x99
    rep movsw
    PRINT rsi
    PRINT rdi
    SUM P + 0x8000, 0x800

    PUTS "the source inside what is written"
    INIT P, 0x800
    mov rsi, V + 0x10
    mov rdi, V + 0x11
    mov ecx, 0x1800
    rep movsb                           ; one byte below: the first byte goes all the way
    SUM P, 0x800
    INIT P, 0x800
    mov rsi, V + 0x10
    mov rdi, V + 0x13
    mov ecx, 0x500
    rep movsd                           ; three bytes below, four at a time
    SUM P, 0x800
    INIT P, 0x800
    mov rsi, V + 0xFFC
    mov rdi, V + 0x1004
    mov ecx, 0x300
    rep movsq                           ; exactly one element below
    SUM P, 0x800
    INIT P, 0x800
    mov rsi, V + 0x1005
    mov rdi, V + 0x1000
    mov ecx, 0x300
    rep movsq                           ; above
    SUM P, 0x800

    PUTS "going down"
    INIT P, 0x800
    INIT P + 0x8000, 0x800
    std
    mov rsi, V + 0x2FF8
    mov rdi, V + 0x12FFB
    mov ecx, 0x500
    rep movsq
    mov rdi, V + 0x1234
    mov ecx, 0x1100
    mov eax, 0x77
    rep stosb
    mov rsi, V + 0x2000
    mov rdi, V + 0x2002
    mov ecx, 0x180
    rep movsd
    cld
    PRINT rsi
    PRINT rdi
    SUM P, 0x800
    SUM P + 0x8000, 0x800

    PUTS "addresses and a count of 32 bits"
    INIT P, 0x800
    mov rdi, 0x100000000 + V + 0x100
    mov rsi, 0x700000000 + V + 0x1800
    mov rcx, 0x300000000 + 0x900
    a32 rep movsb
    PRINT rsi
    PRINT rdi
    PRINT rcx
    mov rcx, 0x500000000 + 0x40
    mov rdi, 0x100000000 + V + 0xFE0
    mov rax, 0x0F0E0D0C0B0A0908
    a32 rep stosq
    PRINT rdi
    PRINT rcx
    SUM P, 0x800

    PUTS "a source in FS's segment"
    INIT P, 0x800
    mov ecx, 0xC0000100
    mov eax, 0x1800
    xor edx, edx
    wrmsr
    mov rsi, V + 0x20
    mov rdi, V + 0x40
    mov ecx, 0x600
    db 0x64                             ; FS: the source is 1800h further on
    rep movsb
    PRINT rsi
    SUM P, 0x800
    mov ecx, 0xC0000100
    xor eax, eax
    wrmsr

    PUTS "a fill that meets a page that is not there"
    MAP V + 0x20000, P + 0x10000, 3
    INIT P + 0x10000, 0x400
    mov qword [hook_phys], P + 0x11000
    mov qword [f_hook], note_and_map
    mov rdi, V + 0x20F00
    mov ecx, 0x400
    mov eax, 0xC3
    rep stosb
    PRINT [f_vec]
    PRINT [f_err]
    PRINT [f_cr2]
    PRINT [at_rcx]
    PRINT [at_rdi]
    PRINT [at_mem]
    PRINT rdi
    SUM P + 0x10000, 0x400

    PUTS "a copy whose source runs into one"
    MAP V + 0x22000, P + 0x12000, 3
    INIT P + 0x12000, 0x400
    mov qword [hook_phys], P + 0x13000
    mov rsi, V + 0x22FC4
    mov rdi, V + 0x10010
    mov ecx, 0x20
    rep movsq
    PRINT [f_err]
    PRINT [f_cr2]
    PRINT [at_rcx]
    PRINT [at_rsi]
    PRINT [at_rdi]
    SUM P + 0x8000, 0x40

    PUTS "an element that lies across the end of the last page that is there"
    MAP V + 0x24000, P + 0x14000, 3
    INIT P + 0x14000, 0x400
    mov qword [hook_phys], P + 0x15000
    mov rdi, V + 0x24F9C
    mov ecx, 0x30
    mov rax, 0x8877665544332211
    rep stosq
    PRINT [f_cr2]
    PRINT [at_rcx]
    PRINT [at_rdi]
    PRINT [at_mem]
    SUM P + 0x14000, 0x400
    PRINT [f_count]
    mov qword [f_hook], 0

    PUTS "a copy over code that has run"
    MAP V + 0x30000, P + 0x18000, 3
    mov rbx, V + 0x30000
    mov rax, 0x00C300000001B8           ; MOV EAX, 1, and RET
    mov [rbx + 0x80], rax
    lea rbx, [rbx + 0x80]
    mov r14d, 3
.again:
    call rbx
    dec r14d
    jnz .again
    PRINT rax
    lea rsi, [new_code]
    mov rdi, rbx
    mov ecx, 6
    rep movsb
    call rbx
    PRINT rax
    mov rdi, rbx
    inc rdi
    mov ecx, 1
    mov eax, 7
    rep stosb
    call rbx
    PRINT rax
    EXIT

new_code:
    db 0xB8, 2, 0, 0, 0, 0xC3           ; MOV EAX, 2, and RET
align 8
at_rcx: dq 0
at_rsi: dq 0
at_rdi: dq 0
at_mem: dq 0
hook_phys: dq 0
file_end:
