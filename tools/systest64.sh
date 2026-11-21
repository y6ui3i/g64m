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

"$GOOSE" build --debug -o build/g64m-debug src/g64m.goose >/dev/null || exit 2
"$GOOSE" build -o build/g64m src/g64m.goose >/dev/null || exit 2

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

# The disk for y_ide: 2,048 sectors, word i of sector n holding n * 257 + i * 3.
python3 -c "
import struct
open('build/s64/ide.img','wb').write(b''.join(struct.pack('<256H',*[(n*257+i*3)&0xFFFF for i in range(256)]) for n in range(2048)))"
# What a test is given beyond its image, by this program and by QEMU.
ours() { case "$1" in y_ide) echo "--disk build/s64/ide.img" ;; esac; }
theirs() { case "$1" in y_ide) echo "-drive file=ide.img,format=raw,if=ide,snapshot=on" ;; esac; }

QEMU="timeout 30 qemu-system-x86_64 -cpu max -m 64 -display none -no-reboot -serial stdio -device isa-debug-exit,iobase=0xf4,iosize=4"
if [ -n "${ORACLE_HOST:-}" ]; then
    ssh "$ORACLE_HOST" 'mkdir -p g86m-oracle/s' || exit 2
    for asm in $list; do
        name=$(basename "$asm" .asm)
        scp -q "build/s64/$name" "$ORACLE_HOST:g86m-oracle/s/" || exit 2
        x=$(theirs "$name")
        if [ -n "$x" ]; then scp -q build/s64/ide.img "$ORACLE_HOST:g86m-oracle/s/" || exit 2; fi
        ssh "$ORACLE_HOST" "cd g86m-oracle/s && $QEMU $x -accel kvm -kernel $name > $name.1 2>/dev/null; echo \$? > $name.rc; $QEMU $x -accel kvm -kernel $name > $name.2 2>/dev/null; $QEMU $x -accel tcg -kernel $name > $name.tcg 2>/dev/null; cmp -s $name.1 $name.2 && test -s $name.1 && test \$(cat $name.rc) = 1 && { cmp -s $name.1 $name.tcg || echo 'note  $name: QEMU without KVM prints differently' >&2; cat $name.1; }" > "build/s64/$name.new"
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
    build/g64m-debug $(ours "$name") "build/s64/$name" > "build/s64/$name.out" 2> "build/s64/$name.err"
    if ! build/g64m ${X64:-} $(ours "$name") "build/s64/$name" 2>/dev/null | cmp -s - "$exp"; then
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
        out=$(build/g64m ${X64:-} --initrd images/initramfs64-mini --wait "~ # " \
            --type 'uname -m; echo $((6*7)) > /tmp/a; cat /tmp/a; grep -c processor /proc/cpuinfo; echo end-$?\n' --wait "end-0" \
            images/vmlinuz64-lts 2>build/s64/linux.err | tr -d '\r' | sed -n '/^x86_64$/,$p' | tr '\n' ' ' | sed 's/ *$//')
        n1=$(sed -n 's/^g64m: \([0-9]*\) instructions.*/\1/p' build/s64/linux.err)
        n0=$n1
        # With options (X64, the JIT's), the boot must take the plain boot's instructions.
        if [ -n "${X64:-}" ]; then
            n0=$(build/g64m --initrd images/initramfs64-mini --wait "~ # " \
                --type 'uname -m; echo $((6*7)) > /tmp/a; cat /tmp/a; grep -c processor /proc/cpuinfo; echo end-$?\n' --wait "end-0" \
                images/vmlinuz64-lts 2>&1 >/dev/null | sed -n 's/^g64m: \([0-9]*\) instructions.*/\1/p')
        fi
        if [ "$n0" != "$n1" ]; then
            fail=1
            echo "FAIL  linux64 shell: $n1 instructions with $X64, $n0 without"
        elif [ "$out" = "x86_64 42 1 end-0" ]; then
            echo "ok    linux64 shell: $(sed -n 's/^g64m: \([0-9]*\) instructions.*/\1/p' build/s64/linux.err) instructions to the end of the script"
        else
            fail=1
            echo "FAIL  linux64 shell: printed \"$out\""
            tail -2 build/s64/linux.err | sed 's/^/  /'
        fi
    else
        echo "skip  linux64 shell (images/vmlinuz64-lts and images/initramfs64-mini are not there)"
    fi
    # From the disk (E101): the initramfs loads the driver, finds an ext2 root on /dev/sda and
    # moves there. A file is written and the machine stopped with `off`; a second boot, of the
    # same image, reads it. The image is a copy, kept with --keep, so images/disk64.img stays
    # as it was made.
    if [ -f images/disk64.img ] && [ -f images/initramfs64-disk ]; then
        cp images/disk64.img build/s64/disk64.img
        build/g64m ${X64:-} --disk build/s64/disk64.img --keep --initrd images/initramfs64-disk --wait "root on /dev/sda" --wait "~ # " \
            --type 'echo kept-$((6*7)) > /f; mount | grep -c "sda on / type ext2"; off\n' --wait "System halted" \
            images/vmlinuz64-lts > build/s64/disk1.out 2>build/s64/disk1.err
        out=$(build/g64m ${X64:-} --disk build/s64/disk64.img --initrd images/initramfs64-disk --wait "root on /dev/sda" --wait "~ # " \
            --type 'cat /f; echo end-$?\n' --wait "end-0" images/vmlinuz64-lts 2>build/s64/disk2.err | tr -d '\r' | sed -n '/^kept-42$/,$p' | tr '\n' ' ' | sed 's/ *$//')
        if [ "$out" = "kept-42 end-0" ]; then
            echo "ok    linux64 disk: an ext2 root on /dev/sda; a file written before \`off\` is there at the next boot"
        else
            fail=1
            echo "FAIL  linux64 disk: the second boot printed \"$out\""
            tail -2 build/s64/disk1.err | sed 's/^/  /'
            tail -2 build/s64/disk2.err | sed 's/^/  /'
        fi
    else
        echo "skip  linux64 disk (images/disk64.img and images/initramfs64-disk are not there; tools/images/make-disk.sh makes them)"
    fi

    # A program built on a real x86_64 Linux host, run as it is (E115): NetHack, statically
    # linked there, started in the guest, a character taken, the first level drawn and the
    # inventory opened.
    if [ -f images/disk64-nh.img ] && [ -f images/initramfs64-disk ]; then
        cp images/disk64-nh.img build/s64/disk64-nh.img
        build/g64m ${X64:-} --disk build/s64/disk64-nh.img --initrd images/initramfs64-disk --wait "root on /dev/sda" --wait "~ # " \
            --type '/nh/nethack -u g86m\n' --wait "pick" --type 'y' --wait "Is this ok" --type 'y' --wait "Dlvl" \
            --type ' ' --type 'i' --wait "(end)" --max 12000000000 images/vmlinuz64-lts > build/s64/nh.out 2>build/s64/nh.err
        if grep -q "the script done" build/s64/nh.err && grep -a -q "Dlvl:1" build/s64/nh.out && grep -a -q "Weapons" build/s64/nh.out; then
            echo "ok    linux64 NetHack: built on a real x86_64 host, run in the guest to its first level and the inventory"
        else
            fail=1
            echo "FAIL  linux64 NetHack"
            tail -2 build/s64/nh.err | sed 's/^/  /'
        fi
    else
        echo "skip  linux64 NetHack (images/disk64-nh.img is not there; tools/images/make-nethack.sh makes it)"
    fi
    # On a network (E102): the card found on PCI, an address by DHCP, the gateway pinged.
    # Nothing leaves the host: the gateway is libslirp's.
    if [ -f images/initramfs64-net ] && build/g64m ${X64:-} --net build/s64/y_first >/dev/null 2>&1; then
        out=$(build/g64m ${X64:-} --net --headless --initrd images/initramfs64-net --wait "root on" --wait "# " \
            --type "ifconfig eth0 | grep -c 'inet addr:10.0.2.15'\n" --wait "# " \
            --type "ping -c 3 10.0.2.2 | grep -c '3 packets received'\n" --wait "# " \
            images/vmlinuz64-lts 2>build/s64/net.err | tr -d '\r')
        if [ "$(echo "$out" | grep -c '^1$')" = 2 ]; then
            echo "ok    linux64 on a network: the card on PCI, an address by DHCP, the gateway pinged"
        else
            fail=1
            echo "FAIL  linux64 on a network: no address, or no answer from the gateway"
            echo "$out" | tail -6 | sed 's/^/    |/'
        fi
    else
        echo "skip  linux64 on a network (libslirp or images/initramfs64-net is not there)"
    fi
    # On a frame buffer (E103): the loader tells the kernel of one, the kernel's efifb takes it
    # and puts its console there; a line typed at the keyboard (through the 8042, not the
    # serial port) is read from that console; the run's last frame is saved and has to have
    # the console's text on it. No window is opened: this run is scripted.
    rm -f build/s64/fb.ppm
    out=$(build/g64m ${X64:-} --headless --fb 1024x768 --shot build/s64/fb.ppm --append "console=tty0 console=ttyS0 tsc=reliable" \
        --initrd images/initramfs64-mini --wait "~ # " \
        --type 'cat /sys/class/graphics/fb0/virtual_size; (sleep 2; echo ready-$((1+1))) & read x < /dev/tty0; echo got-$x\n' \
        --wait "ready-2" --keys 'Typed at the keyboard, 100%!\n' --wait "got-Typed" --wait "~ # " \
        images/vmlinuz64-lts 2>build/s64/fb.err | tr -d '\r')
    lit=$(tail -c +16 build/s64/fb.ppm 2>/dev/null | tr -d '\000' | wc -c | tr -d ' ')
    if echo "$out" | grep -q "^1024,768$" && echo "$out" | grep -q "^got-Typed at the keyboard, 100%!$" && [ "$(wc -c < build/s64/fb.ppm | tr -d ' ')" = 2359312 ] && [ "$lit" -gt 20000 ]; then
        echo "ok    linux64 on a frame buffer: efifb at 1024x768, the console drawn ($lit bytes of the frame are not black), a line typed at the keyboard"
    else
        fail=1
        echo "FAIL  linux64 on a frame buffer: no fb0, nothing drawn ($lit bytes not black), or the typed line did not arrive"
        echo "$out" | tail -5 | sed 's/^/    |/'
    fi
    # The same kernel with a pseudo-terminal as its console (E100): a command typed, `sleep 3`
    # timed against the clock, Ctrl-] to leave.
    python3 -I tools/console_test.py build/g64m images 64 2>/dev/null || fail=1
fi
exit $fail
