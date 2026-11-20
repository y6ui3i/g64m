// if and else: chains of comparisons whose arms store to memory, so that they stay jumps.
// flags: int
#include "prim.h"
static u32 data[4096];
static u64 count[6];
NOINLINE static void sort_out(const u32 *p, int n) {
    for (int i = 0; i < n; i++) {
        u32 v = p[i];
        if (v < 10) count[0]++;
        else if (v < 100) count[1] += v;
        else if (v < 1000) { if (v & 1) count[2]++; else count[3] += 2; }
        else if ((i32)v < 0) count[4]++;
        else count[5] ^= v;
    }
}
int main(void) {
    for (int i = 0; i < 4096; i++) { u64 r = next(); data[i] = (u32)(r >> (r & 31)); }
    for (int k = 0; k < 400; k++) sort_out(data, 4096);
    for (int i = 0; i < 6; i++) put("if", count[i]);
    return 0;
}
