// The conditional operator: smaller and larger of two, the absolute value, a value kept
// between two bounds, and a comparison's result used as a number.
// flags: int
#include "prim.h"
static i64 data[4096];
NOINLINE static i64 run(const i64 *p, int n) {
    i64 lo = p[0], hi = p[0], sum = 0, in = 0;
    for (int i = 0; i < n; i++) {
        i64 v = p[i];
        lo = v < lo ? v : lo;
        hi = v > hi ? v : hi;
        sum += v < 0 ? -v : v;
        i64 c = v < -1000 ? -1000 : v > 1000 ? 1000 : v;
        sum ^= c;
        in += (v & 0xFF) < 100;
    }
    return lo ^ hi ^ sum ^ in << 40;
}
int main(void) {
    for (int i = 0; i < 4096; i++) data[i] = (i64)next() >> 40;
    i64 r = 0;
    // Each round changes what the next works on, so that none can be left out.
    for (int k = 0; k < 400; k++) { data[k * 7 & 4095] ^= r >> 3; r += run(data, 4096); }
    put("ternary", (u64)r);
    return 0;
}
