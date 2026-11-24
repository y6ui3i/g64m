#!/usr/bin/env python3
# Three of NetHack's files built in the guest (tools/build_race.py's short form), with a
# look at the program that runs it (E149): the host's sampler (`sample`, macOS) on it for
# 20 seconds in the middle of the build, and for QEMU its monitor's `info jit` at the end.
#
#   python3 -I tools/build_look.py g64m [options for build/g64m, default --jit --jit-stats]
#   python3 -I tools/build_look.py qemu
#
# LOOK_AFTER and LOOK_FOR (seconds) say when the sampler starts and how long it looks: the
# build under g64m is under half a minute since E173, and the default would miss it.
#
# Leaves build/look-WHO.sample (the sampler's report), build/look-WHO.out (the console)
# and for QEMU build/look-qemu.jit (the monitor's answer); prints the report's leaves.
import subprocess, time, sys, os, shutil, socket, re
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
K, I, D = 'images/vmlinuz64-lts', 'images/initramfs64-disk', 'images/disk64-dev.img'
CMD = ('export PATH=/usr/sbin:/usr/bin:/sbin:/bin; cd /root/NetHack-3.6.7/src; '
       'make apply.o artifact.o attrib.o > /root/build.log 2>&1; echo make-rc=$?; sync; echo fin$((6*7))\n')
who = sys.argv[1]
disk = 'build/look-%s.img' % who
shutil.copyfile(D, disk)
SOCK = 'build/look-qemu.sock'
if who == 'g64m':
    opts = sys.argv[2:] or ['--jit', '--jit-stats']
    p = subprocess.Popen(['build/g64m'] + opts + ['--rtc', 'host', '--disk', disk, '--keep', '--initrd', I,
                          '--wait', 'root on /dev/sda', '--wait', '~ # ', '--type', CMD, '--wait', 'fin42',
                          '--type', 'off\n', '--wait', 'System halted', '--max', '40000000000000', K],
                         stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=open('build/look-g64m.err', 'wb'))
else:
    if os.path.exists(SOCK): os.remove(SOCK)
    p = subprocess.Popen(['qemu-system-x86_64', '-accel', 'tcg', '-m', '256', '-nographic', '-no-reboot',
                          '-kernel', K, '-initrd', I, '-append', 'console=ttyS0 tsc=reliable',
                          '-M', 'q35', '-device', 'isa-ide,iobase=0x1f0,iobase2=0x3f6,irq=14,id=ide0',
                          '-drive', 'if=none,id=d0,file=%s,format=raw' % disk, '-device', 'ide-hd,drive=d0,bus=ide0.0',
                          '-serial', 'stdio', '-monitor', 'unix:%s,server,nowait' % SOCK],
                         stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
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
def monitor(line):
    s = socket.socket(socket.AF_UNIX); s.connect(SOCK); s.settimeout(3)
    time.sleep(0.3); s.recv(65536)
    s.sendall(line.encode() + b'\n')
    got = b''
    try:
        while True:
            c = s.recv(65536)
            if not c: break
            got += c
    except socket.timeout: pass
    s.close()
    return got.decode(errors='replace')
t0 = time.perf_counter()
if who == 'g64m':
    ok = True                               # g64m types the command itself, about four seconds in
    time.sleep(4)
else:
    ok = wait(b'root on /dev/sda', 120) and wait(b'~ # ', 60)
    if ok: p.stdin.write(CMD.encode()); p.stdin.flush()
typed = time.perf_counter()
# The sampler, from a quarter of a minute into the build (a third of a minute under g64m).
time.sleep(float(os.environ.get('LOOK_AFTER', 26 if who == 'g64m' else 12)))
rep = 'build/look-%s.sample' % who
subprocess.run(['sample', str(p.pid), os.environ.get('LOOK_FOR', '20'), '-file', rep], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
ok = ok and wait(b'fin42', 3600)
took = time.perf_counter() - typed
if who != 'g64m':
    open('build/look-qemu.jit', 'w').write(monitor('info jit'))
    p.stdin.write(b'off\n'); p.stdin.flush(); wait(b'System halted', 60); p.kill()
p.wait()
open('build/look-%s.out' % who, 'wb').write(out)
text = out.decode(errors='replace')
print('%s: the build %.1f s; %s' % (who, took, 'make-rc=0' if 'make-rc=0' in text else 'the build failed or did not end'))
# The report's leaves: "Sort by top of stack, same collapsed (when >= 5):" and what follows.
r = open(rep, errors='replace').read()
at = r.find('Sort by top of stack')
print(r[at:at + 3200] if at >= 0 else r[:2000])
