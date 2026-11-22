import re
R16 = r'\b(ax|bx|cx|dx|si|di|bp|sp|r\d+w)\b'
def cat(mn, ops):
    if mn.startswith('rep') or re.match(r'(movs|stos|cmps|scas|lods)[bwdq]?$', mn): return 'string'
    if mn.startswith('v'): return 'AVX'
    if re.match(r'f(?!xsave|xrstor)', mn): return 'x87'
    if 'xmm' in ops or 'mm' in ops.split(',')[0]:
        if re.search(r'(ss|sd)$', mn) or mn.startswith(('cvt', 'ucomis', 'comis')): return 'SSE scalar'
        if mn in ('movq', 'movd'): return 'SSE moves'
        if re.match(r'mov(aps|apd|ups|upd|dqa|dqu|lps|hps|lpd|hpd)$', mn): return 'SSE moves'
        return 'SSE packed'
    if mn in ('bt', 'bts', 'btr', 'btc'): return 'BT'
    if mn in ('rol', 'ror', 'rcl', 'rcr'): return 'rotate'
    dst = ops.split(',')[0]
    if mn not in ('movzx', 'movsx', 'movsxd') and (re.search(R16, dst) or (dst.startswith('word ptr'))) : return '16-bit'
    if mn.startswith('j') and mn != 'jmp': return 'Jcc'
    if mn in ('jmp', 'call', 'ret', 'push', 'pop', 'leave'):
        return 'jump via operand' if mn in ('jmp', 'call') and not re.match(r'^[0-9a-f]+ <', ops) else 'branch/stack'
    if mn.startswith(('cmov', 'set')): return 'cmov/set'
    if mn in ('bsf', 'bsr', 'tzcnt', 'lzcnt', 'popcnt', 'shld', 'shrd', 'bswap', 'xchg', 'cmpxchg', 'xadd', 'cpuid', 'rdtsc', 'syscall'): return 'other: ' + mn
    if mn in ('mul', 'imul', 'div', 'idiv'): return 'mul/div'
    return 'integer'
