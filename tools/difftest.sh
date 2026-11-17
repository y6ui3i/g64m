#!/bin/sh
# Runs the instruction tests and compares the per-instruction traces with the expected ones.
#
#   tools/difftest.sh                 compare with tests/expected/*.trace.gz
#   ORACLE=/path/to/trace32 tools/difftest.sh
#                                     regenerate the expected traces with rustx86's trace32 first
#
# To build trace32, put tools/oracle/trace32.rs in rustx86's core/examples/ and run
#   cargo build --release -p rustx86-core --example trace32
# GOOSE names the compiler when it is not on PATH.
set -u
cd "$(dirname "$0")/.."
GOOSE="${GOOSE:-goose}"
mkdir -p build tests/expected

"$GOOSE" build --debug -o build/g86m-debug src/g86m.goose >/dev/null || exit 2
"$GOOSE" build -o build/g86m src/g86m.goose >/dev/null || exit 2

fail=0

# The globals of the inner loop are where the pads in src/ mean them to be (E050).
if tools/layout.sh --check > build/layout.out 2>&1; then
    echo "ok    layout: the watched globals are aligned"
elif [ $? -eq 1 ]; then
    fail=1
    echo "FAIL  layout: a global is off its alignment; see tools/layout.sh"
    sed 's/^/    |/' build/layout.out
else
    echo "skip  layout (the generated C could not be read)"
fi

for asm in tests/asm/t_*.asm tests/asm/u_*.asm tests/asm/v_*.asm tests/asm/s_*.asm; do
    name=$(basename "$asm" .asm)
    nasm -w-other -I tests/asm/ -f bin -o "build/$name.bin" "$asm" || exit 2
done
cp testdata/hello.bin testdata/interrupt.bin testdata/vram.bin build/

for bin in build/t_*.bin build/u_*.bin build/v_*.bin build/hello.bin build/interrupt.bin build/vram.bin; do
    name=$(basename "$bin" .bin)
    # Tests named v_ use instructions newer than the 386: they run on the i686.
    case "$name" in v_*) cpu="--cpu i686" ;; *) cpu="" ;; esac
    exp="tests/expected/$name.trace.gz"
    if [ -n "${ORACLE:-}" ]; then
        "$ORACLE" "$bin" 2>/dev/null | gzip -9n > "$exp"
    fi
    build/g86m-debug $cpu --trace --max 2000000 "$bin" > "build/$name.trace" 2> "build/$name.err"
    gunzip -c "$exp" > "build/$name.expected"
    # The release build must produce the same trace: optimization must not change behaviour.
    if ! build/g86m $cpu --trace --max 2000000 "$bin" 2>/dev/null | cmp -s - "build/$name.expected"; then
        fail=1
        echo "FAIL  $name: release build differs from the expected trace"
    fi
    if cmp -s "build/$name.trace" "build/$name.expected"; then
        echo "ok    $name ($(wc -l < "build/$name.trace" | tr -d ' ') lines)"
    else
        fail=1
        line=$(cmp "build/$name.trace" "build/$name.expected" 2>&1 | sed -n 's/.*line \([0-9][0-9]*\).*/\1/p')
        if [ -z "$line" ]; then line=$(($(wc -l < "build/$name.trace") + 1)); fi
        echo "FAIL  $name: first difference at line $line"
        echo "  before:   $(sed -n "$((line - 1))p" "build/$name.expected")"
        echo "  expected: $(sed -n "${line}p" "build/$name.expected")"
        echo "  got:      $(sed -n "${line}p" "build/$name.trace")"
        tail -1 "build/$name.err" | sed 's/^/  stderr:   /'
    fi
done

# Self-checking tests, for what the oracle cannot judge. A test passes when the console says OK and nothing else.
for bin in build/s_*.bin; do
    name=$(basename "$bin" .bin)
    case "$name" in s_686|s_fpu|s_fpu80|s_rdtsc|s_rmwro|s_invlpg|s_invlpgu|s_flagro|s_pairfault) cpu="--cpu i686" ;; *) cpu="" ;; esac
    for exe in build/g86m-debug build/g86m; do
        out=$("$exe" $cpu --max 2000000 "$bin" 2>/dev/null)
        if [ "$out" = "OK" ]; then
            echo "ok    $name ($(basename "$exe"))"
        else
            fail=1
            echo "FAIL  $name ($(basename "$exe")): console was \"$out\""
        fi
    done
done

# Stopping after any number of instructions. A run of short executors counts a fused pair as two
# instructions and stops one short of the limit; wherever the limit falls, also between the two
# of a pair, the machine must be where the trace, which goes one instruction at a time, says it
# is after that many (E054). s_pairs, stopped at each of 400 counts inside its cached passes.
if [ -f build/s_pairs.bin ]; then
    build/g86m --trace --max 2000000 build/s_pairs.bin 2>/dev/null | cut -c1-13 > build/s_pairs.ips
    for exe in build/g86m-debug build/g86m; do
        bad=0
        k=1200
        while [ $k -lt 1600 ]; do
            want=$(sed -n "$((k + 1))p" build/s_pairs.ips)
            at=$("$exe" --max $k build/s_pairs.bin 2>&1 | sed -n 's/^steps \([0-9]*\) .* at \([0-9a-f]*\):\([0-9a-f]*\) .*/\1 \2 \3/p')
            set -- $at
            got=$(printf '%s:%08X' "$(echo "${2:-}" | tr a-f A-F)" "0x${3:-0}")
            if [ "${1:-}" != "$k" ] || [ "$got" != "$want" ]; then
                bad=$((bad + 1))
                [ $bad -le 3 ] && echo "  after $k: at $got (counted ${1:-?}), the trace says $want"
            fi
            k=$((k + 1))
        done
        if [ $bad -eq 0 ]; then
            echo "ok    stops at 400 counts in s_pairs ($(basename "$exe"))"
        else
            fail=1
            echo "FAIL  stops in s_pairs ($(basename "$exe")): $bad of 400 counts are not where the trace is"
        fi
    done
fi

# With the JIT (E059): every self-check again, and the stops. A block is run whole or not at
# all, so a stop inside one must find the interpreter there instead.
bad=0
count=0
for bin in build/s_*.bin; do
    name=$(basename "$bin" .bin)
    case "$name" in s_686|s_fpu|s_fpu80|s_rdtsc|s_rmwro|s_invlpg|s_invlpgu|s_flagro|s_pairfault) cpu="--cpu i686" ;; *) cpu="" ;; esac
    out=$(build/g86m --jit $cpu --max 2000000 "$bin" 2>/dev/null)
    count=$((count + 1))
    if [ "$out" != "OK" ]; then
        bad=$((bad + 1))
        echo "  $name with --jit: console was \"$out\""
    fi
done
if [ $bad -eq 0 ]; then
    echo "ok    jit: $count self-checks"
else
    fail=1
    echo "FAIL  jit: $bad of $count self-checks"
fi
# The JIT's own self-checks once more with room for very little code, so that the code fills
# up and is dropped while they run (E063).
bad=0
count=0
for bin in build/s_jit*.bin; do
    out=$(build/g86m --jit --jit-size 70000 --max 2000000 "$bin" 2>/dev/null)
    count=$((count + 1))
    if [ "$out" != "OK" ]; then
        bad=$((bad + 1))
        echo "  $(basename "$bin" .bin) with --jit --jit-size 70000: console was \"$out\""
    fi
done
if [ $bad -eq 0 ]; then
    echo "ok    jit: $count self-checks with the code filling up"
else
    fail=1
    echo "FAIL  jit: $bad of $count self-checks with the code filling up"
fi
if [ -f build/s_pairs.bin ]; then
    bad=0
    k=1200
    while [ $k -lt 1600 ]; do
        want=$(sed -n "$((k + 1))p" build/s_pairs.ips)
        at=$(build/g86m --jit --max $k build/s_pairs.bin 2>&1 | sed -n 's/^steps \([0-9]*\) .* at \([0-9a-f]*\):\([0-9a-f]*\) .*/\1 \2 \3/p')
        set -- $at
        got=$(printf '%s:%08X' "$(echo "${2:-}" | tr a-f A-F)" "0x${3:-0}")
        if [ "${1:-}" != "$k" ] || [ "$got" != "$want" ]; then bad=$((bad + 1)); fi
        k=$((k + 1))
    done
    if [ $bad -eq 0 ]; then
        echo "ok    jit: stops at 400 counts in s_pairs"
    else
        fail=1
        echo "FAIL  jit: stops in s_pairs: $bad of 400 counts are not where the trace is"
    fi
fi

# And the Linux boot with the JIT stops at the same instruction as without it: code at linear
# addresses that are not its physical ones, the kernel's own CALLs and RETs, two privilege
# levels.
if [ -f images/vmlinuz-lts ] && [ -f images/initramfs-mini ]; then
    plain=$(build/g86m --headless --initrd images/initramfs-mini --wait "~ # " images/vmlinuz-lts 2>&1 >/dev/null | sed -n 's/^steps \([0-9]*\) .* at \([0-9a-f:]*\) .*/\1 \2/p')
    jit=$(build/g86m --jit --headless --initrd images/initramfs-mini --wait "~ # " images/vmlinuz-lts 2>&1 >/dev/null | sed -n 's/^steps \([0-9]*\) .* at \([0-9a-f:]*\) .*/\1 \2/p')
    if [ -n "$plain" ] && [ "$plain" = "$jit" ]; then
        echo "ok    jit: the Linux boot stops where it does without it ($plain)"
    else
        fail=1
        echo "FAIL  jit: the Linux boot stops at \"$jit\", without the JIT at \"$plain\""
    fi
else
    echo "skip  jit: Linux boot (images/vmlinuz-lts and images/initramfs-mini are not there)"
fi

# Operating-system boots. The disk images are not in the repository; a missing image is skipped
# and reported, never counted as a pass.
if [ -f images/fd2880.img ]; then
    for exe in build/g86m-debug build/g86m; do
        out=$("$exe" --max 600000000 \
            --wait "login:" --type "root\n" --wait "# " \
            --type "uname -a\n" --wait "ibmpc i8086" \
            --type "ls /bin | head -3; echo done-\$?\n" --wait "done-0" \
            images/fd2880.img 2>"build/elks.err")
        if [ $? -eq 0 ] && echo "$out" | grep -q "ELKS elks 0.9.1"; then
            echo "ok    elks shell ($(basename "$exe"))"
        else
            fail=1
            echo "FAIL  elks shell ($(basename "$exe")): $(tail -1 build/elks.err)"
        fi
    done
else
    echo "skip  elks shell (images/fd2880.img is not there)"
fi

# FreeDOS, twice: the normal startup (language menu, decline the installer, prompt), and the F5
# path (skip CONFIG.SYS, tell the kernel where the shell is, prompt).
if [ -f images/fd14boot.img ]; then
    for exe in build/g86m-debug build/g86m; do
        out=$("$exe" --headless --max 3000000000 \
            --wait "Select from Menu" --type '\n' \
            --wait "[Y,N]?" --type 'n\n' \
            --wait 'A:\>' --type 'dir /w\n' --wait "bytes free" \
            images/fd14boot.img 2>"build/freedos.err")
        if [ $? -eq 0 ] && echo "$out" | grep -q "has been aborted"; then
            echo "ok    freedos startup ($(basename "$exe"))"
        else
            fail=1
            echo "FAIL  freedos startup ($(basename "$exe")): $(tail -1 build/freedos.err)"
        fi
        out=$("$exe" --headless --max 900000000 \
            --wait "FreeDOS kernel" --type '\k3F' \
            --wait "full shell command line" --type '\FREEDOS\BIN\COMMAND.COM\n' \
            --wait 'A:\>' --type 'ver /r\n' --wait "DOS version" \
            --type 'dir /w\n' --wait "bytes free" \
            --type 'echo Done-%COMSPEC%\n' --wait 'Done-A:\FREEDOS\BIN\COMMAND.COM' \
            images/fd14boot.img 2>"build/freedos.err")
        if [ $? -eq 0 ] && echo "$out" | grep -q "FreeDOS kernel 2043"; then
            echo "ok    freedos with F5 ($(basename "$exe"))"
        else
            fail=1
            echo "FAIL  freedos with F5 ($(basename "$exe")): $(tail -1 build/freedos.err)"
        fi
    done
else
    echo "skip  freedos startup and freedos with F5 (images/fd14boot.img is not there)"
fi

# test386: a ROM that tests a 386 instruction by instruction in real, protected and virtual-8086
# mode, with paging. It must reach diagnostic code FF, and what it prints on the serial port must
# be the reference taken from real hardware, byte for byte.
if [ -f images/test386.bin ] && [ -f images/test386-EE-reference.txt ]; then
    for exe in build/g86m-debug build/g86m; do
        "$exe" --headless --max 3000000000 --com build/test386.out images/test386.bin >/dev/null 2>build/test386.err
        last=$(sed -n 's/.* post \(.*\) com .*/\1/p' build/test386.err | awk '{print $NF}')
        if [ "$last" != "ff" ]; then
            fail=1
            echo "FAIL  test386 ($(basename "$exe")): stopped at code ${last:-none}"
        elif ! cmp -s build/test386.out images/test386-EE-reference.txt; then
            fail=1
            echo "FAIL  test386 ($(basename "$exe")): reached FF but the output differs from the reference"
        else
            echo "ok    test386 ($(basename "$exe")): code FF, $(wc -l < build/test386.out | tr -d ' ') lines match the reference"
        fi
    done
else
    echo "skip  test386 (images/test386.bin and its reference are not there)"
fi

# Linux: the kernel is loaded directly and must get as far as printing its banner on the serial
# console. Release build only: this is half a billion instructions.
if [ -f images/vmlinuz-lts ] && [ -f images/initramfs-mini ]; then
    out=$(build/g86m --max 8000000000 --initrd images/initramfs-mini \
        --wait "~ # " --type "uname -m\n" --wait "~ # " \
        --type "printf '%f' 3; echo\n" --wait "~ # " \
        --type "printf '%g %e' 0.1 12345.678; echo\n" --wait "~ # " \
        --type "awk 'BEGIN{print sqrt(2), atan2(1,1)*4, int(-3.7)}'\n" --wait "~ # " \
        --type "a=\$(cut -d. -f1 /proc/uptime); sleep 3; b=\$(cut -d. -f1 /proc/uptime); echo slept-\$((b-a))\n" --wait "~ # " \
        images/vmlinuz-lts 2>"build/linux.err" | tr -d '\r')
    status=$?
    if echo "$out" | grep -q "^i686$" && echo "$out" | grep -q "^3\.000000$" \
        && echo "$out" | grep -q "^0\.1 1\.234568e+04$" \
        && echo "$out" | grep -q "^1\.41421 3\.14159 -3$" && echo "$out" | grep -Eq "^slept-[34]$"; then
        echo "ok    linux shell (g86m): $(echo "$out" | grep -c '') lines; uname, printf %f %g %e, awk, sleep 3"
    else
        fail=1
        echo "FAIL  linux shell (g86m): the session did not give the expected answers"
        echo "$out" | tail -12 | sed 's/^/    |/'
        tail -1 "build/linux.err" | sed 's/^/  stderr:   /'
    fi
else
    echo "skip  linux shell (images/vmlinuz-lts and images/initramfs-mini are not there)"
fi

# The interactive console, driven through a pseudo-terminal. It takes the images that are there.
if command -v python3 >/dev/null; then
    python3 -I tools/console_test.py build/g86m images 2>/dev/null || fail=1
else
    echo "skip  console (python3 is not there)"
fi
exit $fail
