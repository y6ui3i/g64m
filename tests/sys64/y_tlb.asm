; What a program can see of a TLB (E096): not what one keeps, which a CPU is free in, but
; what one may not do. Each part first uses a page in one way, so that a TLB has it, and
; then in a way the first use must not stand for.
%include "sys.inc"
    jmp test
%include "idt.inc"
%include "pt.inc"
%include "ring3.inc"

V equ 0x40000000
P equ 0x400000

; Code for a page: MOV EAX, n and RET.
%macro CODE_AT 2
    mov rax, %1
    mov byte [rax], 0xB8
    mov dword [rax + 1], %2
    mov byte [rax + 5], 0xC3
%endmacro

test:
    call idt_init
    call ring3_init
    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x800
    wrmsr

    PUTS "a write after a read sets the dirty bit"
    MAP V, P, 3
    mov rbx, V
    mov rax, [rbx]
    SHOW_ENTRY V, 12
    mov qword [rbx], 0x1111
    SHOW_ENTRY V, 12

    PUTS "level 3 after level 0, on a page that is level 0's"
    mov rax, [rbx]
    mov [rbx], rax
    USER .u1
    SHOW_FAULT
    PRINT [f_cr2]
    jmp .k1
.u1:
    lea rax, [.u1b]
    mov [f_resume], rax
    mov rbx, V
    mov rax, [rbx]
.u1b:
    LEAVE_USER
.k1:
    USER .u2
    PRINT [f_err]
    jmp .k2
.u2:
    lea rax, [.u2b]
    mov [f_resume], rax
    mov rbx, V
    mov [rbx], rax
.u2b:
    LEAVE_USER

.k2:
    PUTS "level 3 writing after level 3 read, on a page it may only read"
    MAP V + 0x1000, P + 0x1000, 5
    USER .u3
    PRINT r8
    PRINT [f_err]
    SHOW_ENTRY V + 0x1000, 12
    jmp .k3
.u3:
    mov rbx, V + 0x1000
    mov r8, [rbx]
    lea rax, [.u3b]
    mov [f_resume], rax
    mov [rbx], rax
.u3b:
    LEAVE_USER

.k3:
    PUTS "level 3 reading the table the CPU has just read for it"
    ; The IDT's 2 MB are level 0's. A fault from level 3 has the CPU read the IDT, as
    ; itself; level 3 reading the same address afterwards is still refused.
    and qword [pd + 1 * 8], ~4
    mov rax, cr3
    mov cr3, rax
    USER .u4
    PRINT [f_vec]
    PRINT [f_err]
    PRINT [f_cr2]
    or qword [pd + 1 * 8], 4
    mov rax, cr3
    mov cr3, rax
    jmp .k4
.u4:
    lea rax, [.u4a]
    mov [f_resume], rax
    ud2
.u4a:
    lea rax, [.u4b]
    mov [f_resume], rax
    mov rax, [abs IDT_AT + 6 * 16]
.u4b:
    LEAVE_USER

.k4:
    PUTS "executing after reading, on a page that may not be executed"
    MAP V + 0x2000, P + 0x2000, 3
    CODE_AT V + 0x2000, 0x77
    mov rdi, V + 0x2000
    mov ecx, 12
    call entry
    bts qword [rax], 63
    mov rbx, V + 0x2000
    invlpg [rbx]
    PRINT [rbx]
    mov qword [rbx + 8], 0x2222
    mov qword [f_resume], .x1
    call rbx
.x1:
    SHOW_FAULT
    add rsp, 8
    PUTS "and reading after executing, when it is taken away"
    MAP V + 0x3000, P + 0x3000, 3
    CODE_AT V + 0x3000, 0x88
    mov rbx, V + 0x3000
    call rbx
    PRINT rax
    mov rdi, V + 0x3000
    mov ecx, 12
    call entry
    bts qword [rax], 63
    invlpg [rbx]
    mov qword [f_resume], .x2
    call rbx
.x2:
    PRINT [f_err]
    add rsp, 8
    PRINT [rbx]

    PUTS "CR0.WP turned on after a write that it would have refused"
    MAP V + 0x4000, P + 0x4000, 1
    mov rbx, V + 0x4000
    mov qword [rbx], 0x3333
    mov rax, cr0
    or eax, 0x10000
    mov cr0, rax
    mov qword [f_resume], .w1
    mov qword [rbx], 0x4444
.w1:
    PRINT [f_err]
    PRINT [rbx]
    mov rax, cr0
    and eax, ~0x10000
    mov cr0, rax
    mov qword [rbx], 0x5555
    PRINT [rbx]

    PUTS "EFER.NXE turned off after a read through an entry with bit 63"
    mov rbx, V + 0x2000
    PRINT [rbx]
    mov ecx, 0xC0000080
    rdmsr
    and eax, ~0x800
    wrmsr
    mov qword [f_resume], .n1
    mov rax, [rbx]
.n1:
    PRINT [f_err]
    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x800
    wrmsr
    PRINT [rbx]

    PUTS "one page invalidated: read, written and executed through the new entry"
    MAP V + 0x5000, P + 0x5000, 3
    CODE_AT V + 0x5000, 1
    CODE_AT P + 0x6000, 2
    mov rbx, V + 0x5000
    call rbx
    PRINT rax
    PRINT [rbx]
    mov byte [rbx + 16], 0xAA
    MAP V + 0x5000, P + 0x6000, 3
    invlpg [rbx]
    PRINT [rbx]
    mov byte [rbx + 16], 0xBB
    call rbx
    PRINT rax
    PRINT [abs P + 0x5010]
    PRINT [abs P + 0x6010]
    PUTS "and by a write of CR3"
    MAP V + 0x5000, P + 0x5000, 3
    mov rax, cr3
    mov cr3, rax
    PRINT [rbx]
    mov byte [rbx + 16], 0xCC
    call rbx
    PRINT rax
    PRINT [abs P + 0x5010]

    PUTS "two pages that a table would put in one place"
    MAP V + 0x8000, P + 0x8000, 3
    MAP V + 0x1008000, P + 0x9000, 3
    MAP V + 0x10008000, P + 0xA000, 3
    mov rbx, V + 0x8000
    mov r12, V + 0x1008000
    mov r13, V + 0x10008000
    mov qword [rbx], 0xA1
    mov qword [r12], 0xB2
    mov qword [r13], 0xC3
    mov rax, [rbx]
    add rax, [r12]
    add rax, [r13]
    add rax, [rbx]
    PRINT rax
    ; Invalidating one of them leaves the others.
    MAP V + 0x1008000, P + 0x8000, 3
    invlpg [r12]
    PRINT [r12]
    PRINT [rbx]
    PRINT [r13]

    PUTS "the page under the running code changed, and CR3 written by that code"
    ; Two copies of a routine that points its own page at the other copy, invalidates, and
    ; says which copy it then is. What follows the invalidation is fetched from the new page.
%macro OWN_PAGE 3               ; template, its length, where the constant is in it
    lea rsi, [%1]
    mov rdi, P + 0x10000
    mov ecx, %2
    rep movsb
    lea rsi, [%1]
    mov rdi, P + 0x11000
    mov ecx, %2
    rep movsb
    mov dword [abs P + 0x11000 + %3], 0x22222222
    MAP V + 0x20000, P + 0x10000, 3
    mov rbx, V + 0x20000
    invlpg [rbx]
    mov rdi, V + 0x20000
    mov ecx, 12
    call entry
    mov rdi, rax
    mov rsi, P + 0x11000 + 3
    xor eax, eax
    call rbx
    PRINT rax
%endmacro
    OWN_PAGE own_cr3, own_cr3_len, own_cr3_len - 5
    PUTS "and invalidated by that code"
    OWN_PAGE own_inv, own_inv_len, own_inv_len - 5

    PUTS "level 3 running on from where level 0 was, on a page that is level 0's"
    ; IRETQ, at level 0, to the instruction after it, at level 3: the same page, which level
    ; 3 may not execute.
    MAP V + 0x30000, P + 0x12000, 3
    mov rbx, V + 0x30000
    mov word [rbx], 0xCF48
    ; What follows the IRETQ, which level 3 must not get to run: INC R12, then UD2.
    mov dword [rbx + 2], 0x0FC4FF49
    mov byte [rbx + 6], 0x0B
    xor r12d, r12d
    lea rax, [.l3back]
    mov [k_cont], rax
    mov [k_rsp], rsp
    lea rax, [.l3fault]
    mov [f_resume], rax
    push 0x1B
    push USER_STACK
    push 2
    push 0x23
    lea rax, [rbx + 2]
    push rax
    jmp rbx
.l3fault:
    LEAVE_USER
.l3back:
    PRINT r12
    PRINT [f_cr2]

    PUTS "an instruction that lies across two pages that are not neighbours in memory"
    MAP V + 0x40000, P + 0x20000, 3
    MAP V + 0x41000, P + 0x22000, 3
    mov rdi, P + 0x21000
    mov ecx, 512
    mov rax, 0xAAAAAAAAAAAAAAAA
    rep stosq
    ; MOV EAX, a constant of four bytes, one of them on the first page.
    mov rbx, V + 0x40FFE
    mov rax, 0x0000C311223344B8
    mov [rbx], rax
    xor eax, eax
    call rbx
    PRINT rax
    ; MOV AX, a constant of two bytes, one on each page.
    mov rbx, V + 0x40FFD
    mov rax, 0x00000000C37788B8
    shl rax, 8
    mov al, 0x66
    mov [rbx], rax
    xor eax, eax
    call rbx
    PRINT rax
    ; MOV RAX, a constant of eight bytes, two of them on the first page.
    mov rbx, V + 0x40FFC
    mov word [rbx], 0xB848
    mov rax, 0x8877665544332211
    mov [rbx + 2], rax
    mov byte [rbx + 10], 0xC3
    xor eax, eax
    call rbx
    PRINT rax

    PUTS "stores and loads that reach one byte into the next page"
    ; The two pages are not neighbours in memory: the byte that crosses must be found on the
    ; second, and the page that follows the first in memory must stay as it was (E108).
    mov rbx, V + 0x40FF9
    mov rax, 0x8877665544332211
    mov [rbx], rax
    PRINT [rbx]
    PRINT [abs P + 0x22000]
    mov dword [rbx + 4], 0xAABBCCDD
    mov eax, [rbx + 4]
    PRINT rax
    PRINT [abs P + 0x22000]
    mov word [rbx + 6], 0x1234
    movzx eax, word [rbx + 6]
    PRINT rax
    PRINT [abs P + 0x22000]
    PRINT [abs P + 0x21000]

    PUTS "code changed by a store at another address of its page"
    ; One page at two addresses, and at its own. What runs at the first is put there, and
    ; then changed, by stores at the others, after it has run three times (E107).
    MAP V + 0x60000, P + 0x14000, 3
    MAP V + 0x61000, P + 0x14000, 3
    mov rbx, V + 0x60000
    mov r13, V + 0x61000
    mov dword [r13], 0xC3C80148             ; ADD RAX, RCX, and RET
    mov eax, 100
    mov ecx, 7
%macro THRICE 0
    mov r14d, 3
%%again:
    call rbx
    dec r14d
    jnz %%again
    PRINT rax
%endmacro
    THRICE
    mov byte [r13 + 1], 0x29                ; SUB
    THRICE
    mov byte [abs P + 0x14001], 0x31        ; XOR
    THRICE
    ; FS's base in an instruction that runs three times.
    mov qword [abs P + 0x14800], 0x1001
    mov ecx, 0xC0000100
    mov eax, P + 0x14000
    xor edx, edx
    wrmsr
    mov rax, 0x000000C301034864             ; ADD RAX, FS:[RCX], and RET
    mov [r13], rax
    mov ecx, 0x800
    xor eax, eax
    THRICE
    ; LEA with FS in front takes nothing from FS's base.
    db 0x64
    lea rax, [rcx + 8]
    PRINT rax
    PUTS "a return to an address above 4 GB"
    MAP V + 0x100062000, P + 0x14000, 3
    mov rax, 0x0000C300000077B8             ; MOV EAX, 77h, and RET
    mov [r13 + 0x100], rax
    lea rdx, [.high_back]
    push rdx
    mov rdx, V + 0x100062100
    push rdx
    ret
.high_back:
    PRINT rax

    PUTS "a page of 2 MB invalidated by any address in it"
    mov rdi, V + 0x400000
    mov ecx, 21
    call entry
    mov r12, rax
    mov qword [r12], 0x800000 + 0x83
    mov rbx, V + 0x400000
    mov qword [rbx + 0x1000], 0x61
    mov qword [rbx + 0x155008], 0x62
    mov qword [abs 0xA00000 + 0x1000], 0x71
    mov qword [abs 0xA00000 + 0x155008], 0x72
    mov rax, [rbx + 0x1000]
    add rax, [rbx + 0x155008]
    PRINT rax
    mov qword [r12], 0xA00000 + 0x83
    invlpg [rbx + 0x1000]
    PRINT [rbx + 0x155008]
    PRINT [rbx + 0x1000]
    PRINT [f_count]
    EXIT

; The two routines of "the page under the running code changed". RDI points at the entry of
; the page they run on and RSI is what to put there; RBX is that page's address.
own_cr3:
    mov [rdi], rsi
    mov rax, cr3
    mov cr3, rax
    mov eax, 0x11111111
    ret
own_cr3_len equ $ - own_cr3
own_inv:
    mov [rdi], rsi
    invlpg [rbx]
    mov eax, 0x11111111
    ret
own_inv_len equ $ - own_inv
file_end:
