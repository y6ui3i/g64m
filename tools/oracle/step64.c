// step64: the oracle for 64-bit user-mode instructions (E091).
//
//   cc -O2 -o step64 step64.c        (on an x86_64 Linux host)
//   ./step64 program > trace
//   ./step64 -x program > trace      also MXCSR and the XMM registers
//
// Runs a static x86_64 ELF one instruction at a time under ptrace, on the host's own CPU,
// and prints the registers and flags after each instruction, one line each, in the format
// of `g64m --trace`. The program gets no arguments and no environment, its standard output
// goes nowhere, and address randomizing is off for it.
//
// Two things are different in a program that is being single-stepped, and both are put
// back here so that the trace is that of the program run freely:
//   - PUSHF pushes the flags with TF set: the bit is cleared in the word on the stack;
//   - SYSCALL leaves the flags in R11 with TF set: the bit is cleared in R11;
//   - the kernel hides TF in the flags it reports, but not for the instruction after a
//     POPF (it takes the program to have set the bit itself): TF is never printed. So a
//     test cannot set TF, which would end it with a signal anyway.
// A REP string instruction is one line for each repetition, as the CPU stops after each.
//
// With -x a line also has MXCSR, without its six status bits (the emulator this is for does
// not keep them), and each XMM register that is not what it was on the line before, as
// X3=high:low. They start as the kernel starts them: MXCSR 1F80h and every register zero.
#define _GNU_SOURCE
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/personality.h>
#include <sys/ptrace.h>
#include <sys/user.h>
#include <sys/wait.h>
#include <unistd.h>

int main(int argc, char **argv) {
    int xmode = argc == 3 && !strcmp(argv[1], "-x");
    if (argc != 2 + xmode) { fprintf(stderr, "usage: step64 [-x] program\n"); return 2; }
    char *prog = argv[1 + xmode];
    struct user_fpregs_struct f, seen;
    memset(&seen, 0, sizeof seen);
    seen.mxcsr = 0x1F80;
    pid_t pid = fork();
    if (pid == 0) {
        personality(ADDR_NO_RANDOMIZE);
        int fd = open("/dev/null", O_WRONLY);
        dup2(fd, 1);
        ptrace(PTRACE_TRACEME, 0, 0, 0);
        char *args[] = { prog, 0 };
        char *env[] = { 0 };
        execve(prog, args, env);
        _exit(127);
    }
    int st;
    waitpid(pid, &st, 0);
    if (!WIFSTOPPED(st)) { fprintf(stderr, "step64: the program did not start\n"); return 2; }
    ptrace(PTRACE_SETOPTIONS, pid, 0, PTRACE_O_EXITKILL);
    struct user_regs_struct r;
    ptrace(PTRACE_GETREGS, pid, 0, &r);
    static char out[1 << 16];
    setvbuf(stdout, out, _IOFBF, sizeof out);
    for (;;) {
        // The first bytes of the instruction about to run, to know a PUSHF or a SYSCALL.
        unsigned long long code = ptrace(PTRACE_PEEKTEXT, pid, (void *)r.rip, 0);
        unsigned char b0 = code, b1 = code >> 8;
        if (b0 == 0x66 || (b0 & 0xF0) == 0x40) { b0 = b1; b1 = code >> 16; }
        ptrace(PTRACE_SINGLESTEP, pid, 0, 0);
        waitpid(pid, &st, 0);
        if (WIFEXITED(st) || WIFSIGNALED(st)) break;
        if (WSTOPSIG(st) != SIGTRAP) {
            fflush(stdout);
            fprintf(stderr, "step64: signal %d\n", WSTOPSIG(st));
            kill(pid, SIGKILL);
            break;
        }
        ptrace(PTRACE_GETREGS, pid, 0, &r);
        if (b0 == 0x9C) {
            unsigned long long w = ptrace(PTRACE_PEEKDATA, pid, (void *)r.rsp, 0);
            ptrace(PTRACE_POKEDATA, pid, (void *)r.rsp, (void *)(w & ~0x100ULL));
        } else if (b0 == 0x0F && b1 == 0x05) {
            r.r11 &= ~0x100ULL;
            ptrace(PTRACE_SETREGS, pid, 0, &r);
        }
        printf("RIP=%016llX RAX=%016llX RCX=%016llX RDX=%016llX RBX=%016llX RSP=%016llX RBP=%016llX "
               "RSI=%016llX RDI=%016llX R8=%016llX R9=%016llX R10=%016llX R11=%016llX R12=%016llX "
               "R13=%016llX R14=%016llX R15=%016llX F=%08llX",
               r.rip, r.rax, r.rcx, r.rdx, r.rbx, r.rsp, r.rbp, r.rsi, r.rdi, r.r8, r.r9, r.r10, r.r11,
               r.r12, r.r13, r.r14, r.r15, r.eflags & ~0x100ULL);
        if (xmode) {
            ptrace(PTRACE_GETFPREGS, pid, 0, &f);
            if ((f.mxcsr & 0xFFC0) != (seen.mxcsr & 0xFFC0)) printf(" MXCSR=%04X", f.mxcsr & 0xFFC0);
            seen.mxcsr = f.mxcsr;
            for (int i = 0; i < 16; i++) {
                unsigned int *x = f.xmm_space + i * 4;
                if (memcmp(x, seen.xmm_space + i * 4, 16)) {
                    memcpy(seen.xmm_space + i * 4, x, 16);
                    printf(" X%d=%08X%08X:%08X%08X", i, x[3], x[2], x[1], x[0]);
                }
            }
        }
        putchar('\n');
    }
    return 0;
}
