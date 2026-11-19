; MOV in its forms, MOVZX, MOVSX, MOVSXD, XCHG, the sign extensions of A, LAHF and SAHF, and every way of writing an address.
; Written by tools/gen64_tests.py: change that, not this.
%include "elf.inc"
    mov r10, 0xFFFFFFFFFFFFFFFF
    mov r14, 0x5B
    mov r10b, r14b
    mov [buf], r14b
    mov r10b, [buf + 8]
    mov byte [buf + 16], 1
    mov r14b, 215
    xchg r10b, r14b
    xchg [buf + 24], r14b
    xchg al, r10b
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov rdx, 0xFFFFFFFFFFFFFF76
    mov rsi, 0xFFFF
    mov dl, sil
    mov [buf], sil
    mov dl, [buf + 8]
    mov byte [buf + 16], 127
    mov sil, 213
    xchg dl, sil
    xchg [buf + 24], sil
    xchg al, dl
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov r13, 0x81
    mov rcx, 0x45A0702DE275D3C0
    mov r13b, cl
    mov [buf], cl
    mov r13b, [buf + 8]
    mov byte [buf + 16], -13
    mov cl, 1
    xchg r13b, cl
    xchg [buf + 24], cl
    xchg al, r13b
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov rsi, 0x10D41ED745AAE87A
    mov r14, 0x7EC6EF64011A384
    mov sil, r14b
    mov [buf], r14b
    mov sil, [buf + 8]
    mov byte [buf + 16], -15
    mov r14b, 114
    xchg sil, r14b
    xchg [buf + 24], r14b
    xchg al, sil
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov rcx, 0xF1
    mov rbx, 0xFFFFFFFFFFFFFF02
    mov cx, bx
    mov [buf], bx
    mov cx, [buf + 8]
    mov word [buf + 16], -128
    mov bx, 65408
    xchg cx, bx
    xchg [buf + 24], bx
    xchg ax, cx
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov rbp, 0x2DBFFD9D4F4162D8
    mov r14, 0x0
    mov bp, r14w
    mov [buf], r14w
    mov bp, [buf + 8]
    mov word [buf + 16], 6400
    mov r14w, 34228
    xchg bp, r14w
    xchg [buf + 24], r14w
    xchg ax, bp
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov r12, 0x7F
    mov rbx, 0x9D8444F505410C9C
    mov r12w, bx
    mov [buf], bx
    mov r12w, [buf + 8]
    mov word [buf + 16], -16042
    mov bx, 0
    xchg r12w, bx
    xchg [buf + 24], bx
    xchg ax, r12w
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov rax, 0xFFFFFFFFFFFFFF4C
    mov r11, 0xFFFFFFFFFFFFFF60
    mov ax, r11w
    mov [buf], r11w
    mov ax, [buf + 8]
    mov word [buf + 16], -23342
    mov r11w, 65535
    xchg ax, r11w
    xchg [buf + 24], r11w
    xchg ax, ax
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov rax, 0x50F9347EB191E5A7
    mov rdx, 0x7FFFFFFFFFFFFFFF
    mov eax, edx
    mov [buf], edx
    mov eax, [buf + 8]
    mov dword [buf + 16], 52599660
    mov edx, 4294967295
    xchg eax, edx
    xchg [buf + 24], edx
    xchg eax, eax
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov rdx, 0xF6B1A586E61BC927
    mov rax, 0x47292708EDF2427B
    mov edx, eax
    mov [buf], eax
    mov edx, [buf + 8]
    mov dword [buf + 16], 0
    mov eax, 4256322783
    xchg edx, eax
    xchg [buf + 24], eax
    xchg eax, edx
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov rbp, 0x80000000
    mov r9, 0x80
    mov ebp, r9d
    mov [buf], r9d
    mov ebp, [buf + 8]
    mov dword [buf + 16], -1
    mov r9d, 0
    xchg ebp, r9d
    xchg [buf + 24], r9d
    xchg eax, ebp
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov r11, 0x8EC5FC80F3B1CD4
    mov rsi, 0x34C4FBBC855092D6
    mov r11d, esi
    mov [buf], esi
    mov r11d, [buf + 8]
    mov dword [buf + 16], 0
    mov esi, 2147483648
    xchg r11d, esi
    xchg [buf + 24], esi
    xchg eax, r11d
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov r13, 0xFFFFFFFFFFFFFFD0
    mov rsi, 0x100
    mov r13, rsi
    mov [buf], rsi
    mov r13, [buf + 8]
    mov qword [buf + 16], 1
    mov rsi, 1
    xchg r13, rsi
    xchg [buf + 24], rsi
    xchg rax, r13
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov r11, 0x7E9CBC059D4C0E4
    mov r10, 0x7277556498AFA74E
    mov r11, r10
    mov [buf], r10
    mov r11, [buf + 8]
    mov qword [buf + 16], 2147483647
    mov r10, 2147483647
    xchg r11, r10
    xchg [buf + 24], r10
    xchg rax, r11
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov r8, 0x0
    mov rdi, 0xFFFFFFFFFFFFFFFF
    mov r8, rdi
    mov [buf], rdi
    mov r8, [buf + 8]
    mov qword [buf + 16], 5
    mov rdi, 1931614506
    xchg r8, rdi
    xchg [buf + 24], rdi
    xchg rax, r8
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov rbp, 0xEB82F004DBCC8D42
    mov rdx, 0x1640D287034C358A
    mov rbp, rdx
    mov [buf], rdx
    mov rbp, [buf + 8]
    mov qword [buf + 16], -2147483648
    mov rdx, 3302702755
    xchg rbp, rdx
    xchg [buf + 24], rdx
    xchg rax, rbp
    mov rsi, [buf]
    mov rdi, [buf + 16]
    mov rbp, [buf + 24]
    mov rax, 0x92D90062622A413E
    mov rbx, 0xFC
    mov ah, bh
    mov bh, al
    mov [buf + 1], ah
    mov bh, [buf + 2]
    movzx esi, ah
    movsx di, bh
    xchg ah, bl
    mov rcx, 0x81
    mov rdx, 0x42B09892A64C43C5
    mov ch, dh
    mov dh, cl
    mov [buf + 1], ch
    mov dh, [buf + 2]
    movzx esi, ch
    movsx di, dh
    xchg ch, dl
    mov rbx, 0x7FFF
    mov rax, 0xFFFF
    mov bh, ah
    mov ah, bl
    mov [buf + 1], bh
    mov ah, [buf + 2]
    movzx esi, bh
    movsx di, ah
    xchg bh, al
    mov rdx, 0x7FFFFFFFFFFFFFFF
    mov rcx, 0x1AFE6D6B94E10E18
    mov dh, ch
    mov ch, dl
    mov [buf + 1], dh
    mov ch, [buf + 2]
    movzx esi, dh
    movsx di, ch
    xchg dh, cl
    mov rax, 0xA21CF11F34139E7
    mov [abs qword buf + 32], al
    mov [abs qword buf + 34], ax
    mov [abs qword buf + 36], eax
    mov [abs qword buf + 40], rax
    mov rax, 0xA5593E6EA31A70FC
    mov al, [abs qword buf + 41]
    mov ax, [abs qword buf + 42]
    mov eax, [abs qword buf + 44]
    mov rax, [abs qword buf + 33]
    mov rbx, 0xA07DBD197A2C2706
    mov rcx, 0xED5575F886E33E5
    movzx bx, cl
    mov rbx, 0x8000
    movsx bx, cl
    mov [buf], rcx
    movzx bx, byte [buf]
    movsx cx, byte [buf + 1]
    mov r13, 0xAC476CECDD42FEC2
    mov r14, 0xBCF05B6156EA03B2
    movzx r13w, r14b
    mov r13, 0xFFFFFFFFFFFFFF54
    movsx r13w, r14b
    mov [buf], r14
    movzx r13w, byte [buf]
    movsx r14w, byte [buf + 1]
    mov rcx, 0x10000
    mov rdx, 0x80
    movzx cx, dl
    mov rcx, 0xA8
    movsx cx, dl
    mov [buf], rdx
    movzx cx, byte [buf]
    movsx dx, byte [buf + 1]
    mov r9, 0x7FFFFFFFFFFFFFFF
    mov r12, 0xFFFFFFFFFFFFFF80
    movzx r9w, r12b
    mov r9, 0xA29C77914E2F0C89
    movsx r9w, r12b
    mov [buf], r12
    movzx r9w, byte [buf]
    movsx r12w, byte [buf + 1]
    mov rax, 0x675D06340830AB14
    mov r10, 0x100000000
    movzx eax, r10b
    mov rax, 0x4527A30A59683DCF
    movsx eax, r10b
    mov [buf], r10
    movzx eax, byte [buf]
    movsx r10d, byte [buf + 1]
    mov r12, 0x6C
    mov rsi, 0x80
    movzx r12d, sil
    mov r12, 0xFF
    movsx r12d, sil
    mov [buf], rsi
    movzx r12d, byte [buf]
    movsx esi, byte [buf + 1]
    mov r11, 0x8000000000000000
    mov rdx, 0x2F92E3448DD03850
    movzx r11d, dl
    mov r11, 0xE20D7F0398976B56
    movsx r11d, dl
    mov [buf], rdx
    movzx r11d, byte [buf]
    movsx edx, byte [buf + 1]
    mov rbx, 0x8561FB4C4F7D4498
    mov r15, 0x1
    movzx ebx, r15b
    mov rbx, 0xB619744F42E49CD1
    movsx ebx, r15b
    mov [buf], r15
    movzx ebx, byte [buf]
    movsx r15d, byte [buf + 1]
    mov r15, 0x4F0872A36E8768C9
    mov r14, 0x81
    movzx r15, r14b
    mov r15, 0x100000000
    movsx r15, r14b
    mov [buf], r14
    movzx r15, byte [buf]
    movsx r14, byte [buf + 1]
    mov r12, 0x80000000
    mov rbp, 0x3
    movzx r12, bpl
    mov r12, 0xFA1A1FE19B07F72B
    movsx r12, bpl
    mov [buf], rbp
    movzx r12, byte [buf]
    movsx rbp, byte [buf + 1]
    mov r14, 0xFFFFFFFFFFFFFFFF
    mov rax, 0x10000
    movzx r14, al
    mov r14, 0xA00EAE884A79CC11
    movsx r14, al
    mov [buf], rax
    movzx r14, byte [buf]
    movsx rax, byte [buf + 1]
    mov r10, 0x3AB74FB456E7A09A
    mov r15, 0x2D66E9F2B7C71D7F
    movzx r10, r15b
    mov r10, 0xA2FE7793423E0298
    movsx r10, r15b
    mov [buf], r15
    movzx r10, byte [buf]
    movsx r15, byte [buf + 1]
    mov r9, 0xC9
    mov r14, 0x1
    movzx r9d, r14w
    mov r9, 0x8000000000000000
    movsx r9d, r14w
    mov [buf], r14
    movzx r9d, word [buf]
    movsx r14d, word [buf + 1]
    mov r9, 0xFF8D75744294C271
    mov rbp, 0x1CABD5E099B878CE
    movzx r9d, bp
    mov r9, 0x8000000000000000
    movsx r9d, bp
    mov [buf], rbp
    movzx r9d, word [buf]
    movsx ebp, word [buf + 1]
    mov r10, 0x68D3824AD610B16
    mov r15, 0xDF
    movzx r10d, r15w
    mov r10, 0xE559BD09AF8C4FA9
    movsx r10d, r15w
    mov [buf], r15
    movzx r10d, word [buf]
    movsx r15d, word [buf + 1]
    mov r9, 0x633415294A90ABFF
    mov r11, 0x3EA9EA7C277D2FCF
    movzx r9d, r11w
    mov r9, 0x65BB72DF9E16B4A7
    movsx r9d, r11w
    mov [buf], r11
    movzx r9d, word [buf]
    movsx r11d, word [buf + 1]
    mov r14, 0xF163D79E9EE9C4FA
    mov r9, 0xFFFFFFFFFFFFFF76
    movzx r14, r9w
    mov r14, 0xED7B34E9DD14154E
    movsx r14, r9w
    mov [buf], r9
    movzx r14, word [buf]
    movsx r9, word [buf + 1]
    mov r12, 0xFFFFFFFFFFFFFF94
    mov r11, 0x7FD34DE7DD352664
    movzx r12, r11w
    mov r12, 0x8000000000000000
    movsx r12, r11w
    mov [buf], r11
    movzx r12, word [buf]
    movsx r11, word [buf + 1]
    mov rbp, 0xFFFFFFFFFFFFFF93
    mov r13, 0x2D8F66C8FF517FF2
    movzx rbp, r13w
    mov rbp, 0x8E8C9E31D49202F8
    movsx rbp, r13w
    mov [buf], r13
    movzx rbp, word [buf]
    movsx r13, word [buf + 1]
    mov r10, 0x8F6297F09BAFCEF5
    mov r8, 0xD5DD9181C44A7C95
    movzx r10, r8w
    mov r10, 0x81
    movsx r10, r8w
    mov [buf], r8
    movzx r10, word [buf]
    movsx r8, word [buf + 1]
    mov r10, 0x8000000000000000
    mov rbx, 0x100000000
    movsxd r10, ebx
    mov [buf], rbx
    movsxd rbx, dword [buf + 2]
    mov r12, 0xBCC46B2A670A2D41
    mov r8, 0x979DFF4A9A80E1D2
    movsxd r12, r8d
    mov [buf], r8
    movsxd r8, dword [buf + 2]
    mov r8, 0xC17B6C94A3319A2D
    mov rax, 0xFFFFFFFFFFFFFF4A
    movsxd r8, eax
    mov [buf], rax
    movsxd rax, dword [buf + 2]
    mov r15, 0x100
    mov rbp, 0x870B09C23CD58370
    movsxd r15, ebp
    mov [buf], rbp
    movsxd rbp, dword [buf + 2]
    mov rdx, 0x8000000000000000
    mov r8, 0x2A
    movsxd rdx, r8d
    mov [buf], r8
    movsxd r8, dword [buf + 2]
    mov rdx, 0x8000000000000000
    mov rax, 0x80000000
    movsxd rdx, eax
    mov [buf], rax
    movsxd rax, dword [buf + 2]
    mov rax, 0x7F
    mov rdx, 0xEA82286135EA28D4
    cbw
    mov rax, 0x7F
    mov rdx, 0x1E0FD4CC44F43871
    cwde
    mov rax, 0x7F
    mov rdx, 0x100000000
    cdqe
    mov rax, 0x7F
    mov rdx, 0x2
    cwd
    mov rax, 0x7F
    mov rdx, 0xFFFFFFFF
    cdq
    mov rax, 0x7F
    mov rdx, 0x555F55CB56BF90FA
    cqo
    mov rax, 0x80
    mov rdx, 0xFFFFFFFFFFFFFF24
    cbw
    mov rax, 0x80
    mov rdx, 0xB291C5464139F245
    cwde
    mov rax, 0x80
    mov rdx, 0xFFFFFFFFFFFFFF73
    cdqe
    mov rax, 0x80
    mov rdx, 0xB40E487E97C22C93
    cwd
    mov rax, 0x80
    mov rdx, 0x80
    cdq
    mov rax, 0x80
    mov rdx, 0x64053B27B42646E9
    cqo
    mov rax, 0x7FFF
    mov rdx, 0x3
    cbw
    mov rax, 0x7FFF
    mov rdx, 0x48CEDFCBF19E2040
    cwde
    mov rax, 0x7FFF
    mov rdx, 0x585B889977969E83
    cdqe
    mov rax, 0x7FFF
    mov rdx, 0xB298E1C0BA54DAB8
    cwd
    mov rax, 0x7FFF
    mov rdx, 0xFFFF
    cdq
    mov rax, 0x7FFF
    mov rdx, 0x80000000
    cqo
    mov rax, 0x8000
    mov rdx, 0x82BFFF1983F3D7C7
    cbw
    mov rax, 0x8000
    mov rdx, 0x49AB27C1D8754CC5
    cwde
    mov rax, 0x8000
    mov rdx, 0x69826F47E6DDF1FC
    cdqe
    mov rax, 0x8000
    mov rdx, 0xFFFFFFFFFFFFFF34
    cwd
    mov rax, 0x8000
    mov rdx, 0x7FFFFFFF
    cdq
    mov rax, 0x8000
    mov rdx, 0x3D4B0933E58B6041
    cqo
    mov rax, 0x7FFFFFFF
    mov rdx, 0x8000000000000000
    cbw
    mov rax, 0x7FFFFFFF
    mov rdx, 0x8EA18C2D4FA0E0BD
    cwde
    mov rax, 0x7FFFFFFF
    mov rdx, 0xFFFFFFFFFFFFFFDE
    cdqe
    mov rax, 0x7FFFFFFF
    mov rdx, 0xFFFFFFFFFFFFFF80
    cwd
    mov rax, 0x7FFFFFFF
    mov rdx, 0xD319C50F4A75032D
    cdq
    mov rax, 0x7FFFFFFF
    mov rdx, 0xFFFFFFFF
    cqo
    mov rax, 0x80000000
    mov rdx, 0x71AE511F0E774EC4
    cbw
    mov rax, 0x80000000
    mov rdx, 0x8335E2FCAF7A88E6
    cwde
    mov rax, 0x80000000
    mov rdx, 0x3
    cdqe
    mov rax, 0x80000000
    mov rdx, 0x9EEF59D5F0E30C25
    cwd
    mov rax, 0x80000000
    mov rdx, 0xFB
    cdq
    mov rax, 0x80000000
    mov rdx, 0x7FFFFFFFFFFFFFFF
    cqo
    mov rax, 0x3E57AE5E63789023
    mov rdx, 0x7F
    cbw
    mov rax, 0x10000
    mov rdx, 0x10000
    cwde
    mov rax, 0xF36E8966D8DF63F2
    mov rdx, 0xFF
    cdqe
    mov rax, 0xC6CEB3C5BC1C5F90
    mov rdx, 0xBC881452BB430F9A
    cwd
    mov rax, 0xF8
    mov rdx, 0x2
    cdq
    mov rax, 0xAF83B3012BBDD61C
    mov rdx, 0x470E36BFA959CFB3
    cqo
    mov rax, 0x5D99C4CD4CA1E15D
    mov rdx, 0xFF
    cbw
    mov rax, 0xCFB4C031565217DA
    mov rdx, 0xFF
    cwde
    mov rax, 0xFFFFFFFFFFFFFF87
    mov rdx, 0x8000000000000000
    cdqe
    mov rax, 0x1F653B54435FB1AF
    mov rdx, 0x100
    cwd
    mov rax, 0xFF
    mov rdx, 0x4E
    cdq
    mov rax, 0xFFFFFFFFFFFFFF80
    mov rdx, 0xFFFFFFFFFFFFFFFF
    cqo
    mov rax, 0xE69010423139D880
    FLAGS 0x202
    lahf
    mov ah, 0x29
    sahf
    mov rax, 0x4
    FLAGS 0x203
    lahf
    mov ah, 0x7B
    sahf
    mov rax, 0xCC43897AFD5C1FEB
    FLAGS 0xA02
    lahf
    mov ah, 0x28
    sahf
    mov rax, 0x54
    FLAGS 0xA03
    lahf
    mov ah, 0xBF
    sahf
    mov rax, 0x8F
    FLAGS 0xAD7
    lahf
    mov ah, 0x65
    sahf
    mov rax, 0x2CFB064404B73F3
    FLAGS 0x2D6
    lahf
    mov ah, 0x1A
    sahf
    mov rax, 0xA9F0E701E91BD04F
    FLAGS 0x213
    lahf
    mov ah, 0x9B
    sahf
    mov rax, 0x10000
    FLAGS 0x246
    lahf
    mov ah, 0x47
    sahf
    mov rax, 0xFFFFFFFFFFFFFFE1
    FLAGS 0xA82
    lahf
    mov ah, 0x70
    sahf
    mov rax, 0xDFC3D38E110C25D0
    FLAGS 0x297
    lahf
    mov ah, 0x7C
    sahf
    mov rax, 0x0
    FLAGS 0xA43
    lahf
    mov ah, 0xEB
    sahf
    mov rax, 0x7F
    FLAGS 0x212
    lahf
    mov ah, 0x47
    sahf
    nop
    pause
    xchg r8, rax
    xchg eax, r8d
    o16 nop
    nop dword [rax + rax * 1 + 0]
    prefetchnta [buf]
    lea rbx, [buf + 128]
    mov rbp, rbx
    mov r12, rbx
    mov r13, rbx
    mov ecx, 3
    mov rsi, -2
    mov r14, 5
    mov r9, 1
    lea rax, [rbx]
    lea edx, [rbx]
    lea di, [rbx]
    mov r10, [rbx]
    add byte [rbx], 0x11
    lea rax, [rbp]
    lea edx, [rbp]
    lea di, [rbp]
    mov r10, [rbp]
    add byte [rbp], 0x11
    lea rax, [r12]
    lea edx, [r12]
    lea di, [r12]
    mov r10, [r12]
    add byte [r12], 0x11
    lea rax, [r13]
    lea edx, [r13]
    lea di, [r13]
    mov r10, [r13]
    add byte [r13], 0x11
    lea rax, [rbx + 8]
    lea edx, [rbx + 8]
    lea di, [rbx + 8]
    mov r10, [rbx + 8]
    add byte [rbx + 8], 0x11
    lea rax, [rbp - 8]
    lea edx, [rbp - 8]
    lea di, [rbp - 8]
    mov r10, [rbp - 8]
    add byte [rbp - 8], 0x11
    lea rax, [r12 + 0x80]
    lea edx, [r12 + 0x80]
    lea di, [r12 + 0x80]
    mov r10, [r12 + 0x80]
    add byte [r12 + 0x80], 0x11
    lea rax, [r13 - 0x81]
    lea edx, [r13 - 0x81]
    lea di, [r13 - 0x81]
    mov r10, [r13 - 0x81]
    add byte [r13 - 0x81], 0x11
    lea rax, [rsp]
    lea edx, [rsp]
    lea di, [rsp]
    lea rax, [rsp + 8]
    lea edx, [rsp + 8]
    lea di, [rsp + 8]
    lea rax, [rsp + 0x100]
    lea edx, [rsp + 0x100]
    lea di, [rsp + 0x100]
    lea rax, [rbx + rcx]
    lea edx, [rbx + rcx]
    lea di, [rbx + rcx]
    mov r10, [rbx + rcx]
    add byte [rbx + rcx], 0x11
    lea rax, [rbx + rcx * 2]
    lea edx, [rbx + rcx * 2]
    lea di, [rbx + rcx * 2]
    mov r10, [rbx + rcx * 2]
    add byte [rbx + rcx * 2], 0x11
    lea rax, [rbx + rcx * 4 + 4]
    lea edx, [rbx + rcx * 4 + 4]
    lea di, [rbx + rcx * 4 + 4]
    mov r10, [rbx + rcx * 4 + 4]
    add byte [rbx + rcx * 4 + 4], 0x11
    lea rax, [rbx + rcx * 8 - 0x90]
    lea edx, [rbx + rcx * 8 - 0x90]
    lea di, [rbx + rcx * 8 - 0x90]
    mov r10, [rbx + rcx * 8 - 0x90]
    add byte [rbx + rcx * 8 - 0x90], 0x11
    lea rax, [rbp + rsi * 8]
    lea edx, [rbp + rsi * 8]
    lea di, [rbp + rsi * 8]
    mov r10, [rbp + rsi * 8]
    add byte [rbp + rsi * 8], 0x11
    lea rax, [rbp + rsi * 4 + 0x7F]
    lea edx, [rbp + rsi * 4 + 0x7F]
    lea di, [rbp + rsi * 4 + 0x7F]
    mov r10, [rbp + rsi * 4 + 0x7F]
    add byte [rbp + rsi * 4 + 0x7F], 0x11
    lea rax, [r13 + r14 * 2]
    lea edx, [r13 + r14 * 2]
    lea di, [r13 + r14 * 2]
    mov r10, [r13 + r14 * 2]
    add byte [r13 + r14 * 2], 0x11
    lea rax, [r13 + r14 * 8 + 0x12345]
    lea edx, [r13 + r14 * 8 + 0x12345]
    lea di, [r13 + r14 * 8 + 0x12345]
    mov r10, [r13 + r14 * 8 + 0x12345]
    add byte [r13 + r14 * 8 + 0x12345], 0x11
    lea rax, [r12 + r9 * 4]
    lea edx, [r12 + r9 * 4]
    lea di, [r12 + r9 * 4]
    mov r10, [r12 + r9 * 4]
    add byte [r12 + r9 * 4], 0x11
    lea rax, [r12 + r12]
    lea edx, [r12 + r12]
    lea di, [r12 + r12]
    lea rax, [rsp + rcx * 4]
    lea edx, [rsp + rcx * 4]
    lea di, [rsp + rcx * 4]
    lea rax, [rsp + r14 * 8 + 16]
    lea edx, [rsp + r14 * 8 + 16]
    lea di, [rsp + r14 * 8 + 16]
    lea rax, [rcx * 4 + 0x500000]
    lea edx, [rcx * 4 + 0x500000]
    lea di, [rcx * 4 + 0x500000]
    mov r10, [rcx * 4 + 0x500000]
    add byte [rcx * 4 + 0x500000], 0x11
    lea rax, [r14 * 8 + 0x500000]
    lea edx, [r14 * 8 + 0x500000]
    lea di, [r14 * 8 + 0x500000]
    mov r10, [r14 * 8 + 0x500000]
    add byte [r14 * 8 + 0x500000], 0x11
    lea rax, [rel buf]
    lea edx, [rel buf]
    lea di, [rel buf]
    mov r10, [rel buf]
    add byte [rel buf], 0x11
    lea rax, [rel buf + 0x40]
    lea edx, [rel buf + 0x40]
    lea di, [rel buf + 0x40]
    mov r10, [rel buf + 0x40]
    add byte [rel buf + 0x40], 0x11
    lea rax, [abs 0x500000]
    lea edx, [abs 0x500000]
    lea di, [abs 0x500000]
    mov r10, [abs 0x500000]
    add byte [abs 0x500000], 0x11
    lea rax, [rbx + rsi]
    lea edx, [rbx + rsi]
    lea di, [rbx + rsi]
    mov r10, [rbx + rsi]
    add byte [rbx + rsi], 0x11
    lea rax, [r12 + rsi * 2 - 1]
    lea edx, [r12 + rsi * 2 - 1]
    lea di, [r12 + rsi * 2 - 1]
    mov r10, [r12 + rsi * 2 - 1]
    add byte [r12 + rsi * 2 - 1], 0x11
    mov r15, 0xFFFFFFFF00000000
    or rbx, r15
    or r12, r15
    lea rax, [ebx]
    lea edx, [ebx]
    mov r10, [ebx]
    lea rax, [ebx + ecx * 4 + 4]
    lea edx, [ebx + ecx * 4 + 4]
    mov r10, [ebx + ecx * 4 + 4]
    lea rax, [r12d + r9d * 8]
    lea edx, [r12d + r9d * 8]
    mov r10, [r12d + r9d * 8]
    lea rax, [ebx + esi]
    lea edx, [ebx + esi]
    mov r10, [ebx + esi]
    lea rax, [ecx * 8 + 0x500000]
    lea edx, [ecx * 8 + 0x500000]
    mov r10, [ecx * 8 + 0x500000]
    lea rax, [esi + 0x500002]
    lea edx, [esi + 0x500002]
    mov r10, [esi + 0x500002]
    EXIT
    align 16
buf: times 64 dq 0x0123456789ABCDEF
file_end:
