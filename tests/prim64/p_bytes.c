// Bytes: text counted, changed and compared one character at a time.
// flags: int
#include "prim.h"
static char text[8192], other[8192];
NOINLINE static u64 length(const char *s) { const char *p = s; while (*p) p++; return p - s; }
NOINLINE static u64 words(const char *s) {
    u64 n = 0; int in = 0;
    for (; *s; s++) {
        int space = *s == ' ' || *s == '\n';
        if (!space && !in) n++;
        in = !space;
    }
    return n;
}
NOINLINE static void upper(char *d, const char *s) {
    for (; *s; s++) *d++ = *s >= 'a' && *s <= 'z' ? *s - 32 : *s;
    *d = 0;
}
NOINLINE static int compare(const char *x, const char *y) {
    while (*x && *x == *y) { x++; y++; }
    return (u8)*x - (u8)*y;
}
int main(void) {
    for (int i = 0; i < 8191; i++) { u64 r = next() % 30; text[i] = r < 26 ? 'a' + r : r < 29 ? ' ' : '\n'; }
    u64 s = 0;
    for (int k = 0; k < 150; k++) {
        s += length(text) + words(text);
        upper(other, text);
        s += compare(other, text) + other[k];
    }
    put("bytes", s);
    return 0;
}
