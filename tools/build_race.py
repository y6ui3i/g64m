#!/usr/bin/env python3
# NetHack built by the guest's own GCC (E135), under g64m and under QEMU's machine: the
# same kernel, initramfs and disk (images/disk64-dev.img: Alpine with GCC, make and
# NetHack's source, configured; each run gets its own copy in build/). Seconds from the
# start of the emulator to the end of `make all` and `make install`, and whether the
# NetHack that was built says its version.
#
#   python3 -I tools/build_race.py g64m [options for build/g64m, default --jit]
#   python3 -I tools/build_race.py qemu
import subprocess, time, sys, os, shutil, re, resource
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
K, I, D = 'images/vmlinuz64-lts', 'images/initramfs64-disk', 'images/disk64-dev.img'
CMD = ('export PATH=/usr/sbin:/usr/bin:/sbin:/bin; cd /root/NetHack-3.6.7; '
       'make all > /root/build.log 2>&1; echo make-rc=$?; '
       'make install > /root/install.log 2>&1; echo install-rc=$?; '
       '/nh2/nethack --version; tail -2 /root/build.log; sync; echo fin$((6*7))\n')
# RACE_SHORT=1: three of NetHack's files only (a minute or two), for trying a change.
# RACE_X64 names another build of g64m than build/g64m.
if os.environ.get('RACE_SHORT'):
    CMD = ('export PATH=/usr/sbin:/usr/bin:/sbin:/bin; cd /root/NetHack-3.6.7/src; '
           'make apply.o artifact.o attrib.o > /root/build.log 2>&1; echo make-rc=$?; ls -l apply.o artifact.o attrib.o | wc -l; sync; echo fin$((6*7))\n')
who = sys.argv[1] + ('-short' if os.environ.get('RACE_SHORT') else '')
disk = 'build/race-%s.img' % who
shutil.copyfile(D, disk)
# /usr/bin/time -l (macOS) says the instructions the program retired and its cycles (E154):
# the count of instructions does not depend on which core ran it or what else ran.
TIME = ['/usr/bin/time', '-l'] if sys.platform == 'darwin' else []
t0 = time.perf_counter()
if who.startswith('g64m'):
    opts = sys.argv[2:] or ['--jit']
    r = subprocess.run(TIME + [os.environ.get('RACE_X64', 'build/g64m')] + opts + ['--rtc', 'host', '--disk', disk, '--keep', '--initrd', I,
                        '--wait', 'root on /dev/sda', '--wait', '~ # ', '--type', CMD, '--wait', 'fin42',
                        '--type', 'off\n', '--wait', 'System halted', '--max', '40000000000000', K],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    took = time.perf_counter() - t0
    out = r.stdout
    open('build/race-%s.err' % who, 'wb').write(r.stderr)
    m = re.search(rb'g64m: (\d+) instructions', r.stderr)
    print('guest instructions:', m[1].decode() if m else '?')
    for l in r.stderr.split(b'\n'):
        if b'jit:' in l: print(l.decode(errors='replace')[-200:])
else:
    p = subprocess.Popen(TIME + ['qemu-system-x86_64', '-accel', 'tcg', '-m', '256', '-nographic', '-no-reboot',
                          '-kernel', K, '-initrd', I, '-append', 'console=ttyS0 tsc=reliable',
                          # The disk where the guest's driver (pata_legacy) looks for it: an IDE
                          # controller on the ISA bus, which QEMU's q35 machine can be given.
                          '-M', 'q35', '-device', 'isa-ide,iobase=0x1f0,iobase2=0x3f6,irq=14,id=ide0',
                          '-drive', 'if=none,id=d0,file=%s,format=raw' % disk, '-device', 'ide-hd,drive=d0,bus=ide0.0'],
                         stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=open('build/race-%s.err' % who, 'wb'))
    os.set_blocking(p.stdout.fileno(), False)
    out = b''
    def wait(text, limit):
        global out
        end = time.perf_counter() + limit
        at = len(out)
        while time.perf_counter() < end:
            try: c = p.stdout.read(65536)
            except BlockingIOError: c = None
            if c:
                out += c
                if text in out[max(0, at - len(text)):]: return True
            elif p.poll() is not None: return False
            else: time.sleep(0.01)
        return False
    ok = wait(b'root on /dev/sda', 120) and wait(b'~ # ', 60)
    if ok:
        p.stdin.write(CMD.encode()); p.stdin.flush()
        ok = wait(b'fin42', 4 * 3600)
    took = time.perf_counter() - t0
    if ok:
        p.stdin.write(b'off\n'); p.stdin.flush(); wait(b'System halted', 60)
    # (QEMU ends by itself when the guest powers off; /usr/bin/time then says what it took.)
    try: p.wait(timeout=20)
    except subprocess.TimeoutExpired: p.kill(); p.wait()
open('build/race-%s.out' % who, 'wb').write(out)
text = out.decode(errors='replace')
tail = text[text.rfind('make-rc='):] if 'make-rc=' in text else text[-400:]
# The CPU time of what was run (E143: a wall clock on a host with other work moves more
# than the changes being measured).
ru = resource.getrusage(resource.RUSAGE_CHILDREN)
print('%s: %.1f s, CPU %.1f s user and %.1f s system' % (who, took, ru.ru_utime, ru.ru_stime))
err = open('build/race-%s.err' % who, 'rb').read()
mi = re.search(rb'(\d+)\s+instructions retired', err)
mc = re.search(rb'(\d+)\s+cycles elapsed', err)
if mi and mc: print('%s: %.2f billion host instructions retired, %.2f billion cycles' % (who, int(mi[1]) / 1e9, int(mc[1]) / 1e9))
print(tail.replace('\r', '')[:600])
