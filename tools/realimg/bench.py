import json, sys, hashlib
k = int(sys.argv[1]) if len(sys.argv) > 1 else 1
def fib(n): return n if n < 2 else fib(n-1) + fib(n-2)
fib(20 + k)
s = [str(i) * 3 for i in range(40000 * k)]; ",".join(s).split(",")
d = [{"a": i, "b": [i, i * 2], "c": "x" * 10} for i in range(4000 * k)]
for _ in range(5): json.loads(json.dumps(d))
sorted(range(60000 * k), key=lambda x: (x * 7919) % 10007)
hashlib.sha256(b"x" * (4000000 * k)).hexdigest()
print("ok")
