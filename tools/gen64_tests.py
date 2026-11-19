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


# ---- SSE and SSE2 (E093): traced with the XMM registers ----

import struct


def f32(x):
    return struct.unpack("<I", struct.pack("<f", x))[0]


def f64(x):
    return struct.unpack("<Q", struct.pack("<d", x))[0]


SINGLES = [f32(x) for x in [0.0, 1.0, -1.0, 0.5, 1.5, 2.5, -2.5, 3.0, 0.1, 1e10, -1e10, 1e-10, 3.4e38, 1e-38,
                            2147483520.0, 2147483648.0, -2147483648.0, 4294967296.0, 16777217.0, 123456.789,
                            9.2233720368547758e18, -9.2233720368547758e18, 0.49999997, -0.5, 7.5, -7.5]] + [
    0x80000000, 0x7F800000, 0xFF800000, 0x7FC00000, 0xFFC00000, 0x7FA00001, 0xFF800123, 0x7FC12345,
    0x00000001, 0x007FFFFF, 0x00800000, 0x80000001, 0x7F7FFFFF]
DOUBLES = [f64(x) for x in [0.0, 1.0, -1.0, 0.5, 1.5, 2.5, -2.5, 3.0, 0.1, 1e10, -1e10, 1e-10, 1.7e308, 1e-308,
                            2147483647.0, 2147483647.5, 2147483648.0, -2147483648.0, -2147483648.5, 4294967296.0,
                            9007199254740993.0, 9.2233720368547758e18, -9.2233720368547758e18, 1e19,
                            123456.789, 0.49999999999999994, -0.5, 7.5, -7.5, 3.4028235677973366e38, 1e-46]] + [
    0x8000000000000000, 0x7FF0000000000000, 0xFFF0000000000000, 0x7FF8000000000000, 0xFFF8000000000000,
    0x7FF4000000000001, 0xFFF0000000000123, 0x7FF8000012345678, 0x0000000000000001, 0x000FFFFFFFFFFFFF,
    0x0010000000000000, 0x7FEFFFFFFFFFFFFF]
LANES = {8: [0, 1, 0x7F, 0x80, 0x81, 0xFF, 0x40], 16: [0, 1, 0x7FFF, 0x8000, 0x8001, 0xFFFF, 0x00FF, 0x0100],
         32: [0, 1, 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF, 0x0000FFFF, 0x00010000],
         64: [0, 1, 0x7FFFFFFFFFFFFFFF, 0x8000000000000000, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFF, 0x100000000]}


class XTest(Test):
    """A test with 128-bit constants in a table after the code."""

    def __init__(self, name, what, seed):
        super().__init__(name, what, seed)
        self.consts = []

    def const(self, lo, hi):
        self.consts.append((lo, hi))
        return f"c{len(self.consts) - 1}"

    def ints(self, w=None):
        """128 bits of lanes w wide (any width if not given), edges and random ones."""
        r = self.rng
        w = w or r.choice([8, 16, 32, 64])
        v = 0
        for i in range(128 // w):
            lane = r.choice(LANES[w]) if r.random() < 0.6 else r.getrandbits(w)
            v |= lane << (i * w)
        return v & (1 << 64) - 1, v >> 64

    def singles(self):
        r = self.rng
        l = [r.choice(SINGLES) if r.random() < 0.8 else f32(r.uniform(-1000, 1000)) for _ in range(4)]
        return l[0] | l[1] << 32, l[2] | l[3] << 32

    def doubles(self):
        r = self.rng
        l = [r.choice(DOUBLES) if r.random() < 0.8 else f64(r.uniform(-1000, 1000)) for _ in range(2)]
        return l[0], l[1]

    def xload(self, i, lo, hi):
        self.e(f"movdqu xmm{i}, [{self.const(lo, hi)}]")

    def xregs(self, n):
        return self.rng.sample(range(16), n)

    def write(self):
        self.lines += ["    EXIT", "    align 16"]
        for i, (lo, hi) in enumerate(self.consts):
            self.lines.append(f"c{i}: dq 0x{lo:X}, 0x{hi:X}")
        self.lines += ["buf: times 64 dq 0x0123456789ABCDEF", "file_end:"]
        path = os.path.join(os.path.dirname(__file__), "..", "tests", "asm64", self.name + ".asm")
        with open(path, "w") as f:
            f.write("\n".join(self.lines) + "\n")


def gen_xmove():
    t = XTest("x_move", "The moves of SSE and SSE2 between XMM registers, memory and general registers; shuffles and unpacking.", 9301)
    r = t.rng
    for op in ["movaps", "movups", "movapd", "movupd", "movdqa", "movdqu"]:
        for _ in range(3):
            a, b = t.xregs(2)
            t.xload(a, *t.ints())
            t.e(f"{op} xmm{b}, xmm{a}")
            t.e(f"{op} [buf + 32], xmm{b}")
            t.xload(a, *t.ints())
            t.e(f"{op} xmm{a}, [buf + 32]")
    for op, size in [("movss", "dword"), ("movsd", "qword")]:
        for _ in range(4):
            a, b = t.xregs(2)
            t.xload(a, *t.ints())
            t.xload(b, *t.ints())
            t.e(f"{op} xmm{b}, xmm{a}")
            t.e(f"{op} [buf + 8], xmm{b}")
            t.e(f"{op} xmm{a}, [buf + 16]")
            t.e("mov rax, [buf + 8]")
    for _ in range(4):
        a, b = t.xregs(2)
        g, h = t.regs(2)
        t.xload(a, *t.ints())
        t.load(g)
        t.load(h)
        t.e(f"movd {R32[g]}, xmm{a}")
        t.e(f"movq {R64[h]}, xmm{a}")
        t.load(g)
        t.e(f"movd xmm{b}, {R32[g]}")
        t.e(f"movq xmm{a}, {R64[g]}")
        t.e(f"movd [buf], xmm{b}")
        t.e(f"movq [buf + 8], xmm{a}")
        t.xload(a, *t.ints())
        t.e(f"movd xmm{a}, dword [buf + 8]")
        t.e(f"movq xmm{b}, qword [buf + 8]")
        t.xload(b, *t.ints())
        t.e(f"movq xmm{b}, xmm{a}")
        t.e("mov rax, [buf]")
        t.e("mov rdx, [buf + 8]")
    for op in ["movlps", "movhps", "movlpd", "movhpd"]:
        a, = t.xregs(1)
        t.xload(a, *t.ints())
        t.e(f"{op} [buf + 24], xmm{a}")
        t.e(f"{op} xmm{a}, [buf + 40]")
        t.e("mov rax, [buf + 24]")
    for op in ["movhlps", "movlhps", "unpcklps", "unpckhps", "unpcklpd", "unpckhpd"]:
        for _ in range(2):
            a, b = t.xregs(2)
            t.xload(a, *t.ints())
            t.xload(b, *t.ints())
            t.e(f"{op} xmm{a}, xmm{b}")
            if op.startswith("unpck"):
                t.e(f"{op} xmm{b}, [{t.const(*t.ints())}]")
    for op in ["movntps", "movntpd", "movntdq"]:
        a, = t.xregs(1)
        t.xload(a, *t.ints())
        t.e(f"{op} [buf + 48], xmm{a}")
        t.e("mov rax, [buf + 48]")
        t.e("mov rdx, [buf + 56]")
    t.load(3)
    t.e("movnti [buf + 64], ebx")
    t.e("movnti [buf + 72], rbx")
    t.e("mov rax, [buf + 64]")
    t.e("mov rdx, [buf + 72]")
    for _ in range(6):
        a, = t.xregs(1)
        g, = t.regs(1)
        t.xload(a, *t.ints())
        t.load(g)
        t.e(f"movmskps {R32[g]}, xmm{a}")
        t.load(g)
        t.e(f"movmskpd {R32[g]}, xmm{a}")
        t.load(g)
        t.e(f"pmovmskb {R32[g]}, xmm{a}")
        t.e(f"pextrw {R32[g]}, xmm{a}, {r.randrange(8)}")
        t.load(g)
        t.e(f"pinsrw xmm{a}, {R32[g]}, {r.randrange(8)}")
        t.e(f"pinsrw xmm{a}, word [buf + 1], {r.randrange(8)}")
    for op in ["shufps", "shufpd", "pshufd", "pshufhw", "pshuflw"]:
        for _ in range(5):
            a, b = t.xregs(2)
            t.xload(a, *t.ints())
            t.xload(b, *t.ints())
            t.e(f"{op} xmm{a}, xmm{b}, 0x{r.getrandbits(8):X}")
            t.e(f"{op} xmm{b}, [{t.const(*t.ints())}], 0x{r.getrandbits(8):X}")
    for _ in range(3):
        a, b = t.xregs(2)
        t.xload(a, *t.ints())
        t.xload(b, *t.ints(8))
        t.e("lea rdi, [buf + 96]")
        t.e(f"maskmovdqu xmm{a}, xmm{b}")
        t.e("mov rax, [buf + 96]")
        t.e("mov rdx, [buf + 104]")
    t.e("lfence")
    t.e("mfence")
    t.e("sfence")
    t.e("prefetcht0 [buf]")
    t.write()


PINT = {8: ["paddb", "psubb", "paddsb", "paddusb", "psubsb", "psubusb", "pcmpeqb", "pcmpgtb", "pavgb", "pminub",
            "pmaxub", "psadbw", "punpcklbw", "punpckhbw"],
        16: ["paddw", "psubw", "paddsw", "paddusw", "psubsw", "psubusw", "pcmpeqw", "pcmpgtw", "pavgw", "pminsw",
             "pmaxsw", "pmullw", "pmulhw", "pmulhuw", "pmaddwd", "punpcklwd", "punpckhwd", "packsswb", "packuswb"],
        32: ["paddd", "psubd", "pcmpeqd", "pcmpgtd", "pmuludq", "punpckldq", "punpckhdq", "packssdw"],
        64: ["paddq", "psubq", "pand", "pandn", "por", "pxor", "punpcklqdq", "punpckhqdq"]}


def gen_xint():
    t = XTest("x_int", "The packed integer instructions of SSE2 on XMM registers: arithmetic, comparisons, packing, unpacking, shifts.", 9302)
    r = t.rng
    for w, ops in PINT.items():
        for op in ops:
            for _ in range(4):
                a, b = t.xregs(2)
                t.xload(a, *t.ints(w))
                t.xload(b, *t.ints(w))
                t.e(f"{op} xmm{a}, xmm{b}")
                t.e(f"{op} xmm{b}, [{t.const(*t.ints(w))}]")
            a, = t.xregs(1)
            t.xload(a, *t.ints(w))
            t.e(f"{op} xmm{a}, xmm{a}")
    for op, w in [("psrlw", 16), ("psrld", 32), ("psrlq", 64), ("psraw", 16), ("psrad", 32),
                  ("psllw", 16), ("pslld", 32), ("psllq", 64)]:
        for n in [0, 1, 3, w // 2, w - 1, w, w + 1, 200]:
            a, b = t.xregs(2)
            t.xload(a, *t.ints(w))
            t.e(f"{op} xmm{a}, {n}")
            t.xload(a, *t.ints(w))
            t.xload(b, n, r.getrandbits(64))
            t.e(f"{op} xmm{a}, xmm{b}")
        a, b = t.xregs(2)
        t.xload(a, *t.ints(w))
        t.xload(b, 1 << 40, 0)
        t.e(f"{op} xmm{a}, xmm{b}")
        t.e(f"{op} xmm{a}, [{t.const(3, 0)}]")
    for op in ["psrldq", "pslldq"]:
        for n in [0, 1, 3, 7, 8, 9, 15, 16, 200]:
            a, = t.xregs(1)
            t.xload(a, *t.ints())
            t.e(f"{op} xmm{a}, {n}")
    t.write()


def gen_xfloat():
    t = XTest("x_float", "The floating-point instructions of SSE and SSE2: arithmetic, comparisons, and the conversions, with numbers, zeros, infinities, denormals and NaNs.", 9303)
    r = t.rng
    for op in ["add", "sub", "mul", "div", "min", "max", "sqrt"]:
        for kind in ["ps", "pd", "ss", "sd"]:
            for _ in range(10):
                a, b = t.xregs(2)
                gen = t.singles if kind[1] == "s" else t.doubles
                t.xload(a, *gen())
                t.xload(b, *gen())
                t.e(f"{op}{kind} xmm{a}, xmm{b}")
                size = "" if kind[0] == "p" else ("dword " if kind == "ss" else "qword ")
                t.e(f"{op}{kind} xmm{b}, {size}[{t.const(*gen())}]")
    for op in ["and", "andn", "or", "xor"]:
        for kind in ["ps", "pd"]:
            a, b = t.xregs(2)
            t.xload(a, *t.ints())
            t.xload(b, *t.ints())
            t.e(f"{op}{kind} xmm{a}, xmm{b}")
            t.e(f"{op}{kind} xmm{b}, [{t.const(*t.ints())}]")
    for kind in ["ps", "pd", "ss", "sd"]:
        for pred in range(8):
            for _ in range(3):
                a, b = t.xregs(2)
                gen = t.singles if kind[1] == "s" else t.doubles
                x = gen()
                t.xload(a, *x)
                t.xload(b, *(x if r.random() < 0.25 else gen()))
                t.e(f"cmp{kind} xmm{a}, xmm{b}, {pred}")
    for op in ["comiss", "ucomiss", "comisd", "ucomisd"]:
        for _ in range(16):
            a, b = t.xregs(2)
            gen = t.singles if op.endswith("ss") else t.doubles
            x = gen()
            t.xload(a, *x)
            t.xload(b, *(x if r.random() < 0.25 else gen()))
            t.flags(True)
            t.e(f"{op} xmm{a}, xmm{b}")
            t.flags(True)
            t.e(f"{op} xmm{b}, [{t.const(*gen())}]")
    # Conversions, under each rounding mode of MXCSR (to nearest, down, up, toward zero).
    for rc in [0, 1, 2, 3]:
        t.e(f"mov dword [buf], 0x{0x1F80 | rc << 13:X}")
        t.e("ldmxcsr [buf]")
        t.e("stmxcsr [buf + 4]")
        t.e("mov eax, [buf + 4]")
        for _ in range(8):
            a, b = t.xregs(2)
            g, = t.regs(1)
            t.xload(a, *t.singles())
            t.xload(b, *t.doubles())
            for op, x in [("cvtss2si", a), ("cvttss2si", a), ("cvtsd2si", b), ("cvttsd2si", b)]:
                t.e(f"{op} {R32[g]}, xmm{x}")
                t.e(f"{op} {R64[g]}, xmm{x}")
            t.e(f"cvtsd2si {R64[g]}, qword [{t.const(*t.doubles())}]")
            t.e(f"cvtss2si {R32[g]}, dword [{t.const(*t.singles())}]")
        for op, gen in [("cvtps2dq", t.singles), ("cvttps2dq", t.singles), ("cvtpd2dq", t.doubles), ("cvttpd2dq", t.doubles)]:
            for _ in range(5):
                a, b = t.xregs(2)
                t.xload(a, *gen())
                t.xload(b, *t.ints())
                t.e(f"{op} xmm{b}, xmm{a}")
                t.e(f"{op} xmm{a}, [{t.const(*gen())}]")
    t.e("mov dword [buf], 0x1F80")
    t.e("ldmxcsr [buf]")
    for _ in range(12):
        a, = t.xregs(1)
        g, = t.regs(1)
        t.xload(a, *t.ints())
        t.load(g)
        t.e(f"cvtsi2ss xmm{a}, {R32[g]}")
        t.e(f"cvtsi2sd xmm{a}, {R32[g]}")
        t.xload(a, *t.ints())
        t.e(f"cvtsi2ss xmm{a}, {R64[g]}")
        t.e(f"cvtsi2sd xmm{a}, {R64[g]}")
        t.e(f"mov [buf + 8], {R64[g]}")
        t.e(f"cvtsi2sd xmm{a}, qword [buf + 8]")
        t.e(f"cvtsi2ss xmm{a}, dword [buf + 8]")
    # The integers that a single cannot hold: where the rounding falls.
    for v in [0x1000001, 0x1000003, 0x7FFFFFFFFFFFFFFF, 0x8000000000000001, 0x20000040000001, 0x20000040000000,
              0x200000C0000000, 0xFFFFFF7FFFFFFFFF, 0x40000080000001, 0x7FFFFFBFFFFFFFFF, 0x7FFFFFC000000000]:
        t.load(0, v)
        t.e("cvtsi2ss xmm1, rax")
        t.e("cvtsi2sd xmm2, rax")
        t.e("neg rax")
        t.e("cvtsi2ss xmm3, rax")
    for op, gen in [("cvtss2sd", t.singles), ("cvtsd2ss", t.doubles), ("cvtps2pd", t.singles), ("cvtpd2ps", t.doubles),
                    ("cvtdq2ps", lambda: t.ints(32)), ("cvtdq2pd", lambda: t.ints(32))]:
        for _ in range(10):
            a, b = t.xregs(2)
            t.xload(a, *gen())
            t.xload(b, *t.ints())
            t.e(f"{op} xmm{b}, xmm{a}")
            size = {"cvtss2sd": "dword ", "cvtsd2ss": "qword ", "cvtps2pd": "qword ", "cvtdq2pd": "qword "}.get(op, "")
            t.e(f"{op} xmm{a}, {size}[{t.const(*gen())}]")
    # Cases the random ones did not reach (each is a wrong build that passed without it).
    # The smaller and the larger of equal operands, which is to say of the two zeros.
    pz, nz, one, nan = f64(0.0), f64(-0.0), f64(1.0), 0x7FF8000000000000
    spz, snz, sone, snan = f32(0.0), f32(-0.0), f32(1.0), 0x7FC00000
    for op in ["min", "max"]:
        for x, y in [(pz, nz), (nz, pz), (one, one)]:
            t.xload(1, x, y)
            t.xload(9, y, x)
            t.e(f"{op}pd xmm1, xmm9")
            t.xload(1, x, y)
            t.e(f"{op}sd xmm1, xmm9")
        for x, y in [(spz, snz), (snz, spz), (sone, sone)]:
            t.xload(2, x | y << 32, y | x << 32)
            t.xload(10, y | x << 32, x | y << 32)
            t.e(f"{op}ps xmm2, xmm10")
            t.xload(2, x | y << 32, y | x << 32)
            t.e(f"{op}ss xmm2, xmm10")
    # Every predicate with a NaN on either side, with equal numbers and with unequal ones.
    for pred in range(8):
        t.xload(3, nan, one)
        t.xload(11, one, nan)
        t.e(f"cmppd xmm3, xmm11, {pred}")
        t.xload(3, one, f64(2.0))
        t.xload(11, one, one)
        t.e(f"cmppd xmm3, xmm11, {pred}")
        t.xload(3, nan, 0)
        t.e(f"cmpsd xmm3, xmm11, {pred}")
        t.xload(4, snan | sone << 32, sone | f32(2.0) << 32)
        t.xload(12, sone | snan << 32, sone | sone << 32)
        t.e(f"cmpps xmm4, xmm12, {pred}")
        t.xload(4, sone, 0)
        t.xload(12, snan, 0)
        t.e(f"cmpss xmm4, xmm12, {pred}")
    # An integer whose lowest bit alone decides which way its single rounds.
    for v in [0x40000040000001, 0x40000040000000, 0x400000C0000001, 0x4000004000000400]:
        t.load(0, v)
        t.e("cvtsi2ss xmm5, rax")
        t.e("neg rax")
        t.e("cvtsi2ss xmm6, rax")
    t.write()


def main():
    gen_xmove()
    gen_xint()
    gen_xfloat()
    gen_mov()
    gen_stack()
    gen_string()
    gen_alu()
    gen_shift()
    gen_muldiv()
    gen_bits()
    gen_cond()


main()
