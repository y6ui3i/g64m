#!/bin/sh
# The primitives (tests/prim64) timed under other emulators on this host, to set g64m's
# numbers beside (E117): QEMU's user-mode emulator, and whatever Docker itself runs an x86_64
# program with (Rosetta or QEMU, by its settings). Needs Docker on an arm64 host.
#
#   tools/prim64_qemu.sh [p_loop ...]     prints, for each: seconds for one run under
#                                         QEMU, under Docker's own, and under build/g64m
#
# The image g86m-qemu is made at the first run: Alpine for arm64 with its package
# qemu-x86_64. Each program is run twenty times in one container and the time divided (the
# container's clock is read to a hundredth of a second).
set -e
cd "$(dirname "$0")/.."
docker image inspect g86m-qemu >/dev/null 2>&1 || \
    printf 'FROM --platform=linux/arm64 alpine:3.24\nRUN apk add --no-cache qemu-x86_64\n' | docker build -q -t g86m-qemu - >/dev/null
if [ $# -gt 0 ]; then list="$*"; else list=$(ls tests/prim64/p_*.elf | sed 's|.*/||; s|\.elf$||'); fi
N=20
echo "QEMU: $(docker run --rm g86m-qemu qemu-x86_64 --version | head -1)"
for p in $list; do
    out=$(docker run --rm -v "$PWD/tests/prim64:/p:ro" g86m-qemu sh -c "
        t() { s=\$(cut -d' ' -f1 /proc/uptime); i=0; while [ \$i -lt $N ]; do \"\$@\" >/dev/null 2>&1 || echo fail; i=\$((i+1)); done; e=\$(cut -d' ' -f1 /proc/uptime); echo \"\$s \$e\"; }
        t qemu-x86_64 /p/$p.elf; t /p/$p.elf")
    s0=$(python3 -c 'import time; print(time.time())')
    i=0; while [ $i -lt 3 ]; do build/g64m tests/prim64/$p.elf >/dev/null; i=$((i+1)); done
    e0=$(python3 -c 'import time; print(time.time())')
    echo "$p $out $s0 $e0" | tr '\n' ' ' | awk -v n=$N '{ if ($2 ~ /fail/) print $1, "failed"; else printf "%s %.4f %.4f %.4f\n", $1, ($3-$2)/n, ($5-$4)/n, ($7-$6)/3 }'
done
