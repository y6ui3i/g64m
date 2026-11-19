; MOVS, STOS, LODS, CMPS and SCAS at every width, forward and backward, alone and with the REP prefixes.
; Written by tools/gen64_tests.py: change that, not this.
%include "elf.inc"
    cld
    lea rsi, [buf + 64]
    lea rdi, [buf + 256]
    mov rax, 0x69C129DA2FD66FE1
    movsb
    stosb
    lodsb
    cmpsb
    scasb
    mov ecx, 3
    rep movsb
    mov ecx, 3
    rep stosb
    mov ecx, 2
    rep lodsb
    xor ecx, ecx
    rep movsb
    repe cmpsb
    lea rsi, [buf + 128]
    lea rdi, [buf + 192]
    mov ecx, 4
    repe cmpsb
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repne cmpsb
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repe cmpsb
    lea rdi, [buf + 256]
    mov rax, [buf + 256]
    mov ecx, 5
    repe scasb
    lea rdi, [buf + 256]
    mov ecx, 5
    repne scasb
    not rax
    mov ecx, 3
    repne scasb
    mov r8, [buf + 256]
    mov r9, [buf + 264]
    mov r10, [buf + 248]
    cld
    lea rsi, [buf + 64]
    lea rdi, [buf + 256]
    mov rax, 0xEBFBFF527C406F04
    movsw
    stosw
    lodsw
    cmpsw
    scasw
    mov ecx, 3
    rep movsw
    mov ecx, 3
    rep stosw
    mov ecx, 2
    rep lodsw
    xor ecx, ecx
    rep movsw
    repe cmpsw
    lea rsi, [buf + 128]
    lea rdi, [buf + 192]
    mov ecx, 4
    repe cmpsw
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repne cmpsw
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repe cmpsw
    lea rdi, [buf + 256]
    mov rax, [buf + 256]
    mov ecx, 5
    repe scasw
    lea rdi, [buf + 256]
    mov ecx, 5
    repne scasw
    not rax
    mov ecx, 3
    repne scasw
    mov r8, [buf + 256]
    mov r9, [buf + 264]
    mov r10, [buf + 248]
    cld
    lea rsi, [buf + 64]
    lea rdi, [buf + 256]
    mov rax, 0xD99CF99D2C77C908
    movsd
    stosd
    lodsd
    cmpsd
    scasd
    mov ecx, 3
    rep movsd
    mov ecx, 3
    rep stosd
    mov ecx, 2
    rep lodsd
    xor ecx, ecx
    rep movsd
    repe cmpsd
    lea rsi, [buf + 128]
    lea rdi, [buf + 192]
    mov ecx, 4
    repe cmpsd
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repne cmpsd
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repe cmpsd
    lea rdi, [buf + 256]
    mov rax, [buf + 256]
    mov ecx, 5
    repe scasd
    lea rdi, [buf + 256]
    mov ecx, 5
    repne scasd
    not rax
    mov ecx, 3
    repne scasd
    mov r8, [buf + 256]
    mov r9, [buf + 264]
    mov r10, [buf + 248]
    cld
    lea rsi, [buf + 64]
    lea rdi, [buf + 256]
    mov rax, 0xBA89236E2E6FD594
    movsq
    stosq
    lodsq
    cmpsq
    scasq
    mov ecx, 3
    rep movsq
    mov ecx, 3
    rep stosq
    mov ecx, 2
    rep lodsq
    xor ecx, ecx
    rep movsq
    repe cmpsq
    lea rsi, [buf + 128]
    lea rdi, [buf + 192]
    mov ecx, 4
    repe cmpsq
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repne cmpsq
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repe cmpsq
    lea rdi, [buf + 256]
    mov rax, [buf + 256]
    mov ecx, 5
    repe scasq
    lea rdi, [buf + 256]
    mov ecx, 5
    repne scasq
    not rax
    mov ecx, 3
    repne scasq
    mov r8, [buf + 256]
    mov r9, [buf + 264]
    mov r10, [buf + 248]
    std
    lea rsi, [buf + 64]
    lea rdi, [buf + 256]
    mov rax, 0x8000
    movsb
    stosb
    lodsb
    cmpsb
    scasb
    mov ecx, 3
    rep movsb
    mov ecx, 3
    rep stosb
    mov ecx, 2
    rep lodsb
    xor ecx, ecx
    rep movsb
    repe cmpsb
    lea rsi, [buf + 128]
    lea rdi, [buf + 192]
    mov ecx, 4
    repe cmpsb
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repne cmpsb
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repe cmpsb
    lea rdi, [buf + 256]
    mov rax, [buf + 256]
    mov ecx, 5
    repe scasb
    lea rdi, [buf + 256]
    mov ecx, 5
    repne scasb
    not rax
    mov ecx, 3
    repne scasb
    mov r8, [buf + 256]
    mov r9, [buf + 264]
    mov r10, [buf + 248]
    std
    lea rsi, [buf + 64]
    lea rdi, [buf + 256]
    mov rax, 0x7FFF
    movsw
    stosw
    lodsw
    cmpsw
    scasw
    mov ecx, 3
    rep movsw
    mov ecx, 3
    rep stosw
    mov ecx, 2
    rep lodsw
    xor ecx, ecx
    rep movsw
    repe cmpsw
    lea rsi, [buf + 128]
    lea rdi, [buf + 192]
    mov ecx, 4
    repe cmpsw
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repne cmpsw
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repe cmpsw
    lea rdi, [buf + 256]
    mov rax, [buf + 256]
    mov ecx, 5
    repe scasw
    lea rdi, [buf + 256]
    mov ecx, 5
    repne scasw
    not rax
    mov ecx, 3
    repne scasw
    mov r8, [buf + 256]
    mov r9, [buf + 264]
    mov r10, [buf + 248]
    std
    lea rsi, [buf + 64]
    lea rdi, [buf + 256]
    mov rax, 0xFFFFFFFFFFFFFFC9
    movsd
    stosd
    lodsd
    cmpsd
    scasd
    mov ecx, 3
    rep movsd
    mov ecx, 3
    rep stosd
    mov ecx, 2
    rep lodsd
    xor ecx, ecx
    rep movsd
    repe cmpsd
    lea rsi, [buf + 128]
    lea rdi, [buf + 192]
    mov ecx, 4
    repe cmpsd
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repne cmpsd
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repe cmpsd
    lea rdi, [buf + 256]
    mov rax, [buf + 256]
    mov ecx, 5
    repe scasd
    lea rdi, [buf + 256]
    mov ecx, 5
    repne scasd
    not rax
    mov ecx, 3
    repne scasd
    mov r8, [buf + 256]
    mov r9, [buf + 264]
    mov r10, [buf + 248]
    std
    lea rsi, [buf + 64]
    lea rdi, [buf + 256]
    mov rax, 0xA88A814FC85FC72B
    movsq
    stosq
    lodsq
    cmpsq
    scasq
    mov ecx, 3
    rep movsq
    mov ecx, 3
    rep stosq
    mov ecx, 2
    rep lodsq
    xor ecx, ecx
    rep movsq
    repe cmpsq
    lea rsi, [buf + 128]
    lea rdi, [buf + 192]
    mov ecx, 4
    repe cmpsq
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repne cmpsq
    lea rsi, [buf + 128]
    lea rdi, [buf + 256]
    mov ecx, 4
    repe cmpsq
    lea rdi, [buf + 256]
    mov rax, [buf + 256]
    mov ecx, 5
    repe scasq
    lea rdi, [buf + 256]
    mov ecx, 5
    repne scasq
    not rax
    mov ecx, 3
    repne scasq
    mov r8, [buf + 256]
    mov r9, [buf + 264]
    mov r10, [buf + 248]
    cld
    mov r15, 0xFFFFFFFF00000000
    lea rsi, [buf + 64]
    lea rdi, [buf + 256]
    or rsi, r15
    or rdi, r15
    mov rcx, r15
    or rcx, 3
    a32 rep movsb
    or rdi, r15
    a32 stosd
    or rsi, r15
    a32 lodsw
    EXIT
    align 16
buf: times 64 dq 0x0123456789ABCDEF
file_end:
