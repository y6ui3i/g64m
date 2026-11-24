#!/bin/sh
# The gate for a change to the 64-bit machine or its JIT: every suite, all at the same time
# (the host has cores to spare; one after another they take 25 minutes).
#
#   tools/gate.sh
#
# Builds once, then runs together: difftest64, prim64, systest64 three times (plain, with
# --jit, with --jit-check: Linux booted with every block compared against the interpreter),
# and three of NetHack's files built in the guest under --jit (what it must print is
# make-rc=0: GCC run to its end; a wrong decision about dead flags passes every suite and
# stops GCC, E147). What each printed is kept in build/gate/. The times in it mean nothing:
# to time a change, race the old and the new build beside each other, nothing else running.
#
# GOOSE names the compiler when it is not on PATH.
set -u
cd "$(dirname "$0")/.."
GOOSE="${GOOSE:-goose}"
G=build/gate
rm -rf "$G"
mkdir -p "$G"
"$GOOSE" build --debug -o build/g64m-debug src/g64m.goose >/dev/null || exit 2
"$GOOSE" build -o build/g64m src/g64m.goose >/dev/null || exit 2
export GATE_BUILT=1
start=$(date +%s)
run() { name=$1; shift; ( "$@" > "$G/$name.txt" 2>&1; echo $? > "$G/$name.rc" ) & }
run difftest64 tools/difftest64.sh
run prim64 tools/prim64.sh
run systest64 env S64_DIR="$G/s64" tools/systest64.sh
run systest64-jit env S64_DIR="$G/s64-jit" X64=--jit tools/systest64.sh
run systest64-jit-check env S64_DIR="$G/s64-jit-check" X64=--jit-check tools/systest64.sh
if [ -f images/disk64-dev.img ]; then run build env RACE_SHORT=1 python3 -I tools/build_race.py g64m-gate --jit; fi
wait
fail=0
total=0
# Where the 64-bit machine's globals are (E173): the interpreter's at multiples of 8, the
# arrays on lines of the cache.
if PROG=g64m tools/layout.sh --check > "$G/layout.txt" 2>&1; then printf '%-20s aligned\n' "layout"
else fail=1; printf '%-20s FAILED\n' "layout"; sed 's/^/    /' "$G/layout.txt"; fi
for name in difftest64 prim64 systest64 systest64-jit systest64-jit-check; do
    n=$(grep -c '^ok' "$G/$name.txt")
    total=$((total + n))
    rc=$(cat "$G/$name.rc")
    printf '%-20s %3d ok%s\n' "$name" "$n" "$([ "$rc" = 0 ] || echo "   FAILED (exit $rc)")"
    if [ "$rc" != 0 ]; then fail=1; grep -v '^ok' "$G/$name.txt" | grep -v 'building the package' | head -12 | sed 's/^/    /'; fi
done
if [ -f "$G/build.txt" ]; then
    if grep -q 'make-rc=0' "$G/build.txt"; then printf '%-20s make-rc=0\n' "build in the guest"
    else fail=1; printf '%-20s FAILED\n' "build in the guest"; tail -5 "$G/build.txt" | sed 's/^/    /'; fi
fi
echo "$total ok in $(( $(date +%s) - start )) s"
exit $fail
