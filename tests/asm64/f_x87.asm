; The x87: loads and stores at every width, the four operations at each precision and rounding, comparisons, conversions to integers, and the small instructions.
; Written by tools/gen64_tests.py: change that, not this.
%include "elf.inc"
    fninit
    fld dword [c0]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld qword [c1]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild word [c2]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild dword [c2]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild qword [c2]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld dword [c3]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld qword [c4]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild word [c5]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild dword [c5]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild qword [c5]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld dword [c6]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld qword [c7]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild word [c8]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild dword [c8]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild qword [c8]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld dword [c9]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld qword [c10]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild word [c11]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild dword [c11]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild qword [c11]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld dword [c12]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld qword [c13]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild word [c14]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild dword [c14]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild qword [c14]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld dword [c15]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld qword [c16]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild word [c17]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild dword [c17]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild qword [c17]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld dword [c18]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld qword [c19]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild word [c20]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild dword [c20]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild qword [c20]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld dword [c21]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld qword [c22]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild word [c23]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild dword [c23]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fild qword [c23]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fld1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xB7F
    fldcw [buf + 80]
    fld1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x27F
    fldcw [buf + 80]
    fld1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fldz
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xB7F
    fldcw [buf + 80]
    fldz
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x27F
    fldcw [buf + 80]
    fldz
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fldpi
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xB7F
    fldcw [buf + 80]
    fldpi
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x27F
    fldcw [buf + 80]
    fldpi
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fldl2e
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xB7F
    fldcw [buf + 80]
    fldl2e
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x27F
    fldcw [buf + 80]
    fldl2e
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fldl2t
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xB7F
    fldcw [buf + 80]
    fldl2t
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x27F
    fldcw [buf + 80]
    fldl2t
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fldlg2
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xB7F
    fldcw [buf + 80]
    fldlg2
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x27F
    fldcw [buf + 80]
    fldlg2
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fldln2
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xB7F
    fldcw [buf + 80]
    fldln2
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x27F
    fldcw [buf + 80]
    fldln2
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fld tword [t0]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t1]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t2]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t3]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t4]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t5]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t6]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t7]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t8]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t9]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t10]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t11]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t12]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t13]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t14]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t15]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    mov word [buf + 80], 0x77F
    fldcw [buf + 80]
    fld tword [t16]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t17]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t18]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t19]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t20]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t21]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t22]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t23]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t24]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t25]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t26]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t27]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t28]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t29]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t30]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t31]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    mov word [buf + 80], 0xB7F
    fldcw [buf + 80]
    fld tword [t32]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t33]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t34]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t35]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t36]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t37]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t38]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t39]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t40]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t41]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t42]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t43]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t44]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t45]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t46]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t47]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    mov word [buf + 80], 0xF7F
    fldcw [buf + 80]
    fld tword [t48]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t49]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t50]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t51]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t52]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t53]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t54]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t55]
    fst dword [buf]
    mov eax, [buf]
    fst qword [buf + 8]
    mov rdx, [buf + 8]
    fstp st0
    fld tword [t56]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t57]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t58]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t59]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t60]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t61]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t62]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    fld tword [t63]
    fist word [buf]
    movzx eax, word [buf]
    fist dword [buf + 8]
    mov edx, [buf + 8]
    fld st0
    fistp qword [buf + 16]
    mov rsi, [buf + 16]
    fstp st0
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fld tword [t64]
    fld tword [t65]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t66]
    fld tword [t67]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t68]
    fld tword [t69]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t70]
    fld tword [t71]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t72]
    fld tword [t73]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t74]
    fld tword [t75]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t76]
    fld tword [t77]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t78]
    fld tword [t79]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t80]
    fld tword [t81]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t82]
    fld tword [t83]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t84]
    fld tword [t85]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t86]
    fld tword [t87]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t88]
    fld tword [t89]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t90]
    fld tword [t91]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t92]
    fld tword [t93]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t94]
    fld tword [t95]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t96]
    fld tword [t97]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t98]
    fld tword [t99]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t100]
    fld tword [t101]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t102]
    fld tword [t103]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t104]
    fld tword [t105]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t106]
    fld tword [t107]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t108]
    fld tword [t109]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t110]
    fld tword [t111]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t112]
    fld tword [t113]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t114]
    fld tword [t115]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t116]
    fld tword [t117]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t118]
    fld tword [t119]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t120]
    fld tword [t121]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t122]
    fld tword [t123]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x77F
    fldcw [buf + 80]
    fld tword [t124]
    fld tword [t125]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t126]
    fld tword [t127]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t128]
    fld tword [t129]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t130]
    fld tword [t131]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t132]
    fld tword [t133]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t134]
    fld tword [t135]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t136]
    fld tword [t137]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t138]
    fld tword [t139]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t140]
    fld tword [t141]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t142]
    fld tword [t143]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t144]
    fld tword [t145]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t146]
    fld tword [t147]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t148]
    fld tword [t149]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t150]
    fld tword [t151]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t152]
    fld tword [t153]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t154]
    fld tword [t155]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t156]
    fld tword [t157]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t158]
    fld tword [t159]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t160]
    fld tword [t161]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t162]
    fld tword [t163]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t164]
    fld tword [t165]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t166]
    fld tword [t167]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t168]
    fld tword [t169]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t170]
    fld tword [t171]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t172]
    fld tword [t173]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t174]
    fld tword [t175]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t176]
    fld tword [t177]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t178]
    fld tword [t179]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t180]
    fld tword [t181]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t182]
    fld tword [t183]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xB7F
    fldcw [buf + 80]
    fld tword [t184]
    fld tword [t185]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t186]
    fld tword [t187]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t188]
    fld tword [t189]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t190]
    fld tword [t191]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t192]
    fld tword [t193]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t194]
    fld tword [t195]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t196]
    fld tword [t197]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t198]
    fld tword [t199]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t200]
    fld tword [t201]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t202]
    fld tword [t203]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t204]
    fld tword [t205]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t206]
    fld tword [t207]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t208]
    fld tword [t209]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t210]
    fld tword [t211]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t212]
    fld tword [t213]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t214]
    fld tword [t215]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t216]
    fld tword [t217]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t218]
    fld tword [t219]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t220]
    fld tword [t221]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t222]
    fld tword [t223]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t224]
    fld tword [t225]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t226]
    fld tword [t227]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t228]
    fld tword [t229]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t230]
    fld tword [t231]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t232]
    fld tword [t233]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t234]
    fld tword [t235]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t236]
    fld tword [t237]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t238]
    fld tword [t239]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t240]
    fld tword [t241]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t242]
    fld tword [t243]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xF7F
    fldcw [buf + 80]
    fld tword [t244]
    fld tword [t245]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t246]
    fld tword [t247]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t248]
    fld tword [t249]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t250]
    fld tword [t251]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t252]
    fld tword [t253]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t254]
    fld tword [t255]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t256]
    fld tword [t257]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t258]
    fld tword [t259]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t260]
    fld tword [t261]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t262]
    fld tword [t263]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t264]
    fld tword [t265]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t266]
    fld tword [t267]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t268]
    fld tword [t269]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t270]
    fld tword [t271]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t272]
    fld tword [t273]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t274]
    fld tword [t275]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t276]
    fld tword [t277]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t278]
    fld tword [t279]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t280]
    fld tword [t281]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t282]
    fld tword [t283]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t284]
    fld tword [t285]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t286]
    fld tword [t287]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t288]
    fld tword [t289]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t290]
    fld tword [t291]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t292]
    fld tword [t293]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t294]
    fld tword [t295]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t296]
    fld tword [t297]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t298]
    fld tword [t299]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t300]
    fld tword [t301]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t302]
    fld tword [t303]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x27F
    fldcw [buf + 80]
    fld tword [t304]
    fld tword [t305]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t306]
    fld tword [t307]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t308]
    fld tword [t309]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t310]
    fld tword [t311]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t312]
    fld tword [t313]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t314]
    fld tword [t315]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t316]
    fld tword [t317]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t318]
    fld tword [t319]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t320]
    fld tword [t321]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t322]
    fld tword [t323]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t324]
    fld tword [t325]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t326]
    fld tword [t327]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t328]
    fld tword [t329]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t330]
    fld tword [t331]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t332]
    fld tword [t333]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t334]
    fld tword [t335]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t336]
    fld tword [t337]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t338]
    fld tword [t339]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t340]
    fld tword [t341]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t342]
    fld tword [t343]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t344]
    fld tword [t345]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t346]
    fld tword [t347]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t348]
    fld tword [t349]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t350]
    fld tword [t351]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t352]
    fld tword [t353]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t354]
    fld tword [t355]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t356]
    fld tword [t357]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t358]
    fld tword [t359]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t360]
    fld tword [t361]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t362]
    fld tword [t363]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x67F
    fldcw [buf + 80]
    fld tword [t364]
    fld tword [t365]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t366]
    fld tword [t367]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t368]
    fld tword [t369]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t370]
    fld tword [t371]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t372]
    fld tword [t373]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t374]
    fld tword [t375]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t376]
    fld tword [t377]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t378]
    fld tword [t379]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t380]
    fld tword [t381]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t382]
    fld tword [t383]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t384]
    fld tword [t385]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t386]
    fld tword [t387]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t388]
    fld tword [t389]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t390]
    fld tword [t391]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t392]
    fld tword [t393]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t394]
    fld tword [t395]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t396]
    fld tword [t397]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t398]
    fld tword [t399]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t400]
    fld tword [t401]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t402]
    fld tword [t403]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t404]
    fld tword [t405]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t406]
    fld tword [t407]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t408]
    fld tword [t409]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t410]
    fld tword [t411]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t412]
    fld tword [t413]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t414]
    fld tword [t415]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t416]
    fld tword [t417]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t418]
    fld tword [t419]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t420]
    fld tword [t421]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t422]
    fld tword [t423]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x7F
    fldcw [buf + 80]
    fld tword [t424]
    fld tword [t425]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t426]
    fld tword [t427]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t428]
    fld tword [t429]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t430]
    fld tword [t431]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t432]
    fld tword [t433]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t434]
    fld tword [t435]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t436]
    fld tword [t437]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t438]
    fld tword [t439]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t440]
    fld tword [t441]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t442]
    fld tword [t443]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t444]
    fld tword [t445]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t446]
    fld tword [t447]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t448]
    fld tword [t449]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t450]
    fld tword [t451]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t452]
    fld tword [t453]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t454]
    fld tword [t455]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t456]
    fld tword [t457]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t458]
    fld tword [t459]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t460]
    fld tword [t461]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t462]
    fld tword [t463]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t464]
    fld tword [t465]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t466]
    fld tword [t467]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t468]
    fld tword [t469]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t470]
    fld tword [t471]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t472]
    fld tword [t473]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t474]
    fld tword [t475]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t476]
    fld tword [t477]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t478]
    fld tword [t479]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t480]
    fld tword [t481]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t482]
    fld tword [t483]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xC7F
    fldcw [buf + 80]
    fld tword [t484]
    fld tword [t485]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t486]
    fld tword [t487]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t488]
    fld tword [t489]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t490]
    fld tword [t491]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t492]
    fld tword [t493]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t494]
    fld tword [t495]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t496]
    fld tword [t497]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t498]
    fld tword [t499]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t500]
    fld tword [t501]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t502]
    fld tword [t503]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t504]
    fld tword [t505]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t506]
    fld tword [t507]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t508]
    fld tword [t509]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t510]
    fld tword [t511]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t512]
    fld tword [t513]
    fsubrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t514]
    fld tword [t515]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t516]
    fld tword [t517]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t518]
    fld tword [t519]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t520]
    fld tword [t521]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t522]
    fld tword [t523]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t524]
    fld tword [t525]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t526]
    fld tword [t527]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t528]
    fld tword [t529]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t530]
    fld tword [t531]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t532]
    fld tword [t533]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t534]
    fld tword [t535]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t536]
    fld tword [t537]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t538]
    fld tword [t539]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t540]
    fld tword [t541]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t542]
    fld tword [t543]
    fdivrp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fld tword [t544]
    fadd qword [c24]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t545]
    fadd dword [c25]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t546]
    fiadd dword [c26]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t547]
    fiadd word [c26]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t548]
    fld tword [t549]
    fadd st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t550]
    fld tword [t551]
    fadd st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t552]
    fadd qword [c27]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t553]
    fadd dword [c28]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t554]
    fiadd dword [c29]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t555]
    fiadd word [c29]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t556]
    fld tword [t557]
    fadd st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t558]
    fld tword [t559]
    fadd st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t560]
    fadd qword [c30]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t561]
    fadd dword [c31]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t562]
    fiadd dword [c32]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t563]
    fiadd word [c32]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t564]
    fld tword [t565]
    fadd st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t566]
    fld tword [t567]
    fadd st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t568]
    fadd qword [c33]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t569]
    fadd dword [c34]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t570]
    fiadd dword [c35]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t571]
    fiadd word [c35]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t572]
    fld tword [t573]
    fadd st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t574]
    fld tword [t575]
    fadd st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t576]
    fsub qword [c36]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t577]
    fsub dword [c37]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t578]
    fisub dword [c38]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t579]
    fisub word [c38]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t580]
    fld tword [t581]
    fsub st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t582]
    fld tword [t583]
    fsub st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t584]
    fsub qword [c39]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t585]
    fsub dword [c40]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t586]
    fisub dword [c41]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t587]
    fisub word [c41]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t588]
    fld tword [t589]
    fsub st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t590]
    fld tword [t591]
    fsub st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t592]
    fsub qword [c42]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t593]
    fsub dword [c43]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t594]
    fisub dword [c44]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t595]
    fisub word [c44]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t596]
    fld tword [t597]
    fsub st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t598]
    fld tword [t599]
    fsub st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t600]
    fsub qword [c45]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t601]
    fsub dword [c46]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t602]
    fisub dword [c47]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t603]
    fisub word [c47]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t604]
    fld tword [t605]
    fsub st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t606]
    fld tword [t607]
    fsub st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t608]
    fsubr qword [c48]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t609]
    fsubr dword [c49]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t610]
    fisubr dword [c50]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t611]
    fisubr word [c50]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t612]
    fld tword [t613]
    fsubr st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t614]
    fld tword [t615]
    fsubr st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t616]
    fsubr qword [c51]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t617]
    fsubr dword [c52]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t618]
    fisubr dword [c53]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t619]
    fisubr word [c53]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t620]
    fld tword [t621]
    fsubr st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t622]
    fld tword [t623]
    fsubr st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t624]
    fsubr qword [c54]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t625]
    fsubr dword [c55]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t626]
    fisubr dword [c56]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t627]
    fisubr word [c56]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t628]
    fld tword [t629]
    fsubr st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t630]
    fld tword [t631]
    fsubr st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t632]
    fsubr qword [c57]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t633]
    fsubr dword [c58]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t634]
    fisubr dword [c59]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t635]
    fisubr word [c59]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t636]
    fld tword [t637]
    fsubr st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t638]
    fld tword [t639]
    fsubr st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t640]
    fmul qword [c60]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t641]
    fmul dword [c61]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t642]
    fimul dword [c62]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t643]
    fimul word [c62]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t644]
    fld tword [t645]
    fmul st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t646]
    fld tword [t647]
    fmul st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t648]
    fmul qword [c63]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t649]
    fmul dword [c64]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t650]
    fimul dword [c65]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t651]
    fimul word [c65]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t652]
    fld tword [t653]
    fmul st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t654]
    fld tword [t655]
    fmul st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t656]
    fmul qword [c66]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t657]
    fmul dword [c67]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t658]
    fimul dword [c68]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t659]
    fimul word [c68]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t660]
    fld tword [t661]
    fmul st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t662]
    fld tword [t663]
    fmul st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t664]
    fmul qword [c69]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t665]
    fmul dword [c70]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t666]
    fimul dword [c71]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t667]
    fimul word [c71]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t668]
    fld tword [t669]
    fmul st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t670]
    fld tword [t671]
    fmul st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t672]
    fdiv qword [c72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t673]
    fdiv dword [c73]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t674]
    fidiv dword [c74]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t675]
    fidiv word [c74]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t676]
    fld tword [t677]
    fdiv st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t678]
    fld tword [t679]
    fdiv st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t680]
    fdiv qword [c75]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t681]
    fdiv dword [c76]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t682]
    fidiv dword [c77]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t683]
    fidiv word [c77]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t684]
    fld tword [t685]
    fdiv st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t686]
    fld tword [t687]
    fdiv st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t688]
    fdiv qword [c78]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t689]
    fdiv dword [c79]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t690]
    fidiv dword [c80]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t691]
    fidiv word [c80]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t692]
    fld tword [t693]
    fdiv st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t694]
    fld tword [t695]
    fdiv st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t696]
    fdiv qword [c81]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t697]
    fdiv dword [c82]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t698]
    fidiv dword [c83]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t699]
    fidiv word [c83]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t700]
    fld tword [t701]
    fdiv st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t702]
    fld tword [t703]
    fdiv st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t704]
    fdivr qword [c84]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t705]
    fdivr dword [c85]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t706]
    fidivr dword [c86]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t707]
    fidivr word [c86]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t708]
    fld tword [t709]
    fdivr st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t710]
    fld tword [t711]
    fdivr st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t712]
    fdivr qword [c87]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t713]
    fdivr dword [c88]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t714]
    fidivr dword [c89]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t715]
    fidivr word [c89]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t716]
    fld tword [t717]
    fdivr st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t718]
    fld tword [t719]
    fdivr st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t720]
    fdivr qword [c90]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t721]
    fdivr dword [c91]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t722]
    fidivr dword [c92]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t723]
    fidivr word [c92]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t724]
    fld tword [t725]
    fdivr st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t726]
    fld tword [t727]
    fdivr st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t728]
    fdivr qword [c93]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t729]
    fdivr dword [c94]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t730]
    fidivr dword [c95]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t731]
    fidivr word [c95]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t732]
    fld tword [t733]
    fdivr st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t734]
    fld tword [t735]
    fdivr st1, st0
    fxch
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t736]
    fld tword [t737]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t738]
    fld tword [t739]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t740]
    fld tword [t741]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t742]
    fld tword [t743]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t744]
    fld tword [t745]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t746]
    fld tword [t747]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t748]
    fld tword [t749]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t750]
    fld tword [t751]
    faddp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t752]
    fld tword [t753]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t754]
    fld tword [t755]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t756]
    fld tword [t757]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t758]
    fld tword [t759]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t760]
    fld tword [t761]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t762]
    fld tword [t763]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t764]
    fld tword [t765]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t766]
    fld tword [t767]
    fsubp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t768]
    fld tword [t769]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t770]
    fld tword [t771]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t772]
    fld tword [t773]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t774]
    fld tword [t775]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t776]
    fld tword [t777]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t778]
    fld tword [t779]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t780]
    fld tword [t781]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t782]
    fld tword [t783]
    fmulp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t784]
    fld tword [t785]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t786]
    fld tword [t787]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t788]
    fld tword [t789]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t790]
    fld tword [t791]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t792]
    fld tword [t793]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t794]
    fld tword [t795]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t796]
    fld tword [t797]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t798]
    fld tword [t799]
    fdivp st1, st0
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t800]
    fld tword [t801]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0xA03
    fucomi st0, st1
    FLAGS 0x246
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t802]
    fld tword [t803]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0xA03
    fucomi st0, st1
    FLAGS 0xA02
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t804]
    fld tword [t805]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0x202
    fucomi st0, st1
    FLAGS 0x203
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t806]
    fld tword [t807]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0x212
    fucomi st0, st1
    FLAGS 0x2D6
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t808]
    fld tword [t809]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0x213
    fucomi st0, st1
    FLAGS 0xA43
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t810]
    fld tword [t811]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0x203
    fucomi st0, st1
    FLAGS 0xA82
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t812]
    fld tword [t813]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0xA02
    fucomi st0, st1
    FLAGS 0xA43
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t814]
    fld tword [t815]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0xA82
    fucomi st0, st1
    FLAGS 0x202
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t816]
    fld tword [t817]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0xA43
    fucomi st0, st1
    FLAGS 0xA03
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t818]
    fld tword [t819]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0x212
    fucomi st0, st1
    FLAGS 0x246
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t820]
    fld tword [t821]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0xA02
    fucomi st0, st1
    FLAGS 0xA82
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t822]
    fld tword [t823]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0x246
    fucomi st0, st1
    FLAGS 0xA02
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t824]
    fld tword [t825]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0x202
    fucomi st0, st1
    FLAGS 0x2D6
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t826]
    fld tword [t827]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0xA43
    fucomi st0, st1
    FLAGS 0x2D6
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t828]
    fld tword [t829]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0x2D6
    fucomi st0, st1
    FLAGS 0xA82
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t830]
    fld tword [t831]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0x246
    fucomi st0, st1
    FLAGS 0x212
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t832]
    fld tword [t833]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0x246
    fucomi st0, st1
    FLAGS 0xA03
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t834]
    fld tword [t835]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0x213
    fucomi st0, st1
    FLAGS 0xA02
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t836]
    fld tword [t837]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0xAD7
    fucomi st0, st1
    FLAGS 0x297
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t838]
    fld tword [t839]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0x203
    fucomi st0, st1
    FLAGS 0x212
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t840]
    fld tword [t841]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0xA43
    fucomi st0, st1
    FLAGS 0xA82
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t842]
    fld tword [t843]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0x203
    fucomi st0, st1
    FLAGS 0xAD7
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t844]
    fld tword [t845]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0x212
    fucomi st0, st1
    FLAGS 0x212
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t846]
    fld tword [t847]
    fnclex
    fucom st1
    fnstsw ax
    FLAGS 0xA43
    fucomi st0, st1
    FLAGS 0xAD7
    fcomi st0, st1
    ftst
    fnstsw ax
    fxam
    fnstsw ax
    fcompp
    fnstsw ax
    fld tword [t848]
    fld tword [t849]
    FLAGS 0x202
    fcmovb st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t850]
    fld tword [t851]
    FLAGS 0x203
    fcmovb st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t852]
    fld tword [t853]
    FLAGS 0x242
    fcmovb st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t854]
    fld tword [t855]
    FLAGS 0x206
    fcmovb st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t856]
    fld tword [t857]
    FLAGS 0x247
    fcmovb st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t858]
    fld tword [t859]
    FLAGS 0x202
    fcmove st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t860]
    fld tword [t861]
    FLAGS 0x203
    fcmove st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t862]
    fld tword [t863]
    FLAGS 0x242
    fcmove st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t864]
    fld tword [t865]
    FLAGS 0x206
    fcmove st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t866]
    fld tword [t867]
    FLAGS 0x247
    fcmove st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t868]
    fld tword [t869]
    FLAGS 0x202
    fcmovbe st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t870]
    fld tword [t871]
    FLAGS 0x203
    fcmovbe st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t872]
    fld tword [t873]
    FLAGS 0x242
    fcmovbe st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t874]
    fld tword [t875]
    FLAGS 0x206
    fcmovbe st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t876]
    fld tword [t877]
    FLAGS 0x247
    fcmovbe st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t878]
    fld tword [t879]
    FLAGS 0x202
    fcmovu st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t880]
    fld tword [t881]
    FLAGS 0x203
    fcmovu st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t882]
    fld tword [t883]
    FLAGS 0x242
    fcmovu st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t884]
    fld tword [t885]
    FLAGS 0x206
    fcmovu st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t886]
    fld tword [t887]
    FLAGS 0x247
    fcmovu st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t888]
    fld tword [t889]
    FLAGS 0x202
    fcmovnb st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t890]
    fld tword [t891]
    FLAGS 0x203
    fcmovnb st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t892]
    fld tword [t893]
    FLAGS 0x242
    fcmovnb st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t894]
    fld tword [t895]
    FLAGS 0x206
    fcmovnb st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t896]
    fld tword [t897]
    FLAGS 0x247
    fcmovnb st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t898]
    fld tword [t899]
    FLAGS 0x202
    fcmovne st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t900]
    fld tword [t901]
    FLAGS 0x203
    fcmovne st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t902]
    fld tword [t903]
    FLAGS 0x242
    fcmovne st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t904]
    fld tword [t905]
    FLAGS 0x206
    fcmovne st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t906]
    fld tword [t907]
    FLAGS 0x247
    fcmovne st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t908]
    fld tword [t909]
    FLAGS 0x202
    fcmovnbe st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t910]
    fld tword [t911]
    FLAGS 0x203
    fcmovnbe st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t912]
    fld tword [t913]
    FLAGS 0x242
    fcmovnbe st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t914]
    fld tword [t915]
    FLAGS 0x206
    fcmovnbe st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t916]
    fld tword [t917]
    FLAGS 0x247
    fcmovnbe st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t918]
    fld tword [t919]
    FLAGS 0x202
    fcmovnu st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t920]
    fld tword [t921]
    FLAGS 0x203
    fcmovnu st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t922]
    fld tword [t923]
    FLAGS 0x242
    fcmovnu st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t924]
    fld tword [t925]
    FLAGS 0x206
    fcmovnu st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t926]
    fld tword [t927]
    FLAGS 0x247
    fcmovnu st0, st1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fld tword [t928]
    fchs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t929]
    fchs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t930]
    fchs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t931]
    fchs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xF7F
    fldcw [buf + 80]
    fld tword [t932]
    fchs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t933]
    fchs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t934]
    fchs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t935]
    fchs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x27F
    fldcw [buf + 80]
    fld tword [t936]
    fchs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t937]
    fchs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t938]
    fchs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t939]
    fchs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fld tword [t940]
    fabs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t941]
    fabs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t942]
    fabs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t943]
    fabs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xF7F
    fldcw [buf + 80]
    fld tword [t944]
    fabs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t945]
    fabs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t946]
    fabs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t947]
    fabs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x27F
    fldcw [buf + 80]
    fld tword [t948]
    fabs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t949]
    fabs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t950]
    fabs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t951]
    fabs
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fld tword [t952]
    frndint
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t953]
    frndint
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t954]
    frndint
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t955]
    frndint
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xF7F
    fldcw [buf + 80]
    fld tword [t956]
    frndint
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t957]
    frndint
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t958]
    frndint
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t959]
    frndint
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x27F
    fldcw [buf + 80]
    fld tword [t960]
    frndint
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t961]
    frndint
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t962]
    frndint
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t963]
    frndint
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fld tword [t964]
    fsqrt
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t965]
    fsqrt
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t966]
    fsqrt
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t967]
    fsqrt
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xF7F
    fldcw [buf + 80]
    fld tword [t968]
    fsqrt
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t969]
    fsqrt
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t970]
    fsqrt
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t971]
    fsqrt
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x27F
    fldcw [buf + 80]
    fld tword [t972]
    fsqrt
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t973]
    fsqrt
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t974]
    fsqrt
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t975]
    fsqrt
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fld tword [t976]
    fxtract
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t977]
    fxtract
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t978]
    fxtract
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t979]
    fxtract
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0xF7F
    fldcw [buf + 80]
    fld tword [t980]
    fxtract
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t981]
    fxtract
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t982]
    fxtract
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t983]
    fxtract
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x27F
    fldcw [buf + 80]
    fld tword [t984]
    fxtract
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t985]
    fxtract
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t986]
    fxtract
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fld tword [t987]
    fxtract
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fld tword [t988]
    fld tword [t989]
    fscale
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t990]
    fld tword [t991]
    fprem
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t992]
    fld tword [t993]
    fprem1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t994]
    fld tword [t995]
    fscale
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t996]
    fld tword [t997]
    fprem
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t998]
    fld tword [t999]
    fprem1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1000]
    fld tword [t1001]
    fscale
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1002]
    fld tword [t1003]
    fprem
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1004]
    fld tword [t1005]
    fprem1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1006]
    fld tword [t1007]
    fscale
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1008]
    fld tword [t1009]
    fprem
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1010]
    fld tword [t1011]
    fprem1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1012]
    fld tword [t1013]
    fscale
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1014]
    fld tword [t1015]
    fprem
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1016]
    fld tword [t1017]
    fprem1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1018]
    fld tword [t1019]
    fscale
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1020]
    fld tword [t1021]
    fprem
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1022]
    fld tword [t1023]
    fprem1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1024]
    fld tword [t1025]
    fscale
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1026]
    fld tword [t1027]
    fprem
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1028]
    fld tword [t1029]
    fprem1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1030]
    fld tword [t1031]
    fscale
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1032]
    fld tword [t1033]
    fprem
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1034]
    fld tword [t1035]
    fprem1
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1036]
    fld tword [t1037]
    fld tword [t1038]
    fld tword [t1039]
    fld tword [t1040]
    fld tword [t1041]
    fxch st3
    fld st2
    fst st5
    fincstp
    fdecstp
    ffree st6
    fnclex
    fnstsw ax
    fnstsw [buf]
    movzx edx, word [buf]
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
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fnstcw [buf]
    movzx eax, word [buf]
    fld tword [t1042]
    fld tword [t1043]
    fld tword [t1044]
    fnclex
    fnstenv [area]
    mov eax, [area]
    mov edx, [area + 4]
    mov esi, [area + 8]
    fnstcw [buf]
    movzx eax, word [buf]
    fldenv [area]
    fnsave [area]
    mov eax, [area]
    mov edx, [area + 4]
    mov esi, [area + 8]
    mov rax, [area + 28]
    mov rdx, [area + 36]
    mov rsi, [area + 44]
    fnstsw ax
    frstor [area]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fninit
    fnstsw ax
    fnstcw [buf]
    movzx eax, word [buf]
    wait
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fld tword [t1045]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1046]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1047]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1048]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1049]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1050]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1051]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1052]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1053]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1054]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1055]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1056]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1057]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1058]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1059]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1060]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1061]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    mov word [buf + 80], 0x77F
    fldcw [buf + 80]
    fld tword [t1062]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1063]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1064]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1065]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1066]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1067]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1068]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1069]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1070]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1071]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1072]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1073]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1074]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1075]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1076]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1077]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1078]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    mov word [buf + 80], 0xB7F
    fldcw [buf + 80]
    fld tword [t1079]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1080]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1081]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1082]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1083]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1084]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1085]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1086]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1087]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1088]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1089]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1090]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1091]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1092]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1093]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1094]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1095]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    mov word [buf + 80], 0xF7F
    fldcw [buf + 80]
    fld tword [t1096]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1097]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1098]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1099]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1100]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1101]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1102]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1103]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1104]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1105]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1106]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1107]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1108]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1109]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1110]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1111]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    fld tword [t1112]
    fst dword [buf]
    mov eax, [buf]
    fstp qword [buf + 8]
    mov rdx, [buf + 8]
    mov word [buf + 80], 0x37F
    fldcw [buf + 80]
    fld tword [t1113]
    fld tword [t1114]
    fprem
    fnclex
    fnstsw ax
    fprem
    fnclex
    fnstsw ax
    fprem
    fnclex
    fnstsw ax
    fprem
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1115]
    fld tword [t1116]
    fprem1
    fnclex
    fnstsw ax
    fprem1
    fnclex
    fnstsw ax
    fprem1
    fnclex
    fnstsw ax
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1117]
    fld tword [t1118]
    fprem
    fnclex
    fnstsw ax
    fprem
    fnclex
    fnstsw ax
    fprem
    fnclex
    fnstsw ax
    fprem
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1119]
    fld tword [t1120]
    fprem1
    fnclex
    fnstsw ax
    fprem1
    fnclex
    fnstsw ax
    fprem1
    fnclex
    fnstsw ax
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1121]
    fld tword [t1122]
    fprem
    fnclex
    fnstsw ax
    fprem
    fnclex
    fnstsw ax
    fprem
    fnclex
    fnstsw ax
    fprem
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1123]
    fld tword [t1124]
    fprem1
    fnclex
    fnstsw ax
    fprem1
    fnclex
    fnstsw ax
    fprem1
    fnclex
    fnstsw ax
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1125]
    fld tword [t1126]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1127]
    fld tword [t1128]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1129]
    fld tword [t1130]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1131]
    fld tword [t1132]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1133]
    fld tword [t1134]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1135]
    fld tword [t1136]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1137]
    fld tword [t1138]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1139]
    fld tword [t1140]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1141]
    fld tword [t1142]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1143]
    fld tword [t1144]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1145]
    fld tword [t1146]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1147]
    fld tword [t1148]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1149]
    fld tword [t1150]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1151]
    fld tword [t1152]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1153]
    fld tword [t1154]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1155]
    fld tword [t1156]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1157]
    fld tword [t1158]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1159]
    fld tword [t1160]
    fprem1
    fnclex
    fnstsw ax
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1161]
    fld tword [t1162]
    db 0x41, 0xD8, 0xC1             ; fadd st0, st1, with REX.B
    fstp tword [buf + 64]
    mov rax, [buf + 64]
    movzx edx, word [buf + 72]
    fstp st0
    fld tword [t1163]
    fld tword [t1164]
    ffree st1
    fnclex
    fnsave [area]
    mov rax, [area + 38]
    movzx edx, word [area + 46]
    mov esi, [area + 8]
    EXIT
    align 16
c0: dq 0xFFC000004F000000, 0xDF0000003DCCCCCD
c1: dq 0x7FF0000000000000, 0x4008000000000000
c2: dq 0x3, 0x0
c3: dq 0x7FC00000007FFFFF, 0xD01502F93F000000
c4: dq 0x7FF4000000000001, 0x40FE240C9FBE76C9
c5: dq 0x8000000000000000, 0x0
c6: dq 0x80000080000001, 0x1D01502F9
c7: dq 0xC08344D190D54D70, 0x0
c8: dq 0x1A6E8ECF28681EB, 0x0
c9: dq 0xBF8000003F800000, 0xC0F0000042BC44C3
c10: dq 0x4202A05F20000000, 0x402E4846FDF97640
c11: dq 0x100, 0x0
c12: dq 0x3F800000DF000000, 0x404000003F000000
c13: dq 0x43E158E460913D00, 0x730D67819E8D2
c14: dq 0xB965E3881D4B11A7, 0x0
c15: dq 0xC3CDAA0343BB5FDB, 0x7F8000007F800000
c16: dq 0xC1E0000000100000, 0x7FF8000012345678
c17: dq 0xFFFFFFFF80000000, 0x0
c18: dq 0x3F800000BF000000, 0x3F800000439CEC9B
c19: dq 0xC3E0000000000000, 0xC1E0000000000000
c20: dq 0xFFFFFFFF, 0x0
c21: dq 0xC0F000003FC00000, 0xC31CB97F006CE3EE
c22: dq 0x41DFFFFFFFE00000, 0x41F0000000000000
c23: dq 0xFFFFFFFFFFFFFF7D, 0x0
c24: dq 0x3FE0000000000000, 0x366244CE242C5561
c25: dq 0x7FFFFF7F7FC99E, 0x47F12065441A699F
c26: dq 0x7FFF, 0x0
c27: dq 0x41E0000000000000, 0x730D67819E8D2
c28: dq 0x800000003EFFFFFF, 0xC472EC913DCCCCCD
c29: dq 0xFFFFFFFFFFFFFF80, 0x0
c30: dq 0xC01E000000000000, 0xC202A05F20000000
c31: dq 0xFF8001234307A6C2, 0x8000004B800000
c32: dq 0x35, 0x0
c33: dq 0x408BE654152856FE, 0x4060BACB2B75F7A0
c34: dq 0xC38CF17B7F7FC99E, 0xC36DB59C5F000000
c35: dq 0xFFFFFFFFFFFFFF37, 0x0
c36: dq 0x10000000000000, 0x4004000000000000
c37: dq 0xCF00000043121CD5, 0x2EDBE6FF501502F9
c38: dq 0x516B7CDB696A1F30, 0x0
c39: dq 0x406FB3CDB20BB8C8, 0x3FB999999999999A
c40: dq 0x3DCCCCCD00000000, 0x3DCCCCCD4F000000
c41: dq 0x2, 0x0
c42: dq 0x7FEE42D130773B76, 0xC08A4D49F12D9AB9
c43: dq 0xBF800000D01502F9, 0x800000013DCCCCCD
c44: dq 0x3, 0x0
c45: dq 0xC08CCFA303F2D6B4, 0x40763DB5F57C62A8
c46: dq 0x3F80000000000000, 0xC41A594FFF800000
c47: dq 0x1B3C33EAA833990D, 0x0
c48: dq 0x43E0000000000000, 0x8000000000000000
c49: dq 0x6CE3EE7F800000, 0x7F7FFFFF7FA00001
c50: dq 0xE66504B2E977A40E, 0x0
c51: dq 0x366244CE242C5561, 0x10000000000000
c52: dq 0x6CE3EE00000001, 0x3EFFFFFF006CE3EE
c53: dq 0x0, 0x0
c54: dq 0x41DFFFFFFFE00000, 0xC004000000000000
c55: dq 0x80000047F12065, 0x1007FFFFF
c56: dq 0xD476EC3F975F7953, 0x0
c57: dq 0x47EFFFFFF0000000, 0x40FE240C9FBE76C9
c58: dq 0x42B743907FC00000, 0x7F7FC99EC464A6F3
c59: dq 0x255E9A002BB6E47E, 0x0
c60: dq 0x366244CE242C5561, 0x4340000000000000
c61: dq 0x3FC00000, 0x800000007FC12345
c62: dq 0xB6362DD3AE5FDB0, 0x0
c63: dq 0xBFF0000000000000, 0x3FF0000000000000
c64: dq 0x4354AD3F40F00000, 0xC3E1E90C3EFFFFFF
c65: dq 0x65413E68D3445556, 0x0
c66: dq 0x7FEFFFFFFFFFFFFF, 0x3FDFFFFFFFFFFFFF
c67: dq 0x5F000000BF000000, 0x7F7FC99E007FFFFF
c68: dq 0xF7E50BDE86265D34, 0x0
c69: dq 0x730D67819E8D2, 0x3DDB7CDFD9D7BDBB
c70: dq 0x800000FFC00000, 0xC3A639C8FFC00000
c71: dq 0x6E, 0x0
c72: dq 0xC01E000000000000, 0xC08198C8F949F9FD
c73: dq 0x800000004B800000, 0x80000001C0F00000
c74: dq 0xFFFFFFFFFFFFFFFF, 0x0
c75: dq 0xC06F8C2234C3930C, 0x3DDB7CDFD9D7BDBB
c76: dq 0x3FC000003FC00000, 0xC0200000DF000000
c77: dq 0xFFFFFFFFFFFFFF34, 0x0
c78: dq 0x3DDB7CDFD9D7BDBB, 0x3FF0000000000000
c79: dq 0x5F00000080000000, 0x6CE3EE00800000
c80: dq 0x308A2BCC3A2E4A9F, 0x0
c81: dq 0x43E0000000000000, 0x40FE240C9FBE76C9
c82: dq 0xC40274AD441EEB79, 0xBF8000003DCCCCCD
c83: dq 0x0, 0x0
c84: dq 0xC069C8414A366EA4, 0xC202A05F20000000
c85: dq 0xBF8000003FC00000, 0x7FC12345C450E85F
c86: dq 0x8ED0069AEA0D2F3C, 0x0
c87: dq 0x3FDFFFFFFFFFFFFF, 0x40822371A0A7B614
c88: dq 0x3FC000007F7FFFFF, 0xCF00000047F12065
c89: dq 0xBDD58B192718046E, 0x0
c90: dq 0x41F0000000000000, 0x40FE240C9FBE76C9
c91: dq 0xC42A924EBF800000, 0xC44E1285442D7886
c92: dq 0x859DC6375F48B7F, 0x0
c93: dq 0xBFE0000000000000, 0xC08C3B4C114B103E
c94: dq 0xD01502F93F000000, 0x3F00000000000000
c95: dq 0x1, 0x0
t0: dq 0xA000000000000000
    dw 0x4002, 0, 0, 0
t1: dq 0xB506FCA552243B70
    dw 0x400D, 0, 0, 0
t2: dq 0xCA3B361E13BD915E
    dw 0x400F, 0, 0, 0
t3: dq 0xC71BEA568DE3B8C3
    dw 0xBFF4, 0, 0, 0
t4: dq 0xE156D42798EABD16
    dw 0x3FDA, 0, 0, 0
t5: dq 0x8000800000000000
    dw 0xC00F, 0, 0, 0
t6: dq 0xA33A0A093ADE22C1
    dw 0xBFFE, 0, 0, 0
t7: dq 0xFD368D2631F44A64
    dw 0x3FEA, 0, 0, 0
t8: dq 0xB000000000000000
    dw 0x4001, 0, 0, 0
t9: dq 0xE000000000000000
    dw 0xC000, 0, 0, 0
t10: dq 0xA706704ED6000000
    dw 0xC024, 0, 0, 0
t11: dq 0x8001800000000000
    dw 0x400E, 0, 0, 0
t12: dq 0xC000000000000000
    dw 0x3FFF, 0, 0, 0
t13: dq 0xB000000000000000
    dw 0x4001, 0, 0, 0
t14: dq 0x8000000180000000
    dw 0xC01E, 0, 0, 0
t15: dq 0x8001800000000000
    dw 0xC00E, 0, 0, 0
t16: dq 0xF60A3CDD3BC63133
    dw 0x3FE6, 0, 0, 0
t17: dq 0xFFFFFFFE00000000
    dw 0x401C, 0, 0, 0
t18: dq 0x804CEF3B0F203806
    dw 0xC007, 0, 0, 0
t19: dq 0xC64370AF811C2AA2
    dw 0xC020, 0, 0, 0
t20: dq 0x877A75F2F76C9686
    dw 0xC015, 0, 0, 0
t21: dq 0x8000800000000000
    dw 0xC00E, 0, 0, 0
t22: dq 0x91BD3617797B7221
    dw 0xC015, 0, 0, 0
t23: dq 0xD8A149D1B676F322
    dw 0x400D, 0, 0, 0
t24: dq 0xE000000000000000
    dw 0xC000, 0, 0, 0
t25: dq 0xB000000000000000
    dw 0x4001, 0, 0, 0
t26: dq 0xB000000000000000
    dw 0x4001, 0, 0, 0
t27: dq 0xFFFFFFFF00000000
    dw 0x401D, 0, 0, 0
t28: dq 0xB000000000000000
    dw 0x4001, 0, 0, 0
t29: dq 0xD7D2C47469800000
    dw 0xC026, 0, 0, 0
t30: dq 0xC000000000000000
    dw 0xBFFF, 0, 0, 0
t31: dq 0xB000000000000000
    dw 0xC001, 0, 0, 0
t32: dq 0xF65254544F980825
    dw 0xC01F, 0, 0, 0
t33: dq 0xB0B885EBD91CB88C
    dw 0x4024, 0, 0, 0
t34: dq 0xCB52A9D5111C4FE1
    dw 0xBFF9, 0, 0, 0
t35: dq 0x8DD75D0F5C99200D
    dw 0xC009, 0, 0, 0
t36: dq 0xFFFFFFFE00000000
    dw 0xC01A, 0, 0, 0
t37: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t38: dq 0x84CF366BD8183BD2
    dw 0xC01B, 0, 0, 0
t39: dq 0xF005BBE7E6EAEFAD
    dw 0x4007, 0, 0, 0
t40: dq 0x8000000180000000
    dw 0xC01E, 0, 0, 0
t41: dq 0xC000000000000000
    dw 0x3FFF, 0, 0, 0
t42: dq 0xF000000000000000
    dw 0xC001, 0, 0, 0
t43: dq 0xF000000000000000
    dw 0xC001, 0, 0, 0
t44: dq 0xF000000000000000
    dw 0x4001, 0, 0, 0
t45: dq 0x8000000180000000
    dw 0x401E, 0, 0, 0
t46: dq 0x8000000180000000
    dw 0x401E, 0, 0, 0
t47: dq 0xF000000000000000
    dw 0xC001, 0, 0, 0
t48: dq 0xAADCB44E3E84A3AA
    dw 0x3FE8, 0, 0, 0
t49: dq 0xBA1F401F6BD2D0FD
    dw 0x3FF2, 0, 0, 0
t50: dq 0xA000000000000000
    dw 0xC007, 0, 0, 0
t51: dq 0xFF00000000000000
    dw 0xC006, 0, 0, 0
t52: dq 0x8000800000000000
    dw 0x400F, 0, 0, 0
t53: dq 0xEB2CEBF0E99512C1
    dw 0xC001, 0, 0, 0
t54: dq 0x9A2A32C5754547F4
    dw 0x3FEC, 0, 0, 0
t55: dq 0xAFC2C50304161E5B
    dw 0xBFD7, 0, 0, 0
t56: dq 0x8001800000000000
    dw 0x400E, 0, 0, 0
t57: dq 0xB000000000000000
    dw 0xC001, 0, 0, 0
t58: dq 0x8000000180000000
    dw 0xC01E, 0, 0, 0
t59: dq 0xFFFFFFFFFFFFFFFF
    dw 0xC03D, 0, 0, 0
t60: dq 0xFA48352551800000
    dw 0xC026, 0, 0, 0
t61: dq 0x8001800000000000
    dw 0x400E, 0, 0, 0
t62: dq 0x98D619B413800000
    dw 0xC026, 0, 0, 0
t63: dq 0x9A12C3BB80800000
    dw 0xC026, 0, 0, 0
t64: dq 0xA000000000000000
    dw 0x4002, 0, 0, 0
t65: dq 0xA000000000000000
    dw 0x4001, 0, 0, 0
t66: dq 0xEAFB873E1726B4F4
    dw 0xBFE3, 0, 0, 0
t67: dq 0x8000000000000000
    dw 0x3FFF, 0, 0, 0
t68: dq 0xD9E6AE5D9273D4E9
    dw 0x4019, 0, 0, 0
t69: dq 0xC2E70EDD90C9775F
    dw 0xBFFC, 0, 0, 0
t70: dq 0x8000000100000000
    dw 0xC023, 0, 0, 0
t71: dq 0xCD7D33D211B49AF4
    dw 0xC023, 0, 0, 0
t72: dq 0xFA00000000000000
    dw 0xC008, 0, 0, 0
t73: dq 0x8000000100000000
    dw 0xC01E, 0, 0, 0
t74: dq 0xB480D4754FDE68A2
    dw 0xBFEB, 0, 0, 0
t75: dq 0xEA32EF80FEE8DEA6
    dw 0x3FF8, 0, 0, 0
t76: dq 0xC35AE0CCE0C94BEB
    dw 0x3FF5, 0, 0, 0
t77: dq 0x8000000000000000
    dw 0x3FFE, 0, 0, 0
t78: dq 0xA000000000000000
    dw 0xC002, 0, 0, 0
t79: dq 0xE62E6CB0D29B4BE5
    dw 0xBFEE, 0, 0, 0
t80: dq 0xE700612CBC996B2A
    dw 0xC019, 0, 0, 0
t81: dq 0x9599400E207199B6
    dw 0xBFE4, 0, 0, 0
t82: dq 0xE01B350F813D6661
    dw 0xC00B, 0, 0, 0
t83: dq 0x964FDC41DB6D7F11
    dw 0xBFE0, 0, 0, 0
t84: dq 0xF41FDDAE7EE852A3
    dw 0x3FDE, 0, 0, 0
t85: dq 0xFF00000000000000
    dw 0xC006, 0, 0, 0
t86: dq 0x9E0E2FEB4AB30303
    dw 0xC026, 0, 0, 0
t87: dq 0xFC506AB7A8E0DB6F
    dw 0x3FDB, 0, 0, 0
t88: dq 0x880169C03220C2DE
    dw 0xBFF8, 0, 0, 0
t89: dq 0xE2C827C753CDDFC0
    dw 0xBFEE, 0, 0, 0
t90: dq 0xFFFFFFFE00000000
    dw 0x401C, 0, 0, 0
t91: dq 0x968DA68B5320FC7A
    dw 0x3FE2, 0, 0, 0
t92: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t93: dq 0x8000000000000000
    dw 0xBFFD, 0, 0, 0
t94: dq 0xA000000000000000
    dw 0x4002, 0, 0, 0
t95: dq 0xC8A6BE0B3DB9FADC
    dw 0xC008, 0, 0, 0
t96: dq 0x92461A2439A023A6
    dw 0xBFFF, 0, 0, 0
t97: dq 0xD496CBE9C2741B7F
    dw 0xBFFC, 0, 0, 0
t98: dq 0x8771F2BF8B4265DD
    dw 0xBFF7, 0, 0, 0
t99: dq 0xB035F8ABCB182956
    dw 0xBFF2, 0, 0, 0
t100: dq 0xFF00000000000000
    dw 0xC006, 0, 0, 0
t101: dq 0xA000000000000000
    dw 0x4001, 0, 0, 0
t102: dq 0xF867BA33BD1A9A56
    dw 0xC012, 0, 0, 0
t103: dq 0xFFFFFFFE00000000
    dw 0xC01A, 0, 0, 0
t104: dq 0xFF00000000000000
    dw 0xC006, 0, 0, 0
t105: dq 0xF8A462F5D85E9E49
    dw 0xC004, 0, 0, 0
t106: dq 0x8F6C85D947FA5127
    dw 0x3FD9, 0, 0, 0
t107: dq 0x96F7E05383CC6C10
    dw 0x401C, 0, 0, 0
t108: dq 0xA9D0248A295CF26E
    dw 0x3FDB, 0, 0, 0
t109: dq 0xE3579EAC025C8DFC
    dw 0xC001, 0, 0, 0
t110: dq 0x8000000000000000
    dw 0x3FFC, 0, 0, 0
t111: dq 0xFF00000000000000
    dw 0xC005, 0, 0, 0
t112: dq 0xF18DE8128F118B90
    dw 0x4009, 0, 0, 0
t113: dq 0xFA00000000000000
    dw 0x400D, 0, 0, 0
t114: dq 0x8000000100000000
    dw 0xC01E, 0, 0, 0
t115: dq 0x8000000100000000
    dw 0xC01D, 0, 0, 0
t116: dq 0xFFFFFFFE00000000
    dw 0x4022, 0, 0, 0
t117: dq 0xF133BBEC2B42678F
    dw 0xBFDA, 0, 0, 0
t118: dq 0xCCFF165D9EEDFE74
    dw 0x400D, 0, 0, 0
t119: dq 0xE35CF5D6141996A3
    dw 0x3FFE, 0, 0, 0
t120: dq 0xCD4B4FDE560498FD
    dw 0x3FD7, 0, 0, 0
t121: dq 0xFA00000000000000
    dw 0xC007, 0, 0, 0
t122: dq 0xF41D11BF4289A659
    dw 0xC002, 0, 0, 0
t123: dq 0x94801DC8D7E5CA54
    dw 0xC00E, 0, 0, 0
t124: dq 0xFFFFFFFE00000000
    dw 0x401C, 0, 0, 0
t125: dq 0xB669B55BD7D2E70E
    dw 0x4026, 0, 0, 0
t126: dq 0xD4A02FAAFCF19721
    dw 0x4012, 0, 0, 0
t127: dq 0xFF00000000000000
    dw 0x400B, 0, 0, 0
t128: dq 0xB395715CD96060B4
    dw 0xBFDF, 0, 0, 0
t129: dq 0x8000000100000000
    dw 0x4023, 0, 0, 0
t130: dq 0xA407CAE7F953F55A
    dw 0xBFFF, 0, 0, 0
t131: dq 0x82BC0847AAB98FFA
    dw 0x3FFE, 0, 0, 0
t132: dq 0xB537F7E74FABC2FC
    dw 0xC014, 0, 0, 0
t133: dq 0x8000000000000000
    dw 0x3FFE, 0, 0, 0
t134: dq 0xFF00000000000000
    dw 0xC006, 0, 0, 0
t135: dq 0x895CE5CA5C799051
    dw 0x4020, 0, 0, 0
t136: dq 0xC000000000000000
    dw 0x3FFD, 0, 0, 0
t137: dq 0xA0B3BCB64C4153CC
    dw 0xBFFF, 0, 0, 0
t138: dq 0x8000000100000000
    dw 0x401E, 0, 0, 0
t139: dq 0xF985F7C0FA28CE9E
    dw 0xC01D, 0, 0, 0
t140: dq 0x8000800000000000
    dw 0x4014, 0, 0, 0
t141: dq 0xFE6FE4D2F883C01C
    dw 0x3FE8, 0, 0, 0
t142: dq 0xC9A8C2536E1FCA7B
    dw 0xBFFE, 0, 0, 0
t143: dq 0xE86FDCB0F4D60854
    dw 0xC019, 0, 0, 0
t144: dq 0xFBAAD7E12C0FF0A1
    dw 0xBFFC, 0, 0, 0
t145: dq 0xE000000000000000
    dw 0x4000, 0, 0, 0
t146: dq 0xC1AF8BCAA34A43E7
    dw 0xBFE5, 0, 0, 0
t147: dq 0xB63B2B22AC1CA6F9
    dw 0x4003, 0, 0, 0
t148: dq 0xC000000000000000
    dw 0xBFFD, 0, 0, 0
t149: dq 0xB33D8780979E574F
    dw 0xBFE9, 0, 0, 0
t150: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t151: dq 0xDE3429153FD046A4
    dw 0xBFF3, 0, 0, 0
t152: dq 0x86F230A5229599EE
    dw 0x3FF7, 0, 0, 0
t153: dq 0x81F1CE3F2917AB50
    dw 0x3FF3, 0, 0, 0
t154: dq 0xBEABE24198E0AE67
    dw 0x401E, 0, 0, 0
t155: dq 0x99118706D9895E6A
    dw 0xC013, 0, 0, 0
t156: dq 0xE000000000000000
    dw 0x4006, 0, 0, 0
t157: dq 0xDF6E57115E602EBF
    dw 0x3FFF, 0, 0, 0
t158: dq 0xD598955AB73572B0
    dw 0x3FDB, 0, 0, 0
t159: dq 0x9372A0522565A2C7
    dw 0x4008, 0, 0, 0
t160: dq 0xD926AE3B99F5CD7F
    dw 0xC002, 0, 0, 0
t161: dq 0xDD8804091909A226
    dw 0x3FEA, 0, 0, 0
t162: dq 0x8A9CD51EB22A0B1A
    dw 0x4020, 0, 0, 0
t163: dq 0xFB095DE77066E690
    dw 0xBFF0, 0, 0, 0
t164: dq 0x9D1783D4D89A769A
    dw 0xBFF5, 0, 0, 0
t165: dq 0xD8D58A4D4FD02F3C
    dw 0xC010, 0, 0, 0
t166: dq 0xFDC36BECDDCF165C
    dw 0x401D, 0, 0, 0
t167: dq 0x95110E0B51243000
    dw 0x4012, 0, 0, 0
t168: dq 0x8000000000000000
    dw 0xC005, 0, 0, 0
t169: dq 0xF5DD58D1DD83F7F2
    dw 0xC015, 0, 0, 0
t170: dq 0x9BB67EA74809F401
    dw 0x4024, 0, 0, 0
t171: dq 0x85EEAA63C3FBF3F6
    dw 0xBFED, 0, 0, 0
t172: dq 0xFA00000000000000
    dw 0x4007, 0, 0, 0
t173: dq 0xBD5C079185224716
    dw 0xC00A, 0, 0, 0
t174: dq 0xFF00000000000000
    dw 0x400B, 0, 0, 0
t175: dq 0x8B0C0EE16FEC0963
    dw 0x3FD7, 0, 0, 0
t176: dq 0xCAD17968A8B1F8CF
    dw 0x3FEB, 0, 0, 0
t177: dq 0x8000800000000000
    dw 0x400C, 0, 0, 0
t178: dq 0x8000800000000000
    dw 0x400C, 0, 0, 0
t179: dq 0xFA00000000000000
    dw 0x4005, 0, 0, 0
t180: dq 0xAE37B5C6AA59E9DC
    dw 0xBFED, 0, 0, 0
t181: dq 0xD508D7DB45F93ADD
    dw 0xBFE1, 0, 0, 0
t182: dq 0xC5C4DE1653588F3B
    dw 0x401C, 0, 0, 0
t183: dq 0xA000000000000000
    dw 0x3FFE, 0, 0, 0
t184: dq 0xDFE898BD163D05E7
    dw 0xC016, 0, 0, 0
t185: dq 0xE0C32A5F8087A2E9
    dw 0x4010, 0, 0, 0
t186: dq 0xA29946D9FA88501E
    dw 0xC00F, 0, 0, 0
t187: dq 0xD022E91F0FED7949
    dw 0x3FFF, 0, 0, 0
t188: dq 0x97F6583C33DCAD25
    dw 0xBFEB, 0, 0, 0
t189: dq 0xBF35F0145D605750
    dw 0x4010, 0, 0, 0
t190: dq 0xF1CE261C57FC63E0
    dw 0xBFDE, 0, 0, 0
t191: dq 0xCD30D748F5E17AEB
    dw 0xBFE4, 0, 0, 0
t192: dq 0xC000000000000000
    dw 0x3FFD, 0, 0, 0
t193: dq 0xE000000000000000
    dw 0xC000, 0, 0, 0
t194: dq 0xA8EE8B1EEACEFB28
    dw 0x3FEA, 0, 0, 0
t195: dq 0x8EB85996707980DF
    dw 0xC014, 0, 0, 0
t196: dq 0xFA00000000000000
    dw 0xC005, 0, 0, 0
t197: dq 0xFA00000000000000
    dw 0x4008, 0, 0, 0
t198: dq 0xB20338C9C8848191
    dw 0xBFDD, 0, 0, 0
t199: dq 0xC000000000000000
    dw 0x3FFF, 0, 0, 0
t200: dq 0xA000000000000000
    dw 0x4002, 0, 0, 0
t201: dq 0xF08B0B8A93FF4BC7
    dw 0x4010, 0, 0, 0
t202: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t203: dq 0xE3FCA51015B25A62
    dw 0x4012, 0, 0, 0
t204: dq 0x942B45AB7932A35C
    dw 0xC002, 0, 0, 0
t205: dq 0xB91380B6786EF7C5
    dw 0x3FE4, 0, 0, 0
t206: dq 0xBE460AB77D490F39
    dw 0xBFFA, 0, 0, 0
t207: dq 0xB25C31557E80AA7B
    dw 0x4007, 0, 0, 0
t208: dq 0x8000000100000000
    dw 0x401E, 0, 0, 0
t209: dq 0xE7717CFC3DF97CA6
    dw 0x4021, 0, 0, 0
t210: dq 0x86D3158FC8D31B4D
    dw 0xBFDD, 0, 0, 0
t211: dq 0x99704DA01031F4AC
    dw 0x4024, 0, 0, 0
t212: dq 0xCF475F88ACDD7F84
    dw 0xBFE3, 0, 0, 0
t213: dq 0xE000000000000000
    dw 0xC000, 0, 0, 0
t214: dq 0x8000000000000000
    dw 0xC004, 0, 0, 0
t215: dq 0x8000800000000000
    dw 0xC00F, 0, 0, 0
t216: dq 0xA68C7556A9D3FDB0
    dw 0xBFF5, 0, 0, 0
t217: dq 0xA000000000000000
    dw 0xC001, 0, 0, 0
t218: dq 0x8000000100000000
    dw 0x4023, 0, 0, 0
t219: dq 0xE651A73FC19E2FB7
    dw 0xBFE2, 0, 0, 0
t220: dq 0xB7FD01CDA61AE7E4
    dw 0xC024, 0, 0, 0
t221: dq 0x8816862FCE2CD8C2
    dw 0xBFE4, 0, 0, 0
t222: dq 0xA120D21E1E99E616
    dw 0x3FE1, 0, 0, 0
t223: dq 0xFF00000000000000
    dw 0x4005, 0, 0, 0
t224: dq 0xE321B6B72AEEDE07
    dw 0x4008, 0, 0, 0
t225: dq 0xFA00000000000000
    dw 0x4008, 0, 0, 0
t226: dq 0xFFFFFFFE00000000
    dw 0xC01C, 0, 0, 0
t227: dq 0x85EED76FD8CF25C6
    dw 0x3FE9, 0, 0, 0
t228: dq 0xA000000000000000
    dw 0x4000, 0, 0, 0
t229: dq 0xD09E25D0DBA82667
    dw 0x4018, 0, 0, 0
t230: dq 0xFFFFFFFE00000000
    dw 0x401D, 0, 0, 0
t231: dq 0xE000000000000000
    dw 0xBFFE, 0, 0, 0
t232: dq 0xC000000000000000
    dw 0x3FFD, 0, 0, 0
t233: dq 0xB045A761F6E73DB3
    dw 0xC007, 0, 0, 0
t234: dq 0xDF2FED9783C0D25A
    dw 0xC009, 0, 0, 0
t235: dq 0x8000000000000000
    dw 0x3FFF, 0, 0, 0
t236: dq 0x8000800000000000
    dw 0xC014, 0, 0, 0
t237: dq 0xEC1638CEF7EDCDCE
    dw 0xBFFF, 0, 0, 0
t238: dq 0xA000000000000000
    dw 0x3FFF, 0, 0, 0
t239: dq 0xE2F51552BB8F77B8
    dw 0xBFEC, 0, 0, 0
t240: dq 0xD978905631AE3D20
    dw 0xC01E, 0, 0, 0
t241: dq 0xF7BD7C4692F969B2
    dw 0xC003, 0, 0, 0
t242: dq 0xD507DCBF1F1D8407
    dw 0x3FE9, 0, 0, 0
t243: dq 0x9DF4BB2B04C0B9BB
    dw 0x3FDB, 0, 0, 0
t244: dq 0xBBE8E23E4A7ECB63
    dw 0x400D, 0, 0, 0
t245: dq 0xE000000000000000
    dw 0x4000, 0, 0, 0
t246: dq 0x875E3336F97AF1BA
    dw 0xBFFC, 0, 0, 0
t247: dq 0x8000000000000000
    dw 0x3FFE, 0, 0, 0
t248: dq 0x9352C44882C41580
    dw 0x400D, 0, 0, 0
t249: dq 0xE894CDB2A8E279B9
    dw 0xC00F, 0, 0, 0
t250: dq 0xF6CFE89FA6C68E9E
    dw 0x3FF0, 0, 0, 0
t251: dq 0xADC417C9B4AECF8A
    dw 0xBFDE, 0, 0, 0
t252: dq 0xFFFFFFFE00000000
    dw 0xC01D, 0, 0, 0
t253: dq 0xFA00000000000000
    dw 0x4008, 0, 0, 0
t254: dq 0x8000000000000000
    dw 0xBFFC, 0, 0, 0
t255: dq 0x8000800000000000
    dw 0xC00C, 0, 0, 0
t256: dq 0xA000000000000000
    dw 0xBFFF, 0, 0, 0
t257: dq 0x9B3D410862EC19F7
    dw 0xC01B, 0, 0, 0
t258: dq 0xFF00000000000000
    dw 0x4003, 0, 0, 0
t259: dq 0xF0E94A095C908250
    dw 0xBFFE, 0, 0, 0
t260: dq 0xAA580FF31DE66DBF
    dw 0x3FFA, 0, 0, 0
t261: dq 0xA189F2986A113706
    dw 0x3FE8, 0, 0, 0
t262: dq 0xFF00000000000000
    dw 0xC003, 0, 0, 0
t263: dq 0xFA00000000000000
    dw 0x4007, 0, 0, 0
t264: dq 0xE908B121F94B5D99
    dw 0xBFF6, 0, 0, 0
t265: dq 0x839CFEDA55E6DF81
    dw 0x401F, 0, 0, 0
t266: dq 0xFF00000000000000
    dw 0xC00B, 0, 0, 0
t267: dq 0x85DE19B73B7E49B0
    dw 0x3FF3, 0, 0, 0
t268: dq 0xA000000000000000
    dw 0xBFFF, 0, 0, 0
t269: dq 0xF95C4AE8C5116035
    dw 0xBFFF, 0, 0, 0
t270: dq 0x9D77419468C299AF
    dw 0x3FF5, 0, 0, 0
t271: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t272: dq 0xB18B50E841F73774
    dw 0x401E, 0, 0, 0
t273: dq 0xD8E574478309240D
    dw 0x3FF2, 0, 0, 0
t274: dq 0x8000000000000000
    dw 0xBFFF, 0, 0, 0
t275: dq 0xC000000000000000
    dw 0xC000, 0, 0, 0
t276: dq 0xE79DCF048EAB595A
    dw 0xBFE7, 0, 0, 0
t277: dq 0xDB9E6A6D371F65D2
    dw 0xC01C, 0, 0, 0
t278: dq 0xE37FA00E755D58AE
    dw 0x4016, 0, 0, 0
t279: dq 0xA000000000000000
    dw 0x4002, 0, 0, 0
t280: dq 0xB496A9D2789B0B40
    dw 0xBFEA, 0, 0, 0
t281: dq 0xFF00000000000000
    dw 0xC003, 0, 0, 0
t282: dq 0xE46A0D5C90E2EC67
    dw 0xBFF9, 0, 0, 0
t283: dq 0xFA00000000000000
    dw 0xC008, 0, 0, 0
t284: dq 0xE70A5F2D86601565
    dw 0xC01C, 0, 0, 0
t285: dq 0xFFFFFFFE00000000
    dw 0xC01D, 0, 0, 0
t286: dq 0xBB66679319B390FE
    dw 0x4016, 0, 0, 0
t287: dq 0x8000000000000000
    dw 0x4004, 0, 0, 0
t288: dq 0x8000000100000000
    dw 0x401E, 0, 0, 0
t289: dq 0xE516FF4B52E31FF5
    dw 0x3FFD, 0, 0, 0
t290: dq 0xC000000000000000
    dw 0xC000, 0, 0, 0
t291: dq 0xA000000000000000
    dw 0xBFFF, 0, 0, 0
t292: dq 0x8000800000000000
    dw 0xC00C, 0, 0, 0
t293: dq 0xA000000000000000
    dw 0x3FFE, 0, 0, 0
t294: dq 0xFA00000000000000
    dw 0x4008, 0, 0, 0
t295: dq 0x8000000000000000
    dw 0xBFFC, 0, 0, 0
t296: dq 0x820DAFC46B8AFCCC
    dw 0xBFF2, 0, 0, 0
t297: dq 0xA000000000000000
    dw 0x4001, 0, 0, 0
t298: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t299: dq 0xFED45FA9011350B0
    dw 0xBFF5, 0, 0, 0
t300: dq 0xD6C27220F72841F3
    dw 0x3FE1, 0, 0, 0
t301: dq 0x8000800000000000
    dw 0xC00F, 0, 0, 0
t302: dq 0xE1959BD9BFA7041D
    dw 0x3FEA, 0, 0, 0
t303: dq 0xE000000000000000
    dw 0xBFFE, 0, 0, 0
t304: dq 0xA000000000000000
    dw 0xC002, 0, 0, 0
t305: dq 0x9224FB260B7E9226
    dw 0x3FF3, 0, 0, 0
t306: dq 0xDACD50FBF8BF7F56
    dw 0x4013, 0, 0, 0
t307: dq 0xA22511BACCDAEE72
    dw 0xBFF3, 0, 0, 0
t308: dq 0x943189E25733C18C
    dw 0xC006, 0, 0, 0
t309: dq 0xD4044BF7BBC281DC
    dw 0xC019, 0, 0, 0
t310: dq 0xBD1D7F6EE8836FC5
    dw 0xC009, 0, 0, 0
t311: dq 0xADE509005B6A9495
    dw 0xC025, 0, 0, 0
t312: dq 0x9CE7AEAD47C75615
    dw 0xBFDD, 0, 0, 0
t313: dq 0x96E567CCC67F0DEE
    dw 0xC004, 0, 0, 0
t314: dq 0xE000000000000000
    dw 0xC006, 0, 0, 0
t315: dq 0xE0A7CDFB1696B91E
    dw 0xC013, 0, 0, 0
t316: dq 0xDBD67D70E5F46FBB
    dw 0x3FEC, 0, 0, 0
t317: dq 0x84CE2FCCB82B9811
    dw 0x4024, 0, 0, 0
t318: dq 0xFE75397D54556FFF
    dw 0xC001, 0, 0, 0
t319: dq 0xA000000000000000
    dw 0x4006, 0, 0, 0
t320: dq 0xFFFFFFFE00000000
    dw 0xC01C, 0, 0, 0
t321: dq 0xBABBD5B9958ED85E
    dw 0x3FF7, 0, 0, 0
t322: dq 0x972B18E2094B4968
    dw 0x4016, 0, 0, 0
t323: dq 0xFA00000000000000
    dw 0x4005, 0, 0, 0
t324: dq 0x8B0B770CC08508FD
    dw 0xC012, 0, 0, 0
t325: dq 0xE02691C7B7597EEC
    dw 0x3FEF, 0, 0, 0
t326: dq 0xE8AB78145C3EC086
    dw 0xBFF3, 0, 0, 0
t327: dq 0xDCE02563E4E98637
    dw 0xC015, 0, 0, 0
t328: dq 0xBADFDB658B125FB4
    dw 0x3FDD, 0, 0, 0
t329: dq 0xD9BD2065645D98E3
    dw 0x400E, 0, 0, 0
t330: dq 0xE0660610001AA74B
    dw 0xBFFB, 0, 0, 0
t331: dq 0xE9486B12CADE91B9
    dw 0xC014, 0, 0, 0
t332: dq 0x93ECFFB7A7AB32FB
    dw 0xBFF5, 0, 0, 0
t333: dq 0xFA00000000000000
    dw 0xC00D, 0, 0, 0
t334: dq 0xB5D998E575BCAE95
    dw 0x4021, 0, 0, 0
t335: dq 0xB99AB476D8F28384
    dw 0x3FED, 0, 0, 0
t336: dq 0x8DBBC15AD49683C1
    dw 0x3FDC, 0, 0, 0
t337: dq 0xFF00000000000000
    dw 0xC003, 0, 0, 0
t338: dq 0xA5B829193B497E91
    dw 0x401E, 0, 0, 0
t339: dq 0xFF00000000000000
    dw 0xC005, 0, 0, 0
t340: dq 0xC2970FB0A0981FE2
    dw 0xBFF4, 0, 0, 0
t341: dq 0xC37311AA67B7877B
    dw 0x4005, 0, 0, 0
t342: dq 0xFF00000000000000
    dw 0xC006, 0, 0, 0
t343: dq 0x8000000000000000
    dw 0x3FFF, 0, 0, 0
t344: dq 0xAB1F58D03127C7CF
    dw 0xC019, 0, 0, 0
t345: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t346: dq 0xEA29B430D5C652B8
    dw 0x4025, 0, 0, 0
t347: dq 0x8000800000000000
    dw 0x400E, 0, 0, 0
t348: dq 0xF7816379BD7B1EBC
    dw 0xC016, 0, 0, 0
t349: dq 0xD6C745F2ACC4A45F
    dw 0xBFE5, 0, 0, 0
t350: dq 0xF4A99D6C1FA9359B
    dw 0xC00F, 0, 0, 0
t351: dq 0xE000000000000000
    dw 0xC001, 0, 0, 0
t352: dq 0xEAA7FD8658326EAB
    dw 0xC009, 0, 0, 0
t353: dq 0x8000000000000000
    dw 0xBFFC, 0, 0, 0
t354: dq 0xCE362B0914B6896A
    dw 0x400A, 0, 0, 0
t355: dq 0x8CA66043F515913E
    dw 0x400A, 0, 0, 0
t356: dq 0x8000000000000000
    dw 0xC004, 0, 0, 0
t357: dq 0xED823BE5841E949B
    dw 0xBFEC, 0, 0, 0
t358: dq 0xC297CF19E72EDE0A
    dw 0x3FD7, 0, 0, 0
t359: dq 0xC000000000000000
    dw 0x4000, 0, 0, 0
t360: dq 0x8000000000000000
    dw 0xC000, 0, 0, 0
t361: dq 0x9CC0521D06A0958E
    dw 0xBFE7, 0, 0, 0
t362: dq 0xFFFFFFFE00000000
    dw 0x401D, 0, 0, 0
t363: dq 0x8000000000000000
    dw 0xC005, 0, 0, 0
t364: dq 0x88CD1A43569897A6
    dw 0xBFED, 0, 0, 0
t365: dq 0xD4E635550C517F07
    dw 0xC024, 0, 0, 0
t366: dq 0x820714B862C9488D
    dw 0x4021, 0, 0, 0
t367: dq 0xFA1EEC3295526C04
    dw 0x3FDB, 0, 0, 0
t368: dq 0xFA00000000000000
    dw 0x4008, 0, 0, 0
t369: dq 0xFA00000000000000
    dw 0xC008, 0, 0, 0
t370: dq 0xFEC1244CD7E19E93
    dw 0x3FE2, 0, 0, 0
t371: dq 0x8000800000000000
    dw 0xC00C, 0, 0, 0
t372: dq 0xBE93D2E2082FF495
    dw 0xC024, 0, 0, 0
t373: dq 0x8000000000000000
    dw 0x4005, 0, 0, 0
t374: dq 0xC15C777C934481ED
    dw 0x4000, 0, 0, 0
t375: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t376: dq 0xD1A9C7DDC240A98B
    dw 0x3FE5, 0, 0, 0
t377: dq 0xA9B60941CA70595A
    dw 0xBFDF, 0, 0, 0
t378: dq 0xAAB7B091DE2848E1
    dw 0xC00F, 0, 0, 0
t379: dq 0x8000000000000000
    dw 0xC000, 0, 0, 0
t380: dq 0xC04FECDE6FA6E3CE
    dw 0xC003, 0, 0, 0
t381: dq 0xFA00000000000000
    dw 0x4008, 0, 0, 0
t382: dq 0xB8277FEFB2ABDD5A
    dw 0xBFF0, 0, 0, 0
t383: dq 0xC7E51F6852040019
    dw 0x3FE0, 0, 0, 0
t384: dq 0xA0E9B9CE8F7363D9
    dw 0xBFF7, 0, 0, 0
t385: dq 0x900420CE2CCB474A
    dw 0xBFFE, 0, 0, 0
t386: dq 0xB2AB117B804D27BD
    dw 0x4002, 0, 0, 0
t387: dq 0xF27452790D9096E8
    dw 0x4004, 0, 0, 0
t388: dq 0xC000000000000000
    dw 0xC000, 0, 0, 0
t389: dq 0x977AFB4C8C92CFF9
    dw 0x4006, 0, 0, 0
t390: dq 0xD2F50ED8D09BE651
    dw 0x4002, 0, 0, 0
t391: dq 0x8000800000000000
    dw 0xC00F, 0, 0, 0
t392: dq 0xF2F476E26C4DE1D9
    dw 0x3FFC, 0, 0, 0
t393: dq 0x99C8E4969A231865
    dw 0x4003, 0, 0, 0
t394: dq 0xAC861D5AE1FADFEF
    dw 0xC004, 0, 0, 0
t395: dq 0xF728F9518ABB3A92
    dw 0x4026, 0, 0, 0
t396: dq 0xEE982BB3C38F7352
    dw 0xC017, 0, 0, 0
t397: dq 0xC000000000000000
    dw 0x4000, 0, 0, 0
t398: dq 0xA6F51722D1B37CFB
    dw 0x4020, 0, 0, 0
t399: dq 0xD8D98DC8E6AD9B1C
    dw 0xC00C, 0, 0, 0
t400: dq 0x94CEA02F09F099C6
    dw 0xC024, 0, 0, 0
t401: dq 0xFF00000000000000
    dw 0xC006, 0, 0, 0
t402: dq 0xE7F7A7204D4B7854
    dw 0x3FE3, 0, 0, 0
t403: dq 0xED44FDA757352895
    dw 0x3FE1, 0, 0, 0
t404: dq 0xA5EBE56B5E7ABDA5
    dw 0xC01B, 0, 0, 0
t405: dq 0x8000800000000000
    dw 0xC00F, 0, 0, 0
t406: dq 0xFDCA2E3DBA002EB5
    dw 0xC00D, 0, 0, 0
t407: dq 0x9DA18594438AA7FB
    dw 0xBFF1, 0, 0, 0
t408: dq 0xA881E630E46D7DC6
    dw 0xBFFE, 0, 0, 0
t409: dq 0xA9C3365CC706F93D
    dw 0x3FF2, 0, 0, 0
t410: dq 0x8000000000000000
    dw 0xBFFE, 0, 0, 0
t411: dq 0xFBF06BF0AE1374C0
    dw 0x401D, 0, 0, 0
t412: dq 0xFF00000000000000
    dw 0x400B, 0, 0, 0
t413: dq 0x8000000000000000
    dw 0xC005, 0, 0, 0
t414: dq 0xC1FD16701F2B6373
    dw 0xC006, 0, 0, 0
t415: dq 0xB4563FFBB9C389ED
    dw 0xC018, 0, 0, 0
t416: dq 0x8000800000000000
    dw 0x400C, 0, 0, 0
t417: dq 0xAE577CAC3EB789BE
    dw 0xBFF5, 0, 0, 0
t418: dq 0xE000000000000000
    dw 0x4006, 0, 0, 0
t419: dq 0xFFFFFFFE00000000
    dw 0x4022, 0, 0, 0
t420: dq 0xE2B20F3EE49720F1
    dw 0x3FEB, 0, 0, 0
t421: dq 0xA000000000000000
    dw 0xBFFF, 0, 0, 0
t422: dq 0xF29EBED4F9C84D6C
    dw 0x3FED, 0, 0, 0
t423: dq 0x8000800000000000
    dw 0x400F, 0, 0, 0
t424: dq 0xA000000000000000
    dw 0xC002, 0, 0, 0
t425: dq 0xC70CCC1344EF91F0
    dw 0x4014, 0, 0, 0
t426: dq 0x92E2B14862977FA8
    dw 0x3FDB, 0, 0, 0
t427: dq 0xE0186D93C55DAAC5
    dw 0xBFF4, 0, 0, 0
t428: dq 0xDA7B8D6072E9D506
    dw 0x3FDC, 0, 0, 0
t429: dq 0x8000000000000000
    dw 0x3FFF, 0, 0, 0
t430: dq 0xFA4C2877DD22F84F
    dw 0x4010, 0, 0, 0
t431: dq 0xC74C5CEA97EB6094
    dw 0xBFFC, 0, 0, 0
t432: dq 0xAAAC55BBAD5E1CD0
    dw 0x4025, 0, 0, 0
t433: dq 0x989E8748289139B6
    dw 0x4005, 0, 0, 0
t434: dq 0xC6FFD38A494470A1
    dw 0xC00E, 0, 0, 0
t435: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t436: dq 0xC74602476605C12A
    dw 0x400B, 0, 0, 0
t437: dq 0xCA3E316C0774103A
    dw 0x401A, 0, 0, 0
t438: dq 0xA495FF4B7BEE8310
    dw 0xBFF3, 0, 0, 0
t439: dq 0x90D5E44A5608E5A9
    dw 0xBFDA, 0, 0, 0
t440: dq 0xA67465DB6C7B1496
    dw 0xBFE2, 0, 0, 0
t441: dq 0xF0B53967B147E511
    dw 0xC008, 0, 0, 0
t442: dq 0xE3702DDE73C4B2E5
    dw 0xC024, 0, 0, 0
t443: dq 0xD9A021A1E35BE77F
    dw 0xC012, 0, 0, 0
t444: dq 0xF1C84EE99C5D72FF
    dw 0xBFF3, 0, 0, 0
t445: dq 0x9D398C076F37A614
    dw 0xC016, 0, 0, 0
t446: dq 0xE71E621A7C12D3E1
    dw 0xBFFD, 0, 0, 0
t447: dq 0xEB014F493DC64520
    dw 0xC025, 0, 0, 0
t448: dq 0xFFFFFFFE00000000
    dw 0xC01A, 0, 0, 0
t449: dq 0x8000000100000000
    dw 0x401D, 0, 0, 0
t450: dq 0xFFFFFFFE00000000
    dw 0xC022, 0, 0, 0
t451: dq 0x8000000000000000
    dw 0x3FFE, 0, 0, 0
t452: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t453: dq 0xE7DC244A5D0F412A
    dw 0xBFE9, 0, 0, 0
t454: dq 0x9D69843FABE666D2
    dw 0xC00E, 0, 0, 0
t455: dq 0xFA00000000000000
    dw 0x400D, 0, 0, 0
t456: dq 0x8000800000000000
    dw 0xC00F, 0, 0, 0
t457: dq 0xB6892A519CF431B1
    dw 0x4004, 0, 0, 0
t458: dq 0xF06C3E71D63D9E56
    dw 0x3FE2, 0, 0, 0
t459: dq 0x8000800000000000
    dw 0x400F, 0, 0, 0
t460: dq 0xC78AE091EA577359
    dw 0xC023, 0, 0, 0
t461: dq 0xA000000000000000
    dw 0x4007, 0, 0, 0
t462: dq 0xC000000000000000
    dw 0x3FFF, 0, 0, 0
t463: dq 0x8000000000000000
    dw 0xBFFD, 0, 0, 0
t464: dq 0x91AC2C183410159B
    dw 0xBFD7, 0, 0, 0
t465: dq 0xC33328E142E71BF9
    dw 0x4018, 0, 0, 0
t466: dq 0xC2A13D777F608828
    dw 0xC006, 0, 0, 0
t467: dq 0xAF54A4C00301692E
    dw 0xC006, 0, 0, 0
t468: dq 0xA05DE14B427CE209
    dw 0x3FFB, 0, 0, 0
t469: dq 0xE2090633838C2041
    dw 0xC023, 0, 0, 0
t470: dq 0x9EB2BEEE08C87CDC
    dw 0xC013, 0, 0, 0
t471: dq 0xCDAECEF030F77DB0
    dw 0x3FE8, 0, 0, 0
t472: dq 0xE000000000000000
    dw 0xC001, 0, 0, 0
t473: dq 0x8000000000000000
    dw 0x3FFF, 0, 0, 0
t474: dq 0xA000000000000000
    dw 0xC006, 0, 0, 0
t475: dq 0xD7CFCAF3D763F36C
    dw 0xBFF3, 0, 0, 0
t476: dq 0xB40316D82F674CF3
    dw 0xC017, 0, 0, 0
t477: dq 0x9D99A215E28A70DD
    dw 0x3FF1, 0, 0, 0
t478: dq 0x90E10F571B63E785
    dw 0x4002, 0, 0, 0
t479: dq 0xEA440B3F50CD2CB7
    dw 0x400C, 0, 0, 0
t480: dq 0xE33BD98B4CFE9DA9
    dw 0x4000, 0, 0, 0
t481: dq 0xC000000000000000
    dw 0xC000, 0, 0, 0
t482: dq 0xF874D068B3551365
    dw 0xBFED, 0, 0, 0
t483: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t484: dq 0xDD208FC9F7C5FA16
    dw 0x3FED, 0, 0, 0
t485: dq 0x96A73CDD59ADF531
    dw 0x4017, 0, 0, 0
t486: dq 0xFFFFFFFE00000000
    dw 0xC01D, 0, 0, 0
t487: dq 0x8000000000000000
    dw 0xBFFF, 0, 0, 0
t488: dq 0x87D1DC21B9763652
    dw 0x4009, 0, 0, 0
t489: dq 0xA12A934250BD1AA4
    dw 0x4013, 0, 0, 0
t490: dq 0xFA00000000000000
    dw 0x4007, 0, 0, 0
t491: dq 0xA000000000000000
    dw 0x4001, 0, 0, 0
t492: dq 0xC182F6E30CECE691
    dw 0xBFED, 0, 0, 0
t493: dq 0xE2608F86ECC022F3
    dw 0xBFE6, 0, 0, 0
t494: dq 0xC000000000000000
    dw 0x3FFF, 0, 0, 0
t495: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t496: dq 0xAF95AC7D81BF67FC
    dw 0x3FD9, 0, 0, 0
t497: dq 0xFFFFFFFE00000000
    dw 0x401A, 0, 0, 0
t498: dq 0xC3B533274E46270D
    dw 0x4010, 0, 0, 0
t499: dq 0xFFFFFFFE00000000
    dw 0x401D, 0, 0, 0
t500: dq 0xDC874426E646A898
    dw 0xBFF6, 0, 0, 0
t501: dq 0xE799C7294293D3DE
    dw 0x4009, 0, 0, 0
t502: dq 0xC349F80F276D2C47
    dw 0x3FF0, 0, 0, 0
t503: dq 0x8000000000000000
    dw 0xC000, 0, 0, 0
t504: dq 0xE2D0AD2D5777B71B
    dw 0xBFF4, 0, 0, 0
t505: dq 0xFFCAD4484BA33792
    dw 0xBFE3, 0, 0, 0
t506: dq 0xFF00000000000000
    dw 0xC006, 0, 0, 0
t507: dq 0xA1BA6C8A81D7B28E
    dw 0xC000, 0, 0, 0
t508: dq 0xEB261F3216DFB303
    dw 0x3FDD, 0, 0, 0
t509: dq 0x80C76772419A6AC6
    dw 0x4019, 0, 0, 0
t510: dq 0xA94780D2ECE967CB
    dw 0xBFEB, 0, 0, 0
t511: dq 0x8000000100000000
    dw 0xC01D, 0, 0, 0
t512: dq 0x8000000000000000
    dw 0x3FFF, 0, 0, 0
t513: dq 0xCF3D14C176E21785
    dw 0xC00B, 0, 0, 0
t514: dq 0xBFFB9344518CE444
    dw 0x3FD9, 0, 0, 0
t515: dq 0x87ED30D2B2AF7A61
    dw 0x400E, 0, 0, 0
t516: dq 0xD595CF4E88F83749
    dw 0x3FF2, 0, 0, 0
t517: dq 0xC2AB34514EDA0C5C
    dw 0xBFF3, 0, 0, 0
t518: dq 0x8992C8FD392FAD2C
    dw 0x4004, 0, 0, 0
t519: dq 0xD4A0E6A23F32E23C
    dw 0x3FEB, 0, 0, 0
t520: dq 0xE000000000000000
    dw 0x4000, 0, 0, 0
t521: dq 0xBAE1F8929ADF5C5E
    dw 0x3FF7, 0, 0, 0
t522: dq 0x8000000000000000
    dw 0xC004, 0, 0, 0
t523: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t524: dq 0xE5E3DE6562720D05
    dw 0x3FDF, 0, 0, 0
t525: dq 0x91AE5FFCE4CA3D4B
    dw 0x3FE6, 0, 0, 0
t526: dq 0xF4BF7FD57FED1ABA
    dw 0x3FFF, 0, 0, 0
t527: dq 0xBAC7891428F2E89B
    dw 0x3FFD, 0, 0, 0
t528: dq 0xAE4CFF22B0D604E2
    dw 0x3FE2, 0, 0, 0
t529: dq 0xFF00000000000000
    dw 0x400B, 0, 0, 0
t530: dq 0xCE9CFEEA9A74AEE1
    dw 0x3FF6, 0, 0, 0
t531: dq 0xC2769FC5E0696B23
    dw 0xBFFB, 0, 0, 0
t532: dq 0xE089B4C0E2020556
    dw 0xC026, 0, 0, 0
t533: dq 0x8000000000000000
    dw 0x3FFF, 0, 0, 0
t534: dq 0xFEC184749ED97404
    dw 0x4005, 0, 0, 0
t535: dq 0x8000800000000000
    dw 0x400F, 0, 0, 0
t536: dq 0xF628327144CA72F0
    dw 0xC018, 0, 0, 0
t537: dq 0xA000000000000000
    dw 0x4001, 0, 0, 0
t538: dq 0xB96E7EC1A62E4BCE
    dw 0xBFE1, 0, 0, 0
t539: dq 0xEA9F1358D05D24B7
    dw 0x4025, 0, 0, 0
t540: dq 0x9F413BA453D0D4E9
    dw 0x4016, 0, 0, 0
t541: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t542: dq 0xFA00000000000000
    dw 0x4008, 0, 0, 0
t543: dq 0x8D5FB11F248DC0EA
    dw 0xC01F, 0, 0, 0
t544: dq 0x8000000000000000
    dw 0x4004, 0, 0, 0
t545: dq 0xBBF32423BC2251EF
    dw 0x4011, 0, 0, 0
t546: dq 0xF972264B035CFF7B
    dw 0xC004, 0, 0, 0
t547: dq 0x96785ACF72E3A7F6
    dw 0xC00B, 0, 0, 0
t548: dq 0xC5D84F57C81D59AE
    dw 0x3FD7, 0, 0, 0
t549: dq 0x8D0079353A52AE4E
    dw 0xC022, 0, 0, 0
t550: dq 0xBF39B503C75C5CE0
    dw 0x3FF8, 0, 0, 0
t551: dq 0xDE35480E30CD8C28
    dw 0x4022, 0, 0, 0
t552: dq 0xFFFFFFFE00000000
    dw 0xC01C, 0, 0, 0
t553: dq 0x8000000000000000
    dw 0x4004, 0, 0, 0
t554: dq 0xFA00000000000000
    dw 0xC007, 0, 0, 0
t555: dq 0xE000000000000000
    dw 0xC000, 0, 0, 0
t556: dq 0xDAAC0946A34B6146
    dw 0xC011, 0, 0, 0
t557: dq 0xE2E229DBA42BF3F8
    dw 0x4004, 0, 0, 0
t558: dq 0xA000000000000000
    dw 0xBFFF, 0, 0, 0
t559: dq 0xC000000000000000
    dw 0xC000, 0, 0, 0
t560: dq 0x930011FA2AD92830
    dw 0xC019, 0, 0, 0
t561: dq 0xA000000000000000
    dw 0x4002, 0, 0, 0
t562: dq 0xBD3533DFE61917D8
    dw 0x400C, 0, 0, 0
t563: dq 0xFF00000000000000
    dw 0xC003, 0, 0, 0
t564: dq 0x95E7422AEDFE156F
    dw 0x4005, 0, 0, 0
t565: dq 0xC000000000000000
    dw 0x4005, 0, 0, 0
t566: dq 0x8CB44F9290E7E04A
    dw 0xC003, 0, 0, 0
t567: dq 0xCF91DCA106836B50
    dw 0x401E, 0, 0, 0
t568: dq 0x8000800000000000
    dw 0xC00E, 0, 0, 0
t569: dq 0x8000800000000000
    dw 0xC00F, 0, 0, 0
t570: dq 0x931EB7023FA57DFB
    dw 0xBFDE, 0, 0, 0
t571: dq 0xE000000000000000
    dw 0xC001, 0, 0, 0
t572: dq 0xE8A42492F7B7FA9E
    dw 0x3FE3, 0, 0, 0
t573: dq 0x8000000000000000
    dw 0x3FFD, 0, 0, 0
t574: dq 0xD2C8E30AC3342102
    dw 0x3FF5, 0, 0, 0
t575: dq 0xFFFFFFFE00000000
    dw 0x401A, 0, 0, 0
t576: dq 0x8DE7A865685F6AAE
    dw 0xC00B, 0, 0, 0
t577: dq 0xA65B4534B2CFAF9D
    dw 0x4002, 0, 0, 0
t578: dq 0xD484E36F10302AE6
    dw 0xBFF4, 0, 0, 0
t579: dq 0x8000000000000000
    dw 0xC005, 0, 0, 0
t580: dq 0xA000000000000000
    dw 0xC000, 0, 0, 0
t581: dq 0x816B87EE4808BFB5
    dw 0xC024, 0, 0, 0
t582: dq 0xB60C3F9202A4E120
    dw 0x4023, 0, 0, 0
t583: dq 0x953692646E724B2C
    dw 0x400A, 0, 0, 0
t584: dq 0xD4F2D4F36F4D61DD
    dw 0xBFDD, 0, 0, 0
t585: dq 0xEC2B855048322FF8
    dw 0x4010, 0, 0, 0
t586: dq 0x85A99676557EC722
    dw 0x4004, 0, 0, 0
t587: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t588: dq 0xD23A9C063D5BC122
    dw 0xBFDC, 0, 0, 0
t589: dq 0x834FAA972E5CA0FF
    dw 0x3FF8, 0, 0, 0
t590: dq 0xA13D1BD4B471D452
    dw 0xC018, 0, 0, 0
t591: dq 0x8000000000000000
    dw 0x3FFF, 0, 0, 0
t592: dq 0x8B76F5849A8BCC66
    dw 0xBFDB, 0, 0, 0
t593: dq 0xEE339826A2B7363A
    dw 0x3FE1, 0, 0, 0
t594: dq 0xC03D4AB8C8460023
    dw 0xC00B, 0, 0, 0
t595: dq 0x8000000000000000
    dw 0xC005, 0, 0, 0
t596: dq 0xBF71E530E17F2307
    dw 0x3FF8, 0, 0, 0
t597: dq 0x81AF4A8A5832C4FC
    dw 0xBFE1, 0, 0, 0
t598: dq 0x86FB4A6BB007EAC4
    dw 0xC007, 0, 0, 0
t599: dq 0xA64FBC1724A7F786
    dw 0xBFF0, 0, 0, 0
t600: dq 0xF489AEFD18C74CFE
    dw 0xC00A, 0, 0, 0
t601: dq 0x8000000100000000
    dw 0x4023, 0, 0, 0
t602: dq 0xA1B8C5FA08476B34
    dw 0xC025, 0, 0, 0
t603: dq 0xFF00000000000000
    dw 0xC003, 0, 0, 0
t604: dq 0xC9774BB45688673F
    dw 0xBFFE, 0, 0, 0
t605: dq 0xA000000000000000
    dw 0xC002, 0, 0, 0
t606: dq 0xC000000000000000
    dw 0xC000, 0, 0, 0
t607: dq 0xC5B7515A8D974613
    dw 0x3FE1, 0, 0, 0
t608: dq 0x984555E25D6EA081
    dw 0xBFF4, 0, 0, 0
t609: dq 0xD47A72D57FF69518
    dw 0x4004, 0, 0, 0
t610: dq 0xC000000000000000
    dw 0xBFFD, 0, 0, 0
t611: dq 0xAF3E645FC3C1D715
    dw 0x4013, 0, 0, 0
t612: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t613: dq 0xC000000000000000
    dw 0xBFFD, 0, 0, 0
t614: dq 0x8000000100000000
    dw 0xC01E, 0, 0, 0
t615: dq 0xAFACD46E10DB0C2A
    dw 0x4013, 0, 0, 0
t616: dq 0xA2F1BB7CE7FB2C6B
    dw 0x3FEA, 0, 0, 0
t617: dq 0xE3A7E06033EF2CC8
    dw 0x4020, 0, 0, 0
t618: dq 0xF7777CDD3AD3F79B
    dw 0x3FE4, 0, 0, 0
t619: dq 0xD8D2215675943B39
    dw 0x4011, 0, 0, 0
t620: dq 0x8000000000000000
    dw 0x4005, 0, 0, 0
t621: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t622: dq 0xFEBEB090D683E766
    dw 0xC023, 0, 0, 0
t623: dq 0x8000000000000000
    dw 0xC005, 0, 0, 0
t624: dq 0x8000000000000000
    dw 0x3FFC, 0, 0, 0
t625: dq 0x8000000000000000
    dw 0xC004, 0, 0, 0
t626: dq 0xA930AFAE5F502195
    dw 0xBFD8, 0, 0, 0
t627: dq 0xA36B7DE8E62BDC9C
    dw 0x4003, 0, 0, 0
t628: dq 0xC5CA2B6914FF712A
    dw 0x4007, 0, 0, 0
t629: dq 0xD7BE325FD74DBB4D
    dw 0x4001, 0, 0, 0
t630: dq 0xB1620C1606E76B0F
    dw 0x4024, 0, 0, 0
t631: dq 0xE1F33BA67FE69B2D
    dw 0x401F, 0, 0, 0
t632: dq 0xD73926088005966F
    dw 0xC00F, 0, 0, 0
t633: dq 0xC000000000000000
    dw 0xC000, 0, 0, 0
t634: dq 0xD5AB9BEB3C0C9475
    dw 0x4008, 0, 0, 0
t635: dq 0x8000800000000000
    dw 0x400F, 0, 0, 0
t636: dq 0xB5C6C893DDAB37D3
    dw 0x4008, 0, 0, 0
t637: dq 0xC315AD9C3669638F
    dw 0xBFDE, 0, 0, 0
t638: dq 0xE39ED8C5064496D6
    dw 0x401F, 0, 0, 0
t639: dq 0xFF00000000000000
    dw 0x4003, 0, 0, 0
t640: dq 0x950A26447BE7C0B4
    dw 0x3FE9, 0, 0, 0
t641: dq 0xB009C2429199B348
    dw 0x401A, 0, 0, 0
t642: dq 0x8963E15F8DA918A4
    dw 0xC021, 0, 0, 0
t643: dq 0x8000000100000000
    dw 0x401E, 0, 0, 0
t644: dq 0xFA00000000000000
    dw 0xC00D, 0, 0, 0
t645: dq 0xFFFFFFFE00000000
    dw 0xC01C, 0, 0, 0
t646: dq 0xAC02353237A9D908
    dw 0x3FF5, 0, 0, 0
t647: dq 0xB19D7858F7C4DF85
    dw 0x3FEC, 0, 0, 0
t648: dq 0xB32D21A337C28186
    dw 0x4007, 0, 0, 0
t649: dq 0x9FF5323E59474E3C
    dw 0x3FE1, 0, 0, 0
t650: dq 0xCFF969190011756E
    dw 0x3FF7, 0, 0, 0
t651: dq 0xE1896CA31ED8111C
    dw 0x3FF3, 0, 0, 0
t652: dq 0xFA00000000000000
    dw 0x4005, 0, 0, 0
t653: dq 0x8000800000000000
    dw 0xC00C, 0, 0, 0
t654: dq 0x809609BC7619546F
    dw 0x4006, 0, 0, 0
t655: dq 0xBC1B556D29DDF34A
    dw 0xC01F, 0, 0, 0
t656: dq 0xE1A7869576CDCEAF
    dw 0xC018, 0, 0, 0
t657: dq 0xFB90B0280831F097
    dw 0x3FE7, 0, 0, 0
t658: dq 0x8E3D13B43D59BB47
    dw 0x4018, 0, 0, 0
t659: dq 0xA19BE613C8743A10
    dw 0xC00B, 0, 0, 0
t660: dq 0x9783FDC5B79F2C9D
    dw 0xC009, 0, 0, 0
t661: dq 0xE288B1739A523E15
    dw 0x3FDA, 0, 0, 0
t662: dq 0x91A7C3A751B7A7F8
    dw 0xBFE2, 0, 0, 0
t663: dq 0xF1D8EFFF7E19D8B2
    dw 0xBFF7, 0, 0, 0
t664: dq 0xA4C7A0B4DC0F8F36
    dw 0xBFD8, 0, 0, 0
t665: dq 0xFB760DCB39F680F7
    dw 0x3FD8, 0, 0, 0
t666: dq 0xA000000000000000
    dw 0x3FFE, 0, 0, 0
t667: dq 0xC40719707AB006D3
    dw 0x3FEA, 0, 0, 0
t668: dq 0xFF00000000000000
    dw 0x4003, 0, 0, 0
t669: dq 0xC61E41D74FC3638B
    dw 0x3FEB, 0, 0, 0
t670: dq 0xFA00000000000000
    dw 0x4008, 0, 0, 0
t671: dq 0x86DB5AE88B4E9823
    dw 0xC01D, 0, 0, 0
t672: dq 0xCD24304282F35D17
    dw 0xBFEC, 0, 0, 0
t673: dq 0x9B1DDC4AE9EA8719
    dw 0xC013, 0, 0, 0
t674: dq 0x903C77560BC07F39
    dw 0x4017, 0, 0, 0
t675: dq 0xFFFFFFFE00000000
    dw 0xC01A, 0, 0, 0
t676: dq 0xC000000000000000
    dw 0x4005, 0, 0, 0
t677: dq 0x8000000000000000
    dw 0xBFFF, 0, 0, 0
t678: dq 0xD763CED3DF4F80C7
    dw 0x401C, 0, 0, 0
t679: dq 0xCC9BE4C68924F41F
    dw 0xC015, 0, 0, 0
t680: dq 0x83227263585B00D9
    dw 0xBFF6, 0, 0, 0
t681: dq 0xA000000000000000
    dw 0x3FFE, 0, 0, 0
t682: dq 0x9F5F75C98E3FF091
    dw 0xBFF7, 0, 0, 0
t683: dq 0x95F247D1D670290C
    dw 0xC002, 0, 0, 0
t684: dq 0xC000000000000000
    dw 0x4000, 0, 0, 0
t685: dq 0xFA00000000000000
    dw 0x400D, 0, 0, 0
t686: dq 0xDDDCE91EE94A0738
    dw 0x3FDA, 0, 0, 0
t687: dq 0xA000000000000000
    dw 0xC002, 0, 0, 0
t688: dq 0xB6BE931ACDBCCEA5
    dw 0xC007, 0, 0, 0
t689: dq 0xA000000000000000
    dw 0x4000, 0, 0, 0
t690: dq 0x90A91A58E3F9FC10
    dw 0x4019, 0, 0, 0
t691: dq 0xFF00000000000000
    dw 0xC006, 0, 0, 0
t692: dq 0x9A2B719FAD0B363D
    dw 0xBFFF, 0, 0, 0
t693: dq 0x8000000100000000
    dw 0x401B, 0, 0, 0
t694: dq 0x85BD22603B584628
    dw 0x3FDF, 0, 0, 0
t695: dq 0xBF58247368537EB9
    dw 0x3FDA, 0, 0, 0
t696: dq 0xF574383E7314A39D
    dw 0x4003, 0, 0, 0
t697: dq 0x8000800000000000
    dw 0xC014, 0, 0, 0
t698: dq 0xFA00000000000000
    dw 0x400D, 0, 0, 0
t699: dq 0x8000000100000000
    dw 0x401B, 0, 0, 0
t700: dq 0xB013697DF9D72808
    dw 0x4010, 0, 0, 0
t701: dq 0x86F46EC03D9274C7
    dw 0xC00E, 0, 0, 0
t702: dq 0xD69E1EE8FAF35114
    dw 0xC00C, 0, 0, 0
t703: dq 0xE000000000000000
    dw 0xBFFE, 0, 0, 0
t704: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t705: dq 0xA791CF2E81BC92DF
    dw 0xBFE1, 0, 0, 0
t706: dq 0xD0EF7EF67C9FFC57
    dw 0x400A, 0, 0, 0
t707: dq 0x950C889CB9B78904
    dw 0xC023, 0, 0, 0
t708: dq 0x9084DE0EC9252FA0
    dw 0xC006, 0, 0, 0
t709: dq 0x876617267BF1B092
    dw 0xBFF0, 0, 0, 0
t710: dq 0xED27A81D9B1F6A9A
    dw 0x401A, 0, 0, 0
t711: dq 0x8000000100000000
    dw 0xC023, 0, 0, 0
t712: dq 0xCC6112DCBF3DB140
    dw 0xC006, 0, 0, 0
t713: dq 0xD01D36440A385A42
    dw 0xBFFA, 0, 0, 0
t714: dq 0xBDCB6E3DE199DB30
    dw 0xC016, 0, 0, 0
t715: dq 0xBDEF7BA8229D8856
    dw 0xC00F, 0, 0, 0
t716: dq 0xA000000000000000
    dw 0xC007, 0, 0, 0
t717: dq 0xA000000000000000
    dw 0x3FFE, 0, 0, 0
t718: dq 0xCF06BCD7828ED14A
    dw 0xBFDC, 0, 0, 0
t719: dq 0xCE592F234B3D5E75
    dw 0x401F, 0, 0, 0
t720: dq 0xA97395FF71BFD0FB
    dw 0x3FE2, 0, 0, 0
t721: dq 0xFF00000000000000
    dw 0xC006, 0, 0, 0
t722: dq 0xFF00000000000000
    dw 0x4003, 0, 0, 0
t723: dq 0x8000000000000000
    dw 0xBFFF, 0, 0, 0
t724: dq 0xFFFFFFFE00000000
    dw 0xC01D, 0, 0, 0
t725: dq 0xD3FEF4FF99629817
    dw 0x3FE5, 0, 0, 0
t726: dq 0xF6CCC9D03D658C66
    dw 0x3FF3, 0, 0, 0
t727: dq 0xA000000000000000
    dw 0xC000, 0, 0, 0
t728: dq 0x8000800000000000
    dw 0x400F, 0, 0, 0
t729: dq 0x83DE1A69F4D50429
    dw 0x3FE0, 0, 0, 0
t730: dq 0xC01D3E1CD215AA10
    dw 0x400D, 0, 0, 0
t731: dq 0xB64B73ADFBF5C882
    dw 0x3FFB, 0, 0, 0
t732: dq 0xA000000000000000
    dw 0xC001, 0, 0, 0
t733: dq 0xADB001A259777320
    dw 0x4012, 0, 0, 0
t734: dq 0xC76A14204733FD8A
    dw 0xBFE9, 0, 0, 0
t735: dq 0x8000000100000000
    dw 0xC01E, 0, 0, 0
t736: dq 0x0
    dw 0x8000, 0, 0, 0
t737: dq 0xE4323B8383AD2797
    dw 0x4012, 0, 0, 0
t738: dq 0x0
    dw 0x0, 0, 0, 0
t739: dq 0xFB41300ADA580C43
    dw 0xBFF9, 0, 0, 0
t740: dq 0x0
    dw 0x0, 0, 0, 0
t741: dq 0x9431ED96341BA9DC
    dw 0xC016, 0, 0, 0
t742: dq 0xD6E727EFED23721E
    dw 0xBFD8, 0, 0, 0
t743: dq 0xA92B3D3A2B96A1E3
    dw 0x3FF6, 0, 0, 0
t744: dq 0x0
    dw 0x8000, 0, 0, 0
t745: dq 0xBAA819EF21879299
    dw 0x3FEB, 0, 0, 0
t746: dq 0x0
    dw 0x0, 0, 0, 0
t747: dq 0xF4E460B07A56EC03
    dw 0x4007, 0, 0, 0
t748: dq 0x8000000000000000
    dw 0x7FFF, 0, 0, 0
t749: dq 0x8000000000000000
    dw 0xFFFF, 0, 0, 0
t750: dq 0x8000000000000000
    dw 0xFFFF, 0, 0, 0
t751: dq 0x94C15AE75D3DD15E
    dw 0x3FF6, 0, 0, 0
t752: dq 0x8000000000000000
    dw 0x7FFF, 0, 0, 0
t753: dq 0xFE1E34ADEC732385
    dw 0x4003, 0, 0, 0
t754: dq 0x96D7136616CB112E
    dw 0x400B, 0, 0, 0
t755: dq 0x8000000000000000
    dw 0x7FFF, 0, 0, 0
t756: dq 0x8000000000000000
    dw 0x7FFF, 0, 0, 0
t757: dq 0x9CEDA42B04FA1069
    dw 0xBFE6, 0, 0, 0
t758: dq 0x8000000000000000
    dw 0x7FFF, 0, 0, 0
t759: dq 0xD57A98001E25B6B8
    dw 0xBFD7, 0, 0, 0
t760: dq 0x0
    dw 0x0, 0, 0, 0
t761: dq 0x0
    dw 0x0, 0, 0, 0
t762: dq 0x8000000000000000
    dw 0xFFFF, 0, 0, 0
t763: dq 0xBE5F0F1AD84584B8
    dw 0x3FDC, 0, 0, 0
t764: dq 0x0
    dw 0x0, 0, 0, 0
t765: dq 0x0
    dw 0x8000, 0, 0, 0
t766: dq 0x8000000000000000
    dw 0xFFFF, 0, 0, 0
t767: dq 0x8000000000000000
    dw 0x7FFF, 0, 0, 0
t768: dq 0x0
    dw 0x0, 0, 0, 0
t769: dq 0x8FEBB9452F614DC4
    dw 0xC012, 0, 0, 0
t770: dq 0xEF8BFE9922D0E353
    dw 0xBFEC, 0, 0, 0
t771: dq 0x8000000000000000
    dw 0xFFFF, 0, 0, 0
t772: dq 0x98EF7D98B5F3D2A7
    dw 0x3FD9, 0, 0, 0
t773: dq 0x0
    dw 0x8000, 0, 0, 0
t774: dq 0xFB004643D7349D8A
    dw 0xBFDB, 0, 0, 0
t775: dq 0x8A93F67E91F239C5
    dw 0xC017, 0, 0, 0
t776: dq 0x8A941FD6A468BDDE
    dw 0x4006, 0, 0, 0
t777: dq 0x8000000000000000
    dw 0x7FFF, 0, 0, 0
t778: dq 0xD1D6EA99261B313A
    dw 0xC003, 0, 0, 0
t779: dq 0xE069DCA059548E47
    dw 0x4007, 0, 0, 0
t780: dq 0x8000000000000000
    dw 0xFFFF, 0, 0, 0
t781: dq 0xFB79722352B7270D
    dw 0x3FF2, 0, 0, 0
t782: dq 0x0
    dw 0x0, 0, 0, 0
t783: dq 0x0
    dw 0x0, 0, 0, 0
t784: dq 0xA4330495D9F4D6A5
    dw 0xBFE7, 0, 0, 0
t785: dq 0x0
    dw 0x0, 0, 0, 0
t786: dq 0xA4450942C2C61E86
    dw 0x3FF5, 0, 0, 0
t787: dq 0x0
    dw 0x0, 0, 0, 0
t788: dq 0x8000000000000000
    dw 0x7FFF, 0, 0, 0
t789: dq 0x8000000000000000
    dw 0xFFFF, 0, 0, 0
t790: dq 0xFE718B78B73A5066
    dw 0xBFDB, 0, 0, 0
t791: dq 0xE2D483E531C7F79C
    dw 0xBFE6, 0, 0, 0
t792: dq 0xE9237EB1E57A4C07
    dw 0x3FF2, 0, 0, 0
t793: dq 0x0
    dw 0x8000, 0, 0, 0
t794: dq 0x0
    dw 0x8000, 0, 0, 0
t795: dq 0xE874EEA00DA2F909
    dw 0x3FDC, 0, 0, 0
t796: dq 0xC98AE4F4A678B109
    dw 0x3FE1, 0, 0, 0
t797: dq 0x892272AE34860BC9
    dw 0x3FF7, 0, 0, 0
t798: dq 0xE131F57ABBA1B120
    dw 0xBFF6, 0, 0, 0
t799: dq 0xEE78F9A34FC523F4
    dw 0xC006, 0, 0, 0
t800: dq 0xAD3524A3C008BF6F
    dw 0x401A, 0, 0, 0
t801: dq 0xE0016B84DFF952AD
    dw 0xBFE4, 0, 0, 0
t802: dq 0xFF00000000000000
    dw 0xC005, 0, 0, 0
t803: dq 0xFF00000000000000
    dw 0xC005, 0, 0, 0
t804: dq 0x8000000000000000
    dw 0xBFFF, 0, 0, 0
t805: dq 0x0
    dw 0x0, 0, 0, 0
t806: dq 0x83BD30D8747428F6
    dw 0xC005, 0, 0, 0
t807: dq 0xAA5F57FED94EBC93
    dw 0x401D, 0, 0, 0
t808: dq 0xA000000000000000
    dw 0xC006, 0, 0, 0
t809: dq 0x986E0500F01FAC71
    dw 0x3FDB, 0, 0, 0
t810: dq 0xFE81E37DC82B0012
    dw 0x3FDB, 0, 0, 0
t811: dq 0xFB3B7944F10C1A58
    dw 0x3FF6, 0, 0, 0
t812: dq 0x8000000000000000
    dw 0xFFFF, 0, 0, 0
t813: dq 0xED1CD7D45289D063
    dw 0x4002, 0, 0, 0
t814: dq 0x0
    dw 0x0, 0, 0, 0
t815: dq 0x0
    dw 0x0, 0, 0, 0
t816: dq 0xFA9085F7CFCC7900
    dw 0xBFDB, 0, 0, 0
t817: dq 0xFA9085F7CFCC7900
    dw 0xBFDB, 0, 0, 0
t818: dq 0xF04DDB4DEF074CA4
    dw 0xC01A, 0, 0, 0
t819: dq 0xFA00000000000000
    dw 0x4008, 0, 0, 0
t820: dq 0x95417324BC01C19A
    dw 0x3FDA, 0, 0, 0
t821: dq 0xEF5665CBAAF60200
    dw 0x4008, 0, 0, 0
t822: dq 0xDB8441300FE5E1D5
    dw 0x4015, 0, 0, 0
t823: dq 0x8BC21A8A6C174A7F
    dw 0x401A, 0, 0, 0
t824: dq 0xEF4592818B16F68D
    dw 0x3FEC, 0, 0, 0
t825: dq 0xEF4592818B16F68D
    dw 0x3FEC, 0, 0, 0
t826: dq 0x849E49A6CEA3911E
    dw 0xC021, 0, 0, 0
t827: dq 0xFFFFFFFE00000000
    dw 0xC01D, 0, 0, 0
t828: dq 0xC6FF5F8539F6A745
    dw 0xC005, 0, 0, 0
t829: dq 0xA3B8DC4CF307806F
    dw 0x3FD8, 0, 0, 0
t830: dq 0x82FE088F8ED6E93F
    dw 0xC003, 0, 0, 0
t831: dq 0x8000000000000000
    dw 0x7FFF, 0, 0, 0
t832: dq 0xED583B8E9FCB8F02
    dw 0xBFF9, 0, 0, 0
t833: dq 0xC000000000000000
    dw 0xBFFD, 0, 0, 0
t834: dq 0xF7D7668D59080D3E
    dw 0xBFDF, 0, 0, 0
t835: dq 0x0
    dw 0x8000, 0, 0, 0
t836: dq 0xA47722494EB9458F
    dw 0xBFED, 0, 0, 0
t837: dq 0x89A18617D08BA07C
    dw 0x3FEB, 0, 0, 0
t838: dq 0xBF7101B9900443D5
    dw 0xBFE0, 0, 0, 0
t839: dq 0xDA598C1DBE57EF28
    dw 0xBFFE, 0, 0, 0
t840: dq 0xC000000000000000
    dw 0x3FFF, 0, 0, 0
t841: dq 0xC000000000000000
    dw 0x3FFF, 0, 0, 0
t842: dq 0xE18C9BD0E2BE121D
    dw 0xBFDE, 0, 0, 0
t843: dq 0xC000000000000000
    dw 0xC005, 0, 0, 0
t844: dq 0xCB330C6826C5A9A0
    dw 0xC015, 0, 0, 0
t845: dq 0xCB330C6826C5A9A0
    dw 0xC015, 0, 0, 0
t846: dq 0x906116E1BD4FBEF3
    dw 0xBFEF, 0, 0, 0
t847: dq 0xB2EF97727B752B15
    dw 0x3FF6, 0, 0, 0
t848: dq 0x9B83B324F76C43BC
    dw 0x3FDF, 0, 0, 0
t849: dq 0xA000000000000000
    dw 0xC006, 0, 0, 0
t850: dq 0xABD808C5E96FEF3A
    dw 0x3FD8, 0, 0, 0
t851: dq 0xA000000000000000
    dw 0xC007, 0, 0, 0
t852: dq 0xFA00000000000000
    dw 0xC007, 0, 0, 0
t853: dq 0xF84547B634D38C64
    dw 0x3FEB, 0, 0, 0
t854: dq 0x9842E26B707166C3
    dw 0xBFFB, 0, 0, 0
t855: dq 0x8CAFCE48C08689B9
    dw 0x401F, 0, 0, 0
t856: dq 0xCE486B1353C76162
    dw 0xC01F, 0, 0, 0
t857: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t858: dq 0xFF00000000000000
    dw 0x400B, 0, 0, 0
t859: dq 0x8230B4186582CA2E
    dw 0xC00D, 0, 0, 0
t860: dq 0xBE1FBA269FE1E26C
    dw 0xBFDD, 0, 0, 0
t861: dq 0x8000800000000000
    dw 0xC00F, 0, 0, 0
t862: dq 0x8492A7D140907458
    dw 0x3FE7, 0, 0, 0
t863: dq 0xCAA84BE46C8D9ED6
    dw 0xC025, 0, 0, 0
t864: dq 0xB11A2EF07CADD2DE
    dw 0xC014, 0, 0, 0
t865: dq 0xF310AAE2EAC89F12
    dw 0x400F, 0, 0, 0
t866: dq 0xB66AE816FF2F290C
    dw 0x3FE6, 0, 0, 0
t867: dq 0xFEEE325A9F91CCEF
    dw 0xBFDC, 0, 0, 0
t868: dq 0x94787F7C5B216DCD
    dw 0x400E, 0, 0, 0
t869: dq 0xE000000000000000
    dw 0xC001, 0, 0, 0
t870: dq 0xA000000000000000
    dw 0x4007, 0, 0, 0
t871: dq 0xC1F80E24B2DEE8D8
    dw 0xC019, 0, 0, 0
t872: dq 0xFF00000000000000
    dw 0x4005, 0, 0, 0
t873: dq 0xC000000000000000
    dw 0xC000, 0, 0, 0
t874: dq 0xFF00000000000000
    dw 0xC003, 0, 0, 0
t875: dq 0x9D704021FC1B2CDE
    dw 0xBFE8, 0, 0, 0
t876: dq 0xA000000000000000
    dw 0xC001, 0, 0, 0
t877: dq 0x9AA43B59E1CC2E23
    dw 0x3FDA, 0, 0, 0
t878: dq 0xC000000000000000
    dw 0x4005, 0, 0, 0
t879: dq 0xAA9E6548C1E78F46
    dw 0x3FEB, 0, 0, 0
t880: dq 0x9AEAED7A5123BFCB
    dw 0xC006, 0, 0, 0
t881: dq 0xC9AA7891A2663432
    dw 0xC022, 0, 0, 0
t882: dq 0xEB33805119502E85
    dw 0xBFEC, 0, 0, 0
t883: dq 0xF2FD7840577323E5
    dw 0xC014, 0, 0, 0
t884: dq 0xBA089CB80DD54A9C
    dw 0xC011, 0, 0, 0
t885: dq 0xA4F2722B484AFFE2
    dw 0x4004, 0, 0, 0
t886: dq 0xF4C5B1CF8B9B62E1
    dw 0x401A, 0, 0, 0
t887: dq 0xB2D0C0C5ACC9F45A
    dw 0xBFF3, 0, 0, 0
t888: dq 0x8000000000000000
    dw 0x3FFF, 0, 0, 0
t889: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t890: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t891: dq 0xBD66FB0BF0CBE06A
    dw 0xBFF2, 0, 0, 0
t892: dq 0xEEA53FB71FB204D3
    dw 0x3FED, 0, 0, 0
t893: dq 0xFFFFFFFE00000000
    dw 0xC01A, 0, 0, 0
t894: dq 0x8000000100000000
    dw 0xC01B, 0, 0, 0
t895: dq 0xC040CC26718ABD28
    dw 0xC010, 0, 0, 0
t896: dq 0xE000000000000000
    dw 0xC006, 0, 0, 0
t897: dq 0xEB592A95C0B7AC53
    dw 0xBFE5, 0, 0, 0
t898: dq 0x8EE4030501B91F27
    dw 0x4015, 0, 0, 0
t899: dq 0xA45C6596F82D820B
    dw 0x4018, 0, 0, 0
t900: dq 0xE000000000000000
    dw 0xBFFE, 0, 0, 0
t901: dq 0xB3BFE9D6CDE9B04F
    dw 0xC025, 0, 0, 0
t902: dq 0xA9B1DB23488775BA
    dw 0xC018, 0, 0, 0
t903: dq 0x8802A8A4A72A7C1A
    dw 0xC01A, 0, 0, 0
t904: dq 0x8000800000000000
    dw 0x4014, 0, 0, 0
t905: dq 0xFA00000000000000
    dw 0x400D, 0, 0, 0
t906: dq 0xD7956735E641D68B
    dw 0x3FED, 0, 0, 0
t907: dq 0xC000000000000000
    dw 0xC000, 0, 0, 0
t908: dq 0x814A063B3D65DAB6
    dw 0x3FF6, 0, 0, 0
t909: dq 0xD3637F37D3BC80E3
    dw 0x4023, 0, 0, 0
t910: dq 0xB7750252543FBB20
    dw 0x4002, 0, 0, 0
t911: dq 0xC000000000000000
    dw 0x4000, 0, 0, 0
t912: dq 0x8000000100000000
    dw 0xC023, 0, 0, 0
t913: dq 0xE49BCD103B4276DD
    dw 0x400A, 0, 0, 0
t914: dq 0xE4758BE13D4E5B69
    dw 0x3FFC, 0, 0, 0
t915: dq 0xAC5ACEF7C32761C3
    dw 0xBFFF, 0, 0, 0
t916: dq 0x9AC71476460CF33C
    dw 0x3FE5, 0, 0, 0
t917: dq 0xFFFFFFFE00000000
    dw 0x401C, 0, 0, 0
t918: dq 0xBF1B67FAAD54FAAA
    dw 0xC012, 0, 0, 0
t919: dq 0xDF7415D75636B764
    dw 0xBFE4, 0, 0, 0
t920: dq 0xC000000000000000
    dw 0xC000, 0, 0, 0
t921: dq 0xAA9C50FC287C6598
    dw 0x3FFA, 0, 0, 0
t922: dq 0x8000000000000000
    dw 0xBFFC, 0, 0, 0
t923: dq 0xA000000000000000
    dw 0x3FFE, 0, 0, 0
t924: dq 0xC12C0158F48417BD
    dw 0xBFE9, 0, 0, 0
t925: dq 0xB47C3F5847BA95B7
    dw 0xC008, 0, 0, 0
t926: dq 0xD9E2E841E4C30521
    dw 0xC009, 0, 0, 0
t927: dq 0xC828FEEFF1E64417
    dw 0x3FE6, 0, 0, 0
t928: dq 0xBC5EAB26B1AD1118
    dw 0x4000, 0, 0, 0
t929: dq 0xC7269B3259DB1382
    dw 0x3FFC, 0, 0, 0
t930: dq 0x81EF09BE05F17DF6
    dw 0xBFEA, 0, 0, 0
t931: dq 0xB905CD04D2EF0834
    dw 0xBFDA, 0, 0, 0
t932: dq 0xF13A2A189E048EEE
    dw 0xC011, 0, 0, 0
t933: dq 0x8000800000000000
    dw 0xC00E, 0, 0, 0
t934: dq 0xA986CCDE4E12DC32
    dw 0x400D, 0, 0, 0
t935: dq 0xE203BEB2AC9729C9
    dw 0xC000, 0, 0, 0
t936: dq 0x9FA101199701775B
    dw 0x4023, 0, 0, 0
t937: dq 0x8000000000000000
    dw 0x3FFF, 0, 0, 0
t938: dq 0xA000000000000000
    dw 0x4007, 0, 0, 0
t939: dq 0xE8BED177FB902EA5
    dw 0x4025, 0, 0, 0
t940: dq 0xAF52E44190418079
    dw 0xC016, 0, 0, 0
t941: dq 0xFF00000000000000
    dw 0x4006, 0, 0, 0
t942: dq 0xFFFFFFFE00000000
    dw 0xC022, 0, 0, 0
t943: dq 0x9B5CDB186E1A40BB
    dw 0x400B, 0, 0, 0
t944: dq 0x9138055C6C6F4F42
    dw 0xC010, 0, 0, 0
t945: dq 0xFF2D677983967D07
    dw 0xBFFE, 0, 0, 0
t946: dq 0xE000000000000000
    dw 0xC000, 0, 0, 0
t947: dq 0x952EA2BFC0918E2F
    dw 0x3FE7, 0, 0, 0
t948: dq 0xB759B713D7E3A1A9
    dw 0xBFE5, 0, 0, 0
t949: dq 0xC0B7823437E98F65
    dw 0xBFE0, 0, 0, 0
t950: dq 0xC8DCD250D1FB6184
    dw 0x401F, 0, 0, 0
t951: dq 0x8DC487A0F0ACAB31
    dw 0xBFD7, 0, 0, 0
t952: dq 0x9DBA9DA06AA623A0
    dw 0x400E, 0, 0, 0
t953: dq 0xEE8D9C222C279317
    dw 0xC015, 0, 0, 0
t954: dq 0xE2A85F9AAF88DC5B
    dw 0x4002, 0, 0, 0
t955: dq 0xEEB797CADC0C654D
    dw 0x4001, 0, 0, 0
t956: dq 0xA410C723D1CB681D
    dw 0xC022, 0, 0, 0
t957: dq 0xA000000000000000
    dw 0xC000, 0, 0, 0
t958: dq 0x8B2A6678AA178C41
    dw 0xBFE0, 0, 0, 0
t959: dq 0xF756E814AB997BF5
    dw 0x3FDD, 0, 0, 0
t960: dq 0xFFFFFFFE00000000
    dw 0xC01D, 0, 0, 0
t961: dq 0xBED38C2049B33E3E
    dw 0x3FE1, 0, 0, 0
t962: dq 0xD1538A780D819419
    dw 0x3FEE, 0, 0, 0
t963: dq 0xE4C7DE60E4A443BA
    dw 0x4003, 0, 0, 0
t964: dq 0x8000800000000000
    dw 0x400F, 0, 0, 0
t965: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t966: dq 0x82E3B40ED6522C95
    dw 0x400D, 0, 0, 0
t967: dq 0xFFFFFFFE00000000
    dw 0x401D, 0, 0, 0
t968: dq 0xA000000000000000
    dw 0x3FFF, 0, 0, 0
t969: dq 0xC36458002A18CE4C
    dw 0x4016, 0, 0, 0
t970: dq 0xC87C1B9563D665DD
    dw 0x4003, 0, 0, 0
t971: dq 0xFA00000000000000
    dw 0x4005, 0, 0, 0
t972: dq 0xF2A54C2453321636
    dw 0x4009, 0, 0, 0
t973: dq 0xF1756D7BA4C06E7A
    dw 0x3FF0, 0, 0, 0
t974: dq 0xC6115FDE2499FA7E
    dw 0x3FF4, 0, 0, 0
t975: dq 0xCAA94A1C72294093
    dw 0x4005, 0, 0, 0
t976: dq 0x8000800000000000
    dw 0xC00E, 0, 0, 0
t977: dq 0xB1214A6E8B08D24C
    dw 0x3FE6, 0, 0, 0
t978: dq 0x8000000000000000
    dw 0x3FFC, 0, 0, 0
t979: dq 0xF8C45F7F7EFEEA5F
    dw 0xBFF0, 0, 0, 0
t980: dq 0xA950F715C9165106
    dw 0x3FFF, 0, 0, 0
t981: dq 0xFDF58C1D1DEC1765
    dw 0xC01B, 0, 0, 0
t982: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t983: dq 0xF6A595ACA8696B9D
    dw 0xBFE4, 0, 0, 0
t984: dq 0xE19E4F4861561372
    dw 0xBFE3, 0, 0, 0
t985: dq 0xBA61584D6264E89A
    dw 0x4003, 0, 0, 0
t986: dq 0xFB769885094A1C38
    dw 0xC00E, 0, 0, 0
t987: dq 0x888A5587EA7E7F88
    dw 0xC025, 0, 0, 0
t988: dq 0xC000000000000000
    dw 0x4002, 0, 0, 0
t989: dq 0x89A9901FD5A0559A
    dw 0xBFDB, 0, 0, 0
t990: dq 0x8F6CEECD63C854F3
    dw 0xBFDC, 0, 0, 0
t991: dq 0xF931496934C8D337
    dw 0x3FF1, 0, 0, 0
t992: dq 0xD508955F6F549B66
    dw 0x400D, 0, 0, 0
t993: dq 0x9827686DB7C674E7
    dw 0x3FDF, 0, 0, 0
t994: dq 0x8000000000000000
    dw 0x4002, 0, 0, 0
t995: dq 0xA7D11AA78147FD99
    dw 0xBFE5, 0, 0, 0
t996: dq 0xADE0D9B2C6DDD29E
    dw 0x3FF9, 0, 0, 0
t997: dq 0x8000000000000000
    dw 0xBFFF, 0, 0, 0
t998: dq 0x897A9CC6BB574947
    dw 0xBFE7, 0, 0, 0
t999: dq 0x9A9183FE773BC00A
    dw 0x4022, 0, 0, 0
t1000: dq 0xE000000000000000
    dw 0xC002, 0, 0, 0
t1001: dq 0x8000800000000000
    dw 0xC00F, 0, 0, 0
t1002: dq 0xA746890A8476113F
    dw 0xC023, 0, 0, 0
t1003: dq 0xAB2B1A8E73B95C2D
    dw 0xC01F, 0, 0, 0
t1004: dq 0xA874D1B6C7DEBBDF
    dw 0xBFD9, 0, 0, 0
t1005: dq 0xA000000000000000
    dw 0x4001, 0, 0, 0
t1006: dq 0x8000000000000000
    dw 0x4002, 0, 0, 0
t1007: dq 0xFAD0A1329419B278
    dw 0x3FF3, 0, 0, 0
t1008: dq 0xC9D72762850EE292
    dw 0x401A, 0, 0, 0
t1009: dq 0xEEC85294938D8C0F
    dw 0xBFF7, 0, 0, 0
t1010: dq 0x8AF2C2C19367A65C
    dw 0x401E, 0, 0, 0
t1011: dq 0xFA00000000000000
    dw 0xC007, 0, 0, 0
t1012: dq 0xC000000000000000
    dw 0x4002, 0, 0, 0
t1013: dq 0xC14E6CFE0DDB0D9B
    dw 0x4006, 0, 0, 0
t1014: dq 0x8F51E70330D50798
    dw 0x400A, 0, 0, 0
t1015: dq 0xC000000000000000
    dw 0x3FFF, 0, 0, 0
t1016: dq 0xFF00000000000000
    dw 0xC003, 0, 0, 0
t1017: dq 0xE000000000000000
    dw 0x3FFE, 0, 0, 0
t1018: dq 0xE000000000000000
    dw 0x4002, 0, 0, 0
t1019: dq 0x8B715895F1F7AB51
    dw 0xBFEA, 0, 0, 0
t1020: dq 0xA000000000000000
    dw 0xBFFE, 0, 0, 0
t1021: dq 0xB936209C23C484BB
    dw 0x3FED, 0, 0, 0
t1022: dq 0xC1767A748E62AEAD
    dw 0xC00E, 0, 0, 0
t1023: dq 0x9777F77F5351CF59
    dw 0xC002, 0, 0, 0
t1024: dq 0xE000000000000000
    dw 0xC002, 0, 0, 0
t1025: dq 0xA019CD325F6DA120
    dw 0xC019, 0, 0, 0
t1026: dq 0x9756B89C981C9DCF
    dw 0x3FE7, 0, 0, 0
t1027: dq 0xA000000000000000
    dw 0x4002, 0, 0, 0
t1028: dq 0xA42FF60DDE7BC321
    dw 0x4013, 0, 0, 0
t1029: dq 0x8000000000000000
    dw 0x3FFF, 0, 0, 0
t1030: dq 0xC000000000000000
    dw 0x4002, 0, 0, 0
t1031: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t1032: dq 0x878D7D2117A49038
    dw 0x3FE3, 0, 0, 0
t1033: dq 0xD29683A061068FDE
    dw 0xBFF2, 0, 0, 0
t1034: dq 0xA000000000000000
    dw 0x4007, 0, 0, 0
t1035: dq 0xFA00000000000000
    dw 0x4005, 0, 0, 0
t1036: dq 0xFF00000000000000
    dw 0xC003, 0, 0, 0
t1037: dq 0xA98E0AACC8686A1E
    dw 0x3FF0, 0, 0, 0
t1038: dq 0xC000000000000000
    dw 0x4005, 0, 0, 0
t1039: dq 0xFF00000000000000
    dw 0x400B, 0, 0, 0
t1040: dq 0x82DE69E1E6F3B296
    dw 0xC012, 0, 0, 0
t1041: dq 0xEEBB90173C170F6C
    dw 0xBFF4, 0, 0, 0
t1042: dq 0xC000000000000000
    dw 0xC005, 0, 0, 0
t1043: dq 0x0
    dw 0x0, 0, 0, 0
t1044: dq 0x8000000000000000
    dw 0x7FFF, 0, 0, 0
t1045: dq 0x8000018000000000
    dw 0x3FFF, 0, 0, 0
t1046: dq 0x8000008000000000
    dw 0xBFFF, 0, 0, 0
t1047: dq 0x8000000000000C00
    dw 0x4005, 0, 0, 0
t1048: dq 0x8000000000000400
    dw 0xC005, 0, 0, 0
t1049: dq 0xFFFFFFFFFFFFFFFF
    dw 0x3FFF, 0, 0, 0
t1050: dq 0xFFFFFFFFFFFFFFFF
    dw 0xC07E, 0, 0, 0
t1051: dq 0x8000000000000001
    dw 0x7000, 0, 0, 0
t1052: dq 0x8000000000000001
    dw 0xF000, 0, 0, 0
t1053: dq 0x8000000000003039
    dw 0x3BEF, 0, 0, 0
t1054: dq 0x8000000000003039
    dw 0xBF73, 0, 0, 0
t1055: dq 0x8000000000000000
    dw 0x3BCC, 0, 0, 0
t1056: dq 0x8000000000000000
    dw 0x100, 0, 0, 0
t1057: dq 0x8000000000000001
    dw 0x8100, 0, 0, 0
t1058: dq 0xA000000000000000
    dw 0x7FFF, 0, 0, 0
t1059: dq 0xC000000012345000
    dw 0xFFFF, 0, 0, 0
t1060: dq 0xE000000000000000
    dw 0x407E, 0, 0, 0
t1061: dq 0xE000000000000000
    dw 0x43FE, 0, 0, 0
t1062: dq 0x8000018000000000
    dw 0x3FFF, 0, 0, 0
t1063: dq 0x8000008000000000
    dw 0xBFFF, 0, 0, 0
t1064: dq 0x8000000000000C00
    dw 0x4005, 0, 0, 0
t1065: dq 0x8000000000000400
    dw 0xC005, 0, 0, 0
t1066: dq 0xFFFFFFFFFFFFFFFF
    dw 0x3FFF, 0, 0, 0
t1067: dq 0xFFFFFFFFFFFFFFFF
    dw 0xC07E, 0, 0, 0
t1068: dq 0x8000000000000001
    dw 0x7000, 0, 0, 0
t1069: dq 0x8000000000000001
    dw 0xF000, 0, 0, 0
t1070: dq 0x8000000000003039
    dw 0x3BEF, 0, 0, 0
t1071: dq 0x8000000000003039
    dw 0xBF73, 0, 0, 0
t1072: dq 0x8000000000000000
    dw 0x3BCC, 0, 0, 0
t1073: dq 0x8000000000000000
    dw 0x100, 0, 0, 0
t1074: dq 0x8000000000000001
    dw 0x8100, 0, 0, 0
t1075: dq 0xA000000000000000
    dw 0x7FFF, 0, 0, 0
t1076: dq 0xC000000012345000
    dw 0xFFFF, 0, 0, 0
t1077: dq 0xE000000000000000
    dw 0x407E, 0, 0, 0
t1078: dq 0xE000000000000000
    dw 0x43FE, 0, 0, 0
t1079: dq 0x8000018000000000
    dw 0x3FFF, 0, 0, 0
t1080: dq 0x8000008000000000
    dw 0xBFFF, 0, 0, 0
t1081: dq 0x8000000000000C00
    dw 0x4005, 0, 0, 0
t1082: dq 0x8000000000000400
    dw 0xC005, 0, 0, 0
t1083: dq 0xFFFFFFFFFFFFFFFF
    dw 0x3FFF, 0, 0, 0
t1084: dq 0xFFFFFFFFFFFFFFFF
    dw 0xC07E, 0, 0, 0
t1085: dq 0x8000000000000001
    dw 0x7000, 0, 0, 0
t1086: dq 0x8000000000000001
    dw 0xF000, 0, 0, 0
t1087: dq 0x8000000000003039
    dw 0x3BEF, 0, 0, 0
t1088: dq 0x8000000000003039
    dw 0xBF73, 0, 0, 0
t1089: dq 0x8000000000000000
    dw 0x3BCC, 0, 0, 0
t1090: dq 0x8000000000000000
    dw 0x100, 0, 0, 0
t1091: dq 0x8000000000000001
    dw 0x8100, 0, 0, 0
t1092: dq 0xA000000000000000
    dw 0x7FFF, 0, 0, 0
t1093: dq 0xC000000012345000
    dw 0xFFFF, 0, 0, 0
t1094: dq 0xE000000000000000
    dw 0x407E, 0, 0, 0
t1095: dq 0xE000000000000000
    dw 0x43FE, 0, 0, 0
t1096: dq 0x8000018000000000
    dw 0x3FFF, 0, 0, 0
t1097: dq 0x8000008000000000
    dw 0xBFFF, 0, 0, 0
t1098: dq 0x8000000000000C00
    dw 0x4005, 0, 0, 0
t1099: dq 0x8000000000000400
    dw 0xC005, 0, 0, 0
t1100: dq 0xFFFFFFFFFFFFFFFF
    dw 0x3FFF, 0, 0, 0
t1101: dq 0xFFFFFFFFFFFFFFFF
    dw 0xC07E, 0, 0, 0
t1102: dq 0x8000000000000001
    dw 0x7000, 0, 0, 0
t1103: dq 0x8000000000000001
    dw 0xF000, 0, 0, 0
t1104: dq 0x8000000000003039
    dw 0x3BEF, 0, 0, 0
t1105: dq 0x8000000000003039
    dw 0xBF73, 0, 0, 0
t1106: dq 0x8000000000000000
    dw 0x3BCC, 0, 0, 0
t1107: dq 0x8000000000000000
    dw 0x100, 0, 0, 0
t1108: dq 0x8000000000000001
    dw 0x8100, 0, 0, 0
t1109: dq 0xA000000000000000
    dw 0x7FFF, 0, 0, 0
t1110: dq 0xC000000012345000
    dw 0xFFFF, 0, 0, 0
t1111: dq 0xE000000000000000
    dw 0x407E, 0, 0, 0
t1112: dq 0xE000000000000000
    dw 0x43FE, 0, 0, 0
t1113: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t1114: dq 0xDEADBEEF12345000
    dw 0x4078, 0, 0, 0
t1115: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t1116: dq 0xDEADBEEF12345000
    dw 0x4078, 0, 0, 0
t1117: dq 0xFFFF000000000000
    dw 0x400E, 0, 0, 0
t1118: dq 0x91A2B3C4D5E6F780
    dw 0x409B, 0, 0, 0
t1119: dq 0xFFFF000000000000
    dw 0x400E, 0, 0, 0
t1120: dq 0x91A2B3C4D5E6F780
    dw 0x409B, 0, 0, 0
t1121: dq 0xA000000000000000
    dw 0x4001, 0, 0, 0
t1122: dq 0xC000000000000000
    dw 0x4040, 0, 0, 0
t1123: dq 0xA000000000000000
    dw 0x4001, 0, 0, 0
t1124: dq 0xC000000000000000
    dw 0x4040, 0, 0, 0
t1125: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t1126: dq 0xA000000000000000
    dw 0x4001, 0, 0, 0
t1127: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t1128: dq 0xA000000000000000
    dw 0xC001, 0, 0, 0
t1129: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t1130: dq 0xE000000000000000
    dw 0x4001, 0, 0, 0
t1131: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t1132: dq 0xE000000000000000
    dw 0xC001, 0, 0, 0
t1133: dq 0x8000000000000000
    dw 0x4001, 0, 0, 0
t1134: dq 0xC000000000000000
    dw 0x4000, 0, 0, 0
t1135: dq 0x8000000000000000
    dw 0x4001, 0, 0, 0
t1136: dq 0xC000000000000000
    dw 0xC000, 0, 0, 0
t1137: dq 0x8000000000000000
    dw 0x4002, 0, 0, 0
t1138: dq 0xA000000000000000
    dw 0x4001, 0, 0, 0
t1139: dq 0x8000000000000000
    dw 0x4002, 0, 0, 0
t1140: dq 0xA000000000000000
    dw 0xC001, 0, 0, 0
t1141: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t1142: dq 0x8000000000000000
    dw 0x3FFF, 0, 0, 0
t1143: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t1144: dq 0x8000000000000000
    dw 0xBFFF, 0, 0, 0
t1145: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t1146: dq 0xC000000000000000
    dw 0x4000, 0, 0, 0
t1147: dq 0x8000000000000000
    dw 0x4000, 0, 0, 0
t1148: dq 0xC000000000000000
    dw 0xC000, 0, 0, 0
t1149: dq 0x8000000000000000
    dw 0x4001, 0, 0, 0
t1150: dq 0x8000000000000000
    dw 0x3FFF, 0, 0, 0
t1151: dq 0x8000000000000000
    dw 0x4001, 0, 0, 0
t1152: dq 0x8000000000000000
    dw 0xBFFF, 0, 0, 0
t1153: dq 0x8000000000000000
    dw 0x4001, 0, 0, 0
t1154: dq 0x9000000000000000
    dw 0x4002, 0, 0, 0
t1155: dq 0x8000000000000000
    dw 0x4001, 0, 0, 0
t1156: dq 0x9000000000000000
    dw 0xC002, 0, 0, 0
t1157: dq 0x8000000000000000
    dw 0x4001, 0, 0, 0
t1158: dq 0xB000000000000000
    dw 0x4002, 0, 0, 0
t1159: dq 0x8000000000000000
    dw 0x4001, 0, 0, 0
t1160: dq 0xB000000000000000
    dw 0xC002, 0, 0, 0
t1161: dq 0xE85ADA0F26A9173C
    dw 0xC005, 0, 0, 0
t1162: dq 0xF9341EDA550CF656
    dw 0x4004, 0, 0, 0
t1163: dq 0xABCDEF0123456789
    dw 0x4001, 0, 0, 0
t1164: dq 0xFA00000000000000
    dw 0x4008, 0, 0, 0
buf: times 64 dq 0x0123456789ABCDEF
area: times 80 dq 0x1111111111111111
file_end:
