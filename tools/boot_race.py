#!/usr/bin/env python3
# The boot raced (E134): the same kernel and initramfs to the shell's prompt, under QEMU's
# machine (TCG: no hardware virtualization can run an x86 guest on this host) and under
# g64m with and without --jit. Wall-clock seconds from the start of the emulator to the
# prompt on the serial console, the best of three. QEMU's time has its firmware in it,
# which loads the kernel; g64m begins at the kernel's entry, and stops itself at the prompt
# (--wait), its console being written out when it ends.
#
#   python3 -I tools/boot_race.py
import subprocess, time, sys, os
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
K, I = 'images/vmlinuz64-lts', 'images/initramfs64-mini'
APPEND = 'console=ttyS0 tsc=reliable'
def run_out(cmd, limit=180):
    best = None
    for _ in range(3):
        t = time.perf_counter()
        r = subprocess.run(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=limit)
        took = time.perf_counter() - t
        if b'the script done' in r.stderr and (best is None or took < best): best = took
    return best

def race(cmd, want=b'~ # ', limit=180):
    best = None
    for _ in range(3):
        t = time.perf_counter()
        p = subprocess.Popen(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        os.set_blocking(p.stdout.fileno(), False)
        seen = b''
        took = None
        while time.perf_counter() - t < limit:
            try:
                c = p.stdout.read(65536)
            except BlockingIOError:
                c = None
            if c:
                seen += c
                if want in seen:
                    took = time.perf_counter() - t
                    break
            elif p.poll() is not None:
                break
            else:
                time.sleep(0.002)
        p.kill(); p.wait()
        if took is not None and (best is None or took < best): best = took
    return best
rows = [
    ('QEMU (TCG)', ['qemu-system-x86_64', '-accel', 'tcg', '-m', '256', '-nographic', '-no-reboot', '-kernel', K, '-initrd', I, '-append', APPEND]),
    ('g64m --jit', ['build/g64m', '--jit', '--headless', '--initrd', I, '--wait', '~ # ', '--max', '600000000000', K]),
    ('g64m', ['build/g64m', '--headless', '--initrd', I, '--wait', '~ # ', '--max', '600000000000', K]),
]
for name, cmd in rows:
    if len(sys.argv) > 1 and sys.argv[1] not in name: continue
    t = race(cmd) if name.startswith('QEMU') else run_out(cmd)
    print('%-12s %s' % (name, ('%.2f s' % t) if t else 'no prompt'))
