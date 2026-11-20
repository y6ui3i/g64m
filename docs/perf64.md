# Where the 64-bit machine's time goes

A survey (E104 in [experiments.md](experiments.md)), taken before any work on the 64-bit
CPU's speed, so that the work is not a guess. Nothing here is a change; the list at the end
is what the numbers say to try, and in what order.

Two stretches were measured, on the build of 2026-11-19 (`build/x64` at E103):

- **the boot**: Alpine's x86_64 kernel from its entry to the shell's prompt, 1,524 million
  guest instructions, 99.8% of them at privilege level 0 (the kernel unpacking itself and
  starting up);
- **user programs**: after the boot, `dd | sha256sum` of 4 MB, `seq | sort -rn` of 60,000
  lines, and a loop of 200,000 turns in awk: 3,508 million instructions, 92.7% of them at
  level 3.

## The host's cost of one guest instruction

| | Boot | User programs |
|---|---:|---:|
| Guest instructions a second | 30.2 million | 30.6 million |
| Host instructions for each | 654 | 633 |
| Host cycles for each | 103 | 103 |

For comparison, the 32-bit machine's interpreter (decode cache, short executors, no JIT)
takes 17.5 host cycles for a guest instruction on its Linux boot (E090: 26.2 billion cycles
for 1,496 million instructions), and with the JIT it runs X at 341 million guest
instructions a second. **The 64-bit CPU is six times slower than the 32-bit interpreter,
instruction for instruction.** It is where the 32-bit machine was before E010.

## Where the 654 go

By stepping the host one instruction at a time through eight consecutive guest instructions
(a loop of `mov`, `add`, `call`, `ret`, `dec`, `jnz`), and by sampling the host's stack for
eight seconds on each stretch:

| Part | Host instructions for each guest instruction | Share of the host's time (boot / user) |
|---|---:|---|
| The run loop in `main` (the checks between two instructions: time, the timer, a script, the network, the single step) | 85, every time | 12% / 11% |
| `exec64` itself (saving sixteen registers, the prefix loop, setting the decode's globals, finding the arm for the opcode) | 165 to 208 | 39% / 39% |
| Fetching the instruction's bytes: `sys_rd` and `mem_rd`, one call for each byte or constant | 49 + 14 for each call; 3.2 calls an instruction in the boot, 2.9 in user programs: about 190 | 28% / 30% |
| ModRM (`modrm`, `rm_get`, `rm_set`, `gr`, `sr`) | 43 + 31 + 18 + 22 + 19 where used | 11% / 10% |
| The instruction's own work (`alu` 62, `cond` 18, `push`, `pop`, a data read or write) | 20 to 150 | 8% / 8% |

**So about nine tenths of the time goes before the instruction's own work begins, or on
finding its operands.** The card's guess was "more than half".

## What the guest runs

| | Boot | User programs |
|---|---:|---:|
| Mean length of an instruction | 3.46 bytes | 3.33 bytes |
| With a REX prefix | 55% | 42% |
| With a 66h prefix | 1.7% | 0.9% |
| With a memory operand | 27% | 24% |
| … of those, with a SIB byte | 42% | 45% |
| Data reads for each instruction | 0.19 | 0.22 |
| Data writes for each instruction | 0.09 | 0.17 |
| Instructions between two taken jumps: mean, median | 8.6, 6 | 8.1, 5 |
| A repetition of a REP string instruction | 1.7% | 3.9% |
| SSE | 0.00% | 0.99% |
| x87 | 0.00% | 0.49% |

A 64-bit program touches memory about once in three instructions (the 32-bit X stretch
passed its arguments on the stack). The commonest first bytes: in the boot `0F` 16% (of
which MOVZX 10%: the unpacking), `89` 10%, `83` 10%, `31` 6%, `8B` 5%, the two short Jcc 7%;
in user programs `89` 14%, `83` 10%, `0F` 10%, `8B` 7%, `8D` 4%, `AA` (REP STOSB) 4%, PUSH
and POP 8%, CALL and RET 3%.

## How concentrated it is

| | Boot | User programs |
|---|---:|---:|
| Distinct instruction addresses executed | 352,137 | 135,532 |
| Addresses that make up 50% of the instructions | 158 | 315 |
| … 90% | 5,289 | 2,173 |
| … 99% | 34,872 | 7,668 |
| … 99.9% | 92,677 | 24,727 |
| Addresses executed fewer than 8 times: their share of the instructions | 0.02% | 0.01% |
| Code pages that make up 99% | 284 of 2,079 | 103 of 981 |

**Very.** Remembering what was decoded would be right for all but a hundredth of a percent,
and a table for 100,000 instructions holds 99.9% of either stretch.

## What is rare

| | Boot | User programs |
|---|---:|---:|
| TLB lookups that miss: instruction bytes | 0.007% | 0.005% |
| … data reads | 0.17% | 0.12% |
| … data writes | 0.15% | 0.06% |
| Writes of CR3 (each empties the TLB) | 23,428 | 104,093 |
| INVLPG | 70,442 | 1,174 |
| Interrupts from outside | 8,785 | 46,416 |
| System calls | 548 | 2,815 |
| Page faults | 449 | 2,052 |
| Accesses that lie across two pages | 34,199 | 67,452 |

The TLB of E096 does its work: emptying it (0.7% of the time, `memset`) and walking are not
where the time is. One event in 30,000 instructions is an interrupt or a switch of address
space: nothing that happens between instructions needs to be fast, only the check for it.

## What to try, in this order

The numbers give each a ceiling. None has been tried.

| # | What | Why the survey says so | At most |
|---|---|---|---|
| 1 | **Fetch an instruction's bytes once**: one translation for the instruction's first page and the bytes read from memory directly (the 32-bit machine's "code page"), instead of a call through the page tables for each byte | 190 of 654 host instructions, 28 to 30% of the time, and 99.99% of fetches hit the TLB | about a quarter of the time |
| 2 | **The run loop**: one test between two instructions for "something is due" (a count to the next event), the rest out of the loop | 85 of 654, every instruction, for events that come once in 30,000 | about a tenth |
| 3 | **`exec64`'s beginning**: the decode's state in locals, not globals; the save of the registers only where an instruction can fault after it has changed one (or a log of what it changed); a table for the opcode's arm | 165 to 208 of 654 | perhaps a fifth |
| 4 | **A decode cache**, by physical address as on the 32-bit machine: the prefix loop, ModRM and the constants done once for an address | 99.98% of instructions are at addresses run 8 times or more; with 1 to 3 it is what took the 32-bit interpreter to 17.5 cycles | with 1 to 3: toward 6 times as fast |
| 5 | **A JIT** for the 64-bit CPU, on the 32-bit machine's design | runs of 8 instructions between jumps, 1 memory access in 3 instructions; the list above is what its design is checked against | the 32-bit machine's went 10 times beyond its interpreter |

**Done so far.**

| # | Entry | Host instructions for a guest instruction | Boot to the prompt |
|---|---|---:|---:|
| | the survey (E104) | 654 | 50.4 s |
| 1 | E105: the code page | 471 | 35.8 s |
| 2 | E106: one test between two instructions | 416 | 31.8 s |
| 4 | E107: a decode cache (prefixes and ModRM) | 399 | 31.4 to 31.9 s |
| | E108: memory a word at a time | 378 | 29.4 to 30.3 s |
| 3 | E109: the decoded instruction in one place | 333 | 27.5 to 27.8 s |
| 3 | E110: a short front for the commonest instructions | 289 | 24.4 to 24.7 s |
| | E113: a string instruction's repetitions in one go | 284 | 24.5 to 24.7 s |
| | E118: the kinds that cut the runs (the JIT's first task) | 276 | not timed yet |

The decode cache finds 97% of instructions and saves 48 host instructions each, but its
upkeep (the watch in every store, the index kept for `modrm`) costs 31, and a found entry
is unpacked into globals that are far apart: E107 has the listing. What that listing puts
first is not a structure: memory read and written a word at a time (eight bytes read are
72 host instructions), the instruction's state near at hand, and the start of the
instruction saved only when a fault is possible.

E109 did the second of those: the cache's entry is the instruction as it is used (a struct
of 24 bytes, with the tag in front), and finding an instruction again is one copy with
nothing unpacked. `exec64` itself went from 200 to 166 host instructions and `modrm` from
48 a call to 34. What every instruction still pays in `exec64` is the save of the start
(18), the twelve registers (16) and the checks before the lookup.

E110 runs a dozen kinds of instruction (most of what the boot runs) at the top of `exec64`,
by a jump on a kind kept in the cache's entry, without the save of the registers: none of
them changes a register before the last point it can fault at. There is one
implementation of each: the rest of the CPU has no arms for them.

**The plan from here is [primitives64.md](primitives64.md)** (E112): one small C program for
each thing a program is made of, measured one by one.

**Where the cycles go (E111).** The boot takes 289 host instructions and 50.3 cycles for a
guest instruction, 5.7 instructions a cycle. Stopped 6,000 times and its program counter
read, the time lies where the instructions are (`exec64` 48%, `main` 11%, `modrm` 9%),
with one exception: loading the decode cache's entry and testing its tag and kind takes
19% of the boot's time for a handful of instructions. A loop of five instructions that
never leaves the nearest cache takes 45.5 cycles for each: nine tenths of the cycles are
there when nothing waits, and fewer host instructions is still what makes the machine
faster. The jump on the instruction's kind is under a tenth.

1 to 3 change no structure and can each be measured alone; 4 is a structure; 5 is a
project. What the survey does not say is how much of 3 and 4 overlap: a decode cache makes
most of `exec64`'s beginning unnecessary, so 3 may be worth doing only in part before 4.

The tests that hold each step to the real CPU are there already: 20 programs compared
instruction by instruction (`tools/difftest64.sh`) and 9 system tests with a kernel booted
four ways (`tools/systest64.sh`).
