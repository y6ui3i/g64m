; BT, BTS, BTR and BTC on registers and memory, BSF, BSR, POPCNT, BSWAP, CMPXCHG, XADD, CMPXCHG8B and 16B.
; Written by tools/gen64_tests.py: change that, not this.
%include "elf.inc"
    mov r9, 0x9F36B505FA596513
    mov rcx, 0x8000000000000000
    FLAGS 0x213
    bt r9w, cx
    FLAGS 0x203
    bt r9w, 64
    mov rcx, 0xFFFFFFFFFFFFFE96
    FLAGS 0x2D6
    bt [buf + 256], cx
    bt word [buf + 256], 2
    mov r9, 0x7FFF
    mov rdi, 0xFFFFFFFFFFFFFF79
    FLAGS 0x297
    bt r9w, di
    FLAGS 0xA02
    bt r9w, 16
    mov rdi, 0xFFFFFFFFFFFFFDCD
    FLAGS 0xA82
    bt [buf + 256], di
    bt word [buf + 256], 239
    mov r8, 0x1
    mov rax, 0x786609B52B3D204E
    FLAGS 0xA03
    bt r8w, ax
    FLAGS 0xA03
    bt r8w, 32
    mov rax, 0x14
    FLAGS 0x246
    bt [buf + 256], ax
    bt word [buf + 256], 64
    mov rbp, 0x64
    mov rbx, 0x0
    FLAGS 0xA02
    bt bp, bx
    FLAGS 0xAD7
    bt bp, 16
    mov rbx, 0xFFFFFFFFFFFFFE71
    FLAGS 0xA03
    bt [buf + 256], bx
    bt word [buf + 256], 93
    mov r8, 0x1
    mov r9, 0xCB745ED9DA28EAC7
    FLAGS 0x203
    bt r8w, r9w
    FLAGS 0xA43
    bt r8w, 63
    mov r9, 0x136
    FLAGS 0x203
    bt [buf + 256], r9w
    bt word [buf + 256], 122
    mov rsi, [buf + 248]
    mov rdi, [buf + 256]
    mov rbp, 0xFFFFFFFFFFFFFFFF
    mov rcx, 0x28D2E6B0867BA854
    FLAGS 0xAD7
    bt ebp, ecx
    FLAGS 0x297
    bt ebp, 7
    mov rcx, 0xFFFFFFFFFFFFFC40
    FLAGS 0x203
    bt [buf + 256], ecx
    bt dword [buf + 256], 199
    mov rdx, 0x98E9C435A0548BB4
    mov r8, 0x62154A8290789421
    FLAGS 0x213
    bt edx, r8d
    FLAGS 0xA82
    bt edx, 200
    mov r8, 0xFFFFFFFFFFFFFE41
    FLAGS 0xA02
    bt [buf + 256], r8d
    bt dword [buf + 256], 92
    mov r14, 0x3907C34E3DAF4953
    mov r12, 0x80
    FLAGS 0x203
    bt r14d, r12d
    FLAGS 0x202
    bt r14d, 16
    mov r12, 0xFFFFFFFFFFFFFC18
    FLAGS 0xA03
    bt [buf + 256], r12d
    bt dword [buf + 256], 49
    mov rbp, 0x63022DAC86AE5B54
    mov r8, 0xFFFFFFFFFFFFFF7E
    FLAGS 0x246
    bt ebp, r8d
    FLAGS 0x203
    bt ebp, 16
    mov r8, 0xFFFFFFFFFFFFFECC
    FLAGS 0xAD7
    bt [buf + 256], r8d
    bt dword [buf + 256], 148
    mov r10, 0x8000
    mov rbx, 0x97A597343E9D6311
    FLAGS 0x246
    bt r10d, ebx
    FLAGS 0xA02
    bt r10d, 7
    mov rbx, 0x24E
    FLAGS 0x213
    bt [buf + 256], ebx
    bt dword [buf + 256], 198
    mov rsi, [buf + 248]
    mov rdi, [buf + 256]
    mov rdx, 0x0
    mov r8, 0x29
    FLAGS 0xA03
    bt rdx, r8
    FLAGS 0xA03
    bt rdx, 1
    mov r8, 0xFFFFFFFFFFFFFFF9
    FLAGS 0xA02
    bt [buf + 256], r8
    bt qword [buf + 256], 8
    mov r15, 0xB2E68139521DE15A
    mov rbx, 0xFFFFFFFFFFFFFF8D
    FLAGS 0x202
    bt r15, rbx
    FLAGS 0xA43
    bt r15, 0
    mov rbx, 0xFFFFFFFFFFFFFCC2
    FLAGS 0x213
    bt [buf + 256], rbx
    bt qword [buf + 256], 162
    mov r12, 0x7F9DCDEBB78DEF1A
    mov rax, 0x28400937067ACC94
    FLAGS 0xA02
    bt r12, rax
    FLAGS 0xA03
    bt r12, 15
    mov rax, 0x1F0
    FLAGS 0x297
    bt [buf + 256], rax
    bt qword [buf + 256], 130
    mov r15, 0x100
    mov rsi, 0xFFCB4EF5A3CF720
    FLAGS 0xA82
    bt r15, rsi
    FLAGS 0xA43
    bt r15, 7
    mov rsi, 0xFFFFFFFFFFFFFE93
    FLAGS 0x2D6
    bt [buf + 256], rsi
    bt qword [buf + 256], 37
    mov r13, 0x7FFFFFFF
    mov r10, 0x7FFFFFFF
    FLAGS 0xA82
    bt r13, r10
    FLAGS 0x246
    bt r13, 64
    mov r10, 0x2F6
    FLAGS 0xA03
    bt [buf + 256], r10
    bt qword [buf + 256], 80
    mov rsi, [buf + 248]
    mov rdi, [buf + 256]
    mov r10, 0x7F
    mov r9, 0xFFFF
    FLAGS 0xA03
    bts r10w, r9w
    FLAGS 0xAD7
    bts r10w, 32
    mov r9, 0xFFFFFFFFFFFFFEDA
    FLAGS 0x212
    bts [buf + 256], r9w
    bts word [buf + 256], 178
    mov r10, 0x100000000
    mov r12, 0x50
    FLAGS 0x297
    bts r10w, r12w
    FLAGS 0xAD7
    bts r10w, 64
    mov r12, 0x28A
    FLAGS 0xA82
    bts [buf + 256], r12w
    bts word [buf + 256], 77
    mov rbp, 0x2
    mov rsi, 0x1
    FLAGS 0xA82
    bts bp, si
    FLAGS 0xA02
    bts bp, 200
    mov rsi, 0xEA
    FLAGS 0x203
    bts [buf + 256], si
    bts word [buf + 256], 108
    mov r11, 0x7F
    mov r8, 0xFFFFFFFFFFFFFF41
    FLAGS 0x212
    bts r11w, r8w
    FLAGS 0xA43
    bts r11w, 32
    mov r8, 0x70
    FLAGS 0x213
    bts [buf + 256], r8w
    bts word [buf + 256], 215
    mov r12, 0xFF
    mov r15, 0x3A6A80810A63063F
    FLAGS 0xA02
    bts r12w, r15w
    FLAGS 0xAD7
    bts r12w, 15
    mov r15, 0x3C1
    FLAGS 0xA82
    bts [buf + 256], r15w
    bts word [buf + 256], 224
    mov rsi, [buf + 248]
    mov rdi, [buf + 256]
    mov rbx, 0x7FFFFFFFFFFFFFFF
    mov r9, 0x7FFF
    FLAGS 0x297
    bts ebx, r9d
    FLAGS 0xA03
    bts ebx, 15
    mov r9, 0x264
    FLAGS 0x203
    bts [buf + 256], r9d
    bts dword [buf + 256], 129
    mov r9, 0xC1
    mov r12, 0x1CA4F918FFC5CB2F
    FLAGS 0xAD7
    bts r9d, r12d
    FLAGS 0x297
    bts r9d, 16
    mov r12, 0x308
    FLAGS 0xA43
    bts [buf + 256], r12d
    bts dword [buf + 256], 15
    mov r15, 0x21
    mov rcx, 0x7602B5335F047A40
    FLAGS 0xA82
    bts r15d, ecx
    FLAGS 0x246
    bts r15d, 15
    mov rcx, 0x3BA
    FLAGS 0xA03
    bts [buf + 256], ecx
    bts dword [buf + 256], 223
    mov rbp, 0x9B1F7A6FCAC220E4
    mov rsi, 0x7FFFFFFFFFFFFFFF
    FLAGS 0xAD7
    bts ebp, esi
    FLAGS 0xA03
    bts ebp, 32
    mov rsi, 0xFFFFFFFFFFFFFC51
    FLAGS 0x2D6
    bts [buf + 256], esi
    bts dword [buf + 256], 81
    mov r10, 0x3D
    mov rdx, 0xAE76A76816B4E58C
    FLAGS 0xAD7
    bts r10d, edx
    FLAGS 0x246
    bts r10d, 200
    mov rdx, 0xFFFFFFFFFFFFFD92
    FLAGS 0x202
    bts [buf + 256], edx
    bts dword [buf + 256], 136
    mov rsi, [buf + 248]
    mov rdi, [buf + 256]
    mov r9, 0xFF
    mov rax, 0xFECC771EC364CBDB
    FLAGS 0xA03
    bts r9, rax
    FLAGS 0x203
    bts r9, 15
    mov rax, 0xD
    FLAGS 0x2D6
    bts [buf + 256], rax
    bts qword [buf + 256], 33
    mov rdi, 0xFFFFFFFFFFFFFF80
    mov rax, 0x2EF0D395334D90E9
    FLAGS 0x202
    bts rdi, rax
    FLAGS 0xA82
    bts rdi, 0
    mov rax, 0xFFFFFFFFFFFFFFB3
    FLAGS 0x212
    bts [buf + 256], rax
    bts qword [buf + 256], 11
    mov rbx, 0xB90A2181B462C2E4
    mov r10, 0xAEC52CE04F687AD1
    FLAGS 0xA43
    bts rbx, r10
    FLAGS 0xA82
    bts rbx, 15
    mov r10, 0x3B6
    FLAGS 0x213
    bts [buf + 256], r10
    bts qword [buf + 256], 44
    mov r15, 0x2
    mov rbp, 0x1
    FLAGS 0x212
    bts r15, rbp
    FLAGS 0xA02
    bts r15, 16
    mov rbp, 0x248
    FLAGS 0x246
    bts [buf + 256], rbp
    bts qword [buf + 256], 135
    mov rbx, 0xD67DEC5D4B5F7FAA
    mov rcx, 0x7FFF
    FLAGS 0xA82
    bts rbx, rcx
    FLAGS 0x297
    bts rbx, 1
    mov rcx, 0x2B2
    FLAGS 0x2D6
    bts [buf + 256], rcx
    bts qword [buf + 256], 230
    mov rsi, [buf + 248]
    mov rdi, [buf + 256]
    mov rbx, 0x7F
    mov r12, 0xFFFF
    FLAGS 0xA43
    btr bx, r12w
    FLAGS 0x203
    btr bx, 15
    mov r12, 0x1E2
    FLAGS 0xA43
    btr [buf + 256], r12w
    btr word [buf + 256], 189
    mov rax, 0x2
    mov r13, 0xB5C791C5661A06E9
    FLAGS 0x212
    btr ax, r13w
    FLAGS 0xAD7
    btr ax, 7
    mov r13, 0x18
    FLAGS 0xA43
    btr [buf + 256], r13w
    btr word [buf + 256], 199
    mov r10, 0x51C0BBBF0FE9D1DA
    mov rdx, 0x8000000000000000
    FLAGS 0x212
    btr r10w, dx
    FLAGS 0xA43
    btr r10w, 200
    mov rdx, 0xFFFFFFFFFFFFFFA0
    FLAGS 0xA82
    btr [buf + 256], dx
    btr word [buf + 256], 176
    mov rbx, 0x2
    mov r13, 0x1001E3F0A1697A0
    FLAGS 0x2D6
    btr bx, r13w
    FLAGS 0x297
    btr bx, 7
    mov r13, 0xFFFFFFFFFFFFFF09
    FLAGS 0xA82
    btr [buf + 256], r13w
    btr word [buf + 256], 78
    mov r14, 0xD338CB245BC59637
    mov r8, 0xFFFF
    FLAGS 0x246
    btr r14w, r8w
    FLAGS 0x213
    btr r14w, 15
    mov r8, 0x7D
    FLAGS 0xA03
    btr [buf + 256], r8w
    btr word [buf + 256], 87
    mov rsi, [buf + 248]
    mov rdi, [buf + 256]
    mov r10, 0x10000
    mov rdx, 0x208C66B1A26913A4
    FLAGS 0x202
    btr r10d, edx
    FLAGS 0xA43
    btr r10d, 0
    mov rdx, 0x3A2
    FLAGS 0x203
    btr [buf + 256], edx
    btr dword [buf + 256], 182
    mov rdx, 0x80
    mov rdi, 0xFFFFFFFFFFFFFF80
    FLAGS 0x246
    btr edx, edi
    FLAGS 0x203
    btr edx, 31
    mov rdi, 0xFFFFFFFFFFFFFDE9
    FLAGS 0xA03
    btr [buf + 256], edi
    btr dword [buf + 256], 102
    mov r11, 0x95868946C5AFE091
    mov rdi, 0x0
    FLAGS 0xA03
    btr r11d, edi
    FLAGS 0x213
    btr r11d, 63
    mov rdi, 0xFFFFFFFFFFFFFDC4
    FLAGS 0x203
    btr [buf + 256], edi
    btr dword [buf + 256], 39
    mov rsi, 0x7F
    mov rdi, 0x6ECA8ADE33989073
    FLAGS 0xA03
    btr esi, edi
    FLAGS 0x213
    btr esi, 200
    mov rdi, 0x30D
    FLAGS 0x212
    btr [buf + 256], edi
    btr dword [buf + 256], 180
    mov r12, 0x80
    mov r10, 0xB2D05FC9D0736D74
    FLAGS 0xA03
    btr r12d, r10d
    FLAGS 0x203
    btr r12d, 200
    mov r10, 0xFFFFFFFFFFFFFE46
    FLAGS 0x297
    btr [buf + 256], r10d
    btr dword [buf + 256], 217
    mov rsi, [buf + 248]
    mov rdi, [buf + 256]
    mov r8, 0x3496439491B99449
    mov r14, 0xE6
    FLAGS 0xA03
    btr r8, r14
    FLAGS 0xA02
    btr r8, 16
    mov r14, 0x2C3
    FLAGS 0x246
    btr [buf + 256], r14
    btr qword [buf + 256], 0
    mov rcx, 0xCFDD6578899A0E0B
    mov r11, 0xC0AFA48757003866
    FLAGS 0x203
    btr rcx, r11
    FLAGS 0xA82
    btr rcx, 1
    mov r11, 0xFFFFFFFFFFFFFC97
    FLAGS 0x202
    btr [buf + 256], r11
    btr qword [buf + 256], 71
    mov r13, 0x80
    mov r15, 0x0
    FLAGS 0xA02
    btr r13, r15
    FLAGS 0xA43
    btr r13, 200
    mov r15, 0xFFFFFFFFFFFFFE6A
    FLAGS 0x2D6
    btr [buf + 256], r15
    btr qword [buf + 256], 179
    mov rbp, 0x8DBD6715EDF6E3FA
    mov r14, 0xFFFFFFFFFFFFFF07
    FLAGS 0x297
    btr rbp, r14
    FLAGS 0xA82
    btr rbp, 200
    mov r14, 0xFFFFFFFFFFFFFD21
    FLAGS 0x2D6
    btr [buf + 256], r14
    btr qword [buf + 256], 38
    mov r11, 0x80000000
    mov r8, 0xFFFFFFFFFFFFFFC6
    FLAGS 0x203
    btr r11, r8
    FLAGS 0xA82
    btr r11, 64
    mov r8, 0x38
    FLAGS 0xA02
    btr [buf + 256], r8
    btr qword [buf + 256], 59
    mov rsi, [buf + 248]
    mov rdi, [buf + 256]
    mov r9, 0xFFFFFFFFFFFFFFCE
    mov rdi, 0x80000000
    FLAGS 0xA03
    btc r9w, di
    FLAGS 0xA43
    btc r9w, 16
    mov rdi, 0x3E2
    FLAGS 0x203
    btc [buf + 256], di
    btc word [buf + 256], 92
    mov rbx, 0x8B149528B721D2A0
    mov r9, 0x0
    FLAGS 0x2D6
    btc bx, r9w
    FLAGS 0xAD7
    btc bx, 7
    mov r9, 0x21D
    FLAGS 0xA43
    btc [buf + 256], r9w
    btc word [buf + 256], 57
    mov r15, 0x20C124DF25978D6A
    mov rdx, 0x1F2876EB167681AA
    FLAGS 0x246
    btc r15w, dx
    FLAGS 0xA82
    btc r15w, 16
    mov rdx, 0xFFFFFFFFFFFFFCE1
    FLAGS 0x212
    btc [buf + 256], dx
    btc word [buf + 256], 65
    mov r10, 0xB1AD2B49A4B61CAB
    mov rax, 0x80
    FLAGS 0x202
    btc r10w, ax
    FLAGS 0xAD7
    btc r10w, 31
    mov rax, 0x4F
    FLAGS 0xA02
    btc [buf + 256], ax
    btc word [buf + 256], 253
    mov rbx, 0x3
    mov rbp, 0x100
    FLAGS 0x297
    btc bx, bp
    FLAGS 0xA43
    btc bx, 64
    mov rbp, 0xFFFFFFFFFFFFFFD6
    FLAGS 0xA02
    btc [buf + 256], bp
    btc word [buf + 256], 210
    mov rsi, [buf + 248]
    mov rdi, [buf + 256]
    mov r9, 0x7FFFFFFFFFFFFFFF
    mov r8, 0xFFFFFFFFFFFFFF80
    FLAGS 0xAD7
    btc r9d, r8d
    FLAGS 0x202
    btc r9d, 200
    mov r8, 0x236
    FLAGS 0xA02
    btc [buf + 256], r8d
    btc dword [buf + 256], 167
    mov rax, 0xFFFFFFFFFFFFFFE2
    mov rdx, 0xA156C18FD8F1300C
    FLAGS 0x213
    btc eax, edx
    FLAGS 0x203
    btc eax, 200
    mov rdx, 0xFFFFFFFFFFFFFF44
    FLAGS 0xA03
    btc [buf + 256], edx
    btc dword [buf + 256], 233
    mov rbp, 0x8000000000000000
    mov r14, 0x7F
    FLAGS 0xA43
    btc ebp, r14d
    FLAGS 0xA02
    btc ebp, 15
    mov r14, 0x387
    FLAGS 0x297
    btc [buf + 256], r14d
    btc dword [buf + 256], 195
    mov rdi, 0x3
    mov rbx, 0x1E6624A6F3C59A95
    FLAGS 0xA02
    btc edi, ebx
    FLAGS 0x297
    btc edi, 63
    mov rbx, 0x26F
    FLAGS 0xA03
    btc [buf + 256], ebx
    btc dword [buf + 256], 247
    mov rdx, 0xFFFFFFFFFFFFFF80
    mov r13, 0x7FFF
    FLAGS 0x297
    btc edx, r13d
    FLAGS 0xAD7
    btc edx, 16
    mov r13, 0x3C0
    FLAGS 0xAD7
    btc [buf + 256], r13d
    btc dword [buf + 256], 134
    mov rsi, [buf + 248]
    mov rdi, [buf + 256]
    mov r13, 0xC0
    mov rax, 0x80
    FLAGS 0x203
    btc r13, rax
    FLAGS 0x2D6
    btc r13, 16
    mov rax, 0xFFFFFFFFFFFFFD29
    FLAGS 0x246
    btc [buf + 256], rax
    btc qword [buf + 256], 32
    mov r14, 0xB132D5BB673F655F
    mov r12, 0x9F37F3C552B3408E
    FLAGS 0xAD7
    btc r14, r12
    FLAGS 0xA82
    btc r14, 64
    mov r12, 0xFFFFFFFFFFFFFE8E
    FLAGS 0x212
    btc [buf + 256], r12
    btc qword [buf + 256], 225
    mov rdx, 0xFF
    mov r12, 0x0
    FLAGS 0x212
    btc rdx, r12
    FLAGS 0x203
    btc rdx, 64
    mov r12, 0xFFFFFFFFFFFFFE02
    FLAGS 0x246
    btc [buf + 256], r12
    btc qword [buf + 256], 195
    mov r13, 0x1
    mov rbp, 0x1F32E9447D225024
    FLAGS 0xA03
    btc r13, rbp
    FLAGS 0x246
    btc r13, 31
    mov rbp, 0x181
    FLAGS 0x203
    btc [buf + 256], rbp
    btc qword [buf + 256], 105
    mov rax, 0xE76334A4A2CEA9CB
    mov r12, 0x385494AE80E14EEF
    FLAGS 0xA82
    btc rax, r12
    FLAGS 0xAD7
    btc rax, 0
    mov r12, 0xFFFFFFFFFFFFFEE0
    FLAGS 0x202
    btc [buf + 256], r12
    btc qword [buf + 256], 12
    mov rsi, [buf + 248]
    mov rdi, [buf + 256]
    mov r13, 0x9D0D67E35EEE9D37
    mov r15, 0x0
    FLAGS 0x202
    bsf r13w, r15w
    mov r10, 0xEC11E45B6741066B
    mov rsi, 0x1
    FLAGS 0xA43
    bsf r10w, si
    mov r11, 0xFFFFFFFFFFFFFF80
    mov r12, 0x8000
    FLAGS 0x203
    bsf r11w, r12w
    mov rdx, 0x1DDBD848768BE7B
    mov r11, 0x80000000
    FLAGS 0xA03
    bsf dx, r11w
    mov r10, 0xFFFFFFFFFFFFFFFF
    mov rbp, 0x8000000000000000
    FLAGS 0xA82
    bsf r10w, bp
    mov rdx, 0x6A2250D0CEB4A984
    mov r12, 0xFFFFFFFFFFFFFFD5
    FLAGS 0x246
    bsf dx, r12w
    mov r10, 0xB75C649DF730A0A8
    mov r9, 0x137392782C5E6BA6
    FLAGS 0xA03
    bsf r10w, r9w
    mov r10, 0x9AD947FD497B72
    mov r9, 0x829DEAE2E6662216
    FLAGS 0x212
    bsf r10w, r9w
    mov r15, 0x8000
    mov r10, 0x0
    FLAGS 0x212
    bsf r15d, r10d
    mov r12, 0x724E0517BCD8BAA
    mov r8, 0x1
    FLAGS 0x213
    bsf r12d, r8d
    mov r14, 0x7833EBC6BE5B64E0
    mov rcx, 0x8000
    FLAGS 0x202
    bsf r14d, ecx
    mov r14, 0x7FFFFFFF
    mov r12, 0x80000000
    FLAGS 0x2D6
    bsf r14d, r12d
    mov rax, 0xB6
    mov r14, 0x8000000000000000
    FLAGS 0xA02
    bsf eax, r14d
    mov r10, 0x792B2BB1B04982FC
    mov r11, 0xFFFFFFFF
    FLAGS 0xAD7
    bsf r10d, r11d
    mov r10, 0xF366CEDF63B1C14E
    mov r13, 0x100
    FLAGS 0x246
    bsf r10d, r13d
    mov rdx, 0x100000000
    mov r10, 0x9930ACBEBAC08D7F
    FLAGS 0xAD7
    bsf edx, r10d
    mov r11, 0x100
    mov r12, 0x0
    FLAGS 0x212
    bsf r11, r12
    mov rax, 0x81
    mov rcx, 0x1
    FLAGS 0xA82
    bsf rax, rcx
    mov rbp, 0x2
    mov r14, 0x8000
    FLAGS 0x212
    bsf rbp, r14
    mov rcx, 0xEFE324C113BCAA1A
    mov r8, 0x80000000
    FLAGS 0xA82
    bsf rcx, r8
    mov r8, 0xCFE2D7E3EE056136
    mov rbx, 0x8000000000000000
    FLAGS 0x2D6
    bsf r8, rbx
    mov r13, 0x3D13D6C5EC82EAF
    mov r10, 0x5A919AA25375235F
    FLAGS 0xA82
    bsf r13, r10
    mov r10, 0x394F58A23C4DD779
    mov r14, 0xDB0C5A35AB31E04F
    FLAGS 0xA02
    bsf r10, r14
    mov rdx, 0x3B82AE3596A37754
    mov rcx, 0x210B6DF4038005F8
    FLAGS 0x2D6
    bsf rdx, rcx
    mov r12, 0xB22A8798BC13ED61
    mov r8, 0x0
    FLAGS 0x213
    bsr r12w, r8w
    mov r8, 0x8000
    mov rdx, 0x1
    FLAGS 0x202
    bsr r8w, dx
    mov rax, 0x100000000
    mov rbp, 0x8000
    FLAGS 0xAD7
    bsr ax, bp
    mov r10, 0x97A638E9765A6948
    mov r12, 0x80000000
    FLAGS 0x202
    bsr r10w, r12w
    mov rdi, 0x33E3D801400D23F1
    mov r11, 0x8000000000000000
    FLAGS 0x2D6
    bsr di, r11w
    mov rsi, 0x24
    mov r9, 0x80
    FLAGS 0x212
    bsr si, r9w
    mov r10, 0xEC1F66F7B190432E
    mov rcx, 0xFFFFFFFF80000000
    FLAGS 0xA82
    bsr r10w, cx
    mov rax, 0x100
    mov rdi, 0xFFFF
    FLAGS 0xA02
    bsr ax, di
    mov r15, 0x6BE49209E6FAF3A
    mov r9, 0x0
    FLAGS 0xA43
    bsr r15d, r9d
    mov r15, 0x2
    mov rax, 0x1
    FLAGS 0x297
    bsr r15d, eax
    mov r13, 0x1
    mov rsi, 0x8000
    FLAGS 0xAD7
    bsr r13d, esi
    mov rax, 0x10000
    mov rbp, 0x80000000
    FLAGS 0x246
    bsr eax, ebp
    mov rax, 0x8A1ACF903841E954
    mov r15, 0x8000000000000000
    FLAGS 0x246
    bsr eax, r15d
    mov r14, 0x81EEEBF9A8B85E2E
    mov rdi, 0xDFD81F50960F37E9
    FLAGS 0xA82
    bsr r14d, edi
    mov rdi, 0x7FFFFFFFFFFFFFFF
    mov r12, 0xFFFFFFFFFFFFFF47
    FLAGS 0x202
    bsr edi, r12d
    mov r15, 0xFFFFFFFFFFFFFFD2
    mov rax, 0x8000000000000000
    FLAGS 0x246
    bsr r15d, eax
    mov rax, 0x5984866C42801EFB
    mov r15, 0x0
    FLAGS 0xAD7
    bsr rax, r15
    mov r13, 0xB40BD6531F257E18
    mov rdi, 0x1
    FLAGS 0x213
    bsr r13, rdi
    mov rdi, 0x10000
    mov r9, 0x8000
    FLAGS 0x213
    bsr rdi, r9
    mov rdi, 0xFFFFFFFFFFFFFF80
    mov rax, 0x80000000
    FLAGS 0xAD7
    bsr rdi, rax
    mov rcx, 0xFFFFFFFFFFFFFFFF
    mov r14, 0x8000000000000000
    FLAGS 0x212
    bsr rcx, r14
    mov rdx, 0x1
    mov r13, 0xEFFE13AF0DE28956
    FLAGS 0xA43
    bsr rdx, r13
    mov r15, 0xAE453A60A894AEEF
    mov r12, 0x1D4ADEC474D37A52
    FLAGS 0x246
    bsr r15, r12
    mov r14, 0xC7C101A23F8FD14F
    mov rcx, 0x81
    FLAGS 0x297
    bsr r14, rcx
    mov r12, 0x7EA3D3267583C9A1
    mov rbp, 0x0
    FLAGS 0xA02
    popcnt r12w, bp
    mov r8, 0x245BD91E375FFF18
    mov r12, 0x1
    FLAGS 0x246
    popcnt r8w, r12w
    mov rdi, 0x2AB8AC49B60BA8E0
    mov rax, 0x8000
    FLAGS 0x246
    popcnt di, ax
    mov r9, 0x6FBA473D83EC48F5
    mov rdi, 0x80000000
    FLAGS 0x213
    popcnt r9w, di
    mov rdx, 0x80
    mov rax, 0x8000000000000000
    FLAGS 0x297
    popcnt dx, ax
    mov rcx, 0xFFFFFFFF
    mov r13, 0xFFFFFFFF
    FLAGS 0xA43
    popcnt cx, r13w
    mov r10, 0x38
    mov r13, 0x37A79AF4E54D3F52
    FLAGS 0x2D6
    popcnt r10w, r13w
    mov rsi, 0x100
    mov r10, 0x8000000000000000
    FLAGS 0xA43
    popcnt si, r10w
    mov r9, 0x100
    mov rax, 0x0
    FLAGS 0x202
    popcnt r9d, eax
    mov rdi, 0xC987F3847FC4B8DF
    mov rsi, 0x1
    FLAGS 0xA82
    popcnt edi, esi
    mov rdx, 0x61AACAF4CFBC97D8
    mov r11, 0x8000
    FLAGS 0x213
    popcnt edx, r11d
    mov rdx, 0x100000000
    mov r9, 0x80000000
    FLAGS 0x212
    popcnt edx, r9d
    mov rdi, 0x8000
    mov r14, 0x8000000000000000
    FLAGS 0x246
    popcnt edi, r14d
    mov r12, 0xFFFFFFFF80000000
    mov r9, 0x55B31E4794AA19A1
    FLAGS 0xAD7
    popcnt r12d, r9d
    mov rbx, 0x1A
    mov rsi, 0x3
    FLAGS 0x246
    popcnt ebx, esi
    mov r8, 0x1
    mov r15, 0xEEB3045E1F0CE5B0
    FLAGS 0x246
    popcnt r8d, r15d
    mov rbp, 0x5EC7F32773035A7B
    mov rdi, 0x0
    FLAGS 0xA03
    popcnt rbp, rdi
    mov rax, 0x100000000
    mov rbp, 0x1
    FLAGS 0xA03
    popcnt rax, rbp
    mov rbp, 0x24F01A5437A12010
    mov r11, 0x8000
    FLAGS 0xA03
    popcnt rbp, r11
    mov r13, 0x69D1D1754096E649
    mov r15, 0x80000000
    FLAGS 0xA82
    popcnt r13, r15
    mov r13, 0x100000000
    mov r15, 0x8000000000000000
    FLAGS 0xA03
    popcnt r13, r15
    mov r9, 0x94683E5129E4CD1
    mov r11, 0x2BB975243707440F
    FLAGS 0xA82
    popcnt r9, r11
    mov rbp, 0x1
    mov rdx, 0xFFFFFFFFFFFFFFFF
    FLAGS 0xA43
    popcnt rbp, rdx
    mov r8, 0x2
    mov r9, 0x408398EBCE68F82C
    FLAGS 0x203
    popcnt r8, r9
    mov r11, 0x2B723DE9A010EF06
    mov rsi, 0x0
    FLAGS 0xA82
    tzcnt r11w, si
    mov rdx, 0x7FFFFFFFFFFFFFFF
    mov r14, 0x1
    FLAGS 0x202
    tzcnt dx, r14w
    mov r14, 0x8000
    mov r12, 0x8000
    FLAGS 0xA02
    tzcnt r14w, r12w
    mov rsi, 0x1DB537A85FF442F8
    mov rbp, 0x80000000
    FLAGS 0x212
    tzcnt si, bp
    mov r14, 0x7FFFFFFF
    mov r12, 0x8000000000000000
    FLAGS 0x2D6
    tzcnt r14w, r12w
    mov rsi, 0xFFFFFFFFFFFFFFFF
    mov r10, 0x3
    FLAGS 0x202
    tzcnt si, r10w
    mov r14, 0x81
    mov r15, 0xFFFFFFFF80000000
    FLAGS 0xA82
    tzcnt r14w, r15w
    mov rdx, 0x8000000000000000
    mov rdi, 0x100000000
    FLAGS 0xA82
    tzcnt dx, di
    mov rdi, 0xB2838EC63AB434A4
    mov rax, 0x0
    FLAGS 0x246
    tzcnt edi, eax
    mov r12, 0xBBD952772128671E
    mov r9, 0x1
    FLAGS 0xA02
    tzcnt r12d, r9d
    mov r14, 0xFFFFFFFFFFFFFF80
    mov rax, 0x8000
    FLAGS 0x203
    tzcnt r14d, eax
    mov r9, 0xFFFFFFFF
    mov r15, 0x80000000
    FLAGS 0x202
    tzcnt r9d, r15d
    mov r10, 0xDC724D20B240B9A4
    mov r14, 0x8000000000000000
    FLAGS 0xAD7
    tzcnt r10d, r14d
    mov r8, 0xFFFFFFFFFFFFFFCC
    mov rbp, 0x7FFFFFFFFFFFFFFF
    FLAGS 0x203
    tzcnt r8d, ebp
    mov rcx, 0x7F
    mov r12, 0xFFFFFFFFFFFFFF4E
    FLAGS 0x2D6
    tzcnt ecx, r12d
    mov r14, 0x81
    mov rbx, 0x7FFF
    FLAGS 0x297
    tzcnt r14d, ebx
    mov rdi, 0x9D3F42702539E47
    mov r9, 0x0
    FLAGS 0x2D6
    tzcnt rdi, r9
    mov rsi, 0x7FFFFFFF
    mov r10, 0x1
    FLAGS 0x2D6
    tzcnt rsi, r10
    mov rdx, 0xBFD3C49B20909114
    mov rcx, 0x8000
    FLAGS 0xA03
    tzcnt rdx, rcx
    mov rcx, 0xFFFFFFFF
    mov r14, 0x80000000
    FLAGS 0xA43
    tzcnt rcx, r14
    mov rbp, 0x7FFF
    mov rcx, 0x8000000000000000
    FLAGS 0xA03
    tzcnt rbp, rcx
    mov r8, 0x7FFFFFFF
    mov r10, 0xFFFF
    FLAGS 0x202
    tzcnt r8, r10
    mov r14, 0xACE82B2B47355BB3
    mov rdx, 0xFFFFFFFF
    FLAGS 0x212
    tzcnt r14, rdx
    mov r11, 0x14E77301EC356B43
    mov rcx, 0xFFFFFFFFFFFFFF42
    FLAGS 0xA02
    tzcnt r11, rcx
    mov rax, 0xA81503A94B9646C8
    mov rcx, 0x0
    FLAGS 0x297
    lzcnt ax, cx
    mov r10, 0x0
    mov r11, 0x1
    FLAGS 0x213
    lzcnt r10w, r11w
    mov r11, 0x63D7ABB6CF2D17F3
    mov rbp, 0x8000
    FLAGS 0x297
    lzcnt r11w, bp
    mov r13, 0x8000
    mov r14, 0x80000000
    FLAGS 0x213
    lzcnt r13w, r14w
    mov r8, 0x1
    mov rsi, 0x8000000000000000
    FLAGS 0x213
    lzcnt r8w, si
    mov r15, 0x91380BB19E77E84A
    mov rcx, 0xC2778C21F1F6A930
    FLAGS 0xA82
    lzcnt r15w, cx
    mov rbp, 0xA205CCC4AB3B9D51
    mov r14, 0x7F
    FLAGS 0x297
    lzcnt bp, r14w
    mov rcx, 0x10000
    mov r15, 0x3
    FLAGS 0x246
    lzcnt cx, r15w
    mov rcx, 0xFFFFFFFFFFFFFFDD
    mov rbp, 0x0
    FLAGS 0x213
    lzcnt ecx, ebp
    mov rbx, 0xDB7966C1BEB74164
    mov r8, 0x1
    FLAGS 0xAD7
    lzcnt ebx, r8d
    mov rbp, 0x3EE030D6D83B208C
    mov r9, 0x8000
    FLAGS 0x213
    lzcnt ebp, r9d
    mov r10, 0xD97C735FB9F179E6
    mov r11, 0x80000000
    FLAGS 0x212
    lzcnt r10d, r11d
    mov r13, 0xFFFFFFFF
    mov r10, 0x8000000000000000
    FLAGS 0xAD7
    lzcnt r13d, r10d
    mov r8, 0xFFFFFFFF
    mov r12, 0x8000000000000000
    FLAGS 0x213
    lzcnt r8d, r12d
    mov rsi, 0xAE85EEC9BFC0E9DA
    mov rbx, 0x7F
    FLAGS 0x246
    lzcnt esi, ebx
    mov r12, 0x8000000000000000
    mov rcx, 0x8000000000000000
    FLAGS 0x246
    lzcnt r12d, ecx
    mov rbx, 0x100
    mov rbp, 0x0
    FLAGS 0xA82
    lzcnt rbx, rbp
    mov r13, 0x535614CEA588145F
    mov r11, 0x1
    FLAGS 0x246
    lzcnt r13, r11
    mov rax, 0x10000
    mov rsi, 0x8000
    FLAGS 0xAD7
    lzcnt rax, rsi
    mov r8, 0x97
    mov rsi, 0x80000000
    FLAGS 0x202
    lzcnt r8, rsi
    mov rax, 0x7FFFFFFF
    mov r14, 0x8000000000000000
    FLAGS 0x297
    lzcnt rax, r14
    mov rdx, 0xFFFF
    mov r8, 0x0
    FLAGS 0x212
    lzcnt rdx, r8
    mov rdi, 0xFFFFFFFFFFFFFF80
    mov rsi, 0xFFFFFFFF80000000
    FLAGS 0x212
    lzcnt rdi, rsi
    mov r11, 0x3
    mov rax, 0x36DA54E725B38F52
    FLAGS 0xA82
    lzcnt r11, rax
    mov r13, 0xFFFFFFFF
    bswap r13d
    mov r15, 0x74
    bswap r15d
    mov rsi, 0x100
    bswap esi
    mov r11, 0x9445350A7B8C6B68
    bswap r11d
    mov rax, 0x2CD7997CE2CB4331
    bswap rax
    mov rbx, 0x81
    bswap rbx
    mov r14, 0x41
    bswap r14
    mov r11, 0x100000000
    bswap r11
    mov rdx, 0xF7B841F389FDBC89
    mov rbp, 0x1B25D3C9B5231E18
    mov rax, 0xF7B841F389FDBC89
    FLAGS 0x2D6
    cmpxchg dl, bpl
    mov [buf], rdx
    FLAGS 0x203
    lock cmpxchg [buf], bpl
    mov rdx, [buf]
    mov rdx, 0xFFFFFFFFFFFFFF38
    FLAGS 0x213
    xadd dl, bpl
    xadd [buf], bpl
    mov rdx, [buf]
    mov rcx, 0x2D5CC9F529C60AF0
    mov r15, 0xFFFFFFFFFFFFFF36
    mov rax, 0x7FFFFFFFFFFFFFFF
    FLAGS 0xA82
    cmpxchg cl, r15b
    mov [buf], rcx
    FLAGS 0x246
    lock cmpxchg [buf], r15b
    mov rcx, [buf]
    mov rcx, 0x9B78560B2CF1AA6C
    FLAGS 0x212
    xadd cl, r15b
    xadd [buf], r15b
    mov rcx, [buf]
    mov rcx, 0xA5AA62F897E6A440
    mov r14, 0x4BE41F4EDFA4F0B6
    mov rax, 0xA5AA62F897E6A440
    FLAGS 0xA43
    cmpxchg cl, r14b
    mov [buf], rcx
    FLAGS 0x2D6
    lock cmpxchg [buf], r14b
    mov rcx, [buf]
    mov rcx, 0xA9481E2F30F3BC3A
    FLAGS 0x202
    xadd cl, r14b
    xadd [buf], r14b
    mov rcx, [buf]
    mov r11, 0x15
    mov r9, 0xFFFF
    mov rax, 0x1
    FLAGS 0x203
    cmpxchg r11b, r9b
    mov [buf], r11
    FLAGS 0xA02
    lock cmpxchg [buf], r9b
    mov r11, [buf]
    mov r11, 0x17
    FLAGS 0x297
    xadd r11b, r9b
    xadd [buf], r9b
    mov r11, [buf]
    mov r12, 0xFFFFFFFF
    mov r8, 0x7FFFFFFF
    mov rax, 0xFFFFFFFF
    FLAGS 0x297
    cmpxchg r12w, r8w
    mov [buf], r12
    FLAGS 0x212
    lock cmpxchg [buf], r8w
    mov r12, [buf]
    mov r12, 0x2BE86DB3615456DB
    FLAGS 0x297
    xadd r12w, r8w
    xadd [buf], r8w
    mov r12, [buf]
    mov r15, 0x8000000000000000
    mov r8, 0x80000000
    mov rax, 0xFFFFFFFFFFFFFFB5
    FLAGS 0xA43
    cmpxchg r15w, r8w
    mov [buf], r15
    FLAGS 0xA02
    lock cmpxchg [buf], r8w
    mov r15, [buf]
    mov r15, 0x8000
    FLAGS 0x297
    xadd r15w, r8w
    xadd [buf], r8w
    mov r15, [buf]
    mov rdx, 0x7FFFFFFFFFFFFFFF
    mov r8, 0xAAF830F6E9671168
    mov rax, 0x7FFFFFFFFFFFFFFF
    FLAGS 0xA02
    cmpxchg dx, r8w
    mov [buf], rdx
    FLAGS 0x2D6
    lock cmpxchg [buf], r8w
    mov rdx, [buf]
    mov rdx, 0xE6ADEDFAEDE93173
    FLAGS 0x297
    xadd dx, r8w
    xadd [buf], r8w
    mov rdx, [buf]
    mov r13, 0x72
    mov r14, 0x100
    mov rax, 0xFFFFFFFF80000000
    FLAGS 0x212
    cmpxchg r13w, r14w
    mov [buf], r13
    FLAGS 0x203
    lock cmpxchg [buf], r14w
    mov r13, [buf]
    mov r13, 0x726D1CF7F7A13AA4
    FLAGS 0x2D6
    xadd r13w, r14w
    xadd [buf], r14w
    mov r13, [buf]
    mov r13, 0x437A1C56A8BCF0EF
    mov rbp, 0xFFFFFFFF80000000
    mov rax, 0x437A1C56A8BCF0EF
    FLAGS 0x212
    cmpxchg r13d, ebp
    mov [buf], r13
    FLAGS 0xA02
    lock cmpxchg [buf], ebp
    mov r13, [buf]
    mov r13, 0x8000
    FLAGS 0xA02
    xadd r13d, ebp
    xadd [buf], ebp
    mov r13, [buf]
    mov r15, 0x8000
    mov r14, 0xAE2D8B3734A29A5D
    mov rax, 0xD2
    FLAGS 0xA02
    cmpxchg r15d, r14d
    mov [buf], r15
    FLAGS 0x203
    lock cmpxchg [buf], r14d
    mov r15, [buf]
    mov r15, 0xE1CCE0EA79668C19
    FLAGS 0x202
    xadd r15d, r14d
    xadd [buf], r14d
    mov r15, [buf]
    mov rdi, 0xFFFFFFFF80000000
    mov rsi, 0x8000
    mov rax, 0xFFFFFFFF80000000
    FLAGS 0x212
    cmpxchg edi, esi
    mov [buf], rdi
    FLAGS 0x246
    lock cmpxchg [buf], esi
    mov rdi, [buf]
    mov rdi, 0xC9CC2AAE689F702D
    FLAGS 0xAD7
    xadd edi, esi
    xadd [buf], esi
    mov rdi, [buf]
    mov r8, 0xC4
    mov r14, 0x573465047CCE0F42
    mov rax, 0xE2FBBC5BA6C23FBA
    FLAGS 0x202
    cmpxchg r8d, r14d
    mov [buf], r8
    FLAGS 0xAD7
    lock cmpxchg [buf], r14d
    mov r8, [buf]
    mov r8, 0xF27291E92A7B84C2
    FLAGS 0x212
    xadd r8d, r14d
    xadd [buf], r14d
    mov r8, [buf]
    mov r9, 0xCB8F4095246B9FCB
    mov r14, 0xFFA8BC8E930EBF97
    mov rax, 0xCB8F4095246B9FCB
    FLAGS 0xAD7
    cmpxchg r9, r14
    mov [buf], r9
    FLAGS 0x202
    lock cmpxchg [buf], r14
    mov r9, [buf]
    mov r9, 0x0
    FLAGS 0x203
    xadd r9, r14
    xadd [buf], r14
    mov r9, [buf]
    mov r8, 0x8000000000000000
    mov rbp, 0xEB81C04D23252D9F
    mov rax, 0x7FFFFFFFFFFFFFFF
    FLAGS 0x246
    cmpxchg r8, rbp
    mov [buf], r8
    FLAGS 0xA43
    lock cmpxchg [buf], rbp
    mov r8, [buf]
    mov r8, 0x8E
    FLAGS 0x203
    xadd r8, rbp
    xadd [buf], rbp
    mov r8, [buf]
    mov rbx, 0x100
    mov r15, 0x3FA654EE5C6040A
    mov rax, 0x100
    FLAGS 0x213
    cmpxchg rbx, r15
    mov [buf], rbx
    FLAGS 0x212
    lock cmpxchg [buf], r15
    mov rbx, [buf]
    mov rbx, 0xD63D28906E301E94
    FLAGS 0x297
    xadd rbx, r15
    xadd [buf], r15
    mov rbx, [buf]
    mov rbp, 0xFF
    mov r14, 0x7FFF
    mov rax, 0x1
    FLAGS 0xA03
    cmpxchg rbp, r14
    mov [buf], rbp
    FLAGS 0x203
    lock cmpxchg [buf], r14
    mov rbp, [buf]
    mov rbp, 0x1
    FLAGS 0x212
    xadd rbp, r14
    xadd [buf], r14
    mov rbp, [buf]
    mov rax, 0x7FFF
    mov rdx, 0x2DD8D6A9BA0ED72B
    mov rbx, 0xAE4A61DA4670F8E3
    mov rcx, 0xFFFFFFFFFFFFFF80
    mov rsi, 0x7FFF
    mov rdi, 0x2DD8D6A9BA0ED72B
    mov [buf + 32], esi
    mov [buf + 36], edi
    mov eax, eax
    mov edx, edx
    FLAGS 0x297
    cmpxchg8b [buf + 32]
    mov rsi, [buf + 32]
    mov rdi, [buf + 40]
    mov rax, 0x2
    mov rdx, 0x2
    mov rbx, 0xEC7F543DC00EBC48
    mov rcx, 0xFFFFFFFFFFFFFFBB
    mov rsi, 0x100000002
    mov rdi, 0x2
    mov [buf + 32], esi
    mov [buf + 36], edi
    mov eax, eax
    mov edx, edx
    FLAGS 0x213
    cmpxchg8b [buf + 32]
    mov rsi, [buf + 32]
    mov rdi, [buf + 40]
    mov rax, 0x1
    mov rdx, 0xFFFFFFFFFFFFFF3D
    mov rbx, 0xFFFFFFFFFFFFFF7E
    mov rcx, 0xF5782A2EF62C321B
    mov rsi, 0x1
    mov rdi, 0xFFFFFFFFFFFFFF3D
    mov [buf + 32], rsi
    mov [buf + 40], rdi
    FLAGS 0x202
    cmpxchg16b [buf + 32]
    mov rsi, [buf + 32]
    mov rdi, [buf + 40]
    mov rax, 0x6E7B8E335527BFCC
    mov rdx, 0xABC119767306F64F
    mov rbx, 0xFF
    mov rcx, 0xDD8F5FF29F291E9
    mov rsi, 0x6E7B8E325527BFCC
    mov rdi, 0xABC119767306F64F
    mov [buf + 32], rsi
    mov [buf + 40], rdi
    FLAGS 0xA43
    cmpxchg16b [buf + 32]
    mov rsi, [buf + 32]
    mov rdi, [buf + 40]
    EXIT
    align 16
buf: times 64 dq 0x0123456789ABCDEF
file_end:
