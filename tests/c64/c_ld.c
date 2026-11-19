// A 64-bit test in C with `long double` (E098), which on x86_64 is the x87's 80 bits: sums,
// a square root by Newton's method, a number written out digit by digit the way a C
// library's printf does it, and comparisons. Built on an x86_64 Linux host with
//   gcc -O2 -static -nostdlib -ffreestanding -fno-pic -no-pie -fno-stack-protector \
//       -fcf-protection=none -Wl,--build-id=none -o c_ld.elf c_ld.c
// and kept as c_ld.elf beside this file. What is compared is the trace of every
// instruction; the x87's registers are not in it, so everything is stored on the way.
typedef unsigned long u64;
typedef unsigned char u8;

u8 stack[65536];
static char line[80];

static long sys(long n, long a, long b, long c) {
    long r;
    __asm__ volatile("syscall" : "=a"(r) : "a"(n), "D"(a), "S"(b), "d"(c) : "rcx", "r11", "memory");
    return r;
}

static void puts_n(const char *s, int n) { sys(1, 1, (long)s, n); }

static void put(const char *name, u64 v) {
    int n = 0;
    while (*name) line[n++] = *name++;
    line[n++] = ' ';
    for (int i = 60; i >= 0; i -= 4) line[n++] = "0123456789abcdef"[v >> i & 15];
    line[n++] = '\n';
    puts_n(line, n);
}

// The 80 bits of a long double: the mantissa, and the sign and exponent.
static void put_ld(const char *name, long double v) {
    union { long double d; struct { u64 m; unsigned short se; } b; } x;
    x.d = v;
    put(name, x.b.m);
    put(name, x.b.se);
}

__attribute__((noinline)) static long double root(long double x) {
    long double g = x > 1 ? x / 2 : 1;
    for (int i = 0; i < 9; i++) g = (g + x / g) / 2;
    return g;
}

// A number with twenty digits after the point, as printf would write it.
__attribute__((noinline)) static void decimal(long double v) {
    int n = 0;
    if (v < 0) { line[n++] = '-'; v = -v; }
    u64 whole = (u64)v;
    char tmp[24];
    int k = 0;
    do { tmp[k++] = '0' + whole % 10; whole /= 10; } while (whole);
    while (k) line[n++] = tmp[--k];
    line[n++] = '.';
    v -= (u64)v;
    for (int i = 0; i < 20; i++) {
        v *= 10;
        int d = (int)v;
        line[n++] = '0' + d;
        v -= d;
    }
    line[n++] = '\n';
    puts_n(line, n);
}

int main(void) {
    long double h = 0;
    for (int i = 1; i <= 40; i++) h += 1.0L / i;
    put_ld("harmonic", h);
    decimal(h);
    long double r = root(2.0L);
    put_ld("root2", r);
    decimal(r);
    decimal(-1.0L / 3);
    long double big = 18446744073709551615.0L;
    put_ld("big", big + 1);
    put("cmp", (big > r) + (r >= r) * 2 + (h != h) * 4 + (r < 1.5L) * 8);
    put("to_u64", (u64)(big / 3));
    put("to_long", (u64)(long)(-r * 1e15L));
    double d = (double)r;
    float f = (float)h;
    union { double d; u64 u; } x = { d };
    union { float f; unsigned u; } y = { f };
    put("double", x.u);
    put("float", y.u);
    long double p = 1;
    for (int i = 0; i < 70; i++) p *= 1.1L;
    put_ld("pow", p);
    return 0;
}

__attribute__((naked, used)) void _start(void) {
    __asm__("mov $stack + 65536, %rsp\n"
            "call main\n"
            "mov %eax, %edi\n"
            "mov $60, %eax\n"
            "syscall\n");
}
