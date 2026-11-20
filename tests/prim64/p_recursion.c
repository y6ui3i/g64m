// Recursion: a function that calls itself twice, and one that goes down a tree it builds
// on the stack.
// flags: int
#include "prim.h"
NOINLINE static u64 fib(u64 n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }
NOINLINE static u64 depth(u64 n, u64 *up) {
    u64 here = n * 3 + (up ? *up : 0);
    if (n == 0) return here;
    return depth(n - 1, &here) ^ here;
}
int main(void) {
    put("fib", fib(27));
    u64 s = 0;
    for (int k = 0; k < 2000; k++) s += depth(200, 0);
    put("depth", s);
    return 0;
}
