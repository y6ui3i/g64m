// What every primitive program shares (E112): no library, a stack of its own, numbers
// printed in hexadecimal, and numbers to work on that are the same wherever it runs.
typedef unsigned long u64;
typedef unsigned int u32;
typedef unsigned short u16;
typedef unsigned char u8;
typedef long i64;
typedef int i32;
#define NOINLINE __attribute__((noinline))

u8 stack[1 << 20];
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

static u64 seed = 0x9E3779B97F4A7C15;
static u64 next(void) {
    seed ^= seed << 13;
    seed ^= seed >> 7;
    seed ^= seed << 17;
    return seed;
}

int main(void);
__attribute__((naked, used)) void _start(void) {
    __asm__("mov $stack + (1 << 20), %rsp\n"
            "call main\n"
            "mov %eax, %edi\n"
            "mov $60, %eax\n"
            "syscall\n");
}
