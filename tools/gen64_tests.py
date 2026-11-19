#!/usr/bin/env python3
"""Writes the generated 64-bit instruction tests, tests/asm64/g_*.asm (E091).

    tools/gen64_tests.py

Each test is a long run of cases: registers loaded with values from a pool (the edges of
each width, and random ones), the flags sometimes set from a constant, then the instruction.
Nothing is checked inside the test: the trace of registers and flags after every instruction
is what is compared with a real CPU's (tools/difftest64.sh). The random numbers have a fixed
seed, so the files come out the same every time; they are kept in the repository.
"""
import os
import random

R64 = ["rax", "rcx", "rdx", "rbx", "rsp", "rbp", "rsi", "rdi"] + [f"r{i}" for i in range(8, 16)]
R32 = ["eax", "ecx", "edx", "ebx", "esp", "ebp", "esi", "edi"] + [f"r{i}d" for i in range(8, 16)]
R16 = ["ax", "cx", "dx", "bx", "sp", "bp", "si", "di"] + [f"r{i}w" for i in range(8, 16)]
R8 = ["al", "cl", "dl", "bl", "spl", "bpl", "sil", "dil"] + [f"r{i}b" for i in range(8, 16)]
HIGH = {0: "ah", 1: "ch", 2: "dh", 3: "bh"}
FREE = [0, 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]      # every register but RSP
SIZE = {8: "byte", 16: "word", 32: "dword", 64: "qword"}
WIDTHS = [8, 16, 32, 64]
ARITH = [0x000, 0x001, 0x800, 0x801, 0x8D5, 0x0D4, 0x011, 0x044, 0x880, 0x095, 0x841, 0x010]

EDGES = [0, 1, 2, 3, 0x7F, 0x80, 0x81, 0xFF, 0x100, 0x7FFF, 0x8000, 0xFFFF, 0x10000,
         0x7FFFFFFF, 0x80000000, 0xFFFFFFFF, 0x100000000, 0x7FFFFFFFFFFFFFFF,
         0x8000000000000000, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFF80, 0xFFFFFFFF80000000]


def rn(i, w):
    return {64: R64, 32: R32, 16: R16, 8: R8}[w][i]


class Test:
    def __init__(self, name, what, seed):
        self.name = name
        self.rng = random.Random(seed)
        self.lines = [f"; {what}", "; Written by tools/gen64_tests.py: change that, not this.",
                      '%include "elf.inc"']

    def e(self, text):
        self.lines.append("    " + text)

    def value(self):
        r = self.rng
        k = r.random()
        if k < 0.45:
            return r.choice(EDGES)
        if k < 0.6:
            return r.getrandbits(8) | r.choice([0, 0xFFFFFFFFFFFFFF00])
        return r.getrandbits(64)

    def load(self, i, v=None):
        v = self.value() if v is None else v
        self.e(f"mov {R64[i]}, 0x{v:X}")
        return v

    def regs(self, n):
        return self.rng.sample(FREE, n)

    def flags(self, always=False):
        if always or self.rng.random() < 0.3:
            self.e(f"FLAGS 0x{self.rng.choice(ARITH) | 0x202:X}")

    def write(self):
        self.lines += ["    EXIT", "    align 16", "buf: times 64 dq 0x0123456789ABCDEF", "file_end:"]
        path = os.path.join(os.path.dirname(__file__), "..", "tests", "asm64", self.name + ".asm")
        with open(path, "w") as f:
            f.write("\n".join(self.lines) + "\n")


def imm_for(t, w):
    r = t.rng
    if r.random() < 0.4:
        return r.choice([0, 1, -1, 0x7F, -0x80, 5])
    if w == 8:
        return r.randrange(-0x80, 0x80)
    if w == 16:
        return r.randrange(-0x8000, 0x8000)
    return r.choice([0x7FFFFFFF, -0x80000000, r.randrange(-0x80000000, 0x80000000)])


def gen_alu():
    t = Test("g_alu", "The eight arithmetic operations and TEST, INC, DEC, NEG and NOT, at every width and in every form.", 9101)
    for op in ["add", "or", "adc", "sbb", "and", "sub", "xor", "cmp", "test"]:
        for w in WIDTHS:
            for form in range(7):
                for _ in range(3):
                    d, s = t.regs(2)
                    t.load(d)
                    t.load(s)
                    t.flags()
                    if form == 0:
                        t.e(f"{op} {rn(d, w)}, {rn(s, w)}")
                    elif form == 1:
                        t.e(f"{op} {rn(d, w)}, {imm_for(t, w)}")
                    elif form == 2:
                        t.e(f"mov [buf + 8], {R64[s]}")
                        if op == "test":
                            t.e(f"test [buf + 8], {rn(d, w)}")
                        else:
                            t.e(f"{op} {rn(d, w)}, [buf + 8]")
                    elif form == 3:
                        t.e(f"mov [buf + 16], {R64[d]}")
                        t.e(f"{op} [buf + 16], {rn(s, w)}")
                        t.e(f"mov {R64[d]}, [buf + 16]")
                    elif form == 4:
                        t.e(f"mov [buf + 24], {R64[d]}")
                        t.e(f"{op} {SIZE[w]} [buf + 24], {imm_for(t, w)}")
                        t.e(f"mov {R64[s]}, [buf + 24]")
                    elif form == 5:
                        # The accumulator's short forms.
                        t.load(0)
                        t.e(f"{op} {rn(0, w)}, {imm_for(t, w)}")
                    elif w == 8:
                        # The high byte registers, which no REX prefix may go with.
                        a, b = t.rng.sample([0, 1, 2, 3], 2)
                        t.load(a)
                        t.load(b)
                        t.e(f"{op} {HIGH[a]}, {R8[b]}")
                        t.e(f"{op} {R8[a]}, {HIGH[b]}")
                    else:
                        t.e(f"{op} {rn(d, w)}, {rn(d, w)}")
    for op in ["inc", "dec", "neg", "not"]:
        for w in WIDTHS:
            for _ in range(6):
                d, = t.regs(1)
                t.load(d)
                t.flags(True)
                t.e(f"{op} {rn(d, w)}")
                t.e(f"mov [buf], {R64[d]}")
                t.e(f"{op} {SIZE[w]} [buf]")
                t.e(f"mov {R64[d]}, [buf]")
    t.write()


def gen_shift():
    t = Test("g_shift", "Shifts and rotates at every width, by a constant, by one and by CL, with counts past the width; SHLD and SHRD.", 9102)
    counts = [0, 1, 2, 3, 7, 8, 9, 15, 16, 17, 31, 32, 33, 63, 64, 65, 255]
    for op in ["rol", "ror", "rcl", "rcr", "shl", "shr", "sar"]:
        for w in WIDTHS:
            for n in counts:
                d, = [r for r in t.regs(2) if r != 1][:1]
                t.load(d)
                t.flags(True)
                t.e(f"{op} {rn(d, w)}, {n}")
                t.load(d)
                t.e(f"mov ecx, {n}")
                t.flags(True)
                t.e(f"{op} {rn(d, w)}, cl")
            t.load(0)
            t.e("mov [buf], rax")
            t.flags(True)
            t.e(f"{op} {SIZE[w]} [buf], 3")
            t.e("mov rax, [buf]")
            t.e("mov ecx, 5")
            t.flags(True)
            t.e(f"{op} {SIZE[w]} [buf], cl")
            t.e("mov rax, [buf]")
            t.flags(True)
            t.e(f"{op} {SIZE[w]} [buf], 1")
            t.e("mov rax, [buf]")
    for op in ["shld", "shrd"]:
        for w in [16, 32, 64]:
            for n in [0, 1, 2, 5, 15, 16, 17, 31, 32, 33, 63, 64]:
                d, s = [r for r in t.regs(3) if r != 1][:2]
                t.load(d)
                t.load(s)
                t.flags(True)
                t.e(f"{op} {rn(d, w)}, {rn(s, w)}, {n}")
                t.load(d)
                t.e(f"mov ecx, {n}")
                t.flags(True)
                t.e(f"{op} {rn(d, w)}, {rn(s, w)}, cl")
    t.write()


def gen_muldiv():
    t = Test("g_muldiv", "MUL, IMUL in its three forms, DIV and IDIV at every width.", 9103)
    r = t.rng
    for op in ["mul", "imul"]:
        for w in WIDTHS:
            for _ in range(14):
                s, = [x for x in t.regs(3) if x not in (0, 2)][:1]
                t.load(0)
                t.load(2)
                t.load(s)
                t.flags(True)
                t.e(f"{op} {rn(s, w)}")
    for w in [16, 32, 64]:
        for _ in range(14):
            d, s = t.regs(2)
            t.load(d)
            t.load(s)
            t.flags(True)
            t.e(f"imul {rn(d, w)}, {rn(s, w)}")
            t.load(s)
            t.flags(True)
            t.e(f"imul {rn(d, w)}, {rn(s, w)}, {imm_for(t, 8)}")
            t.e(f"mov [buf], {R64[s]}")
            t.flags(True)
            t.e(f"imul {rn(s, w)}, {SIZE[w]} [buf], {imm_for(t, w)}")
    for w in WIDTHS:
        m = (1 << w) - 1
        for _ in range(14):
            # Unsigned: a quotient that fits, by building the dividend from it.
            d = max(1, t.value() & m)
            q = t.value() & m
            rem = r.randrange(d)
            n = q * d + rem
            s, = [x for x in t.regs(3) if x not in (0, 2)][:1]
            if w == 8:
                t.load(0, n & 0xFFFF | r.getrandbits(48) << 16)
            else:
                t.load(0, n & m | (r.getrandbits(64 - w) << w if w < 64 else 0))
                t.load(2, n >> w | (r.getrandbits(64 - w) << w if w < 64 else 0))
            t.load(s, d | (r.getrandbits(64 - w) << w if w < 64 else 0))
            t.flags(True)
            t.e(f"div {rn(s, w)}")
        for _ in range(14):
            # Signed: sizes that fit, then signs.
            half = 1 << (w - 1)
            d = max(1, t.value() & (half - 1))
            q = t.value() & (half - 1)
            rem = r.randrange(d)
            n = q * d + rem
            if r.random() < 0.5:
                n = -n
            if r.random() < 0.5:
                d = -d
            n &= (1 << (2 * w)) - 1
            d &= m
            s, = [x for x in t.regs(3) if x not in (0, 2)][:1]
            if w == 8:
                t.load(0, n & 0xFFFF)
            else:
                t.load(0, n & m)
                t.load(2, n >> w)
            t.load(s, d)
            t.flags(True)
            t.e(f"idiv {rn(s, w)}")
    t.write()


def gen_bits():
    t = Test("g_bits", "BT, BTS, BTR and BTC on registers and memory, BSF, BSR, POPCNT, BSWAP, CMPXCHG, XADD, CMPXCHG8B and 16B.", 9104)
    r = t.rng
    for op in ["bt", "bts", "btr", "btc"]:
        for w in [16, 32, 64]:
            for _ in range(5):
                d, s = t.regs(2)
                t.load(d)
                t.load(s)
                t.flags(True)
                t.e(f"{op} {rn(d, w)}, {rn(s, w)}")
                t.flags(True)
                t.e(f"{op} {rn(d, w)}, {r.choice([0, 1, 7, 15, 16, 31, 32, 63, 64, 200])}")
                # In memory a register's bit number is signed and reaches outside the operand.
                t.load(s, r.randrange(-1000, 1000) & 0xFFFFFFFFFFFFFFFF)
                t.flags(True)
                t.e(f"{op} [buf + 256], {rn(s, w)}")
                t.e(f"{op} {SIZE[w]} [buf + 256], {r.randrange(256)}")
            t.e("mov rsi, [buf + 248]")
            t.e("mov rdi, [buf + 256]")
    for op in ["bsf", "bsr", "popcnt", "tzcnt", "lzcnt"]:
        for w in [16, 32, 64]:
            for v in [0, 1, 0x8000, 0x80000000, 0x8000000000000000, None, None, None]:
                d, s = t.regs(2)
                t.load(d)
                t.load(s, v)
                t.flags(True)
                t.e(f"{op} {rn(d, w)}, {rn(s, w)}")
    for w in [32, 64]:
        for _ in range(4):
            d, = t.regs(1)
            t.load(d)
            t.e(f"bswap {rn(d, w)}")
    for w in WIDTHS:
        for same in [True, False, True, False]:
            d, s = [x for x in t.regs(3) if x != 0][:2]
            v = t.load(d)
            t.load(s)
            t.load(0, v if same else t.value())
            t.flags(True)
            t.e(f"cmpxchg {rn(d, w)}, {rn(s, w)}")
            t.e(f"mov [buf], {R64[d]}")
            t.flags(True)
            t.e(f"lock cmpxchg [buf], {rn(s, w)}")
            t.e(f"mov {R64[d]}, [buf]")
            t.load(d)
            t.flags(True)
            t.e(f"xadd {rn(d, w)}, {rn(s, w)}")
            t.e(f"xadd [buf], {rn(s, w)}")
            t.e(f"mov {R64[d]}, [buf]")
    for wide in [False, True]:
        for same in [True, False]:
            a, d = t.value(), t.value()
            t.load(0, a)
            t.load(2, d)
            t.load(3)
            t.load(1)
            t.e(f"mov rsi, 0x{a if same else a ^ 0x100000000:X}")
            t.e(f"mov rdi, 0x{d:X}")
            if wide:
                t.e("mov [buf + 32], rsi")
                t.e("mov [buf + 40], rdi")
                t.flags(True)
                t.e("cmpxchg16b [buf + 32]")
            else:
                t.e("mov [buf + 32], esi")
                t.e("mov [buf + 36], edi")
                t.e("mov eax, eax")
                t.e("mov edx, edx")
                t.flags(True)
                t.e("cmpxchg8b [buf + 32]")
            t.e("mov rsi, [buf + 32]")
            t.e("mov rdi, [buf + 40]")
    t.write()


CC = ["o", "no", "b", "ae", "e", "ne", "be", "a", "s", "ns", "p", "np", "l", "ge", "le", "g"]


def gen_cond():
    t = Test("g_cond", "The sixteen conditions in Jcc (both lengths), SETcc and CMOVcc, under a dozen settings of the flags.", 9105)
    k = 0
    for f in ARITH:
        t.load(3)
        t.load(6)
        for cc in CC:
            k += 1
            if k % 4 == 1:
                t.load(9, t.rng.getrandbits(64) | 1 << 63)
            t.e(f"FLAGS 0x{f | 0x202:X}")
            t.e(f"set{cc} dl")
            t.e(f"cmov{cc} rax, rbx")
            t.e(f"cmov{cc} r9d, esi")
            t.e(f"cmov{cc} r10w, si")
            t.e(f"j{cc} short .s{k}")
            t.e("inc r12")
            t.lines.append(f".s{k}:")
            t.e(f"j{cc} near .n{k}")
            t.e("inc r13")
            t.lines.append(f".n{k}:")
    t.e("mov [buf], rbx")
    for cc in ["e", "ne", "l", "a"]:
        t.e("FLAGS 0x246")
        t.e(f"cmov{cc} r14d, [buf]")
        t.e(f"set{cc} byte [buf + 8]")
        t.e("FLAGS 0x202")
        t.e(f"cmov{cc} r15, [buf]")
        t.e(f"set{cc} byte [buf + 9]")
    t.e("mov rax, [buf + 8]")
    t.write()


def gen_mov():
    t = Test("g_mov", "MOV in its forms, MOVZX, MOVSX, MOVSXD, XCHG, the sign extensions of A, LAHF and SAHF, and every way of writing an address.", 9106)
    r = t.rng
    for w in WIDTHS:
        for _ in range(4):
            d, s = t.regs(2)
            t.load(d)
            t.load(s)
            t.e(f"mov {rn(d, w)}, {rn(s, w)}")
            t.e(f"mov [buf], {rn(s, w)}")
            t.e(f"mov {rn(d, w)}, [buf + 8]")
            t.e(f"mov {SIZE[w]} [buf + 16], {imm_for(t, w)}")
            t.e(f"mov {rn(s, w)}, {imm_for(t, w) & ((1 << min(w, 32)) - 1)}")
            t.e(f"xchg {rn(d, w)}, {rn(s, w)}")
            t.e(f"xchg [buf + 24], {rn(s, w)}")
            t.e(f"xchg {rn(0, w)}, {rn(d, w)}")
            t.e("mov rsi, [buf]")
            t.e("mov rdi, [buf + 16]")
            t.e("mov rbp, [buf + 24]")
    for a, b in [(0, 3), (1, 2), (3, 0), (2, 1)]:
        t.load(a)
        t.load(b)
        t.e(f"mov {HIGH[a]}, {HIGH[b]}")
        t.e(f"mov {HIGH[b]}, {R8[a]}")
        t.e(f"mov [buf + 1], {HIGH[a]}")
        t.e(f"mov {HIGH[b]}, [buf + 2]")
        t.e(f"movzx esi, {HIGH[a]}")
        t.e(f"movsx di, {HIGH[b]}")
        t.e(f"xchg {HIGH[a]}, {R8[b]}")
    # The accumulator and a 64-bit address in the instruction.
    t.load(0)
    t.e("mov [abs qword buf + 32], al")
    t.e("mov [abs qword buf + 34], ax")
    t.e("mov [abs qword buf + 36], eax")
    t.e("mov [abs qword buf + 40], rax")
    t.load(0)
    t.e("mov al, [abs qword buf + 41]")
    t.e("mov ax, [abs qword buf + 42]")
    t.e("mov eax, [abs qword buf + 44]")
    t.e("mov rax, [abs qword buf + 33]")
    for src in [8, 16]:
        for dst in [16, 32, 64]:
            if dst <= src:
                continue
            for _ in range(4):
                d, s = t.regs(2)
                t.load(d)
                t.load(s)
                t.e(f"movzx {rn(d, dst)}, {rn(s, src)}")
                t.load(d)
                t.e(f"movsx {rn(d, dst)}, {rn(s, src)}")
                t.e(f"mov [buf], {R64[s]}")
                t.e(f"movzx {rn(d, dst)}, {SIZE[src]} [buf]")
                t.e(f"movsx {rn(s, dst)}, {SIZE[src]} [buf + 1]")
    for _ in range(6):
        d, s = t.regs(2)
        t.load(d)
        t.load(s)
        t.e(f"movsxd {R64[d]}, {R32[s]}")
        t.e(f"mov [buf], {R64[s]}")
        t.e(f"movsxd {R64[s]}, dword [buf + 2]")
    for v in [0x7F, 0x80, 0x7FFF, 0x8000, 0x7FFFFFFF, 0x80000000, None, None]:
        for op in ["cbw", "cwde", "cdqe", "cwd", "cdq", "cqo"]:
            t.load(0, v)
            t.load(2)
            t.e(op)
    for f in ARITH:
        t.load(0)
        t.e(f"FLAGS 0x{f | 0x202:X}")
        t.e("lahf")
        t.e(f"mov ah, 0x{r.getrandbits(8):X}")
        t.e("sahf")
    t.e("nop")
    t.e("pause")
    t.e("xchg r8, rax")
    t.e("xchg eax, r8d")
    t.e("o16 nop")
    t.e("nop dword [rax + rax * 1 + 0]")
    t.e("prefetchnta [buf]")
    # Addresses. LEA shows the address itself; a load through it, that it is used.
    t.e("lea rbx, [buf + 128]")
    t.e("mov rbp, rbx")
    t.e("mov r12, rbx")
    t.e("mov r13, rbx")
    t.e("mov ecx, 3")
    t.e("mov rsi, -2")
    t.e("mov r14, 5")
    t.e("mov r9, 1")
    modes = ["rbx", "rbp", "r12", "r13", "rbx + 8", "rbp - 8", "r12 + 0x80", "r13 - 0x81", "rsp", "rsp + 8",
             "rsp + 0x100", "rbx + rcx", "rbx + rcx * 2", "rbx + rcx * 4 + 4", "rbx + rcx * 8 - 0x90",
             "rbp + rsi * 8", "rbp + rsi * 4 + 0x7F", "r13 + r14 * 2", "r13 + r14 * 8 + 0x12345", "r12 + r9 * 4",
             "r12 + r12", "rsp + rcx * 4", "rsp + r14 * 8 + 16", "rcx * 4 + 0x500000", "r14 * 8 + 0x500000",
             "rel buf", "rel buf + 0x40", "abs 0x500000", "rbx + rsi", "r12 + rsi * 2 - 1"]
    for m in modes:
        t.e(f"lea rax, [{m}]")
        t.e(f"lea edx, [{m}]")
        t.e(f"lea di, [{m}]")
        if not m.startswith("rsp") and m != "r12 + r12":
            t.e(f"mov r10, [{m}]")
            t.e(f"add byte [{m}], 0x11")
    # The same with 32-bit addresses (the prefix 67h): the sum is cut to 32 bits.
    t.e("mov r15, 0xFFFFFFFF00000000")
    t.e("or rbx, r15")
    t.e("or r12, r15")
    for m in ["ebx", "ebx + ecx * 4 + 4", "r12d + r9d * 8", "ebx + esi", "ecx * 8 + 0x500000", "esi + 0x500002"]:
        t.e(f"lea rax, [{m}]")
        t.e(f"lea edx, [{m}]")
        t.e(f"mov r10, [{m}]")
    t.write()


def gen_stack():
    t = Test("g_stack", "PUSH and POP in their forms, PUSHF and POPF, CALL, RET, the jumps through registers and memory, LOOP, JRCXZ and LEAVE.", 9107)
    r = t.rng
    for i in FREE:
        t.load(i)
    for i in FREE:
        t.e(f"push {R64[i]}")
    for i in r.sample(FREE, len(FREE)):
        t.e(f"pop {R64[i]}")
    for i in [0, 3, 9, 14]:
        t.e(f"push {R16[i]}")
        t.e(f"pop {R16[(i + 5) % 16 if (i + 5) % 16 != 4 else 6]}")
    t.e("push 0x7F")
    t.e("push -0x80")
    t.e("push 0x12345678")
    t.e("push -0x12345678")
    t.e("push word 0x1234")
    t.e("push word -2")
    t.e("pop ax")
    t.e("pop bx")
    t.e("pop rax")
    t.e("pop rbx")
    t.e("pop rcx")
    t.e("pop rdx")
    t.e("push rsp")
    t.e("pop rax")
    t.e("push qword [buf]")
    t.e("pop qword [buf + 8]")
    t.e("push word [buf + 3]")
    t.e("pop word [buf + 17]")
    t.e("mov rsi, [buf + 8]")
    t.e("mov rdi, [buf + 16]")
    # POP to an address made from RSP uses RSP as it is after the pop.
    t.e("push 0x55")
    t.e("push 0x66")
    t.e("pop qword [rsp]")
    t.e("pop rax")
    t.e("mov rax, rsp")
    t.e("push 0x77")
    t.e("pop rsp")
    t.e("mov rsp, rax")
    for f in [0x202, 0x8D5 | 0x202, 0x400 | 0x202, 0x40000 | 0x202, 0x200000 | 0x202, 0x202 | 0x4000]:
        t.e(f"mov rax, 0x{f:X}")
        t.e("push rax")
        t.e("popfq")
        t.e("pushfq")
        t.e("pop rbx")
    t.e("mov rax, 0xFFFFFFFFFFFF08D5")
    t.e("push rax")
    t.e("popfw")
    t.e("pushfw")
    t.e("pop cx")
    t.e("FLAGS 0x202")
    t.e("stc")
    t.e("cmc")
    t.e("cmc")
    t.e("clc")
    t.e("std")
    t.e("cld")
    # Calls.
    t.e("jmp over")
    t.lines += ["f1:", "    inc r8", "    ret",
                "f2:", "    call f1", "    inc r9", "    ret 16",
                "f3:", "    push rbp", "    mov rbp, rsp", "    sub rsp, 32", "    mov [rbp - 8], r8", "    leave", "    ret",
                "over:"]
    t.e("call f1")
    t.e("push 1")
    t.e("push 2")
    t.e("call f2")
    t.e("call f3")
    t.e("lea rax, [f1]")
    t.e("call rax")
    t.e("mov [buf], rax")
    t.e("call [buf]")
    t.e("lea r11, [f3]")
    t.e("call r11")
    t.e("lea rax, [.j1]")
    t.e("jmp rax")
    t.e("inc r10")
    t.lines.append(".j1:")
    t.e("lea rcx, [.j2]")
    t.e("mov [buf + 8], rcx")
    t.e("jmp [buf + 8]")
    t.e("inc r10")
    t.lines.append(".j2:")
    t.e("jmp short .j3")
    t.e("inc r10")
    t.lines.append(".j3:")
    t.e("jmp near .j4")
    t.e("inc r10")
    t.lines.append(".j4:")
    # LOOP and its kin.
    t.e("mov ecx, 3")
    t.lines.append(".l1:")
    t.e("inc r12")
    t.e("loop .l1")
    t.e("mov rcx, 5")
    t.e("xor eax, eax")
    t.lines.append(".l2:")
    t.e("inc eax")
    t.e("cmp eax, 3")
    t.e("loopne .l2")
    t.e("mov rcx, 5")
    t.lines.append(".l3:")
    t.e("cmp rcx, rcx")
    t.e("loope .l3")
    t.e("mov rcx, 4")
    t.lines.append(".l4:")
    t.e("cmp rcx, 2")
    t.e("loope .l4")
    t.e("xor ecx, ecx")
    t.e("jrcxz .l5")
    t.e("inc r13")
    t.lines.append(".l5:")
    t.e("mov rcx, 0x100000000")
    t.e("jrcxz .l6")
    t.e("inc r13")
    t.lines.append(".l6:")
    t.e("jecxz .l7")
    t.e("inc r14")
    t.lines.append(".l7:")
    t.e("mov rcx, 0xFFFFFFFF00000002")
    t.lines.append(".l8:")
    t.e("inc r15")
    t.e("a32 loop .l8")
    t.write()


def gen_string():
    t = Test("g_string", "MOVS, STOS, LODS, CMPS and SCAS at every width, forward and backward, alone and with the REP prefixes.", 9108)
    names = {8: "b", 16: "w", 32: "d", 64: "q"}
    for df in [False, True]:
        for w in WIDTHS:
            n = names[w]
            t.e("std" if df else "cld")
            t.e("lea rsi, [buf + 64]")
            t.e("lea rdi, [buf + 256]")
            t.load(0)
            t.e(f"movs{n}")
            t.e(f"stos{n}")
            t.e(f"lods{n}")
            t.e(f"cmps{n}")
            t.e(f"scas{n}")
            t.e("mov ecx, 3")
            t.e(f"rep movs{n}")
            t.e("mov ecx, 3")
            t.e(f"rep stos{n}")
            t.e("mov ecx, 2")
            t.e(f"rep lods{n}")
            t.e("xor ecx, ecx")
            t.e(f"rep movs{n}")
            t.e(f"repe cmps{n}")
            # Compare what was just made equal, then run into a difference.
            t.e("lea rsi, [buf + 128]")
            t.e("lea rdi, [buf + 192]")
            t.e("mov ecx, 4")
            t.e(f"repe cmps{n}")
            t.e("lea rsi, [buf + 128]")
            t.e("lea rdi, [buf + 256]")
            t.e("mov ecx, 4")
            t.e(f"repne cmps{n}")
            t.e("lea rsi, [buf + 128]")
            t.e("lea rdi, [buf + 256]")
            t.e("mov ecx, 4")
            t.e(f"repe cmps{n}")
            t.e("lea rdi, [buf + 256]")
            t.e("mov rax, [buf + 256]")
            t.e("mov ecx, 5")
            t.e(f"repe scas{n}")
            t.e("lea rdi, [buf + 256]")
            t.e("mov ecx, 5")
            t.e(f"repne scas{n}")
            t.e("not rax")
            t.e("mov ecx, 3")
            t.e(f"repne scas{n}")
            t.e("mov r8, [buf + 256]")
            t.e("mov r9, [buf + 264]")
            t.e("mov r10, [buf + 248]")
    t.e("cld")
    # With 32-bit addresses the three registers are used, and left, as 32 bits.
    t.e("mov r15, 0xFFFFFFFF00000000")
    t.e("lea rsi, [buf + 64]")
    t.e("lea rdi, [buf + 256]")
    t.e("or rsi, r15")
    t.e("or rdi, r15")
    t.e("mov rcx, r15")
    t.e("or rcx, 3")
    t.e("a32 rep movsb")
    t.e("or rdi, r15")
    t.e("a32 stosd")
    t.e("or rsi, r15")
    t.e("a32 lodsw")
    t.write()


def main():
    gen_mov()
    gen_stack()
    gen_string()
    gen_alu()
    gen_shift()
    gen_muldiv()
    gen_bits()
    gen_cond()


main()
