#!/bin/sh
# Runs the 64-bit instruction tests and compares the per-instruction traces with the
# expected ones, which were taken from a real CPU (E091).
#
#   tools/difftest64.sh               compare with tests/expected64/*.trace.gz
#   tools/difftest64.sh a_first ...   only the tests named (those in assembly)
#   ORACLE_HOST=name tools/difftest64.sh
#                                     take the expected traces again first, on the x86_64
#                                     Linux host of that ssh name: tools/oracle/step64.c is
#                                     built there, in ~/g86m-oracle, and run on each test
#
# GOOSE names the compiler when it is not on PATH.
set -u
cd "$(dirname "$0")/.."
GOOSE="${GOOSE:-goose}"
mkdir -p build/t64 tests/expected64

"$GOOSE" build --debug -o build/x64-debug src/x64.goose >/dev/null || exit 2
"$GOOSE" build -o build/x64 src/x64.goose >/dev/null || exit 2

if [ $# -gt 0 ]; then
    list=""
    for n in "$@"; do list="$list tests/asm64/$n.asm"; done
else
    list=$(ls tests/asm64/*.asm)
fi

for asm in $list; do
    name=$(basename "$asm" .asm)
    nasm -w-other -I tests/asm64/ -f bin -l "build/t64/$name.lst" -o "build/t64/$name" "$asm" || exit 2
    chmod +x "build/t64/$name"
done

# The tests in C are kept built (tests/c64/*.elf, beside their sources, which say how each
# was built): they take part when no tests are named.
if [ $# -eq 0 ]; then
    for elf in tests/c64/*.elf; do
        name=$(basename "$elf" .elf)
        cp "$elf" "build/t64/$name"
        list="$list $name"
    done
fi

if [ -n "${ORACLE_HOST:-}" ]; then
    ssh "$ORACLE_HOST" 'mkdir -p g86m-oracle/t' || exit 2
    scp -q tools/oracle/step64.c "$ORACLE_HOST:g86m-oracle/" || exit 2
    ssh "$ORACLE_HOST" 'cd g86m-oracle && cc -O2 -Wall -o step64 step64.c' || exit 2
    for asm in $list; do
        name=$(basename "$asm" .asm)
        scp -q "build/t64/$name" "$ORACLE_HOST:g86m-oracle/t/" || exit 2
        # Twice: a trace that is not the same on two runs is no trace to compare with.
        case "$name" in x_*|cx_*) x="-x" ;; *) x="" ;; esac
        ssh "$ORACLE_HOST" "cd g86m-oracle && ./step64 $x t/$name > t/$name.1 && ./step64 $x t/$name > t/$name.2 && cmp -s t/$name.1 t/$name.2 && gzip -9nc t/$name.1" > "build/t64/$name.gz"
        if [ $? -ne 0 ]; then echo "FAIL  $name: the oracle's two runs differ, or it did not run"; exit 2; fi
        mv "build/t64/$name.gz" "tests/expected64/$name.trace.gz"
    done
fi

fail=0
for asm in $list; do
    name=$(basename "$asm" .asm)
    exp="tests/expected64/$name.trace.gz"
    if [ ! -f "$exp" ]; then fail=1; echo "FAIL  $name: no expected trace"; continue; fi
    # Tests named x_ and cx_ use SSE: their traces have the XMM registers too.
    case "$name" in x_*|cx_*) tr="--trace-xmm" ;; *) tr="--trace" ;; esac
    build/x64-debug $tr "build/t64/$name" > "build/t64/$name.trace" 2> "build/t64/$name.err"
    gunzip -c "$exp" > "build/t64/$name.expected"
    # The release build must produce the same trace: optimization must not change behaviour.
    if ! build/x64 $tr "build/t64/$name" 2>/dev/null | cmp -s - "build/t64/$name.expected"; then
        fail=1
        echo "FAIL  $name: release build differs from the expected trace"
    fi
    # And with the JIT, each block compared with the same instructions interpreted (E120).
    # A trace runs no block, so this is a run without one: what it says is its exit code.
    if ! build/x64 --jit-check "build/t64/$name" > /dev/null 2> "build/t64/$name.jit"; then
        fail=1
        echo "FAIL  $name: with --jit-check: $(head -c 400 "build/t64/$name.jit" | tr '\n' ' ')"
    fi
    if ! build/x64 --jit "build/t64/$name" > /dev/null 2> "build/t64/$name.jit"; then
        fail=1
        echo "FAIL  $name: with --jit: $(head -c 400 "build/t64/$name.jit" | tr '\n' ' ')"
    fi
    if cmp -s "build/t64/$name.trace" "build/t64/$name.expected"; then
        echo "ok    $name ($(wc -l < "build/t64/$name.trace" | tr -d ' ') lines)"
    else
        fail=1
        line=$(cmp "build/t64/$name.trace" "build/t64/$name.expected" 2>&1 | sed -n 's/.*line \([0-9][0-9]*\).*/\1/p')
        if [ -z "$line" ]; then line=$(($(wc -l < "build/t64/$name.trace") + 1)); fi
        echo "FAIL  $name: first difference at line $line"
        tools/diff64.py "build/t64/$name.expected" "build/t64/$name.trace" "$line" "build/t64/$name.lst"
        sed 's/^/  /' "build/t64/$name.err" | head -3
    fi
done
exit $fail
