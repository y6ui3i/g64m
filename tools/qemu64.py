#!/usr/bin/env python3
"""Compares QEMU's user-mode emulator with the real CPU's traces (E092).

    qemu-x86_64 -cpu IvyBridge -one-insn-per-tb -d cpu -D name.qlog program
    tools/qemu64.py name.qlog expected.trace [listing]

QEMU's log has the CPU's state before each instruction, which is the state after the one
before: the first is dropped and the rest are lined up with the oracle's lines by RIP. The
oracle has a line for each repetition of a REP instruction and QEMU one for all of them, so
the oracle's lines between repetitions are passed over. Every instruction that brings a
difference is printed, with the fields that differ (one carried along from an earlier
instruction is not shown again), then a count by instruction and flag.
"""
import collections
import os
import re
import sys

BASE = 0x400000
FLAGS = [(0x800, "OF"), (0x400, "DF"), (0x80, "SF"), (0x40, "ZF"), (0x10, "AF"), (4, "PF"), (1, "CF")]
ORDER = ["RIP", "RAX", "RCX", "RDX", "RBX", "RSP", "RBP", "RSI", "RDI"] + [f"R{i}" for i in range(8, 16)] + ["F"]


def qemu_states(path):
    out, cur = [], {}
    for line in open(path, errors="replace"):
        for name, val in re.findall(r"\b(R[A-Z0-9]{1,2}) ?=([0-9a-f]{8,16})\b", line):
            cur["F" if name == "RFL" else name] = val.upper()
        if line.startswith("RIP="):
            out.append(cur)
            cur = {}
    return out[1:]


def listing(path):
    at = {}
    for line in open(path, errors="replace"):
        m = re.match(r"\s*\d+ ([0-9A-F]{8}) [0-9A-F\[\]()]+-?\s+(?:<\d+> )?\s*(.*)", line)
        if m and m.group(2).strip():
            at.setdefault(BASE + int(m.group(1), 16), m.group(2).strip())
    return at


def names(bits):
    return "+".join(n for b, n in FLAGS if bits & b) or f"{bits:X}"


def main():
    q = qemu_states(sys.argv[1])
    exp = [dict(f.split("=") for f in l.split()) for l in open(sys.argv[2])]
    src = listing(sys.argv[3]) if len(sys.argv) > 3 and os.path.exists(sys.argv[3]) else {}
    count = collections.Counter()
    i = j = same = 0
    before = {}
    while i < len(exp) and j < len(q):
        e, g = exp[i], q[j]
        if e["RIP"] != g["RIP"] and i > 0 and e["RIP"] == exp[i - 1]["RIP"]:
            i += 1
            continue
        was = exp[i - 1] if i > 0 else None
        text = src.get(int(was["RIP"], 16), was["RIP"]) if was else "start"
        if e["RIP"] != g["RIP"]:
            print(f"line {i + 1}: lost step after `{text}`: real RIP {e['RIP']}, QEMU {g['RIP']}")
            break
        # Only what this instruction brought: a field that already differed before it, by
        # the same bits, is the earlier difference carried along.
        now = {k: int(e[k], 16) ^ int(g[k], 16) for k in ORDER}
        diff = [k for k in ORDER if now[k] and now[k] != before.get(k, 0)]
        before = now
        if diff:
            parts = []
            for k in diff:
                if k == "F":
                    x = int(e[k], 16) ^ int(g[k], 16)
                    parts.append(f"F real {e[k]} QEMU {g[k]} ({names(x)})")
                    count[(text.split()[0], names(x))] += 1
                else:
                    parts.append(f"{k} real {e[k]} QEMU {g[k]}")
                    count[(text.split()[0], k)] += 1
            print(f"line {i + 1}: {text}  [F was {was['F'] if was else '?'}]  " + "; ".join(parts))
        else:
            same += 1
        i += 1
        j += 1
    print(f"-- {same} instructions the same, {sum(count.values())} differences; real lines left {len(exp) - i}, QEMU states left {len(q) - j}")
    for (op, what), n in sorted(count.items()):
        print(f"   {op:8} {what:12} {n}")


main()
