// A 64-bit test in C with floating point (E093): what a compiler makes of doubles, singles
// and the copying of structures, which on x86_64 all go through XMM registers. Built on an
// x86_64 Linux host with
//   gcc -O2 -static -nostdlib -ffreestanding -fno-pic -no-pie -fno-stack-protector \
//       -fcf-protection=none -Wl,--build-id=none -o cx_float.elf cx_float.c
// and kept as cx_float.elf beside this file. It prints a few numbers; what is compared is
// the trace of every instruction, XMM registers included.
typedef unsigned long u64;
typedef unsigned int u32;
typedef unsigned char u8;

u8 stack[65536];
static char line[64];

static long sys(long n, long a, long b, long c) {
    long r;
    __asm__ volatile("syscall" : "=a"(r) : "a"(n), "D"(a), "S"(b), "d"(c) : "rcx", "r11", "memory");
    return r;
}

static void put(const char *name, u64 v) {
    int n = 0;
    while (*name) line[n++] = *name++;
    line[n++] = ' ';
    for (int i = 60; i >= 0; i -= 4) line[n++] = "0123456789abcdef"[v >> i & 15];
    line[n++] = '\n';
    sys(1, 1, (long)line, n);
}

static u64 bits(double d) { union { double d; u64 u; } x = { d }; return x.u; }
static u32 bitsf(float f) { union { float f; u32 u; } x = { f }; return x.u; }

__attribute__((noinline)) static double root(double x) {
    double g = x > 1 ? x / 2 : 1;
    for (int i = 0; i < 12; i++) g = (g + x / g) / 2;
    return g;
}

__attribute__((noinline)) static double poly(const double *c, int n, double x) {
    double r = 0;
    for (int i = n - 1; i >= 0; i--) r = r * x + c[i];
    return r;
}

__attribute__((noinline)) static float dot(const float *a, const float *b, int n) {
    float s = 0;
    for (int i = 0; i < n; i++) s += a[i] * b[i];
    return s;
}

struct body { double pos[3], vel[3]; float mass; int id; };

__attribute__((noinline)) static struct body step(struct body b, double dt) {
    for (int i = 0; i < 3; i++) {
        b.vel[i] -= b.pos[i] * dt * b.mass;
        b.pos[i] += b.vel[i] * dt;
    }
    b.id++;
    return b;
}

static const double coef[6] = { 1.0, -0.5, 0.041666666666666664, -0.001388888888888889, 2.48015873015873e-05, -2.7557319223985888e-07 };
static float fa[19], fb[19];
static u8 from[100], to[100];

int main(void) {
    double s = 0;
    for (int i = 1; i <= 9; i++) s += root(i * 1.25);
    put("root", bits(s));
    put("poly", bits(poly(coef, 6, 0.7 * 0.7)));
    for (int i = 0; i < 19; i++) { fa[i] = i * 0.37f - 2; fb[i] = 1.0f / (i + 1); }
    put("dot", bitsf(dot(fa, fb, 19)));
    struct body b = { { 1, 0.5, -0.25 }, { 0, 0.125, 0.75 }, 1.5f, 7 };
    for (int i = 0; i < 20; i++) b = step(b, 0.01);
    put("pos", bits(b.pos[0] + b.pos[1] + b.pos[2]));
    put("id", b.id);
    long acc = 0;
    for (int i = -6; i <= 6; i++) {
        double d = i * 0.75;
        acc = acc * 31 + (long)d + (int)(d * 1e3) + (u32)(d * d) + (long)(float)(d * 1e6);
        acc += (d < 0.5) + (d >= -1.5) * 2 + (d != d) * 4;
    }
    put("conv", (u64)acc);
    u64 big = 0xFFFFFFFFFFFFFC00;
    put("u2d", bits((double)big) ^ bits((double)(big >> 1)) ^ bitsf((float)big));
    for (int i = 0; i < 100; i++) from[i] = i * 7 + 3;
    __builtin_memcpy(to, from, 100);
    __builtin_memset(to + 13, 0x5A, 41);
    u64 sum = 0;
    for (int i = 0; i < 100; i++) sum = sum * 3 + to[i];
    put("copy", sum);
    return 0;
}

// What the compiler calls for copying and filling when it does not do them in place.
void *memcpy(void *d, const void *s, u64 n) {
    u8 *a = d;
    const u8 *b = s;
    while (n--) *a++ = *b++;
    return d;
}

void *memset(void *d, int c, u64 n) {
    u8 *a = d;
    while (n--) *a++ = c;
    return d;
}

__attribute__((naked, used)) void _start(void) {
    __asm__("mov $stack + 65536, %rsp\n"
            "call main\n"
            "mov %eax, %edi\n"
            "mov $60, %eax\n"
            "syscall\n");
}
