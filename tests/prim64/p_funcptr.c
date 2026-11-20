// Pointers to functions: one of eight called by a number from the data, and a function
// handed to another that calls it for every element.
// flags: int
#include "prim.h"
static u64 f0(u64 x) { return x + 1; }
static u64 f1(u64 x) { return x * 3; }
static u64 f2(u64 x) { return x ^ 0x55; }
static u64 f3(u64 x) { return x >> 1; }
static u64 f4(u64 x) { return x - 7; }
static u64 f5(u64 x) { return ~x; }
static u64 f6(u64 x) { return x << 2; }
static u64 f7(u64 x) { return x | 0x100; }
static u64 (*const table[8])(u64) = { f0, f1, f2, f3, f4, f5, f6, f7 };
static u8 which[4096];
NOINLINE static u64 by_table(u64 x, const u8 *w, int n) {
    for (int i = 0; i < n; i++) x = table[w[i]](x);
    return x;
}
NOINLINE static u64 each(u64 (*f)(u64), const u8 *w, int n) {
    u64 s = 0;
    for (int i = 0; i < n; i++) s += f(w[i]);
    return s;
}
int main(void) {
    for (int i = 0; i < 4096; i++) which[i] = next() & 7;
    u64 x = 1, s = 0;
    for (int k = 0; k < 300; k++) { x = by_table(x, which, 4096); s += each(table[k & 7], which, 4096); }
    put("table", x);
    put("each", s);
    return 0;
}
