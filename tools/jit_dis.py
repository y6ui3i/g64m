#!/usr/bin/env python3
# Disassembles what `build/g64m --jit-dump FILE ...` wrote: the JIT's generated arm64 code
# as raw bytes. The bytes are put into an object file as words and given to objdump, which
# on macOS reads no raw file.
#
#   python3 -I tools/jit_dis.py FILE > code.txt
#
# The offsets printed are those in the room for code (dc_code's values); the way in and
# the way out are first, and each block begins with `cmp x0, #n` (its count of instructions).
import sys, struct, subprocess, tempfile, os
data = open(sys.argv[1], 'rb').read()
data += b'\0' * (-len(data) % 4)
with tempfile.TemporaryDirectory() as d:
    s, o = os.path.join(d, 'c.s'), os.path.join(d, 'c.o')
    with open(s, 'w') as f:
        f.write('.text\n')
        for (w,) in struct.iter_unpack('<I', data): f.write('.long 0x%08x\n' % w)
    subprocess.run(['clang', '-c', '-arch', 'arm64', '-o', o, s], check=True)
    out = subprocess.run(['objdump', '-d', '--no-show-raw-insn', o], capture_output=True, text=True).stdout
for l in out.split('\n'):
    if ':' in l and l.strip()[:1].isalnum() and '\t' in l: print(l.strip())
