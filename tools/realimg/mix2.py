# mix2.py PERFDATA ROOT : instruction mix of every sample of the workload (sudo/chroot/env left out),
# each sample's instruction read from its binary under ROOT by objdump.
import subprocess, re, sys, collections, os
data, root = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cls import cat
out = subprocess.run(['perf', 'script', '-i', data, '-F', 'comm,ip,dsoff'], capture_output=True, text=True).stdout
per = collections.defaultdict(collections.Counter); other = collections.Counter(); n = 0
for l in out.splitlines():
    m = re.match(r'\s*(\S+)\s+[0-9a-f]+\s+\((.*)\+0x([0-9a-f]+)\)', l)
    if not m:
        m2 = re.match(r'\s*(\S+)\s', l)
        if m2 and m2[1] not in ('sudo', 'chroot', 'env'): other['unknown'] += 1; n += 1
        continue
    if m[1] in ('sudo', 'chroot', 'env'): continue
    n += 1
    if m[2].startswith('['): other['JIT/unknown'] += 1; continue
    per[m[2]][int(m[3], 16)] += 1
mix = collections.Counter(); mn_c = collections.Counter(); bydso = collections.Counter()
for dso, offs in per.items():
    f = root + dso
    if not os.path.exists(f): other['no file'] += sum(offs.values()); continue
    loads = [(int(a, 16), int(b, 16), int(c, 16)) for a, b, c in
             re.findall(r'LOAD\s+0x([0-9a-f]+)\s+0x([0-9a-f]+)\s+0x[0-9a-f]+\s+0x([0-9a-f]+)', subprocess.run(['readelf', '-lW', f], capture_output=True, text=True).stdout)]
    dis = {}
    for l in subprocess.run(['objdump', '-d', '-w', '-M', 'intel', '--no-show-raw-insn', f], capture_output=True, text=True).stdout.splitlines():
        m = re.match(r'\s+([0-9a-f]+):\s+(?:(?:lock|data16|cs|ds|bnd|notrack|rex\.?\w*)\s+)*(\S+)\s*(.*)$', l)
        if m: dis[int(m[1], 16)] = (m[2], m[3])
    for off, c in offs.items():
        va = next((off - po + pv for po, pv, sz in loads if po <= off < po + sz), off)
        bydso[dso.split('/')[-1]] += c
        if va not in dis: other['not decoded'] += c; continue
        mn, ops = dis[va]; k = cat(mn, ops.lower()); mix[k] += c; mn_c[mn] += c
print('samples %d; ' % n + ', '.join('%s %.1f%%' % (k, 100 * v / n) for k, v in other.items()))
print('dsos:', ', '.join('%s %.1f%%' % (k, 100 * v / n) for k, v in bydso.most_common(6)))
print('mix:', ', '.join('%s %.1f%%' % (k, 100 * v / n) for k, v in mix.most_common()))
print('top:', ', '.join('%s %.1f%%' % (k, 100 * v / n) for k, v in mn_c.most_common(16)))
