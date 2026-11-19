; The eight arithmetic operations and TEST, INC, DEC, NEG and NOT, at every width and in every form.
; Written by tools/gen64_tests.py: change that, not this.
%include "elf.inc"
    mov r12, 0x2D8E5BAE344EB7B1
    mov rax, 0x8E14F20B38B3F69E
    add r12b, al
    mov rdi, 0x81
    mov rsi, 0x7FFD3E2D05D000B0
    add dil, sil
    mov r10, 0x80000000
    mov r15, 0x7FFFFFFF
    add r10b, r15b
    mov rsi, 0x0
    mov r13, 0xC7558FB5CB4D1FEA
    FLAGS 0x213
    add sil, -70
    mov rcx, 0xFFFFFFFFFFFFFFD6
    mov rbp, 0x75207E85DD23E5B7
    add cl, -113
    mov r11, 0x98B4E8234E392A89
    mov r12, 0xB265CA21762D5979
    add r11b, -128
    mov rdx, 0xFFFFFFFFFFFFFFFF
    mov r9, 0x81
    mov [buf + 8], r9
    add dl, [buf + 8]
    mov r14, 0x8000000000000000
    mov rdi, 0xEB1DECBCBEA7BC44
    mov [buf + 8], rdi
    add r14b, [buf + 8]
    mov rbx, 0xFF
    mov r15, 0x1BD3AC3E666FD1DE
    mov [buf + 8], r15
    add bl, [buf + 8]
    mov rcx, 0xFFFFFFFF80000000
    mov r9, 0x1
    FLAGS 0x202
    mov [buf + 16], rcx
    add [buf + 16], r9b
    mov rcx, [buf + 16]
    mov rbp, 0x21
    mov r9, 0xFFFF
    FLAGS 0x202
    mov [buf + 16], rbp
    add [buf + 16], r9b
    mov rbp, [buf + 16]
    mov r8, 0x7FFF
    mov rsi, 0x80000000
    mov [buf + 16], r8
    add [buf + 16], sil
    mov r8, [buf + 16]
    mov r14, 0x10000
    mov rsi, 0xFFFFFFFFFFFFFF38
    FLAGS 0xA82
    mov [buf + 24], r14
    add byte [buf + 24], 36
    mov rsi, [buf + 24]
    mov rsi, 0x2
    mov r14, 0x45DC652D3EE53C62
    FLAGS 0x297
    mov [buf + 24], rsi
    add byte [buf + 24], -128
    mov r14, [buf + 24]
    mov rsi, 0x8000000000000000
    mov r13, 0xD959C602D9D7C619
    mov [buf + 24], rsi
    add byte [buf + 24], 5
    mov r13, [buf + 24]
    mov rax, 0x643013AEE1698417
    mov rdi, 0x16
    FLAGS 0x203
    mov rax, 0x8000
    add al, 1
    mov rbx, 0x754B46B50739894F
    mov rcx, 0x8000
    mov rax, 0x80000000
    add al, 87
    mov rdi, 0x100
    mov r13, 0x7FFFFFFFFFFFFFFF
    mov rax, 0x100
    add al, -73
    mov rdx, 0x8000000000000000
    mov r10, 0x1C295F91950C914B
    mov rbx, 0xCF739CB1B5E547DB
    mov rcx, 0xA7
    add bh, cl
    add bl, ch
    mov rsi, 0x8000
    mov rax, 0x7213C8AD3A112101
    mov rax, 0xC85624B8D31237B
    mov rbx, 0x80000000
    add ah, bl
    add al, bh
    mov rdx, 0xFFFFFFFFFFFFFFFF
    mov rcx, 0xFFFFFFFFFFFFFF11
    mov rdx, 0xC6
    mov rbx, 0x10000
    add dh, bl
    add dl, bh
    mov rax, 0x1C85DE29C8E55C08
    mov r14, 0x36C0639EA2EAAD0D
    add ax, r14w
    mov rbp, 0x80000000
    mov r10, 0xDCDE31DCFF5A33F
    add bp, r10w
    mov r10, 0x100
    mov rdx, 0x1
    add r10w, dx
    mov r9, 0x64
    mov rdi, 0x85
    add r9w, -31688
    mov r13, 0x8CB3DFBE8FC3BC10
    mov rbp, 0xE7F944AB80B488F1
    add r13w, 23624
    mov rsi, 0xC0549FD55D4B39F0
    mov r14, 0x100
    add si, 14126
    mov r15, 0xCCE6E957644B2909
    mov rax, 0x34
    mov [buf + 8], rax
    add r15w, [buf + 8]
    mov rbp, 0xA4C3427E7A002511
    mov r12, 0x81
    mov [buf + 8], r12
    add bp, [buf + 8]
    mov r8, 0xFF
    mov r15, 0xCD8F6E72D3117BFD
    mov [buf + 8], r15
    add r8w, [buf + 8]
    mov rsi, 0xFFFF
    mov r14, 0xC1
    mov [buf + 16], rsi
    add [buf + 16], r14w
    mov rsi, [buf + 16]
    mov r12, 0xD01013B5D2D27274
    mov rsi, 0x63E4472D1EB34668
    mov [buf + 16], r12
    add [buf + 16], si
    mov r12, [buf + 16]
    mov rsi, 0x80
    mov r10, 0x1
    mov [buf + 16], rsi
    add [buf + 16], r10w
    mov rsi, [buf + 16]
    mov r12, 0x3
    mov r8, 0x80
    mov [buf + 24], r12
    add word [buf + 24], 7526
    mov r8, [buf + 24]
    mov rbx, 0x2A1F87CF5CB393D9
    mov r10, 0xFFFFFFFFFFFFFF80
    mov [buf + 24], rbx
    add word [buf + 24], -3355
    mov r10, [buf + 24]
    mov rax, 0x35094994FCC707EC
    mov r14, 0x0
    mov [buf + 24], rax
    add word [buf + 24], -1
    mov r14, [buf + 24]
    mov rax, 0x54AB213048874C74
    mov rbx, 0xE694AF8727451E79
    mov rax, 0xFFFFFFFFFFFFFF3F
    add ax, 1280
    mov r9, 0x7FFF
    mov r12, 0x72B4D9B5E6DF4214
    mov rax, 0xE67AEC4026309308
    add ax, -28127
    mov rbp, 0xFFFFFFFFFFFFFFA6
    mov rbx, 0x1
    mov rax, 0x3E5770AF0519C4F0
    add ax, 7823
    mov rbx, 0x137CA7EB4F70D82
    mov rbp, 0x5C8A15F9E98989ED
    FLAGS 0xA02
    add bx, bx
    mov r13, 0x7FFF
    mov r12, 0xFFFFFFFF
    add r13w, r13w
    mov rcx, 0xFFFFFFFFFFFFFFAC
    mov rsi, 0x8B180CA84885499
    add cx, cx
    mov rcx, 0x0
    mov rdi, 0xFFFFFFFFFFFFFF61
    add ecx, edi
    mov r13, 0xA777AAD9E51D91FD
    mov rdi, 0xE86B04BB257C5D54
    add r13d, edi
    mov rcx, 0xE5
    mov r10, 0xFFFF
    add ecx, r10d
    mov rdx, 0x81
    mov r9, 0x8C996E8F6C6021E5
    FLAGS 0x246
    add edx, 2147483647
    mov rbx, 0x35C46F33D3391C10
    mov r12, 0xF2A2741F8B23ED83
    add ebx, -2147483648
    mov r8, 0xFFFFFFFF
    mov rax, 0x54BD6F4279AE8C28
    add r8d, -1
    mov rbp, 0x7FFF
    mov rax, 0x7F
    FLAGS 0x213
    mov [buf + 8], rax
    add ebp, [buf + 8]
    mov r8, 0x81
    mov rdx, 0x8000
    mov [buf + 8], rdx
    add r8d, [buf + 8]
    mov rcx, 0x7F
    mov rbx, 0x7FFFFFFF
    mov [buf + 8], rbx
    add ecx, [buf + 8]
    mov r13, 0x8DD475B1308B20D8
    mov rdi, 0x80000000
    mov [buf + 16], r13
    add [buf + 16], edi
    mov r13, [buf + 16]
    mov rcx, 0x507493030C1EAD28
    mov r13, 0x7E
    mov [buf + 16], rcx
    add [buf + 16], r13d
    mov rcx, [buf + 16]
    mov r11, 0xE9303FBCA91714AA
    mov r15, 0xFFFFFFFFFFFFFFFF
    FLAGS 0x212
    mov [buf + 16], r11
    add [buf + 16], r15d
    mov r11, [buf + 16]
    mov r14, 0x7FFF
    mov r8, 0x5117E9902740DE70
    mov [buf + 24], r14
    add dword [buf + 24], 5
    mov r8, [buf + 24]
    mov rbp, 0x48
    mov r8, 0xFFFFFFFF
    FLAGS 0x202
    mov [buf + 24], rbp
    add dword [buf + 24], -1
    mov r8, [buf + 24]
    mov r14, 0xEAFC91F8D7B54C1
    mov r15, 0xFFFFFFFFFFFFFFFF
    mov [buf + 24], r14
    add dword [buf + 24], 0
    mov r15, [buf + 24]
    mov r12, 0xFFFFFFFF80000000
    mov r14, 0xFFFFFFFFFFFFFF35
    mov rax, 0x7
    add eax, -2147483648
    mov rdi, 0x78E7DF266AF2160
    mov rbp, 0x24A76058D49B4A5
    FLAGS 0x203
    mov rax, 0xBA67FAE4A89337E4
    add eax, 115800969
    mov rdx, 0x5C07F89DD1992017
    mov r13, 0xD650F5BCFE57FE65
    mov rax, 0x35D1FF17011A3377
    add eax, 2147483647
    mov rax, 0x68CEDB9F8EF2C96F
    mov r15, 0xAFFD56FA4572C2E9
    FLAGS 0x246
    add eax, eax
    mov rbx, 0x10000
    mov r12, 0x10000
    add ebx, ebx
    mov r9, 0x4558FF3B0B918094
    mov rcx, 0xFFFF
    add r9d, r9d
    mov r12, 0x137DD712BCF7731F
    mov r15, 0x100000000
    add r12, r15
    mov rcx, 0x456EF7EF876CCAC9
    mov r12, 0xD0B3173FC64EAE57
    add rcx, r12
    mov r15, 0x47A69A701F00A1BF
    mov rdi, 0x7FFFFFFF
    add r15, rdi
    mov r15, 0xEC
    mov rax, 0x80000000
    add r15, 127
    mov r10, 0x7FFFFFFFFFFFFFFF
    mov rdx, 0x2
    FLAGS 0xA02
    add r10, -2147483648
    mov rax, 0x27293870B07DF71C
    mov r13, 0xFFFFFFFFFFFFFFC2
    add rax, -2147483648
    mov rbx, 0xC5AD84FE7E8944A6
    mov rbp, 0xE438DF9FF65883C4
    mov [buf + 8], rbp
    add rbx, [buf + 8]
    mov r14, 0x80000000
    mov rbp, 0x75436279B871C327
    FLAGS 0xA43
    mov [buf + 8], rbp
    add r14, [buf + 8]
    mov rdi, 0x113199EF6E1E10E2
    mov r8, 0xB055600DEBE69DF1
    mov [buf + 8], r8
    add rdi, [buf + 8]
    mov rdx, 0xFFFFFFFF
    mov rdi, 0xD6E33EE07145BD68
    mov [buf + 16], rdx
    add [buf + 16], rdi
    mov rdx, [buf + 16]
    mov r12, 0x4FC13FFDF832B47C
    mov rbx, 0x15
    mov [buf + 16], r12
    add [buf + 16], rbx
    mov r12, [buf + 16]
    mov rdx, 0x859DD244F3DB1EAB
    mov r15, 0xC219349B280519D
    FLAGS 0x297
    mov [buf + 16], rdx
    add [buf + 16], r15
    mov rdx, [buf + 16]
    mov rbx, 0xFFFFFFFF80000000
    mov rcx, 0x7FFFFFFFFFFFFFFF
    mov [buf + 24], rbx
    add qword [buf + 24], -2147483648
    mov rcx, [buf + 24]
    mov r11, 0x42
    mov r12, 0xFFFFFFFFFFFFFF80
    mov [buf + 24], r11
    add qword [buf + 24], 351627053
    mov r12, [buf + 24]
    mov r13, 0x711F3A0FE370FD7F
    mov rbx, 0xBC9513C36F33B542
    mov [buf + 24], r13
    add qword [buf + 24], 127
    mov rbx, [buf + 24]
    mov rbp, 0xFFFFFFFF80000000
    mov r14, 0xDA
    mov rax, 0x100
    add rax, 2147483647
    mov r8, 0xFFFFFFFFFFFFFF18
    mov r10, 0xFFFFFFFFFFFFFF80
    FLAGS 0x203
    mov rax, 0x8000
    add rax, 2147483647
    mov rbx, 0xFF
    mov r15, 0x6F375444E6EE138A
    mov rax, 0xF84E47390C69ECF7
    add rax, -2147483648
    mov rdx, 0xF53D8F2280A22CC2
    mov rbp, 0x10000
    add rdx, rdx
    mov r10, 0xFFFFFFFFFFFFFF80
    mov r13, 0xFFFFFFFFFFFFFF80
    add r10, r10
    mov rcx, 0xFFFFFFFFFFFFFF0B
    mov r12, 0x100
    FLAGS 0x203
    add rcx, rcx
    mov rcx, 0x690CCADED21680B9
    mov rdi, 0x10000
    or cl, dil
    mov r13, 0xFFFFFFFFFFFFFFC2
    mov r9, 0x3CBB43E8E70D954D
    FLAGS 0x213
    or r13b, r9b
    mov r9, 0x81
    mov rcx, 0xEFCA29A3F0D17FD7
    or r9b, cl
    mov r10, 0x3E
    mov rsi, 0xFFFFFFFFFFFFFFFF
    or r10b, 127
    mov r14, 0x7FFFFFFF
    mov rdi, 0x14
    or r14b, -128
    mov r9, 0xEF
    mov r10, 0x7FFFFFFF
    FLAGS 0xA03
    or r9b, 5
    mov r11, 0x8000
    mov r13, 0xF1F2BD46C461256F
    mov [buf + 8], r13
    or r11b, [buf + 8]
    mov r9, 0x0
    mov r12, 0x3
    mov [buf + 8], r12
    or r9b, [buf + 8]
    mov r10, 0x1
    mov rcx, 0x100
    mov [buf + 8], rcx
    or r10b, [buf + 8]
    mov rsi, 0xDE3ECE9C247CA2D6
    mov r10, 0xFFFFFFFF
    mov [buf + 16], rsi
    or [buf + 16], r10b
    mov rsi, [buf + 16]
    mov rdi, 0x80
    mov r9, 0x7FFF
    mov [buf + 16], rdi
    or [buf + 16], r9b
    mov rdi, [buf + 16]
    mov rsi, 0xF87F6B7F78F381A9
    mov r8, 0x10000
    mov [buf + 16], rsi
    or [buf + 16], r8b
    mov rsi, [buf + 16]
    mov r9, 0x2
    mov rsi, 0xFFFFFFFF
    mov [buf + 24], r9
    or byte [buf + 24], 127
    mov rsi, [buf + 24]
    mov r11, 0x7FFF
    mov r10, 0xDE
    FLAGS 0x297
    mov [buf + 24], r11
    or byte [buf + 24], 23
    mov r10, [buf + 24]
    mov rbx, 0xFFFF937EE527955B
    mov rbp, 0x10000
    mov [buf + 24], rbx
    or byte [buf + 24], 1
    mov rbp, [buf + 24]
    mov rsi, 0x675FAD3ED6A619C
    mov r8, 0x7FFFFFFF
    mov rax, 0xFFFFFFFFFFFFFF46
    or al, 95
    mov rbx, 0xC40492527868191B
    mov r10, 0x3D1571BAC3D05CF8
    mov rax, 0xA4
    or al, 87
    mov r14, 0xFFFF
    mov r10, 0x78
    FLAGS 0x213
    mov rax, 0x187CF064CCC1ED66
    or al, 0
    mov rbx, 0xA4B074B20ADEA673
    mov rbp, 0x7FFFFFFF
    FLAGS 0x213
    mov rcx, 0xE8A04804446C0752
    mov rdx, 0x100
    or ch, dl
    or cl, dh
    mov rbp, 0xB5F5885FF4F536F8
    mov rcx, 0x26
    mov rax, 0x3FF1209E88000070
    mov rbx, 0x7FFF
    or ah, bl
    or al, bh
    mov r11, 0x7F
    mov rbx, 0x6204D11840D97AA7
    mov rbx, 0x2
    mov rdx, 0x7FFFFFFFFFFFFFFF
    or bh, dl
    or bl, dh
    mov rdx, 0x55
    mov r13, 0xFF
    or dx, r13w
    mov rbp, 0xFFFFFFFF
    mov rsi, 0x1F5A83BDEAA1B5D1
    FLAGS 0x2D6
    or bp, si
    mov r15, 0xB8
    mov rbx, 0x25677AE446219D2F
    or r15w, bx
    mov r13, 0x80
    mov rdx, 0xB643464D0A68A52D
    or r13w, 1
    mov r13, 0xFFFF
    mov rdx, 0xC75CD2C692427110
    or r13w, 8845
    mov r10, 0x7FFFFFFFFFFFFFFF
    mov r9, 0x81
    FLAGS 0xA03
    or r10w, -2349
    mov r11, 0xE3F6DE1429FE4FAE
    mov rbp, 0x13
    FLAGS 0xA82
    mov [buf + 8], rbp
    or r11w, [buf + 8]
    mov r8, 0x517164C02C81AD8F
    mov r10, 0x7A4BC244D3C3D18A
    mov [buf + 8], r10
    or r8w, [buf + 8]
    mov rdx, 0xFE7C089E9163308F
    mov r15, 0xFFFFFFFFFFFFFF68
    mov [buf + 8], r15
    or dx, [buf + 8]
    mov r13, 0x80000000
    mov r15, 0x31
    mov [buf + 16], r13
    or [buf + 16], r15w
    mov r13, [buf + 16]
    mov r13, 0xFFFFFFFFFFFFFF68
    mov r15, 0xD40014B6F3BE06E3
    mov [buf + 16], r13
    or [buf + 16], r15w
    mov r13, [buf + 16]
    mov rax, 0xFFFFFFFFFFFFFFBC
    mov rcx, 0x8000
    FLAGS 0xAD7
    mov [buf + 16], rax
    or [buf + 16], cx
    mov rax, [buf + 16]
    mov r10, 0xB0242F556AC2AEF6
    mov rcx, 0x90
    mov [buf + 24], r10
    or word [buf + 24], -128
    mov rcx, [buf + 24]
    mov rbp, 0x5D6B1494C50620E7
    mov r14, 0x80000000
    mov [buf + 24], rbp
    or word [buf + 24], 19783
    mov r14, [buf + 24]
    mov rdi, 0x6925C523C9B9B475
    mov r9, 0xF4BDB4FFA45E6AB0
    FLAGS 0x212
    mov [buf + 24], rdi
    or word [buf + 24], 127
    mov r9, [buf + 24]
    mov rdi, 0x8000000000000000
    mov rax, 0x8239D96CC55BD4F0
    mov rax, 0xFFFFFFFFFFFFFFEE
    or ax, -22006
    mov rax, 0x7F
    mov r9, 0xFFFFFFFFFFFFFFFF
    FLAGS 0x213
    mov rax, 0x8000
    or ax, 1
    mov r8, 0x2C81376E0503B42F
    mov r14, 0xFFFFFFFFFFFFFF18
    mov rax, 0x80000000
    or ax, -5823
    mov r14, 0xAEE802DA705D63D1
    mov r13, 0x7FFF
    or r14w, r14w
    mov rsi, 0xDF80593274F51E57
    mov rdi, 0x8
    or si, si
    mov r11, 0x1C4A2F4948D2CF29
    mov rdx, 0x100000000
    FLAGS 0x246
    or r11w, r11w
    mov r13, 0x52F8FF1A61A6B2D
    mov r11, 0xFFFFFFFFFFFFFFE1
    or r13d, r11d
    mov rax, 0x8000000000000000
    mov rbp, 0x0
    or eax, ebp
    mov rsi, 0x4D0E7672270F3636
    mov r8, 0x68
    or esi, r8d
    mov rsi, 0xEE5195B2B525DBD1
    mov r13, 0x80
    FLAGS 0x202
    or esi, -1111342510
    mov rsi, 0x7F
    mov r10, 0x80
    or esi, 2147483647
    mov r14, 0x4C4279153C619BCA
    mov r11, 0x61A11433157CC428
    or r14d, -2147483648
    mov r15, 0x7F
    mov rbx, 0x7FFF
    mov [buf + 8], rbx
    or r15d, [buf + 8]
    mov rax, 0xF8430CFBBEEBD4A7
    mov rbp, 0x90AB77BF86DF3145
    mov [buf + 8], rbp
    or eax, [buf + 8]
    mov rbx, 0x7FFFFFFF
    mov rdx, 0xFFFF
    mov [buf + 8], rdx
    or ebx, [buf + 8]
    mov r15, 0x8000
    mov r8, 0xF5F255F4885C83A
    FLAGS 0xA02
    mov [buf + 16], r15
    or [buf + 16], r8d
    mov r15, [buf + 16]
    mov rbx, 0x7FFFFFFF
    mov r10, 0x7FFFFFFFFFFFFFFF
    mov [buf + 16], rbx
    or [buf + 16], r10d
    mov rbx, [buf + 16]
    mov r11, 0x3
    mov rbp, 0x6EFD0A78FED5E211
    mov [buf + 16], r11
    or [buf + 16], ebp
    mov r11, [buf + 16]
    mov r11, 0x7F
    mov rsi, 0xFFFF
    FLAGS 0xA03
    mov [buf + 24], r11
    or dword [buf + 24], -2147483648
    mov rsi, [buf + 24]
    mov r9, 0xB23B7D8CA14E3F2F
    mov r11, 0x10000
    FLAGS 0x212
    mov [buf + 24], r9
    or dword [buf + 24], -2147483648
    mov r11, [buf + 24]
    mov rbp, 0xFFFFFFFFFFFFFFBD
    mov r9, 0xFFFFFFFF80000000
    mov [buf + 24], rbp
    or dword [buf + 24], 227270936
    mov r9, [buf + 24]
    mov r9, 0x2
    mov r13, 0x10000
    mov rax, 0x8000
    or eax, 2147483647
    mov r9, 0xDF3EC372A3E46CBB
    mov rcx, 0x3E
    mov rax, 0xD3C9621A0749CC1E
    or eax, -2147483648
    mov r8, 0x7FFF
    mov r13, 0x9845D567A84F1AE6
    mov rax, 0x2
    or eax, 1
    mov rax, 0x7BDD8004B66B2C68
    mov rsi, 0x64CD6AEF81690154
    or eax, eax
    mov rax, 0x8000
    mov rcx, 0x7F
    or eax, eax
    mov r13, 0x80000000
    mov r14, 0xFFFFFFFF80000000
    FLAGS 0x246
    or r13d, r13d
    mov rbx, 0x6AD10CFD2AA3B692
    mov rbp, 0xFFFFFFFFFFFFFFBA
    FLAGS 0xA82
    or rbx, rbp
    mov r10, 0x64
    mov r8, 0xF37CC539154DC050
    or r10, r8
    mov r9, 0x6927CC8E2D87045F
    mov r14, 0xF038C18FF6363C55
    or r9, r14
    mov rdi, 0xFFFFFFFFFFFFFF3E
    mov r8, 0xFFFFFFFFFFFFFFBD
    or rdi, -167381636
    mov rbp, 0x43951D377825D003
    mov r10, 0x9758906E810F15F0
    FLAGS 0xA82
    or rbp, 5
    mov r11, 0xFFFFFFFF
    mov rbx, 0x7F
    or r11, -1
    mov rdx, 0xFF
    mov rcx, 0x1
    mov [buf + 8], rcx
    or rdx, [buf + 8]
    mov rbp, 0x810B5C441AB171CD
    mov r13, 0x1
    mov [buf + 8], r13
    or rbp, [buf + 8]
    mov rdi, 0x67CDED329F37592
    mov rdx, 0xA3A61082F274BF44
    FLAGS 0xA02
    mov [buf + 8], rdx
    or rdi, [buf + 8]
    mov r14, 0x80
    mov rcx, 0x83064C51F9B42A9
    mov [buf + 16], r14
    or [buf + 16], rcx
    mov r14, [buf + 16]
    mov rax, 0xC022275B81DF17B7
    mov rdi, 0x59F4B46F396F169C
    mov [buf + 16], rax
    or [buf + 16], rdi
    mov rax, [buf + 16]
    mov rax, 0x80000000
    mov r13, 0x1
    mov [buf + 16], rax
    or [buf + 16], r13
    mov rax, [buf + 16]
    mov rcx, 0xBF4BE21A26D08AAC
    mov rbp, 0xC38A02DBD47E51D6
    FLAGS 0xAD7
    mov [buf + 24], rcx
    or qword [buf + 24], 5
    mov rbp, [buf + 24]
    mov r15, 0xFFFFFFFF80000000
    mov r13, 0x101407AEDABE92DA
    FLAGS 0x203
    mov [buf + 24], r15
    or qword [buf + 24], -2147483648
    mov r13, [buf + 24]
    mov rcx, 0x7FFFFFFF
    mov rbx, 0xFFFFFFFF
    FLAGS 0xA03
    mov [buf + 24], rcx
    or qword [buf + 24], 2147483647
    mov rbx, [buf + 24]
    mov r14, 0x9239DC84CD7BC901
    mov rsi, 0x3A2B85D0DE09F6C5
    FLAGS 0x203
    mov rax, 0xAEACB1B64B93EE55
    or rax, 2147483647
    mov r15, 0x3
    mov rbp, 0xFFFFFFFFFFFFFF35
    mov rax, 0x80
    or rax, 227327945
    mov r9, 0x81
    mov r10, 0x80
    mov rax, 0xCB9F91EDD774BC57
    or rax, 821257659
    mov rbp, 0xEC
    mov rax, 0x16B23C0D917B2C34
    or rbp, rbp
    mov rdi, 0xA189F623B2CC3827
    mov r9, 0x7F
    or rdi, rdi
    mov r9, 0x97448122DBADA0C9
    mov rbp, 0xFFFFFFFFFFFFFFB6
    FLAGS 0xA82
    or r9, r9
    mov r13, 0x2
    mov r12, 0x80000000
    FLAGS 0x212
    adc r13b, r12b
    mov rax, 0xFFFFFFFFFFFFFF52
    mov r12, 0x80
    adc al, r12b
    mov rdx, 0xD82900A5D79B9D2F
    mov r8, 0x86363273740F4871
    adc dl, r8b
    mov rdx, 0x7F
    mov rdi, 0xB8CC887808A7E964
    adc dl, -1
    mov r12, 0x7FFFFFFF
    mov r15, 0xFFFFFFFFFFFFFF4A
    FLAGS 0x297
    adc r12b, -98
    mov r12, 0x8000000000000000
    mov r14, 0xFFFF
    adc r12b, 127
    mov r8, 0x390C9D8190994D4C
    mov rsi, 0x100
    FLAGS 0xA03
    mov [buf + 8], rsi
    adc r8b, [buf + 8]
    mov r12, 0x81
    mov rax, 0xD77857C80420C354
    mov [buf + 8], rax
    adc r12b, [buf + 8]
    mov r8, 0xA684BA1B9518BF92
    mov r14, 0xFF
    mov [buf + 8], r14
    adc r8b, [buf + 8]
    mov r12, 0x80
    mov r15, 0x81
    mov [buf + 16], r12
    adc [buf + 16], r15b
    mov r12, [buf + 16]
    mov r13, 0x81
    mov r15, 0x7F
    mov [buf + 16], r13
    adc [buf + 16], r15b
    mov r13, [buf + 16]
    mov r10, 0x3
    mov rcx, 0xA4B459833FF39BBE
    mov [buf + 16], r10
    adc [buf + 16], cl
    mov r10, [buf + 16]
    mov rax, 0x88362A77021BBDD3
    mov r9, 0x2
    mov [buf + 24], rax
    adc byte [buf + 24], -86
    mov r9, [buf + 24]
    mov rdi, 0xC5F7EDEEDEAF47A2
    mov r12, 0xFFFF
    mov [buf + 24], rdi
    adc byte [buf + 24], -85
    mov r12, [buf + 24]
    mov r14, 0x6CD74E2B8E06403
    mov rbp, 0x7FFFFFFF
    mov [buf + 24], r14
    adc byte [buf + 24], 50
    mov rbp, [buf + 24]
    mov rax, 0x7FFFFFFF
    mov r11, 0x55
    mov rax, 0x5C
    adc al, 5
    mov r9, 0xC3FF03F6F66EE14F
    mov r11, 0xFF
    mov rax, 0xFFFFFFFFFFFFFF27
    adc al, -91
    mov rsi, 0xF67F107954D24851
    mov rcx, 0x7F
    mov rax, 0x77
    adc al, -128
    mov r9, 0xFFFFFFFF80000000
    mov rdx, 0x1
    mov rax, 0xFFFFFFFFFFFFFF3C
    mov rcx, 0x4BBC4736D8E85896
    adc ah, cl
    adc al, ch
    mov rbx, 0x0
    mov rbp, 0x1
    mov rcx, 0x928A65F228FE5BB1
    mov rdx, 0x1589F70311CA9F33
    adc ch, dl
    adc cl, dh
    mov r10, 0xCB
    mov r12, 0x80
    mov rbx, 0x10000
    mov rax, 0x7FFFFFFFFFFFFFFF
    adc bh, al
    adc bl, ah
    mov rsi, 0xFE2B09AC433685CE
    mov rbx, 0x2
    FLAGS 0xA82
    adc si, bx
    mov r11, 0xF9B1C37A96D2D2FA
    mov rdx, 0xFFFFFFFF
    adc r11w, dx
    mov r11, 0xC005AD4FE3696BA7
    mov rax, 0x6D8203272ACD6CE2
    FLAGS 0x203
    adc r11w, ax
    mov r10, 0x2C375719883514F6
    mov rax, 0x100000000
    adc r10w, -19924
    mov r10, 0x7F
    mov r9, 0x1428FC4E4F1A3247
    FLAGS 0x202
    adc r10w, 5934
    mov rsi, 0xFF
    mov rdx, 0x898D978F565407E1
    adc si, -8058
    mov rbp, 0xFFFFFFFFFFFFFFFF
    mov r12, 0xFF
    mov [buf + 8], r12
    adc bp, [buf + 8]
    mov r11, 0xAE
    mov rbp, 0x0
    FLAGS 0x212
    mov [buf + 8], rbp
    adc r11w, [buf + 8]
    mov r14, 0x19B0121A75FFE0C5
    mov r9, 0xFFFFFFFF
    mov [buf + 8], r9
    adc r14w, [buf + 8]
    mov r12, 0xFFFFFFFFFFFFFFCE
    mov rbx, 0x7FFFFFFF
    mov [buf + 16], r12
    adc [buf + 16], bx
    mov r12, [buf + 16]
    mov rdi, 0x8CA612CA4AF38DC
    mov r8, 0x80
    mov [buf + 16], rdi
    adc [buf + 16], r8w
    mov rdi, [buf + 16]
    mov rbx, 0x8000
    mov r9, 0x8000
    mov [buf + 16], rbx
    adc [buf + 16], r9w
    mov rbx, [buf + 16]
    mov r15, 0xB12A52BC4D9C3568
    mov rdi, 0x52C77DC44196255D
    mov [buf + 24], r15
    adc word [buf + 24], -1890
    mov rdi, [buf + 24]
    mov r14, 0xFFFFFFFFFFFFFF0A
    mov r13, 0x322B493B92781D89
    mov [buf + 24], r14
    adc word [buf + 24], 22197
    mov r13, [buf + 24]
    mov rdx, 0xB95C0576A58146FC
    mov r15, 0xFFFFFFFFFFFFFFDE
    mov [buf + 24], rdx
    adc word [buf + 24], -29278
    mov r15, [buf + 24]
    mov r8, 0x861514766090EEA8
    mov r13, 0x1D75C7E1FE94E126
    FLAGS 0x297
    mov rax, 0xFFFFFFFFFFFFFF80
    adc ax, 127
    mov rbp, 0x1411409FF0AF23E7
    mov r13, 0x3ADE917324D0ACD9
    mov rax, 0xFFFFFFFFFFFFFF66
    adc ax, 1
    mov r14, 0xFFFFFFFFFFFFFF86
    mov r10, 0x1
    mov rax, 0x0
    adc ax, 5
    mov r14, 0x25
    mov rdx, 0x89F2D28B42EE9D69
    FLAGS 0xA03
    adc r14w, r14w
    mov rsi, 0x7FFF
    mov r8, 0xDFF3EE8F77ACE0CC
    adc si, si
    mov r10, 0xBAD337B3BD92A8D
    mov rdx, 0x71C392AFD11F477F
    adc r10w, r10w
    mov r14, 0x100
    mov rcx, 0xBF
    FLAGS 0xA82
    adc r14d, ecx
    mov r14, 0x1
    mov r8, 0x7FFFFFFFFFFFFFFF
    adc r14d, r8d
    mov r14, 0xEE
    mov r11, 0x81
    adc r14d, r11d
    mov rbp, 0xC3EB651FC56C3560
    mov rcx, 0xFF30B9BD6899A021
    adc ebp, -1
    mov rsi, 0xFFFFFFFFFFFFFF33
    mov rdi, 0x100000000
    adc esi, -2147483648
    mov r15, 0x7FFF
    mov rdi, 0xFFFFFFFFFFFFFF92
    adc r15d, 249245243
    mov rsi, 0x87FAE1E1ACA3E46
    mov r13, 0x6
    mov [buf + 8], r13
    adc esi, [buf + 8]
    mov rsi, 0x8000
    mov r13, 0x3
    mov [buf + 8], r13
    adc esi, [buf + 8]
    mov r15, 0xB728FB9D89A39C22
    mov rcx, 0xFFFFFFFF
    FLAGS 0x2D6
    mov [buf + 8], rcx
    adc r15d, [buf + 8]
    mov r10, 0xE8
    mov r8, 0x81
    FLAGS 0xA03
    mov [buf + 16], r10
    adc [buf + 16], r8d
    mov r10, [buf + 16]
    mov rsi, 0x8000
    mov r12, 0x0
    mov [buf + 16], rsi
    adc [buf + 16], r12d
    mov rsi, [buf + 16]
    mov r15, 0x81
    mov r11, 0x7FFFFFFF
    mov [buf + 16], r15
    adc [buf + 16], r11d
    mov r15, [buf + 16]
    mov rbp, 0x7F
    mov r14, 0x8FF3BB65DA4CB0CE
    mov [buf + 24], rbp
    adc dword [buf + 24], 2050679800
    mov r14, [buf + 24]
    mov r10, 0x62F393C92FB6C9DF
    mov r12, 0xFFFF
    mov [buf + 24], r10
    adc dword [buf + 24], 2147483647
    mov r12, [buf + 24]
    mov rbx, 0x10291CC0CAC7EEE3
    mov r10, 0xA4F4FE9DA363A3BA
    FLAGS 0x212
    mov [buf + 24], rbx
    adc dword [buf + 24], -2147483648
    mov r10, [buf + 24]
    mov rax, 0xBA18024467F36978
    mov rdx, 0x7FFF
    FLAGS 0xAD7
    mov rax, 0xED
    adc eax, 2147483647
    mov r14, 0x7F
    mov r12, 0x100
    mov rax, 0xFFFFFFFF80000000
    adc eax, 5
    mov rbx, 0x7F
    mov rbp, 0x100000000
    FLAGS 0xAD7
    mov rax, 0x1
    adc eax, -1
    mov rbx, 0x2
    mov r13, 0xEB9C8671BBD3FDC7
    adc ebx, ebx
    mov r11, 0xA2697574654D966F
    mov r15, 0x4951543E7DA56C7E
    adc r11d, r11d
    mov r12, 0x80
    mov rbp, 0x0
    adc r12d, r12d
    mov r9, 0x57
    mov r14, 0x7FFF
    adc r9, r14
    mov r13, 0xFFFFFFFFFFFFFF80
    mov r8, 0xDC79F29388AE704A
    adc r13, r8
    mov r15, 0x7FFF
    mov r8, 0xFFFFFFFFFFFFFF57
    FLAGS 0x203
    adc r15, r8
    mov rdi, 0x7B6B38A9B57B6321
    mov r12, 0x7F
    adc rdi, 1086898287
    mov r14, 0xFFFFFFFFFFFFFF01
    mov rbp, 0x80
    adc r14, 1
    mov r15, 0x81
    mov rbx, 0x583264E43ED4ED8E
    adc r15, 5
    mov rbp, 0xD8
    mov r10, 0xAE15E8F9921E9B9F
    FLAGS 0x202
    mov [buf + 8], r10
    adc rbp, [buf + 8]
    mov r15, 0x9CDE34A4E0BAC46
    mov rbx, 0x3
    mov [buf + 8], rbx
    adc r15, [buf + 8]
    mov r9, 0x7FFF
    mov rsi, 0xFFFFFFFFFFFFFF8E
    mov [buf + 8], rsi
    adc r9, [buf + 8]
    mov rbx, 0xB43E791C5432ED1C
    mov r15, 0x7D33CC0D40B6B0F9
    mov [buf + 16], rbx
    adc [buf + 16], r15
    mov rbx, [buf + 16]
    mov rsi, 0xFFFFFFFFFFFFFF1A
    mov r9, 0xF4EFB4AE7402D22
    FLAGS 0x246
    mov [buf + 16], rsi
    adc [buf + 16], r9
    mov rsi, [buf + 16]
    mov rax, 0x2
    mov rbp, 0xFFFFFFFFFFFFFF7D
    FLAGS 0x246
    mov [buf + 16], rax
    adc [buf + 16], rbp
    mov rax, [buf + 16]
    mov r8, 0x3
    mov r15, 0x80000000
    mov [buf + 24], r8
    adc qword [buf + 24], 5
    mov r15, [buf + 24]
    mov rdx, 0x1
    mov rsi, 0x0
    mov [buf + 24], rdx
    adc qword [buf + 24], 2147483647
    mov rsi, [buf + 24]
    mov r13, 0x1CA49F53121878FE
    mov rsi, 0xFFFFFFFFFFFFFF2F
    mov [buf + 24], r13
    adc qword [buf + 24], -2147483648
    mov rsi, [buf + 24]
    mov r12, 0xBA5FE411DABAA6DA
    mov r11, 0x5AAB5D986DF003BA
    mov rax, 0x10000
    adc rax, 0
    mov r8, 0x7FFFFFFFFFFFFFFF
    mov rdx, 0xEBDA105BC105C21F
    mov rax, 0xCF13F94366220AEB
    adc rax, 0
    mov r11, 0xAF
    mov r9, 0xE5342550AEA3C50C
    mov rax, 0xFFFFFFFFFFFFFF80
    adc rax, -2147483648
    mov r10, 0x76
    mov rdx, 0x7FFF
    adc r10, r10
    mov r15, 0xDE966DCF581D66CF
    mov r13, 0x7FFFFFFF
    adc r15, r15
    mov rdi, 0xFFFFFFFFFFFFFF80
    mov rbx, 0x7D6FBDE0148D6F9F
    adc rdi, rdi
    mov r14, 0x7FFF
    mov rcx, 0x4EF7F6733A9DC2EF
    sbb r14b, cl
    mov r12, 0xC387BBF4AB8ABA8
    mov rax, 0x7F
    FLAGS 0x212
    sbb r12b, al
    mov r8, 0xE12BCA37A8760BD7
    mov r9, 0x9E7E9F3137F23BB3
    sbb r8b, r9b
    mov r11, 0x9940F770A7F87AD6
    mov r15, 0x8000000000000000
    sbb r11b, -41
    mov rcx, 0x199378B57326DE7
    mov r8, 0x88F0C1D49E906213
    sbb cl, 127
    mov r13, 0x7FFFFFFF
    mov rsi, 0x6
    sbb r13b, 1
    mov r15, 0x2
    mov r8, 0x80000000
    mov [buf + 8], r8
    sbb r15b, [buf + 8]
    mov r10, 0xB673C43E69E6051F
    mov rdi, 0x81
    mov [buf + 8], rdi
    sbb r10b, [buf + 8]
    mov r13, 0xFFFFFFFFFFFFFF80
    mov rdx, 0x250CDB02BF93C50F
    mov [buf + 8], rdx
    sbb r13b, [buf + 8]
    mov r12, 0x3
    mov r9, 0x80000000
    mov [buf + 16], r12
    sbb [buf + 16], r9b
    mov r12, [buf + 16]
    mov r11, 0xFFFF
    mov r12, 0xBB38C2B4477B9C82
    mov [buf + 16], r11
    sbb [buf + 16], r12b
    mov r11, [buf + 16]
    mov r12, 0x8000
    mov r15, 0x2
    mov [buf + 16], r12
    sbb [buf + 16], r15b
    mov r12, [buf + 16]
    mov r11, 0x9253ED4D51647A59
    mov r8, 0x81
    FLAGS 0xA02
    mov [buf + 24], r11
    sbb byte [buf + 24], -128
    mov r8, [buf + 24]
    mov rcx, 0xFFFFFFFF
    mov rbp, 0xFFFFFFFFFFFFFFFF
    FLAGS 0x2D6
    mov [buf + 24], rcx
    sbb byte [buf + 24], -32
    mov rbp, [buf + 24]
    mov rsi, 0x81
    mov r13, 0x995EC9A41F4F0EF5
    mov [buf + 24], rsi
    sbb byte [buf + 24], -41
    mov r13, [buf + 24]
    mov r10, 0x2
    mov rsi, 0xEE2EB8B53F44124
    mov rax, 0xE1
    sbb al, 127
    mov r14, 0x1680308F8E747930
    mov r8, 0xFFFFFFFFFFFFFFD5
    mov rax, 0xFFFFFFFFFFFFFFFF
    sbb al, 121
    mov rax, 0x85704E92EA766B63
    mov r15, 0x6D897725D9A318FE
    mov rax, 0xB2
    sbb al, 4
    mov rcx, 0x8000000000000000
    mov r9, 0x0
    FLAGS 0x202
    mov rcx, 0x2E513C091CE960F4
    mov rdx, 0xFBD14DCD77498108
    sbb ch, dl
    sbb cl, dh
    mov rsi, 0x9A171FA9E913BD02
    mov r14, 0x4F041A10A07FDBAE
    mov rcx, 0x81
    mov rdx, 0x8308B54FD10A0C65
    sbb ch, dl
    sbb cl, dh
    mov rbx, 0x35463BA21ACD2EFB
    mov r10, 0x56
    mov rbx, 0x8000
    mov rcx, 0x80
    sbb bh, cl
    sbb bl, ch
    mov r10, 0x51C89827CEBCFD65
    mov rbp, 0xE535183CDA37A53B
    sbb r10w, bp
    mov rcx, 0x930B556C354697D0
    mov r14, 0x81FAC0F5D6D510AE
    sbb cx, r14w
    mov r13, 0x80
    mov rdi, 0x7FFFFFFF
    sbb r13w, di
    mov rax, 0x7EDBF885D89D734B
    mov rdi, 0x8000
    sbb ax, -29756
    mov r9, 0xFFFF
    mov r13, 0x7F
    FLAGS 0x2D6
    sbb r9w, 0
    mov r10, 0xFFFFFFFFFFFFFFC3
    mov r8, 0x6357CDCF2447859
    sbb r10w, -1
    mov r14, 0x1
    mov rax, 0xEC82A6F244802883
    mov [buf + 8], rax
    sbb r14w, [buf + 8]
    mov r13, 0x100000000
    mov r15, 0x6023B735CB037ADF
    mov [buf + 8], r15
    sbb r13w, [buf + 8]
    mov rbx, 0xB58B8A75C6A7F08F
    mov r9, 0xF4BA19A67CC9FDE
    mov [buf + 8], r9
    sbb bx, [buf + 8]
    mov r8, 0x1
    mov rax, 0xC3A7139E6D76B9B7
    FLAGS 0x297
    mov [buf + 16], r8
    sbb [buf + 16], ax
    mov r8, [buf + 16]
    mov r13, 0xFFFFFFFFFFFFFF98
    mov rsi, 0x6BBA950DCF2FA5B6
    mov [buf + 16], r13
    sbb [buf + 16], si
    mov r13, [buf + 16]
    mov rax, 0x18CEE18EC6DC2239
    mov r15, 0x8000
    FLAGS 0x246
    mov [buf + 16], rax
    sbb [buf + 16], r15w
    mov rax, [buf + 16]
    mov rdx, 0x8184A6AA89E723CF
    mov rcx, 0x10000
    FLAGS 0xA03
    mov [buf + 24], rdx
    sbb word [buf + 24], 5
    mov rcx, [buf + 24]
    mov r10, 0x5C5C935B2025EB81
    mov r12, 0x32479E4CF187FC99
    mov [buf + 24], r10
    sbb word [buf + 24], -1982
    mov r12, [buf + 24]
    mov r12, 0xC6EBD8D2A381A847
    mov r9, 0x248A4B8F71161832
    mov [buf + 24], r12
    sbb word [buf + 24], 0
    mov r9, [buf + 24]
    mov rax, 0x100000000
    mov rbp, 0x9B2211DF4F14D14C
    mov rax, 0x876367CB90019587
    sbb ax, 127
    mov rbx, 0xE87400A5D59F259B
    mov rdi, 0x7D9C3D91743BF676
    FLAGS 0xA02
    mov rax, 0x7C78F118C280536D
    sbb ax, 12840
    mov r12, 0x701E7808377AE1E1
    mov r14, 0xC71A976326FA8553
    mov rax, 0xFFFFFFFF80000000
    sbb ax, 15335
    mov rcx, 0x7FFFFFFF
    mov r12, 0x7FFFFFFFFFFFFFFF
    sbb cx, cx
    mov r14, 0x347676E9745DDFAE
    mov r15, 0x3
    sbb r14w, r14w
    mov rcx, 0xFFFFFFFF80000000
    mov r11, 0xFFFFFFFF
    sbb cx, cx
    mov r15, 0x81
    mov r10, 0xFFFFFFFFFFFFFFFF
    sbb r15d, r10d
    mov r10, 0xC0C4FE410C5CB960
    mov r9, 0x1EA2CA4CD1820677
    sbb r10d, r9d
    mov rax, 0xFFFFFFFF
    mov rdi, 0xA82F3601B6C5DD0C
    sbb eax, edi
    mov rcx, 0xD6A66850022D49BD
    mov r9, 0x4EEC02B6E2485E0C
    sbb ecx, 0
    mov r13, 0x10000
    mov r12, 0x56992E4311070215
    sbb r13d, -167345223
    mov rdx, 0xFFFF
    mov r12, 0x93AEFF635FF23E2D
    sbb edx, 672819504
    mov r10, 0xC2
    mov rdi, 0x8000000000000000
    mov [buf + 8], rdi
    sbb r10d, [buf + 8]
    mov rcx, 0xC758FA5E0060E7D3
    mov rax, 0x7F90CEE78FE6D8A5
    FLAGS 0xA43
    mov [buf + 8], rax
    sbb ecx, [buf + 8]
    mov rdx, 0xFC800E219875A36
    mov rsi, 0x6ABD38A4E48590C0
    mov [buf + 8], rsi
    sbb edx, [buf + 8]
    mov rax, 0x10000
    mov r14, 0xFFFFFFFF80000000
    mov [buf + 16], rax
    sbb [buf + 16], r14d
    mov rax, [buf + 16]
    mov r13, 0x71AC6946CB189963
    mov r11, 0xFFFFFFFFFFFFFF82
    mov [buf + 16], r13
    sbb [buf + 16], r11d
    mov r13, [buf + 16]
    mov r9, 0x7FFFFFFF
    mov rdx, 0xFFFFFFFFFFFFFFE9
    mov [buf + 16], r9
    sbb [buf + 16], edx
    mov r9, [buf + 16]
    mov r11, 0x7FFFFFFF
    mov rbx, 0xAA1E7BDFCBB3A503
    mov [buf + 24], r11
    sbb dword [buf + 24], 2147483647
    mov rbx, [buf + 24]
    mov r14, 0x80000000
    mov rbx, 0x100000000
    FLAGS 0xA02
    mov [buf + 24], r14
    sbb dword [buf + 24], 2147483647
    mov rbx, [buf + 24]
    mov r8, 0x7F
    mov r11, 0x1
    mov [buf + 24], r8
    sbb dword [buf + 24], -1
    mov r11, [buf + 24]
    mov rbp, 0x13A2F7554261B95C
    mov r8, 0xDBFB0EFF38F76B17
    FLAGS 0x297
    mov rax, 0x7FFFFFFF
    sbb eax, 2147483647
    mov r13, 0x2
    mov r15, 0xB7
    mov rax, 0xFF
    sbb eax, -2147483648
    mov r15, 0x7FFF
    mov r9, 0x33674408D13C039B
    FLAGS 0x2D6
    mov rax, 0x5632FBE080127E6A
    sbb eax, 2147483647
    mov r8, 0x43AF67A6C8ADB4D0
    mov r12, 0x10000
    sbb r8d, r8d
    mov r15, 0xFFFFFFFFFFFFFF04
    mov r8, 0xA04FFF07E0269553
    FLAGS 0x297
    sbb r15d, r15d
    mov r11, 0x1A64BA2544BC0268
    mov rbx, 0x88CB1097643AAD90
    sbb r11d, r11d
    mov r14, 0xFFFFFFFF
    mov r9, 0xF6
    sbb r14, r9
    mov rdi, 0x10000
    mov r10, 0x54
    sbb rdi, r10
    mov rbp, 0xFFFF
    mov rax, 0x1C10970EE58DFE7E
    FLAGS 0x203
    sbb rbp, rax
    mov r14, 0xFFFFFFFFFFFFFF80
    mov r9, 0xFFFF
    sbb r14, -128
    mov r11, 0x93AA7480E81A03E
    mov rsi, 0x6D7B870A577576C8
    sbb r11, 962868036
    mov rcx, 0xA1F330D8B4F572D3
    mov rbp, 0x4B6A7C4F25A35B58
    sbb rcx, -2147483648
    mov rdi, 0x2A30882CD67FDD5D
    mov rdx, 0x282010C78CDED38F
    mov [buf + 8], rdx
    sbb rdi, [buf + 8]
    mov rdx, 0x8F7D15E9BA13F988
    mov rax, 0x2
    mov [buf + 8], rax
    sbb rdx, [buf + 8]
    mov r8, 0xC400472A63475C89
    mov r15, 0xF121D27938ECB091
    FLAGS 0xA03
    mov [buf + 8], r15
    sbb r8, [buf + 8]
    mov rbp, 0x66D7B608E0EC2E26
    mov rcx, 0x5AB0F8F683B0CA37
    mov [buf + 16], rbp
    sbb [buf + 16], rcx
    mov rbp, [buf + 16]
    mov r14, 0x2
    mov r13, 0x7F
    mov [buf + 16], r14
    sbb [buf + 16], r13
    mov r14, [buf + 16]
    mov r8, 0x10000
    mov rcx, 0x100000000
    mov [buf + 16], r8
    sbb [buf + 16], rcx
    mov r8, [buf + 16]
    mov r11, 0x3
    mov rax, 0xF28A046DB4D222B2
    mov [buf + 24], r11
    sbb qword [buf + 24], 2147483647
    mov rax, [buf + 24]
    mov r9, 0x9A4648D2874B2B0B
    mov rsi, 0xD3FF61F821460064
    mov [buf + 24], r9
    sbb qword [buf + 24], -2147483648
    mov rsi, [buf + 24]
    mov r11, 0x8000000000000000
    mov rdi, 0x3
    FLAGS 0x297
    mov [buf + 24], r11
    sbb qword [buf + 24], -808583814
    mov rdi, [buf + 24]
    mov rdx, 0x100000000
    mov r15, 0xA9
    FLAGS 0xA82
    mov rax, 0x10000
    sbb rax, 1191481932
    mov r12, 0x2
    mov rdi, 0x7FFFFFFF
    mov rax, 0x81
    sbb rax, -2147483648
    mov r10, 0x8000000000000000
    mov r9, 0x4F77778F26E20082
    mov rax, 0x9CA893CD34877FD2
    sbb rax, -1964827788
    mov r14, 0xFFFFFFFFFFFFFF49
    mov r13, 0xFFFFFFFFFFFFFFE8
    sbb r14, r14
    mov r11, 0xFFFFFFFFFFFFFF80
    mov r8, 0xBA87C83FB7A08792
    FLAGS 0x2D6
    sbb r11, r11
    mov r11, 0x8000000000000000
    mov rdx, 0xCDC24A32F65008E
    sbb r11, r11
    mov r8, 0x9AB5977F9BA324C9
    mov r10, 0x8000000000000000
    and r8b, r10b
    mov r9, 0x7FFF
    mov r10, 0xBF90CD16021C0761
    and r9b, r10b
    mov r8, 0x6387DCF9DC8F577
    mov r12, 0x8000
    and r8b, r12b
    mov rdi, 0x19BEA4C39DF0717C
    mov rbp, 0x8AAF37511589A306
    FLAGS 0xA03
    and dil, -7
    mov r15, 0x13CC3822387528E0
    mov rdi, 0x100000000
    and r15b, 1
    mov r15, 0xFFFFFFFFFFFFFF80
    mov r9, 0x2EF58AA5AA3EEE23
    and r15b, -1
    mov r12, 0xAE138FA112BC820
    mov rcx, 0x7FFF
    FLAGS 0x297
    mov [buf + 8], rcx
    and r12b, [buf + 8]
    mov rbp, 0xE
    mov rdx, 0x80
    mov [buf + 8], rdx
    and bpl, [buf + 8]
    mov rcx, 0xFFFFFFFFFFFFFFB7
    mov rdi, 0xFFFFFFFFFFFFFFFF
    mov [buf + 8], rdi
    and cl, [buf + 8]
    mov rdi, 0x83CC9971D795DA71
    mov rbp, 0x848047085C477E1A
    FLAGS 0x202
    mov [buf + 16], rdi
    and [buf + 16], bpl
    mov rdi, [buf + 16]
    mov r13, 0xABC74ED5569ED2C9
    mov rbx, 0xF7
    mov [buf + 16], r13
    and [buf + 16], bl
    mov r13, [buf + 16]
    mov rdx, 0x100
    mov r13, 0xFFFFFFFF80000000
    mov [buf + 16], rdx
    and [buf + 16], r13b
    mov rdx, [buf + 16]
    mov rax, 0xD4619C7CD8BFDD84
    mov r13, 0xFFFFFFFFFFFFFF99
    mov [buf + 24], rax
    and byte [buf + 24], 1
    mov r13, [buf + 24]
    mov r12, 0x5F04D9B6D92977BE
    mov rbx, 0x3
    mov [buf + 24], r12
    and byte [buf + 24], 119
    mov rbx, [buf + 24]
    mov r15, 0x88
    mov rbx, 0xD5AAC868E3913B1A
    mov [buf + 24], r15
    and byte [buf + 24], -1
    mov rbx, [buf + 24]
    mov r11, 0x7FFF
    mov r15, 0xFFFFFFFFFFFFFFDE
    mov rax, 0x52FBCF7FA431C930
    and al, 24
    mov rsi, 0x81
    mov r11, 0xFF
    mov rax, 0xAEAD069B3604327B
    and al, 93
    mov rax, 0xD3420ED644C6B33C
    mov r9, 0x3B83200066AED1DA
    FLAGS 0xA03
    mov rax, 0x100
    and al, 47
    mov r14, 0x3
    mov rsi, 0xB4
    mov rax, 0xFFFFFFFFFFFFFF86
    mov rdx, 0x30471C7375BA1202
    and ah, dl
    and al, dh
    mov r8, 0x7F
    mov rdi, 0x345F8EE951DAC909
    FLAGS 0xA03
    mov rcx, 0x8000000000000000
    mov rbx, 0x51F1F647A4A3F24E
    and ch, bl
    and cl, bh
    mov r13, 0xFFFF
    mov r11, 0xFFFFFFFFFFFFFF8C
    FLAGS 0x212
    mov rcx, 0x93
    mov rdx, 0x8000
    and ch, dl
    and cl, dh
    mov rsi, 0x2F94A7F551EDA33F
    mov r10, 0x309208130983E9A3
    and si, r10w
    mov r11, 0x1
    mov rbp, 0x279521C7EA4001C3
    and r11w, bp
    mov rsi, 0xFFFFFFFFFFFFFFFF
    mov r14, 0x8E0C00DAB5CA338D
    and si, r14w
    mov r11, 0x7B9F951F0C7B0F74
    mov r13, 0x8000
    FLAGS 0x213
    and r11w, -26806
    mov rbp, 0x10000
    mov rcx, 0x38
    and bp, 32560
    mov rax, 0x0
    mov rdi, 0x7FFFFFFF
    and ax, 26787
    mov r15, 0xFFFFFFFFFFFFFFF4
    mov r14, 0x992D0875DF2D8FD3
    mov [buf + 8], r14
    and r15w, [buf + 8]
    mov r11, 0x26B280D38D71E816
    mov r12, 0x6C19C38C56719CC4
    FLAGS 0x212
    mov [buf + 8], r12
    and r11w, [buf + 8]
    mov r11, 0x6F1FF7F96D112D7C
    mov r12, 0x205F83724E61E93D
    FLAGS 0x2D6
    mov [buf + 8], r12
    and r11w, [buf + 8]
    mov rcx, 0x9F0489A06CC74BB3
    mov r9, 0x0
    FLAGS 0x246
    mov [buf + 16], rcx
    and [buf + 16], r9w
    mov rcx, [buf + 16]
    mov r15, 0xA7
    mov rsi, 0xFFFFFFFFFFFFFFFF
    mov [buf + 16], r15
    and [buf + 16], si
    mov r15, [buf + 16]
    mov r14, 0x67D88876BDC0A2F0
    mov r10, 0xF1E25D347A23A5F4
    mov [buf + 16], r14
    and [buf + 16], r10w
    mov r14, [buf + 16]
    mov r13, 0x100
    mov r15, 0xFFFF
    mov [buf + 24], r13
    and word [buf + 24], 16228
    mov r15, [buf + 24]
    mov rdi, 0x29D92163FE7F14BE
    mov r12, 0xFFFFFFFFFFFFFF22
    mov [buf + 24], rdi
    and word [buf + 24], -13180
    mov r12, [buf + 24]
    mov rax, 0x3
    mov r13, 0x8B8A7836D622D6A1
    mov [buf + 24], rax
    and word [buf + 24], -12361
    mov r13, [buf + 24]
    mov r12, 0x4BD243C90824A24B
    mov r8, 0x1
    mov rax, 0x8D51D0097A747090
    and ax, 8396
    mov rax, 0x3
    mov r14, 0x95634C942A26A9DF
    mov rax, 0x95FE255C42759AB3
    and ax, -25269
    mov rbp, 0x852A0737822C2D19
    mov r10, 0x2
    mov rax, 0x37E9D73BFB16D44E
    and ax, 120
    mov r13, 0xFFFFFFFFFFFFFFD4
    mov rdx, 0x64
    and r13w, r13w
    mov rdx, 0xFFFFFFFF
    mov r15, 0xFFFF
    FLAGS 0x246
    and dx, dx
    mov r13, 0xC5
    mov rax, 0x2
    FLAGS 0x2D6
    and r13w, r13w
    mov r13, 0xFFFFFFFFFFFFFF9F
    mov r12, 0x5C3A02845DD7E90E
    and r13d, r12d
    mov rax, 0x80000000
    mov rsi, 0x11B2BAF9857A4270
    and eax, esi
    mov r9, 0xFAE77DB28DE2C2F1
    mov rbx, 0x5175F363FF783D03
    and r9d, ebx
    mov rsi, 0xFFFFFFFFFFFFFFCA
    mov r9, 0xFFFFFFFFFFFFFF80
    FLAGS 0x203
    and esi, 2147483647
    mov r8, 0xC936750AB492E0CE
    mov r11, 0xFFFFFFFFFFFFFF35
    and r8d, 1112917425
    mov r9, 0x7FFFFFFF
    mov r15, 0x3F0D9BF5A3A7B3DC
    FLAGS 0x212
    and r9d, 2147483647
    mov rbp, 0xFFFFFFFFFFFFFFFF
    mov rcx, 0x7FFFFFFF
    mov [buf + 8], rcx
    and ebp, [buf + 8]
    mov r11, 0xFFFFFFFFFFFFFFFF
    mov r9, 0x1
    mov [buf + 8], r9
    and r11d, [buf + 8]
    mov r15, 0x0
    mov r14, 0xAA68A15286AB4159
    mov [buf + 8], r14
    and r15d, [buf + 8]
    mov r15, 0x7FFFFFFFFFFFFFFF
    mov r8, 0xFC
    mov [buf + 16], r15
    and [buf + 16], r8d
    mov r15, [buf + 16]
    mov rsi, 0x8000
    mov r9, 0x7C
    FLAGS 0x213
    mov [buf + 16], rsi
    and [buf + 16], r9d
    mov rsi, [buf + 16]
    mov rcx, 0x100
    mov r12, 0x44
    FLAGS 0x202
    mov [buf + 16], rcx
    and [buf + 16], r12d
    mov rcx, [buf + 16]
    mov rsi, 0xFF33AC47BF9C856D
    mov rbx, 0xC274E3B7C4AF3335
    FLAGS 0xA02
    mov [buf + 24], rsi
    and dword [buf + 24], 5
    mov rbx, [buf + 24]
    mov rdx, 0xD8C6C0A0BECD4032
    mov r15, 0x12D62A915E899D46
    FLAGS 0x246
    mov [buf + 24], rdx
    and dword [buf + 24], 1
    mov r15, [buf + 24]
    mov r8, 0xE4295417E16E9B49
    mov r13, 0xFFFFFFFFFFFFFF34
    mov [buf + 24], r8
    and dword [buf + 24], 494844409
    mov r13, [buf + 24]
    mov r10, 0xF68D703791823B2E
    mov r12, 0xCFA07FDBC8F4C962
    mov rax, 0x7FFFFFFFFFFFFFFF
    and eax, 127
    mov rdx, 0xFFFFFFFFFFFFFFB5
    mov rdi, 0x92
    mov rax, 0x77
    and eax, 1
    mov r12, 0x152B17EC26AEFBB4
    mov rbp, 0x8C795F786199F679
    FLAGS 0x212
    mov rax, 0x3
    and eax, 2147483647
    mov r11, 0x4503B0C11A088FA5
    mov rdx, 0x27
    and r11d, r11d
    mov rbx, 0xAD281BBA8E5A23E3
    mov r10, 0x22E5050C5D0679E5
    and ebx, ebx
    mov r14, 0xFFFFFFFF
    mov rcx, 0xFF
    and r14d, r14d
    mov r14, 0x11FD42EDCEC5363E
    mov rsi, 0xFFFFFFFFFFFFFFE4
    and r14, rsi
    mov r9, 0xC9CD6E6F3089C665
    mov r14, 0xB2E23F258370BE86
    and r9, r14
    mov rax, 0xF1956B989AEA4BEA
    mov r9, 0x100
    and rax, r9
    mov rcx, 0x38F2609003B31805
    mov r8, 0x3
    FLAGS 0x203
    and rcx, -2147483648
    mov rbx, 0x586C6A2D7DC1BD80
    mov r9, 0x7FFFFFFF
    FLAGS 0x212
    and rbx, -2147483648
    mov rbp, 0x7F
    mov r10, 0x2EE8F5478E8F5B2B
    and rbp, 2147483647
    mov r10, 0xC8BE8F41818D003B
    mov r9, 0xD3B94714B87FCB78
    mov [buf + 8], r9
    and r10, [buf + 8]
    mov r12, 0x17
    mov r9, 0x81
    mov [buf + 8], r9
    and r12, [buf + 8]
    mov rdx, 0x9791A47E0BC67904
    mov rbp, 0xFFFFFFFF
    FLAGS 0xA02
    mov [buf + 8], rbp
    and rdx, [buf + 8]
    mov rax, 0xFFFFFFFFFFFFFF5B
    mov rcx, 0xE631C7E33A3ED6E2
    mov [buf + 16], rax
    and [buf + 16], rcx
    mov rax, [buf + 16]
    mov rbx, 0xA7B9BFFCD3684832
    mov rdi, 0x6A
    mov [buf + 16], rbx
    and [buf + 16], rdi
    mov rbx, [buf + 16]
    mov r12, 0x4BA7D060075AD805
    mov r8, 0xA5A8AAF62886937B
    FLAGS 0xAD7
    mov [buf + 16], r12
    and [buf + 16], r8
    mov r12, [buf + 16]
    mov r8, 0x40D96F9584946EC4
    mov r11, 0xC8AB871A87415430
    mov [buf + 24], r8
    and qword [buf + 24], -247188982
    mov r11, [buf + 24]
    mov rsi, 0xFFFFFFFFFFFFFFAF
    mov r10, 0x7A25B27D35D90F0A
    mov [buf + 24], rsi
    and qword [buf + 24], 1488439628
    mov r10, [buf + 24]
    mov rbp, 0x604603C55A76D7FE
    mov r13, 0x7FFFFFFFFFFFFFFF
    mov [buf + 24], rbp
    and qword [buf + 24], 2147483647
    mov r13, [buf + 24]
    mov rcx, 0xE
    mov rax, 0x33FEF80983CBB330
    FLAGS 0x2D6
    mov rax, 0x8000
    and rax, 127
    mov rax, 0x10000
    mov r12, 0xF66A5DA7A5319C57
    mov rax, 0x0
    and rax, 1
    mov rdx, 0x8000
    mov rdi, 0xFFFFFFFFFFFFFFFF
    mov rax, 0x8000000000000000
    and rax, -2147483648
    mov rdi, 0x80
    mov r10, 0x80000000
    FLAGS 0x212
    and rdi, rdi
    mov rax, 0x55
    mov r9, 0x840F490E95284470
    FLAGS 0x213
    and rax, rax
    mov rbp, 0x859C5E507B222E7E
    mov r8, 0x837DACF31AF44E8D
    FLAGS 0x213
    and rbp, rbp
    mov rax, 0x3
    mov rdi, 0x1F8946A6BE36D7A0
    sub al, dil
    mov rdi, 0x3
    mov rsi, 0x100000000
    sub dil, sil
    mov r13, 0xFFFFFFFF80000000
    mov r11, 0xBF02E49E76E6D263
    sub r13b, r11b
    mov r10, 0xFF
    mov rsi, 0x17
    FLAGS 0x202
    sub r10b, 127
    mov r13, 0x80000000
    mov rax, 0xFF
    sub r13b, 72
    mov r15, 0x22BDE1392C5BFED5
    mov r11, 0x9D3E39BAB299524F
    FLAGS 0x212
    sub r15b, 48
    mov rbp, 0x88B23FB41FA56792
    mov r12, 0xFFFF
    mov [buf + 8], r12
    sub bpl, [buf + 8]
    mov rsi, 0xECB2F3A0483A4BA7
    mov r14, 0x7FFFFFFF
    FLAGS 0x297
    mov [buf + 8], r14
    sub sil, [buf + 8]
    mov rsi, 0xCDAAEE978BC1FE4F
    mov r10, 0xF746FF3580C5FBD7
    mov [buf + 8], r10
    sub sil, [buf + 8]
    mov rbp, 0x0
    mov r11, 0x2D62B503C0342CCC
    FLAGS 0x213
    mov [buf + 16], rbp
    sub [buf + 16], r11b
    mov rbp, [buf + 16]
    mov r9, 0x8000000000000000
    mov r8, 0xF714F4F4898823D8
    mov [buf + 16], r9
    sub [buf + 16], r8b
    mov r9, [buf + 16]
    mov rbx, 0x7F
    mov r10, 0xE43E5E72787E3160
    mov [buf + 16], rbx
    sub [buf + 16], r10b
    mov rbx, [buf + 16]
    mov rcx, 0x8000000000000000
    mov r15, 0xA4327D8621EF29E9
    FLAGS 0xA43
    mov [buf + 24], rcx
    sub byte [buf + 24], 127
    mov r15, [buf + 24]
    mov r15, 0x30F161F837900D11
    mov r12, 0x0
    mov [buf + 24], r15
    sub byte [buf + 24], -117
    mov r12, [buf + 24]
    mov r15, 0x81
    mov r13, 0x0
    mov [buf + 24], r15
    sub byte [buf + 24], 105
    mov r13, [buf + 24]
    mov rbx, 0x0
    mov rdx, 0x2390DDE23305EAA1
    mov rax, 0x3
    sub al, 23
    mov r10, 0x21B5D116B2E69CC9
    mov r13, 0xFFFFFFFF80000000
    mov rax, 0x18E50D910237940B
    sub al, -12
    mov rbp, 0xFFFFFFFF80000000
    mov rcx, 0x0
    FLAGS 0xA43
    mov rax, 0xFFFFFFFFFFFFFFFF
    sub al, -1
    mov r10, 0xF33650A8B70D025F
    mov r12, 0x2
    mov rdx, 0xDDD17A834AA8820D
    mov rax, 0x8000
    sub dh, al
    sub dl, ah
    mov rdx, 0xFFFFFFFFFFFFFF02
    mov rbx, 0xFE215C90C2385A76
    mov rcx, 0xFAC64449376E0259
    mov rax, 0xE81C89FD7C3E913C
    sub ch, al
    sub cl, ah
    mov rsi, 0x100
    mov r14, 0x1
    FLAGS 0xA02
    mov rdx, 0xFFFFFFFFFFFFFFE5
    mov rcx, 0x80
    sub dh, cl
    sub dl, ch
    mov r12, 0xBC
    mov r9, 0x5CFD43E1F1D8A1DB
    sub r12w, r9w
    mov rsi, 0x28BC86DC18E3FF69
    mov r13, 0xFFFFFFFF80000000
    FLAGS 0xA82
    sub si, r13w
    mov rdx, 0x0
    mov r14, 0xFFFF
    sub dx, r14w
    mov r9, 0xE1
    mov rdi, 0xFFFFFFFF
    sub r9w, 5627
    mov rax, 0xD37401ECD89D03E4
    mov r9, 0xFFFFFFFFFFFFFFFF
    FLAGS 0x246
    sub ax, 3067
    mov rbx, 0x100
    mov rdx, 0xFDA9EC865A1E96A2
    FLAGS 0xA02
    sub bx, 26498
    mov rdi, 0x7F
    mov rbx, 0x3
    FLAGS 0x213
    mov [buf + 8], rbx
    sub di, [buf + 8]
    mov rbx, 0xFFFF
    mov rbp, 0x3A
    mov [buf + 8], rbp
    sub bx, [buf + 8]
    mov r15, 0x8000
    mov rax, 0xD91AAA2227E57C5E
    mov [buf + 8], rax
    sub r15w, [buf + 8]
    mov rdi, 0x2
    mov r14, 0x80000000
    FLAGS 0xAD7
    mov [buf + 16], rdi
    sub [buf + 16], r14w
    mov rdi, [buf + 16]
    mov rbp, 0x909813515F16BE3F
    mov r8, 0x80D8310AA7319AA3
    mov [buf + 16], rbp
    sub [buf + 16], r8w
    mov rbp, [buf + 16]
    mov rbp, 0xFFFFFFFFFFFFFFDB
    mov rdi, 0x1
    FLAGS 0x213
    mov [buf + 16], rbp
    sub [buf + 16], di
    mov rbp, [buf + 16]
    mov rbx, 0xFFFFFFFF
    mov r13, 0x9C7194B14B7EF5A2
    mov [buf + 24], rbx
    sub word [buf + 24], 28190
    mov r13, [buf + 24]
    mov rdx, 0x9FE9EAF00735D3E
    mov r8, 0x3
    mov [buf + 24], rdx
    sub word [buf + 24], -128
    mov r8, [buf + 24]
    mov rbx, 0xFFFFFFFF
    mov r9, 0x39A6EB2DDC11CC71
    FLAGS 0xA43
    mov [buf + 24], rbx
    sub word [buf + 24], -128
    mov r9, [buf + 24]
    mov r13, 0xFFFF
    mov r15, 0x100000000
    mov rax, 0x80000000
    sub ax, -12868
    mov rdi, 0x9854C01C3C8D5EAB
    mov rbp, 0x84A57DFF49897B0E
    mov rax, 0x98E93D362B421CDE
    sub ax, 5920
    mov r15, 0x180EEB1957F55CF5
    mov r8, 0xE4AC8897DF59CFCA
    mov rax, 0xFFFFFFFFFFFFFF80
    sub ax, 127
    mov rbp, 0xFFFFFFFFFFFFFFFF
    mov rsi, 0x2
    FLAGS 0x213
    sub bp, bp
    mov rsi, 0x8638B863A1268484
    mov r11, 0x2B21CB0A4238A8AB
    sub si, si
    mov rsi, 0x2A8EE7E5EFCDBF4A
    mov r15, 0x3
    sub si, si
    mov rcx, 0xFFFFFFFFFFFFFFCE
    mov rax, 0x2F0658261F54CD52
    sub ecx, eax
    mov rax, 0x6C751596B7D14230
    mov rsi, 0x7FFFFFFFFFFFFFFF
    sub eax, esi
    mov rcx, 0xB7B7204EEFAA1361
    mov r12, 0xCAD2367AD66F5879
    sub ecx, r12d
    mov rsi, 0xFFFFFFFFFFFFFF80
    mov rbx, 0xA4C758E0A1FD5070
    sub esi, 2147483647
    mov r12, 0x708DD78CB9644BAC
    mov rdx, 0xBAF4C4EC2A4311E7
    FLAGS 0x297
    sub r12d, 0
    mov r15, 0x8855C459503566BF
    mov r14, 0xFFFFFFFFFFFFFF80
    sub r15d, 1
    mov rbx, 0x1
    mov rax, 0x25
    mov [buf + 8], rax
    sub ebx, [buf + 8]
    mov rcx, 0x100
    mov r10, 0xFFFFFFFFFFFFFF08
    mov [buf + 8], r10
    sub ecx, [buf + 8]
    mov r15, 0x1215FCB307BBB9DB
    mov rsi, 0x2D
    mov [buf + 8], rsi
    sub r15d, [buf + 8]
    mov rax, 0xFFFFFFFFFFFFFF7D
    mov r13, 0xFFFFFFFFFFFFFFFF
    mov [buf + 16], rax
    sub [buf + 16], r13d
    mov rax, [buf + 16]
    mov rbp, 0xCF622B9CA6E5D482
    mov r11, 0x842779CBA6EC9883
    mov [buf + 16], rbp
    sub [buf + 16], r11d
    mov rbp, [buf + 16]
    mov rax, 0xFFFFFFFF
    mov r8, 0x7FFFFFFFFFFFFFFF
    mov [buf + 16], rax
    sub [buf + 16], r8d
    mov rax, [buf + 16]
    mov r12, 0x8000
    mov rdx, 0x80000000
    mov [buf + 24], r12
    sub dword [buf + 24], -128
    mov rdx, [buf + 24]
    mov rsi, 0x1
    mov rdi, 0x80
    mov [buf + 24], rsi
    sub dword [buf + 24], -2147483648
    mov rdi, [buf + 24]
    mov r14, 0x6878DC43062613EB
    mov r13, 0x7FFFFFFF
    mov [buf + 24], r14
    sub dword [buf + 24], -2147483648
    mov r13, [buf + 24]
    mov r13, 0xB06F40FCB949CE50
    mov rsi, 0x100
    FLAGS 0x203
    mov rax, 0xFFFFFFFF80000000
    sub eax, -2147483648
    mov r11, 0xFFFFFFFF
    mov rbx, 0xFFFFFFFFFFFFFF11
    mov rax, 0x80
    sub eax, 960972079
    mov r12, 0xFFFFFFFFFFFFFFAA
    mov rdi, 0x8000
    mov rax, 0x7FFFFFFF
    sub eax, -2147483648
    mov r14, 0xFFFFFFFF
    mov r15, 0x100
    FLAGS 0xA43
    sub r14d, r14d
    mov r11, 0xF4C4A0E371269067
    mov r14, 0x3
    sub r11d, r11d
    mov rcx, 0x100000000
    mov r8, 0x93825B546BA73B46
    sub ecx, ecx
    mov r9, 0xAD58BF87AE0BD0E5
    mov rax, 0xCFC477A6BA954C0E
    sub r9, rax
    mov r15, 0x3
    mov rdx, 0xB00814143E9584BD
    sub r15, rdx
    mov r13, 0x80000000
    mov r8, 0x3C
    sub r13, r8
    mov rcx, 0xB8365210CA02E338
    mov rax, 0xFFFFFFFFFFFFFFC5
    sub rcx, 0
    mov r12, 0xFFFFFFFFFFFFFF82
    mov r10, 0x80000000
    FLAGS 0xA02
    sub r12, 5
    mov r12, 0xFFFFFFFFFFFFFF80
    mov r14, 0x19
    sub r12, -2147483648
    mov rbp, 0xFFFFFFFFFFFFFFE3
    mov rdi, 0xAEE91CDAC0B848C3
    mov [buf + 8], rdi
    sub rbp, [buf + 8]
    mov r8, 0x8000000000000000
    mov rbp, 0xEA8964992BA8758C
    FLAGS 0x213
    mov [buf + 8], rbp
    sub r8, [buf + 8]
    mov r9, 0xA5CF2DF3D08B982C
    mov rbx, 0x100
    mov [buf + 8], rbx
    sub r9, [buf + 8]
    mov r11, 0x2655CF1A738D80B9
    mov rbp, 0x81
    mov [buf + 16], r11
    sub [buf + 16], rbp
    mov r11, [buf + 16]
    mov rdi, 0xFF
    mov r10, 0x7F
    mov [buf + 16], rdi
    sub [buf + 16], r10
    mov rdi, [buf + 16]
    mov r15, 0x7FFFFFFF
    mov r14, 0x7F
    FLAGS 0xAD7
    mov [buf + 16], r15
    sub [buf + 16], r14
    mov r15, [buf + 16]
    mov rax, 0x1C
    mov rdi, 0xFC918A04C7790030
    mov [buf + 24], rax
    sub qword [buf + 24], 1
    mov rdi, [buf + 24]
    mov r12, 0x3
    mov r13, 0xFFFFFFFFFFFFFF19
    mov [buf + 24], r12
    sub qword [buf + 24], -2147483648
    mov r13, [buf + 24]
    mov rbp, 0x736177C796A98C4A
    mov r12, 0x3
    mov [buf + 24], rbp
    sub qword [buf + 24], -128
    mov r12, [buf + 24]
    mov r13, 0x4992440D170BA0E7
    mov rsi, 0x80
    FLAGS 0x212
    mov rax, 0x4FE247B51DB6A813
    sub rax, 2147483647
    mov r10, 0xED4EB147A87B769A
    mov rax, 0x2FBBC76BA83E3CBE
    FLAGS 0xA02
    mov rax, 0xB3
    sub rax, 2147483647
    mov rax, 0xEB04EDA643CB7A51
    mov r10, 0x80000000
    mov rax, 0xAE4016916E83F460
    sub rax, -2147483648
    mov r8, 0xF4
    mov rbp, 0x59753F78FF4298D1
    FLAGS 0x297
    sub r8, r8
    mov r14, 0xFFFFFFFFFFFFFF18
    mov rbp, 0x0
    sub r14, r14
    mov rdx, 0x1
    mov r11, 0x80
    FLAGS 0xAD7
    sub rdx, rdx
    mov rbx, 0xFFFFFFFFFFFFFFB7
    mov r10, 0x0
    xor bl, r10b
    mov rax, 0xFFFF
    mov rbp, 0x7FFFFFFF
    FLAGS 0x246
    xor al, bpl
    mov r11, 0xFFFFFFFFFFFFFF7F
    mov r12, 0x2EDE93BA13C40B36
    xor r11b, r12b
    mov rax, 0x7FFFFFFFFFFFFFFF
    mov r10, 0x3
    xor al, 127
    mov r15, 0x23D5577E6370C7C1
    mov r10, 0xFFFFFFFFFFFFFFB6
    xor r15b, 122
    mov r15, 0x81
    mov r11, 0xFFFFFFFFFFFFFFC3
    xor r15b, 109
    mov rbp, 0xFFFFFFFF
    mov r10, 0x30
    mov [buf + 8], r10
    xor bpl, [buf + 8]
    mov r15, 0xFFFFFFFFFFFFFF80
    mov r8, 0x7FFFFFFFFFFFFFFF
    FLAGS 0xA82
    mov [buf + 8], r8
    xor r15b, [buf + 8]
    mov rdx, 0x8000
    mov rcx, 0xF29C9042762F7DB5
    mov [buf + 8], rcx
    xor dl, [buf + 8]
    mov rcx, 0x79259DCCEE8352BB
    mov rdx, 0x1F70DA6D42113ECC
    mov [buf + 16], rcx
    xor [buf + 16], dl
    mov rcx, [buf + 16]
    mov r11, 0x0
    mov rdi, 0x963CA77C823A2946
    mov [buf + 16], r11
    xor [buf + 16], dil
    mov r11, [buf + 16]
    mov r14, 0x1FB914F6900D96C9
    mov r12, 0x2
    mov [buf + 16], r14
    xor [buf + 16], r12b
    mov r14, [buf + 16]
    mov r11, 0x7FFFFFFFFFFFFFFF
    mov rbx, 0xB682CE7B540F4CBC
    mov [buf + 24], r11
    xor byte [buf + 24], 5
    mov rbx, [buf + 24]
    mov rbx, 0x7F
    mov rbp, 0x33E473E691128329
    mov [buf + 24], rbx
    xor byte [buf + 24], 47
    mov rbp, [buf + 24]
    mov r13, 0xD23298FFA3D2A335
    mov r9, 0x80000000
    mov [buf + 24], r13
    xor byte [buf + 24], -95
    mov r9, [buf + 24]
    mov rcx, 0xFFFFFFFFFFFFFFD5
    mov r14, 0xCFD57F4CB46D9054
    mov rax, 0x5B490792D0698C65
    xor al, 34
    mov r15, 0xFFFF
    mov r14, 0xFFFFFFFFFFFFFFD6
    mov rax, 0x74F77985AA015396
    xor al, -128
    mov rcx, 0x70846ED69E763FC4
    mov r9, 0xDEC9A07BB4F5263E
    FLAGS 0xA02
    mov rax, 0xFFFFFFFFFFFFFFFF
    xor al, 5
    mov r9, 0xF2240D164F9D139F
    mov r10, 0xFFFFFFFFFFFFFF64
    mov rdx, 0x429EDED253DC9C3D
    mov rax, 0x3
    xor dh, al
    xor dl, ah
    mov rcx, 0x67
    mov r13, 0xEEC931915E8DFE29
    FLAGS 0x297
    mov rdx, 0x7FFF
    mov rbx, 0xD380DF87085E9FA2
    xor dh, bl
    xor dl, bh
    mov rsi, 0x6DA9B86A8B7F8493
    mov rdx, 0x52
    mov rcx, 0x8C264CD8DE443755
    mov rax, 0x100000000
    xor ch, al
    xor cl, ah
    mov r10, 0x7300AB6BCE358226
    mov rsi, 0xB9F118F4B16E1BA8
    FLAGS 0x202
    xor r10w, si
    mov r13, 0x9B0B8B0C864DD1BF
    mov rbp, 0x7BAEE0AFB0231B12
    xor r13w, bp
    mov r15, 0xC6C358867D2B6305
    mov r10, 0x79E1F0AFA0BACCE9
    FLAGS 0xA43
    xor r15w, r10w
    mov r14, 0xEF8B5481303CBF1A
    mov rbp, 0xAC02EE137E23FF19
    xor r14w, 0
    mov rsi, 0x8000000000000000
    mov r14, 0x0
    FLAGS 0x246
    xor si, 7155
    mov rsi, 0xFFFFFFFFFFFFFF53
    mov r14, 0x10000
    xor si, -30849
    mov rsi, 0x80
    mov r9, 0x88AEF3032F143719
    FLAGS 0x2D6
    mov [buf + 8], r9
    xor si, [buf + 8]
    mov rdi, 0x548959C9A0B9B63A
    mov rax, 0xD9E93773BA237ABB
    mov [buf + 8], rax
    xor di, [buf + 8]
    mov rsi, 0xFFFF
    mov rbp, 0xBE8DE1B13CBE2A9
    mov [buf + 8], rbp
    xor si, [buf + 8]
    mov r10, 0xF08D24E9BEF8F2B8
    mov r14, 0x67A35E870498F92
    mov [buf + 16], r10
    xor [buf + 16], r14w
    mov r10, [buf + 16]
    mov r10, 0x12EF671EDD5028FF
    mov r8, 0x2
    mov [buf + 16], r10
    xor [buf + 16], r8w
    mov r10, [buf + 16]
    mov r8, 0x5B1029562E6216A9
    mov rdx, 0x5426C3C72CABB3F2
    FLAGS 0xAD7
    mov [buf + 16], r8
    xor [buf + 16], dx
    mov r8, [buf + 16]
    mov r10, 0x2A
    mov r12, 0xFFFF
    FLAGS 0xA02
    mov [buf + 24], r10
    xor word [buf + 24], -24908
    mov r12, [buf + 24]
    mov r11, 0xFFFF
    mov r14, 0x2
    mov [buf + 24], r11
    xor word [buf + 24], 29049
    mov r14, [buf + 24]
    mov rdx, 0xDE560561CAC2A8F0
    mov rax, 0x71A21BE4CF486072
    mov [buf + 24], rdx
    xor word [buf + 24], 21858
    mov rax, [buf + 24]
    mov r14, 0x80
    mov rsi, 0xF039EE4EBD014498
    FLAGS 0x2D6
    mov rax, 0xFFFFFFFFFFFFFF80
    xor ax, -128
    mov r12, 0xB9
    mov r9, 0xAC4E886534206070
    FLAGS 0x246
    mov rax, 0xFFFFFFFFFFFFFFFF
    xor ax, 12055
    mov rax, 0x4CC9F7BD1F49A0B
    mov rcx, 0xE23138BDED568775
    mov rax, 0x11FA035BFF951C21
    xor ax, 23465
    mov rdx, 0x12B50323E54C55A8
    mov rdi, 0x84F4A2B07E417ADD
    FLAGS 0x212
    xor dx, dx
    mov r14, 0x71605473334B2BDB
    mov rax, 0x3
    xor r14w, r14w
    mov rsi, 0x7FFFFFFF
    mov rdx, 0xFFFF
    xor si, si
    mov rdi, 0xD6899B5291D5F484
    mov r12, 0x80000000
    FLAGS 0xA43
    xor edi, r12d
    mov r10, 0x7F
    mov r12, 0x7FFFFFFFFFFFFFFF
    xor r10d, r12d
    mov r8, 0xFFFFFFFF80000000
    mov rdx, 0xA6C1194B967F52CE
    xor r8d, edx
    mov rdx, 0x74216FE0DB1E3375
    mov rdi, 0xFFFFFFFFFFFFFF80
    xor edx, -1
    mov rbp, 0x81
    mov rdx, 0xBC01E5436A2AC94C
    xor ebp, 254924470
    mov rdi, 0x9D406DDFF95ED46F
    mov r10, 0x40365EF4B9E2E368
    xor edi, -1
    mov r12, 0x8C7067ADED6B213C
    mov r8, 0x81
    mov [buf + 8], r8
    xor r12d, [buf + 8]
    mov r9, 0x80000000
    mov rdi, 0xFFFFFFFFFFFFFFFF
    FLAGS 0xA03
    mov [buf + 8], rdi
    xor r9d, [buf + 8]
    mov rdx, 0x817CF9F2E2AC4A45
    mov r12, 0x8000
    mov [buf + 8], r12
    xor edx, [buf + 8]
    mov rdi, 0x7F
    mov rax, 0x7A7972443CB59BDE
    mov [buf + 16], rdi
    xor [buf + 16], eax
    mov rdi, [buf + 16]
    mov rbp, 0x48B1D8183805327E
    mov r8, 0xFFFFFFFFFFFFFF5B
    mov [buf + 16], rbp
    xor [buf + 16], r8d
    mov rbp, [buf + 16]
    mov r13, 0xDE85A27DEDF70035
    mov r8, 0xFFFFFFFFFFFFFFFF
    FLAGS 0xAD7
    mov [buf + 16], r13
    xor [buf + 16], r8d
    mov r13, [buf + 16]
    mov rdx, 0x4C370FAD5A3C5FBA
    mov r14, 0x80000000
    mov [buf + 24], rdx
    xor dword [buf + 24], -128
    mov r14, [buf + 24]
    mov rax, 0x80000000
    mov rsi, 0x2
    mov [buf + 24], rax
    xor dword [buf + 24], -1
    mov rsi, [buf + 24]
    mov rbp, 0x8CBB2C2381D6B120
    mov r13, 0xAF07D88906787E5C
    mov [buf + 24], rbp
    xor dword [buf + 24], -2147483648
    mov r13, [buf + 24]
    mov rsi, 0xFFFFFFFF80000000
    mov r11, 0xFFFFFFFFFFFFFF95
    mov rax, 0x9DB47001B797119E
    xor eax, 430267310
    mov rcx, 0x91
    mov r15, 0xFFFFFFFFFFFFFF94
    mov rax, 0x75
    xor eax, -2147483648
    mov rbp, 0x2
    mov r12, 0x7F
    mov rax, 0xFFFFFFFFFFFFFF97
    xor eax, 127
    mov rax, 0xA06AB936C69D0B07
    mov rbx, 0xFFFF
    xor eax, eax
    mov r11, 0x67
    mov r15, 0xEDAA3FFF671A48A3
    FLAGS 0x212
    xor r11d, r11d
    mov rsi, 0xEF8FCE527CAEECF5
    mov rax, 0xFFFFFFFFFFFFFFFF
    xor esi, esi
    mov r13, 0x9B188240ECB2CE17
    mov rbx, 0xCF7E0A0CDEB9470D
    xor r13, rbx
    mov rax, 0x94B600C276E3D709
    mov rdx, 0x6B83B0DA7E170D53
    xor rax, rdx
    mov rbp, 0x493872B53E500507
    mov r11, 0x2E8215B09046F574
    FLAGS 0xA82
    xor rbp, r11
    mov rbx, 0x2
    mov rax, 0x9708C26F6FAD5177
    xor rbx, -128
    mov r12, 0x889868228752E41B
    mov r15, 0xFF
    xor r12, 5
    mov rbp, 0xFFFFFFFFFFFFFFFF
    mov rdi, 0x802A6314A0B0D4D0
    xor rbp, 1
    mov rdi, 0xFFFFFFFFFFFFFF80
    mov rcx, 0x37609DFC51D78BFD
    mov [buf + 8], rcx
    xor rdi, [buf + 8]
    mov r10, 0xAD0D3172DB6319E4
    mov r11, 0x1
    mov [buf + 8], r11
    xor r10, [buf + 8]
    mov rdi, 0xFFFFFFFFFFFFFF31
    mov r8, 0x80000000
    mov [buf + 8], r8
    xor rdi, [buf + 8]
    mov rbx, 0x8000
    mov r9, 0xD2AE20E1583E0F82
    FLAGS 0xA02
    mov [buf + 16], rbx
    xor [buf + 16], r9
    mov rbx, [buf + 16]
    mov r12, 0x1E1DB7887A04E0E8
    mov rbx, 0x7FFF
    mov [buf + 16], r12
    xor [buf + 16], rbx
    mov r12, [buf + 16]
    mov r14, 0x8000
    mov rdx, 0x7FFFFFFF
    mov [buf + 16], r14
    xor [buf + 16], rdx
    mov r14, [buf + 16]
    mov rdx, 0x1
    mov r13, 0xFFFFFFFFFFFFFFD8
    mov [buf + 24], rdx
    xor qword [buf + 24], -2147483648
    mov r13, [buf + 24]
    mov rcx, 0x36B856A51467923C
    mov r15, 0x8E5DE2F2002E6A8D
    FLAGS 0x213
    mov [buf + 24], rcx
    xor qword [buf + 24], -1903347461
    mov r15, [buf + 24]
    mov r15, 0x100
    mov r13, 0x93
    mov [buf + 24], r15
    xor qword [buf + 24], 1
    mov r13, [buf + 24]
    mov r11, 0x115ADF6CC07B43F5
    mov rax, 0x5804AF82D7BC76D5
    mov rax, 0x81
    xor rax, 5
    mov r9, 0x2A7311A52386435
    mov r11, 0x55
    FLAGS 0xA82
    mov rax, 0x1035CBFCBA50B670
    xor rax, 2147483647
    mov rcx, 0x2
    mov r15, 0x7F
    FLAGS 0xA82
    mov rax, 0xFFFFFFFFFFFFFF92
    xor rax, 2147483647
    mov r9, 0x3AB38ECEFD25B4CC
    mov r12, 0x6A24AE6E9C475966
    FLAGS 0xA02
    xor r9, r9
    mov rcx, 0x8000000000000000
    mov rbp, 0x8000
    xor rcx, rcx
    mov rcx, 0x80000000
    mov r12, 0x3
    FLAGS 0xA03
    xor rcx, rcx
    mov rax, 0xFFFFFFFFFFFFFF80
    mov r13, 0xFFFFFFFF
    cmp al, r13b
    mov r13, 0xDD58777426B375F8
    mov rsi, 0x81
    cmp r13b, sil
    mov rcx, 0xB00ECBEC39D42797
    mov rbp, 0x5E05C91305E263D9
    FLAGS 0xA82
    cmp cl, bpl
    mov rbx, 0xAFE3DD7C8DBF6F04
    mov r8, 0xFFFFFFFF
    FLAGS 0x202
    cmp bl, -77
    mov r11, 0x8000
    mov rsi, 0xBD
    cmp r11b, 37
    mov rbp, 0x7FFF
    mov r14, 0xFFFFFFFF80000000
    FLAGS 0x202
    cmp bpl, 31
    mov r15, 0xA2D94E137E836151
    mov r8, 0x8000000000000000
    mov [buf + 8], r8
    cmp r15b, [buf + 8]
    mov rsi, 0xFFFFFFFFFFFFFFF9
    mov r14, 0x32
    mov [buf + 8], r14
    cmp sil, [buf + 8]
    mov r15, 0x59
    mov rbp, 0xA2E9DCB1B6643A08
    mov [buf + 8], rbp
    cmp r15b, [buf + 8]
    mov rdi, 0xF5AFECEA81235491
    mov rax, 0x29AA3323363FFF9B
    mov [buf + 16], rdi
    cmp [buf + 16], al
    mov rdi, [buf + 16]
    mov rbx, 0x100000000
    mov r11, 0xFFFFFFFFFFFFFFF8
    mov [buf + 16], rbx
    cmp [buf + 16], r11b
    mov rbx, [buf + 16]
    mov rcx, 0x100
    mov r8, 0x81
    FLAGS 0xA03
    mov [buf + 16], rcx
    cmp [buf + 16], r8b
    mov rcx, [buf + 16]
    mov rax, 0x7F
    mov rsi, 0x80
    FLAGS 0xAD7
    mov [buf + 24], rax
    cmp byte [buf + 24], 127
    mov rsi, [buf + 24]
    mov r12, 0xE07ACA2692D6B305
    mov r10, 0x8000000000000000
    mov [buf + 24], r12
    cmp byte [buf + 24], 1
    mov r10, [buf + 24]
    mov r11, 0xDA084A180ED5F2C5
    mov rdx, 0x7FFFFFFF
    mov [buf + 24], r11
    cmp byte [buf + 24], -99
    mov rdx, [buf + 24]
    mov rsi, 0x2C88BD638F5B30D8
    mov r15, 0xFFFFFFFFFFFFFF13
    FLAGS 0x213
    mov rax, 0x424FDB780CC988DD
    cmp al, -66
    mov r12, 0x2
    mov r9, 0x2258001C0FE9D1ED
    mov rax, 0x6454D4F51AB3E43F
    cmp al, 49
    mov r10, 0x8917EC072A9BDBF1
    mov r9, 0xFFFFFFFFFFFFFFFF
    mov rax, 0x7F
    cmp al, -14
    mov rdx, 0x80
    mov rdi, 0x3C
    mov rcx, 0x100000000
    mov rdx, 0x41A7853AEE42AF79
    cmp ch, dl
    cmp cl, dh
    mov r8, 0xFFFFFFFF80000000
    mov r11, 0x10000
    mov rax, 0x61BCF04318BF9853
    mov rdx, 0x3B79B7470623FAC3
    cmp ah, dl
    cmp al, dh
    mov r14, 0xFFFFFFFF
    mov rsi, 0xFFFFFFFFFFFFFF80
    mov rdx, 0x9A559FD3AFCE50F0
    mov rax, 0xFFFFFFFFFFFFFF1A
    cmp dh, al
    cmp dl, ah
    mov r13, 0xFFFFFFFF80000000
    mov r14, 0xFFFFFFFFFFFFFF7B
    FLAGS 0x212
    cmp r13w, r14w
    mov r9, 0x80000000
    mov rbp, 0x3
    cmp r9w, bp
    mov r15, 0x7F874C861205CEF9
    mov rdx, 0x1F
    cmp r15w, dx
    mov rax, 0xDE8BF8AABFB59EBD
    mov r13, 0x3
    cmp ax, 127
    mov rbx, 0x88D4609A5140E6BB
    mov rdx, 0x48D4B9C1643B3E0A
    cmp bx, -128
    mov rdx, 0x100000000
    mov rax, 0x8A9765CE1DC999F1
    cmp dx, 887
    mov r10, 0x7FFFFFFF
    mov r15, 0xC44F6B8469CF9629
    mov [buf + 8], r15
    cmp r10w, [buf + 8]
    mov r10, 0x1AEDA7529B8F334E
    mov r8, 0xFC50B37B0CCE7747
    mov [buf + 8], r8
    cmp r10w, [buf + 8]
    mov r8, 0x24D933CDFE63D66F
    mov rsi, 0xC17E8E838F1BD298
    mov [buf + 8], rsi
    cmp r8w, [buf + 8]
    mov rax, 0x80000000
    mov rdx, 0x48AFB10CA8A7217E
    FLAGS 0xA03
    mov [buf + 16], rax
    cmp [buf + 16], dx
    mov rax, [buf + 16]
    mov r13, 0xF74186435ED1502F
    mov r15, 0xFFFFFFFF80000000
    mov [buf + 16], r13
    cmp [buf + 16], r15w
    mov r13, [buf + 16]
    mov rcx, 0x5851D26B153ACF2
    mov rdx, 0xFFFFFFFF80000000
    FLAGS 0xA02
    mov [buf + 16], rcx
    cmp [buf + 16], dx
    mov rcx, [buf + 16]
    mov r14, 0x10000
    mov r10, 0x7FFF
    FLAGS 0x212
    mov [buf + 24], r14
    cmp word [buf + 24], 1
    mov r10, [buf + 24]
    mov rdi, 0xFFFFFFFF
    mov r13, 0x7FFFFFFF
    FLAGS 0x213
    mov [buf + 24], rdi
    cmp word [buf + 24], 6765
    mov r13, [buf + 24]
    mov r10, 0xC0
    mov rdx, 0xFFFFFFFFFFFFFFF9
    mov [buf + 24], r10
    cmp word [buf + 24], 2922
    mov rdx, [buf + 24]
    mov rax, 0x20
    mov rdi, 0x100000000
    mov rax, 0xFFFFFFFFFFFFFFFF
    cmp ax, -30286
    mov r13, 0xFFFFFFFFFFFFFFE3
    mov rsi, 0xD72AD502AA70526
    mov rax, 0xCABC1B951A522251
    cmp ax, 25048
    mov r8, 0xFFFFFFFF80000000
    mov r10, 0x12D277B9CDD2F335
    mov rax, 0x8000
    cmp ax, -11088
    mov rax, 0x10000
    mov r15, 0x7FFFFFFFFFFFFFFF
    cmp ax, ax
    mov rsi, 0x53DC85FF38459537
    mov rbp, 0x80
    cmp si, si
    mov r9, 0x100
    mov r11, 0x8DAA4031731824F0
    FLAGS 0x212
    cmp r9w, r9w
    mov r13, 0x3
    mov rbp, 0xC9B344BBA89E9705
    cmp r13d, ebp
    mov rdx, 0xEA5C99017B62C8CC
    mov rbx, 0x7F
    FLAGS 0xAD7
    cmp edx, ebx
    mov rdx, 0x5357B7E08C08303E
    mov r14, 0x80000000
    cmp edx, r14d
    mov rcx, 0x48418AEB5D3FD5AB
    mov r10, 0xD31168DF6F9AB298
    FLAGS 0xA03
    cmp ecx, -128
    mov r8, 0x2561BBA7CF39770B
    mov rbx, 0x2
    FLAGS 0xA03
    cmp r8d, 0
    mov rbx, 0x11D7B3296405C178
    mov rdx, 0x8000
    cmp ebx, 0
    mov r12, 0xFFFFFFFFFFFFFF80
    mov rax, 0x7FFFFFFFFFFFFFFF
    mov [buf + 8], rax
    cmp r12d, [buf + 8]
    mov rsi, 0xFFFFFFFFFFFFFF1A
    mov rcx, 0xDB45FB2CC3076176
    mov [buf + 8], rcx
    cmp esi, [buf + 8]
    mov rbx, 0x8000000000000000
    mov rbp, 0x49C44486C35F75D
    FLAGS 0x297
    mov [buf + 8], rbp
    cmp ebx, [buf + 8]
    mov rdx, 0xDC6388F27AC6CC72
    mov rax, 0xFFFFFFFFFFFFFF80
    mov [buf + 16], rdx
    cmp [buf + 16], eax
    mov rdx, [buf + 16]
    mov rdi, 0xFFFF
    mov r14, 0x43AA4F6218632A4F
    FLAGS 0xAD7
    mov [buf + 16], rdi
    cmp [buf + 16], r14d
    mov rdi, [buf + 16]
    mov r10, 0x0
    mov r11, 0x8000
    mov [buf + 16], r10
    cmp [buf + 16], r11d
    mov r10, [buf + 16]
    mov rbx, 0x0
    mov rcx, 0xFFFFFFFF
    mov [buf + 24], rbx
    cmp dword [buf + 24], -2147483648
    mov rcx, [buf + 24]
    mov r14, 0x0
    mov rax, 0x49AA69C10A63AA76
    mov [buf + 24], r14
    cmp dword [buf + 24], 2147483647
    mov rax, [buf + 24]
    mov r8, 0xFFFFFFFF80000000
    mov r10, 0x100
    FLAGS 0x203
    mov [buf + 24], r8
    cmp dword [buf + 24], -2147483648
    mov r10, [buf + 24]
    mov r11, 0x1
    mov rsi, 0xFFFFFFFFFFFFFF80
    mov rax, 0xFFFFFFFFFFFFFF67
    cmp eax, -2147483648
    mov r13, 0x80000000
    mov rdi, 0x3
    FLAGS 0xA43
    mov rax, 0x2
    cmp eax, -931197543
    mov r9, 0xC57401F6AC706CA2
    mov rax, 0x7B14CA298852DE8D
    FLAGS 0x212
    mov rax, 0x80
    cmp eax, -128
    mov rbp, 0xA8AA5E5C02018CDE
    mov rax, 0xFF
    FLAGS 0xA03
    cmp ebp, ebp
    mov r11, 0x81
    mov r12, 0xFFFFFFFFFFFFFF6A
    cmp r11d, r11d
    mov r8, 0xFFFFFFFF80000000
    mov r14, 0x1
    FLAGS 0xA03
    cmp r8d, r8d
    mov rax, 0x57BDADB6743914A6
    mov rbx, 0xFBF528D747772B35
    FLAGS 0x2D6
    cmp rax, rbx
    mov r9, 0xFFFFFFFF
    mov r10, 0x27840DBCF0A474DE
    cmp r9, r10
    mov rsi, 0xE1
    mov r13, 0x8AE45BF838D3FA83
    FLAGS 0xA82
    cmp rsi, r13
    mov rbp, 0x2
    mov r11, 0x3690364D3230FC57
    FLAGS 0xA03
    cmp rbp, 5
    mov r11, 0xFF
    mov r10, 0xE
    FLAGS 0x202
    cmp r11, 2147483647
    mov rdx, 0x2E159C11BCCDBDC4
    mov r13, 0xEC090F3E7193ACC8
    cmp rdx, -2147483648
    mov r12, 0x7F
    mov r10, 0x3
    FLAGS 0x213
    mov [buf + 8], r10
    cmp r12, [buf + 8]
    mov r13, 0x38735F7C9052FB73
    mov rdi, 0x10000
    mov [buf + 8], rdi
    cmp r13, [buf + 8]
    mov rbp, 0x816507061F4ECFBF
    mov rcx, 0xFFFFFFFFFFFFFFC1
    mov [buf + 8], rcx
    cmp rbp, [buf + 8]
    mov r11, 0xFFFF
    mov r15, 0x2
    mov [buf + 16], r11
    cmp [buf + 16], r15
    mov r11, [buf + 16]
    mov r10, 0xFF
    mov rsi, 0x7FFFFFFF
    FLAGS 0x203
    mov [buf + 16], r10
    cmp [buf + 16], rsi
    mov r10, [buf + 16]
    mov rax, 0xFFFF
    mov r12, 0x8000000000000000
    mov [buf + 16], rax
    cmp [buf + 16], r12
    mov rax, [buf + 16]
    mov r11, 0xEFEFCCA4BD2EC6B8
    mov rcx, 0x52C077A38696FC43
    mov [buf + 24], r11
    cmp qword [buf + 24], -2147483648
    mov rcx, [buf + 24]
    mov rdi, 0x8000000000000000
    mov rcx, 0xFF
    FLAGS 0xA02
    mov [buf + 24], rdi
    cmp qword [buf + 24], -128
    mov rcx, [buf + 24]
    mov rbp, 0xFFFFFFFFFFFFFFFF
    mov rbx, 0x7FFF
    mov [buf + 24], rbp
    cmp qword [buf + 24], 127
    mov rbx, [buf + 24]
    mov rsi, 0x81
    mov r9, 0xFFFFFFFFFFFFFFBE
    mov rax, 0x7F
    cmp rax, 1053211588
    mov rcx, 0x8000000000000000
    mov r8, 0xFFFFFFFF
    mov rax, 0xFFFFFFFFFFFFFF06
    cmp rax, -1
    mov r14, 0xCA238BA8A79EE08B
    mov rcx, 0x0
    mov rax, 0x0
    cmp rax, -128
    mov r14, 0x1C4BE09DE82A69FB
    mov r10, 0x12998BF4737DD733
    cmp r14, r14
    mov r10, 0x5DA728C5DC2F2A0C
    mov r12, 0xBB5C5A0A1F0AE152
    FLAGS 0x203
    cmp r10, r10
    mov rcx, 0xFFFFFFFFFFFFFF40
    mov r8, 0x1816A4AD4DFE33E
    FLAGS 0xA82
    cmp rcx, rcx
    mov rsi, 0x2
    mov r13, 0xFFFFFFFF80000000
    FLAGS 0x297
    test sil, r13b
    mov r9, 0x2
    mov rax, 0x58961A4901BDDBC2
    FLAGS 0x246
    test r9b, al
    mov rbp, 0xD8DBABFB112FA902
    mov r8, 0x80
    FLAGS 0x297
    test bpl, r8b
    mov r11, 0x7F17AA04A0522C86
    mov rdi, 0x782164D7F1E623C1
    test r11b, 124
    mov rdx, 0xFFFF
    mov rdi, 0x100
    test dl, -84
    mov r13, 0x496F51D60ED8B32F
    mov r15, 0x3
    FLAGS 0x212
    test r13b, 61
    mov r14, 0x7FFFFFFFFFFFFFFF
    mov r15, 0x9435975DF02BF4D5
    mov [buf + 8], r15
    test [buf + 8], r14b
    mov rdx, 0xFC0AC88C49CC7076
    mov rbx, 0xE02796CDC968938C
    mov [buf + 8], rbx
    test [buf + 8], dl
    mov r10, 0x100000000
    mov r13, 0xBD4E4D30FBC67E57
    mov [buf + 8], r13
    test [buf + 8], r10b
    mov rax, 0x7F
    mov r15, 0x80000000
    mov [buf + 16], rax
    test [buf + 16], r15b
    mov rax, [buf + 16]
    mov rdx, 0x80000000
    mov r15, 0x38A4E0C6716860C1
    mov [buf + 16], rdx
    test [buf + 16], r15b
    mov rdx, [buf + 16]
    mov rsi, 0x97
    mov rcx, 0xEE7E5DC8F94B2FF9
    mov [buf + 16], rsi
    test [buf + 16], cl
    mov rsi, [buf + 16]
    mov r15, 0x80000000
    mov rax, 0xFFFFFFFFFFFFFF4F
    mov [buf + 24], r15
    test byte [buf + 24], 1
    mov rax, [buf + 24]
    mov rdi, 0x84
    mov r14, 0xFFFFFFFFFFFFFF80
    FLAGS 0x202
    mov [buf + 24], rdi
    test byte [buf + 24], -69
    mov r14, [buf + 24]
    mov r9, 0x7FFFFFFFFFFFFFFF
    mov rcx, 0xFFFFFFFFFFFFFF80
    mov [buf + 24], r9
    test byte [buf + 24], -86
    mov rcx, [buf + 24]
    mov rbx, 0x3
    mov rdx, 0x7F
    FLAGS 0xA02
    mov rax, 0x80
    test al, -49
    mov rdx, 0xFFFFFFFFFFFFFFDE
    mov r11, 0x15
    mov rax, 0xC45277E395FA0ABC
    test al, -1
    mov r12, 0x84CD1A1FB8254A1A
    mov r9, 0x37
    FLAGS 0xAD7
    mov rax, 0x5C
    test al, -128
    mov r12, 0x80000000
    mov rdx, 0x3178E286C6A38D20
    mov rbx, 0x2E2D1608CC03A3D9
    mov rcx, 0x3570A866136C909C
    test bh, cl
    test bl, ch
    mov r13, 0x70D4B78AB93DCE9D
    mov r14, 0x22B20E96EF266F10
    mov rcx, 0x7FFF
    mov rbx, 0xD94C2857C3007888
    test ch, bl
    test cl, bh
    mov rcx, 0x2B73521D7AE49965
    mov r8, 0x10000
    mov rcx, 0x699E417CB15296CD
    mov rbx, 0xFF
    test ch, bl
    test cl, bh
    mov r9, 0xF2E36B7A8D947563
    mov rdi, 0xFFFFFFFFFFFFFFEF
    test r9w, di
    mov r14, 0xFFFFFFFF80000000
    mov rdi, 0xFE2A5E915B398817
    FLAGS 0xA43
    test r14w, di
    mov r12, 0x3311D90101B951D6
    mov r8, 0x81
    FLAGS 0xA02
    test r12w, r8w
    mov r14, 0xAC9698AF86F996FD
    mov rbp, 0x8D006DD74575D8B
    test r14w, -1831
    mov r9, 0x80000000
    mov r12, 0xFFFFFFFFFFFFFF14
    FLAGS 0x213
    test r9w, -24082
    mov r15, 0x7FFFFFFF
    mov r11, 0xFFFFFFFF80000000
    test r15w, -18240
    mov r13, 0xFFFFFFFFFFFFFFEB
    mov r11, 0x7F
    mov [buf + 8], r11
    test [buf + 8], r13w
    mov r10, 0x80000000
    mov rbp, 0x100
    mov [buf + 8], rbp
    test [buf + 8], r10w
    mov r14, 0x9326DD7628D54FE9
    mov r8, 0x73D2F0601CA611B
    FLAGS 0xA43
    mov [buf + 8], r8
    test [buf + 8], r14w
    mov r13, 0x2179403CF4B2174B
    mov rdx, 0x8000000000000000
    mov [buf + 16], r13
    test [buf + 16], dx
    mov r13, [buf + 16]
    mov r10, 0x92296A47A3ECD82D
    mov rbx, 0x10000
    mov [buf + 16], r10
    test [buf + 16], bx
    mov r10, [buf + 16]
    mov rbx, 0x10000
    mov r12, 0x80000000
    FLAGS 0x202
    mov [buf + 16], rbx
    test [buf + 16], r12w
    mov rbx, [buf + 16]
    mov rcx, 0x81
    mov rbx, 0xC588594C7BBFA016
    mov [buf + 24], rcx
    test word [buf + 24], 9613
    mov rbx, [buf + 24]
    mov rsi, 0xB6
    mov r15, 0x11274E428CC5249C
    FLAGS 0x202
    mov [buf + 24], rsi
    test word [buf + 24], -4667
    mov r15, [buf + 24]
    mov rbp, 0xB56226AF15E67DD6
    mov r8, 0x9D488DFDD2449885
    mov [buf + 24], rbp
    test word [buf + 24], -28026
    mov r8, [buf + 24]
    mov rax, 0x3
    mov rcx, 0x4B
    mov rax, 0xD19F2BA00095EA63
    test ax, -12524
    mov r10, 0x4C25FC329A889721
    mov rax, 0x1
    mov rax, 0x37518C4A22C6B0B7
    test ax, 2770
    mov rdi, 0xA3379E851421E553
    mov rsi, 0x81
    mov rax, 0x7FFFFFFFFFFFFFFF
    test ax, -22420
    mov rbp, 0x77F06034B31BF7F8
    mov r12, 0xFFFFFFFFFFFFFF3B
    FLAGS 0xA02
    test bp, bp
    mov r12, 0xC092D3987DD015D5
    mov r15, 0xA2356FDC8CC07303
    test r12w, r12w
    mov r9, 0x133D72083025E570
    mov r13, 0xC550C5923CC2C1A8
    test r9w, r9w
    mov r8, 0x80000000
    mov rbx, 0xFFFFFFFFFFFFFF78
    FLAGS 0x246
    test r8d, ebx
    mov r8, 0x100000000
    mov r13, 0x7FFF
    FLAGS 0xA43
    test r8d, r13d
    mov rdx, 0xFFFFFFFFFFFFFF80
    mov r8, 0xFFFFFFFFFFFFFFDD
    test edx, r8d
    mov r9, 0x80000000
    mov rdx, 0x8295BD39DF46D660
    FLAGS 0xAD7
    test r9d, -2147483648
    mov r8, 0x60
    mov rdx, 0xFFFFFFFFFFFFFF80
    test r8d, 2147483647
    mov r9, 0x306A912388CEABB6
    mov rcx, 0xF0
    test r9d, 1575053655
    mov rbx, 0x10000
    mov rdi, 0xB0
    FLAGS 0xA43
    mov [buf + 8], rdi
    test [buf + 8], ebx
    mov r9, 0x0
    mov rdx, 0x1164D08970ED32FD
    FLAGS 0xA03
    mov [buf + 8], rdx
    test [buf + 8], r9d
    mov rdx, 0x12A1D1A73AABD558
    mov rbx, 0x5132CA41C60B13FA
    mov [buf + 8], rbx
    test [buf + 8], edx
    mov r9, 0x100
    mov rdx, 0xC0F2CF0B80FFD1E4
    mov [buf + 16], r9
    test [buf + 16], edx
    mov r9, [buf + 16]
    mov r12, 0x3DAF08C142803E20
    mov r14, 0x1182B3B5E9E48076
    mov [buf + 16], r12
    test [buf + 16], r14d
    mov r12, [buf + 16]
    mov r13, 0x3
    mov rbx, 0xFFFFFFFFFFFFFF8B
    FLAGS 0xA03
    mov [buf + 16], r13
    test [buf + 16], ebx
    mov r13, [buf + 16]
    mov r14, 0x7F
    mov r11, 0xFFFF
    mov [buf + 24], r14
    test dword [buf + 24], 5
    mov r11, [buf + 24]
    mov rbx, 0xA7D211CF2FA9F200
    mov rcx, 0x8000000000000000
    mov [buf + 24], rbx
    test dword [buf + 24], 2147483647
    mov rcx, [buf + 24]
    mov r9, 0xFFFF
    mov r15, 0xFFFFFFFFFFFFFF18
    FLAGS 0x202
    mov [buf + 24], r9
    test dword [buf + 24], 127
    mov r15, [buf + 24]
    mov rcx, 0x7FFFFFFF
    mov r13, 0x71DD0E5536DC51D3
    mov rax, 0xF2
    test eax, 2147483647
    mov rcx, 0xFFFFFFFF80000000
    mov rsi, 0xFFFFFFFFFFFFFFCB
    mov rax, 0x7FFFFFFFFFFFFFFF
    test eax, 127
    mov rbp, 0xFFFF
    mov r13, 0x10000
    FLAGS 0x202
    mov rax, 0xDCC88CC36C8727BE
    test eax, 2147483647
    mov rcx, 0x10000
    mov r8, 0x11
    test ecx, ecx
    mov r10, 0xC93E3428E615EB8D
    mov rdi, 0x10000
    FLAGS 0xAD7
    test r10d, r10d
    mov rdx, 0x80000000
    mov r14, 0x7F
    test edx, edx
    mov r11, 0xFFFFFFFF80000000
    mov r10, 0xFFFFFFFFFFFFFF57
    test r11, r10
    mov rdi, 0x7FFFFFFFFFFFFFFF
    mov rbp, 0xFFFFFFFFFFFFFF91
    test rdi, rbp
    mov rbx, 0x10000
    mov rdi, 0xFFFF
    FLAGS 0xA02
    test rbx, rdi
    mov r15, 0xFD
    mov rbp, 0xFFFFFFFFFFFFFF99
    FLAGS 0x246
    test r15, 2147483647
    mov r11, 0xE6324F43B6A2EF25
    mov rbp, 0xCC391DABE3D75DE
    test r11, -2147483648
    mov rsi, 0xF8F4B8414CD9196F
    mov rdx, 0xFFFFFFFF80000000
    test rsi, -1145717597
    mov rsi, 0x59475F9604721B7
    mov r14, 0x7F
    FLAGS 0xA03
    mov [buf + 8], r14
    test [buf + 8], rsi
    mov r8, 0x80000000
    mov r12, 0x100
    FLAGS 0x2D6
    mov [buf + 8], r12
    test [buf + 8], r8
    mov r13, 0x7FFFFFFFFFFFFFFF
    mov r11, 0x8E204AD64B6B78F3
    mov [buf + 8], r11
    test [buf + 8], r13
    mov r12, 0x10000
    mov r13, 0x31CC7996359FF63F
    mov [buf + 16], r12
    test [buf + 16], r13
    mov r12, [buf + 16]
    mov r10, 0x364EC824CB4AC063
    mov rbx, 0x81
    mov [buf + 16], r10
    test [buf + 16], rbx
    mov r10, [buf + 16]
    mov rbp, 0xD64F7D0A12759ED4
    mov r8, 0x81
    FLAGS 0x213
    mov [buf + 16], rbp
    test [buf + 16], r8
    mov rbp, [buf + 16]
    mov r14, 0x7F
    mov r12, 0x7FFF
    mov [buf + 24], r14
    test qword [buf + 24], 5
    mov r12, [buf + 24]
    mov rbx, 0xFC8C43360CAF223
    mov rdi, 0xFFCA853DC09C27E7
    mov [buf + 24], rbx
    test qword [buf + 24], -1219734479
    mov rdi, [buf + 24]
    mov r13, 0x29601074C82A2534
    mov r11, 0xFFFFFFFFFFFFFFFF
    mov [buf + 24], r13
    test qword [buf + 24], -128
    mov r11, [buf + 24]
    mov rbx, 0x100000000
    mov rsi, 0x2
    mov rax, 0xB5350DA8818CE8FF
    test rax, 742980726
    mov r13, 0x7FFFFFFFFFFFFFFF
    mov r11, 0x10000
    mov rax, 0xF66AB0F8CA3B6C76
    test rax, -128
    mov r15, 0x44BBD0D28524B29A
    mov r9, 0x50
    FLAGS 0xA02
    mov rax, 0x7D5EECED869CD3A5
    test rax, -2147483648
    mov rsi, 0x7FFFFFFF
    mov rdi, 0x719ACD5AA70A05D4
    test rsi, rsi
    mov rax, 0x8000
    mov r13, 0xB330F40F5BB449F8
    test rax, rax
    mov rdi, 0x251886F2422EEE93
    mov r8, 0x765D41B2665377DC
    FLAGS 0x297
    test rdi, rdi
    mov r14, 0xC0216433FEF3749E
    FLAGS 0x213
    inc r14b
    mov [buf], r14
    inc byte [buf]
    mov r14, [buf]
    mov rbx, 0x81
    FLAGS 0x212
    inc bl
    mov [buf], rbx
    inc byte [buf]
    mov rbx, [buf]
    mov rbp, 0xF496C29AE2F9C0E9
    FLAGS 0x212
    inc bpl
    mov [buf], rbp
    inc byte [buf]
    mov rbp, [buf]
    mov r11, 0xEA
    FLAGS 0x212
    inc r11b
    mov [buf], r11
    inc byte [buf]
    mov r11, [buf]
    mov rbx, 0xE82D9F613B2AAC80
    FLAGS 0x297
    inc bl
    mov [buf], rbx
    inc byte [buf]
    mov rbx, [buf]
    mov r11, 0xB30B402CDC4BA952
    FLAGS 0x213
    inc r11b
    mov [buf], r11
    inc byte [buf]
    mov r11, [buf]
    mov r12, 0xA59B458A7583B120
    FLAGS 0x202
    inc r12w
    mov [buf], r12
    inc word [buf]
    mov r12, [buf]
    mov rbp, 0xFFFFFFFFFFFFFFFF
    FLAGS 0x203
    inc bp
    mov [buf], rbp
    inc word [buf]
    mov rbp, [buf]
    mov r10, 0x701BFA57B2C62C47
    FLAGS 0xA02
    inc r10w
    mov [buf], r10
    inc word [buf]
    mov r10, [buf]
    mov rax, 0x100000000
    FLAGS 0x213
    inc ax
    mov [buf], rax
    inc word [buf]
    mov rax, [buf]
    mov r15, 0x2C070FF9878F693D
    FLAGS 0x297
    inc r15w
    mov [buf], r15
    inc word [buf]
    mov r15, [buf]
    mov r8, 0xE39D7F16BF2BBC69
    FLAGS 0x213
    inc r8w
    mov [buf], r8
    inc word [buf]
    mov r8, [buf]
    mov rbx, 0x0
    FLAGS 0x212
    inc ebx
    mov [buf], rbx
    inc dword [buf]
    mov rbx, [buf]
    mov rbp, 0xAEDD1E510396351A
    FLAGS 0xA03
    inc ebp
    mov [buf], rbp
    inc dword [buf]
    mov rbp, [buf]
    mov rbx, 0x949CC15DAA23C026
    FLAGS 0x202
    inc ebx
    mov [buf], rbx
    inc dword [buf]
    mov rbx, [buf]
    mov rbp, 0x2057DF7F95D915BB
    FLAGS 0xA03
    inc ebp
    mov [buf], rbp
    inc dword [buf]
    mov rbp, [buf]
    mov rdx, 0x7FFFFFFF
    FLAGS 0xA02
    inc edx
    mov [buf], rdx
    inc dword [buf]
    mov rdx, [buf]
    mov rbx, 0xEE891C597F604207
    FLAGS 0x246
    inc ebx
    mov [buf], rbx
    inc dword [buf]
    mov rbx, [buf]
    mov rbp, 0xB249489046810170
    FLAGS 0xA82
    inc rbp
    mov [buf], rbp
    inc qword [buf]
    mov rbp, [buf]
    mov rcx, 0xFFFFFFFF
    FLAGS 0x297
    inc rcx
    mov [buf], rcx
    inc qword [buf]
    mov rcx, [buf]
    mov r15, 0x8000
    FLAGS 0x203
    inc r15
    mov [buf], r15
    inc qword [buf]
    mov r15, [buf]
    mov rbx, 0x1
    FLAGS 0xAD7
    inc rbx
    mov [buf], rbx
    inc qword [buf]
    mov rbx, [buf]
    mov r13, 0x59A06FD056AB9D14
    FLAGS 0x246
    inc r13
    mov [buf], r13
    inc qword [buf]
    mov r13, [buf]
    mov rbx, 0x1
    FLAGS 0x213
    inc rbx
    mov [buf], rbx
    inc qword [buf]
    mov rbx, [buf]
    mov r8, 0xFFFFFFFF80000000
    FLAGS 0x2D6
    dec r8b
    mov [buf], r8
    dec byte [buf]
    mov r8, [buf]
    mov r12, 0xD82081BF93625CE7
    FLAGS 0xA43
    dec r12b
    mov [buf], r12
    dec byte [buf]
    mov r12, [buf]
    mov rax, 0x1A2E34C25F6C7DE1
    FLAGS 0x246
    dec al
    mov [buf], rax
    dec byte [buf]
    mov rax, [buf]
    mov rdi, 0x3
    FLAGS 0xA02
    dec dil
    mov [buf], rdi
    dec byte [buf]
    mov rdi, [buf]
    mov r15, 0x0
    FLAGS 0x2D6
    dec r15b
    mov [buf], r15
    dec byte [buf]
    mov r15, [buf]
    mov r13, 0x8D90BA261B53A667
    FLAGS 0x2D6
    dec r13b
    mov [buf], r13
    dec byte [buf]
    mov r13, [buf]
    mov rax, 0xD3544C61B33D361C
    FLAGS 0x2D6
    dec ax
    mov [buf], rax
    dec word [buf]
    mov rax, [buf]
    mov r10, 0xBD19B82E120DC27B
    FLAGS 0x2D6
    dec r10w
    mov [buf], r10
    dec word [buf]
    mov r10, [buf]
    mov r11, 0x7F
    FLAGS 0x202
    dec r11w
    mov [buf], r11
    dec word [buf]
    mov r11, [buf]
    mov r9, 0x3
    FLAGS 0x246
    dec r9w
    mov [buf], r9
    dec word [buf]
    mov r9, [buf]
    mov r8, 0xD7EE294AC3B9123E
    FLAGS 0xA02
    dec r8w
    mov [buf], r8
    dec word [buf]
    mov r8, [buf]
    mov r9, 0x9D9F8D6034681001
    FLAGS 0xA82
    dec r9w
    mov [buf], r9
    dec word [buf]
    mov r9, [buf]
    mov r11, 0x0
    FLAGS 0xA02
    dec r11d
    mov [buf], r11
    dec dword [buf]
    mov r11, [buf]
    mov rsi, 0xFFFFFFFFFFFFFF6D
    FLAGS 0x297
    dec esi
    mov [buf], rsi
    dec dword [buf]
    mov rsi, [buf]
    mov r14, 0xA559108B3666CE44
    FLAGS 0x203
    dec r14d
    mov [buf], r14
    dec dword [buf]
    mov r14, [buf]
    mov r11, 0xCF24563373F8D23C
    FLAGS 0x212
    dec r11d
    mov [buf], r11
    dec dword [buf]
    mov r11, [buf]
    mov rdx, 0xFFFFFFFF
    FLAGS 0xAD7
    dec edx
    mov [buf], rdx
    dec dword [buf]
    mov rdx, [buf]
    mov r9, 0x75D9B69B6DDA2D03
    FLAGS 0xA43
    dec r9d
    mov [buf], r9
    dec dword [buf]
    mov r9, [buf]
    mov rbx, 0x7FFF
    FLAGS 0x213
    dec rbx
    mov [buf], rbx
    dec qword [buf]
    mov rbx, [buf]
    mov rbp, 0xBE11673E66CBC4C6
    FLAGS 0x2D6
    dec rbp
    mov [buf], rbp
    dec qword [buf]
    mov rbp, [buf]
    mov rdi, 0xFFFFFFFFFFFFFFF8
    FLAGS 0xA43
    dec rdi
    mov [buf], rdi
    dec qword [buf]
    mov rdi, [buf]
    mov r10, 0x7FFFFFFFFFFFFFFF
    FLAGS 0x246
    dec r10
    mov [buf], r10
    dec qword [buf]
    mov r10, [buf]
    mov r14, 0x7FFF
    FLAGS 0x246
    dec r14
    mov [buf], r14
    dec qword [buf]
    mov r14, [buf]
    mov r10, 0x53
    FLAGS 0x246
    dec r10
    mov [buf], r10
    dec qword [buf]
    mov r10, [buf]
    mov r9, 0xFFFFFFFFFFFFFFFD
    FLAGS 0xA43
    neg r9b
    mov [buf], r9
    neg byte [buf]
    mov r9, [buf]
    mov r9, 0x94A77BC134A791CA
    FLAGS 0xAD7
    neg r9b
    mov [buf], r9
    neg byte [buf]
    mov r9, [buf]
    mov rbp, 0x7FFFFFFFFFFFFFFF
    FLAGS 0x2D6
    neg bpl
    mov [buf], rbp
    neg byte [buf]
    mov rbp, [buf]
    mov rdi, 0x100
    FLAGS 0x212
    neg dil
    mov [buf], rdi
    neg byte [buf]
    mov rdi, [buf]
    mov rsi, 0x7F
    FLAGS 0xA43
    neg sil
    mov [buf], rsi
    neg byte [buf]
    mov rsi, [buf]
    mov rax, 0xFFFFFFFF80000000
    FLAGS 0x212
    neg al
    mov [buf], rax
    neg byte [buf]
    mov rax, [buf]
    mov r12, 0x8000
    FLAGS 0x297
    neg r12w
    mov [buf], r12
    neg word [buf]
    mov r12, [buf]
    mov rax, 0x8000000000000000
    FLAGS 0x297
    neg ax
    mov [buf], rax
    neg word [buf]
    mov rax, [buf]
    mov rcx, 0x89BDAA4399BECCB5
    FLAGS 0x297
    neg cx
    mov [buf], rcx
    neg word [buf]
    mov rcx, [buf]
    mov r10, 0x7F
    FLAGS 0x212
    neg r10w
    mov [buf], r10
    neg word [buf]
    mov r10, [buf]
    mov r13, 0x525F3AAD5F96CFB
    FLAGS 0x246
    neg r13w
    mov [buf], r13
    neg word [buf]
    mov r13, [buf]
    mov rbp, 0xAD7E0DF2E7962922
    FLAGS 0xA43
    neg bp
    mov [buf], rbp
    neg word [buf]
    mov rbp, [buf]
    mov r9, 0x100000000
    FLAGS 0xA82
    neg r9d
    mov [buf], r9
    neg dword [buf]
    mov r9, [buf]
    mov rax, 0x7F
    FLAGS 0xA03
    neg eax
    mov [buf], rax
    neg dword [buf]
    mov rax, [buf]
    mov rcx, 0x4944705C66D01786
    FLAGS 0x212
    neg ecx
    mov [buf], rcx
    neg dword [buf]
    mov rcx, [buf]
    mov r9, 0x80
    FLAGS 0x203
    neg r9d
    mov [buf], r9
    neg dword [buf]
    mov r9, [buf]
    mov r15, 0x653A489CBC5E3F0C
    FLAGS 0xA03
    neg r15d
    mov [buf], r15
    neg dword [buf]
    mov r15, [buf]
    mov r15, 0x5E5FD3EDD08B01CF
    FLAGS 0x297
    neg r15d
    mov [buf], r15
    neg dword [buf]
    mov r15, [buf]
    mov rbx, 0x77BF3805127932CB
    FLAGS 0xA43
    neg rbx
    mov [buf], rbx
    neg qword [buf]
    mov rbx, [buf]
    mov r14, 0xFFFFFFFFFFFFFFFF
    FLAGS 0x2D6
    neg r14
    mov [buf], r14
    neg qword [buf]
    mov r14, [buf]
    mov r15, 0x3
    FLAGS 0x297
    neg r15
    mov [buf], r15
    neg qword [buf]
    mov r15, [buf]
    mov r8, 0x2
    FLAGS 0xA43
    neg r8
    mov [buf], r8
    neg qword [buf]
    mov r8, [buf]
    mov r8, 0x100
    FLAGS 0xA02
    neg r8
    mov [buf], r8
    neg qword [buf]
    mov r8, [buf]
    mov rdx, 0x451049DF637A04DD
    FLAGS 0xA03
    neg rdx
    mov [buf], rdx
    neg qword [buf]
    mov rdx, [buf]
    mov r13, 0xFFFFFFFFFFFFFF80
    FLAGS 0x203
    not r13b
    mov [buf], r13
    not byte [buf]
    mov r13, [buf]
    mov r15, 0x8000000000000000
    FLAGS 0xA43
    not r15b
    mov [buf], r15
    not byte [buf]
    mov r15, [buf]
    mov r15, 0x91
    FLAGS 0x203
    not r15b
    mov [buf], r15
    not byte [buf]
    mov r15, [buf]
    mov rsi, 0x6D71533CB226465B
    FLAGS 0xAD7
    not sil
    mov [buf], rsi
    not byte [buf]
    mov rsi, [buf]
    mov r10, 0x7F
    FLAGS 0x246
    not r10b
    mov [buf], r10
    not byte [buf]
    mov r10, [buf]
    mov r8, 0xFFFFFFFF80000000
    FLAGS 0x297
    not r8b
    mov [buf], r8
    not byte [buf]
    mov r8, [buf]
    mov rdi, 0x3
    FLAGS 0x297
    not di
    mov [buf], rdi
    not word [buf]
    mov rdi, [buf]
    mov rbx, 0xB4D71FAD019BA2D7
    FLAGS 0x203
    not bx
    mov [buf], rbx
    not word [buf]
    mov rbx, [buf]
    mov r9, 0x7B18BB69C98110C5
    FLAGS 0x2D6
    not r9w
    mov [buf], r9
    not word [buf]
    mov r9, [buf]
    mov r10, 0x9C0E2B10DB9130C0
    FLAGS 0x202
    not r10w
    mov [buf], r10
    not word [buf]
    mov r10, [buf]
    mov rbx, 0x100
    FLAGS 0xA02
    not bx
    mov [buf], rbx
    not word [buf]
    mov rbx, [buf]
    mov rsi, 0x3
    FLAGS 0x2D6
    not si
    mov [buf], rsi
    not word [buf]
    mov rsi, [buf]
    mov rax, 0x825739D10A718B9E
    FLAGS 0x212
    not eax
    mov [buf], rax
    not dword [buf]
    mov rax, [buf]
    mov rdx, 0x81
    FLAGS 0x203
    not edx
    mov [buf], rdx
    not dword [buf]
    mov rdx, [buf]
    mov rbx, 0x100000000
    FLAGS 0x246
    not ebx
    mov [buf], rbx
    not dword [buf]
    mov rbx, [buf]
    mov r13, 0x5A1F512DE357CB61
    FLAGS 0xA82
    not r13d
    mov [buf], r13
    not dword [buf]
    mov r13, [buf]
    mov r12, 0x2D309EAE3DBB7050
    FLAGS 0xAD7
    not r12d
    mov [buf], r12
    not dword [buf]
    mov r12, [buf]
    mov r9, 0x10000
    FLAGS 0xA02
    not r9d
    mov [buf], r9
    not dword [buf]
    mov r9, [buf]
    mov r14, 0xD14DBA8FB86127A4
    FLAGS 0x213
    not r14
    mov [buf], r14
    not qword [buf]
    mov r14, [buf]
    mov rdi, 0x55
    FLAGS 0x246
    not rdi
    mov [buf], rdi
    not qword [buf]
    mov rdi, [buf]
    mov rcx, 0x3DAD0DE447183C4F
    FLAGS 0xA82
    not rcx
    mov [buf], rcx
    not qword [buf]
    mov rcx, [buf]
    mov rbx, 0x3F
    FLAGS 0x297
    not rbx
    mov [buf], rbx
    not qword [buf]
    mov rbx, [buf]
    mov r10, 0x3F3A9D82498167F5
    FLAGS 0x297
    not r10
    mov [buf], r10
    not qword [buf]
    mov r10, [buf]
    mov rdx, 0x100000000
    FLAGS 0x246
    not rdx
    mov [buf], rdx
    not qword [buf]
    mov rdx, [buf]
    EXIT
    align 16
buf: times 64 dq 0x0123456789ABCDEF
file_end:
