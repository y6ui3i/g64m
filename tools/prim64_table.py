#!/usr/bin/env python3
"""The table of the primitive programs (E112): for each of tests/prim64/p_*.elf, the guest
instructions it runs, the host instructions for each, the share the short front runs, and
the instructions that go to the rest of the CPU.

The host's instructions are read from /usr/bin/time -l (macOS) on build/x64. The other
columns come from a counting copy of the sources (build/primsrc), which this script makes:
the copy counts every instruction by where it is run and, in the rest of the CPU, by its
opcode. Nothing in src/ is changed.

    tools/prim64_table.py [p_loop ...]      prints the table as Markdown
"""
import glob, os, re, shutil, subprocess, sys

GOOSE = os.environ.get("GOOSE") or shutil.which("goose") or os.path.expanduser("~/.local/opt/goose-v2026.4-macos-arm64/goose")

def patch(text, old, new):
    assert text.count(old) == 1, old
    return text.replace(old, new)

def counting_build():
    shutil.rmtree("build/primsrc", ignore_errors=True)
    shutil.copytree("src", "build/primsrc")
    p = "build/primsrc/cpu64.goose"
    s = open(p).read()
    s = patch(s, "inline fn run_kind() -> bool {\n    let op = ins.op;",
              "var prim_front: u64 = 0;\nvar prim_op: u64[512] = [0; 512];\nvar prim_grp: u64[4096] = [0; 4096];\n"
              "inline fn run_kind() -> bool {\n    prim_front += 1;\n    let op = ins.op;")
    s = patch(s, "    let op = ins.op;\n    ip = rip + ins.plen;\n    let w: u8",
              "    let op = ins.op;\n    ip = rip + ins.plen;\n"
              "    { let gi: i64 = op; prim_op[gi] += 1; let g2 = peek8() as! i64;\n"
              "      if op == 0x0F { prim_op[256 + g2] += 1; }\n"
              "      if op == 0xC0 || op == 0xC1 || (op >= 0xD0 && op <= 0xD3) || op == 0xF6 || op == 0xF7 || op == 0xFE || op == 0xFF { prim_grp[gi * 8 + (g2 >> 3 & 7)] += 1; }\n"
              "      if ins.rep != 0 { prim_grp[2048 + gi] += 1; if op == 0x0F { prim_grp[2304 + g2] += 1; } }\n"
              "      if ins.p66 && op == 0x0F { prim_grp[2560 + g2] += 1; } }\n"
              "    let w: u8")
    open(p, "w").write(s)
    p = "build/primsrc/x64.goose"
    s = open(p).read()
    s = patch(s, "    exit(exit_code as! i32);",
              "    { var m: u8[>..] = [];\n"
              "      format(m, \"PRIM steps \", steps as! i64, \" front \", prim_front as! i64, \"\\n\");\n"
              "      for i in 512 { if prim_op[i] != 0 { format(m, \"PRIM op \", i as i64, \" \", prim_op[i] as! i64, \"\\n\"); } }\n"
              "      for i in 4096 { if prim_grp[i] != 0 { format(m, \"PRIM grp \", i as i64, \" \", prim_grp[i] as! i64, \"\\n\"); } }\n"
              "      write_stderr(m); }\n"
              "    exit(exit_code as! i32);")
    open(p, "w").write(s)
    r = subprocess.run([GOOSE, "build", "-o", "build/x64-prim", "build/primsrc/x64.goose"], capture_output=True, text=True)
    if "built" not in r.stdout + r.stderr:
        sys.exit("the counting copy did not build:\n" + (r.stdout + r.stderr)[-2000:])

ONE = {0x63: "MOVSXD", 0x69: "IMUL", 0x6B: "IMUL", 0x86: "XCHG", 0x87: "XCHG", 0x90: "NOP", 0x98: "CDQE", 0x99: "CDQ/CQO",
       0xA8: "TEST", 0xA9: "TEST", 0xC6: "MOV imm", 0xC7: "MOV imm", 0xC9: "LEAVE", 0x68: "PUSH imm", 0x6A: "PUSH imm",
       0xA4: "MOVSB", 0xA5: "MOVS", 0xAA: "STOSB", 0xAB: "STOS", 0x9E: "SAHF", 0x9F: "LAHF", 0x0F05: "SYSCALL"}
GROUP = {0xC0: "ROL ROR RCL RCR SHL SHR SAL SAR", 0xF6: "TEST TEST NOT NEG MUL IMUL DIV IDIV", 0xFE: "INC DEC ? ? ? ? ? ?",
         0xFF: "INC DEC CALL-indirect CALLF JMP-indirect JMPF PUSH ?"}
for k in (0xC1, 0xD0, 0xD1, 0xD2, 0xD3): GROUP[k] = GROUP[0xC0]
GROUP[0xF7] = GROUP[0xF6]
TWO = {0xAF: "IMUL", 0xBE: "MOVSX", 0xBF: "MOVSX", 0xA3: "BT", 0xAB: "BTS", 0xBA: "BT group", 0xBC: "BSF", 0xBD: "BSR",
       0xA2: "CPUID", 0x1F: "NOP", 0xA4: "SHLD", 0xA5: "SHLD", 0xAC: "SHRD", 0xAD: "SHRD", 0x0B: "UD2", 0xB8: "POPCNT"}
SSE = {0x10: "MOVUPS/SS/SD", 0x11: "MOVUPS/SS/SD", 0x28: "MOVAPS", 0x29: "MOVAPS", 0x2A: "CVTSI2SS/SD", 0x2C: "CVTTSS/SD2SI",
       0x2D: "CVTSS/SD2SI", 0x2E: "UCOMISS/SD", 0x2F: "COMISS/SD", 0x51: "SQRT", 0x54: "ANDPS", 0x57: "XORPS", 0x58: "ADD",
       0x59: "MUL", 0x5A: "CVT ss/sd", 0x5C: "SUB", 0x5D: "MIN", 0x5E: "DIV", 0x5F: "MAX", 0x6E: "MOVD/Q", 0x7E: "MOVD/Q",
       0x6F: "MOVDQA/U", 0x7F: "MOVDQA/U", 0xD6: "MOVQ", 0xEF: "PXOR", 0x14: "UNPCKLPS/PD", 0x16: "MOVHPS/PD", 0xC6: "SHUFPS/PD"}

def name_of(i, grp):
    if i < 256:
        if i in GROUP: return None        # shown by its field
        if 0x40 <= i <= 0x4F: return "REX?"
        if 0xB0 <= i <= 0xBF: return "MOV r, imm"
        if 0x91 <= i <= 0x97: return "XCHG"
        if 0xD8 <= i <= 0xDF: return "x87"
        if i < 0x40: return ["ADD", "OR", "ADC", "SBB", "AND", "SUB", "XOR", "CMP"][i >> 3] + " A, imm"
        return ONE.get(i, "%02X" % i)
    j = i - 256
    if 0x40 <= j <= 0x4F: return "CMOVcc"
    if 0x90 <= j <= 0x9F: return "SETcc"
    if 0xC8 <= j <= 0xCF: return "BSWAP"
    if j in TWO: return TWO[j]
    if j in SSE: return "SSE " + SSE[j]
    return "SSE/MMX 0F %02X" % j if (0x50 <= j <= 0x7F or 0xD0 <= j <= 0xFF or j in (0x12, 0x13, 0x15, 0x17, 0xC2, 0xC4, 0xC5)) else "0F %02X" % j

def measure(name):
    elf = "tests/prim64/%s.elf" % name
    r = subprocess.run(["build/x64-prim", elf], capture_output=True, text=True)
    steps = front = 0
    rest = {}
    for l in r.stderr.split("\n"):
        f = l.split()
        if f[:2] == ["PRIM", "steps"]: steps, front = int(f[2]), int(f[4])
        elif f[:2] == ["PRIM", "op"]:
            i, c = int(f[2]), int(f[3])
            if i == 0x0F: continue
            n = name_of(i, None)
            if n: rest[n] = rest.get(n, 0) + c
        elif f[:2] == ["PRIM", "grp"]:
            i, c = int(f[2]), int(f[3])
            if i < 2048:
                n = GROUP[i >> 3].split()[i & 7]
                rest[n] = rest.get(n, 0) + c
    t = subprocess.run(["/usr/bin/time", "-l", "build/x64", elf], capture_output=True, text=True)
    host = int(re.search(r"(\d+)\s+instructions retired", t.stderr).group(1))
    cyc = int(re.search(r"(\d+)\s+cycles elapsed", t.stderr).group(1))
    return steps, front, rest, host, cyc

def main():
    names = sys.argv[1:] or sorted(os.path.basename(p)[:-4] for p in glob.glob("tests/prim64/p_*.elf"))
    r = subprocess.run([GOOSE, "build", "-o", "build/x64", "src/x64.goose"], capture_output=True, text=True)
    counting_build()
    rows = []
    for n in names:
        steps, front, rest, host, cyc = measure(n)
        rows.append((host / steps, n, steps, front, rest, cyc))
    print("| Primitive | Guest instructions | Host instructions for each | Cycles for each | Run by the front | What the front does not run (share of the program's instructions) |")
    print("|---|---:|---:|---:|---:|---|")
    for each, n, steps, front, rest, cyc in sorted(rows):
        top = sorted(rest.items(), key=lambda x: -x[1])[:5]
        what = ", ".join("%s %.0f%%" % (k, 100 * c / steps) for k, c in top if c / steps >= 0.005)
        print("| `%s` | %.1f million | %.0f | %.1f | %.0f%% | %s |" % (n, steps / 1e6, each, cyc / steps, 100 * front / steps, what))

main()
