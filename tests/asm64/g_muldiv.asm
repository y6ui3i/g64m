; MUL, IMUL in its three forms, DIV and IDIV at every width.
; Written by tools/gen64_tests.py: change that, not this.
%include "elf.inc"
    mov rax, 0x80
    mov rdx, 0x80
    mov r14, 0x7FFF
    FLAGS 0x246
    mul r14b
    mov rax, 0x2
    mov rdx, 0x100
    mov r12, 0x1
    FLAGS 0x297
    mul r12b
    mov rax, 0x8AB0F6BA95AAC8F6
    mov rdx, 0x748A0767337E2292
    mov rcx, 0x1
    FLAGS 0xA03
    mul cl
    mov rax, 0xAFCEEB7AA1E9A221
    mov rdx, 0xD39D551CCCACBC59
    mov r15, 0x5B47FE01E0A3F268
    FLAGS 0x202
    mul r15b
    mov rax, 0x7FFFFFFFFFFFFFFF
    mov rdx, 0xD02F461DC331DD1A
    mov rdi, 0x3
    FLAGS 0xAD7
    mul dil
    mov rax, 0xD5
    mov rdx, 0xFFFFFFFFFFFFFF52
    mov r9, 0xA9757C034F480AD2
    FLAGS 0xA03
    mul r9b
    mov rax, 0xFB942270CCD5A6B
    mov rdx, 0x9EDBEA948D54138D
    mov r15, 0x2
    FLAGS 0x297
    mul r15b
    mov rax, 0xFFFFFFFF
    mov rdx, 0x20A59BD4EC6B84DC
    mov r8, 0xBE856112C7A11526
    FLAGS 0xA03
    mul r8b
    mov rax, 0xFFFFFFFF
    mov rdx, 0xFFFFFFFF
    mov rdi, 0x8000000000000000
    FLAGS 0xAD7
    mul dil
    mov rax, 0xADE85FE53EEDE76D
    mov rdx, 0x7FFFFFFFFFFFFFFF
    mov r10, 0x81
    FLAGS 0x297
    mul r10b
    mov rax, 0x0
    mov rdx, 0xE474FC798173D6F9
    mov rbp, 0x80
    FLAGS 0x212
    mul bpl
    mov rax, 0xF9
    mov rdx, 0x2928966C74C20913
    mov r15, 0x7FFFFFFFFFFFFFFF
    FLAGS 0xA82
    mul r15b
    mov rax, 0x463DC2E66E10A0D2
    mov rdx, 0x7FFFFFFF
    mov r9, 0x93A660AB3FF82315
    FLAGS 0x203
    mul r9b
    mov rax, 0xFFFFFFFFFFFFFF86
    mov rdx, 0x3
    mov r14, 0xFFFFFFFFFFFFFFFF
    FLAGS 0x2D6
    mul r14b
    mov rax, 0x2
    mov rdx, 0x7FFFFFFFFFFFFFFF
    mov r15, 0x1
    FLAGS 0x202
    mul r15w
    mov rax, 0xFFFFFFFFFFFFFFC0
    mov rdx, 0x3
    mov r10, 0x81
    FLAGS 0x213
    mul r10w
    mov rax, 0x5FF4B786CA3D14C
    mov rdx, 0x6A7D35D4174DB1AE
    mov r13, 0x10000
    FLAGS 0x212
    mul r13w
    mov rax, 0x4503B5F6AA5CFDFF
    mov rdx, 0x100
    mov r10, 0x9660521D519E69D4
    FLAGS 0xA02
    mul r10w
    mov rax, 0x7FFF
    mov rdx, 0xFFFFFFFFFFFFFFFF
    mov rcx, 0x100
    FLAGS 0xA82
    mul cx
    mov rax, 0x7FFFFFFFFFFFFFFF
    mov rdx, 0xFFFFFFFFFFFFFF80
    mov rsi, 0xFFFFFFFFFFFFFF6C
    FLAGS 0xA03
    mul si
    mov rax, 0xBDAEF053A4EF709
    mov rdx, 0xD3
    mov r13, 0x7F
    FLAGS 0x246
    mul r13w
    mov rax, 0x76A0A1DF071B7693
    mov rdx, 0xFFFFFFFF80000000
    mov rsi, 0x1F3E7B5C165F5AEA
    FLAGS 0x202
    mul si
    mov rax, 0x10000
    mov rdx, 0x9E
    mov rsi, 0x8178E1A64C742EE3
    FLAGS 0xA03
    mul si
    mov rax, 0x6942FA9788D9F7EC
    mov rdx, 0x7FFF
    mov rdi, 0x96
    FLAGS 0x213
    mul di
    mov rax, 0x80000000
    mov rdx, 0x7FFF
    mov rbp, 0x8000000000000000
    FLAGS 0x202
    mul bp
    mov rax, 0xA9710CA0B14B3F1C
    mov rdx, 0x10000
    mov r12, 0x80
    FLAGS 0x202
    mul r12w
    mov rax, 0xF4C2C4B4697C31EC
    mov rdx, 0x4948EF737B6EC5F6
    mov r12, 0x7F
    FLAGS 0x203
    mul r12w
    mov rax, 0x274FA99F188A9E17
    mov rdx, 0x8FD050CA892F360A
    mov r8, 0x8000000000000000
    FLAGS 0xA03
    mul r8w
    mov rax, 0x723CEF57CE98D9C4
    mov rdx, 0xC2
    mov rbx, 0x7FFF
    FLAGS 0xA02
    mul ebx
    mov rax, 0xB5731719092A66F5
    mov rdx, 0xB59EC7D46CEF88E5
    mov r8, 0x10000
    FLAGS 0xA82
    mul r8d
    mov rax, 0x7DF25A4EAB6DB923
    mov rdx, 0x0
    mov rdi, 0x7FFFFFFFFFFFFFFF
    FLAGS 0xA02
    mul edi
    mov rax, 0xFFFFFFFFFFFFFF80
    mov rdx, 0x8000000000000000
    mov r13, 0xFFFF
    FLAGS 0x202
    mul r13d
    mov rax, 0x80000000
    mov rdx, 0x43E1772FD47F5020
    mov r8, 0x8000000000000000
    FLAGS 0xA03
    mul r8d
    mov rax, 0x8000
    mov rdx, 0x8E159E576D2A2F3D
    mov r13, 0x1
    FLAGS 0x297
    mul r13d
    mov rax, 0xFFFFFFFFFFFFFF01
    mov rdx, 0x7FFFFFFFFFFFFFFF
    mov r14, 0x58340C19260DDD7B
    FLAGS 0xA82
    mul r14d
    mov rax, 0xFFFFFFFFFFFFFFE5
    mov rdx, 0x740ABC02820689DA
    mov r11, 0x2
    FLAGS 0x246
    mul r11d
    mov rax, 0x521DB2F12C05161D
    mov rdx, 0x7FFFFFFFFFFFFFFF
    mov r13, 0x1C
    FLAGS 0x202
    mul r13d
    mov rax, 0x6917E3C538A54990
    mov rdx, 0x100
    mov rbx, 0xFFFFFFFFFFFFFFFF
    FLAGS 0xAD7
    mul ebx
    mov rax, 0xFFFFFFFF80000000
    mov rdx, 0xE97CAAA20886A4C8
    mov r9, 0x3527E5A0E737BED0
    FLAGS 0x202
    mul r9d
    mov rax, 0x81
    mov rdx, 0xFFFFFFFFFFFFFF27
    mov r9, 0xC111E96BF4A91B81
    FLAGS 0x212
    mul r9d
    mov rax, 0xFFFFFFFF
    mov rdx, 0xB1DFE65B42FE3BB
    mov rsi, 0xFFFF
    FLAGS 0xA03
    mul esi
    mov rax, 0x81
    mov rdx, 0x7FFFFFFF
    mov r8, 0xD08BA5CA1AE0FCC7
    FLAGS 0x212
    mul r8d
    mov rax, 0xC2
    mov rdx, 0xB8
    mov rsi, 0xE3C3675789677E1A
    FLAGS 0x246
    mul rsi
    mov rax, 0xFFFFFFFFFFFFFF8F
    mov rdx, 0x81
    mov r14, 0x21CEC3E4E377CA66
    FLAGS 0x203
    mul r14
    mov rax, 0xFFFFFFFF
    mov rdx, 0xFFFFFFFFFFFFFF80
    mov r9, 0x7FFFFFFFFFFFFFFF
    FLAGS 0xA02
    mul r9
    mov rax, 0x2AB6EF978B3A8C78
    mov rdx, 0xDB
    mov rsi, 0x15
    FLAGS 0xAD7
    mul rsi
    mov rax, 0xFFFFFFFFFFFFFFFF
    mov rdx, 0x1
    mov rbx, 0x811FEC9EB2100261
    FLAGS 0xAD7
    mul rbx
    mov rax, 0xFFFF
    mov rdx, 0x819186DFF85612C7
    mov rbp, 0x80
    FLAGS 0xAD7
    mul rbp
    mov rax, 0x80000000
    mov rdx, 0xFFFFFFFFFFFFFF2B
    mov rbx, 0x1
    FLAGS 0xA02
    mul rbx
    mov rax, 0x80000000
    mov rdx, 0xD6
    mov r12, 0x81
    FLAGS 0x203
    mul r12
    mov rax, 0xFFFFFFFFFFFFFFF5
    mov rdx, 0xCF85470F4870EEB
    mov r14, 0xFFFFFFFFFFFFFFE4
    FLAGS 0x212
    mul r14
    mov rax, 0xAE
    mov rdx, 0x2DB49CC7883939E6
    mov rcx, 0x565F1FE04CD126F3
    FLAGS 0x202
    mul rcx
    mov rax, 0x5CBFFCEFA9D50CCC
    mov rdx, 0x80000000
    mov r15, 0x7FFF
    FLAGS 0x2D6
    mul r15
    mov rax, 0xFFFF
    mov rdx, 0x2
    mov r11, 0x7FFFFFFF
    FLAGS 0xA03
    mul r11
    mov rax, 0xFFFF
    mov rdx, 0x31612A649E7C4966
    mov r8, 0x43AC668A3DCBFE92
    FLAGS 0xA43
    mul r8
    mov rax, 0x7FFFFFFFFFFFFFFF
    mov rdx, 0x3
    mov rcx, 0x3
    FLAGS 0xA43
    mul rcx
    mov rax, 0xF2108CAA069182E6
    mov rdx, 0x1D6974BF070F0478
    mov r9, 0x9B97DD33E927BA43
    FLAGS 0x2D6
    imul r9b
    mov rax, 0xFFFFFFFFFFFFFF80
    mov rdx, 0xB8DAF7EF9C82E95C
    mov r9, 0xB3B32F2CFD7B0313
    FLAGS 0xA82
    imul r9b
    mov rax, 0xFFFFFFFFFFFFFFFF
    mov rdx, 0x8000
    mov rsi, 0x5D978D31F54ED10B
    FLAGS 0xA43
    imul sil
    mov rax, 0x3
    mov rdx, 0x77
    mov rsi, 0x424E269947565323
    FLAGS 0x213
    imul sil
    mov rax, 0xFFFFFFFFFFFFFF04
    mov rdx, 0xFF
    mov rdi, 0xFFFFFFFFFFFFFFCC
    FLAGS 0x213
    imul dil
    mov rax, 0x100000000
    mov rdx, 0xFFFFFFFF
    mov rbp, 0x0
    FLAGS 0xA43
    imul bpl
    mov rax, 0x3
    mov rdx, 0x80
    mov r9, 0x2
    FLAGS 0x246
    imul r9b
    mov rax, 0x80000000
    mov rdx, 0x553DA33CF25E99D7
    mov rcx, 0x8000000000000000
    FLAGS 0xA43
    imul cl
    mov rax, 0xA89C03137FB42E99
    mov rdx, 0xE9D836F1D6A78999
    mov rbp, 0x4A75EB4221A9134D
    FLAGS 0x202
    imul bpl
    mov rax, 0xFFFFFFFFFFFFFF80
    mov rdx, 0x3D974C5018DFB442
    mov r8, 0x54
    FLAGS 0x203
    imul r8b
    mov rax, 0x10000
    mov rdx, 0x7F
    mov r13, 0xAE574133F8EC47F4
    FLAGS 0xA03
    imul r13b
    mov rax, 0xA084159B76001959
    mov rdx, 0x5CE354F5FA576641
    mov r10, 0x80000000
    FLAGS 0xA03
    imul r10b
    mov rax, 0xA11EC6C35BF00F39
    mov rdx, 0xFFFFFFFFFFFFFFBD
    mov r9, 0x7F4AC3877DB64D20
    FLAGS 0x203
    imul r9b
    mov rax, 0xC884490A4AC0C420
    mov rdx, 0x7F
    mov rdi, 0x932CC9A94D559B4E
    FLAGS 0x213
    imul dil
    mov rax, 0xFFFFFFFFFFFFFF7F
    mov rdx, 0x80000000
    mov r11, 0x96
    FLAGS 0x213
    imul r11w
    mov rax, 0x21D84EFE38E46849
    mov rdx, 0xA8CD0B1C3999BE09
    mov r12, 0x3B6CE26AFB0344A9
    FLAGS 0x297
    imul r12w
    mov rax, 0xFF
    mov rdx, 0xFFFFFFFF
    mov rdi, 0xFFFF
    FLAGS 0x212
    imul di
    mov rax, 0xFFFFFFFFFFFFFFA6
    mov rdx, 0xA8518EC7C4168151
    mov rbx, 0x9EB6F3F12E107A24
    FLAGS 0x203
    imul bx
    mov rax, 0xC3CECB27A70CEB26
    mov rdx, 0x7F
    mov rdi, 0x4DA0B354C8EF5B7B
    FLAGS 0xA02
    imul di
    mov rax, 0x1
    mov rdx, 0xA9EFEC0733C44AE9
    mov rbx, 0x8000
    FLAGS 0x213
    imul bx
    mov rax, 0x7FFF
    mov rdx, 0xD1EF0C5B43B3F0D5
    mov rdi, 0x7FFFFFFF
    FLAGS 0x202
    imul di
    mov rax, 0xFFFFFFFF80000000
    mov rdx, 0x1BB56711A3146022
    mov r12, 0x3D53089E7123E50A
    FLAGS 0x212
    imul r12w
    mov rax, 0x9258E1D821587BA3
    mov rdx, 0x7727C9932A1EE5EB
    mov r12, 0x5282CD12A5939566
    FLAGS 0x2D6
    imul r12w
    mov rax, 0xFFFFFFFFFFFFFF80
    mov rdx, 0x7FFFFFFFFFFFFFFF
    mov r13, 0x7DA48A58A467E725
    FLAGS 0x203
    imul r13w
    mov rax, 0x22C7B6573198F060
    mov rdx, 0xC8F552A2382CA53
    mov r13, 0x81
    FLAGS 0x202
    imul r13w
    mov rax, 0x7E30B94C5AB937A0
    mov rdx, 0xFFFFFFFFFFFFFF16
    mov rcx, 0x4A460375F4552C4A
    FLAGS 0xA02
    imul cx
    mov rax, 0xE7F653EB6EC1F4B5
    mov rdx, 0x10000
    mov r8, 0xC04D6A336CBF19E2
    FLAGS 0xAD7
    imul r8w
    mov rax, 0x9866B94DEFDF8D2F
    mov rdx, 0xFFFFFFFF80000000
    mov rbx, 0x8000000000000000
    FLAGS 0xA03
    imul bx
    mov rax, 0x7B
    mov rdx, 0xAB0EB928122E5923
    mov r10, 0x51
    FLAGS 0x2D6
    imul r10d
    mov rax, 0x38148637E4D4E4C1
    mov rdx, 0x1
    mov r12, 0xFF
    FLAGS 0xA02
    imul r12d
    mov rax, 0xC670E26917943343
    mov rdx, 0x8000000000000000
    mov r14, 0x80000000
    FLAGS 0x246
    imul r14d
    mov rax, 0x38EA1254D169E915
    mov rdx, 0x6E12D881196C2FC2
    mov r12, 0x4C
    FLAGS 0x213
    imul r12d
    mov rax, 0x8000
    mov rdx, 0x80000000
    mov r10, 0x8D4ECF1D5C7A9D97
    FLAGS 0x297
    imul r10d
    mov rax, 0x7F
    mov rdx, 0x7FFFFFFFFFFFFFFF
    mov r11, 0x161CFD037B032654
    FLAGS 0x213
    imul r11d
    mov rax, 0xFFFFFFFFFFFFFF19
    mov rdx, 0xF7
    mov r9, 0xFFFFFFFFFFFFFFFF
    FLAGS 0x202
    imul r9d
    mov rax, 0xE52FB4E0DCB46595
    mov rdx, 0x92F7AB938BD61ABF
    mov r12, 0x7BA3AFDEF31A5BD
    FLAGS 0xA03
    imul r12d
    mov rax, 0xFFFFFFFFFFFFFFFF
    mov rdx, 0xFF
    mov r13, 0x3
    FLAGS 0x297
    imul r13d
    mov rax, 0xFFFFFFFFFFFFFF2A
    mov rdx, 0x48E295612B552F7A
    mov rbp, 0x47BF346072DE6543
    FLAGS 0x213
    imul ebp
    mov rax, 0xFFFFFFFFFFFFFF96
    mov rdx, 0x94309002D601C6B5
    mov rcx, 0xFFFFFFFFFFFFFF2B
    FLAGS 0x203
    imul ecx
    mov rax, 0x363FD683217F0F59
    mov rdx, 0xFFFFFFFFFFFFFF80
    mov r8, 0x532680B60D06B574
    FLAGS 0x203
    imul r8d
    mov rax, 0xFFFFFFFF80000000
    mov rdx, 0x0
    mov rcx, 0x88BD680EFDC672DD
    FLAGS 0xA02
    imul ecx
    mov rax, 0xA4
    mov rdx, 0xB631CFE67F38D67B
    mov rsi, 0x80000000
    FLAGS 0x212
    imul esi
    mov rax, 0x2
    mov rdx, 0x7F
    mov r8, 0xF2DB2D6BA52FA6CB
    FLAGS 0xA03
    imul r8
    mov rax, 0xFD6C999F8C982ED1
    mov rdx, 0xFFFFFFFFFFFFFFE0
    mov r14, 0xFFFFFFFF80000000
    FLAGS 0x202
    imul r14
    mov rax, 0xFFFFFFFFFFFFFFFF
    mov rdx, 0x49626510C9292FA2
    mov r9, 0x3
    FLAGS 0x212
    imul r9
    mov rax, 0x6B3E420F2D75CA18
    mov rdx, 0x2
    mov r11, 0x80
    FLAGS 0x2D6
    imul r11
    mov rax, 0x7F
    mov rdx, 0x2F
    mov r12, 0x7F
    FLAGS 0xA03
    imul r12
    mov rax, 0xBDE8C88C30F0803D
    mov rdx, 0x0
    mov rbp, 0x8000
    FLAGS 0x246
    imul rbp
    mov rax, 0x8000
    mov rdx, 0x6ED30A09087E9D4F
    mov r15, 0xFFFFFFFF80000000
    FLAGS 0x212
    imul r15
    mov rax, 0xB3E3B99AAA487819
    mov rdx, 0x7FFF
    mov r13, 0x7FFFFFFF
    FLAGS 0x212
    imul r13
    mov rax, 0x8C4946A41952620F
    mov rdx, 0x0
    mov r11, 0x7FFFFFFF
    FLAGS 0xA82
    imul r11
    mov rax, 0xFFFF
    mov rdx, 0x3
    mov rsi, 0x80
    FLAGS 0xAD7
    imul rsi
    mov rax, 0x7FFFFFFF
    mov rdx, 0x91FFBE6FBD9FB216
    mov r12, 0xFFFFFFFFFFFFFF80
    FLAGS 0xA03
    imul r12
    mov rax, 0xA6EABD083EF91237
    mov rdx, 0x94
    mov r9, 0xFFFF
    FLAGS 0x297
    imul r9
    mov rax, 0xFFFFFFFFFFFFFFFF
    mov rdx, 0x10000
    mov r15, 0x80
    FLAGS 0xA43
    imul r15
    mov rax, 0x4ADF5A3FC594181A
    mov rdx, 0xFFFF
    mov r13, 0xCC3B0C300A27CE78
    FLAGS 0x202
    imul r13
    mov r9, 0xC74D1D6D73AD16D9
    mov r15, 0xFFFFFFFFFFFFFFA4
    FLAGS 0xAD7
    imul r9w, r15w
    mov r15, 0x4E
    FLAGS 0xA82
    imul r9w, r15w, -48
    mov [buf], r15
    FLAGS 0x212
    imul r15w, word [buf], 20228
    mov r10, 0xDD
    mov r8, 0x0
    FLAGS 0xA03
    imul r10w, r8w
    mov r8, 0x1
    FLAGS 0x203
    imul r10w, r8w, 6
    mov [buf], r8
    FLAGS 0xA03
    imul r8w, word [buf], -128
    mov r13, 0xC065A02129A5F225
    mov r12, 0x100
    FLAGS 0x2D6
    imul r13w, r12w
    mov r12, 0xFFFFFFFFFFFFFF80
    FLAGS 0xAD7
    imul r13w, r12w, -67
    mov [buf], r12
    FLAGS 0xA82
    imul r12w, word [buf], -23214
    mov rbx, 0x2
    mov rdi, 0xFFFF
    FLAGS 0x203
    imul bx, di
    mov rdi, 0x22EFC06CC0E07872
    FLAGS 0xA03
    imul bx, di, -89
    mov [buf], rdi
    FLAGS 0x212
    imul di, word [buf], -1
    mov r14, 0x3A
    mov rax, 0xC4FB4D4F108D098D
    FLAGS 0x203
    imul r14w, ax
    mov rax, 0xFFFFFFFF80000000
    FLAGS 0xA03
    imul r14w, ax, -32
    mov [buf], rax
    FLAGS 0x2D6
    imul ax, word [buf], -128
    mov rcx, 0x7FFF
    mov r9, 0xBD6A6A62087BE367
    FLAGS 0xAD7
    imul cx, r9w
    mov r9, 0x93
    FLAGS 0x203
    imul cx, r9w, 5
    mov [buf], r9
    FLAGS 0x202
    imul r9w, word [buf], -128
    mov r9, 0x100000000
    mov rcx, 0xFFFFFFFFFFFFFF3B
    FLAGS 0x213
    imul r9w, cx
    mov rcx, 0xFFFFFFFFFFFFFF13
    FLAGS 0x212
    imul r9w, cx, -1
    mov [buf], rcx
    FLAGS 0xA82
    imul cx, word [buf], 3730
    mov r10, 0x1
    mov r8, 0xF11FF13901AC0644
    FLAGS 0x2D6
    imul r10w, r8w
    mov r8, 0xD2F36F29DB871BDC
    FLAGS 0xA43
    imul r10w, r8w, 1
    mov [buf], r8
    FLAGS 0xAD7
    imul r8w, word [buf], 18880
    mov r10, 0x10000
    mov rdi, 0xFFFFFFFFFFFFFF85
    FLAGS 0x2D6
    imul r10w, di
    mov rdi, 0x4D8746184D3426AB
    FLAGS 0x2D6
    imul r10w, di, 1
    mov [buf], rdi
    FLAGS 0xA03
    imul di, word [buf], 127
    mov r8, 0x7FFF
    mov rsi, 0x7F
    FLAGS 0xA02
    imul r8w, si
    mov rsi, 0x100
    FLAGS 0x2D6
    imul r8w, si, -124
    mov [buf], rsi
    FLAGS 0xAD7
    imul si, word [buf], 18061
    mov r9, 0xDF
    mov rdi, 0xFFFFFFFF
    FLAGS 0x297
    imul r9w, di
    mov rdi, 0xC2347C9B173D7394
    FLAGS 0x212
    imul r9w, di, 127
    mov [buf], rdi
    FLAGS 0x202
    imul di, word [buf], -128
    mov rbp, 0x7935BD6C8D3E1B9F
    mov r8, 0xFFFFFFFFFFFFFF03
    FLAGS 0xA43
    imul bp, r8w
    mov r8, 0xF79D3133C992368
    FLAGS 0xAD7
    imul bp, r8w, -128
    mov [buf], r8
    FLAGS 0x2D6
    imul r8w, word [buf], 0
    mov rdx, 0xF7
    mov rax, 0xE3
    FLAGS 0x213
    imul dx, ax
    mov rax, 0x7A
    FLAGS 0x203
    imul dx, ax, 111
    mov [buf], rax
    FLAGS 0x246
    imul ax, word [buf], 12195
    mov r11, 0x80000000
    mov rax, 0x7FFFFFFFFFFFFFFF
    FLAGS 0x212
    imul r11w, ax
    mov rax, 0x7DC93B0875EA5801
    FLAGS 0x246
    imul r11w, ax, -1
    mov [buf], rax
    FLAGS 0x2D6
    imul ax, word [buf], 1
    mov r15, 0x80000000
    mov r10, 0xC5
    FLAGS 0x2D6
    imul r15d, r10d
    mov r10, 0xA3
    FLAGS 0xA43
    imul r15d, r10d, 59
    mov [buf], r10
    FLAGS 0x297
    imul r10d, dword [buf], -2147483648
    mov rsi, 0x7FFFFFFF
    mov r8, 0x2E84B481A72DA951
    FLAGS 0x213
    imul esi, r8d
    mov r8, 0x45E1204CD97F3A17
    FLAGS 0x202
    imul esi, r8d, -38
    mov [buf], r8
    FLAGS 0x202
    imul r8d, dword [buf], 2147483647
    mov r9, 0xA01454DF75893161
    mov r13, 0x1A
    FLAGS 0x246
    imul r9d, r13d
    mov r13, 0x48230AC1B80C0E4B
    FLAGS 0x212
    imul r9d, r13d, 10
    mov [buf], r13
    FLAGS 0xA82
    imul r13d, dword [buf], 2147483647
    mov rbp, 0x7FFFFFFFFFFFFFFF
    mov rsi, 0x10000
    FLAGS 0xA43
    imul ebp, esi
    mov rsi, 0x9BFFBB5F0E559971
    FLAGS 0xA43
    imul ebp, esi, 15
    mov [buf], rsi
    FLAGS 0x203
    imul esi, dword [buf], 2147483647
    mov r15, 0xFF
    mov r13, 0x4B07459539287C3F
    FLAGS 0x246
    imul r15d, r13d
    mov r13, 0x81
    FLAGS 0x202
    imul r15d, r13d, -66
    mov [buf], r13
    FLAGS 0x213
    imul r13d, dword [buf], -1059527901
    mov rbp, 0x8000
    mov r11, 0x1
    FLAGS 0xA02
    imul ebp, r11d
    mov r11, 0xFFFFFFFFFFFFFF45
    FLAGS 0x203
    imul ebp, r11d, -3
    mov [buf], r11
    FLAGS 0x212
    imul r11d, dword [buf], 2147483647
    mov r10, 0x81
    mov rax, 0xFF
    FLAGS 0x246
    imul r10d, eax
    mov rax, 0x41
    FLAGS 0x2D6
    imul r10d, eax, 27
    mov [buf], rax
    FLAGS 0x297
    imul eax, dword [buf], 5
    mov rdi, 0xF87AE93C27B10016
    mov rbx, 0xF6A6EEE4942EB8
    FLAGS 0xA02
    imul edi, ebx
    mov rbx, 0xA1
    FLAGS 0xA03
    imul edi, ebx, 1
    mov [buf], rbx
    FLAGS 0xA43
    imul ebx, dword [buf], -2147483648
    mov r13, 0xFFFFFFFF80000000
    mov r8, 0x2B0B79601DA5AD6C
    FLAGS 0xA82
    imul r13d, r8d
    mov r8, 0x0
    FLAGS 0x297
    imul r13d, r8d, 33
    mov [buf], r8
    FLAGS 0xA02
    imul r8d, dword [buf], 1404167986
    mov rdx, 0xFFFFFFFFFFFFFF80
    mov r13, 0xFFFFFFFFFFFFFFC6
    FLAGS 0x202
    imul edx, r13d
    mov r13, 0x100
    FLAGS 0xA82
    imul edx, r13d, -1
    mov [buf], r13
    FLAGS 0x203
    imul r13d, dword [buf], 127
    mov rbp, 0x77F517B7D5F85AB8
    mov r12, 0xDDA2DF1568E6A938
    FLAGS 0x246
    imul ebp, r12d
    mov r12, 0x3B1BACFB6F9608F2
    FLAGS 0xA03
    imul ebp, r12d, 47
    mov [buf], r12
    FLAGS 0x297
    imul r12d, dword [buf], -1
    mov r14, 0x4F00AEF5B30CB873
    mov r9, 0xF1F4511F8E44A1DE
    FLAGS 0x2D6
    imul r14d, r9d
    mov r9, 0x0
    FLAGS 0xA43
    imul r14d, r9d, -59
    mov [buf], r9
    FLAGS 0x246
    imul r9d, dword [buf], 936740080
    mov rsi, 0xFFFFFFFFFFFFFFE4
    mov r14, 0x3690E99C82C14FA7
    FLAGS 0xA03
    imul esi, r14d
    mov r14, 0xF53AF8E4824006AA
    FLAGS 0xA82
    imul esi, r14d, 60
    mov [buf], r14
    FLAGS 0x212
    imul r14d, dword [buf], 2147483647
    mov r15, 0x2
    mov rsi, 0x8000000000000000
    FLAGS 0x213
    imul r15d, esi
    mov rsi, 0x5E774C4DB47C6908
    FLAGS 0x202
    imul r15d, esi, 71
    mov [buf], rsi
    FLAGS 0x202
    imul esi, dword [buf], -477941301
    mov rdx, 0x1
    mov rcx, 0xB833E22903A92900
    FLAGS 0x297
    imul rdx, rcx
    mov rcx, 0x8000
    FLAGS 0x297
    imul rdx, rcx, 124
    mov [buf], rcx
    FLAGS 0x2D6
    imul rcx, qword [buf], -2147483648
    mov rsi, 0xFFFFFFFFFFFFFFE7
    mov r13, 0x51
    FLAGS 0x203
    imul rsi, r13
    mov r13, 0xFFFFFFFFFFFFFF51
    FLAGS 0x203
    imul rsi, r13, -111
    mov [buf], r13
    FLAGS 0xA43
    imul r13, qword [buf], -2147483648
    mov r14, 0xFFFFFFFF80000000
    mov rdx, 0x6C535BB6EAB45079
    FLAGS 0xA03
    imul r14, rdx
    mov rdx, 0x3
    FLAGS 0x213
    imul r14, rdx, 0
    mov [buf], rdx
    FLAGS 0xA03
    imul rdx, qword [buf], 1
    mov rcx, 0x81
    mov r8, 0x7FFFFFFF
    FLAGS 0x2D6
    imul rcx, r8
    mov r8, 0x6CC9D753D1B09FC8
    FLAGS 0x2D6
    imul rcx, r8, -36
    mov [buf], r8
    FLAGS 0x297
    imul r8, qword [buf], -2147483648
    mov r12, 0xFFFFFFFFFFFFFFFF
    mov r15, 0x141F48802AB01CF5
    FLAGS 0xA82
    imul r12, r15
    mov r15, 0x7FFF
    FLAGS 0xA02
    imul r12, r15, -92
    mov [buf], r15
    FLAGS 0xAD7
    imul r15, qword [buf], 2147483647
    mov r10, 0x74812BDEEA2278C8
    mov rcx, 0x3E1966F627A788CF
    FLAGS 0x212
    imul r10, rcx
    mov rcx, 0xE4EC2003C498056D
    FLAGS 0xA43
    imul r10, rcx, 127
    mov [buf], rcx
    FLAGS 0x203
    imul rcx, qword [buf], 2147483647
    mov rax, 0xC560C916D653FFA7
    mov r8, 0x7CDB5CFA16D2AFED
    FLAGS 0x212
    imul rax, r8
    mov r8, 0xC6E3A3F1C120BD87
    FLAGS 0xA03
    imul rax, r8, 32
    mov [buf], r8
    FLAGS 0xA43
    imul r8, qword [buf], 0
    mov rcx, 0x100000000
    mov rbp, 0xEB52C0DE9674745B
    FLAGS 0x2D6
    imul rcx, rbp
    mov rbp, 0xF98A46A092B788C3
    FLAGS 0x213
    imul rcx, rbp, 0
    mov [buf], rbp
    FLAGS 0x202
    imul rbp, qword [buf], 0
    mov rsi, 0x80
    mov rdi, 0xD6C253E62392A655
    FLAGS 0xA82
    imul rsi, rdi
    mov rdi, 0x7844581BAD3212F9
    FLAGS 0x2D6
    imul rsi, rdi, 83
    mov [buf], rdi
    FLAGS 0xA82
    imul rdi, qword [buf], 2147483647
    mov rax, 0x3FE4478E2D63BBD6
    mov rbp, 0x6F25C6762E184D96
    FLAGS 0x297
    imul rax, rbp
    mov rbp, 0xFFFFFFFFFFFFFFDD
    FLAGS 0x246
    imul rax, rbp, -18
    mov [buf], rbp
    FLAGS 0x202
    imul rbp, qword [buf], -2147483648
    mov r9, 0x7FFFFFFF
    mov rsi, 0x22
    FLAGS 0x246
    imul r9, rsi
    mov rsi, 0xE087DC0F24436B4D
    FLAGS 0xA03
    imul r9, rsi, 1
    mov [buf], rsi
    FLAGS 0x2D6
    imul rsi, qword [buf], -2147483648
    mov r9, 0xFFFFFFFFFFFFFFFB
    mov r10, 0x80
    FLAGS 0xAD7
    imul r9, r10
    mov r10, 0xAE19B04545C8F9A
    FLAGS 0xA82
    imul r9, r10, 127
    mov [buf], r10
    FLAGS 0x212
    imul r10, qword [buf], -2147483648
    mov r14, 0x9FC366949FF1B812
    mov r13, 0xF3B5206E97E88E5B
    FLAGS 0xA82
    imul r14, r13
    mov r13, 0xFFFFFFFFFFFFFF69
    FLAGS 0xAD7
    imul r14, r13, 48
    mov [buf], r13
    FLAGS 0xA43
    imul r13, qword [buf], 2147483647
    mov r12, 0x6F
    mov r11, 0x75EEBC7B823F4920
    FLAGS 0x246
    imul r12, r11
    mov r11, 0x5E893980976EBE94
    FLAGS 0x297
    imul r12, r11, 127
    mov [buf], r11
    FLAGS 0x213
    imul r11, qword [buf], 360186107
    mov rax, 0x733FC5A45FF06AD4
    mov rbp, 0x664B04BE1CCCED8B
    FLAGS 0xAD7
    div bpl
    mov rax, 0xB99C7703D5BE115F
    mov r15, 0x1F288C7626BA1723
    FLAGS 0xAD7
    div r15b
    mov rax, 0xA8D638D07BBB004A
    mov r10, 0x6327224F92488401
    FLAGS 0x212
    div r10b
    mov rax, 0x2A77985CB5AD00FF
    mov r8, 0xE8B4123DB68E8701
    FLAGS 0x297
    div r8b
    mov rax, 0x9F2EBD2985C88C2E
    mov r14, 0x1143A5B969BEA3C5
    FLAGS 0x203
    div r14b
    mov rax, 0x19126EEBC9A5000A
    mov rbx, 0x58C6A0846F513A09
    FLAGS 0xA43
    div bl
    mov rax, 0x5FFB669442C81BFF
    mov rbx, 0x72312A3315B2D01C
    FLAGS 0x212
    div bl
    mov rax, 0x375DF7E8542B036B
    mov r12, 0x666DB5E78C59C4E5
    FLAGS 0xA02
    div r12b
    mov rax, 0xFD062D01BE3E1EED
    mov r8, 0x720A05588C4E5A1F
    FLAGS 0xAD7
    div r8b
    mov rax, 0x12B99E1EEF9300B8
    mov r12, 0x6A86E3C523D9D2FF
    FLAGS 0x246
    div r12b
    mov rax, 0xD5458DE63BAD00D6
    mov rbx, 0x76A149EF7D0F0601
    FLAGS 0x297
    div bl
    mov rax, 0x62DEA614DFF00FF
    mov rdi, 0x2B07C1B15064D601
    FLAGS 0x297
    div dil
    mov rax, 0x795C34FE5258268E
    mov r8, 0x801F1015200F1681
    FLAGS 0x297
    div r8b
    mov rax, 0xFFECDF517AF500EB
    mov r15, 0x704A8F8BD61D7C01
    FLAGS 0xA43
    div r15b
    mov rax, 0xFF2E
    mov r8, 0xD6
    FLAGS 0x246
    idiv r8b
    mov rax, 0xFFA0
    mov r9, 0xE0
    FLAGS 0x213
    idiv r9b
    mov rax, 0xFFEA
    mov r14, 0x1F
    FLAGS 0x212
    idiv r14b
    mov rax, 0x7F
    mov r8, 0x1
    FLAGS 0xA43
    idiv r8b
    mov rax, 0xFFC2
    mov r15, 0x1
    FLAGS 0x202
    idiv r15b
    mov rax, 0x5F
    mov r9, 0xFF
    FLAGS 0xA02
    idiv r9b
    mov rax, 0x25
    mov rsi, 0xCE
    FLAGS 0x203
    idiv sil
    mov rax, 0xF832
    mov r15, 0x81
    FLAGS 0x297
    idiv r15b
    mov rax, 0xF12A
    mov r13, 0x94
    FLAGS 0xA43
    idiv r13b
    mov rax, 0x69B
    mov r9, 0xEE
    FLAGS 0x203
    idiv r9b
    mov rax, 0xFF81
    mov r11, 0xFF
    FLAGS 0x246
    idiv r11b
    mov rax, 0xFFDA
    mov r14, 0xB4
    FLAGS 0xAD7
    idiv r14b
    mov rax, 0x69
    mov r14, 0xFF
    FLAGS 0xA03
    idiv r14b
    mov rax, 0x5C
    mov rdi, 0x81
    FLAGS 0x212
    idiv dil
    mov rax, 0x6F1ABF288C9800B5
    mov rdx, 0xA1041F428330000
    mov r8, 0xFF891A32430B00D8
    FLAGS 0xA43
    div r8w
    mov rax, 0x11D92F2B9E0E7E8C
    mov rdx, 0xE8CE299753160000
    mov r15, 0xD53377A10F900FF
    FLAGS 0x246
    div r15w
    mov rax, 0x59E2A45910F90038
    mov rdx, 0x99E541396A940000
    mov r11, 0x4D46ECFDF3680001
    FLAGS 0x212
    div r11w
    mov rax, 0xDE633B71931EFFFF
    mov rdx, 0x347F9EB1E3CC0000
    mov r13, 0x4D6ADCC7E3450001
    FLAGS 0x203
    div r13w
    mov rax, 0xE522F036BF36A019
    mov rdx, 0x4111F7D0FC7872BF
    mov rsi, 0x6C9CBF342A51D8A0
    FLAGS 0xA43
    div si
    mov rax, 0xA8900607DBBDFFA9
    mov rdx, 0xB5D3BCA66FF3007F
    mov rsi, 0x1DD562AEFB10100
    FLAGS 0xA02
    div si
    mov rax, 0x4561188713A50100
    mov rdx, 0x68EE8B21C1AF0000
    mov r13, 0xFC4DF92E1FAC0001
    FLAGS 0xA03
    div r13w
    mov rax, 0x8624E2ED5C580003
    mov rdx, 0xAA6A013F44DA0000
    mov rbp, 0xB421494BFEE90001
    FLAGS 0x246
    div bp
    mov rax, 0x9EED0C62E5BE7763
    mov rdx, 0x339DC7E3A5C70000
    mov r14, 0xBC85B32BDC84B5ED
    FLAGS 0x2D6
    div r14w
    mov rax, 0x5DF922379EEB1444
    mov rdx, 0x63C5C46BA2D150F8
    mov rcx, 0xBBD69B458A0B7FFF
    FLAGS 0x203
    div cx
    mov rax, 0x4C4D487FA5B7F11B
    mov rdx, 0x7F919A12D4574154
    mov rbx, 0x97CB921A4974166
    FLAGS 0x297
    div bx
    mov rax, 0x235B26094DEEAD84
    mov rdx, 0xC086E9C12529FFFE
    mov r8, 0x20CDA044B276FFFF
    FLAGS 0xA03
    div r8w
    mov rax, 0xC5ADB8B28EDA165F
    mov rdx, 0xCD1DBAB97D6C8BDE
    mov rsi, 0x29892E0C9304FFFF
    FLAGS 0xA82
    div si
    mov rax, 0x9C382CDF622D62F5
    mov rdx, 0x80CA01D0474B1978
    mov rbx, 0xAF72F3A6864CEBEF
    FLAGS 0x212
    div bx
    mov rax, 0x50F1
    mov rdx, 0x0
    mov r11, 0xA3C1
    FLAGS 0x297
    idiv r11w
    mov rax, 0x8001
    mov rdx, 0xFFFF
    mov r9, 0x1
    FLAGS 0x203
    idiv r9w
    mov rax, 0x7FFF
    mov rdx, 0x0
    mov r13, 0x1
    FLAGS 0xA43
    idiv r13w
    mov rax, 0x975F
    mov rdx, 0xFE7B
    mov r10, 0x6CB7
    FLAGS 0xA03
    idiv r10w
    mov rax, 0xFFA8
    mov rdx, 0xFFFF
    mov r15, 0x2
    FLAGS 0x2D6
    idiv r15w
    mov rax, 0x210
    mov rdx, 0xFFE0
    mov r9, 0x51
    FLAGS 0xAD7
    idiv r9w
    mov rax, 0xFC7E
    mov rdx, 0xC000
    mov r13, 0x7FFF
    FLAGS 0x213
    idiv r13w
    mov rax, 0x3934
    mov rdx, 0xF62F
    mov r11, 0x4276
    FLAGS 0x203
    idiv r11w
    mov rax, 0x185
    mov rdx, 0x0
    mov r13, 0x3
    FLAGS 0x2D6
    idiv r13w
    mov rax, 0x2018
    mov rdx, 0xFFBC
    mov rcx, 0xFF07
    FLAGS 0xA03
    idiv cx
    mov rax, 0x4C4C
    mov rdx, 0x76
    mov r15, 0x76A5
    FLAGS 0xA82
    idiv r15w
    mov rax, 0xC9B2
    mov rdx, 0xFFBF
    mov rdi, 0x8001
    FLAGS 0x203
    idiv di
    mov rax, 0x8076
    mov rdx, 0xFFFF
    mov r8, 0x1
    FLAGS 0x202
    idiv r8w
    mov rax, 0xA312
    mov rdx, 0xFC5D
    mov rbp, 0x8DA3
    FLAGS 0xA03
    idiv bp
    mov rax, 0xB1FC3302F2C076DF
    mov rdx, 0xDB50421F0000001C
    mov r12, 0x935775200000100
    FLAGS 0x213
    div r12d
    mov rax, 0x4B8898115F01F845
    mov rdx, 0xE6860DC500000000
    mov r10, 0x70FA793BB176D1DC
    FLAGS 0x202
    div r10d
    mov rax, 0xABAE4BC8C4DCBFF4
    mov rdx, 0x4989318BD1B4988A
    mov rbx, 0xB82587D9D1B4988B
    FLAGS 0x213
    div ebx
    mov rax, 0x8202D13CB0BF3FD0
    mov rdx, 0xA63853A500000000
    mov r10, 0x3546CE1100000001
    FLAGS 0xAD7
    div r10d
    mov rax, 0x582B3C50CB38007E
    mov rdx, 0x25DE1C9236661A1D
    mov r9, 0xC65E11F684EC083
    FLAGS 0x202
    div r9d
    mov rax, 0xFB8F70520100255E
    mov rdx, 0xEF64A41E00000000
    mov r14, 0xCD7AD50E00010000
    FLAGS 0xA03
    div r14d
    mov rax, 0xD56A2B89E2AD43A1
    mov rdx, 0xE688C46B0000005D
    mov r14, 0xF59D4AC300000081
    FLAGS 0x297
    div r14d
    mov rax, 0xF69179750000FFFF
    mov rdx, 0xD3C78F2C00000000
    mov r15, 0xFA7A0A6D00000001
    FLAGS 0x246
    div r15d
    mov rax, 0x1FF1CBED0000312B
    mov rdx, 0x94609B5D00000000
    mov r9, 0xFFAF80D000000DB
    FLAGS 0xA43
    div r9d
    mov rax, 0x54E2E7F400007FBB
    mov rdx, 0x4B840C5000000000
    mov r14, 0x5564EE700000100
    FLAGS 0x213
    div r14d
    mov rax, 0xADCDA3470000FF3A
    mov rdx, 0x7EEA33BA00000000
    mov rbx, 0x46DF8662000000FF
    FLAGS 0xA03
    div ebx
    mov rax, 0x8A1EED5A22C88CA4
    mov rdx, 0x51636D3F00000023
    mov rbp, 0xAE9A065946B6CDE1
    FLAGS 0x213
    div ebp
    mov rax, 0x7C395D8C0F83B9B
    mov rdx, 0x16F7FFA051C05293
    mov rsi, 0xFFDE557DA380A527
    FLAGS 0xA03
    div esi
    mov rax, 0x23DDC2970000034D
    mov rdx, 0x4D394BB00000000
    mov rsi, 0x3DBF43000000FF
    FLAGS 0x213
    div esi
    mov rax, 0x7FFFF264
    mov rdx, 0x40
    mov r15, 0xFFFFFF7F
    FLAGS 0xA02
    idiv r15d
    mov rax, 0xEDF5E5D6
    mov rdx, 0x14EB26F5
    mov r9, 0xAEE3CEC3
    FLAGS 0xA82
    idiv r9d
    mov rax, 0x3BF512D1
    mov rdx, 0x6FC4C87
    mov rcx, 0xE10E179
    FLAGS 0xA03
    idiv ecx
    mov rax, 0xFFFFFFAC
    mov rdx, 0xFFFFFFFF
    mov rdi, 0x81
    FLAGS 0x212
    idiv edi
    mov rax, 0x80000041
    mov rdx, 0xFFFFFFFE
    mov r8, 0x3
    FLAGS 0xA02
    idiv r8d
    mov rax, 0x6A6B024
    mov rdx, 0xFFFFFFFC
    mov r12, 0x908CBE6
    FLAGS 0xA82
    idiv r12d
    mov rax, 0xCFCA38F
    mov rdx, 0x236B2DFA
    mov r13, 0x83C0CC14
    FLAGS 0x212
    idiv r13d
    mov rax, 0x48AA98A2
    mov rdx, 0x9
    mov r13, 0xFFFFFF00
    FLAGS 0x202
    idiv r13d
    mov rax, 0xBE99B875
    mov rdx, 0x1353C007
    mov r14, 0x7FFFFFFF
    FLAGS 0xAD7
    idiv r14d
    mov rax, 0xEA661C19
    mov rdx, 0xFFFFD9DA
    mov r14, 0xD9DB0702
    FLAGS 0x213
    idiv r14d
    mov rax, 0xD61264CF
    mov rdx, 0xD14B64DF
    mov rcx, 0xA296C9A8
    FLAGS 0xA02
    idiv ecx
    mov rax, 0x8000
    mov rdx, 0x0
    mov rdi, 0xFFFFFFFF
    FLAGS 0x202
    idiv edi
    mov rax, 0x7FFFFFAC
    mov rdx, 0x0
    mov r14, 0x1
    FLAGS 0xA03
    idiv r14d
    mov rax, 0xF5B21803
    mov rdx, 0xFFFFAC3A
    mov r10, 0x10000
    FLAGS 0xA43
    idiv r10d
    mov rax, 0x549139D946445DE5
    mov rdx, 0x83691F730FEDD2B
    mov r11, 0xFFFFFFFFFFFFFF2F
    FLAGS 0xA82
    div r11
    mov rax, 0x5EB97307DC2C7985
    mov rdx, 0xFA1A
    mov rsi, 0xFA1A291E4C4B7318
    FLAGS 0x212
    div rsi
    mov rax, 0x67EDDE90CC72B07A
    mov rdx, 0x2
    mov r12, 0x3
    FLAGS 0xA02
    div r12
    mov rax, 0xD495DD00A837F35D
    mov rdx, 0xD62C477A46B40816
    mov rbx, 0xD8FE5DE1119EEB40
    FLAGS 0x2D6
    div rbx
    mov rax, 0xCC8B2805A65EFB82
    mov rdx, 0x4609EA86
    mov rbx, 0x100000000
    FLAGS 0xA82
    div rbx
    mov rax, 0x5C37AA0ECDE13D5
    mov rdx, 0x25164140
    mov r10, 0x4A2C828063A3BCD0
    FLAGS 0x203
    div r10
    mov rax, 0x93240D9738585078
    mov rdx, 0x5D9C
    mov r10, 0x7FFF
    FLAGS 0x203
    div r10
    mov rax, 0x24A68F8C474939F7
    mov rdx, 0x0
    mov rbx, 0x68D8B73D9D959DC7
    FLAGS 0x213
    div rbx
    mov rax, 0xEAC7A9F9F2B36911
    mov rdx, 0x23994D106216F475
    mov rcx, 0x47329A20C42DE8EC
    FLAGS 0xA43
    div rcx
    mov rax, 0xD7CE4D0333BDA655
    mov rdx, 0x59E4
    mov r8, 0xB3C8BEDAE3E0D198
    FLAGS 0xA02
    div r8
    mov rax, 0xFFFFFFFFFFFF8090
    mov rdx, 0xFE
    mov r12, 0xFF
    FLAGS 0x203
    div r12
    mov rax, 0x211787412B6CC6A7
    mov rdx, 0x7FFFFFFFFFFFFFC1
    mov r9, 0x7FFFFFFFFFFFFFFF
    FLAGS 0x297
    div r9
    mov rax, 0x28A95BF993C77479
    mov rdx, 0x21
    mov rbp, 0x2121C859074098B2
    FLAGS 0xA02
    div rbp
    mov rax, 0xB5D62F30F29112C3
    mov rdx, 0x2
    mov r14, 0x33AF986BDC34DB0
    FLAGS 0x212
    div r14
    mov rax, 0x85CAB67D8FFA157C
    mov rdx, 0xEFC05BF8EF5CA4A8
    mov r13, 0xDF80B7F1BE3A0143
    FLAGS 0x213
    idiv r13
    mov rax, 0xC117FC33BC
    mov rdx, 0xFFFFFFFF80000000
    mov rbx, 0x100000000
    FLAGS 0x203
    idiv rbx
    mov rax, 0xC87888C80059978B
    mov rdx, 0xD12877A66C60BB6A
    mov r13, 0xA250EF4CD8C17678
    FLAGS 0xAD7
    idiv r13
    mov rax, 0xD29B7A5443FC32B7
    mov rdx, 0xF621D6F97D620DC2
    mov r12, 0x24575800D4355487
    FLAGS 0x212
    idiv r12
    mov rax, 0xD19819A728C0A9EF
    mov rdx, 0x187D0E117DA30718
    mov rdi, 0x3B68E2BB05E69E14
    FLAGS 0xA82
    idiv rdi
    mov rax, 0x4984E654ACC892F8
    mov rdx, 0xFFFFFFFFFFFFFFAA
    mov r9, 0x870CB74A23DA27BA
    FLAGS 0x297
    idiv r9
    mov rax, 0xFFFFFFFFFFFFFF8A
    mov rdx, 0x7F
    mov rcx, 0x100
    FLAGS 0x203
    idiv rcx
    mov rax, 0xE18E86787C26A08C
    mov rdx, 0x1D880C97AA3F87F6
    mov rdi, 0xC4EFE6D0AB80F012
    FLAGS 0x2D6
    idiv rdi
    mov rax, 0x59FE5130DF8491D8
    mov rdx, 0x3F00
    mov r13, 0x8000
    FLAGS 0x212
    idiv r13
    mov rax, 0xF458DD2466662E8B
    mov rdx, 0x4EBE0B7A0700603
    mov r11, 0xC597F45B9B7F25E
    FLAGS 0x203
    idiv r11
    mov rax, 0xFF65F70611228F7E
    mov rdx, 0xD
    mov rdi, 0x13E88172DB545EB8
    FLAGS 0xA82
    idiv rdi
    mov rax, 0x921D7433804C2CF8
    mov rdx, 0x7FFFFFFF
    mov rcx, 0x7FFFFFFFFFFFFFF7
    FLAGS 0x212
    idiv rcx
    mov rax, 0x204EEABBF83C84F3
    mov rdx, 0xFFFFFFFFFFFFFFD5
    mov rbx, 0xFFFFFFFFFFFFFF81
    FLAGS 0xA02
    idiv rbx
    mov rax, 0x1E21103D56E7A4B3
    mov rdx, 0x0
    mov rbp, 0xF647A3A0F4CD7764
    FLAGS 0xA02
    idiv rbp
    EXIT
    align 16
buf: times 64 dq 0x0123456789ABCDEF
file_end:
