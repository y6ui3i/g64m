#!/usr/bin/env python3
"""Shows where two 64-bit traces part: diff64.py expected got line [listing]

Prints the line before (the state the instruction started from, whose RIP is where the
instruction is), the instruction if nasm's listing of the test is given, and, of the line
itself, only the fields that differ. With `all` for the line, every place where the two
traces agree on a line and not on the next is shown, in short."""
import re
import sys

BASE = 0x400000


def listing(path):
    """Address to source text, from nasm's listing."""
    at = {}
    for line in open(path, errors="replace"):
        m = re.match(r"\s*\d+ ([0-9A-F]{8}) [0-9A-F\[\]()]+-?\s+(?:<\d+> )?\s*(.*)", line)
        if m and m.group(2).strip():
            at.setdefault(BASE + int(m.group(1), 16), m.group(2).strip())
    return at

FLAGS = [(0x800, "OF"), (0x400, "DF"), (0x80, "SF"), (0x40, "ZF"), (0x10, "AF"), (4, "PF"), (1, "CF")]


def fields(line):
    return dict(f.split("=") for f in line.split())


def flags(text):
    v = int(text, 16)
    return text + " (" + " ".join(n for bit, n in FLAGS if v & bit) + ")"


def main():
    exp = open(sys.argv[1]).read().splitlines()
    got = open(sys.argv[2]).read().splitlines()
    src = listing(sys.argv[4]) if len(sys.argv) > 4 else {}
    if sys.argv[3] == "all":
        for i in range(1, min(len(exp), len(got))):
            if exp[i - 1] == got[i - 1] and exp[i] != got[i]:
                e, g = fields(exp[i]), fields(got[i])
                diff = ", ".join(f"{k} {e[k]} not {g[k]}" for k in e if e[k] != g[k])
                was = fields(exp[i - 1])
                print(f"{i + 1}: {src.get(int(was['RIP'], 16), '?')}  [F was {was['F']}]  {diff}")
        return
    n = int(sys.argv[3])
    longer = exp if len(exp) >= len(got) else got
    if n >= 2 and src:
        print("  at:       " + src.get(int(fields(longer[n - 2])["RIP"], 16), "?"))
    if n >= 2:
        print("  before:   " + " ".join(f for f in longer[n - 2].split() if not f.endswith("=" + "0" * 16)))
    if n > len(got):
        print("  got:      nothing (the run ended)")
        return
    if n > len(exp):
        print("  expected: nothing (the run ended)")
        return
    e, g = fields(exp[n - 1]), fields(got[n - 1])
    for k in e:
        if e[k] != g.get(k):
            show = flags if k == "F" else (lambda t: t)
            print(f"  {k}: expected {show(e[k])}, got {show(g.get(k, '?'))}")


main()
