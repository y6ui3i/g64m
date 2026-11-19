// A 64-bit test in C (E091): what a compiler makes of ordinary integer code, with no
// library and no SSE. Built on an x86_64 Linux host with
//   gcc -O2 -static -nostdlib -ffreestanding -fno-pic -no-pie -mgeneral-regs-only \
//       -fno-stack-protector -fcf-protection=none -Wl,--build-id=none -o c_mix.elf c_mix.c -lgcc
// (libgcc is there for the 128-bit remainder) and kept as c_mix.elf beside this file, since
// the tests are otherwise built where there is no such compiler. It prints a few numbers;
// what is compared is the trace of every instruction.
//
// The stack is the program's own, so that RSP is the same wherever it runs.
typedef unsigned long u64;
typedef unsigned int u32;
typedef unsigned char u8;

u8 stack[65536];
static char line[64];
static u32 table[16];
static u64 nums[16];

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

static u64 seed = 0x9E3779B97F4A7C15;
static u64 next(void) {
    seed ^= seed << 13;
    seed ^= seed >> 7;
    seed ^= seed << 17;
    return seed;
}

static u32 crc(const u8 *p, int n) {
    u32 c = 0xFFFFFFFF;
    while (n--) {
        c ^= *p++;
        c = table[c & 15] ^ c >> 4;
        c = table[c & 15] ^ c >> 4;
    }
    return ~c;
}

static void sort(u64 *a, int n) {
    for (int i = 1; i < n; i++) {
        u64 v = a[i];
        int j = i;
        while (j > 0 && (long)a[j - 1] > (long)v) { a[j] = a[j - 1]; j--; }
        a[j] = v;
    }
}

static u64 gcd(u64 a, u64 b) {
    while (b) { u64 t = a % b; a = b; b = t; }
    return a;
}

static int bits(u64 v) {
    int n = 0;
    while (v) { v &= v - 1; n++; }
    return n;
}

__attribute__((noinline)) static u64 mulhi(u64 a, u64 b) {
    return (unsigned __int128)a * b >> 64;
}

__attribute__((noinline)) static long smod(__int128 a, long b) {
    return (long)(a % b);
}

int main(void) {
    for (u32 i = 0; i < 16; i++) {
        u32 c = i;
        for (int k = 0; k < 4; k++) c = c & 1 ? 0xEDB88320 ^ c >> 1 : c >> 1;
        table[i] = c;
    }
    for (int i = 0; i < 16; i++) nums[i] = next() >> (i & 31);
    put("crc", crc((const u8 *)nums, sizeof nums));
    sort(nums, 16);
    put("min", nums[0]);
    put("max", nums[15]);
    u64 g = 0, pop = 0, hi = 0;
    long sm = 0;
    for (int i = 0; i < 15; i++) {
        g += gcd(nums[i] | 1, nums[i + 1] | 1);
        pop += bits(nums[i]);
        hi ^= mulhi(nums[i], nums[i + 1]);
        sm += smod((__int128)(long)nums[i] * (long)nums[15 - i], (long)(nums[i + 1] | 3));
        sm += (long)nums[i] / (long)(i + 3) - (int)nums[i] % (i + 7);
    }
    put("gcd", g);
    put("pop", pop);
    put("mulhi", hi);
    put("smod", (u64)sm);
    return 0;
}

__attribute__((naked, used)) void _start(void) {
    __asm__("mov $stack + 65536, %rsp\n"
            "call main\n"
            "mov %eax, %edi\n"
            "mov $60, %eax\n"
            "syscall\n");
}
