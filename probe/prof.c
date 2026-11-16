// A sampling profile by address, for finding where the host waits (E032, redone in E040). Not
// part of g86m.
//
// Use: copy src/ somewhere, append this file to the copy's console.c, build that copy, and run
// it with G86M_PROF naming an output file:
//
//   mkdir -p build/psrc && cp src/* build/psrc/ && cat probe/prof.c >> build/psrc/console.c
//   goose build -o build/g86m-prof build/psrc/g86m.goose
//   G86M_PROF=build/prof.txt build/g86m-prof ...
//   otool -tV build/g86m-prof > build/disp.txt     # the addresses in prof.txt are these
//
// A second thread wakes about every 150 microseconds, suspends the main thread, reads its
// program counter and lets it go. The output is one line per address that was hit: the address
// as the disassembly shows it, and the number of hits. A stopped CPU reports the oldest
// instruction it has not yet completed, so hits pile up on the instruction that was being
// waited for: a load whose address came late or that missed the cache, or the first
// instruction after a mispredicted jump.
//
// The first version of this file took its samples from a timer signal (ITIMER_PROF). That
// sampler is biased and must not be used: it delivered a fifth of the samples that were due,
// and put them by preference on stores into guest RAM. It showed the decompressor's MOVSW at
// 230 cycles a copy; a clock read before and after the executor gives 9 nanoseconds, the same
// as a PUSH (E040). What E032 to E036 read from it about single stores is withdrawn there.
//
// By kind of guest instruction. A profile by address cannot say which guest instruction the
// time belongs to wherever the compiler has merged code from several executors. For that, the
// copy can call prof_note() with a number just before it runs an instruction, and every sample
// is also counted under the number last noted (G86M_PROF's file name with ".k" added: number,
// hits). In the copy's exec.goose:
//
//   extern fn prof_note(k: i32);
//   ... in exec_short, before `a = run_short(kind, slot, base);`:   prof_note(kind);
//   ... at the top of exec_general:                                  prof_note(1024);
//   ... in exec_general, once `op` is known:                         prof_note(256 + op);
//
// The call costs about one cycle an instruction and shows as about 6% of the samples in
// prof_note itself; the shares of the kinds among themselves are what to read.

#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <pthread.h>
#include <stdio.h>
static uint32_t prof_hist[1 << 20];
static uint32_t prof_kinds[2048];
static volatile uint32_t prof_cur;
static uintptr_t prof_slide;
static thread_act_t prof_main;
static volatile int prof_stop;
static pthread_t prof_thread;
void prof_note(int32_t k) { prof_cur = (uint32_t)k; }
static void *prof_loop(void *arg) {
    (void)arg;
    while (!prof_stop) {
        usleep(150);
        if (thread_suspend(prof_main) != KERN_SUCCESS) continue;
        arm_thread_state64_t st;
        mach_msg_type_number_t n = ARM_THREAD_STATE64_COUNT;
        if (thread_get_state(prof_main, ARM_THREAD_STATE64, (thread_state_t)&st, &n) == KERN_SUCCESS) {
            uintptr_t pc = (uintptr_t)arm_thread_state64_get_pc(st) - prof_slide - 0x100000000ull;
            // Number 2047 collects the samples outside the program's own text (the C library).
            if ((pc >> 2) < (1 << 20)) { prof_hist[pc >> 2]++; prof_kinds[prof_cur & 2047]++; }
            else prof_kinds[2047]++;
        }
        thread_resume(prof_main);
    }
    return 0;
}
static void prof_dump(void) {
    prof_stop = 1;
    pthread_join(prof_thread, 0);
    const char *path = getenv("G86M_PROF");
    FILE *f = fopen(path, "w");
    if (!f) return;
    for (uint32_t i = 0; i < (1 << 20); i++)
        if (prof_hist[i]) fprintf(f, "%llx %u\n", 0x100000000ull + ((unsigned long long)i << 2), prof_hist[i]);
    fclose(f);
    char kinds[1024];
    snprintf(kinds, sizeof kinds, "%s.k", path);
    f = fopen(kinds, "w");
    if (!f) return;
    for (int i = 0; i < 2048; i++)
        if (prof_kinds[i]) fprintf(f, "%d %u\n", i, prof_kinds[i]);
    fclose(f);
}
__attribute__((constructor)) static void prof_start(void) {
    if (!getenv("G86M_PROF")) return;
    prof_slide = _dyld_get_image_vmaddr_slide(0);
    prof_main = mach_thread_self();
    pthread_create(&prof_thread, 0, prof_loop, 0);
    atexit(prof_dump);
}
