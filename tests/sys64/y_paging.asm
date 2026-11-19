; Four-level paging at privilege level 0: pages of 4 KB and 2 MB, two addresses for one
; page, the accessed and dirty bits, pages that are not there, pages that may not be
; written, pages that may not be executed, and an access that lies across two pages.
;
; New tables are taken from 300000h up, which is zero. The addresses used are at 1 GB and
; above, outside the first gigabyte that sys.inc maps. An entry that was in use is
; invalidated when it is changed, as a CPU with a TLB needs.
%include "sys.inc"
    jmp test
%include "idt.inc"

V equ 0x40000000            ; where the test's pages go
P equ 0x400000              ; the memory behind them, reached also at its own address

; The address of the entry for linear address RDI at the level whose index starts at bit CL
; (39, 30, 21 or 12), in RAX; tables on the way are made as needed.
entry:
    push rbx
    push rdx
    push rsi
    mov rbx, cr3
    and rbx, -4096
    mov esi, 39
.down:
    mov rax, rdi
    xchg ecx, esi
    shr rax, cl
    xchg ecx, esi
    and eax, 511
    lea rax, [rbx + rax * 8]
    cmp esi, ecx
    je .done
    mov rdx, [rax]
    test dl, 1
    jnz .have
    mov rdx, [next_table]
    add qword [next_table], 4096
    or rdx, 7
    mov [rax], rdx
.have:
    mov rbx, rdx
    and rbx, -4096
    mov rdx, 0x000FFFFFFFFFFFFF
    and rbx, rdx
    sub esi, 9
    jmp .down
.done:
    pop rsi
    pop rdx
    pop rbx
    ret

; Maps the 4 KB page at RDI to physical RSI with the bits in RDX.
map:
    push rax
    push rcx
    mov ecx, 12
    call entry
    mov rcx, rsi
    or rcx, rdx
    mov [rax], rcx
    pop rcx
    pop rax
    ret

%macro MAP 3
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    call map
%endmacro

; Prints the entry of the level whose index starts at bit %2, for address %1.
%macro SHOW_ENTRY 2
    mov rdi, %1
    mov ecx, %2
    call entry
    PRINT [rax]
%endmacro

; The hook for a page that is not there: maps the page that faulted to P + 3000h, writable.
map_missing:
    push rdi
    push rsi
    push rdx
    mov rdi, [f_cr2]
    and rdi, -4096
    mov rsi, P + 0x3000
    mov edx, 3
    call map
    pop rdx
    pop rsi
    pop rdi
    ret

test:
    call idt_init

    PUTS "one page at two addresses"
    MAP V, P, 3
    MAP V + 0x1000, P, 3
    mov rax, 0x1122334455667788
    mov rbx, V
    mov [rbx], rax
    PRINT [abs P]
    PRINT [rbx + 0x1000]
    mov dword [abs P + 4], 0xAABBCCDD
    PRINT [rbx]

    PUTS "accessed and dirty"
    MAP V + 0x2000, P + 0x1000, 3
    SHOW_ENTRY V + 0x2000, 12
    mov rbx, V + 0x2000
    mov rax, [rbx]
    SHOW_ENTRY V + 0x2000, 12
    mov [rbx], rax
    SHOW_ENTRY V + 0x2000, 12
    SHOW_ENTRY V + 0x2000, 21
    SHOW_ENTRY V + 0x2000, 30
    SHOW_ENTRY V + 0x2000, 39
    ; A table that nothing has gone through yet has no accessed bit.
    MAP V + 0x40000000, P + 0x1000, 3
    SHOW_ENTRY V + 0x40000000, 30
    SHOW_ENTRY V + 0x40000000, 21

    PUTS "a page that is not there, read"
    mov qword [f_resume], .n1
    mov rbx, V + 0x5008
    mov rax, [rbx]
.n1:
    SHOW_FAULT
    PRINT [f_cr2]
    PUTS "written"
    mov qword [f_resume], .n2
    mov [rbx], rax
.n2:
    PRINT [f_err]
    PRINT [f_cr2]
    PUTS "executed"
    mov qword [f_resume], .n3
    call rbx
.n3:
    PRINT [f_err]
    PRINT [f_cr2]
    PRINT [f_rip]
    add rsp, 8
    PUTS "put there by the handler, and the instruction run again"
    mov qword [f_hook], map_missing
    mov rax, 0x0DDC0FFEE0DDF00D
    mov [rbx], rax
    mov qword [f_hook], 0
    PRINT [abs P + 0x3008]
    PRINT [f_count]
    SHOW_ENTRY V + 0x5000, 12

    PUTS "a page that may not be written"
    MAP V + 0x6000, P + 0x4000, 1
    mov rbx, V + 0x6000
    mov rax, 0x5555
    mov [rbx], rax
    PRINT [abs P + 0x4000]
    SHOW_ENTRY V + 0x6000, 12
    mov rax, cr0
    or eax, 0x10000
    mov cr0, rax
    mov qword [f_resume], .w1
    mov qword [rbx + 8], 0x6666
.w1:
    SHOW_FAULT
    PRINT [f_cr2]
    PRINT [abs P + 0x4008]
    PRINT [rbx]
    ; The write that was refused leaves no accessed bit on a page nothing else has touched.
    MAP V + 0x8000, P + 0x7000, 1
    mov qword [f_resume], .w3
    mov rbx, V + 0x8000
    mov qword [rbx], 0x9999
.w3:
    PRINT [f_err]
    SHOW_ENTRY V + 0x8000, 12
    ; Not writable higher up is not writable either.
    MAP V + 0x200000, P + 0x5000, 3
    mov rdi, V + 0x200000
    mov ecx, 21
    call entry
    and qword [rax], -3
    mov qword [f_resume], .w2
    mov rbx, V + 0x200000
    mov qword [rbx], 0x7777
.w2:
    PRINT [f_err]
    PRINT [f_cr2]
    mov rax, cr0
    and eax, ~0x10000
    mov cr0, rax
    mov qword [rbx], 0x8888
    PRINT [abs P + 0x5000]

    PUTS "a page that may not be executed"
    MAP V + 0x7000, P + 0x6000, 3
    mov rbx, V + 0x7000
    mov byte [rbx], 0xC3
    call rbx
    ; Until EFER says so, the bit is one that must be clear.
    MAP V + 0xA000, P + 0x6000, 3
    mov rdi, V + 0xA000
    mov ecx, 12
    call entry
    bts qword [rax], 63
    mov qword [f_resume], .x0
    mov rbx, V + 0xA000
    mov rax, [rbx]
.x0:
    SHOW_FAULT
    PRINT [f_cr2]
    mov rbx, V + 0x7000
    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x800
    wrmsr
    rdmsr
    PRINT rax
    mov rdi, V + 0x7000
    mov ecx, 12
    call entry
    bts qword [rax], 63
    invlpg [rbx]
    PRINT [rbx]
    mov qword [f_resume], .x1
    call rbx
.x1:
    SHOW_FAULT
    PRINT [f_cr2]
    add rsp, 8
    ; With the bit on, a page that is not there says "executed" in its error code too.
    mov qword [f_resume], .x2
    mov rbx, V + 0x9000
    call rbx
.x2:
    PRINT [f_err]
    add rsp, 8

    PUTS "across two pages"
    MAP V + 0x10000, P + 0x8000, 3
    MAP V + 0x11000, P + 0xA000, 3
    mov rbx, V + 0x10FFD
    mov rax, 0x8877665544332211
    mov [rbx], rax
    PRINT [abs P + 0x8FF8]
    PRINT [abs P + 0xA000]
    PRINT [rbx]
    ; The second page is not there: nothing of the write is done.
    MAP V + 0x12000, P + 0xB000, 3
    mov rbx, V + 0x12FFC
    mov qword [f_resume], .c1
    mov rax, -1
    mov [rbx], rax
.c1:
    SHOW_FAULT
    PRINT [f_cr2]
    PRINT [abs P + 0xBFF8]

    PUTS "an entry changed and invalidated"
    mov rbx, V
    PRINT [rbx]
    MAP V, P + 0x1000, 3
    invlpg [rbx]
    PRINT [rbx]
    MAP V, P, 3
    mov rax, cr3
    mov cr3, rax
    PRINT [rbx]

    PUTS "a handler in the upper half of the addresses"
    ; The first gigabyte again at FFFF800000000000h, and vector 5's gate pointing there.
    mov rax, cr3
    mov rbx, [rax]
    mov [rax + 256 * 8], rbx
    mov ecx, 5
    mov rax, 0xFFFF800000000000
    lea rdx, [stub5]
    add rax, rdx
    mov dl, 0x8E
    call set_gate
    int 5
    PRINT [f_vec]
    PRINT [f_where]
    int3
    PRINT [f_where]

    PUTS "a page of 2 MB"
    mov rdi, V + 0x400000
    mov ecx, 21
    call entry
    mov qword [rax], 0x800000 + 0x83
    mov rbx, V + 0x400000 + 0x123458
    mov rax, 0xCAFE
    mov [rbx], rax
    PRINT [abs 0x800000 + 0x123458]
    SHOW_ENTRY V + 0x400000, 21
    PRINT [next_table]
    PRINT [f_count]
    EXIT

align 8
next_table: dq 0x300000
file_end:
