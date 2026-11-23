#!/bin/sh
# The primitive programs (tests/prim64/p_*.c, E112): one small C program for each thing a
# program is made of. Runs each on the 64-bit CPU and compares what it prints with what it
# printed on a real CPU.
#
#   tools/prim64.sh                compare with tests/prim64/*.out
#   tools/prim64.sh p_loop ...     only the programs named
#   ORACLE_HOST=name tools/prim64.sh
#                                  build them again first, with GCC on the x86_64 Linux host
#                                  of that ssh name (in ~/g86m-oracle/prim), and run each
#                                  there twice for its expected text. The programs built are
#                                  kept beside their sources (p_*.elf), since they are
#                                  otherwise run where there is no such compiler.
#   tools/prim64_table.py          the table: host instructions for a guest instruction, and
#                                  the instructions the short front does not run
#
# How each is built is said by its line "// flags:": int (no SSE, as a kernel is built),
# sse (the compiler's defaults), simd (-O3, for loops worked several elements at a time).
#
# GOOSE names the compiler when it is not on PATH.
set -u
cd "$(dirname "$0")/.."
GOOSE="${GOOSE:-goose}"
BASE="-static -nostdlib -ffreestanding -fno-pic -no-pie -fno-stack-protector -fcf-protection=none -Wl,--build-id=none"

if [ -z "${GATE_BUILT:-}" ]; then "$GOOSE" build -o build/g64m src/g64m.goose >/dev/null || exit 2; fi

if [ $# -gt 0 ]; then
    list=""
    for n in "$@"; do list="$list tests/prim64/$n.c"; done
else
    list=$(ls tests/prim64/p_*.c)
fi

if [ -n "${ORACLE_HOST:-}" ]; then
    ssh "$ORACLE_HOST" 'mkdir -p g86m-oracle/prim' || exit 2
    scp -q tests/prim64/prim.h $list "$ORACLE_HOST:g86m-oracle/prim/" || exit 2
    for src in $list; do
        name=$(basename "$src" .c)
        case "$(sed -n 's|^// flags: ||p' "$src")" in
            int) flags="-O2 -mgeneral-regs-only" ;;
            sse) flags="-O2" ;;
            simd) flags="-O3" ;;
            *) echo "FAIL  $name: no line // flags:"; exit 2 ;;
        esac
        ssh "$ORACLE_HOST" "cd g86m-oracle/prim && gcc $flags $BASE -o $name.elf $name.c -lgcc && ./$name.elf > $name.1 && ./$name.elf > $name.2 && cmp -s $name.1 $name.2" \
            || { echo "FAIL  $name: it did not build, or its two runs differ"; exit 2; }
        scp -q "$ORACLE_HOST:g86m-oracle/prim/$name.elf" "tests/prim64/$name.elf" || exit 2
        scp -q "$ORACLE_HOST:g86m-oracle/prim/$name.1" "tests/prim64/$name.out" || exit 2
    done
fi

fail=0
for src in $list; do
    name=$(basename "$src" .c)
    if [ ! -f "tests/prim64/$name.elf" ] || [ ! -f "tests/prim64/$name.out" ]; then fail=1; echo "FAIL  $name: not built"; continue; fi
    # With options (X64, the JIT's), the count of instructions must be the plain run's too.
    count() { build/g64m $1 --jit-stats "tests/prim64/$name.elf" 2>&1 >/dev/null | sed -n 's/.* of \([0-9]*\) instructions in blocks.*/\1/p'; }
    if [ -n "${X64:-}" ] && [ "$(count "$X64")" != "$(count "")" ]; then
        fail=1
        echo "FAIL  $name: $(count "$X64") instructions with $X64, $(count "") without"
    elif [ -n "${X64:-}" ] && [ "$(count "$X64 --max 1000003")" != "$(count "--max 1000003")" ]; then
        # And a run cut short stops at the same instruction: blocks run into one another
        # only as far as the time left (E122).
        fail=1
        echo "FAIL  $name: stopped by --max after $(count "$X64 --max 1000003") instructions with $X64, $(count "--max 1000003") without"
    elif build/g64m ${X64:-} "tests/prim64/$name.elf" 2> "build/$name.err" | cmp -s - "tests/prim64/$name.out"; then
        echo "ok    $name"
    else
        fail=1
        echo "FAIL  $name: $(head -c 300 "build/$name.err" | tr '\n' ' ')"
    fi
done
exit $fail
