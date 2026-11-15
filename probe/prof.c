// A sampling profile by address, for finding where the host waits (E032). Not part of g86m.
//
// Use: copy src/ somewhere, append this file to the copy's console.c, build that copy, and run
// it with G86M_PROF naming an output file:
//
//   mkdir -p build/psrc && cp src/* build/psrc/ && cat probe/prof.c >> build/psrc/console.c
//   goose build -o build/g86m-prof build/psrc/g86m.goose
//   G86M_PROF=build/prof.txt build/g86m-prof ...
//   otool -tV build/g86m-prof > build/disp.txt     # the addresses in prof.txt are these
//
// A timer signal (ITIMER_PROF, every 200 microseconds of CPU time) notes the program counter.
// The output is one line per address that was hit: the address as the disassembly shows it,
// and the number of hits. An interrupted CPU reports the oldest instruction it has not yet
// completed, so hits pile up on the instruction that was being waited for: a load whose
// address came late or that missed the cache, or the first instruction after a mispredicted
// jump. That is what makes it more use here than a count of instructions.

#include <mach-o/dyld.h>
#include <stdio.h>
#include <sys/time.h>
#include <sys/ucontext.h>
static uint32_t prof_hist[1 << 20];
static uintptr_t prof_slide;
static void prof_tick(int sig, siginfo_t *si, void *ctx) {
    (void)sig; (void)si;
    ucontext_t *uc = ctx;
    uintptr_t pc = (uintptr_t)__darwin_arm_thread_state64_get_pc(uc->uc_mcontext->__ss) - prof_slide - 0x100000000ull;
    if ((pc >> 2) < (1 << 20)) prof_hist[pc >> 2]++;
}
static void prof_dump(void) {
    const char *path = getenv("G86M_PROF");
    FILE *f = fopen(path, "w");
    if (!f) return;
    for (uint32_t i = 0; i < (1 << 20); i++)
        if (prof_hist[i]) fprintf(f, "%llx %u\n", 0x100000000ull + ((unsigned long long)i << 2), prof_hist[i]);
    fclose(f);
}
__attribute__((constructor)) static void prof_start(void) {
    if (!getenv("G86M_PROF")) return;
    prof_slide = _dyld_get_image_vmaddr_slide(0);
    struct sigaction sa = {0};
    sa.sa_sigaction = prof_tick;
    sa.sa_flags = SA_SIGINFO | SA_RESTART;
    sigaction(SIGPROF, &sa, 0);
    struct itimerval it = {{0, 200}, {0, 200}};
    setitimer(ITIMER_PROF, &it, 0);
    atexit(prof_dump);
}
