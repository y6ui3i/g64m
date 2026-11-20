// Large numbers: two of 256 bits multiplied into one of 512, a product of 128 bits from
// every pair of parts and the carry handed on; and two of 256 bits added.
// flags: int
#include "prim.h"
typedef unsigned __int128 u128;
static u64 a[4], b[4], r[8];
NOINLINE static void mul(u64 *out, const u64 *x, const u64 *y) {
    for (int i = 0; i < 8; i++) out[i] = 0;
    for (int i = 0; i < 4; i++) {
        u64 carry = 0;
        for (int j = 0; j < 4; j++) {
            u128 t = (u128)x[i] * y[j] + out[i + j] + carry;
            out[i + j] = (u64)t;
            carry = (u64)(t >> 64);
        }
        out[i + 4] = carry;
    }
}
NOINLINE static u64 add(u64 *x, const u64 *y) {
    u128 c = 0;
    for (int i = 0; i < 4; i++) { c += (u128)x[i] + y[i]; x[i] = (u64)c; c >>= 64; }
    return (u64)c;
}
int main(void) {
    for (int i = 0; i < 4; i++) { a[i] = next(); b[i] = next(); }
    u64 s = 0;
    for (int k = 0; k < 150000; k++) {
        mul(r, a, b);
        s += add(a, r + 2);
        b[k & 3] ^= r[k & 7];
    }
    put("bignum", s ^ r[0] ^ r[7] ^ a[3]);
    return 0;
}
