; FXSAVE and FXRSTOR: what is written, field by field, and that it comes back.
; Written by tools/gen64_tests.py: change that, not this.
%include "elf.inc"
    fninit
    movdqu xmm0, [c0]
    movdqu xmm1, [c1]
    movdqu xmm2, [c2]
    movdqu xmm3, [c3]
    movdqu xmm4, [c4]
    movdqu xmm5, [c5]
    movdqu xmm6, [c6]
    movdqu xmm7, [c7]
    movdqu xmm8, [c8]
    movdqu xmm9, [c9]
    movdqu xmm10, [c10]
    movdqu xmm11, [c11]
    movdqu xmm12, [c12]
    movdqu xmm13, [c13]
    movdqu xmm14, [c14]
    movdqu xmm15, [c15]
    fld tword [t0]
    fld tword [t1]
    fld tword [t2]
    fld tword [t3]
    fld tword [t4]
    mov dword [buf], 0x5F80
    ldmxcsr [buf]
    mov word [buf + 80], 0x0A7F
    fldcw [buf + 80]
    fnclex
    fxsave [area]
    movzx eax, word [area]
    movzx edx, word [area + 2]
    movzx esi, word [area + 4]
    mov eax, [area + 24]
    mov edx, [area + 28]
    mov rax, [area + 32]
    mov rdx, [area + 40]
    mov rax, [area + 48]
    mov rdx, [area + 56]
    mov rax, [area + 64]
    mov rdx, [area + 72]
    mov rax, [area + 80]
    mov rdx, [area + 88]
    mov rax, [area + 96]
    mov rdx, [area + 104]
    mov rax, [area + 112]
    mov rdx, [area + 120]
    mov rax, [area + 128]
    mov rdx, [area + 136]
    mov rax, [area + 144]
    mov rdx, [area + 152]
    mov rax, [area + 160]
    mov rdx, [area + 168]
    mov rax, [area + 176]
    mov rdx, [area + 184]
    mov rax, [area + 192]
    mov rdx, [area + 200]
    mov rax, [area + 208]
    mov rdx, [area + 216]
    mov rax, [area + 224]
    mov rdx, [area + 232]
    mov rax, [area + 240]
    mov rdx, [area + 248]
    mov rax, [area + 256]
    mov rdx, [area + 264]
    mov rax, [area + 272]
    mov rdx, [area + 280]
    mov rax, [area + 288]
    mov rdx, [area + 296]
    mov rax, [area + 304]
    mov rdx, [area + 312]
    mov rax, [area + 320]
    mov rdx, [area + 328]
    mov rax, [area + 336]
    mov rdx, [area + 344]
    mov rax, [area + 352]
    mov rdx, [area + 360]
    mov rax, [area + 368]
    mov rdx, [area + 376]
    mov rax, [area + 384]
    mov rdx, [area + 392]
    mov rax, [area + 400]
    mov rdx, [area + 408]
    mov rax, [area + 416]
    mov rdx, [area + 504]
    fninit
    pxor xmm0, xmm0
    pxor xmm1, xmm1
    pxor xmm2, xmm2
    pxor xmm3, xmm3
    pxor xmm4, xmm4
    pxor xmm5, xmm5
    pxor xmm6, xmm6
    pxor xmm7, xmm7
    pxor xmm8, xmm8
    pxor xmm9, xmm9
    pxor xmm10, xmm10
    pxor xmm11, xmm11
    pxor xmm12, xmm12
    pxor xmm13, xmm13
    pxor xmm14, xmm14
    pxor xmm15, xmm15
    mov dword [buf], 0x1F80
    ldmxcsr [buf]
    fxrstor [area]
    stmxcsr [buf]
    mov eax, [buf]
    fnstcw [buf]
    movzx eax, word [buf]
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fnstsw ax
    fxsave [area]
    mov rax, 0xC000000000000000
    mov [area + 32], rax
    mov word [area + 40], 0x4000
    or word [area + 4], 0x80
    and word [area + 2], 0xC7FF
    or word [area + 2], 0x3800
    mov qword [area + 160 + 9 * 16], 0x55
    fxrstor [area]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    movq rax, xmm9
    EXIT
    align 16
c0: dq 0x8080E940FF140140, 0x22C081407A404040
c1: dq 0xFFFF3DE7E51F, 0x7FFFFFFFD09B7637
c2: dq 0x4E653FD2B46CE135, 0xFFFF13A6C6A0
c3: dq 0x80017FFF00000001, 0x2B9DFFFF80010000
c4: dq 0x7FFFFFFFE1A88001, 0x1007FFF
c5: dq 0x8000000000000000, 0x78F4E910A1F279F9
c6: dq 0xE38EFFFF0100766D, 0x18A300018000
c7: dq 0xE73180007FFF, 0x61928000B6327FFF
c8: dq 0x7FFF00013F738000, 0x800000FF5C06693B
c9: dq 0x18B80ADE3805073, 0x815B917C7F9CE4FF
c10: dq 0x4081FF6D6B804E81, 0x40B84081CE00013F
c11: dq 0x159164F8B, 0xE852676D00000001
c12: dq 0xFFFFFFFF, 0x1
c13: dq 0x100000000FFFF, 0xFFFF52D2DB74
c14: dq 0xFFFFFFFF7FFFFFFF, 0x3C9767F400000001
c15: dq 0xFFFFFFFFFFFFFFFF, 0x100000000
t0: dq 0xC97D288AE41FDDA4
    dw 0xBFD9, 0, 0, 0
t1: dq 0x800681E5C21277DA
    dw 0xC01E, 0, 0, 0
t2: dq 0xE0CE3F6BF0BF656C
    dw 0xC01D, 0, 0, 0
t3: dq 0xBDB13EDFE324186D
    dw 0x3FE4, 0, 0, 0
t4: dq 0xA3808A96E6FE6DED
    dw 0xBFF5, 0, 0, 0
buf: times 64 dq 0x0123456789ABCDEF
area: times 80 dq 0x1111111111111111
file_end:
