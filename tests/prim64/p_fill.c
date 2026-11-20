// Filling and copying memory, as a library does it: the string instructions with a
// repeat count, for long stretches and for short ones.
// flags: int
#include "prim.h"
static u8 buf[1 << 16], dst[1 << 16];
static void fill(void *d, int c, u64 n) { __asm__ volatile("rep stosb" : "+D"(d), "+c"(n) : "a"(c) : "memory"); }
static void fill8(void *d, u64 v, u64 n) { __asm__ volatile("rep stosq" : "+D"(d), "+c"(n) : "a"(v) : "memory"); }
static void copy(void *d, const void *s, u64 n) { __asm__ volatile("rep movsb" : "+D"(d), "+S"(s), "+c"(n) : : "memory"); }
static void copy8(void *d, const void *s, u64 n) { __asm__ volatile("rep movsq" : "+D"(d), "+S"(s), "+c"(n) : : "memory"); }
int main(void) {
    u64 s = 0;
    for (int k = 0; k < 40; k++) {
        fill(buf, k, sizeof buf);
        fill8(buf + 8 * k, 0x0102030405060708 * k, 4096);
        copy(dst, buf, sizeof buf);
        copy8(dst + 16, buf, 4096);
        // Short ones: a few bytes at a time, as for the members of a structure.
        for (int i = 0; i < 2000; i++) { copy(dst + i * 16, buf + i * 8, 13); fill(buf + i * 8, i, 5); }
        s += dst[k * 100] + dst[40000 + k];
    }
    put("fill", s);
    return 0;
}
