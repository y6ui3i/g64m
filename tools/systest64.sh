#!/bin/sh
# Runs the 64-bit system tests (tests/sys64/y_*.asm) and compares what each prints with what
# it printed on a real CPU (E094).
#
#   tools/systest64.sh                compare with tests/expected64/*.out
#   tools/systest64.sh y_fault ...    only the tests named
#   ORACLE_HOST=name tools/systest64.sh
#                                     take the expected text again first, on the x86_64 Linux
#                                     host of that ssh name, which needs QEMU and KVM: the test
#                                     runs there as a guest whose instructions the host's own
#                                     CPU executes. Taken twice, and once more under QEMU's own
#                                     emulation; a test that prints differently there is named.
#
# GOOSE names the compiler when it is not on PATH.
set -u
cd "$(dirname "$0")/.."
GOOSE="${GOOSE:-goose}"
mkdir -p build/s64 tests/expected64

"$GOOSE" build --debug -o build/x64-debug src/x64.goose >/dev/null || exit 2
"$GOOSE" build -o build/x64 src/x64.goose >/dev/null || exit 2

if [ $# -gt 0 ]; then
    list=""
    for n in "$@"; do list="$list tests/sys64/$n.asm"; done
else
    list=$(ls tests/sys64/y_*.asm)
fi

for asm in $list; do
    name=$(basename "$asm" .asm)
    nasm -w-other -I tests/sys64/ -f bin -l "build/s64/$name.lst" -o "build/s64/$name" "$asm" || exit 2
done

QEMU="timeout 30 qemu-system-x86_64 -cpu max -m 64 -display none -no-reboot -serial stdio -device isa-debug-exit,iobase=0xf4,iosize=4"
if [ -n "${ORACLE_HOST:-}" ]; then
    ssh "$ORACLE_HOST" 'mkdir -p g86m-oracle/s' || exit 2
    for asm in $list; do
        name=$(basename "$asm" .asm)
        scp -q "build/s64/$name" "$ORACLE_HOST:g86m-oracle/s/" || exit 2
        ssh "$ORACLE_HOST" "cd g86m-oracle/s && $QEMU -accel kvm -kernel $name > $name.1 2>/dev/null; echo \$? > $name.rc; $QEMU -accel kvm -kernel $name > $name.2 2>/dev/null; $QEMU -accel tcg -kernel $name > $name.tcg 2>/dev/null; cmp -s $name.1 $name.2 && test -s $name.1 && test \$(cat $name.rc) = 1 && { cmp -s $name.1 $name.tcg || echo 'note  $name: QEMU without KVM prints differently' >&2; cat $name.1; }" > "build/s64/$name.new"
        # (The test must also have stopped by its own EXIT: QEMU's status is then 1.)
        if [ ! -s "build/s64/$name.new" ]; then echo "FAIL  $name: the oracle's two runs differ, or it printed nothing, or it did not reach its end"; exit 2; fi
        mv "build/s64/$name.new" "tests/expected64/$name.out"
    done
fi

fail=0
for asm in $list; do
    name=$(basename "$asm" .asm)
    exp="tests/expected64/$name.out"
    if [ ! -f "$exp" ]; then fail=1; echo "FAIL  $name: no expected text"; continue; fi
    build/x64-debug "build/s64/$name" > "build/s64/$name.out" 2> "build/s64/$name.err"
    if ! build/x64 "build/s64/$name" 2>/dev/null | cmp -s - "$exp"; then
        fail=1
        echo "FAIL  $name: release build prints differently"
    fi
    if cmp -s "build/s64/$name.out" "$exp"; then
        echo "ok    $name ($(wc -l < "$exp" | tr -d ' ') lines)"
    else
        fail=1
        echo "FAIL  $name"
        diff "$exp" "build/s64/$name.out" | head -12 | sed 's/^/  /'
        sed 's/^/  /' "build/s64/$name.err" | head -3
    fi
done
# With the images in images/ (an x86_64 Alpine kernel as vmlinuz64-lts, and initramfs64-mini,
# which tools/images/make-mini64.py makes), a 64-bit Linux is booted to a shell and a few
# commands typed at it (E099). Nothing checks its instructions one by one: what is compared
# is what the commands print.
if [ $# -eq 0 ]; then
    if [ -f images/vmlinuz64-lts ] && [ -f images/initramfs64-mini ]; then
        out=$(build/x64 --initrd images/initramfs64-mini --wait "~ # " \
            --type 'uname -m; echo $((6*7)) > /tmp/a; cat /tmp/a; grep -c processor /proc/cpuinfo; echo end-$?\n' --wait "end-0" \
            images/vmlinuz64-lts 2>build/s64/linux.err | tr -d '\r' | sed -n '/^x86_64$/,$p' | tr '\n' ' ')
        if [ "$out" = "x86_64 42 1 end-0" ]; then
            echo "ok    linux64 shell: $(sed -n 's/^x64: \([0-9]*\) instructions.*/\1/p' build/s64/linux.err) instructions to the end of the script"
        else
            fail=1
            echo "FAIL  linux64 shell: printed \"$out\""
            tail -2 build/s64/linux.err | sed 's/^/  /'
        fi
    else
        echo "skip  linux64 shell (images/vmlinuz64-lts and images/initramfs64-mini are not there)"
    fi
fi
exit $fail
