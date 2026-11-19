; The sixteen conditions in Jcc (both lengths), SETcc and CMOVcc, under a dozen settings of the flags.
; Written by tools/gen64_tests.py: change that, not this.
%include "elf.inc"
    mov rbx, 0x158D37884B89A131
    mov rsi, 0x8B02DBB5954DD9A6
    mov r9, 0xA67E484A00B33F15
    FLAGS 0x202
    seto dl
    cmovo rax, rbx
    cmovo r9d, esi
    cmovo r10w, si
    jo short .s1
    inc r12
.s1:
    jo near .n1
    inc r13
.n1:
    FLAGS 0x202
    setno dl
    cmovno rax, rbx
    cmovno r9d, esi
    cmovno r10w, si
    jno short .s2
    inc r12
.s2:
    jno near .n2
    inc r13
.n2:
    FLAGS 0x202
    setb dl
    cmovb rax, rbx
    cmovb r9d, esi
    cmovb r10w, si
    jb short .s3
    inc r12
.s3:
    jb near .n3
    inc r13
.n3:
    FLAGS 0x202
    setae dl
    cmovae rax, rbx
    cmovae r9d, esi
    cmovae r10w, si
    jae short .s4
    inc r12
.s4:
    jae near .n4
    inc r13
.n4:
    mov r9, 0xDE1B98AC0234A863
    FLAGS 0x202
    sete dl
    cmove rax, rbx
    cmove r9d, esi
    cmove r10w, si
    je short .s5
    inc r12
.s5:
    je near .n5
    inc r13
.n5:
    FLAGS 0x202
    setne dl
    cmovne rax, rbx
    cmovne r9d, esi
    cmovne r10w, si
    jne short .s6
    inc r12
.s6:
    jne near .n6
    inc r13
.n6:
    FLAGS 0x202
    setbe dl
    cmovbe rax, rbx
    cmovbe r9d, esi
    cmovbe r10w, si
    jbe short .s7
    inc r12
.s7:
    jbe near .n7
    inc r13
.n7:
    FLAGS 0x202
    seta dl
    cmova rax, rbx
    cmova r9d, esi
    cmova r10w, si
    ja short .s8
    inc r12
.s8:
    ja near .n8
    inc r13
.n8:
    mov r9, 0xA53E357CD70EE357
    FLAGS 0x202
    sets dl
    cmovs rax, rbx
    cmovs r9d, esi
    cmovs r10w, si
    js short .s9
    inc r12
.s9:
    js near .n9
    inc r13
.n9:
    FLAGS 0x202
    setns dl
    cmovns rax, rbx
    cmovns r9d, esi
    cmovns r10w, si
    jns short .s10
    inc r12
.s10:
    jns near .n10
    inc r13
.n10:
    FLAGS 0x202
    setp dl
    cmovp rax, rbx
    cmovp r9d, esi
    cmovp r10w, si
    jp short .s11
    inc r12
.s11:
    jp near .n11
    inc r13
.n11:
    FLAGS 0x202
    setnp dl
    cmovnp rax, rbx
    cmovnp r9d, esi
    cmovnp r10w, si
    jnp short .s12
    inc r12
.s12:
    jnp near .n12
    inc r13
.n12:
    mov r9, 0x8AE5FFC630E2F725
    FLAGS 0x202
    setl dl
    cmovl rax, rbx
    cmovl r9d, esi
    cmovl r10w, si
    jl short .s13
    inc r12
.s13:
    jl near .n13
    inc r13
.n13:
    FLAGS 0x202
    setge dl
    cmovge rax, rbx
    cmovge r9d, esi
    cmovge r10w, si
    jge short .s14
    inc r12
.s14:
    jge near .n14
    inc r13
.n14:
    FLAGS 0x202
    setle dl
    cmovle rax, rbx
    cmovle r9d, esi
    cmovle r10w, si
    jle short .s15
    inc r12
.s15:
    jle near .n15
    inc r13
.n15:
    FLAGS 0x202
    setg dl
    cmovg rax, rbx
    cmovg r9d, esi
    cmovg r10w, si
    jg short .s16
    inc r12
.s16:
    jg near .n16
    inc r13
.n16:
    mov rbx, 0xD709622B9E908D1F
    mov rsi, 0x8000000000000000
    mov r9, 0xF4416064034847B6
    FLAGS 0x203
    seto dl
    cmovo rax, rbx
    cmovo r9d, esi
    cmovo r10w, si
    jo short .s17
    inc r12
.s17:
    jo near .n17
    inc r13
.n17:
    FLAGS 0x203
    setno dl
    cmovno rax, rbx
    cmovno r9d, esi
    cmovno r10w, si
    jno short .s18
    inc r12
.s18:
    jno near .n18
    inc r13
.n18:
    FLAGS 0x203
    setb dl
    cmovb rax, rbx
    cmovb r9d, esi
    cmovb r10w, si
    jb short .s19
    inc r12
.s19:
    jb near .n19
    inc r13
.n19:
    FLAGS 0x203
    setae dl
    cmovae rax, rbx
    cmovae r9d, esi
    cmovae r10w, si
    jae short .s20
    inc r12
.s20:
    jae near .n20
    inc r13
.n20:
    mov r9, 0xCA7407C3E4DDF905
    FLAGS 0x203
    sete dl
    cmove rax, rbx
    cmove r9d, esi
    cmove r10w, si
    je short .s21
    inc r12
.s21:
    je near .n21
    inc r13
.n21:
    FLAGS 0x203
    setne dl
    cmovne rax, rbx
    cmovne r9d, esi
    cmovne r10w, si
    jne short .s22
    inc r12
.s22:
    jne near .n22
    inc r13
.n22:
    FLAGS 0x203
    setbe dl
    cmovbe rax, rbx
    cmovbe r9d, esi
    cmovbe r10w, si
    jbe short .s23
    inc r12
.s23:
    jbe near .n23
    inc r13
.n23:
    FLAGS 0x203
    seta dl
    cmova rax, rbx
    cmova r9d, esi
    cmova r10w, si
    ja short .s24
    inc r12
.s24:
    ja near .n24
    inc r13
.n24:
    mov r9, 0xE214D783F71D2C3C
    FLAGS 0x203
    sets dl
    cmovs rax, rbx
    cmovs r9d, esi
    cmovs r10w, si
    js short .s25
    inc r12
.s25:
    js near .n25
    inc r13
.n25:
    FLAGS 0x203
    setns dl
    cmovns rax, rbx
    cmovns r9d, esi
    cmovns r10w, si
    jns short .s26
    inc r12
.s26:
    jns near .n26
    inc r13
.n26:
    FLAGS 0x203
    setp dl
    cmovp rax, rbx
    cmovp r9d, esi
    cmovp r10w, si
    jp short .s27
    inc r12
.s27:
    jp near .n27
    inc r13
.n27:
    FLAGS 0x203
    setnp dl
    cmovnp rax, rbx
    cmovnp r9d, esi
    cmovnp r10w, si
    jnp short .s28
    inc r12
.s28:
    jnp near .n28
    inc r13
.n28:
    mov r9, 0xE836BE7CEBA8CBA0
    FLAGS 0x203
    setl dl
    cmovl rax, rbx
    cmovl r9d, esi
    cmovl r10w, si
    jl short .s29
    inc r12
.s29:
    jl near .n29
    inc r13
.n29:
    FLAGS 0x203
    setge dl
    cmovge rax, rbx
    cmovge r9d, esi
    cmovge r10w, si
    jge short .s30
    inc r12
.s30:
    jge near .n30
    inc r13
.n30:
    FLAGS 0x203
    setle dl
    cmovle rax, rbx
    cmovle r9d, esi
    cmovle r10w, si
    jle short .s31
    inc r12
.s31:
    jle near .n31
    inc r13
.n31:
    FLAGS 0x203
    setg dl
    cmovg rax, rbx
    cmovg r9d, esi
    cmovg r10w, si
    jg short .s32
    inc r12
.s32:
    jg near .n32
    inc r13
.n32:
    mov rbx, 0x80000000
    mov rsi, 0xBF2BD70E2883C657
    mov r9, 0xD4136349C795A70C
    FLAGS 0xA02
    seto dl
    cmovo rax, rbx
    cmovo r9d, esi
    cmovo r10w, si
    jo short .s33
    inc r12
.s33:
    jo near .n33
    inc r13
.n33:
    FLAGS 0xA02
    setno dl
    cmovno rax, rbx
    cmovno r9d, esi
    cmovno r10w, si
    jno short .s34
    inc r12
.s34:
    jno near .n34
    inc r13
.n34:
    FLAGS 0xA02
    setb dl
    cmovb rax, rbx
    cmovb r9d, esi
    cmovb r10w, si
    jb short .s35
    inc r12
.s35:
    jb near .n35
    inc r13
.n35:
    FLAGS 0xA02
    setae dl
    cmovae rax, rbx
    cmovae r9d, esi
    cmovae r10w, si
    jae short .s36
    inc r12
.s36:
    jae near .n36
    inc r13
.n36:
    mov r9, 0xFDA82C416F7636C9
    FLAGS 0xA02
    sete dl
    cmove rax, rbx
    cmove r9d, esi
    cmove r10w, si
    je short .s37
    inc r12
.s37:
    je near .n37
    inc r13
.n37:
    FLAGS 0xA02
    setne dl
    cmovne rax, rbx
    cmovne r9d, esi
    cmovne r10w, si
    jne short .s38
    inc r12
.s38:
    jne near .n38
    inc r13
.n38:
    FLAGS 0xA02
    setbe dl
    cmovbe rax, rbx
    cmovbe r9d, esi
    cmovbe r10w, si
    jbe short .s39
    inc r12
.s39:
    jbe near .n39
    inc r13
.n39:
    FLAGS 0xA02
    seta dl
    cmova rax, rbx
    cmova r9d, esi
    cmova r10w, si
    ja short .s40
    inc r12
.s40:
    ja near .n40
    inc r13
.n40:
    mov r9, 0xCA2BDB671348EB1C
    FLAGS 0xA02
    sets dl
    cmovs rax, rbx
    cmovs r9d, esi
    cmovs r10w, si
    js short .s41
    inc r12
.s41:
    js near .n41
    inc r13
.n41:
    FLAGS 0xA02
    setns dl
    cmovns rax, rbx
    cmovns r9d, esi
    cmovns r10w, si
    jns short .s42
    inc r12
.s42:
    jns near .n42
    inc r13
.n42:
    FLAGS 0xA02
    setp dl
    cmovp rax, rbx
    cmovp r9d, esi
    cmovp r10w, si
    jp short .s43
    inc r12
.s43:
    jp near .n43
    inc r13
.n43:
    FLAGS 0xA02
    setnp dl
    cmovnp rax, rbx
    cmovnp r9d, esi
    cmovnp r10w, si
    jnp short .s44
    inc r12
.s44:
    jnp near .n44
    inc r13
.n44:
    mov r9, 0xC622F593C19857B5
    FLAGS 0xA02
    setl dl
    cmovl rax, rbx
    cmovl r9d, esi
    cmovl r10w, si
    jl short .s45
    inc r12
.s45:
    jl near .n45
    inc r13
.n45:
    FLAGS 0xA02
    setge dl
    cmovge rax, rbx
    cmovge r9d, esi
    cmovge r10w, si
    jge short .s46
    inc r12
.s46:
    jge near .n46
    inc r13
.n46:
    FLAGS 0xA02
    setle dl
    cmovle rax, rbx
    cmovle r9d, esi
    cmovle r10w, si
    jle short .s47
    inc r12
.s47:
    jle near .n47
    inc r13
.n47:
    FLAGS 0xA02
    setg dl
    cmovg rax, rbx
    cmovg r9d, esi
    cmovg r10w, si
    jg short .s48
    inc r12
.s48:
    jg near .n48
    inc r13
.n48:
    mov rbx, 0xFFFFFFFFFFFFFF80
    mov rsi, 0x80000000
    mov r9, 0xA07A1DE9E91D82FC
    FLAGS 0xA03
    seto dl
    cmovo rax, rbx
    cmovo r9d, esi
    cmovo r10w, si
    jo short .s49
    inc r12
.s49:
    jo near .n49
    inc r13
.n49:
    FLAGS 0xA03
    setno dl
    cmovno rax, rbx
    cmovno r9d, esi
    cmovno r10w, si
    jno short .s50
    inc r12
.s50:
    jno near .n50
    inc r13
.n50:
    FLAGS 0xA03
    setb dl
    cmovb rax, rbx
    cmovb r9d, esi
    cmovb r10w, si
    jb short .s51
    inc r12
.s51:
    jb near .n51
    inc r13
.n51:
    FLAGS 0xA03
    setae dl
    cmovae rax, rbx
    cmovae r9d, esi
    cmovae r10w, si
    jae short .s52
    inc r12
.s52:
    jae near .n52
    inc r13
.n52:
    mov r9, 0xD513DAC14F4E6169
    FLAGS 0xA03
    sete dl
    cmove rax, rbx
    cmove r9d, esi
    cmove r10w, si
    je short .s53
    inc r12
.s53:
    je near .n53
    inc r13
.n53:
    FLAGS 0xA03
    setne dl
    cmovne rax, rbx
    cmovne r9d, esi
    cmovne r10w, si
    jne short .s54
    inc r12
.s54:
    jne near .n54
    inc r13
.n54:
    FLAGS 0xA03
    setbe dl
    cmovbe rax, rbx
    cmovbe r9d, esi
    cmovbe r10w, si
    jbe short .s55
    inc r12
.s55:
    jbe near .n55
    inc r13
.n55:
    FLAGS 0xA03
    seta dl
    cmova rax, rbx
    cmova r9d, esi
    cmova r10w, si
    ja short .s56
    inc r12
.s56:
    ja near .n56
    inc r13
.n56:
    mov r9, 0xCDB2264CB3632E90
    FLAGS 0xA03
    sets dl
    cmovs rax, rbx
    cmovs r9d, esi
    cmovs r10w, si
    js short .s57
    inc r12
.s57:
    js near .n57
    inc r13
.n57:
    FLAGS 0xA03
    setns dl
    cmovns rax, rbx
    cmovns r9d, esi
    cmovns r10w, si
    jns short .s58
    inc r12
.s58:
    jns near .n58
    inc r13
.n58:
    FLAGS 0xA03
    setp dl
    cmovp rax, rbx
    cmovp r9d, esi
    cmovp r10w, si
    jp short .s59
    inc r12
.s59:
    jp near .n59
    inc r13
.n59:
    FLAGS 0xA03
    setnp dl
    cmovnp rax, rbx
    cmovnp r9d, esi
    cmovnp r10w, si
    jnp short .s60
    inc r12
.s60:
    jnp near .n60
    inc r13
.n60:
    mov r9, 0xCC24955244B79A81
    FLAGS 0xA03
    setl dl
    cmovl rax, rbx
    cmovl r9d, esi
    cmovl r10w, si
    jl short .s61
    inc r12
.s61:
    jl near .n61
    inc r13
.n61:
    FLAGS 0xA03
    setge dl
    cmovge rax, rbx
    cmovge r9d, esi
    cmovge r10w, si
    jge short .s62
    inc r12
.s62:
    jge near .n62
    inc r13
.n62:
    FLAGS 0xA03
    setle dl
    cmovle rax, rbx
    cmovle r9d, esi
    cmovle r10w, si
    jle short .s63
    inc r12
.s63:
    jle near .n63
    inc r13
.n63:
    FLAGS 0xA03
    setg dl
    cmovg rax, rbx
    cmovg r9d, esi
    cmovg r10w, si
    jg short .s64
    inc r12
.s64:
    jg near .n64
    inc r13
.n64:
    mov rbx, 0xC3E0530FF34EA470
    mov rsi, 0xFFFFFFFFFFFFFF31
    mov r9, 0x8B73795DE49AD735
    FLAGS 0xAD7
    seto dl
    cmovo rax, rbx
    cmovo r9d, esi
    cmovo r10w, si
    jo short .s65
    inc r12
.s65:
    jo near .n65
    inc r13
.n65:
    FLAGS 0xAD7
    setno dl
    cmovno rax, rbx
    cmovno r9d, esi
    cmovno r10w, si
    jno short .s66
    inc r12
.s66:
    jno near .n66
    inc r13
.n66:
    FLAGS 0xAD7
    setb dl
    cmovb rax, rbx
    cmovb r9d, esi
    cmovb r10w, si
    jb short .s67
    inc r12
.s67:
    jb near .n67
    inc r13
.n67:
    FLAGS 0xAD7
    setae dl
    cmovae rax, rbx
    cmovae r9d, esi
    cmovae r10w, si
    jae short .s68
    inc r12
.s68:
    jae near .n68
    inc r13
.n68:
    mov r9, 0xC8D4F93CF1F4AF71
    FLAGS 0xAD7
    sete dl
    cmove rax, rbx
    cmove r9d, esi
    cmove r10w, si
    je short .s69
    inc r12
.s69:
    je near .n69
    inc r13
.n69:
    FLAGS 0xAD7
    setne dl
    cmovne rax, rbx
    cmovne r9d, esi
    cmovne r10w, si
    jne short .s70
    inc r12
.s70:
    jne near .n70
    inc r13
.n70:
    FLAGS 0xAD7
    setbe dl
    cmovbe rax, rbx
    cmovbe r9d, esi
    cmovbe r10w, si
    jbe short .s71
    inc r12
.s71:
    jbe near .n71
    inc r13
.n71:
    FLAGS 0xAD7
    seta dl
    cmova rax, rbx
    cmova r9d, esi
    cmova r10w, si
    ja short .s72
    inc r12
.s72:
    ja near .n72
    inc r13
.n72:
    mov r9, 0xC8A545C1A977CE08
    FLAGS 0xAD7
    sets dl
    cmovs rax, rbx
    cmovs r9d, esi
    cmovs r10w, si
    js short .s73
    inc r12
.s73:
    js near .n73
    inc r13
.n73:
    FLAGS 0xAD7
    setns dl
    cmovns rax, rbx
    cmovns r9d, esi
    cmovns r10w, si
    jns short .s74
    inc r12
.s74:
    jns near .n74
    inc r13
.n74:
    FLAGS 0xAD7
    setp dl
    cmovp rax, rbx
    cmovp r9d, esi
    cmovp r10w, si
    jp short .s75
    inc r12
.s75:
    jp near .n75
    inc r13
.n75:
    FLAGS 0xAD7
    setnp dl
    cmovnp rax, rbx
    cmovnp r9d, esi
    cmovnp r10w, si
    jnp short .s76
    inc r12
.s76:
    jnp near .n76
    inc r13
.n76:
    mov r9, 0x9806C5804D193A08
    FLAGS 0xAD7
    setl dl
    cmovl rax, rbx
    cmovl r9d, esi
    cmovl r10w, si
    jl short .s77
    inc r12
.s77:
    jl near .n77
    inc r13
.n77:
    FLAGS 0xAD7
    setge dl
    cmovge rax, rbx
    cmovge r9d, esi
    cmovge r10w, si
    jge short .s78
    inc r12
.s78:
    jge near .n78
    inc r13
.n78:
    FLAGS 0xAD7
    setle dl
    cmovle rax, rbx
    cmovle r9d, esi
    cmovle r10w, si
    jle short .s79
    inc r12
.s79:
    jle near .n79
    inc r13
.n79:
    FLAGS 0xAD7
    setg dl
    cmovg rax, rbx
    cmovg r9d, esi
    cmovg r10w, si
    jg short .s80
    inc r12
.s80:
    jg near .n80
    inc r13
.n80:
    mov rbx, 0xFFFFFFFFFFFFFFFF
    mov rsi, 0x5CADF553F85D2DFB
    mov r9, 0xF6C14477D1DBBB39
    FLAGS 0x2D6
    seto dl
    cmovo rax, rbx
    cmovo r9d, esi
    cmovo r10w, si
    jo short .s81
    inc r12
.s81:
    jo near .n81
    inc r13
.n81:
    FLAGS 0x2D6
    setno dl
    cmovno rax, rbx
    cmovno r9d, esi
    cmovno r10w, si
    jno short .s82
    inc r12
.s82:
    jno near .n82
    inc r13
.n82:
    FLAGS 0x2D6
    setb dl
    cmovb rax, rbx
    cmovb r9d, esi
    cmovb r10w, si
    jb short .s83
    inc r12
.s83:
    jb near .n83
    inc r13
.n83:
    FLAGS 0x2D6
    setae dl
    cmovae rax, rbx
    cmovae r9d, esi
    cmovae r10w, si
    jae short .s84
    inc r12
.s84:
    jae near .n84
    inc r13
.n84:
    mov r9, 0xE4635AEB7A1024DB
    FLAGS 0x2D6
    sete dl
    cmove rax, rbx
    cmove r9d, esi
    cmove r10w, si
    je short .s85
    inc r12
.s85:
    je near .n85
    inc r13
.n85:
    FLAGS 0x2D6
    setne dl
    cmovne rax, rbx
    cmovne r9d, esi
    cmovne r10w, si
    jne short .s86
    inc r12
.s86:
    jne near .n86
    inc r13
.n86:
    FLAGS 0x2D6
    setbe dl
    cmovbe rax, rbx
    cmovbe r9d, esi
    cmovbe r10w, si
    jbe short .s87
    inc r12
.s87:
    jbe near .n87
    inc r13
.n87:
    FLAGS 0x2D6
    seta dl
    cmova rax, rbx
    cmova r9d, esi
    cmova r10w, si
    ja short .s88
    inc r12
.s88:
    ja near .n88
    inc r13
.n88:
    mov r9, 0xF962138B2378DD16
    FLAGS 0x2D6
    sets dl
    cmovs rax, rbx
    cmovs r9d, esi
    cmovs r10w, si
    js short .s89
    inc r12
.s89:
    js near .n89
    inc r13
.n89:
    FLAGS 0x2D6
    setns dl
    cmovns rax, rbx
    cmovns r9d, esi
    cmovns r10w, si
    jns short .s90
    inc r12
.s90:
    jns near .n90
    inc r13
.n90:
    FLAGS 0x2D6
    setp dl
    cmovp rax, rbx
    cmovp r9d, esi
    cmovp r10w, si
    jp short .s91
    inc r12
.s91:
    jp near .n91
    inc r13
.n91:
    FLAGS 0x2D6
    setnp dl
    cmovnp rax, rbx
    cmovnp r9d, esi
    cmovnp r10w, si
    jnp short .s92
    inc r12
.s92:
    jnp near .n92
    inc r13
.n92:
    mov r9, 0xE4B6D97E134D9A24
    FLAGS 0x2D6
    setl dl
    cmovl rax, rbx
    cmovl r9d, esi
    cmovl r10w, si
    jl short .s93
    inc r12
.s93:
    jl near .n93
    inc r13
.n93:
    FLAGS 0x2D6
    setge dl
    cmovge rax, rbx
    cmovge r9d, esi
    cmovge r10w, si
    jge short .s94
    inc r12
.s94:
    jge near .n94
    inc r13
.n94:
    FLAGS 0x2D6
    setle dl
    cmovle rax, rbx
    cmovle r9d, esi
    cmovle r10w, si
    jle short .s95
    inc r12
.s95:
    jle near .n95
    inc r13
.n95:
    FLAGS 0x2D6
    setg dl
    cmovg rax, rbx
    cmovg r9d, esi
    cmovg r10w, si
    jg short .s96
    inc r12
.s96:
    jg near .n96
    inc r13
.n96:
    mov rbx, 0x8000000000000000
    mov rsi, 0xD456F51B96BB2EB4
    mov r9, 0xD2C5ACBCE9402A14
    FLAGS 0x213
    seto dl
    cmovo rax, rbx
    cmovo r9d, esi
    cmovo r10w, si
    jo short .s97
    inc r12
.s97:
    jo near .n97
    inc r13
.n97:
    FLAGS 0x213
    setno dl
    cmovno rax, rbx
    cmovno r9d, esi
    cmovno r10w, si
    jno short .s98
    inc r12
.s98:
    jno near .n98
    inc r13
.n98:
    FLAGS 0x213
    setb dl
    cmovb rax, rbx
    cmovb r9d, esi
    cmovb r10w, si
    jb short .s99
    inc r12
.s99:
    jb near .n99
    inc r13
.n99:
    FLAGS 0x213
    setae dl
    cmovae rax, rbx
    cmovae r9d, esi
    cmovae r10w, si
    jae short .s100
    inc r12
.s100:
    jae near .n100
    inc r13
.n100:
    mov r9, 0xCE3DDC36A75332AE
    FLAGS 0x213
    sete dl
    cmove rax, rbx
    cmove r9d, esi
    cmove r10w, si
    je short .s101
    inc r12
.s101:
    je near .n101
    inc r13
.n101:
    FLAGS 0x213
    setne dl
    cmovne rax, rbx
    cmovne r9d, esi
    cmovne r10w, si
    jne short .s102
    inc r12
.s102:
    jne near .n102
    inc r13
.n102:
    FLAGS 0x213
    setbe dl
    cmovbe rax, rbx
    cmovbe r9d, esi
    cmovbe r10w, si
    jbe short .s103
    inc r12
.s103:
    jbe near .n103
    inc r13
.n103:
    FLAGS 0x213
    seta dl
    cmova rax, rbx
    cmova r9d, esi
    cmova r10w, si
    ja short .s104
    inc r12
.s104:
    ja near .n104
    inc r13
.n104:
    mov r9, 0x9E5C43CB2AB4C961
    FLAGS 0x213
    sets dl
    cmovs rax, rbx
    cmovs r9d, esi
    cmovs r10w, si
    js short .s105
    inc r12
.s105:
    js near .n105
    inc r13
.n105:
    FLAGS 0x213
    setns dl
    cmovns rax, rbx
    cmovns r9d, esi
    cmovns r10w, si
    jns short .s106
    inc r12
.s106:
    jns near .n106
    inc r13
.n106:
    FLAGS 0x213
    setp dl
    cmovp rax, rbx
    cmovp r9d, esi
    cmovp r10w, si
    jp short .s107
    inc r12
.s107:
    jp near .n107
    inc r13
.n107:
    FLAGS 0x213
    setnp dl
    cmovnp rax, rbx
    cmovnp r9d, esi
    cmovnp r10w, si
    jnp short .s108
    inc r12
.s108:
    jnp near .n108
    inc r13
.n108:
    mov r9, 0x91272B5C77DDAFDD
    FLAGS 0x213
    setl dl
    cmovl rax, rbx
    cmovl r9d, esi
    cmovl r10w, si
    jl short .s109
    inc r12
.s109:
    jl near .n109
    inc r13
.n109:
    FLAGS 0x213
    setge dl
    cmovge rax, rbx
    cmovge r9d, esi
    cmovge r10w, si
    jge short .s110
    inc r12
.s110:
    jge near .n110
    inc r13
.n110:
    FLAGS 0x213
    setle dl
    cmovle rax, rbx
    cmovle r9d, esi
    cmovle r10w, si
    jle short .s111
    inc r12
.s111:
    jle near .n111
    inc r13
.n111:
    FLAGS 0x213
    setg dl
    cmovg rax, rbx
    cmovg r9d, esi
    cmovg r10w, si
    jg short .s112
    inc r12
.s112:
    jg near .n112
    inc r13
.n112:
    mov rbx, 0x6BACCDAE2A3D635D
    mov rsi, 0xFFFFFFFFFFFFFFDB
    mov r9, 0xA4913C13622C1800
    FLAGS 0x246
    seto dl
    cmovo rax, rbx
    cmovo r9d, esi
    cmovo r10w, si
    jo short .s113
    inc r12
.s113:
    jo near .n113
    inc r13
.n113:
    FLAGS 0x246
    setno dl
    cmovno rax, rbx
    cmovno r9d, esi
    cmovno r10w, si
    jno short .s114
    inc r12
.s114:
    jno near .n114
    inc r13
.n114:
    FLAGS 0x246
    setb dl
    cmovb rax, rbx
    cmovb r9d, esi
    cmovb r10w, si
    jb short .s115
    inc r12
.s115:
    jb near .n115
    inc r13
.n115:
    FLAGS 0x246
    setae dl
    cmovae rax, rbx
    cmovae r9d, esi
    cmovae r10w, si
    jae short .s116
    inc r12
.s116:
    jae near .n116
    inc r13
.n116:
    mov r9, 0xAB059BFBE1A0C994
    FLAGS 0x246
    sete dl
    cmove rax, rbx
    cmove r9d, esi
    cmove r10w, si
    je short .s117
    inc r12
.s117:
    je near .n117
    inc r13
.n117:
    FLAGS 0x246
    setne dl
    cmovne rax, rbx
    cmovne r9d, esi
    cmovne r10w, si
    jne short .s118
    inc r12
.s118:
    jne near .n118
    inc r13
.n118:
    FLAGS 0x246
    setbe dl
    cmovbe rax, rbx
    cmovbe r9d, esi
    cmovbe r10w, si
    jbe short .s119
    inc r12
.s119:
    jbe near .n119
    inc r13
.n119:
    FLAGS 0x246
    seta dl
    cmova rax, rbx
    cmova r9d, esi
    cmova r10w, si
    ja short .s120
    inc r12
.s120:
    ja near .n120
    inc r13
.n120:
    mov r9, 0xEFCA4ABB14C2C3AE
    FLAGS 0x246
    sets dl
    cmovs rax, rbx
    cmovs r9d, esi
    cmovs r10w, si
    js short .s121
    inc r12
.s121:
    js near .n121
    inc r13
.n121:
    FLAGS 0x246
    setns dl
    cmovns rax, rbx
    cmovns r9d, esi
    cmovns r10w, si
    jns short .s122
    inc r12
.s122:
    jns near .n122
    inc r13
.n122:
    FLAGS 0x246
    setp dl
    cmovp rax, rbx
    cmovp r9d, esi
    cmovp r10w, si
    jp short .s123
    inc r12
.s123:
    jp near .n123
    inc r13
.n123:
    FLAGS 0x246
    setnp dl
    cmovnp rax, rbx
    cmovnp r9d, esi
    cmovnp r10w, si
    jnp short .s124
    inc r12
.s124:
    jnp near .n124
    inc r13
.n124:
    mov r9, 0xA6EA6524801BFD5E
    FLAGS 0x246
    setl dl
    cmovl rax, rbx
    cmovl r9d, esi
    cmovl r10w, si
    jl short .s125
    inc r12
.s125:
    jl near .n125
    inc r13
.n125:
    FLAGS 0x246
    setge dl
    cmovge rax, rbx
    cmovge r9d, esi
    cmovge r10w, si
    jge short .s126
    inc r12
.s126:
    jge near .n126
    inc r13
.n126:
    FLAGS 0x246
    setle dl
    cmovle rax, rbx
    cmovle r9d, esi
    cmovle r10w, si
    jle short .s127
    inc r12
.s127:
    jle near .n127
    inc r13
.n127:
    FLAGS 0x246
    setg dl
    cmovg rax, rbx
    cmovg r9d, esi
    cmovg r10w, si
    jg short .s128
    inc r12
.s128:
    jg near .n128
    inc r13
.n128:
    mov rbx, 0x8000
    mov rsi, 0x64
    mov r9, 0xDD13C19079047EA5
    FLAGS 0xA82
    seto dl
    cmovo rax, rbx
    cmovo r9d, esi
    cmovo r10w, si
    jo short .s129
    inc r12
.s129:
    jo near .n129
    inc r13
.n129:
    FLAGS 0xA82
    setno dl
    cmovno rax, rbx
    cmovno r9d, esi
    cmovno r10w, si
    jno short .s130
    inc r12
.s130:
    jno near .n130
    inc r13
.n130:
    FLAGS 0xA82
    setb dl
    cmovb rax, rbx
    cmovb r9d, esi
    cmovb r10w, si
    jb short .s131
    inc r12
.s131:
    jb near .n131
    inc r13
.n131:
    FLAGS 0xA82
    setae dl
    cmovae rax, rbx
    cmovae r9d, esi
    cmovae r10w, si
    jae short .s132
    inc r12
.s132:
    jae near .n132
    inc r13
.n132:
    mov r9, 0xE2540A5E8AF7A110
    FLAGS 0xA82
    sete dl
    cmove rax, rbx
    cmove r9d, esi
    cmove r10w, si
    je short .s133
    inc r12
.s133:
    je near .n133
    inc r13
.n133:
    FLAGS 0xA82
    setne dl
    cmovne rax, rbx
    cmovne r9d, esi
    cmovne r10w, si
    jne short .s134
    inc r12
.s134:
    jne near .n134
    inc r13
.n134:
    FLAGS 0xA82
    setbe dl
    cmovbe rax, rbx
    cmovbe r9d, esi
    cmovbe r10w, si
    jbe short .s135
    inc r12
.s135:
    jbe near .n135
    inc r13
.n135:
    FLAGS 0xA82
    seta dl
    cmova rax, rbx
    cmova r9d, esi
    cmova r10w, si
    ja short .s136
    inc r12
.s136:
    ja near .n136
    inc r13
.n136:
    mov r9, 0xAAFBFB22227B0FF3
    FLAGS 0xA82
    sets dl
    cmovs rax, rbx
    cmovs r9d, esi
    cmovs r10w, si
    js short .s137
    inc r12
.s137:
    js near .n137
    inc r13
.n137:
    FLAGS 0xA82
    setns dl
    cmovns rax, rbx
    cmovns r9d, esi
    cmovns r10w, si
    jns short .s138
    inc r12
.s138:
    jns near .n138
    inc r13
.n138:
    FLAGS 0xA82
    setp dl
    cmovp rax, rbx
    cmovp r9d, esi
    cmovp r10w, si
    jp short .s139
    inc r12
.s139:
    jp near .n139
    inc r13
.n139:
    FLAGS 0xA82
    setnp dl
    cmovnp rax, rbx
    cmovnp r9d, esi
    cmovnp r10w, si
    jnp short .s140
    inc r12
.s140:
    jnp near .n140
    inc r13
.n140:
    mov r9, 0x96873A038E79CB74
    FLAGS 0xA82
    setl dl
    cmovl rax, rbx
    cmovl r9d, esi
    cmovl r10w, si
    jl short .s141
    inc r12
.s141:
    jl near .n141
    inc r13
.n141:
    FLAGS 0xA82
    setge dl
    cmovge rax, rbx
    cmovge r9d, esi
    cmovge r10w, si
    jge short .s142
    inc r12
.s142:
    jge near .n142
    inc r13
.n142:
    FLAGS 0xA82
    setle dl
    cmovle rax, rbx
    cmovle r9d, esi
    cmovle r10w, si
    jle short .s143
    inc r12
.s143:
    jle near .n143
    inc r13
.n143:
    FLAGS 0xA82
    setg dl
    cmovg rax, rbx
    cmovg r9d, esi
    cmovg r10w, si
    jg short .s144
    inc r12
.s144:
    jg near .n144
    inc r13
.n144:
    mov rbx, 0x7F
    mov rsi, 0xE9510FD4A1E5AF1C
    mov r9, 0x8E069937524606F4
    FLAGS 0x297
    seto dl
    cmovo rax, rbx
    cmovo r9d, esi
    cmovo r10w, si
    jo short .s145
    inc r12
.s145:
    jo near .n145
    inc r13
.n145:
    FLAGS 0x297
    setno dl
    cmovno rax, rbx
    cmovno r9d, esi
    cmovno r10w, si
    jno short .s146
    inc r12
.s146:
    jno near .n146
    inc r13
.n146:
    FLAGS 0x297
    setb dl
    cmovb rax, rbx
    cmovb r9d, esi
    cmovb r10w, si
    jb short .s147
    inc r12
.s147:
    jb near .n147
    inc r13
.n147:
    FLAGS 0x297
    setae dl
    cmovae rax, rbx
    cmovae r9d, esi
    cmovae r10w, si
    jae short .s148
    inc r12
.s148:
    jae near .n148
    inc r13
.n148:
    mov r9, 0xF2F7C58D81367A9A
    FLAGS 0x297
    sete dl
    cmove rax, rbx
    cmove r9d, esi
    cmove r10w, si
    je short .s149
    inc r12
.s149:
    je near .n149
    inc r13
.n149:
    FLAGS 0x297
    setne dl
    cmovne rax, rbx
    cmovne r9d, esi
    cmovne r10w, si
    jne short .s150
    inc r12
.s150:
    jne near .n150
    inc r13
.n150:
    FLAGS 0x297
    setbe dl
    cmovbe rax, rbx
    cmovbe r9d, esi
    cmovbe r10w, si
    jbe short .s151
    inc r12
.s151:
    jbe near .n151
    inc r13
.n151:
    FLAGS 0x297
    seta dl
    cmova rax, rbx
    cmova r9d, esi
    cmova r10w, si
    ja short .s152
    inc r12
.s152:
    ja near .n152
    inc r13
.n152:
    mov r9, 0xC1C627019CE57584
    FLAGS 0x297
    sets dl
    cmovs rax, rbx
    cmovs r9d, esi
    cmovs r10w, si
    js short .s153
    inc r12
.s153:
    js near .n153
    inc r13
.n153:
    FLAGS 0x297
    setns dl
    cmovns rax, rbx
    cmovns r9d, esi
    cmovns r10w, si
    jns short .s154
    inc r12
.s154:
    jns near .n154
    inc r13
.n154:
    FLAGS 0x297
    setp dl
    cmovp rax, rbx
    cmovp r9d, esi
    cmovp r10w, si
    jp short .s155
    inc r12
.s155:
    jp near .n155
    inc r13
.n155:
    FLAGS 0x297
    setnp dl
    cmovnp rax, rbx
    cmovnp r9d, esi
    cmovnp r10w, si
    jnp short .s156
    inc r12
.s156:
    jnp near .n156
    inc r13
.n156:
    mov r9, 0x9B45B0FD7142B7BC
    FLAGS 0x297
    setl dl
    cmovl rax, rbx
    cmovl r9d, esi
    cmovl r10w, si
    jl short .s157
    inc r12
.s157:
    jl near .n157
    inc r13
.n157:
    FLAGS 0x297
    setge dl
    cmovge rax, rbx
    cmovge r9d, esi
    cmovge r10w, si
    jge short .s158
    inc r12
.s158:
    jge near .n158
    inc r13
.n158:
    FLAGS 0x297
    setle dl
    cmovle rax, rbx
    cmovle r9d, esi
    cmovle r10w, si
    jle short .s159
    inc r12
.s159:
    jle near .n159
    inc r13
.n159:
    FLAGS 0x297
    setg dl
    cmovg rax, rbx
    cmovg r9d, esi
    cmovg r10w, si
    jg short .s160
    inc r12
.s160:
    jg near .n160
    inc r13
.n160:
    mov rbx, 0x100000000
    mov rsi, 0xFFFFFFFFFFFFFF9D
    mov r9, 0x9AADF7FE446210F4
    FLAGS 0xA43
    seto dl
    cmovo rax, rbx
    cmovo r9d, esi
    cmovo r10w, si
    jo short .s161
    inc r12
.s161:
    jo near .n161
    inc r13
.n161:
    FLAGS 0xA43
    setno dl
    cmovno rax, rbx
    cmovno r9d, esi
    cmovno r10w, si
    jno short .s162
    inc r12
.s162:
    jno near .n162
    inc r13
.n162:
    FLAGS 0xA43
    setb dl
    cmovb rax, rbx
    cmovb r9d, esi
    cmovb r10w, si
    jb short .s163
    inc r12
.s163:
    jb near .n163
    inc r13
.n163:
    FLAGS 0xA43
    setae dl
    cmovae rax, rbx
    cmovae r9d, esi
    cmovae r10w, si
    jae short .s164
    inc r12
.s164:
    jae near .n164
    inc r13
.n164:
    mov r9, 0xD69569743A8A480D
    FLAGS 0xA43
    sete dl
    cmove rax, rbx
    cmove r9d, esi
    cmove r10w, si
    je short .s165
    inc r12
.s165:
    je near .n165
    inc r13
.n165:
    FLAGS 0xA43
    setne dl
    cmovne rax, rbx
    cmovne r9d, esi
    cmovne r10w, si
    jne short .s166
    inc r12
.s166:
    jne near .n166
    inc r13
.n166:
    FLAGS 0xA43
    setbe dl
    cmovbe rax, rbx
    cmovbe r9d, esi
    cmovbe r10w, si
    jbe short .s167
    inc r12
.s167:
    jbe near .n167
    inc r13
.n167:
    FLAGS 0xA43
    seta dl
    cmova rax, rbx
    cmova r9d, esi
    cmova r10w, si
    ja short .s168
    inc r12
.s168:
    ja near .n168
    inc r13
.n168:
    mov r9, 0x97FFD218CADAC3FF
    FLAGS 0xA43
    sets dl
    cmovs rax, rbx
    cmovs r9d, esi
    cmovs r10w, si
    js short .s169
    inc r12
.s169:
    js near .n169
    inc r13
.n169:
    FLAGS 0xA43
    setns dl
    cmovns rax, rbx
    cmovns r9d, esi
    cmovns r10w, si
    jns short .s170
    inc r12
.s170:
    jns near .n170
    inc r13
.n170:
    FLAGS 0xA43
    setp dl
    cmovp rax, rbx
    cmovp r9d, esi
    cmovp r10w, si
    jp short .s171
    inc r12
.s171:
    jp near .n171
    inc r13
.n171:
    FLAGS 0xA43
    setnp dl
    cmovnp rax, rbx
    cmovnp r9d, esi
    cmovnp r10w, si
    jnp short .s172
    inc r12
.s172:
    jnp near .n172
    inc r13
.n172:
    mov r9, 0xCB7229E44237503A
    FLAGS 0xA43
    setl dl
    cmovl rax, rbx
    cmovl r9d, esi
    cmovl r10w, si
    jl short .s173
    inc r12
.s173:
    jl near .n173
    inc r13
.n173:
    FLAGS 0xA43
    setge dl
    cmovge rax, rbx
    cmovge r9d, esi
    cmovge r10w, si
    jge short .s174
    inc r12
.s174:
    jge near .n174
    inc r13
.n174:
    FLAGS 0xA43
    setle dl
    cmovle rax, rbx
    cmovle r9d, esi
    cmovle r10w, si
    jle short .s175
    inc r12
.s175:
    jle near .n175
    inc r13
.n175:
    FLAGS 0xA43
    setg dl
    cmovg rax, rbx
    cmovg r9d, esi
    cmovg r10w, si
    jg short .s176
    inc r12
.s176:
    jg near .n176
    inc r13
.n176:
    mov rbx, 0x7FFF
    mov rsi, 0xD134B48510139AB8
    mov r9, 0xA3F4A1F44072D1DB
    FLAGS 0x212
    seto dl
    cmovo rax, rbx
    cmovo r9d, esi
    cmovo r10w, si
    jo short .s177
    inc r12
.s177:
    jo near .n177
    inc r13
.n177:
    FLAGS 0x212
    setno dl
    cmovno rax, rbx
    cmovno r9d, esi
    cmovno r10w, si
    jno short .s178
    inc r12
.s178:
    jno near .n178
    inc r13
.n178:
    FLAGS 0x212
    setb dl
    cmovb rax, rbx
    cmovb r9d, esi
    cmovb r10w, si
    jb short .s179
    inc r12
.s179:
    jb near .n179
    inc r13
.n179:
    FLAGS 0x212
    setae dl
    cmovae rax, rbx
    cmovae r9d, esi
    cmovae r10w, si
    jae short .s180
    inc r12
.s180:
    jae near .n180
    inc r13
.n180:
    mov r9, 0xC360D3CC0910BD80
    FLAGS 0x212
    sete dl
    cmove rax, rbx
    cmove r9d, esi
    cmove r10w, si
    je short .s181
    inc r12
.s181:
    je near .n181
    inc r13
.n181:
    FLAGS 0x212
    setne dl
    cmovne rax, rbx
    cmovne r9d, esi
    cmovne r10w, si
    jne short .s182
    inc r12
.s182:
    jne near .n182
    inc r13
.n182:
    FLAGS 0x212
    setbe dl
    cmovbe rax, rbx
    cmovbe r9d, esi
    cmovbe r10w, si
    jbe short .s183
    inc r12
.s183:
    jbe near .n183
    inc r13
.n183:
    FLAGS 0x212
    seta dl
    cmova rax, rbx
    cmova r9d, esi
    cmova r10w, si
    ja short .s184
    inc r12
.s184:
    ja near .n184
    inc r13
.n184:
    mov r9, 0x9CA9214AD0624E30
    FLAGS 0x212
    sets dl
    cmovs rax, rbx
    cmovs r9d, esi
    cmovs r10w, si
    js short .s185
    inc r12
.s185:
    js near .n185
    inc r13
.n185:
    FLAGS 0x212
    setns dl
    cmovns rax, rbx
    cmovns r9d, esi
    cmovns r10w, si
    jns short .s186
    inc r12
.s186:
    jns near .n186
    inc r13
.n186:
    FLAGS 0x212
    setp dl
    cmovp rax, rbx
    cmovp r9d, esi
    cmovp r10w, si
    jp short .s187
    inc r12
.s187:
    jp near .n187
    inc r13
.n187:
    FLAGS 0x212
    setnp dl
    cmovnp rax, rbx
    cmovnp r9d, esi
    cmovnp r10w, si
    jnp short .s188
    inc r12
.s188:
    jnp near .n188
    inc r13
.n188:
    mov r9, 0xAC64B3C1AFBA73ED
    FLAGS 0x212
    setl dl
    cmovl rax, rbx
    cmovl r9d, esi
    cmovl r10w, si
    jl short .s189
    inc r12
.s189:
    jl near .n189
    inc r13
.n189:
    FLAGS 0x212
    setge dl
    cmovge rax, rbx
    cmovge r9d, esi
    cmovge r10w, si
    jge short .s190
    inc r12
.s190:
    jge near .n190
    inc r13
.n190:
    FLAGS 0x212
    setle dl
    cmovle rax, rbx
    cmovle r9d, esi
    cmovle r10w, si
    jle short .s191
    inc r12
.s191:
    jle near .n191
    inc r13
.n191:
    FLAGS 0x212
    setg dl
    cmovg rax, rbx
    cmovg r9d, esi
    cmovg r10w, si
    jg short .s192
    inc r12
.s192:
    jg near .n192
    inc r13
.n192:
    mov [buf], rbx
    FLAGS 0x246
    cmove r14d, [buf]
    sete byte [buf + 8]
    FLAGS 0x202
    cmove r15, [buf]
    sete byte [buf + 9]
    FLAGS 0x246
    cmovne r14d, [buf]
    setne byte [buf + 8]
    FLAGS 0x202
    cmovne r15, [buf]
    setne byte [buf + 9]
    FLAGS 0x246
    cmovl r14d, [buf]
    setl byte [buf + 8]
    FLAGS 0x202
    cmovl r15, [buf]
    setl byte [buf + 9]
    FLAGS 0x246
    cmova r14d, [buf]
    seta byte [buf + 8]
    FLAGS 0x202
    cmova r15, [buf]
    seta byte [buf + 9]
    mov rax, [buf + 8]
    EXIT
    align 16
buf: times 64 dq 0x0123456789ABCDEF
file_end:
