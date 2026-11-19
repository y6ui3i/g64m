; The frame of a 64-bit system test (E094): an image loaded at 1 MB, built with
; `nasm -f bin`, that runs at privilege level 0 in long mode.
;
; Two ways in:
; - QEMU (`-kernel`) finds the multiboot header and enters start32 in 32-bit protected
;   mode; start32 turns on PAE, long mode and paging and jumps to start64.
; - g86m's 64-bit CPU has no 32-bit mode. Its loader finds the "G64T" header, puts the
;   image at 1 MB and sets what start32 would have left: CR0 = 80000011h, CR4 = 20h,
;   EFER = 500h, CR3 = the table named in the header, the GDT named in the header, CS = 8
;   (64-bit code), the data segments 10h, and RIP = start64.
;
; The page tables map the first gigabyte to itself with 2 MB pages. A test goes on from
; `start64:`'s end with every general register zero but RSP, and ends with EXIT.
;
; PRINT reg prints a 64-bit register in hex and a new line on the serial port; PUTS prints
; a text. What a test prints is what is compared with the real CPU's (QEMU with KVM).

LOAD equ 0x100000
STACK_TOP equ 0x1F0000

bits 32
org LOAD
mb:
    dd 0x1BADB002, 0x00010000, -(0x1BADB002 + 0x00010000)
    dd mb, LOAD, file_end, file_end, start32
g64:
    db "G64T"
    dd 0
    dq start64, pml4, gdt_ptr

align 16
gdt:
    dq 0
    dq 0x00209A0000000000       ; 08h: 64-bit code, level 0
    dq 0x0000920000000000       ; 10h: data, level 0
    dq 0x0000F20000000000       ; 18h: data, level 3
    dq 0x0020FA0000000000       ; 20h: 64-bit code, level 3
    dq 0, 0                     ; 28h: room for a TSS
gdt_end:
gdt_ptr:
    dw gdt_end - gdt - 1
    dq gdt

align 4096
pml4:
    dq pdpt + 7
    times 511 dq 0
pdpt:
    dq pd + 7
    times 511 dq 0
pd:
%assign i 0
%rep 512
    dq i * 0x200000 + 0x87
%assign i i + 1
%endrep

start32:
    mov eax, cr4
    or eax, 0x20
    mov cr4, eax
    mov eax, pml4
    mov cr3, eax
    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x100
    wrmsr
    mov eax, 0x80000011
    mov cr0, eax
    lgdt [gdt_ptr]
    jmp 0x08:start64

bits 64
default rel

; Prints AL on the serial port.
putc:
    push rdx
    push rax
    mov dx, 0x3FD
.wait:
    in al, dx
    test al, 0x20
    jz .wait
    pop rax
    mov dx, 0x3F8
    out dx, al
    pop rdx
    ret

; Prints RAX as sixteen hex digits and a new line.
print_rax:
    push rax
    push rcx
    push rbx
    mov rbx, rax
    mov ecx, 16
.digit:
    rol rbx, 4
    mov eax, ebx
    and eax, 15
    cmp eax, 10
    jb .num
    add eax, 7
.num:
    add eax, '0'
    call putc
    dec ecx
    jnz .digit
    mov eax, 10
    call putc
    pop rbx
    pop rcx
    pop rax
    ret

; Prints the text at RSI, which ends with a zero.
puts:
    push rax
.next:
    mov al, [rsi]
    inc rsi
    test al, al
    jz .done
    call putc
    jmp .next
.done:
    pop rax
    ret

%macro PRINT 1
    push rax
    mov rax, %1
    call print_rax
    pop rax
%endmacro

%macro PUTS 1
    push rsi
    lea rsi, [%%text]
    call puts
    pop rsi
    jmp %%over
%%text: db %1, 10, 0
%%over:
%endmacro

; Stops the machine: QEMU's isa-debug-exit device, then a halt for anything without it.
%macro EXIT 0
    mov eax, 0
    out 0xF4, eax
%%stop:
    hlt
    jmp %%stop
%endmacro

start64:
    mov eax, 0x10
    mov ds, eax
    mov es, eax
    mov ss, eax
    mov fs, eax
    mov gs, eax
    mov rsp, STACK_TOP
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    xor esi, esi
    xor edi, edi
    xor ebp, ebp
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15
    push 2
    popfq
