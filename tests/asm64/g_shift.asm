; Shifts and rotates at every width, by a constant, by one and by CL, with counts past the width; SHLD and SHRD.
; Written by tools/gen64_tests.py: change that, not this.
%include "elf.inc"
    mov rbp, 0x81
    FLAGS 0x203
    rol bpl, 0
    mov rbp, 0xFFFFFFFFFFFFFFAC
    mov ecx, 0
    FLAGS 0x203
    rol bpl, cl
    mov rbx, 0x9FDCCEBBF4A8A377
    FLAGS 0x297
    rol bl, 1
    mov rbx, 0xFFFFFFFF80000000
    mov ecx, 1
    FLAGS 0x2D6
    rol bl, cl
    mov r8, 0x100
    FLAGS 0xA43
    rol r8b, 2
    mov r8, 0x184B887D299A75B3
    mov ecx, 2
    FLAGS 0x203
    rol r8b, cl
    mov rax, 0xB7F9D94570793A27
    FLAGS 0x213
    rol al, 3
    mov rax, 0xFA
    mov ecx, 3
    FLAGS 0x2D6
    rol al, cl
    mov r15, 0xFBD4EDF097BB35C4
    FLAGS 0x213
    rol r15b, 7
    mov r15, 0x99
    mov ecx, 7
    FLAGS 0xA82
    rol r15b, cl
    mov r9, 0xFD45C1F0DB209E44
    FLAGS 0x297
    rol r9b, 8
    mov r9, 0x889E1C0CE33F2FD7
    mov ecx, 8
    FLAGS 0xA03
    rol r9b, cl
    mov r9, 0x100
    FLAGS 0xA82
    rol r9b, 9
    mov r9, 0x2
    mov ecx, 9
    FLAGS 0x203
    rol r9b, cl
    mov rbp, 0x892C2A5F51D1DB88
    FLAGS 0x2D6
    rol bpl, 15
    mov rbp, 0xCF28FD127D180B17
    mov ecx, 15
    FLAGS 0xAD7
    rol bpl, cl
    mov r13, 0x100000000
    FLAGS 0x2D6
    rol r13b, 16
    mov r13, 0x947A1684E7A40FDF
    mov ecx, 16
    FLAGS 0x213
    rol r13b, cl
    mov r15, 0xCF13E7CA0048C542
    FLAGS 0xA02
    rol r15b, 17
    mov r15, 0x2
    mov ecx, 17
    FLAGS 0x297
    rol r15b, cl
    mov r10, 0x81
    FLAGS 0xAD7
    rol r10b, 31
    mov r10, 0x80000000
    mov ecx, 31
    FLAGS 0x202
    rol r10b, cl
    mov r12, 0x7FFFFFFFFFFFFFFF
    FLAGS 0x297
    rol r12b, 32
    mov r12, 0x1
    mov ecx, 32
    FLAGS 0x2D6
    rol r12b, cl
    mov rdi, 0xFFFFFFFFFFFFFF10
    FLAGS 0xA82
    rol dil, 33
    mov rdi, 0xFFFFFFFFFFFFFFFF
    mov ecx, 33
    FLAGS 0xA82
    rol dil, cl
    mov rax, 0x2EB3B5AD00BA2825
    FLAGS 0x212
    rol al, 63
    mov rax, 0x2
    mov ecx, 63
    FLAGS 0xA03
    rol al, cl
    mov r13, 0xFF
    FLAGS 0xA03
    rol r13b, 64
    mov r13, 0x3
    mov ecx, 64
    FLAGS 0x212
    rol r13b, cl
    mov rax, 0xFFFFFFFFFFFFFF6F
    FLAGS 0xA43
    rol al, 65
    mov rax, 0x7FFFFFFF
    mov ecx, 65
    FLAGS 0x2D6
    rol al, cl
    mov rbp, 0x1
    FLAGS 0x212
    rol bpl, 255
    mov rbp, 0x5179777132031DCF
    mov ecx, 255
    FLAGS 0x246
    rol bpl, cl
    mov rax, 0xE9
    mov [buf], rax
    FLAGS 0x246
    rol byte [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x212
    rol byte [buf], cl
    mov rax, [buf]
    FLAGS 0xA03
    rol byte [buf], 1
    mov rax, [buf]
    mov r15, 0x1
    FLAGS 0x246
    rol r15w, 0
    mov r15, 0x100000000
    mov ecx, 0
    FLAGS 0x203
    rol r15w, cl
    mov r10, 0xFFFFFFFFFFFFFFFF
    FLAGS 0xAD7
    rol r10w, 1
    mov r10, 0xFFFFFFFF
    mov ecx, 1
    FLAGS 0xA02
    rol r10w, cl
    mov r15, 0xEF2CE185FDAB60
    FLAGS 0x297
    rol r15w, 2
    mov r15, 0x81
    mov ecx, 2
    FLAGS 0x213
    rol r15w, cl
    mov r9, 0xF9CB606AC61A5406
    FLAGS 0xA82
    rol r9w, 3
    mov r9, 0x7AE9A21801C6D81C
    mov ecx, 3
    FLAGS 0x2D6
    rol r9w, cl
    mov rbx, 0xA336DFF075B5C913
    FLAGS 0x212
    rol bx, 7
    mov rbx, 0x39D96D0A5D46ED80
    mov ecx, 7
    FLAGS 0x297
    rol bx, cl
    mov rbp, 0x3
    FLAGS 0x203
    rol bp, 8
    mov rbp, 0x8000
    mov ecx, 8
    FLAGS 0xA03
    rol bp, cl
    mov r8, 0x8DA51EB71316EC79
    FLAGS 0xA82
    rol r8w, 9
    mov r8, 0x4EC0075E4B162236
    mov ecx, 9
    FLAGS 0x2D6
    rol r8w, cl
    mov rsi, 0x0
    FLAGS 0xA02
    rol si, 15
    mov rsi, 0x80
    mov ecx, 15
    FLAGS 0x246
    rol si, cl
    mov r8, 0x9C82CA96B145BB7D
    FLAGS 0x202
    rol r8w, 16
    mov r8, 0x90E3F1650F6438BE
    mov ecx, 16
    FLAGS 0xA82
    rol r8w, cl
    mov r8, 0x3
    FLAGS 0x212
    rol r8w, 17
    mov r8, 0x100
    mov ecx, 17
    FLAGS 0xAD7
    rol r8w, cl
    mov r15, 0x7F
    FLAGS 0xA02
    rol r15w, 31
    mov r15, 0x4FF5009379D2B3CE
    mov ecx, 31
    FLAGS 0x212
    rol r15w, cl
    mov r11, 0xFFFFFFFFFFFFFF21
    FLAGS 0x297
    rol r11w, 32
    mov r11, 0xDF2BB6AD23D20859
    mov ecx, 32
    FLAGS 0x202
    rol r11w, cl
    mov r10, 0xFFFFFFFFFFFFFFFF
    FLAGS 0xA43
    rol r10w, 33
    mov r10, 0xF6666F751FC116CC
    mov ecx, 33
    FLAGS 0xA82
    rol r10w, cl
    mov r8, 0xFFFFFFFFFFFFFFF9
    FLAGS 0xAD7
    rol r8w, 63
    mov r8, 0xFFFFFFFFFFFFFFFF
    mov ecx, 63
    FLAGS 0xA43
    rol r8w, cl
    mov rbp, 0x80000000
    FLAGS 0xA02
    rol bp, 64
    mov rbp, 0xFFFFFFFFFFFFFFCF
    mov ecx, 64
    FLAGS 0x213
    rol bp, cl
    mov r12, 0xFFFFFFFFFFFFFF1C
    FLAGS 0x202
    rol r12w, 65
    mov r12, 0x81
    mov ecx, 65
    FLAGS 0x297
    rol r12w, cl
    mov rdi, 0x740C9BF3B723982D
    FLAGS 0xA03
    rol di, 255
    mov rdi, 0x17
    mov ecx, 255
    FLAGS 0x297
    rol di, cl
    mov rax, 0x3D
    mov [buf], rax
    FLAGS 0xA03
    rol word [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x202
    rol word [buf], cl
    mov rax, [buf]
    FLAGS 0x212
    rol word [buf], 1
    mov rax, [buf]
    mov r11, 0x100
    FLAGS 0xA03
    rol r11d, 0
    mov r11, 0xFFFFFFFFFFFFFFFF
    mov ecx, 0
    FLAGS 0x246
    rol r11d, cl
    mov r11, 0xFFFFFFFFFFFFFFCB
    FLAGS 0xA03
    rol r11d, 1
    mov r11, 0xF92A4163B3C6E1EF
    mov ecx, 1
    FLAGS 0x246
    rol r11d, cl
    mov rdx, 0x7FFF
    FLAGS 0xA82
    rol edx, 2
    mov rdx, 0xFFFF
    mov ecx, 2
    FLAGS 0x2D6
    rol edx, cl
    mov r11, 0x854C1264352E385E
    FLAGS 0x297
    rol r11d, 3
    mov r11, 0xFFFFFFFF80000000
    mov ecx, 3
    FLAGS 0x213
    rol r11d, cl
    mov rdi, 0x7FFFFFFF
    FLAGS 0xAD7
    rol edi, 7
    mov rdi, 0xD2
    mov ecx, 7
    FLAGS 0xA82
    rol edi, cl
    mov r8, 0x69272D3B87615CF5
    FLAGS 0xAD7
    rol r8d, 8
    mov r8, 0x5215C618FED2C513
    mov ecx, 8
    FLAGS 0x2D6
    rol r8d, cl
    mov rax, 0xA8A54236C8030461
    FLAGS 0xA02
    rol eax, 9
    mov rax, 0x59
    mov ecx, 9
    FLAGS 0xA43
    rol eax, cl
    mov rdx, 0x3
    FLAGS 0xA43
    rol edx, 15
    mov rdx, 0x2
    mov ecx, 15
    FLAGS 0xA43
    rol edx, cl
    mov r12, 0x3
    FLAGS 0xA43
    rol r12d, 16
    mov r12, 0x7FFFFFFF
    mov ecx, 16
    FLAGS 0xA02
    rol r12d, cl
    mov r12, 0x4AD035DB0B117619
    FLAGS 0xA02
    rol r12d, 17
    mov r12, 0x5C
    mov ecx, 17
    FLAGS 0x213
    rol r12d, cl
    mov r9, 0x1C1080210DBEEF9B
    FLAGS 0xA02
    rol r9d, 31
    mov r9, 0x9AFBBAE7E929B140
    mov ecx, 31
    FLAGS 0xA43
    rol r9d, cl
    mov rbp, 0x8000000000000000
    FLAGS 0x213
    rol ebp, 32
    mov rbp, 0x8B
    mov ecx, 32
    FLAGS 0xA02
    rol ebp, cl
    mov rbx, 0x7C57916D5AD7998A
    FLAGS 0xA02
    rol ebx, 33
    mov rbx, 0x81
    mov ecx, 33
    FLAGS 0xAD7
    rol ebx, cl
    mov r12, 0x791DC225DA347BB6
    FLAGS 0xA43
    rol r12d, 63
    mov r12, 0x1
    mov ecx, 63
    FLAGS 0x246
    rol r12d, cl
    mov rsi, 0xFFFFFFFFFFFFFF80
    FLAGS 0x297
    rol esi, 64
    mov rsi, 0xFFFFFFFFFFFFFF19
    mov ecx, 64
    FLAGS 0x203
    rol esi, cl
    mov rdi, 0xFFFF
    FLAGS 0xAD7
    rol edi, 65
    mov rdi, 0xC631572FAD039EF0
    mov ecx, 65
    FLAGS 0xAD7
    rol edi, cl
    mov rax, 0x10000
    FLAGS 0x202
    rol eax, 255
    mov rax, 0x46E4E0CFDBEDA77B
    mov ecx, 255
    FLAGS 0x246
    rol eax, cl
    mov rax, 0xAAE6A1739DD52EF4
    mov [buf], rax
    FLAGS 0x213
    rol dword [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0xA43
    rol dword [buf], cl
    mov rax, [buf]
    FLAGS 0x203
    rol dword [buf], 1
    mov rax, [buf]
    mov r14, 0xFD55B382B5424484
    FLAGS 0x2D6
    rol r14, 0
    mov r14, 0xFFFFFFFFFFFFFFAB
    mov ecx, 0
    FLAGS 0xA02
    rol r14, cl
    mov r9, 0x76626270BEB7A087
    FLAGS 0x246
    rol r9, 1
    mov r9, 0x1
    mov ecx, 1
    FLAGS 0x246
    rol r9, cl
    mov r9, 0xB6CB95D50165FEBA
    FLAGS 0xA43
    rol r9, 2
    mov r9, 0x2D5C475CC3D5A143
    mov ecx, 2
    FLAGS 0xA03
    rol r9, cl
    mov r9, 0x8000000000000000
    FLAGS 0xA02
    rol r9, 3
    mov r9, 0xFFFF
    mov ecx, 3
    FLAGS 0xA03
    rol r9, cl
    mov r9, 0xFFFFFFFF
    FLAGS 0xA03
    rol r9, 7
    mov r9, 0x100000000
    mov ecx, 7
    FLAGS 0x2D6
    rol r9, cl
    mov r13, 0x6C4424D4201B601B
    FLAGS 0x2D6
    rol r13, 8
    mov r13, 0xB4B5AA470690E04C
    mov ecx, 8
    FLAGS 0x203
    rol r13, cl
    mov rax, 0xA8
    FLAGS 0x246
    rol rax, 9
    mov rax, 0x40
    mov ecx, 9
    FLAGS 0x246
    rol rax, cl
    mov r11, 0xFFFFFFFFFFFFFF80
    FLAGS 0xAD7
    rol r11, 15
    mov r11, 0x100
    mov ecx, 15
    FLAGS 0xAD7
    rol r11, cl
    mov r11, 0xF02A5D4EF40A8DB6
    FLAGS 0x297
    rol r11, 16
    mov r11, 0x38FBF7FD56F1B892
    mov ecx, 16
    FLAGS 0x212
    rol r11, cl
    mov r11, 0x75632D1064A6BCA
    FLAGS 0xA03
    rol r11, 17
    mov r11, 0x100
    mov ecx, 17
    FLAGS 0xA43
    rol r11, cl
    mov r12, 0xB34F17F288231FA7
    FLAGS 0x203
    rol r12, 31
    mov r12, 0x81
    mov ecx, 31
    FLAGS 0x297
    rol r12, cl
    mov r15, 0x100
    FLAGS 0x212
    rol r15, 32
    mov r15, 0xFFFFFFFFFFFFFF16
    mov ecx, 32
    FLAGS 0x297
    rol r15, cl
    mov rbx, 0xFFFFFFFFFFFFFFDB
    FLAGS 0xA82
    rol rbx, 33
    mov rbx, 0x8000000000000000
    mov ecx, 33
    FLAGS 0xA43
    rol rbx, cl
    mov rbp, 0x7F
    FLAGS 0x246
    rol rbp, 63
    mov rbp, 0x100
    mov ecx, 63
    FLAGS 0x212
    rol rbp, cl
    mov rdi, 0xFFFF
    FLAGS 0xA02
    rol rdi, 64
    mov rdi, 0xFFFFFFFFFFFFFFD2
    mov ecx, 64
    FLAGS 0xA02
    rol rdi, cl
    mov rsi, 0x7FFF
    FLAGS 0xA82
    rol rsi, 65
    mov rsi, 0x5E563C42276FC2F0
    mov ecx, 65
    FLAGS 0x213
    rol rsi, cl
    mov r8, 0x10000
    FLAGS 0x297
    rol r8, 255
    mov r8, 0xFF
    mov ecx, 255
    FLAGS 0x203
    rol r8, cl
    mov rax, 0xFFFFFFFF80000000
    mov [buf], rax
    FLAGS 0x2D6
    rol qword [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x2D6
    rol qword [buf], cl
    mov rax, [buf]
    FLAGS 0xA43
    rol qword [buf], 1
    mov rax, [buf]
    mov r9, 0x100
    FLAGS 0x297
    ror r9b, 0
    mov r9, 0x4
    mov ecx, 0
    FLAGS 0x2D6
    ror r9b, cl
    mov rax, 0x100000000
    FLAGS 0xA43
    ror al, 1
    mov rax, 0xE16BCE0DDC6A88D7
    mov ecx, 1
    FLAGS 0x2D6
    ror al, cl
    mov r15, 0x57
    FLAGS 0x2D6
    ror r15b, 2
    mov r15, 0xFD98C10BAF535BD7
    mov ecx, 2
    FLAGS 0x297
    ror r15b, cl
    mov r13, 0xFFFF
    FLAGS 0x297
    ror r13b, 3
    mov r13, 0xFF
    mov ecx, 3
    FLAGS 0x213
    ror r13b, cl
    mov r12, 0x8000000000000000
    FLAGS 0x212
    ror r12b, 7
    mov r12, 0x1169C1F7C24473DD
    mov ecx, 7
    FLAGS 0x297
    ror r12b, cl
    mov rbp, 0x8000
    FLAGS 0x2D6
    ror bpl, 8
    mov rbp, 0xE69091553477608B
    mov ecx, 8
    FLAGS 0x212
    ror bpl, cl
    mov rax, 0x7FFFFFFF
    FLAGS 0x202
    ror al, 9
    mov rax, 0x8000000000000000
    mov ecx, 9
    FLAGS 0x297
    ror al, cl
    mov r14, 0x100000000
    FLAGS 0xA03
    ror r14b, 15
    mov r14, 0xDC75E1E6165752EB
    mov ecx, 15
    FLAGS 0xA02
    ror r14b, cl
    mov rbx, 0xFB55FE1024828B18
    FLAGS 0x203
    ror bl, 16
    mov rbx, 0xE3
    mov ecx, 16
    FLAGS 0xA43
    ror bl, cl
    mov rbp, 0xCC
    FLAGS 0xA02
    ror bpl, 17
    mov rbp, 0x1
    mov ecx, 17
    FLAGS 0x2D6
    ror bpl, cl
    mov rdx, 0x84FA8BE90CCAF57A
    FLAGS 0x2D6
    ror dl, 31
    mov rdx, 0x100
    mov ecx, 31
    FLAGS 0x212
    ror dl, cl
    mov r11, 0x1
    FLAGS 0xA82
    ror r11b, 32
    mov r11, 0x88067E37B917C52F
    mov ecx, 32
    FLAGS 0xA43
    ror r11b, cl
    mov rdi, 0x5BC08B6E7759A1A6
    FLAGS 0xA03
    ror dil, 33
    mov rdi, 0xDFC95F2A6E52A855
    mov ecx, 33
    FLAGS 0xA82
    ror dil, cl
    mov r10, 0x7FFFFFFFFFFFFFFF
    FLAGS 0x213
    ror r10b, 63
    mov r10, 0x100000000
    mov ecx, 63
    FLAGS 0xA43
    ror r10b, cl
    mov r9, 0xFFFFFFFFFFFFFF6B
    FLAGS 0x212
    ror r9b, 64
    mov r9, 0x100
    mov ecx, 64
    FLAGS 0xAD7
    ror r9b, cl
    mov r13, 0xD686F5E0673493B
    FLAGS 0x297
    ror r13b, 65
    mov r13, 0x10000
    mov ecx, 65
    FLAGS 0x2D6
    ror r13b, cl
    mov r13, 0xF974A9ADEF6666BE
    FLAGS 0xAD7
    ror r13b, 255
    mov r13, 0x56ADFA98AEED3924
    mov ecx, 255
    FLAGS 0xA43
    ror r13b, cl
    mov rax, 0x0
    mov [buf], rax
    FLAGS 0x213
    ror byte [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0xA82
    ror byte [buf], cl
    mov rax, [buf]
    FLAGS 0xA43
    ror byte [buf], 1
    mov rax, [buf]
    mov r13, 0xDD03BBB6C1971418
    FLAGS 0x246
    ror r13w, 0
    mov r13, 0x7F
    mov ecx, 0
    FLAGS 0x203
    ror r13w, cl
    mov r14, 0x9B49E653CF78F97D
    FLAGS 0xA02
    ror r14w, 1
    mov r14, 0xC7
    mov ecx, 1
    FLAGS 0x2D6
    ror r14w, cl
    mov rsi, 0x0
    FLAGS 0x2D6
    ror si, 2
    mov rsi, 0x3
    mov ecx, 2
    FLAGS 0x212
    ror si, cl
    mov rsi, 0xB74F2F9651EF5577
    FLAGS 0x203
    ror si, 3
    mov rsi, 0xE4
    mov ecx, 3
    FLAGS 0x2D6
    ror si, cl
    mov r14, 0xA071E1EB05960AEB
    FLAGS 0x246
    ror r14w, 7
    mov r14, 0x0
    mov ecx, 7
    FLAGS 0xA03
    ror r14w, cl
    mov r11, 0x3
    FLAGS 0xA02
    ror r11w, 8
    mov r11, 0x100
    mov ecx, 8
    FLAGS 0x203
    ror r11w, cl
    mov r10, 0x7FFFFFFFFFFFFFFF
    FLAGS 0xA02
    ror r10w, 9
    mov r10, 0x5835AE9C2E4A9598
    mov ecx, 9
    FLAGS 0x203
    ror r10w, cl
    mov r11, 0xFFFFFFFFFFFFFFC4
    FLAGS 0x297
    ror r11w, 15
    mov r11, 0xAF6BE9C3CB8CD3EF
    mov ecx, 15
    FLAGS 0x213
    ror r11w, cl
    mov r13, 0x5D0861951079080D
    FLAGS 0x213
    ror r13w, 16
    mov r13, 0xFFFFFFFFFFFFFFBC
    mov ecx, 16
    FLAGS 0x212
    ror r13w, cl
    mov r13, 0x7FFFFFFF
    FLAGS 0xA82
    ror r13w, 17
    mov r13, 0x81
    mov ecx, 17
    FLAGS 0x213
    ror r13w, cl
    mov r14, 0x71
    FLAGS 0x297
    ror r14w, 31
    mov r14, 0xFFFFFFFFFFFFFF80
    mov ecx, 31
    FLAGS 0xA03
    ror r14w, cl
    mov rdx, 0x864DCA456D4E764D
    FLAGS 0x202
    ror dx, 32
    mov rdx, 0x88
    mov ecx, 32
    FLAGS 0x213
    ror dx, cl
    mov r14, 0x3
    FLAGS 0x297
    ror r14w, 33
    mov r14, 0xFFFFFFFFFFFFFF11
    mov ecx, 33
    FLAGS 0x203
    ror r14w, cl
    mov r11, 0x100
    FLAGS 0xA02
    ror r11w, 63
    mov r11, 0xD05B767E6B811FFB
    mov ecx, 63
    FLAGS 0x202
    ror r11w, cl
    mov r15, 0x1
    FLAGS 0xA02
    ror r15w, 64
    mov r15, 0x815B312CFEBBEF15
    mov ecx, 64
    FLAGS 0xA43
    ror r15w, cl
    mov r15, 0x0
    FLAGS 0xA82
    ror r15w, 65
    mov r15, 0xFFFFFFFFFFFFFF00
    mov ecx, 65
    FLAGS 0x246
    ror r15w, cl
    mov rdx, 0x83BC02B8A46840EA
    FLAGS 0xA43
    ror dx, 255
    mov rdx, 0x7FFFFFFF
    mov ecx, 255
    FLAGS 0xA03
    ror dx, cl
    mov rax, 0x541A5F6EA4AFE868
    mov [buf], rax
    FLAGS 0x297
    ror word [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0xAD7
    ror word [buf], cl
    mov rax, [buf]
    FLAGS 0xA02
    ror word [buf], 1
    mov rax, [buf]
    mov rbx, 0xAA
    FLAGS 0xA02
    ror ebx, 0
    mov rbx, 0x9F0A7242A4A75226
    mov ecx, 0
    FLAGS 0xA02
    ror ebx, cl
    mov r9, 0x7F
    FLAGS 0xA03
    ror r9d, 1
    mov r9, 0xD9
    mov ecx, 1
    FLAGS 0x202
    ror r9d, cl
    mov r9, 0x422F7852AEAE64D5
    FLAGS 0xA03
    ror r9d, 2
    mov r9, 0xFFFFFFFF80000000
    mov ecx, 2
    FLAGS 0x297
    ror r9d, cl
    mov rbx, 0xFFFFFFFFFFFFFF1C
    FLAGS 0xA43
    ror ebx, 3
    mov rbx, 0x731B3D0E7BDE8CFC
    mov ecx, 3
    FLAGS 0x203
    ror ebx, cl
    mov r15, 0xA71DEB54D079B3D1
    FLAGS 0x202
    ror r15d, 7
    mov r15, 0x117470EA24E1A5AF
    mov ecx, 7
    FLAGS 0x202
    ror r15d, cl
    mov r9, 0x81
    FLAGS 0xA02
    ror r9d, 8
    mov r9, 0x55FD0EDE39026144
    mov ecx, 8
    FLAGS 0x297
    ror r9d, cl
    mov r14, 0x7F
    FLAGS 0x212
    ror r14d, 9
    mov r14, 0xD4
    mov ecx, 9
    FLAGS 0x203
    ror r14d, cl
    mov r15, 0x314C5B4F3DF20411
    FLAGS 0x246
    ror r15d, 15
    mov r15, 0x52874FDD72AB25F0
    mov ecx, 15
    FLAGS 0x297
    ror r15d, cl
    mov r11, 0x713C3D5D80541F40
    FLAGS 0x2D6
    ror r11d, 16
    mov r11, 0x80000000
    mov ecx, 16
    FLAGS 0x212
    ror r11d, cl
    mov r11, 0x98E6566232E3809
    FLAGS 0xA02
    ror r11d, 17
    mov r11, 0x7F
    mov ecx, 17
    FLAGS 0x2D6
    ror r11d, cl
    mov rax, 0xFFFFFFFFFFFFFF4F
    FLAGS 0x202
    ror eax, 31
    mov rax, 0x80
    mov ecx, 31
    FLAGS 0xA43
    ror eax, cl
    mov rdx, 0xFF
    FLAGS 0x212
    ror edx, 32
    mov rdx, 0xB5D8ED9B6C383C2C
    mov ecx, 32
    FLAGS 0x297
    ror edx, cl
    mov r14, 0xFF
    FLAGS 0x212
    ror r14d, 33
    mov r14, 0x0
    mov ecx, 33
    FLAGS 0x213
    ror r14d, cl
    mov rsi, 0xC945FCF4806CBD6
    FLAGS 0x202
    ror esi, 63
    mov rsi, 0xFFFF
    mov ecx, 63
    FLAGS 0x246
    ror esi, cl
    mov r14, 0x10000
    FLAGS 0x212
    ror r14d, 64
    mov r14, 0xFFFF
    mov ecx, 64
    FLAGS 0x297
    ror r14d, cl
    mov r8, 0xFF
    FLAGS 0xAD7
    ror r8d, 65
    mov r8, 0xFFFFFFFF
    mov ecx, 65
    FLAGS 0x246
    ror r8d, cl
    mov r14, 0x15
    FLAGS 0x2D6
    ror r14d, 255
    mov r14, 0xD1563B71DA4C8EDC
    mov ecx, 255
    FLAGS 0x297
    ror r14d, cl
    mov rax, 0xFFFFFFFFFFFFFF88
    mov [buf], rax
    FLAGS 0x202
    ror dword [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0xA03
    ror dword [buf], cl
    mov rax, [buf]
    FLAGS 0xA82
    ror dword [buf], 1
    mov rax, [buf]
    mov r15, 0xE47F12A4BC7876D1
    FLAGS 0xA02
    ror r15, 0
    mov r15, 0x80
    mov ecx, 0
    FLAGS 0x297
    ror r15, cl
    mov r8, 0xED
    FLAGS 0x297
    ror r8, 1
    mov r8, 0x2A279E8FF8C61D82
    mov ecx, 1
    FLAGS 0x246
    ror r8, cl
    mov rdi, 0x8000
    FLAGS 0x202
    ror rdi, 2
    mov rdi, 0xFFFFFFFFFFFFFFC9
    mov ecx, 2
    FLAGS 0x202
    ror rdi, cl
    mov rdx, 0xFFFFFFFF80000000
    FLAGS 0x203
    ror rdx, 3
    mov rdx, 0x80
    mov ecx, 3
    FLAGS 0x212
    ror rdx, cl
    mov rbp, 0x81
    FLAGS 0xA03
    ror rbp, 7
    mov rbp, 0xFFFF
    mov ecx, 7
    FLAGS 0xA43
    ror rbp, cl
    mov rax, 0xD3D0D2952B075F54
    FLAGS 0xA82
    ror rax, 8
    mov rax, 0x89870BC8D6079203
    mov ecx, 8
    FLAGS 0xA02
    ror rax, cl
    mov r12, 0x7E1C2DD91450A1EE
    FLAGS 0x212
    ror r12, 9
    mov r12, 0x6468FE3F5BF50576
    mov ecx, 9
    FLAGS 0xA82
    ror r12, cl
    mov rax, 0xFFFFFFFF80000000
    FLAGS 0xA02
    ror rax, 15
    mov rax, 0x7C4C821392FAE24E
    mov ecx, 15
    FLAGS 0xA02
    ror rax, cl
    mov r10, 0xFFFF
    FLAGS 0x2D6
    ror r10, 16
    mov r10, 0x1402889B60C0CEF2
    mov ecx, 16
    FLAGS 0x212
    ror r10, cl
    mov r14, 0x100
    FLAGS 0x2D6
    ror r14, 17
    mov r14, 0x9C2D9135ADA2A3E7
    mov ecx, 17
    FLAGS 0xA43
    ror r14, cl
    mov r8, 0x7FFFFFFFFFFFFFFF
    FLAGS 0x202
    ror r8, 31
    mov r8, 0x2E
    mov ecx, 31
    FLAGS 0xA02
    ror r8, cl
    mov rax, 0xC139916EDE8B1583
    FLAGS 0x246
    ror rax, 32
    mov rax, 0x2FCD4F8903188C4B
    mov ecx, 32
    FLAGS 0x2D6
    ror rax, cl
    mov rdx, 0x100
    FLAGS 0xAD7
    ror rdx, 33
    mov rdx, 0xC8B5092D2D2AEB9E
    mov ecx, 33
    FLAGS 0x212
    ror rdx, cl
    mov r8, 0x81
    FLAGS 0xA82
    ror r8, 63
    mov r8, 0x100
    mov ecx, 63
    FLAGS 0xA82
    ror r8, cl
    mov rbp, 0x2
    FLAGS 0xA43
    ror rbp, 64
    mov rbp, 0x80000000
    mov ecx, 64
    FLAGS 0xA03
    ror rbp, cl
    mov r13, 0xFFFF
    FLAGS 0xA03
    ror r13, 65
    mov r13, 0xE473B633AFBA2920
    mov ecx, 65
    FLAGS 0x246
    ror r13, cl
    mov r15, 0x58BDF0D1B34D30BA
    FLAGS 0x246
    ror r15, 255
    mov r15, 0xEB49C9BB56D5F0ED
    mov ecx, 255
    FLAGS 0x202
    ror r15, cl
    mov rax, 0xFFFFFFFFFFFFFF3C
    mov [buf], rax
    FLAGS 0xA82
    ror qword [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0xA02
    ror qword [buf], cl
    mov rax, [buf]
    FLAGS 0x203
    ror qword [buf], 1
    mov rax, [buf]
    mov rax, 0xFFFFFFFFFFFFFFFF
    FLAGS 0xA82
    rcl al, 0
    mov rax, 0xFFFF
    mov ecx, 0
    FLAGS 0x297
    rcl al, cl
    mov rbx, 0x692C256043B8FF5D
    FLAGS 0xA02
    rcl bl, 1
    mov rbx, 0x100
    mov ecx, 1
    FLAGS 0xAD7
    rcl bl, cl
    mov rsi, 0xB6A6A65211234B4D
    FLAGS 0xAD7
    rcl sil, 2
    mov rsi, 0x7FFFFFFFFFFFFFFF
    mov ecx, 2
    FLAGS 0x246
    rcl sil, cl
    mov r8, 0x2656B43A791F73C1
    FLAGS 0xA03
    rcl r8b, 3
    mov r8, 0xFF
    mov ecx, 3
    FLAGS 0x203
    rcl r8b, cl
    mov r12, 0xCE3328D03D5E6D1E
    FLAGS 0x246
    rcl r12b, 7
    mov r12, 0x7C54E4BE5D1CD366
    mov ecx, 7
    FLAGS 0x2D6
    rcl r12b, cl
    mov r11, 0x75779690584C7846
    FLAGS 0xA02
    rcl r11b, 8
    mov r11, 0x80969AD5AE42D8BA
    mov ecx, 8
    FLAGS 0xA02
    rcl r11b, cl
    mov r15, 0xFFFFFFFFFFFFFF6A
    FLAGS 0xA82
    rcl r15b, 9
    mov r15, 0x9878D04306B0AB8F
    mov ecx, 9
    FLAGS 0x213
    rcl r15b, cl
    mov r13, 0x100
    FLAGS 0x246
    rcl r13b, 15
    mov r13, 0xFFFFFFFF80000000
    mov ecx, 15
    FLAGS 0x2D6
    rcl r13b, cl
    mov r9, 0xEE667799048053D0
    FLAGS 0x212
    rcl r9b, 16
    mov r9, 0x70
    mov ecx, 16
    FLAGS 0x212
    rcl r9b, cl
    mov rax, 0x19
    FLAGS 0x203
    rcl al, 17
    mov rax, 0xFF
    mov ecx, 17
    FLAGS 0xA02
    rcl al, cl
    mov r12, 0xB7
    FLAGS 0x213
    rcl r12b, 31
    mov r12, 0xF69505C8030D5665
    mov ecx, 31
    FLAGS 0x297
    rcl r12b, cl
    mov rdx, 0xFFFF
    FLAGS 0x2D6
    rcl dl, 32
    mov rdx, 0xFFFFFFFFFFFFFFFF
    mov ecx, 32
    FLAGS 0x297
    rcl dl, cl
    mov r11, 0x7FFF
    FLAGS 0x2D6
    rcl r11b, 33
    mov r11, 0x3FE44F9B1C24FA3C
    mov ecx, 33
    FLAGS 0x297
    rcl r11b, cl
    mov r9, 0xAF
    FLAGS 0xA02
    rcl r9b, 63
    mov r9, 0xFF
    mov ecx, 63
    FLAGS 0xA43
    rcl r9b, cl
    mov r14, 0xEE99410D9314CCE6
    FLAGS 0xA43
    rcl r14b, 64
    mov r14, 0x80
    mov ecx, 64
    FLAGS 0x203
    rcl r14b, cl
    mov rbx, 0xFFFFFFFFFFFFFF65
    FLAGS 0x213
    rcl bl, 65
    mov rbx, 0x38E3168F831A4ABB
    mov ecx, 65
    FLAGS 0xA02
    rcl bl, cl
    mov r8, 0xD66CB8F659B36CFC
    FLAGS 0xA02
    rcl r8b, 255
    mov r8, 0xD8
    mov ecx, 255
    FLAGS 0x246
    rcl r8b, cl
    mov rax, 0xFFFFFFFF80000000
    mov [buf], rax
    FLAGS 0x212
    rcl byte [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0xA02
    rcl byte [buf], cl
    mov rax, [buf]
    FLAGS 0xA03
    rcl byte [buf], 1
    mov rax, [buf]
    mov rsi, 0x37EB4B7C4E04E759
    FLAGS 0xA43
    rcl si, 0
    mov rsi, 0xFFFFFFFFFFFFFF4C
    mov ecx, 0
    FLAGS 0x202
    rcl si, cl
    mov rsi, 0xFFFFFFFF80000000
    FLAGS 0x203
    rcl si, 1
    mov rsi, 0x7FFFFFFF
    mov ecx, 1
    FLAGS 0x203
    rcl si, cl
    mov r9, 0x10000
    FLAGS 0xA03
    rcl r9w, 2
    mov r9, 0x10
    mov ecx, 2
    FLAGS 0xA02
    rcl r9w, cl
    mov r11, 0x7FEAAE2A665BED3A
    FLAGS 0x246
    rcl r11w, 3
    mov r11, 0xBCB274B96C81B25B
    mov ecx, 3
    FLAGS 0xA82
    rcl r11w, cl
    mov r11, 0xD0C71076E163659B
    FLAGS 0xA43
    rcl r11w, 7
    mov r11, 0xFFFFFFFF
    mov ecx, 7
    FLAGS 0x246
    rcl r11w, cl
    mov r14, 0x29DD635ADA65E1A0
    FLAGS 0x202
    rcl r14w, 8
    mov r14, 0x8000000000000000
    mov ecx, 8
    FLAGS 0x212
    rcl r14w, cl
    mov r12, 0x80000000
    FLAGS 0x203
    rcl r12w, 9
    mov r12, 0xAE2B70CA904350E4
    mov ecx, 9
    FLAGS 0xA82
    rcl r12w, cl
    mov rax, 0xE0
    FLAGS 0xA02
    rcl ax, 15
    mov rax, 0x100000000
    mov ecx, 15
    FLAGS 0xA02
    rcl ax, cl
    mov r14, 0x32
    FLAGS 0xA82
    rcl r14w, 16
    mov r14, 0xFFFFFFFFFFFFFFFF
    mov ecx, 16
    FLAGS 0x297
    rcl r14w, cl
    mov r14, 0x2
    FLAGS 0xA03
    rcl r14w, 17
    mov r14, 0xFD9C6757DDE4223C
    mov ecx, 17
    FLAGS 0x297
    rcl r14w, cl
    mov r13, 0x80000000
    FLAGS 0xAD7
    rcl r13w, 31
    mov r13, 0x8000
    mov ecx, 31
    FLAGS 0x212
    rcl r13w, cl
    mov r13, 0x66682375D2D76C1
    FLAGS 0x213
    rcl r13w, 32
    mov r13, 0xD8CC14447F4724A8
    mov ecx, 32
    FLAGS 0x2D6
    rcl r13w, cl
    mov r9, 0x3B81F4CFE51C019B
    FLAGS 0xAD7
    rcl r9w, 33
    mov r9, 0x9FC6DFD6A9C200C4
    mov ecx, 33
    FLAGS 0x246
    rcl r9w, cl
    mov r12, 0x1
    FLAGS 0xA02
    rcl r12w, 63
    mov r12, 0x678B354E2A460A23
    mov ecx, 63
    FLAGS 0xA82
    rcl r12w, cl
    mov r14, 0x8000000000000000
    FLAGS 0xA03
    rcl r14w, 64
    mov r14, 0xFFFFFFFF80000000
    mov ecx, 64
    FLAGS 0xA82
    rcl r14w, cl
    mov r15, 0x4E
    FLAGS 0xA82
    rcl r15w, 65
    mov r15, 0x3
    mov ecx, 65
    FLAGS 0xA43
    rcl r15w, cl
    mov rax, 0xDEE40F434344F782
    FLAGS 0x2D6
    rcl ax, 255
    mov rax, 0x80000000
    mov ecx, 255
    FLAGS 0xA03
    rcl ax, cl
    mov rax, 0x4836CA6C5E6B6F6F
    mov [buf], rax
    FLAGS 0x213
    rcl word [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x297
    rcl word [buf], cl
    mov rax, [buf]
    FLAGS 0xA03
    rcl word [buf], 1
    mov rax, [buf]
    mov r9, 0xFDC6A755FF3ABF97
    FLAGS 0x297
    rcl r9d, 0
    mov r9, 0xFFFFFFFFFFFFFFFF
    mov ecx, 0
    FLAGS 0x246
    rcl r9d, cl
    mov rbx, 0xA4286D813E5ED8AE
    FLAGS 0x203
    rcl ebx, 1
    mov rbx, 0xFFFFFFFF80000000
    mov ecx, 1
    FLAGS 0x212
    rcl ebx, cl
    mov r13, 0x1C1FB797DD7A4AE3
    FLAGS 0xA02
    rcl r13d, 2
    mov r13, 0x63BAE08CB7C403AB
    mov ecx, 2
    FLAGS 0x203
    rcl r13d, cl
    mov r12, 0x8000000000000000
    FLAGS 0x297
    rcl r12d, 3
    mov r12, 0x2
    mov ecx, 3
    FLAGS 0x297
    rcl r12d, cl
    mov r13, 0x100
    FLAGS 0xA43
    rcl r13d, 7
    mov r13, 0xAD27B118B557B935
    mov ecx, 7
    FLAGS 0xAD7
    rcl r13d, cl
    mov r9, 0x7F
    FLAGS 0xA82
    rcl r9d, 8
    mov r9, 0x3
    mov ecx, 8
    FLAGS 0xA03
    rcl r9d, cl
    mov r13, 0x10000
    FLAGS 0x246
    rcl r13d, 9
    mov r13, 0x100000000
    mov ecx, 9
    FLAGS 0x202
    rcl r13d, cl
    mov r10, 0xFFFFFFFFFFFFFFD8
    FLAGS 0x212
    rcl r10d, 15
    mov r10, 0x5B746E5ED97FDB9B
    mov ecx, 15
    FLAGS 0x202
    rcl r10d, cl
    mov rdi, 0xA91401FE515ED55F
    FLAGS 0xAD7
    rcl edi, 16
    mov rdi, 0x7FFFFFFF
    mov ecx, 16
    FLAGS 0xA03
    rcl edi, cl
    mov r9, 0x3
    FLAGS 0xA03
    rcl r9d, 17
    mov r9, 0x100000000
    mov ecx, 17
    FLAGS 0xA02
    rcl r9d, cl
    mov r8, 0x5227C19C9EA4A62F
    FLAGS 0xA82
    rcl r8d, 31
    mov r8, 0xD1
    mov ecx, 31
    FLAGS 0x212
    rcl r8d, cl
    mov r11, 0xBAE33EC2E612BB7
    FLAGS 0x297
    rcl r11d, 32
    mov r11, 0xFFFFFFFF80000000
    mov ecx, 32
    FLAGS 0xA02
    rcl r11d, cl
    mov rdx, 0x1045ADDE72B49E2E
    FLAGS 0x212
    rcl edx, 33
    mov rdx, 0xFFFFFFFFFFFFFFCA
    mov ecx, 33
    FLAGS 0x2D6
    rcl edx, cl
    mov r15, 0x100
    FLAGS 0x213
    rcl r15d, 63
    mov r15, 0x45
    mov ecx, 63
    FLAGS 0x213
    rcl r15d, cl
    mov r14, 0x3A8E21EB42995B7
    FLAGS 0x213
    rcl r14d, 64
    mov r14, 0xFFFFFFFF
    mov ecx, 64
    FLAGS 0x203
    rcl r14d, cl
    mov r11, 0x8000
    FLAGS 0xA82
    rcl r11d, 65
    mov r11, 0x3
    mov ecx, 65
    FLAGS 0x297
    rcl r11d, cl
    mov rbp, 0x6F6408F911C91DFE
    FLAGS 0xA02
    rcl ebp, 255
    mov rbp, 0x1
    mov ecx, 255
    FLAGS 0xA03
    rcl ebp, cl
    mov rax, 0x875A8426FA90F6F2
    mov [buf], rax
    FLAGS 0xA02
    rcl dword [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x212
    rcl dword [buf], cl
    mov rax, [buf]
    FLAGS 0xA03
    rcl dword [buf], 1
    mov rax, [buf]
    mov r9, 0x97F72D6A16213248
    FLAGS 0x202
    rcl r9, 0
    mov r9, 0x7FFFFFFF
    mov ecx, 0
    FLAGS 0x212
    rcl r9, cl
    mov r11, 0xFFFFFFFFFFFFFF80
    FLAGS 0x203
    rcl r11, 1
    mov r11, 0x6FC31C0AF96EB970
    mov ecx, 1
    FLAGS 0x2D6
    rcl r11, cl
    mov rdi, 0xF6
    FLAGS 0xA03
    rcl rdi, 2
    mov rdi, 0xF48283BD883BB24E
    mov ecx, 2
    FLAGS 0x246
    rcl rdi, cl
    mov r10, 0xFA025743ECE7E3C5
    FLAGS 0x202
    rcl r10, 3
    mov r10, 0x7F
    mov ecx, 3
    FLAGS 0x212
    rcl r10, cl
    mov r9, 0x3E
    FLAGS 0xA82
    rcl r9, 7
    mov r9, 0x522CBC3F17602819
    mov ecx, 7
    FLAGS 0x212
    rcl r9, cl
    mov rax, 0xFFFFFFFFFFFFFFFF
    FLAGS 0xA03
    rcl rax, 8
    mov rax, 0xFFFFFFFFFFFFFF93
    mov ecx, 8
    FLAGS 0x297
    rcl rax, cl
    mov r11, 0x73536B4AC5E7C4D4
    FLAGS 0x297
    rcl r11, 9
    mov r11, 0x80
    mov ecx, 9
    FLAGS 0xA02
    rcl r11, cl
    mov r14, 0xFFFFFFFFFFFFFFFF
    FLAGS 0x2D6
    rcl r14, 15
    mov r14, 0x9D54F4560E626EFA
    mov ecx, 15
    FLAGS 0xA03
    rcl r14, cl
    mov r13, 0xFFFFFFFFFFFFFFFF
    FLAGS 0x202
    rcl r13, 16
    mov r13, 0xFFFFFFFF
    mov ecx, 16
    FLAGS 0x297
    rcl r13, cl
    mov rbx, 0x80000000
    FLAGS 0xAD7
    rcl rbx, 17
    mov rbx, 0x80000000
    mov ecx, 17
    FLAGS 0x202
    rcl rbx, cl
    mov r8, 0x100000000
    FLAGS 0x202
    rcl r8, 31
    mov r8, 0x7A7EB85A77E822CB
    mov ecx, 31
    FLAGS 0x246
    rcl r8, cl
    mov rbp, 0xDAD73410EC3793D7
    FLAGS 0xA43
    rcl rbp, 32
    mov rbp, 0xFFFFFFFFFFFFFF80
    mov ecx, 32
    FLAGS 0x212
    rcl rbp, cl
    mov rdi, 0x88050FB1A83DE0A5
    FLAGS 0xA43
    rcl rdi, 33
    mov rdi, 0xA63AF75590652B8D
    mov ecx, 33
    FLAGS 0x203
    rcl rdi, cl
    mov rax, 0x15B5A96EE92A3838
    FLAGS 0xA82
    rcl rax, 63
    mov rax, 0xA4020275EEEFF12
    mov ecx, 63
    FLAGS 0xA02
    rcl rax, cl
    mov r15, 0x7FFF
    FLAGS 0x202
    rcl r15, 64
    mov r15, 0x6958DB25A2E0B241
    mov ecx, 64
    FLAGS 0xA03
    rcl r15, cl
    mov r10, 0xFFFFFFFFFFFFFF33
    FLAGS 0x213
    rcl r10, 65
    mov r10, 0x81
    mov ecx, 65
    FLAGS 0xAD7
    rcl r10, cl
    mov r10, 0x8000
    FLAGS 0x297
    rcl r10, 255
    mov r10, 0xFF
    mov ecx, 255
    FLAGS 0x212
    rcl r10, cl
    mov rax, 0x1
    mov [buf], rax
    FLAGS 0x203
    rcl qword [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x297
    rcl qword [buf], cl
    mov rax, [buf]
    FLAGS 0x212
    rcl qword [buf], 1
    mov rax, [buf]
    mov rdx, 0xA45538731844C547
    FLAGS 0xA82
    rcr dl, 0
    mov rdx, 0x81
    mov ecx, 0
    FLAGS 0xA02
    rcr dl, cl
    mov rdi, 0xFFFFFFFF80000000
    FLAGS 0x2D6
    rcr dil, 1
    mov rdi, 0xFFFFFFFFFFFFFF89
    mov ecx, 1
    FLAGS 0x202
    rcr dil, cl
    mov r15, 0xB7001C190CB6237B
    FLAGS 0x212
    rcr r15b, 2
    mov r15, 0x7FFFFFFF
    mov ecx, 2
    FLAGS 0x246
    rcr r15b, cl
    mov r8, 0x84E1D2358443673A
    FLAGS 0x246
    rcr r8b, 3
    mov r8, 0xD8859009BF8BC150
    mov ecx, 3
    FLAGS 0x202
    rcr r8b, cl
    mov r14, 0xFFFFFFFFFFFFFFB8
    FLAGS 0xA03
    rcr r14b, 7
    mov r14, 0x9A75F6BD2C3C70A1
    mov ecx, 7
    FLAGS 0x2D6
    rcr r14b, cl
    mov r11, 0x90F21528BB03C10E
    FLAGS 0x297
    rcr r11b, 8
    mov r11, 0xB901A8AAE885502B
    mov ecx, 8
    FLAGS 0x246
    rcr r11b, cl
    mov r11, 0x80000000
    FLAGS 0xA43
    rcr r11b, 9
    mov r11, 0xFFFFFFFFFFFFFF80
    mov ecx, 9
    FLAGS 0x212
    rcr r11b, cl
    mov r8, 0xFFFFFFFF80000000
    FLAGS 0x2D6
    rcr r8b, 15
    mov r8, 0xEF41AA1A243AC6C
    mov ecx, 15
    FLAGS 0xAD7
    rcr r8b, cl
    mov r10, 0xFF
    FLAGS 0xA02
    rcr r10b, 16
    mov r10, 0x3
    mov ecx, 16
    FLAGS 0xA82
    rcr r10b, cl
    mov r9, 0x7FFFFFFFFFFFFFFF
    FLAGS 0x246
    rcr r9b, 17
    mov r9, 0x80
    mov ecx, 17
    FLAGS 0xA02
    rcr r9b, cl
    mov r14, 0x19F9765930EEC889
    FLAGS 0x297
    rcr r14b, 31
    mov r14, 0x49
    mov ecx, 31
    FLAGS 0x212
    rcr r14b, cl
    mov rsi, 0xFFFFFFFFFFFFFF7F
    FLAGS 0xAD7
    rcr sil, 32
    mov rsi, 0x3630652C7AEC8A8E
    mov ecx, 32
    FLAGS 0x297
    rcr sil, cl
    mov r14, 0x100
    FLAGS 0x202
    rcr r14b, 33
    mov r14, 0xEF36B630F1E6F20
    mov ecx, 33
    FLAGS 0x2D6
    rcr r14b, cl
    mov r10, 0x2AC4BBC34E80B99E
    FLAGS 0xA43
    rcr r10b, 63
    mov r10, 0x21B8DF38007D99E0
    mov ecx, 63
    FLAGS 0xA43
    rcr r10b, cl
    mov r11, 0x68C7360BB860F774
    FLAGS 0xA03
    rcr r11b, 64
    mov r11, 0x7FFFFFFF
    mov ecx, 64
    FLAGS 0x213
    rcr r11b, cl
    mov r12, 0x1D264C0E63EE39B2
    FLAGS 0xA02
    rcr r12b, 65
    mov r12, 0x80
    mov ecx, 65
    FLAGS 0xA43
    rcr r12b, cl
    mov rdi, 0x80
    FLAGS 0xA02
    rcr dil, 255
    mov rdi, 0x2F683E00C1814A94
    mov ecx, 255
    FLAGS 0x213
    rcr dil, cl
    mov rax, 0x80000000
    mov [buf], rax
    FLAGS 0xA43
    rcr byte [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x213
    rcr byte [buf], cl
    mov rax, [buf]
    FLAGS 0xA82
    rcr byte [buf], 1
    mov rax, [buf]
    mov r12, 0x7FFF
    FLAGS 0x213
    rcr r12w, 0
    mov r12, 0xCD87A01AC78106DA
    mov ecx, 0
    FLAGS 0xA43
    rcr r12w, cl
    mov rbp, 0xFEDC6F72F7D1C37C
    FLAGS 0x2D6
    rcr bp, 1
    mov rbp, 0xFFFFFFFFFFFFFFD8
    mov ecx, 1
    FLAGS 0xA82
    rcr bp, cl
    mov rbx, 0x10000
    FLAGS 0x202
    rcr bx, 2
    mov rbx, 0x1
    mov ecx, 2
    FLAGS 0x202
    rcr bx, cl
    mov rbx, 0xFFFFFFFFFFFFFFCD
    FLAGS 0x212
    rcr bx, 3
    mov rbx, 0x7FFFFFFF
    mov ecx, 3
    FLAGS 0xAD7
    rcr bx, cl
    mov rdi, 0xFFFFFFFFFFFFFFA3
    FLAGS 0x213
    rcr di, 7
    mov rdi, 0xFFFFFFFFFFFFFF5C
    mov ecx, 7
    FLAGS 0x2D6
    rcr di, cl
    mov r10, 0xEA
    FLAGS 0xA82
    rcr r10w, 8
    mov r10, 0xE9BE5797BBA33284
    mov ecx, 8
    FLAGS 0x246
    rcr r10w, cl
    mov rax, 0x5CAF6C85A71011E5
    FLAGS 0x246
    rcr ax, 9
    mov rax, 0x8F
    mov ecx, 9
    FLAGS 0xA43
    rcr ax, cl
    mov rax, 0xFFFFFFFFFFFFFFFF
    FLAGS 0x202
    rcr ax, 15
    mov rax, 0x3B
    mov ecx, 15
    FLAGS 0xA02
    rcr ax, cl
    mov rsi, 0x10C251996BAC6F3
    FLAGS 0xA43
    rcr si, 16
    mov rsi, 0x100
    mov ecx, 16
    FLAGS 0xA43
    rcr si, cl
    mov r11, 0x10000
    FLAGS 0x212
    rcr r11w, 17
    mov r11, 0x4005E1DD02E9C0A8
    mov ecx, 17
    FLAGS 0x2D6
    rcr r11w, cl
    mov r11, 0x34752000AF81D981
    FLAGS 0x213
    rcr r11w, 31
    mov r11, 0xF5C4F4A293BC924D
    mov ecx, 31
    FLAGS 0x246
    rcr r11w, cl
    mov r15, 0x2
    FLAGS 0xA43
    rcr r15w, 32
    mov r15, 0xFFFFFFFFFFFFFF80
    mov ecx, 32
    FLAGS 0xA82
    rcr r15w, cl
    mov r10, 0x3
    FLAGS 0xA82
    rcr r10w, 33
    mov r10, 0x3CF9F66133D4608D
    mov ecx, 33
    FLAGS 0x2D6
    rcr r10w, cl
    mov rax, 0x2
    FLAGS 0xA82
    rcr ax, 63
    mov rax, 0x6A
    mov ecx, 63
    FLAGS 0xA03
    rcr ax, cl
    mov r14, 0xFFFF
    FLAGS 0xAD7
    rcr r14w, 64
    mov r14, 0x4F21E4C898D0D9AC
    mov ecx, 64
    FLAGS 0x246
    rcr r14w, cl
    mov r14, 0x7F
    FLAGS 0x246
    rcr r14w, 65
    mov r14, 0x4BB2564348E19EC3
    mov ecx, 65
    FLAGS 0xA03
    rcr r14w, cl
    mov r12, 0xFFFFFFFFFFFFFF55
    FLAGS 0x203
    rcr r12w, 255
    mov r12, 0x8AF0D72350E61428
    mov ecx, 255
    FLAGS 0x297
    rcr r12w, cl
    mov rax, 0x7FFFFFFF
    mov [buf], rax
    FLAGS 0xA82
    rcr word [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x212
    rcr word [buf], cl
    mov rax, [buf]
    FLAGS 0x246
    rcr word [buf], 1
    mov rax, [buf]
    mov r15, 0x4731DE33F89C3729
    FLAGS 0xA02
    rcr r15d, 0
    mov r15, 0x791B5477C7570B3B
    mov ecx, 0
    FLAGS 0xAD7
    rcr r15d, cl
    mov r13, 0x80000000
    FLAGS 0x213
    rcr r13d, 1
    mov r13, 0xFFFFFFFFFFFFFFBC
    mov ecx, 1
    FLAGS 0xA43
    rcr r13d, cl
    mov r11, 0xFFFFFFFF
    FLAGS 0x297
    rcr r11d, 2
    mov r11, 0x4FF1813696A0A360
    mov ecx, 2
    FLAGS 0x212
    rcr r11d, cl
    mov r9, 0xE6622530B2FA68B8
    FLAGS 0xA02
    rcr r9d, 3
    mov r9, 0x2AF063EBDAEF705B
    mov ecx, 3
    FLAGS 0xA43
    rcr r9d, cl
    mov r12, 0x16155CD8545CA48E
    FLAGS 0xA82
    rcr r12d, 7
    mov r12, 0xDE
    mov ecx, 7
    FLAGS 0xA43
    rcr r12d, cl
    mov r12, 0xEE5A6BB0009540D
    FLAGS 0xA43
    rcr r12d, 8
    mov r12, 0x325AEDAE24F83AA1
    mov ecx, 8
    FLAGS 0xA03
    rcr r12d, cl
    mov r9, 0x36
    FLAGS 0x297
    rcr r9d, 9
    mov r9, 0xFFFFFFFFFFFFFF0B
    mov ecx, 9
    FLAGS 0xA02
    rcr r9d, cl
    mov r13, 0xFF
    FLAGS 0xA02
    rcr r13d, 15
    mov r13, 0xB0E9CD966A14798B
    mov ecx, 15
    FLAGS 0xA02
    rcr r13d, cl
    mov rbp, 0xF822283DF5FA90BD
    FLAGS 0x2D6
    rcr ebp, 16
    mov rbp, 0xFFFFFFFFFFFFFF9B
    mov ecx, 16
    FLAGS 0x2D6
    rcr ebp, cl
    mov r15, 0xFFFFFFFFFFFFFF29
    FLAGS 0x212
    rcr r15d, 17
    mov r15, 0xFFFFFFFFFFFFFF80
    mov ecx, 17
    FLAGS 0xA43
    rcr r15d, cl
    mov rsi, 0x7
    FLAGS 0x203
    rcr esi, 31
    mov rsi, 0x8000
    mov ecx, 31
    FLAGS 0x202
    rcr esi, cl
    mov r9, 0x1
    FLAGS 0x213
    rcr r9d, 32
    mov r9, 0x80
    mov ecx, 32
    FLAGS 0xA43
    rcr r9d, cl
    mov r10, 0xFFFFFFFFFFFFFF4F
    FLAGS 0xAD7
    rcr r10d, 33
    mov r10, 0x7FFFFFFF
    mov ecx, 33
    FLAGS 0x203
    rcr r10d, cl
    mov r15, 0x0
    FLAGS 0xA43
    rcr r15d, 63
    mov r15, 0x3278D531ECFEF050
    mov ecx, 63
    FLAGS 0x213
    rcr r15d, cl
    mov r15, 0xD13BD70517889DCF
    FLAGS 0x246
    rcr r15d, 64
    mov r15, 0x5133F5AF10F5181A
    mov ecx, 64
    FLAGS 0x246
    rcr r15d, cl
    mov rax, 0x1
    FLAGS 0x2D6
    rcr eax, 65
    mov rax, 0xFFFFFFFFFFFFFF11
    mov ecx, 65
    FLAGS 0x212
    rcr eax, cl
    mov r9, 0xFFFFFFFFFFFFFF80
    FLAGS 0x297
    rcr r9d, 255
    mov r9, 0xFFFFFFFFFFFFFF25
    mov ecx, 255
    FLAGS 0x297
    rcr r9d, cl
    mov rax, 0xAABFD95D598E5BDD
    mov [buf], rax
    FLAGS 0x203
    rcr dword [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0xA43
    rcr dword [buf], cl
    mov rax, [buf]
    FLAGS 0x213
    rcr dword [buf], 1
    mov rax, [buf]
    mov rdx, 0x7FFFFFFF
    FLAGS 0xA82
    rcr rdx, 0
    mov rdx, 0xFFFFFFFF80000000
    mov ecx, 0
    FLAGS 0xAD7
    rcr rdx, cl
    mov r9, 0x81
    FLAGS 0x203
    rcr r9, 1
    mov r9, 0x3396AD788AD0F2BE
    mov ecx, 1
    FLAGS 0xA03
    rcr r9, cl
    mov r11, 0xAAF6915E62B2D2F
    FLAGS 0xA02
    rcr r11, 2
    mov r11, 0x0
    mov ecx, 2
    FLAGS 0xA02
    rcr r11, cl
    mov rbp, 0xFFFFFFFF
    FLAGS 0x203
    rcr rbp, 3
    mov rbp, 0xED
    mov ecx, 3
    FLAGS 0x246
    rcr rbp, cl
    mov r13, 0x75910E814FB913DE
    FLAGS 0xA43
    rcr r13, 7
    mov r13, 0x813939A627CFFAA
    mov ecx, 7
    FLAGS 0xA03
    rcr r13, cl
    mov r9, 0xAF78DB89CFCDD657
    FLAGS 0x212
    rcr r9, 8
    mov r9, 0xFFFFFFFF80000000
    mov ecx, 8
    FLAGS 0x297
    rcr r9, cl
    mov r8, 0xFFFFFFFFFFFFFFEF
    FLAGS 0x203
    rcr r8, 9
    mov r8, 0xFFFFFFFF80000000
    mov ecx, 9
    FLAGS 0x213
    rcr r8, cl
    mov r10, 0x9012324A89DA9775
    FLAGS 0xA82
    rcr r10, 15
    mov r10, 0xA581D1C1216824EA
    mov ecx, 15
    FLAGS 0xA02
    rcr r10, cl
    mov rsi, 0x7FFFFFFFFFFFFFFF
    FLAGS 0xA02
    rcr rsi, 16
    mov rsi, 0xFFFFFFFFFFFFFFBA
    mov ecx, 16
    FLAGS 0x203
    rcr rsi, cl
    mov r9, 0xFFFFFFFF
    FLAGS 0x213
    rcr r9, 17
    mov r9, 0x100000000
    mov ecx, 17
    FLAGS 0x246
    rcr r9, cl
    mov r9, 0x907C20FE5F41A394
    FLAGS 0xA43
    rcr r9, 31
    mov r9, 0x4E0F7DC91D7F4031
    mov ecx, 31
    FLAGS 0x202
    rcr r9, cl
    mov r12, 0x73F41C67249C6547
    FLAGS 0xAD7
    rcr r12, 32
    mov r12, 0x768A28DC4875C6CF
    mov ecx, 32
    FLAGS 0x202
    rcr r12, cl
    mov rdx, 0xADE6E543E75CD4CF
    FLAGS 0xA03
    rcr rdx, 33
    mov rdx, 0xA3
    mov ecx, 33
    FLAGS 0xA03
    rcr rdx, cl
    mov r9, 0x82DF0D4ADB15E6EC
    FLAGS 0x213
    rcr r9, 63
    mov r9, 0xA5BC795D3D21A123
    mov ecx, 63
    FLAGS 0x2D6
    rcr r9, cl
    mov r15, 0x71134BF1E393BB9B
    FLAGS 0x297
    rcr r15, 64
    mov r15, 0xFFFFFFFFFFFFFFCB
    mov ecx, 64
    FLAGS 0xAD7
    rcr r15, cl
    mov r12, 0x100000000
    FLAGS 0x202
    rcr r12, 65
    mov r12, 0xEDD2294FD31AC10B
    mov ecx, 65
    FLAGS 0xA03
    rcr r12, cl
    mov rdx, 0x80000000
    FLAGS 0xA43
    rcr rdx, 255
    mov rdx, 0x6E70E725EEFF3B9A
    mov ecx, 255
    FLAGS 0x202
    rcr rdx, cl
    mov rax, 0xFFFF
    mov [buf], rax
    FLAGS 0x212
    rcr qword [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x212
    rcr qword [buf], cl
    mov rax, [buf]
    FLAGS 0xA03
    rcr qword [buf], 1
    mov rax, [buf]
    mov rdx, 0x3
    FLAGS 0x246
    shl dl, 0
    mov rdx, 0x8000000000000000
    mov ecx, 0
    FLAGS 0xA03
    shl dl, cl
    mov rbp, 0x19
    FLAGS 0x246
    shl bpl, 1
    mov rbp, 0x8000000000000000
    mov ecx, 1
    FLAGS 0xA43
    shl bpl, cl
    mov rdi, 0xFFFFFFFFFFFFFF8E
    FLAGS 0x202
    shl dil, 2
    mov rdi, 0xFFFFFFFF80000000
    mov ecx, 2
    FLAGS 0x203
    shl dil, cl
    mov r10, 0x100000000
    FLAGS 0xA03
    shl r10b, 3
    mov r10, 0x48E27ABCCFB14284
    mov ecx, 3
    FLAGS 0xA82
    shl r10b, cl
    mov rdx, 0x83
    FLAGS 0xA02
    shl dl, 7
    mov rdx, 0xFFFFFFFFFFFFFFAD
    mov ecx, 7
    FLAGS 0xA03
    shl dl, cl
    mov rax, 0xFFFFFFFFFFFFFF4C
    FLAGS 0x246
    shl al, 8
    mov rax, 0xFFFF
    mov ecx, 8
    FLAGS 0x213
    shl al, cl
    mov rsi, 0xAB19D7C56FD2DDB8
    FLAGS 0xA43
    shl sil, 9
    mov rsi, 0xFFFFFFFFFFFFFFFF
    mov ecx, 9
    FLAGS 0x202
    shl sil, cl
    mov rbp, 0x8000
    FLAGS 0x203
    shl bpl, 15
    mov rbp, 0x81B369EAF814C145
    mov ecx, 15
    FLAGS 0x2D6
    shl bpl, cl
    mov r11, 0xD7A4427757EBB9D0
    FLAGS 0x202
    shl r11b, 16
    mov r11, 0xCF99716C542A3BC
    mov ecx, 16
    FLAGS 0x213
    shl r11b, cl
    mov rdx, 0x100
    FLAGS 0x202
    shl dl, 17
    mov rdx, 0x7F
    mov ecx, 17
    FLAGS 0xA82
    shl dl, cl
    mov rdx, 0xFF
    FLAGS 0xA02
    shl dl, 31
    mov rdx, 0xD4303E0427C38F42
    mov ecx, 31
    FLAGS 0x212
    shl dl, cl
    mov r15, 0x2
    FLAGS 0x203
    shl r15b, 32
    mov r15, 0x4EE0E583FE5FFF16
    mov ecx, 32
    FLAGS 0xA03
    shl r15b, cl
    mov r8, 0x80
    FLAGS 0xA02
    shl r8b, 33
    mov r8, 0x80000000
    mov ecx, 33
    FLAGS 0x203
    shl r8b, cl
    mov r10, 0x7FFFFFFFFFFFFFFF
    FLAGS 0x203
    shl r10b, 63
    mov r10, 0xE08A108A1B01F645
    mov ecx, 63
    FLAGS 0xA82
    shl r10b, cl
    mov rbp, 0xA7CBD30077F9E2C7
    FLAGS 0xA43
    shl bpl, 64
    mov rbp, 0x2
    mov ecx, 64
    FLAGS 0x246
    shl bpl, cl
    mov r9, 0x100
    FLAGS 0xA82
    shl r9b, 65
    mov r9, 0x100000000
    mov ecx, 65
    FLAGS 0xA43
    shl r9b, cl
    mov r12, 0xFFFF
    FLAGS 0xA02
    shl r12b, 255
    mov r12, 0x5F
    mov ecx, 255
    FLAGS 0x213
    shl r12b, cl
    mov rax, 0xA5FC1FD5DE09F1F
    mov [buf], rax
    FLAGS 0x202
    shl byte [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x202
    shl byte [buf], cl
    mov rax, [buf]
    FLAGS 0x213
    shl byte [buf], 1
    mov rax, [buf]
    mov rbp, 0x80
    FLAGS 0x246
    shl bp, 0
    mov rbp, 0x80
    mov ecx, 0
    FLAGS 0xA43
    shl bp, cl
    mov r15, 0xC413E0D26EC2366B
    FLAGS 0xA02
    shl r15w, 1
    mov r15, 0x7FFFFFFF
    mov ecx, 1
    FLAGS 0x2D6
    shl r15w, cl
    mov r12, 0xFFFFFFFFFFFFFFA0
    FLAGS 0xA03
    shl r12w, 2
    mov r12, 0xB4DD8F7D0A9E781B
    mov ecx, 2
    FLAGS 0x213
    shl r12w, cl
    mov rsi, 0x7FFF
    FLAGS 0x246
    shl si, 3
    mov rsi, 0x748E0BFD95C5242
    mov ecx, 3
    FLAGS 0xA02
    shl si, cl
    mov r12, 0xFFFFFFFF
    FLAGS 0xA43
    shl r12w, 7
    mov r12, 0x2
    mov ecx, 7
    FLAGS 0xA03
    shl r12w, cl
    mov r14, 0xFFFFFFFFFFFFFF80
    FLAGS 0x246
    shl r14w, 8
    mov r14, 0xFFFFFFFF80000000
    mov ecx, 8
    FLAGS 0x213
    shl r14w, cl
    mov r10, 0x7FFFFFFFFFFFFFFF
    FLAGS 0x212
    shl r10w, 9
    mov r10, 0xB40DF2BC898B3187
    mov ecx, 9
    FLAGS 0xA43
    shl r10w, cl
    mov r13, 0xFFFFFFFFFFFFFF80
    FLAGS 0x202
    shl r13w, 15
    mov r13, 0x3D3814D69EF398C8
    mov ecx, 15
    FLAGS 0xAD7
    shl r13w, cl
    mov rsi, 0x34E6498C04632DD
    FLAGS 0xAD7
    shl si, 16
    mov rsi, 0x0
    mov ecx, 16
    FLAGS 0xA03
    shl si, cl
    mov r14, 0xFFFFFFFF
    FLAGS 0x2D6
    shl r14w, 17
    mov r14, 0x80000000
    mov ecx, 17
    FLAGS 0xA43
    shl r14w, cl
    mov r14, 0x1E7DD946E2848B1E
    FLAGS 0x212
    shl r14w, 31
    mov r14, 0x94D513C703DC9D02
    mov ecx, 31
    FLAGS 0xA02
    shl r14w, cl
    mov rbp, 0x0
    FLAGS 0x202
    shl bp, 32
    mov rbp, 0xD060B9E94FAAE970
    mov ecx, 32
    FLAGS 0xA03
    shl bp, cl
    mov rsi, 0x6EBEA61F9F811533
    FLAGS 0xAD7
    shl si, 33
    mov rsi, 0xFFFFFFFFFFFFFF23
    mov ecx, 33
    FLAGS 0x203
    shl si, cl
    mov r9, 0x0
    FLAGS 0x297
    shl r9w, 63
    mov r9, 0x56C6EBC1EE8D2843
    mov ecx, 63
    FLAGS 0x246
    shl r9w, cl
    mov rbx, 0x81
    FLAGS 0x213
    shl bx, 64
    mov rbx, 0xE0E04398DDA4C907
    mov ecx, 64
    FLAGS 0xA02
    shl bx, cl
    mov r10, 0x2
    FLAGS 0x212
    shl r10w, 65
    mov r10, 0x54
    mov ecx, 65
    FLAGS 0x203
    shl r10w, cl
    mov r14, 0x25047B809FFE2FD8
    FLAGS 0x213
    shl r14w, 255
    mov r14, 0x82EC545C507011B6
    mov ecx, 255
    FLAGS 0xAD7
    shl r14w, cl
    mov rax, 0xFFFFFFFF80000000
    mov [buf], rax
    FLAGS 0x297
    shl word [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x2D6
    shl word [buf], cl
    mov rax, [buf]
    FLAGS 0x202
    shl word [buf], 1
    mov rax, [buf]
    mov rax, 0xB8D68BF48D2F4E8B
    FLAGS 0x212
    shl eax, 0
    mov rax, 0xFFFFFFFFFFFFFF2B
    mov ecx, 0
    FLAGS 0xA02
    shl eax, cl
    mov rbx, 0x809AABE54005CA4
    FLAGS 0xA02
    shl ebx, 1
    mov rbx, 0xC1A45474A8115D2C
    mov ecx, 1
    FLAGS 0x297
    shl ebx, cl
    mov r8, 0x47C00309B26C1447
    FLAGS 0xA02
    shl r8d, 2
    mov r8, 0x3
    mov ecx, 2
    FLAGS 0xA43
    shl r8d, cl
    mov rbx, 0xDED0AE32D4F0E1E3
    FLAGS 0x297
    shl ebx, 3
    mov rbx, 0xC8
    mov ecx, 3
    FLAGS 0xAD7
    shl ebx, cl
    mov r13, 0x8000
    FLAGS 0x203
    shl r13d, 7
    mov r13, 0xCCE9CFAD6B774772
    mov ecx, 7
    FLAGS 0x213
    shl r13d, cl
    mov r14, 0x874AFECF8B76A4BD
    FLAGS 0x297
    shl r14d, 8
    mov r14, 0xFFFFFFFF
    mov ecx, 8
    FLAGS 0x202
    shl r14d, cl
    mov rdi, 0x7FFFFFFF
    FLAGS 0xA82
    shl edi, 9
    mov rdi, 0xFFFFFFFFFFFFFF6D
    mov ecx, 9
    FLAGS 0xA43
    shl edi, cl
    mov r11, 0xFFFFFFFFFFFFFFF4
    FLAGS 0x297
    shl r11d, 15
    mov r11, 0xFFFFFFFF80000000
    mov ecx, 15
    FLAGS 0x212
    shl r11d, cl
    mov r9, 0xEF797A21E4A991F7
    FLAGS 0x246
    shl r9d, 16
    mov r9, 0x100000000
    mov ecx, 16
    FLAGS 0xAD7
    shl r9d, cl
    mov r15, 0xFFFFFFFFFFFFFFCB
    FLAGS 0xA03
    shl r15d, 17
    mov r15, 0x8000
    mov ecx, 17
    FLAGS 0x2D6
    shl r15d, cl
    mov r11, 0xFFFFFFFFFFFFFF80
    FLAGS 0xA43
    shl r11d, 31
    mov r11, 0xBD53BB5FF30D8411
    mov ecx, 31
    FLAGS 0x246
    shl r11d, cl
    mov r11, 0xFFFFFFFFFFFFFF45
    FLAGS 0xAD7
    shl r11d, 32
    mov r11, 0x8000000000000000
    mov ecx, 32
    FLAGS 0x212
    shl r11d, cl
    mov r10, 0x81
    FLAGS 0x202
    shl r10d, 33
    mov r10, 0xFFFFFFFFFFFFFFFF
    mov ecx, 33
    FLAGS 0x213
    shl r10d, cl
    mov rbp, 0xDC604A60B9A07B28
    FLAGS 0x2D6
    shl ebp, 63
    mov rbp, 0x2DD1BEE4C7C3FCB6
    mov ecx, 63
    FLAGS 0x202
    shl ebp, cl
    mov r11, 0xBBB0C87A896A5EBC
    FLAGS 0x213
    shl r11d, 64
    mov r11, 0x1A
    mov ecx, 64
    FLAGS 0xA03
    shl r11d, cl
    mov r14, 0xC3
    FLAGS 0x2D6
    shl r14d, 65
    mov r14, 0x8000000000000000
    mov ecx, 65
    FLAGS 0x246
    shl r14d, cl
    mov r12, 0x8F954A16D365E2DD
    FLAGS 0xA02
    shl r12d, 255
    mov r12, 0xB67229D1E55FC57E
    mov ecx, 255
    FLAGS 0x202
    shl r12d, cl
    mov rax, 0xE2669C67BCC72740
    mov [buf], rax
    FLAGS 0xA03
    shl dword [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x202
    shl dword [buf], cl
    mov rax, [buf]
    FLAGS 0xA03
    shl dword [buf], 1
    mov rax, [buf]
    mov rdx, 0x1A
    FLAGS 0x2D6
    shl rdx, 0
    mov rdx, 0x81
    mov ecx, 0
    FLAGS 0x212
    shl rdx, cl
    mov r11, 0x45D9B36341FC2A6B
    FLAGS 0x2D6
    shl r11, 1
    mov r11, 0x4D2C24FF1652999C
    mov ecx, 1
    FLAGS 0xA03
    shl r11, cl
    mov r9, 0xFFFFFFFFFFFFFF4A
    FLAGS 0x2D6
    shl r9, 2
    mov r9, 0x100000000
    mov ecx, 2
    FLAGS 0x202
    shl r9, cl
    mov r12, 0x7FFF
    FLAGS 0x2D6
    shl r12, 3
    mov r12, 0xE3ED883220B1D4CC
    mov ecx, 3
    FLAGS 0xA82
    shl r12, cl
    mov rax, 0xFFFF
    FLAGS 0x213
    shl rax, 7
    mov rax, 0x9B0B0294F846386F
    mov ecx, 7
    FLAGS 0xA03
    shl rax, cl
    mov r13, 0x745D1C9F39EE0576
    FLAGS 0xA43
    shl r13, 8
    mov r13, 0x6E37985414854431
    mov ecx, 8
    FLAGS 0x246
    shl r13, cl
    mov rdx, 0x93
    FLAGS 0xAD7
    shl rdx, 9
    mov rdx, 0xFFFFFFFFFFFFFF99
    mov ecx, 9
    FLAGS 0x203
    shl rdx, cl
    mov r10, 0x5A5460515D99D20C
    FLAGS 0xA02
    shl r10, 15
    mov r10, 0x100000000
    mov ecx, 15
    FLAGS 0x202
    shl r10, cl
    mov rdi, 0xAA476EDAEA0C8FC2
    FLAGS 0x246
    shl rdi, 16
    mov rdi, 0xFFFFFFFFFFFFFF80
    mov ecx, 16
    FLAGS 0xA82
    shl rdi, cl
    mov r15, 0xDDF0511FBC0F97FD
    FLAGS 0xA82
    shl r15, 17
    mov r15, 0x69CAE3679BE791F4
    mov ecx, 17
    FLAGS 0xA03
    shl r15, cl
    mov rax, 0x9105329AECEE1DE
    FLAGS 0x2D6
    shl rax, 31
    mov rax, 0x7FFFFFFFFFFFFFFF
    mov ecx, 31
    FLAGS 0x202
    shl rax, cl
    mov r12, 0x30588F5F6BD7640C
    FLAGS 0x203
    shl r12, 32
    mov r12, 0xBD2CDBD37EE779A6
    mov ecx, 32
    FLAGS 0x297
    shl r12, cl
    mov r8, 0x9FDD14AF5611D62
    FLAGS 0xA03
    shl r8, 33
    mov r8, 0x3
    mov ecx, 33
    FLAGS 0xA02
    shl r8, cl
    mov rdi, 0x7FFF
    FLAGS 0x246
    shl rdi, 63
    mov rdi, 0xCA640F9F43780812
    mov ecx, 63
    FLAGS 0x203
    shl rdi, cl
    mov r12, 0x622451339AD87300
    FLAGS 0x212
    shl r12, 64
    mov r12, 0xDEB88A6ADF08F41D
    mov ecx, 64
    FLAGS 0xA82
    shl r12, cl
    mov rbp, 0x1
    FLAGS 0x2D6
    shl rbp, 65
    mov rbp, 0x0
    mov ecx, 65
    FLAGS 0xA02
    shl rbp, cl
    mov rdi, 0x2A86BE010395CDF5
    FLAGS 0x213
    shl rdi, 255
    mov rdi, 0xB0E571306D58044
    mov ecx, 255
    FLAGS 0x203
    shl rdi, cl
    mov rax, 0x7FFFFFFF
    mov [buf], rax
    FLAGS 0xA03
    shl qword [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x246
    shl qword [buf], cl
    mov rax, [buf]
    FLAGS 0xA02
    shl qword [buf], 1
    mov rax, [buf]
    mov r14, 0xFF
    FLAGS 0xA02
    shr r14b, 0
    mov r14, 0xF5C402FB836A2EF
    mov ecx, 0
    FLAGS 0xA02
    shr r14b, cl
    mov r9, 0x3
    FLAGS 0x246
    shr r9b, 1
    mov r9, 0x87F64D5492BC3416
    mov ecx, 1
    FLAGS 0x297
    shr r9b, cl
    mov rbx, 0x7F
    FLAGS 0x202
    shr bl, 2
    mov rbx, 0xFFFFFFFF80000000
    mov ecx, 2
    FLAGS 0x297
    shr bl, cl
    mov r11, 0xB5279DCC7CF662AA
    FLAGS 0xAD7
    shr r11b, 3
    mov r11, 0x81
    mov ecx, 3
    FLAGS 0x213
    shr r11b, cl
    mov r8, 0x2
    FLAGS 0xA03
    shr r8b, 7
    mov r8, 0xDA5C0E9AFA2FDE99
    mov ecx, 7
    FLAGS 0x213
    shr r8b, cl
    mov r10, 0x7FC48A8921241557
    FLAGS 0xAD7
    shr r10b, 8
    mov r10, 0xED76D247C54948A4
    mov ecx, 8
    FLAGS 0xA02
    shr r10b, cl
    mov rsi, 0xE52B54565D525C70
    FLAGS 0x297
    shr sil, 9
    mov rsi, 0xCD
    mov ecx, 9
    FLAGS 0x246
    shr sil, cl
    mov rbx, 0xFFFFFFFFFFFFFF80
    FLAGS 0xA43
    shr bl, 15
    mov rbx, 0x3
    mov ecx, 15
    FLAGS 0xA02
    shr bl, cl
    mov r10, 0x7FFFFFFFFFFFFFFF
    FLAGS 0x202
    shr r10b, 16
    mov r10, 0xFFFFFFFFFFFFFFFF
    mov ecx, 16
    FLAGS 0xA82
    shr r10b, cl
    mov r15, 0x3AF6C48C53D62AC7
    FLAGS 0xA02
    shr r15b, 17
    mov r15, 0xD5
    mov ecx, 17
    FLAGS 0x2D6
    shr r15b, cl
    mov rbp, 0x2296A8B880E8B389
    FLAGS 0xA82
    shr bpl, 31
    mov rbp, 0x8000000000000000
    mov ecx, 31
    FLAGS 0x213
    shr bpl, cl
    mov rsi, 0x9917D0FDA4025DD
    FLAGS 0xA82
    shr sil, 32
    mov rsi, 0x0
    mov ecx, 32
    FLAGS 0x202
    shr sil, cl
    mov rax, 0x7FFFFFFF
    FLAGS 0xA82
    shr al, 33
    mov rax, 0x4F62E2600ECA81B2
    mov ecx, 33
    FLAGS 0x212
    shr al, cl
    mov rbp, 0xA8C99A994EA5AFC7
    FLAGS 0x202
    shr bpl, 63
    mov rbp, 0x88CD6FEBFE91AA9F
    mov ecx, 63
    FLAGS 0xA82
    shr bpl, cl
    mov r10, 0x9F38310131EF02C0
    FLAGS 0xA03
    shr r10b, 64
    mov r10, 0xFF
    mov ecx, 64
    FLAGS 0xA03
    shr r10b, cl
    mov r12, 0xD9
    FLAGS 0xA82
    shr r12b, 65
    mov r12, 0x94BE1916292CA20
    mov ecx, 65
    FLAGS 0xA02
    shr r12b, cl
    mov r8, 0xF9
    FLAGS 0x212
    shr r8b, 255
    mov r8, 0xFDA480E60639C110
    mov ecx, 255
    FLAGS 0xA02
    shr r8b, cl
    mov rax, 0x46
    mov [buf], rax
    FLAGS 0x203
    shr byte [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0xA82
    shr byte [buf], cl
    mov rax, [buf]
    FLAGS 0xA03
    shr byte [buf], 1
    mov rax, [buf]
    mov r13, 0x7
    FLAGS 0xAD7
    shr r13w, 0
    mov r13, 0xDC44C85C8A846FF5
    mov ecx, 0
    FLAGS 0x2D6
    shr r13w, cl
    mov rbx, 0x80000000
    FLAGS 0x213
    shr bx, 1
    mov rbx, 0x80
    mov ecx, 1
    FLAGS 0x2D6
    shr bx, cl
    mov r10, 0x8000
    FLAGS 0x202
    shr r10w, 2
    mov r10, 0x7F
    mov ecx, 2
    FLAGS 0xA03
    shr r10w, cl
    mov r11, 0x8000000000000000
    FLAGS 0xA82
    shr r11w, 3
    mov r11, 0x100000000
    mov ecx, 3
    FLAGS 0x203
    shr r11w, cl
    mov r9, 0x8000
    FLAGS 0x202
    shr r9w, 7
    mov r9, 0xF2543A18D2FE149D
    mov ecx, 7
    FLAGS 0x297
    shr r9w, cl
    mov r10, 0xFFFFFFFFFFFFFF80
    FLAGS 0xA02
    shr r10w, 8
    mov r10, 0x1
    mov ecx, 8
    FLAGS 0xAD7
    shr r10w, cl
    mov r13, 0x3
    FLAGS 0xA02
    shr r13w, 9
    mov r13, 0x3
    mov ecx, 9
    FLAGS 0x212
    shr r13w, cl
    mov r8, 0x2D403F1D230473D6
    FLAGS 0x297
    shr r8w, 15
    mov r8, 0x8A59594D0526523E
    mov ecx, 15
    FLAGS 0x202
    shr r8w, cl
    mov r13, 0x7FFF
    FLAGS 0x202
    shr r13w, 16
    mov r13, 0x7FFFFFFF
    mov ecx, 16
    FLAGS 0xA43
    shr r13w, cl
    mov r11, 0x81
    FLAGS 0x246
    shr r11w, 17
    mov r11, 0xFFFFFFFFFFFFFF1D
    mov ecx, 17
    FLAGS 0xA03
    shr r11w, cl
    mov r8, 0x8425108A0D5F7ABC
    FLAGS 0xA02
    shr r8w, 31
    mov r8, 0xBAB388954F1E7F49
    mov ecx, 31
    FLAGS 0xA02
    shr r8w, cl
    mov r15, 0x80
    FLAGS 0x202
    shr r15w, 32
    mov r15, 0x81
    mov ecx, 32
    FLAGS 0x2D6
    shr r15w, cl
    mov rsi, 0x81
    FLAGS 0x213
    shr si, 33
    mov rsi, 0x3
    mov ecx, 33
    FLAGS 0xA43
    shr si, cl
    mov rax, 0xFFFFFFFFFFFFFFDD
    FLAGS 0x297
    shr ax, 63
    mov rax, 0xFFFFFFFFFFFFFFFF
    mov ecx, 63
    FLAGS 0x297
    shr ax, cl
    mov rdx, 0x80
    FLAGS 0xA02
    shr dx, 64
    mov rdx, 0xFFFFFFFFFFFFFFB6
    mov ecx, 64
    FLAGS 0xA03
    shr dx, cl
    mov rbx, 0x74E6983E83042B52
    FLAGS 0xA02
    shr bx, 65
    mov rbx, 0xDBB0DA1401BF6B99
    mov ecx, 65
    FLAGS 0xA82
    shr bx, cl
    mov rsi, 0x81
    FLAGS 0x202
    shr si, 255
    mov rsi, 0x3
    mov ecx, 255
    FLAGS 0x297
    shr si, cl
    mov rax, 0x80
    mov [buf], rax
    FLAGS 0xA43
    shr word [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x203
    shr word [buf], cl
    mov rax, [buf]
    FLAGS 0xA03
    shr word [buf], 1
    mov rax, [buf]
    mov rbx, 0x7FFFFFFF
    FLAGS 0xA02
    shr ebx, 0
    mov rbx, 0x93FD4F79499675EC
    mov ecx, 0
    FLAGS 0x297
    shr ebx, cl
    mov rax, 0x8
    FLAGS 0x213
    shr eax, 1
    mov rax, 0xC04860B6ED4B0B21
    mov ecx, 1
    FLAGS 0x246
    shr eax, cl
    mov r13, 0x3ECA237EC3FF14E9
    FLAGS 0x202
    shr r13d, 2
    mov r13, 0xCE4BD1D3641F4B28
    mov ecx, 2
    FLAGS 0x246
    shr r13d, cl
    mov r13, 0xBC
    FLAGS 0x203
    shr r13d, 3
    mov r13, 0x0
    mov ecx, 3
    FLAGS 0x246
    shr r13d, cl
    mov rbx, 0xFFFFFFFFFFFFFFFF
    FLAGS 0xA03
    shr ebx, 7
    mov rbx, 0x7FFFFFFF
    mov ecx, 7
    FLAGS 0xA82
    shr ebx, cl
    mov rax, 0xAB560D3D739717E1
    FLAGS 0x213
    shr eax, 8
    mov rax, 0x334565D09824C563
    mov ecx, 8
    FLAGS 0x213
    shr eax, cl
    mov r15, 0x8B
    FLAGS 0xAD7
    shr r15d, 9
    mov r15, 0x100000000
    mov ecx, 9
    FLAGS 0xA82
    shr r15d, cl
    mov rax, 0xFFFFFFFF80000000
    FLAGS 0xA82
    shr eax, 15
    mov rax, 0x80000000
    mov ecx, 15
    FLAGS 0xA43
    shr eax, cl
    mov rdi, 0x61427D2E3A597818
    FLAGS 0xA82
    shr edi, 16
    mov rdi, 0x7FFF
    mov ecx, 16
    FLAGS 0x2D6
    shr edi, cl
    mov r14, 0xA0836654E1559F59
    FLAGS 0x203
    shr r14d, 17
    mov r14, 0xA333896F0F18086F
    mov ecx, 17
    FLAGS 0x202
    shr r14d, cl
    mov r15, 0xBECC8F133D2C7993
    FLAGS 0xA02
    shr r15d, 31
    mov r15, 0xB08B9F87BC62BD0E
    mov ecx, 31
    FLAGS 0x246
    shr r15d, cl
    mov rbp, 0xF262EF623E9D41F5
    FLAGS 0x203
    shr ebp, 32
    mov rbp, 0xB0C952E319E32751
    mov ecx, 32
    FLAGS 0x203
    shr ebp, cl
    mov r13, 0x2263BF9DFA531B97
    FLAGS 0x2D6
    shr r13d, 33
    mov r13, 0x2
    mov ecx, 33
    FLAGS 0x213
    shr r13d, cl
    mov rbx, 0x631F49DC1F6CF63
    FLAGS 0xA43
    shr ebx, 63
    mov rbx, 0x80000000
    mov ecx, 63
    FLAGS 0x246
    shr ebx, cl
    mov rax, 0x1
    FLAGS 0xAD7
    shr eax, 64
    mov rax, 0xFF
    mov ecx, 64
    FLAGS 0xA03
    shr eax, cl
    mov rdx, 0xC2C2FDE3865966B7
    FLAGS 0x203
    shr edx, 65
    mov rdx, 0x33D179820870631B
    mov ecx, 65
    FLAGS 0x2D6
    shr edx, cl
    mov rsi, 0x100
    FLAGS 0x202
    shr esi, 255
    mov rsi, 0xBB05EF5C92D52535
    mov ecx, 255
    FLAGS 0xA82
    shr esi, cl
    mov rax, 0xFC519ECA722A6A2A
    mov [buf], rax
    FLAGS 0x2D6
    shr dword [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x202
    shr dword [buf], cl
    mov rax, [buf]
    FLAGS 0x212
    shr dword [buf], 1
    mov rax, [buf]
    mov rsi, 0x9346A4B52CBE79EA
    FLAGS 0x246
    shr rsi, 0
    mov rsi, 0x81
    mov ecx, 0
    FLAGS 0x212
    shr rsi, cl
    mov rbx, 0xA7873520AEAB1B8E
    FLAGS 0x202
    shr rbx, 1
    mov rbx, 0xD01E9AE1B58B736E
    mov ecx, 1
    FLAGS 0xAD7
    shr rbx, cl
    mov r14, 0xFFFFFFFF80000000
    FLAGS 0xA43
    shr r14, 2
    mov r14, 0x10000
    mov ecx, 2
    FLAGS 0x202
    shr r14, cl
    mov rax, 0x7FFF
    FLAGS 0xA03
    shr rax, 3
    mov rax, 0x80
    mov ecx, 3
    FLAGS 0x203
    shr rax, cl
    mov r10, 0xBC8EF5AEDC44BB07
    FLAGS 0x246
    shr r10, 7
    mov r10, 0xC435D14A495AC871
    mov ecx, 7
    FLAGS 0x202
    shr r10, cl
    mov r9, 0x3CA3B212A6A0B563
    FLAGS 0xA02
    shr r9, 8
    mov r9, 0xD7E5272807680CC
    mov ecx, 8
    FLAGS 0x2D6
    shr r9, cl
    mov r15, 0xFFFFFFFF
    FLAGS 0x2D6
    shr r15, 9
    mov r15, 0x6A6F2102E37F0182
    mov ecx, 9
    FLAGS 0xAD7
    shr r15, cl
    mov rsi, 0xE753AD8F2D11ED7D
    FLAGS 0x212
    shr rsi, 15
    mov rsi, 0xA9B060B513219EAC
    mov ecx, 15
    FLAGS 0xA43
    shr rsi, cl
    mov r13, 0xFFFFFFFF
    FLAGS 0xA02
    shr r13, 16
    mov r13, 0x0
    mov ecx, 16
    FLAGS 0x213
    shr r13, cl
    mov r12, 0x3
    FLAGS 0x2D6
    shr r12, 17
    mov r12, 0x2
    mov ecx, 17
    FLAGS 0xA02
    shr r12, cl
    mov r12, 0x449D2AB482BD36CD
    FLAGS 0xA02
    shr r12, 31
    mov r12, 0xFFFFFFFFFFFFFFFF
    mov ecx, 31
    FLAGS 0x203
    shr r12, cl
    mov rdi, 0x1
    FLAGS 0xA02
    shr rdi, 32
    mov rdi, 0xED18F270396A416B
    mov ecx, 32
    FLAGS 0x202
    shr rdi, cl
    mov r15, 0x80000000
    FLAGS 0x213
    shr r15, 33
    mov r15, 0x8000000000000000
    mov ecx, 33
    FLAGS 0x297
    shr r15, cl
    mov rdx, 0x7FFF
    FLAGS 0xA82
    shr rdx, 63
    mov rdx, 0xBDE10C3F1F94642A
    mov ecx, 63
    FLAGS 0x213
    shr rdx, cl
    mov rdi, 0xD6E0A052C4B6BE13
    FLAGS 0x202
    shr rdi, 64
    mov rdi, 0x7F
    mov ecx, 64
    FLAGS 0x212
    shr rdi, cl
    mov rax, 0xAA042481CDB8E7CE
    FLAGS 0xAD7
    shr rax, 65
    mov rax, 0xFF
    mov ecx, 65
    FLAGS 0x2D6
    shr rax, cl
    mov r10, 0x4836F819B0A47BE9
    FLAGS 0xA02
    shr r10, 255
    mov r10, 0x80000000
    mov ecx, 255
    FLAGS 0xA82
    shr r10, cl
    mov rax, 0x1433A99ADA0623F6
    mov [buf], rax
    FLAGS 0xA82
    shr qword [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x203
    shr qword [buf], cl
    mov rax, [buf]
    FLAGS 0xAD7
    shr qword [buf], 1
    mov rax, [buf]
    mov rdi, 0x0
    FLAGS 0x2D6
    sar dil, 0
    mov rdi, 0x324C83C3F219447C
    mov ecx, 0
    FLAGS 0x212
    sar dil, cl
    mov r10, 0x8000
    FLAGS 0x213
    sar r10b, 1
    mov r10, 0xFF
    mov ecx, 1
    FLAGS 0xA03
    sar r10b, cl
    mov r14, 0x3C4EA9AA0B54B683
    FLAGS 0xA82
    sar r14b, 2
    mov r14, 0x80
    mov ecx, 2
    FLAGS 0x297
    sar r14b, cl
    mov rsi, 0x10000
    FLAGS 0x212
    sar sil, 3
    mov rsi, 0xA14A775C0FE38EC3
    mov ecx, 3
    FLAGS 0x246
    sar sil, cl
    mov rdx, 0x519E04AAB0DB4008
    FLAGS 0x2D6
    sar dl, 7
    mov rdx, 0xFFFFFFFFFFFFFF5E
    mov ecx, 7
    FLAGS 0x246
    sar dl, cl
    mov r12, 0x80000000
    FLAGS 0xAD7
    sar r12b, 8
    mov r12, 0x80000000
    mov ecx, 8
    FLAGS 0x202
    sar r12b, cl
    mov rbp, 0x46B8EDFE02E096C1
    FLAGS 0x297
    sar bpl, 9
    mov rbp, 0xFFFFFFFFFFFFFF80
    mov ecx, 9
    FLAGS 0xAD7
    sar bpl, cl
    mov r9, 0x8000000000000000
    FLAGS 0xA43
    sar r9b, 15
    mov r9, 0x100000000
    mov ecx, 15
    FLAGS 0xA02
    sar r9b, cl
    mov r10, 0xE2
    FLAGS 0x2D6
    sar r10b, 16
    mov r10, 0x100
    mov ecx, 16
    FLAGS 0x202
    sar r10b, cl
    mov r14, 0x1
    FLAGS 0xA43
    sar r14b, 17
    mov r14, 0x9A2741E9D163BFEE
    mov ecx, 17
    FLAGS 0xA43
    sar r14b, cl
    mov r8, 0x2D815C19C68D1E27
    FLAGS 0xA03
    sar r8b, 31
    mov r8, 0x100000000
    mov ecx, 31
    FLAGS 0xAD7
    sar r8b, cl
    mov r8, 0xFFFFFFFF80000000
    FLAGS 0x202
    sar r8b, 32
    mov r8, 0xA69C5041F436F76C
    mov ecx, 32
    FLAGS 0x212
    sar r8b, cl
    mov rbp, 0xF19C4E3F28D43BCA
    FLAGS 0x212
    sar bpl, 33
    mov rbp, 0x0
    mov ecx, 33
    FLAGS 0xA03
    sar bpl, cl
    mov rdx, 0x67CBC63268D7789F
    FLAGS 0xA03
    sar dl, 63
    mov rdx, 0x81
    mov ecx, 63
    FLAGS 0xA82
    sar dl, cl
    mov r14, 0x1
    FLAGS 0x212
    sar r14b, 64
    mov r14, 0xFFFF
    mov ecx, 64
    FLAGS 0xA02
    sar r14b, cl
    mov rbp, 0x3
    FLAGS 0x202
    sar bpl, 65
    mov rbp, 0xFFFFFFFFFFFFFFD3
    mov ecx, 65
    FLAGS 0x213
    sar bpl, cl
    mov rbp, 0x2B
    FLAGS 0xA82
    sar bpl, 255
    mov rbp, 0x91732883E40ED635
    mov ecx, 255
    FLAGS 0xA43
    sar bpl, cl
    mov rax, 0x100000000
    mov [buf], rax
    FLAGS 0xAD7
    sar byte [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x297
    sar byte [buf], cl
    mov rax, [buf]
    FLAGS 0xAD7
    sar byte [buf], 1
    mov rax, [buf]
    mov r11, 0x7FFF
    FLAGS 0xA43
    sar r11w, 0
    mov r11, 0x1
    mov ecx, 0
    FLAGS 0x212
    sar r11w, cl
    mov r8, 0x7FFFFFFFFFFFFFFF
    FLAGS 0x203
    sar r8w, 1
    mov r8, 0x7FFFFFFFFFFFFFFF
    mov ecx, 1
    FLAGS 0xA02
    sar r8w, cl
    mov r10, 0xE8A3C5487944E92B
    FLAGS 0x212
    sar r10w, 2
    mov r10, 0x760DAD82BE72CB9F
    mov ecx, 2
    FLAGS 0xA03
    sar r10w, cl
    mov r13, 0x8000000000000000
    FLAGS 0x212
    sar r13w, 3
    mov r13, 0x10000
    mov ecx, 3
    FLAGS 0x297
    sar r13w, cl
    mov rsi, 0x81
    FLAGS 0xA43
    sar si, 7
    mov rsi, 0x8000
    mov ecx, 7
    FLAGS 0xA02
    sar si, cl
    mov rbx, 0x264D254D07B19121
    FLAGS 0xA02
    sar bx, 8
    mov rbx, 0xD23ED82039DC7D59
    mov ecx, 8
    FLAGS 0xA43
    sar bx, cl
    mov rbp, 0x8C88A0D37B066B2A
    FLAGS 0x203
    sar bp, 9
    mov rbp, 0x154C8E33D5076F95
    mov ecx, 9
    FLAGS 0x203
    sar bp, cl
    mov r13, 0x3
    FLAGS 0x297
    sar r13w, 15
    mov r13, 0xFFFF
    mov ecx, 15
    FLAGS 0x297
    sar r13w, cl
    mov r12, 0x10000
    FLAGS 0xA03
    sar r12w, 16
    mov r12, 0x8D9C75506C6A2EA7
    mov ecx, 16
    FLAGS 0x203
    sar r12w, cl
    mov r10, 0x6C3A3A2C5F5A3A0E
    FLAGS 0x202
    sar r10w, 17
    mov r10, 0x34757516C27C18C
    mov ecx, 17
    FLAGS 0xA02
    sar r10w, cl
    mov rbx, 0xF5
    FLAGS 0xAD7
    sar bx, 31
    mov rbx, 0x27E0A34B2F1AD8D1
    mov ecx, 31
    FLAGS 0xA43
    sar bx, cl
    mov r8, 0x100
    FLAGS 0x212
    sar r8w, 32
    mov r8, 0x1
    mov ecx, 32
    FLAGS 0xA03
    sar r8w, cl
    mov rbp, 0xFF
    FLAGS 0x202
    sar bp, 33
    mov rbp, 0xFFFF
    mov ecx, 33
    FLAGS 0x213
    sar bp, cl
    mov r8, 0xFFFFFFFFFFFFFFF8
    FLAGS 0x203
    sar r8w, 63
    mov r8, 0x3
    mov ecx, 63
    FLAGS 0x212
    sar r8w, cl
    mov r15, 0xFFFFFFFFFFFFFF83
    FLAGS 0x297
    sar r15w, 64
    mov r15, 0x9BEF807D1F35BFB4
    mov ecx, 64
    FLAGS 0x202
    sar r15w, cl
    mov r10, 0x7FFF
    FLAGS 0xA43
    sar r10w, 65
    mov r10, 0x8000
    mov ecx, 65
    FLAGS 0x2D6
    sar r10w, cl
    mov r10, 0xFFFFFFFFFFFFFF54
    FLAGS 0xA02
    sar r10w, 255
    mov r10, 0x0
    mov ecx, 255
    FLAGS 0xA03
    sar r10w, cl
    mov rax, 0xFF
    mov [buf], rax
    FLAGS 0x203
    sar word [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x246
    sar word [buf], cl
    mov rax, [buf]
    FLAGS 0x202
    sar word [buf], 1
    mov rax, [buf]
    mov r10, 0x848ABBF190CC16C3
    FLAGS 0x297
    sar r10d, 0
    mov r10, 0x3B
    mov ecx, 0
    FLAGS 0x2D6
    sar r10d, cl
    mov r15, 0xFFFFFFFFFFFFFF60
    FLAGS 0xA82
    sar r15d, 1
    mov r15, 0xEBB875B7E0849C97
    mov ecx, 1
    FLAGS 0xAD7
    sar r15d, cl
    mov rbp, 0x7
    FLAGS 0x213
    sar ebp, 2
    mov rbp, 0xF
    mov ecx, 2
    FLAGS 0x212
    sar ebp, cl
    mov r13, 0x0
    FLAGS 0x2D6
    sar r13d, 3
    mov r13, 0xCD
    mov ecx, 3
    FLAGS 0x297
    sar r13d, cl
    mov rbx, 0xFFFFFFFFFFFFFFEF
    FLAGS 0x203
    sar ebx, 7
    mov rbx, 0x3425BC556EBAE669
    mov ecx, 7
    FLAGS 0xA02
    sar ebx, cl
    mov r13, 0x1
    FLAGS 0xAD7
    sar r13d, 8
    mov r13, 0x7FFF
    mov ecx, 8
    FLAGS 0x203
    sar r13d, cl
    mov rax, 0x1
    FLAGS 0x203
    sar eax, 9
    mov rax, 0x4064932C18ED3488
    mov ecx, 9
    FLAGS 0x203
    sar eax, cl
    mov r9, 0xB37D734012DAC164
    FLAGS 0x297
    sar r9d, 15
    mov r9, 0x33
    mov ecx, 15
    FLAGS 0xA82
    sar r9d, cl
    mov r12, 0x5
    FLAGS 0xA03
    sar r12d, 16
    mov r12, 0x8000
    mov ecx, 16
    FLAGS 0x212
    sar r12d, cl
    mov r15, 0x80
    FLAGS 0xA82
    sar r15d, 17
    mov r15, 0x7030767C14B81AEE
    mov ecx, 17
    FLAGS 0xA03
    sar r15d, cl
    mov rsi, 0xFFFFFFFFFFFFFF06
    FLAGS 0xAD7
    sar esi, 31
    mov rsi, 0xC00D8E79AAFA1A04
    mov ecx, 31
    FLAGS 0xA03
    sar esi, cl
    mov rax, 0x100000000
    FLAGS 0x246
    sar eax, 32
    mov rax, 0x1
    mov ecx, 32
    FLAGS 0x202
    sar eax, cl
    mov rax, 0x3
    FLAGS 0x202
    sar eax, 33
    mov rax, 0xFFFF
    mov ecx, 33
    FLAGS 0x213
    sar eax, cl
    mov r10, 0x80000000
    FLAGS 0x2D6
    sar r10d, 63
    mov r10, 0x8000000000000000
    mov ecx, 63
    FLAGS 0x202
    sar r10d, cl
    mov rdi, 0xFFFFFFFF80000000
    FLAGS 0x297
    sar edi, 64
    mov rdi, 0x8000
    mov ecx, 64
    FLAGS 0x202
    sar edi, cl
    mov r14, 0x377D56E93228DCE3
    FLAGS 0xA82
    sar r14d, 65
    mov r14, 0x100
    mov ecx, 65
    FLAGS 0xAD7
    sar r14d, cl
    mov rdx, 0x81
    FLAGS 0x203
    sar edx, 255
    mov rdx, 0x1
    mov ecx, 255
    FLAGS 0xA82
    sar edx, cl
    mov rax, 0x1
    mov [buf], rax
    FLAGS 0x246
    sar dword [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x297
    sar dword [buf], cl
    mov rax, [buf]
    FLAGS 0x246
    sar dword [buf], 1
    mov rax, [buf]
    mov r9, 0xFFFF
    FLAGS 0xA03
    sar r9, 0
    mov r9, 0x80000000
    mov ecx, 0
    FLAGS 0xAD7
    sar r9, cl
    mov r13, 0x2
    FLAGS 0x202
    sar r13, 1
    mov r13, 0x7FFFFFFFFFFFFFFF
    mov ecx, 1
    FLAGS 0x202
    sar r13, cl
    mov r9, 0xFFFF
    FLAGS 0xA02
    sar r9, 2
    mov r9, 0x2
    mov ecx, 2
    FLAGS 0x246
    sar r9, cl
    mov r9, 0x5BD2BB710B2E4AC0
    FLAGS 0x246
    sar r9, 3
    mov r9, 0x80
    mov ecx, 3
    FLAGS 0xAD7
    sar r9, cl
    mov rdi, 0x5CA07A2401B01508
    FLAGS 0xAD7
    sar rdi, 7
    mov rdi, 0xFCDEF6CABE4AD145
    mov ecx, 7
    FLAGS 0xAD7
    sar rdi, cl
    mov r13, 0xD99B7BBCEDEBC324
    FLAGS 0xA43
    sar r13, 8
    mov r13, 0x299FD60CCA264E7
    mov ecx, 8
    FLAGS 0x202
    sar r13, cl
    mov rax, 0x4E47ED907CAA8193
    FLAGS 0x2D6
    sar rax, 9
    mov rax, 0xFC5450D6B84EE335
    mov ecx, 9
    FLAGS 0xA03
    sar rax, cl
    mov r15, 0xC2
    FLAGS 0x246
    sar r15, 15
    mov r15, 0xFFFFFFFFFFFFFF46
    mov ecx, 15
    FLAGS 0x297
    sar r15, cl
    mov rax, 0xFFFFFFFF
    FLAGS 0x2D6
    sar rax, 16
    mov rax, 0x16
    mov ecx, 16
    FLAGS 0xA03
    sar rax, cl
    mov r8, 0x10000
    FLAGS 0x202
    sar r8, 17
    mov r8, 0x1
    mov ecx, 17
    FLAGS 0xA02
    sar r8, cl
    mov r15, 0x8000
    FLAGS 0xA43
    sar r15, 31
    mov r15, 0x552050A3D157CAA4
    mov ecx, 31
    FLAGS 0x2D6
    sar r15, cl
    mov r9, 0x1
    FLAGS 0x212
    sar r9, 32
    mov r9, 0x25A82A2688E39DEB
    mov ecx, 32
    FLAGS 0xA02
    sar r9, cl
    mov rdi, 0x3
    FLAGS 0xAD7
    sar rdi, 33
    mov rdi, 0xAEE589A0C34420A1
    mov ecx, 33
    FLAGS 0x246
    sar rdi, cl
    mov r13, 0xBB83C247FE2A108A
    FLAGS 0xAD7
    sar r13, 63
    mov r13, 0x7FFFFFFF
    mov ecx, 63
    FLAGS 0x203
    sar r13, cl
    mov rsi, 0x1
    FLAGS 0x203
    sar rsi, 64
    mov rsi, 0xF3
    mov ecx, 64
    FLAGS 0x202
    sar rsi, cl
    mov r10, 0x8A98EDC9A5955CA2
    FLAGS 0xA82
    sar r10, 65
    mov r10, 0xC74D4EB278EC332B
    mov ecx, 65
    FLAGS 0xAD7
    sar r10, cl
    mov rbp, 0x94
    FLAGS 0x246
    sar rbp, 255
    mov rbp, 0xFF
    mov ecx, 255
    FLAGS 0xAD7
    sar rbp, cl
    mov rax, 0xFFFFFFFFFFFFFFCC
    mov [buf], rax
    FLAGS 0x297
    sar qword [buf], 3
    mov rax, [buf]
    mov ecx, 5
    FLAGS 0x2D6
    sar qword [buf], cl
    mov rax, [buf]
    FLAGS 0x203
    sar qword [buf], 1
    mov rax, [buf]
    mov rdi, 0x80000000
    mov r15, 0x7FFFFFFF
    FLAGS 0x297
    shld di, r15w, 0
    mov rdi, 0x7FFF
    mov ecx, 0
    FLAGS 0xA43
    shld di, r15w, cl
    mov rax, 0xFFFFFFFFFFFFFFFF
    mov rsi, 0x8000000000000000
    FLAGS 0x2D6
    shld ax, si, 1
    mov rax, 0x0
    mov ecx, 1
    FLAGS 0x297
    shld ax, si, cl
    mov rdx, 0x7F
    mov rdi, 0x2B2CE85E5C3AEE63
    FLAGS 0x202
    shld dx, di, 2
    mov rdx, 0xFF
    mov ecx, 2
    FLAGS 0x212
    shld dx, di, cl
    mov rbp, 0x1
    mov r11, 0xDA79CE219E438195
    FLAGS 0x213
    shld bp, r11w, 5
    mov rbp, 0x2
    mov ecx, 5
    FLAGS 0xA03
    shld bp, r11w, cl
    mov rbp, 0x8000000000000000
    mov rbx, 0xC5999B68F0EE4047
    FLAGS 0x246
    shld bp, bx, 15
    mov rbp, 0xFFFFFFFFFFFFFFFF
    mov ecx, 15
    FLAGS 0x2D6
    shld bp, bx, cl
    mov rax, 0x100000000
    mov rsi, 0x2A
    FLAGS 0x246
    shld ax, si, 16
    mov rax, 0x81
    mov ecx, 16
    FLAGS 0xA03
    shld ax, si, cl
    mov rdi, 0x262D7100F169602A
    mov rdx, 0xBC6F6C67A5795278
    FLAGS 0xA82
    shld di, dx, 17
    mov rdi, 0x49F91412FB4085BE
    mov ecx, 17
    FLAGS 0xAD7
    shld di, dx, cl
    mov rsi, 0x7F
    mov r13, 0x90EE077CC988D75F
    FLAGS 0xA03
    shld si, r13w, 31
    mov rsi, 0x80000000
    mov ecx, 31
    FLAGS 0x203
    shld si, r13w, cl
    mov r14, 0xFFFFFFFF
    mov r10, 0x100000000
    FLAGS 0x297
    shld r14w, r10w, 32
    mov r14, 0x0
    mov ecx, 32
    FLAGS 0xAD7
    shld r14w, r10w, cl
    mov r11, 0x2A
    mov r15, 0x7FFF
    FLAGS 0x212
    shld r11w, r15w, 33
    mov r11, 0x7FFFFFFFFFFFFFFF
    mov ecx, 33
    FLAGS 0x212
    shld r11w, r15w, cl
    mov r14, 0xFFFFFFFFFFFFFF80
    mov r9, 0xFFFFFFFF
    FLAGS 0xA03
    shld r14w, r9w, 63
    mov r14, 0xC7415FFD3FE38A42
    mov ecx, 63
    FLAGS 0xA82
    shld r14w, r9w, cl
    mov r9, 0xFFFFFFFFFFFFFF49
    mov r14, 0x7AC9E3E1F7396592
    FLAGS 0x2D6
    shld r9w, r14w, 64
    mov r9, 0xBA
    mov ecx, 64
    FLAGS 0xA03
    shld r9w, r14w, cl
    mov rax, 0x0
    mov rdi, 0xFFFFFFFFFFFFFFD0
    FLAGS 0x203
    shld eax, edi, 0
    mov rax, 0x10000
    mov ecx, 0
    FLAGS 0x213
    shld eax, edi, cl
    mov rbx, 0x7FFFFFFFFFFFFFFF
    mov r12, 0x8000
    FLAGS 0x2D6
    shld ebx, r12d, 1
    mov rbx, 0x5AF6A0B60B441EFA
    mov ecx, 1
    FLAGS 0xA02
    shld ebx, r12d, cl
    mov r15, 0x7F
    mov rdi, 0xFFFFFFFFFFFFFF80
    FLAGS 0x297
    shld r15d, edi, 2
    mov r15, 0xFFFFFFFF
    mov ecx, 2
    FLAGS 0x213
    shld r15d, edi, cl
    mov rbx, 0x7F
    mov r12, 0x6098F32D4DB6AE2F
    FLAGS 0x202
    shld ebx, r12d, 5
    mov rbx, 0xCF80763B25D1CB4D
    mov ecx, 5
    FLAGS 0xA82
    shld ebx, r12d, cl
    mov rsi, 0x7FFFFFFFFFFFFFFF
    mov r8, 0x7F
    FLAGS 0x246
    shld esi, r8d, 15
    mov rsi, 0x3
    mov ecx, 15
    FLAGS 0x2D6
    shld esi, r8d, cl
    mov r10, 0xB312DAD622487626
    mov r15, 0xBE6586D087A440EF
    FLAGS 0xA03
    shld r10d, r15d, 16
    mov r10, 0x628B4AC1F8DD7F33
    mov ecx, 16
    FLAGS 0x212
    shld r10d, r15d, cl
    mov rbp, 0x754B096AE9203DC6
    mov r12, 0xFFFFFFFFFFFFFF0A
    FLAGS 0x2D6
    shld ebp, r12d, 17
    mov rbp, 0xFFFFFFFFFFFFFF3D
    mov ecx, 17
    FLAGS 0x213
    shld ebp, r12d, cl
    mov r9, 0x7FFFFFFFFFFFFFFF
    mov r8, 0x100000000
    FLAGS 0x246
    shld r9d, r8d, 31
    mov r9, 0x89
    mov ecx, 31
    FLAGS 0xA02
    shld r9d, r8d, cl
    mov r9, 0x28F1B1D204EB0257
    mov r15, 0x1EBDEDED28242366
    FLAGS 0x213
    shld r9d, r15d, 32
    mov r9, 0x81878A5C18E1BF1E
    mov ecx, 32
    FLAGS 0xAD7
    shld r9d, r15d, cl
    mov r15, 0x59F566B6CD4B1F34
    mov rdi, 0x3F
    FLAGS 0x202
    shld r15d, edi, 33
    mov r15, 0x8000
    mov ecx, 33
    FLAGS 0x212
    shld r15d, edi, cl
    mov rbx, 0x80000000
    mov rsi, 0xA75CB97039D167E8
    FLAGS 0x212
    shld ebx, esi, 63
    mov rbx, 0x3
    mov ecx, 63
    FLAGS 0xA82
    shld ebx, esi, cl
    mov r14, 0x100000000
    mov r10, 0x6268979685A96E90
    FLAGS 0x212
    shld r14d, r10d, 64
    mov r14, 0x81
    mov ecx, 64
    FLAGS 0xA43
    shld r14d, r10d, cl
    mov rdi, 0x6E017AEB83F8411A
    mov r10, 0xFFFFFFFFFFFFFF80
    FLAGS 0xAD7
    shld rdi, r10, 0
    mov rdi, 0xFFFFFFFFFFFFFF10
    mov ecx, 0
    FLAGS 0x213
    shld rdi, r10, cl
    mov rdx, 0x2285917DEE49FA14
    mov r14, 0x7FFFFFFF
    FLAGS 0xA03
    shld rdx, r14, 1
    mov rdx, 0xBC0F58681E8350A
    mov ecx, 1
    FLAGS 0x246
    shld rdx, r14, cl
    mov r13, 0x100000000
    mov r11, 0x38EA43E01C4611
    FLAGS 0xA82
    shld r13, r11, 2
    mov r13, 0x8ADC11CE92ADEEA2
    mov ecx, 2
    FLAGS 0x203
    shld r13, r11, cl
    mov r11, 0x75019026BCD1FE2C
    mov rsi, 0x8000
    FLAGS 0xA02
    shld r11, rsi, 5
    mov r11, 0x2
    mov ecx, 5
    FLAGS 0x246
    shld r11, rsi, cl
    mov rax, 0x7F
    mov r12, 0xAE
    FLAGS 0x203
    shld rax, r12, 15
    mov rax, 0x60D9F4C91ED0965D
    mov ecx, 15
    FLAGS 0xA02
    shld rax, r12, cl
    mov rsi, 0x14C3AEF7B8A216CD
    mov r10, 0xFFFFFFFFFFFFFFE2
    FLAGS 0x203
    shld rsi, r10, 16
    mov rsi, 0xFFFFFFFF80000000
    mov ecx, 16
    FLAGS 0x212
    shld rsi, r10, cl
    mov rbp, 0xFFFFFFFFFFFFFFEF
    mov r12, 0xFFFFFFFFFFFFFFDE
    FLAGS 0xAD7
    shld rbp, r12, 17
    mov rbp, 0xFFFFFFFF
    mov ecx, 17
    FLAGS 0x246
    shld rbp, r12, cl
    mov rax, 0x1
    mov r10, 0x517E888654A5FFEA
    FLAGS 0xA82
    shld rax, r10, 31
    mov rax, 0xC4CEF051B6BF1680
    mov ecx, 31
    FLAGS 0x213
    shld rax, r10, cl
    mov rdx, 0x265EF0AE478F9EEB
    mov rdi, 0x7F
    FLAGS 0xA43
    shld rdx, rdi, 32
    mov rdx, 0xFFFFFFFFFFFFFF2B
    mov ecx, 32
    FLAGS 0x212
    shld rdx, rdi, cl
    mov rdi, 0x7FFFFFFF
    mov r10, 0xEE
    FLAGS 0x202
    shld rdi, r10, 33
    mov rdi, 0xDD82B93E97AB9BA1
    mov ecx, 33
    FLAGS 0xA82
    shld rdi, r10, cl
    mov r14, 0xFFFFFFFFFFFFFF7E
    mov r10, 0x81
    FLAGS 0xAD7
    shld r14, r10, 63
    mov r14, 0xFFFFFFFFFFFFFFFF
    mov ecx, 63
    FLAGS 0x202
    shld r14, r10, cl
    mov r15, 0x619542BCC5A028E7
    mov rdi, 0x80
    FLAGS 0xA43
    shld r15, rdi, 64
    mov r15, 0x3
    mov ecx, 64
    FLAGS 0xAD7
    shld r15, rdi, cl
    mov rbp, 0x100
    mov r11, 0x1
    FLAGS 0xAD7
    shrd bp, r11w, 0
    mov rbp, 0x2593B087D00871FC
    mov ecx, 0
    FLAGS 0x203
    shrd bp, r11w, cl
    mov rax, 0x56F60116625C879D
    mov r8, 0x73AAA5A52F23D1A9
    FLAGS 0x2D6
    shrd ax, r8w, 1
    mov rax, 0x3
    mov ecx, 1
    FLAGS 0xA03
    shrd ax, r8w, cl
    mov r8, 0xEF961264ACE8939A
    mov rax, 0x9D1A75C192E6FE8B
    FLAGS 0xA03
    shrd r8w, ax, 2
    mov r8, 0x417E1930327270C9
    mov ecx, 2
    FLAGS 0xA43
    shrd r8w, ax, cl
    mov rdx, 0x649B1B8FBBCB06D
    mov r10, 0x51CE0BC8FBC43F2C
    FLAGS 0x2D6
    shrd dx, r10w, 5
    mov rdx, 0xF019C8061FA4B2D8
    mov ecx, 5
    FLAGS 0xA82
    shrd dx, r10w, cl
    mov rax, 0xFFFFFFFF
    mov r9, 0xFFFFFFFFFFFFFFE1
    FLAGS 0x2D6
    shrd ax, r9w, 15
    mov rax, 0xFFFFFFFFFFFFFFCD
    mov ecx, 15
    FLAGS 0xA82
    shrd ax, r9w, cl
    mov r12, 0x7FFF
    mov r10, 0xFFFFFFFFFFFFFF80
    FLAGS 0xA02
    shrd r12w, r10w, 16
    mov r12, 0x7FFFFFFFFFFFFFFF
    mov ecx, 16
    FLAGS 0x202
    shrd r12w, r10w, cl
    mov rbx, 0x71010350FB3D7F02
    mov r10, 0x5BF3873FF738777E
    FLAGS 0x203
    shrd bx, r10w, 17
    mov rbx, 0xFF
    mov ecx, 17
    FLAGS 0xA02
    shrd bx, r10w, cl
    mov rbp, 0xFFFFFFFF80000000
    mov r14, 0x81
    FLAGS 0xAD7
    shrd bp, r14w, 31
    mov rbp, 0xFFFFFFFFFFFFFF52
    mov ecx, 31
    FLAGS 0x213
    shrd bp, r14w, cl
    mov r14, 0x71
    mov rdi, 0x8B3ABDEB077B97CB
    FLAGS 0x297
    shrd r14w, di, 32
    mov r14, 0x100000000
    mov ecx, 32
    FLAGS 0x246
    shrd r14w, di, cl
    mov rbp, 0x10000
    mov r14, 0x553571802B2BDCB2
    FLAGS 0x202
    shrd bp, r14w, 33
    mov rbp, 0x60
    mov ecx, 33
    FLAGS 0x2D6
    shrd bp, r14w, cl
    mov r8, 0x544FD2AD0FF93F55
    mov r13, 0xC2AF779B480B45B3
    FLAGS 0x2D6
    shrd r8w, r13w, 63
    mov r8, 0x4241178F77FE916F
    mov ecx, 63
    FLAGS 0xA82
    shrd r8w, r13w, cl
    mov r12, 0xEBC3A51611EF877E
    mov rdx, 0xFFFFFFFFFFFFFFF9
    FLAGS 0x246
    shrd r12w, dx, 64
    mov r12, 0xE50F29080A113B1A
    mov ecx, 64
    FLAGS 0xA82
    shrd r12w, dx, cl
    mov r11, 0xFFFFFFFFFFFFFFFF
    mov r15, 0xFFFFFFFFFFFFFF79
    FLAGS 0xAD7
    shrd r11d, r15d, 0
    mov r11, 0xFFFFFFFFFFFFFFFF
    mov ecx, 0
    FLAGS 0xA82
    shrd r11d, r15d, cl
    mov rbp, 0x0
    mov r10, 0xF1D25D1CB2B4C349
    FLAGS 0xA43
    shrd ebp, r10d, 1
    mov rbp, 0xB0DD0CC77F4F6703
    mov ecx, 1
    FLAGS 0xA02
    shrd ebp, r10d, cl
    mov r12, 0x100
    mov rsi, 0xEE75641D35431112
    FLAGS 0x213
    shrd r12d, esi, 2
    mov r12, 0x7FFF
    mov ecx, 2
    FLAGS 0xAD7
    shrd r12d, esi, cl
    mov r8, 0x1
    mov r10, 0xFFFFFFFFFFFFFFBA
    FLAGS 0xA03
    shrd r8d, r10d, 5
    mov r8, 0xF6
    mov ecx, 5
    FLAGS 0xAD7
    shrd r8d, r10d, cl
    mov r8, 0x7FFFFFFFFFFFFFFF
    mov r10, 0x22E3B221FBABD6C6
    FLAGS 0xA02
    shrd r8d, r10d, 15
    mov r8, 0x3
    mov ecx, 15
    FLAGS 0x2D6
    shrd r8d, r10d, cl
    mov rbp, 0xFFFFFFFF80000000
    mov r15, 0x97C390087A6912A2
    FLAGS 0xAD7
    shrd ebp, r15d, 16
    mov rbp, 0x8000000000000000
    mov ecx, 16
    FLAGS 0x246
    shrd ebp, r15d, cl
    mov rbp, 0x62853A27BC04D357
    mov r9, 0x7FFF
    FLAGS 0xA43
    shrd ebp, r9d, 17
    mov rbp, 0x8000
    mov ecx, 17
    FLAGS 0x203
    shrd ebp, r9d, cl
    mov r12, 0xC3
    mov rdx, 0x7FFFFFFF
    FLAGS 0x246
    shrd r12d, edx, 31
    mov r12, 0x7FFFFFFF
    mov ecx, 31
    FLAGS 0xA82
    shrd r12d, edx, cl
    mov r9, 0x38B53AD6ED2174FA
    mov rdi, 0x81
    FLAGS 0x297
    shrd r9d, edi, 32
    mov r9, 0x1DF729CA0CAD2096
    mov ecx, 32
    FLAGS 0xA03
    shrd r9d, edi, cl
    mov r15, 0x65E8D710056E4999
    mov rbp, 0xFFFFFFFFFFFFFF59
    FLAGS 0x202
    shrd r15d, ebp, 33
    mov r15, 0x7C9FC2545CDD2644
    mov ecx, 33
    FLAGS 0xA03
    shrd r15d, ebp, cl
    mov rsi, 0x1CB3158040BB76CC
    mov r9, 0xFF
    FLAGS 0x213
    shrd esi, r9d, 63
    mov rsi, 0xD66FBCE2CEF6BD2C
    mov ecx, 63
    FLAGS 0x246
    shrd esi, r9d, cl
    mov rsi, 0xFFFFFFFFFFFFFFE5
    mov rdx, 0xDB5BC37A153168FA
    FLAGS 0xA82
    shrd esi, edx, 64
    mov rsi, 0x86A4759BE7C50C2E
    mov ecx, 64
    FLAGS 0x212
    shrd esi, edx, cl
    mov r13, 0x31D3AED0690AB0B0
    mov r15, 0xEA0225FAC17EBE0C
    FLAGS 0x203
    shrd r13, r15, 0
    mov r13, 0x213BCB1A2C379C7D
    mov ecx, 0
    FLAGS 0xA82
    shrd r13, r15, cl
    mov rdx, 0x81
    mov rbp, 0xC2AEEA72B7A7EEBD
    FLAGS 0x212
    shrd rdx, rbp, 1
    mov rdx, 0x184E82F0363AA740
    mov ecx, 1
    FLAGS 0xA02
    shrd rdx, rbp, cl
    mov r13, 0x87531F5443D7EF68
    mov r9, 0x6FAF92E2DC5E9F65
    FLAGS 0x202
    shrd r13, r9, 2
    mov r13, 0xDFB3A5474E9011FB
    mov ecx, 2
    FLAGS 0x2D6
    shrd r13, r9, cl
    mov r13, 0x99
    mov rdi, 0x5D
    FLAGS 0xAD7
    shrd r13, rdi, 5
    mov r13, 0x1
    mov ecx, 5
    FLAGS 0xAD7
    shrd r13, rdi, cl
    mov rbp, 0x89BAD8890EF81531
    mov r11, 0xDC3A1D8A150B55F5
    FLAGS 0x246
    shrd rbp, r11, 15
    mov rbp, 0xF33BED127FFBC6CE
    mov ecx, 15
    FLAGS 0xA03
    shrd rbp, r11, cl
    mov rdx, 0x9D5884DB9ED9DCAD
    mov r9, 0x8000000000000000
    FLAGS 0x202
    shrd rdx, r9, 16
    mov rdx, 0xDD
    mov ecx, 16
    FLAGS 0xA02
    shrd rdx, r9, cl
    mov rdx, 0xD07B7679D879B010
    mov rsi, 0x68820D9BBD117F
    FLAGS 0x246
    shrd rdx, rsi, 17
    mov rdx, 0x10000
    mov ecx, 17
    FLAGS 0x213
    shrd rdx, rsi, cl
    mov rbp, 0x80000000
    mov r9, 0x8C3CDAED22A920A9
    FLAGS 0x203
    shrd rbp, r9, 31
    mov rbp, 0x70
    mov ecx, 31
    FLAGS 0x2D6
    shrd rbp, r9, cl
    mov rdx, 0x3
    mov r8, 0xB7289F32A566AF12
    FLAGS 0x297
    shrd rdx, r8, 32
    mov rdx, 0x11CB37AC36384326
    mov ecx, 32
    FLAGS 0x246
    shrd rdx, r8, cl
    mov rbx, 0xE57B3D3327259B3A
    mov r8, 0xCEE8821947ADEC5F
    FLAGS 0x203
    shrd rbx, r8, 33
    mov rbx, 0x4A576F6CC76E912F
    mov ecx, 33
    FLAGS 0x213
    shrd rbx, r8, cl
    mov rax, 0x81
    mov rsi, 0xFFFFFFFFFFFFFF80
    FLAGS 0x203
    shrd rax, rsi, 63
    mov rax, 0xCDDFB66EC54AD712
    mov ecx, 63
    FLAGS 0x212
    shrd rax, rsi, cl
    mov rbx, 0xFFFFFFFFFFFFFFF7
    mov r10, 0x1
    FLAGS 0x2D6
    shrd rbx, r10, 64
    mov rbx, 0x210779124CC899DC
    mov ecx, 64
    FLAGS 0x203
    shrd rbx, r10, cl
    EXIT
    align 16
buf: times 64 dq 0x0123456789ABCDEF
file_end:
