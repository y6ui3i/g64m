// switch: twelve cases next to each other (a table of addresses), and five far apart
// (comparisons).
// flags: int
#include "prim.h"
static u8 ops[4096];
static u32 keys[4096];
NOINLINE static u64 dense(const u8 *p, int n) {
    u64 a = 1;
    for (int i = 0; i < n; i++) {
        switch (p[i]) {
        case 0: a += 3; break;
        case 1: a ^= a >> 5; break;
        case 2: a *= 5; break;
        case 3: a -= i; break;
        case 4: a |= 1; break;
        case 5: a = ~a; break;
        case 6: a <<= 1; break;
        case 7: a += a >> 60; break;
        case 8: a ^= 0xABCD; break;
        case 9: a -= 9; break;
        case 10: a += i * 2; break;
        default: a++; break;
        }
    }
    return a;
}
NOINLINE static u64 sparse(const u32 *p, int n) {
    u64 a = 0;
    for (int i = 0; i < n; i++) {
        switch (p[i]) {
        case 3: a += 1; break;
        case 1000: a ^= i; break;
        case 70000: a += 5; break;
        case 9000000: a -= 2; break;
        case 0x40000000: a <<= 1; break;
        default: a += 7; break;
        }
    }
    return a;
}
int main(void) {
    static const u32 far[8] = { 3, 1000, 70000, 9000000, 0x40000000, 5, 6, 7 };
    for (int i = 0; i < 4096; i++) { u64 r = next(); ops[i] = r % 12; keys[i] = far[r >> 20 & 7]; }
    u64 s = 0, t = 0;
    for (int k = 0; k < 300; k++) {
        // Each round changes what the next works on, so that none can be left out.
        ops[k * 7 & 4095] = (s + k) % 12;
        keys[k * 5 & 4095] = far[t & 7];
        s += dense(ops, 4096);
        t += sparse(keys, 4096);
    }
    put("dense", s);
    put("sparse", t);
    return 0;
}
