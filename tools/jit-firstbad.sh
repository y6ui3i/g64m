#!/bin/sh
# For finding a wrong translation of the JIT in a small program (docs/jit.md).
#
#   tools/jit-firstbad.sh program.bin [--cpu i686]
#
# Runs the program once with a trace, which goes one instruction at a time and uses no blocks,
# then with --jit stopped after N instructions, for N found by halving: the first N at which
# the JIT's run is not at the address the trace has after N instructions. That instruction is
# in the block that went wrong. Needs build/g86m.
set -u
cd "$(dirname "$0")/.."
bin=$1
cpu=${2:-}
[ -n "$cpu" ] && cpu="$cpu ${3:-}"
build/g86m $cpu --trace --max 2000000 "$bin" 2>/dev/null | cut -c1-13 > build/firstbad.ips
total=$(wc -l < build/firstbad.ips)
ok() {
    want=$(sed -n "$(($1 + 1))p" build/firstbad.ips)
    at=$(build/g86m --jit $cpu --max "$1" "$bin" 2>&1 | sed -n 's/^steps \([0-9]*\) .* at \([0-9a-f]*\):\([0-9a-f]*\) .*/\1 \2 \3/p')
    set -- "$1" $at
    got=$(printf '%s:%08X' "$(echo "${3:-}" | tr a-f A-F)" "0x${4:-0}")
    [ "${2:-}" = "$1" ] && [ "$got" = "$want" ]
}
lo=1
hi=$((total - 2))
if ok $hi; then echo "no stop is wrong up to $hi instructions"; exit 0; fi
while [ $((hi - lo)) -gt 1 ]; do
    k=$(((lo + hi) / 2))
    if ok $k; then lo=$k; else hi=$k; fi
done
echo "the first wrong stop is after $hi instructions (of $total); the trace there:"
sed -n "$((hi - 3)),$((hi + 1))p" build/firstbad.ips
build/g86m --jit $cpu --max $hi "$bin" 2>&1 | tail -1
exit 1
