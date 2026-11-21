#!/bin/sh
# Times the primitives against QEMU with enough work in each to be timed (E126): every
# primitive is built again on the x86_64 host with its main() called ROUNDS times, and
# run under QEMU's user mode, under Docker's own emulator, and under g64m with the JIT.
#
#   ORACLE_HOST=name tools/prim64_long.sh [ROUNDS]     (30 if not given)
#
# The long programs go to build/long/ and are not kept in the repository. What comes out
# is a line for each: guest instructions (millions), seconds under QEMU, Docker's own and
# g86m --jit, each less the time of a program that does nothing.
set -u
cd "$(dirname "$0")/.."
R="${1:-30}"
H="${ORACLE_HOST:?ORACLE_HOST names the x86_64 host that builds the programs}"
BASE="-static -nostdlib -ffreestanding -fno-pic -no-pie -fno-stack-protector -fcf-protection=none -Wl,--build-id=none"
mkdir -p build/long
ssh "$H" 'rm -rf g86m-oracle/long && mkdir -p g86m-oracle/long' || exit 2
scp -q tests/prim64/*.c tests/prim64/prim.h "$H:g86m-oracle/long/" || exit 2
ssh "$H" "cd g86m-oracle/long && sed -i 's/call main/call many/' prim.h && printf '#include \"prim.h\"\nint main(void) { return 0; }\n' > p_none.c && for f in p_*.c; do n=\${f%.c}; case \$(sed -n 's|^// flags: ||p' \$f) in int) fl='-O2 -mgeneral-regs-only' ;; simd) fl='-O3' ;; *) fl='-O2' ;; esac; echo 'void many(void) { for (int i = 0; i < ROUNDS; i++) main(); }' >> \$f; gcc \$fl -DROUNDS=$R $BASE -o \$n.elf \$f -lgcc || exit 1; done" || exit 2
scp -q "$H:g86m-oracle/long/*.elf" build/long/ || exit 2
docker run --rm -v "$PWD/build/long:/p:ro" g86m-qemu sh -c '
t() { s=$(cut -d" " -f1 /proc/uptime); "$@" >/dev/null 2>&1; "$@" >/dev/null 2>&1; "$@" >/dev/null 2>&1; e=$(cut -d" " -f1 /proc/uptime); echo "$s $e"; }
for f in /p/p_*.elf; do n=$(basename $f .elf); echo $n $(t qemu-x86_64 $f) $(t $f); done' > build/long/qemu.txt
python3 -I - <<'PY'
import subprocess, time, re, glob, os
q = {}
for l in open('build/long/qemu.txt'):
    f = l.split()
    if len(f) == 5: q[f[0]] = ((float(f[2]) - float(f[1])) / 3, (float(f[4]) - float(f[3])) / 3)
def t(p):
    b = []
    for i in range(3):
        s = time.perf_counter(); subprocess.run(['build/g64m', '--jit', '--max', '1000000000000', p], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL); b.append(time.perf_counter() - s)
    return min(b)
base = t('build/long/p_none.elf')
print('nothing: QEMU %.3f s, Docker %.3f s, g64m %.3f s' % (q['p_none'][0], q['p_none'][1], base))
for f in sorted(glob.glob('build/long/p_*.elf')):
    n = os.path.basename(f)[:-4]
    if n == 'p_none': continue
    r = subprocess.run(['build/g64m', '--jit', '--max', '1000000000000', '--jit-stats', f], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    m = re.search(rb' of (\d+) instructions in blocks', r.stderr)
    g = int(m[1]) / 1e6 if m else 0
    print('%s %.1f %.3f %.3f %.3f' % (n, g, q[n][0] - q['p_none'][0], q[n][1] - q['p_none'][1], t(f) - base))
PY
