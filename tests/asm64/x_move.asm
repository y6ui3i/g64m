; The moves of SSE and SSE2 between XMM registers, memory and general registers; shuffles and unpacking.
; Written by tools/gen64_tests.py: change that, not this.
%include "elf.inc"
    movdqu xmm10, [c0]
    movaps xmm5, xmm10
    movaps [buf + 32], xmm5
    movdqu xmm10, [c1]
    movaps xmm10, [buf + 32]
    movdqu xmm5, [c2]
    movaps xmm4, xmm5
    movaps [buf + 32], xmm4
    movdqu xmm5, [c3]
    movaps xmm5, [buf + 32]
    movdqu xmm5, [c4]
    movaps xmm9, xmm5
    movaps [buf + 32], xmm9
    movdqu xmm5, [c5]
    movaps xmm5, [buf + 32]
    movdqu xmm3, [c6]
    movups xmm10, xmm3
    movups [buf + 32], xmm10
    movdqu xmm3, [c7]
    movups xmm3, [buf + 32]
    movdqu xmm15, [c8]
    movups xmm10, xmm15
    movups [buf + 32], xmm10
    movdqu xmm15, [c9]
    movups xmm15, [buf + 32]
    movdqu xmm7, [c10]
    movups xmm14, xmm7
    movups [buf + 32], xmm14
    movdqu xmm7, [c11]
    movups xmm7, [buf + 32]
    movdqu xmm7, [c12]
    movapd xmm6, xmm7
    movapd [buf + 32], xmm6
    movdqu xmm7, [c13]
    movapd xmm7, [buf + 32]
    movdqu xmm7, [c14]
    movapd xmm9, xmm7
    movapd [buf + 32], xmm9
    movdqu xmm7, [c15]
    movapd xmm7, [buf + 32]
    movdqu xmm13, [c16]
    movapd xmm0, xmm13
    movapd [buf + 32], xmm0
    movdqu xmm13, [c17]
    movapd xmm13, [buf + 32]
    movdqu xmm10, [c18]
    movupd xmm15, xmm10
    movupd [buf + 32], xmm15
    movdqu xmm10, [c19]
    movupd xmm10, [buf + 32]
    movdqu xmm3, [c20]
    movupd xmm11, xmm3
    movupd [buf + 32], xmm11
    movdqu xmm3, [c21]
    movupd xmm3, [buf + 32]
    movdqu xmm13, [c22]
    movupd xmm11, xmm13
    movupd [buf + 32], xmm11
    movdqu xmm13, [c23]
    movupd xmm13, [buf + 32]
    movdqu xmm12, [c24]
    movdqa xmm0, xmm12
    movdqa [buf + 32], xmm0
    movdqu xmm12, [c25]
    movdqa xmm12, [buf + 32]
    movdqu xmm1, [c26]
    movdqa xmm6, xmm1
    movdqa [buf + 32], xmm6
    movdqu xmm1, [c27]
    movdqa xmm1, [buf + 32]
    movdqu xmm1, [c28]
    movdqa xmm9, xmm1
    movdqa [buf + 32], xmm9
    movdqu xmm1, [c29]
    movdqa xmm1, [buf + 32]
    movdqu xmm13, [c30]
    movdqu xmm3, xmm13
    movdqu [buf + 32], xmm3
    movdqu xmm13, [c31]
    movdqu xmm13, [buf + 32]
    movdqu xmm9, [c32]
    movdqu xmm11, xmm9
    movdqu [buf + 32], xmm11
    movdqu xmm9, [c33]
    movdqu xmm9, [buf + 32]
    movdqu xmm11, [c34]
    movdqu xmm10, xmm11
    movdqu [buf + 32], xmm10
    movdqu xmm11, [c35]
    movdqu xmm11, [buf + 32]
    movdqu xmm12, [c36]
    movdqu xmm7, [c37]
    movss xmm7, xmm12
    movss [buf + 8], xmm7
    movss xmm12, [buf + 16]
    mov rax, [buf + 8]
    movdqu xmm2, [c38]
    movdqu xmm7, [c39]
    movss xmm7, xmm2
    movss [buf + 8], xmm7
    movss xmm2, [buf + 16]
    mov rax, [buf + 8]
    movdqu xmm13, [c40]
    movdqu xmm11, [c41]
    movss xmm11, xmm13
    movss [buf + 8], xmm11
    movss xmm13, [buf + 16]
    mov rax, [buf + 8]
    movdqu xmm13, [c42]
    movdqu xmm12, [c43]
    movss xmm12, xmm13
    movss [buf + 8], xmm12
    movss xmm13, [buf + 16]
    mov rax, [buf + 8]
    movdqu xmm14, [c44]
    movdqu xmm1, [c45]
    movsd xmm1, xmm14
    movsd [buf + 8], xmm1
    movsd xmm14, [buf + 16]
    mov rax, [buf + 8]
    movdqu xmm3, [c46]
    movdqu xmm4, [c47]
    movsd xmm4, xmm3
    movsd [buf + 8], xmm4
    movsd xmm3, [buf + 16]
    mov rax, [buf + 8]
    movdqu xmm13, [c48]
    movdqu xmm5, [c49]
    movsd xmm5, xmm13
    movsd [buf + 8], xmm5
    movsd xmm13, [buf + 16]
    mov rax, [buf + 8]
    movdqu xmm5, [c50]
    movdqu xmm14, [c51]
    movsd xmm14, xmm5
    movsd [buf + 8], xmm14
    movsd xmm5, [buf + 16]
    mov rax, [buf + 8]
    movdqu xmm2, [c52]
    mov rsi, 0x149039F0DEF6E432
    mov r14, 0xFFFFFFFF
    movd esi, xmm2
    movq r14, xmm2
    mov rsi, 0xFFFFFFFFFFFFFF8A
    movd xmm11, esi
    movq xmm2, rsi
    movd [buf], xmm11
    movq [buf + 8], xmm2
    movdqu xmm2, [c53]
    movd xmm2, dword [buf + 8]
    movq xmm11, qword [buf + 8]
    movdqu xmm11, [c54]
    movq xmm11, xmm2
    mov rax, [buf]
    mov rdx, [buf + 8]
    movdqu xmm9, [c55]
    mov r15, 0xFFFFFFFF
    mov rbp, 0xAE
    movd r15d, xmm9
    movq rbp, xmm9
    mov r15, 0x7FFFFFFF
    movd xmm3, r15d
    movq xmm9, r15
    movd [buf], xmm3
    movq [buf + 8], xmm9
    movdqu xmm9, [c56]
    movd xmm9, dword [buf + 8]
    movq xmm3, qword [buf + 8]
    movdqu xmm3, [c57]
    movq xmm3, xmm9
    mov rax, [buf]
    mov rdx, [buf + 8]
    movdqu xmm3, [c58]
    mov rcx, 0x49F4B713F4FEFAF2
    mov r8, 0x2
    movd ecx, xmm3
    movq r8, xmm3
    mov rcx, 0xFFFFFFFF
    movd xmm14, ecx
    movq xmm3, rcx
    movd [buf], xmm14
    movq [buf + 8], xmm3
    movdqu xmm3, [c59]
    movd xmm3, dword [buf + 8]
    movq xmm14, qword [buf + 8]
    movdqu xmm14, [c60]
    movq xmm14, xmm3
    mov rax, [buf]
    mov rdx, [buf + 8]
    movdqu xmm6, [c61]
    mov rsi, 0xFFFF
    mov r10, 0x2
    movd esi, xmm6
    movq r10, xmm6
    mov rsi, 0x276DB521DCEE4FA9
    movd xmm15, esi
    movq xmm6, rsi
    movd [buf], xmm15
    movq [buf + 8], xmm6
    movdqu xmm6, [c62]
    movd xmm6, dword [buf + 8]
    movq xmm15, qword [buf + 8]
    movdqu xmm15, [c63]
    movq xmm15, xmm6
    mov rax, [buf]
    mov rdx, [buf + 8]
    movdqu xmm0, [c64]
    movlps [buf + 24], xmm0
    movlps xmm0, [buf + 40]
    mov rax, [buf + 24]
    movdqu xmm1, [c65]
    movhps [buf + 24], xmm1
    movhps xmm1, [buf + 40]
    mov rax, [buf + 24]
    movdqu xmm5, [c66]
    movlpd [buf + 24], xmm5
    movlpd xmm5, [buf + 40]
    mov rax, [buf + 24]
    movdqu xmm11, [c67]
    movhpd [buf + 24], xmm11
    movhpd xmm11, [buf + 40]
    mov rax, [buf + 24]
    movdqu xmm5, [c68]
    movdqu xmm1, [c69]
    movhlps xmm5, xmm1
    movdqu xmm5, [c70]
    movdqu xmm3, [c71]
    movhlps xmm5, xmm3
    movdqu xmm7, [c72]
    movdqu xmm5, [c73]
    movlhps xmm7, xmm5
    movdqu xmm6, [c74]
    movdqu xmm15, [c75]
    movlhps xmm6, xmm15
    movdqu xmm13, [c76]
    movdqu xmm7, [c77]
    unpcklps xmm13, xmm7
    unpcklps xmm7, [c78]
    movdqu xmm6, [c79]
    movdqu xmm1, [c80]
    unpcklps xmm6, xmm1
    unpcklps xmm1, [c81]
    movdqu xmm0, [c82]
    movdqu xmm8, [c83]
    unpckhps xmm0, xmm8
    unpckhps xmm8, [c84]
    movdqu xmm1, [c85]
    movdqu xmm13, [c86]
    unpckhps xmm1, xmm13
    unpckhps xmm13, [c87]
    movdqu xmm7, [c88]
    movdqu xmm0, [c89]
    unpcklpd xmm7, xmm0
    unpcklpd xmm0, [c90]
    movdqu xmm6, [c91]
    movdqu xmm2, [c92]
    unpcklpd xmm6, xmm2
    unpcklpd xmm2, [c93]
    movdqu xmm1, [c94]
    movdqu xmm3, [c95]
    unpckhpd xmm1, xmm3
    unpckhpd xmm3, [c96]
    movdqu xmm11, [c97]
    movdqu xmm8, [c98]
    unpckhpd xmm11, xmm8
    unpckhpd xmm8, [c99]
    movdqu xmm6, [c100]
    movntps [buf + 48], xmm6
    mov rax, [buf + 48]
    mov rdx, [buf + 56]
    movdqu xmm14, [c101]
    movntpd [buf + 48], xmm14
    mov rax, [buf + 48]
    mov rdx, [buf + 56]
    movdqu xmm12, [c102]
    movntdq [buf + 48], xmm12
    mov rax, [buf + 48]
    mov rdx, [buf + 56]
    mov rbx, 0x5387E82AA6B5244F
    movnti [buf + 64], ebx
    movnti [buf + 72], rbx
    mov rax, [buf + 64]
    mov rdx, [buf + 72]
    movdqu xmm10, [c103]
    mov rbp, 0xFF
    movmskps ebp, xmm10
    mov rbp, 0x9B
    movmskpd ebp, xmm10
    mov rbp, 0xC64AF5FD408BA2F0
    pmovmskb ebp, xmm10
    pextrw ebp, xmm10, 1
    mov rbp, 0x267D1D9823D61A87
    pinsrw xmm10, ebp, 7
    pinsrw xmm10, word [buf + 1], 7
    movdqu xmm0, [c104]
    mov r10, 0xAF741A818CD49530
    movmskps r10d, xmm0
    mov r10, 0x681E63677F1570CD
    movmskpd r10d, xmm0
    mov r10, 0xFFFFFFFFFFFFFFC7
    pmovmskb r10d, xmm0
    pextrw r10d, xmm0, 3
    mov r10, 0xDB82170A28CDE9A9
    pinsrw xmm0, r10d, 3
    pinsrw xmm0, word [buf + 1], 2
    movdqu xmm7, [c105]
    mov r12, 0x56
    movmskps r12d, xmm7
    mov r12, 0xFF
    movmskpd r12d, xmm7
    mov r12, 0xB40DAF5BDAA07BBF
    pmovmskb r12d, xmm7
    pextrw r12d, xmm7, 1
    mov r12, 0x73
    pinsrw xmm7, r12d, 4
    pinsrw xmm7, word [buf + 1], 3
    movdqu xmm12, [c106]
    mov r9, 0xFFFF
    movmskps r9d, xmm12
    mov r9, 0x0
    movmskpd r9d, xmm12
    mov r9, 0x7FFFFFFF
    pmovmskb r9d, xmm12
    pextrw r9d, xmm12, 2
    mov r9, 0xDB764E9AD2F3FE02
    pinsrw xmm12, r9d, 2
    pinsrw xmm12, word [buf + 1], 1
    movdqu xmm7, [c107]
    mov r14, 0xFF
    movmskps r14d, xmm7
    mov r14, 0x81
    movmskpd r14d, xmm7
    mov r14, 0x7FFFFFFFFFFFFFFF
    pmovmskb r14d, xmm7
    pextrw r14d, xmm7, 2
    mov r14, 0x46785672CB4850E0
    pinsrw xmm7, r14d, 3
    pinsrw xmm7, word [buf + 1], 0
    movdqu xmm7, [c108]
    mov rdi, 0x1
    movmskps edi, xmm7
    mov rdi, 0x571B71787C85A2DC
    movmskpd edi, xmm7
    mov rdi, 0x8000
    pmovmskb edi, xmm7
    pextrw edi, xmm7, 3
    mov rdi, 0x100
    pinsrw xmm7, edi, 4
    pinsrw xmm7, word [buf + 1], 1
    movdqu xmm11, [c109]
    movdqu xmm5, [c110]
    shufps xmm11, xmm5, 0x64
    shufps xmm5, [c111], 0xF5
    movdqu xmm1, [c112]
    movdqu xmm3, [c113]
    shufps xmm1, xmm3, 0xC1
    shufps xmm3, [c114], 0xE6
    movdqu xmm2, [c115]
    movdqu xmm9, [c116]
    shufps xmm2, xmm9, 0x9E
    shufps xmm9, [c117], 0xEB
    movdqu xmm13, [c118]
    movdqu xmm4, [c119]
    shufps xmm13, xmm4, 0xBD
    shufps xmm4, [c120], 0x87
    movdqu xmm0, [c121]
    movdqu xmm6, [c122]
    shufps xmm0, xmm6, 0x87
    shufps xmm6, [c123], 0xAC
    movdqu xmm10, [c124]
    movdqu xmm11, [c125]
    shufpd xmm10, xmm11, 0xA0
    shufpd xmm11, [c126], 0x90
    movdqu xmm13, [c127]
    movdqu xmm9, [c128]
    shufpd xmm13, xmm9, 0x0
    shufpd xmm9, [c129], 0xA3
    movdqu xmm2, [c130]
    movdqu xmm15, [c131]
    shufpd xmm2, xmm15, 0x4
    shufpd xmm15, [c132], 0xB6
    movdqu xmm11, [c133]
    movdqu xmm15, [c134]
    shufpd xmm11, xmm15, 0x55
    shufpd xmm15, [c135], 0xE1
    movdqu xmm6, [c136]
    movdqu xmm11, [c137]
    shufpd xmm6, xmm11, 0xBC
    shufpd xmm11, [c138], 0xE6
    movdqu xmm5, [c139]
    movdqu xmm0, [c140]
    pshufd xmm5, xmm0, 0xB6
    pshufd xmm0, [c141], 0x4C
    movdqu xmm10, [c142]
    movdqu xmm15, [c143]
    pshufd xmm10, xmm15, 0xE8
    pshufd xmm15, [c144], 0x4D
    movdqu xmm8, [c145]
    movdqu xmm13, [c146]
    pshufd xmm8, xmm13, 0x5C
    pshufd xmm13, [c147], 0xE5
    movdqu xmm3, [c148]
    movdqu xmm4, [c149]
    pshufd xmm3, xmm4, 0x9A
    pshufd xmm4, [c150], 0x79
    movdqu xmm5, [c151]
    movdqu xmm9, [c152]
    pshufd xmm5, xmm9, 0x95
    pshufd xmm9, [c153], 0x69
    movdqu xmm2, [c154]
    movdqu xmm4, [c155]
    pshufhw xmm2, xmm4, 0xE5
    pshufhw xmm4, [c156], 0xDE
    movdqu xmm10, [c157]
    movdqu xmm9, [c158]
    pshufhw xmm10, xmm9, 0x32
    pshufhw xmm9, [c159], 0xF6
    movdqu xmm11, [c160]
    movdqu xmm13, [c161]
    pshufhw xmm11, xmm13, 0xD2
    pshufhw xmm13, [c162], 0x6F
    movdqu xmm9, [c163]
    movdqu xmm5, [c164]
    pshufhw xmm9, xmm5, 0x15
    pshufhw xmm5, [c165], 0x79
    movdqu xmm5, [c166]
    movdqu xmm6, [c167]
    pshufhw xmm5, xmm6, 0xF0
    pshufhw xmm6, [c168], 0xCA
    movdqu xmm2, [c169]
    movdqu xmm11, [c170]
    pshuflw xmm2, xmm11, 0xAB
    pshuflw xmm11, [c171], 0x66
    movdqu xmm6, [c172]
    movdqu xmm14, [c173]
    pshuflw xmm6, xmm14, 0x41
    pshuflw xmm14, [c174], 0x14
    movdqu xmm11, [c175]
    movdqu xmm1, [c176]
    pshuflw xmm11, xmm1, 0x40
    pshuflw xmm1, [c177], 0x88
    movdqu xmm4, [c178]
    movdqu xmm11, [c179]
    pshuflw xmm4, xmm11, 0xBE
    pshuflw xmm11, [c180], 0xFD
    movdqu xmm15, [c181]
    movdqu xmm12, [c182]
    pshuflw xmm15, xmm12, 0xC8
    pshuflw xmm12, [c183], 0x3
    movdqu xmm4, [c184]
    movdqu xmm11, [c185]
    lea rdi, [buf + 96]
    maskmovdqu xmm4, xmm11
    mov rax, [buf + 96]
    mov rdx, [buf + 104]
    movdqu xmm14, [c186]
    movdqu xmm5, [c187]
    lea rdi, [buf + 96]
    maskmovdqu xmm14, xmm5
    mov rax, [buf + 96]
    mov rdx, [buf + 104]
    movdqu xmm10, [c188]
    movdqu xmm15, [c189]
    lea rdi, [buf + 96]
    maskmovdqu xmm10, xmm15
    mov rax, [buf + 96]
    mov rdx, [buf + 104]
    lfence
    mfence
    sfence
    prefetcht0 [buf]
    EXIT
    align 16
c0: dq 0x814E205196450BCD, 0xE9547C89EFF19BC5
c1: dq 0x1000BC580010001, 0x7FFF0118FAA50000
c2: dq 0x180008000C6F2, 0x10000FF9807FFE3
c3: dq 0x2C4BE72E9A4D8FD, 0xFFFFFFFFFFFF
c4: dq 0x800000FF351F7FFF, 0x800080004BB90000
c5: dq 0x7E61987C06C273B2, 0xC734A4EF55D96C84
c6: dq 0x8000000000000000, 0x8D4E7394D4517238
c7: dq 0x1, 0x4565E9E30000FFFF
c8: dq 0x2C00800102AB7FFF, 0x73C18883814C0001
c9: dq 0x97F0518405A5081, 0xFF00AC2823018000
c10: dq 0x0, 0xFFFFFFFFFFFFFFFF
c11: dq 0x7FB8A880BE0081, 0xCE4D408140014355
c12: dq 0x7F80FFB1FF80807F, 0x279B430000012A01
c13: dq 0xFF0100A25AF19B, 0x97959F4A7FFF1E84
c14: dq 0x800180019E680001, 0xFFFF8001201600FF
c15: dq 0x7FFF00FFB0E00000, 0xD0B800018000A8E8
c16: dq 0xBB7E859F9A65E925, 0x3ED089238727670D
c17: dq 0x7FFFFFFFFFFFFFFF, 0x100000000
c18: dq 0x992F7FFFA64B8000, 0x7FFFD721706830DE
c19: dq 0x5800000081017F56, 0x4081AEFEC9400100
c20: dq 0x8A47B95F80DFD7, 0x1807F33FF008101
c21: dq 0xC763E69721377359, 0x9F933D5D638BAF83
c22: dq 0x8000000012403144, 0x30E51E90B98407B
c23: dq 0xB88E587F813CFF80, 0x6300577F005DFF7F
c24: dq 0x8001353D0100, 0x80007FFFFFFF0001
c25: dq 0x6DFAE149FBA3C43D, 0x100000000
c26: dq 0x7F81F76F0140EFE6, 0x7F987FDBFF8201C4
c27: dq 0x7FC3E8657FFFFFFF, 0x10000841DD2F1
c28: dq 0x1FFFFFFFF, 0xFB47D072ABF1A1A6
c29: dq 0x1B0AD225CB5CDE70, 0x3D58E15EDCDF1691
c30: dq 0x804040006B7FE740, 0xFF217F718040017F
c31: dq 0x8000000000000000, 0xBBB48E40934C1499
c32: dq 0x784780401781D6, 0x101307F7FC8C4FF
c33: dq 0x1EDC160FA0DD26, 0x8251A407FA8D9BBE
c34: dq 0xE540013F01C900FF, 0x7FED017833C163FF
c35: dq 0x1, 0xFFFFFFFF
c36: dq 0x17FFFFFFF, 0xCB943BB07C757789
c37: dq 0x0, 0x8000000000000000
c38: dq 0xE4C18C186CC5527D, 0xFFFFFFFFFFFFFFFF
c39: dq 0x180D140402601A7, 0x80017F8009017F80
c40: dq 0x7FFFFFFFFFFFFFFF, 0x0
c41: dq 0x8000FFFF80014395, 0x871097C97FFF0000
c42: dq 0x27A92F317FFFFFFF, 0xC37894C57FFFFFFF
c43: dq 0x7FFFFFFF2D25760E, 0x7FFFFFFF
c44: dq 0x440BA15F392EDF1F, 0x8000000000000000
c45: dq 0x37F6029C00000001, 0x8825E98F00018000
c46: dq 0x7F8140A47F80BC7F, 0x833C818E00C7CC81
c47: dq 0x100007FFFFFFF, 0xB660071400010000
c48: dq 0x800080001C30B256, 0x3C74FFFF01000001
c49: dq 0x8001000180007FFF, 0xD99600010000662E
c50: dq 0xDF3182000000001, 0xFFFFFFFF7FFFFFFF
c51: dq 0xF4BD00007FFF, 0x1FFFF00000100
c52: dq 0xA95B00FF00FF0001, 0x7FFF9F9B000074A2
c53: dq 0x1008CB20000AE00, 0x23A08000FFFF0000
c54: dq 0x46AE00FF396B2220, 0x100FFFFFFFF0000
c55: dq 0xFFFF0B9E5576A75E, 0x7FFF00FF80008000
c56: dq 0xFF8E0094807F87BA, 0x7D817F818081803D
c57: dq 0x18747FFF800100FF, 0x1007FFF00000100
c58: dq 0xFFFFFFFFFFFF, 0x7FFFFFFF03230713
c59: dq 0x8C8F498BFEAD4D95, 0x10000FFFFFFFF
c60: dq 0x10000FF0001DA64, 0x800000FF0001FFFF
c61: dq 0x7F28841627D52388, 0x1
c62: dq 0x3D3F0603CAFFE47E, 0xFFFFFFFF
c63: dq 0x724100BFFF7F4001, 0xB1D70840BD55404B
c64: dq 0x7BCDFFFF8000DA51, 0x7FFF800100008ECF
c65: dq 0x4C091EF61D700954, 0xFFFF00000001
c66: dq 0x0, 0xFFFFFFFFFFFFFFFF
c67: dq 0xBACA12C611C9BE02, 0xC1B27A1C7FFFFFFF
c68: dq 0x816DD5AB01000100, 0xFFFF7EEE7252D2E7
c69: dq 0x5F832589D70F31C0, 0xFFFFFFFFFFFFFFFF
c70: dq 0x7FFFFFFFFFFFFFFF, 0x0
c71: dq 0x0, 0xFFFFFFFFFFFFFFFF
c72: dq 0xFFFFFFFFFEE88B35, 0xFFFF00010000
c73: dq 0xFFFFFFFFFFFFFFFF, 0x9B6D735BE73FB416
c74: dq 0x30C2C7989145D0F7, 0x1
c75: dq 0xFFB79C40FF81D33E, 0xBF81008001BE01F2
c76: dq 0xFFFF0DFCD2E7, 0x1000000000001
c77: dq 0x11B0800149918001, 0x1F9BDBF360100
c78: dq 0x81407F80FF6881FF, 0x6F817F807E12E24C
c79: dq 0xC24429AF01007FFF, 0x734701007FFF635F
c80: dq 0xA10D2344FFFFFFFF, 0x3FBE812A210D312C
c81: dq 0x80019D6E8001, 0xA676C85E01004482
c82: dq 0x9F69F8A11E842697, 0xEA5FBE40C73E1FDC
c83: dq 0x100000000, 0x100000000
c84: dq 0x705C17E200000001, 0x1F24F481D
c85: dq 0xE2940471DCC684CA, 0x7FFFFFFF00000001
c86: dq 0x68FDE9E7, 0x33111CB8A94C78BD
c87: dq 0xFFFFFF7D2377, 0x7FFFFFFF00010000
c88: dq 0x100000000, 0x0
c89: dq 0xFFFFFFFF167F25BA, 0x800000007FFFFFFF
c90: dq 0x401F617F7F7F0100, 0x8001FF734040B887
c91: dq 0xFF94D07F000100, 0x8001FFFF103F7FFF
c92: dq 0x3139F37F024DB74, 0x71447B0DC856D6BB
c93: dq 0x100000000, 0x7FFFFFFFFFFFFFFF
c94: dq 0xA5E330190E67C60F, 0x1000091658032
c95: dq 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF
c96: dq 0x80807F889E007F, 0x800081407F018093
c97: dq 0xFF0100EE7A198E, 0x909EA4E200FF7FFF
c98: dq 0x40014040013C757F, 0x80017F409D7FB661
c99: dq 0x8000000000000000, 0x541A339BC0D054
c100: dq 0x213976DBF6FE1580, 0xFFFFFFFFFFFFFFFF
c101: dq 0x37A60171E87F12FF, 0x1001007F7F018001
c102: dq 0x7FFF00004B100001, 0xFCD5FFFF9D5DD359
c103: dq 0xFFF1C81281814000, 0xB9FF570C40001567
c104: dq 0xCFF0180F2E27F58, 0x80B1D18B007FEE6C
c105: dq 0x9921BF16, 0x800000007FFFFFFF
c106: dq 0x7B8DBB7FD468FFD, 0xFFFFFFFF00000000
c107: dq 0xFFFFFFFFF096A7D1, 0x8000000000000000
c108: dq 0x1, 0x70AE75611A85C2C
c109: dq 0x17681A0C, 0x1B143C102
c110: dq 0xFFFFFFFF, 0x7FFFFFFFFFFFFFFF
c111: dq 0x172801580B41F95, 0x81D37E0181407F45
c112: dq 0x71773E310000FFFF, 0xFFFFFFFF
c113: dq 0xFFFF4CD4F9B89D64, 0xFE2C800100018001
c114: dq 0xA35312DC470F1F3C, 0x618BC4346C4E686E
c115: dq 0xFF800100FFEB9B, 0xBDB3000180000100
c116: dq 0x8000000000000000, 0x0
c117: dq 0xE3EEC18F54656477, 0x0
c118: dq 0x916B0DF37FFFFFFF, 0x7FC0FBA700000000
c119: dq 0x800043D7B3B68000, 0x4DB88001380F0C94
c120: dq 0x1B9D4577F814000, 0x4000FF014E3F7F81
c121: dq 0xFDF62F53E4161CCC, 0xAF1083C39EEBBE78
c122: dq 0xFF0A7F8140807F01, 0x801D8058804040
c123: dq 0x10000017B22B2B0, 0x100800080019C1D
c124: dq 0x8001A67A00FF00FF, 0xB9E601007FFF0100
c125: dq 0x100000000, 0xFFFFFFFF
c126: dq 0xFFFF00FF00FF8001, 0x728400FFFFFF
c127: dq 0xFFE94000805AF280, 0x53EC7F7ED2818131
c128: dq 0x26D2916486981407, 0x8000000000000000
c129: dq 0x4F81FFFF00D10040, 0x808003807FB91C80
c130: dq 0x180010001ABEE, 0x57BA80009B347FFF
c131: dq 0x1B7BE631B8001, 0x9D56194580010100
c132: dq 0x5CC7FF3B3D38B57B, 0x3C5A54EBC796AEEE
c133: dq 0x4DD80000FFFF0000, 0x800001000001D32B
c134: dq 0x1, 0x464BEE1067082A9B
c135: dq 0x1, 0xFFFFFFFF
c136: dq 0xEE348000, 0xFF3AF900000000
c137: dq 0x13F55416430DE, 0xFF23917FFF7FFF
c138: dq 0xFFFF010000017FFF, 0xFF2D44800100FF
c139: dq 0xCB0B023B00010000, 0x7F40C5B37FFFFFFF
c140: dq 0x1406D808080DFC3, 0x1DD017F8081FFE0
c141: dq 0xFFFFFFFF2D2BD55D, 0x7DB5BCF40000FFFF
c142: dq 0xA8C9F06100000000, 0xFFFFFFFFEEC20A07
c143: dq 0x8000000000000000, 0xFFFFFFFF
c144: dq 0xD634968D42AF0100, 0x1000000000001
c145: dq 0x7FFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF
c146: dq 0x80000000C5594D0F, 0x9374F7324379D060
c147: dq 0x25988000DFEF0000, 0x1000000FF2C31
c148: dq 0x5440AB40C54032FF, 0x9E7F73004040AB06
c149: dq 0x1ACE31DD7EE200FF, 0xF918800080019F10
c150: dq 0x0, 0x8056A30DD178F43C
c151: dq 0x8000800001007FFF, 0xFFFF00018B12DCF5
c152: dq 0xFFFF37B780010100, 0xFF000000013B83
c153: dq 0x592A361501007FFF, 0x9A2700016F773D29
c154: dq 0x40007F40ECD440FF, 0xD142E500A9800001
c155: dq 0x100000001, 0x80000000CB7A0796
c156: dq 0x1007FFF9C26BFD3, 0xFFFF89AD00018001
c157: dq 0x404710201C600000, 0xFF800080000100
c158: dq 0x2300FF80498100, 0x31FF80258000945B
c159: dq 0xFCE9300940FF7F15, 0x6C03FF7F01EAEDAD
c160: dq 0x2F2871BE80016516, 0x8001000000008001
c161: dq 0xFFFFFFFF, 0x381ED6DB3CEABB2A
c162: dq 0x54FF428609DC03B4, 0xA58367FEFFFFFFFF
c163: dq 0xFB3938674CA33CA3, 0x9286943D81C4D01C
c164: dq 0x8000000000000000, 0xFFFFFFFF
c165: dq 0xFFFFFFFFFFFFFFFF, 0xA273BC76E8B5ABBB
c166: dq 0x132E3808181950B, 0x9BD501400086
c167: dq 0x576CCE48B6485E8D, 0xF4A351C82F799AAA
c168: dq 0x1000080000000, 0x9B452740
c169: dq 0xFFFFFFFF, 0x7FFFFFFFFFFFFFFF
c170: dq 0xE95643A100010000, 0x672B48A700010000
c171: dq 0xD639B51B9BF500FF, 0x7A2FFFF80007FFF
c172: dq 0x8000000057B27FFF, 0x19C07FFF0001AABC
c173: dq 0x80000000EA3CBBB1, 0x100006677C464
c174: dq 0x527F80FFFF7F46A3, 0x1FF7201FF7F0A
c175: dq 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF
c176: dq 0x810077E27F408007, 0x4080428040FF7F80
c177: dq 0xD7AF8000E6A58000, 0x8A1B80010100184F
c178: dq 0x4E5DDB4000497F00, 0x7F0B413826118D27
c179: dq 0x815980F62A8001FA, 0x804001FF80000062
c180: dq 0xCD69000080498000, 0x100FFFF2EFC
c181: dq 0x5E0A11810000C7C1, 0x80010000FFFF8001
c182: dq 0xFF72BA00FF8001, 0xDE2F80008001
c183: dq 0x1A2B281DC6504E7, 0x6E7F7F40A301817F
c184: dq 0xA0F9AC3D294173EE, 0x1
c185: dq 0x8018FF0F017FD200, 0x2D81FF33407FFFCE
c186: dq 0x5479A20181884060, 0xFF7F010100406BFB
c187: dq 0x7F0AF8810101FF74, 0xFD808083449BBDAF
c188: dq 0xFFFFFFFF, 0xC7D34DF6D1D7591E
c189: dq 0xD8817F0E0162ECFF, 0xE391750081A37F68
buf: times 64 dq 0x0123456789ABCDEF
file_end:
