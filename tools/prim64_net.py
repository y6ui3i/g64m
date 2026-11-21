# Host instructions and cycles for a guest instruction under --jit, net of the emulator's
# start (E129): the long programs
# (tools/prim64_long.sh) less a program that does nothing
import subprocess,re,sys,glob,os
def run(f):
    r=subprocess.run(['/usr/bin/time','-l','build/g64m','--jit','--max','1000000000000','--jit-stats',f],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE).stderr
    i=int(re.search(rb'(\d+)\s+instructions retired',r)[1]); c=int(re.search(rb'(\d+)\s+cycles elapsed',r)[1])
    g=int(re.search(rb' of (\d+) instructions in blocks',r)[1])
    return i,c,g
bi,bc,bg=run('build/long/p_none.elf')
names=sys.argv[1:] or [os.path.basename(f)[:-4] for f in sorted(glob.glob('build/long/p_*.elf')) if 'p_none' not in f]
for n in names:
    i,c,g=run('build/long/'+n+'.elf')
    print('%-12s %6.2f host instructions, %5.2f cycles for a guest instruction'%(n,(i-bi)/g,(c-bc)/g))
