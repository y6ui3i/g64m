# Making X quick: the plan

The owner's order (2026-11-19): make X on the 32-bit machine quick first, with what will
carry over to x86_64, then go to x86_64 (M10 of [roadmap.md](roadmap.md)). This is the list
for the first half. It is made from a count (E085 in [experiments.md](experiments.md)), and
it is counted again after each group of items, so the order below is the order today.

## Where X's time goes

- Half of the host's time is trips between generated code and Goose, as it was for the
  boot before E067: generated code is entered once for 34 guest instructions under X, once
  for 103 in the boot.
- The host gets through 250 million guest instructions a second in X (500 in the boot).
  The guest's CPU is 76 million a second at the default speed and 305 at `--speed 4`: the
  aim is for the host to keep up with `--speed 4` while X runs.
- It is not MMX and SSE (1% of the time), not the disk, not the frame buffer.

## What carries over to x86_64

| Kind of work | Carries over |
|---|---|
| The decode cache holding more of the instructions (longer ones, prefixes) | whole, if the decode cache is shared |
| The far way's lookup, return prediction, the linking of blocks | the design and the emitter; the code where addresses are 32 bits is written again |
| A translation of one more instruction | the design and its tests; the code is written again for sixteen registers and 64-bit operands |
| The interpreter's short executors, segment limits | not at all: long mode has no segments to speak of |
| Counting builds, wrong builds, traces against rustx86 and real hardware | whole |

So nothing more goes into the interpreter's short executors, and each item below says what
of it is kept.

## Cut short (2026-11-19)

After E088 the owner asked whether a wider search for speed here would help x86_64, and
the answer was: only the work on the structure does. A translation of one more instruction
is written again for sixteen registers and 64-bit operands, and what is hot in 32-bit X is
not what will be hot in 64-bit X (which passes arguments in registers and does its
floating point and its copying with SSE2). So of the list below only P8 (the count, of
trips this time) and P7 (the far way's prediction) are done, in that order, and then
x86_64, whether or not the host keeps up with `--speed 4` by then. P2b, P2c, P4, P5 and P6
are left; the same items are looked for again in the count of 64-bit X.

## The list

Counts are of the stretch from `startx` to the desktop, in millions of instructions that
reach the general path. (Until E088 this column said "trips". It never was: several such
instructions in a row share one trip. P2a took 14 million instructions off the general path
and 1 million entries.)

| # | Item | On the general path | Kept for x86_64 | State |
|---|---|---:|---|---|
| P1 | Indirect CALL and JMP (FF /2, /4) end their block at the far way, as RET does | 12.5, and what follows each | the design | done, E087 |
| P2 | Why instructions that have executors are on the general path | | | counted, E086 |
| P2a | An instruction that begins in a page's last fifteen bytes gets an entry in the decode cache when it ends in the page | 17.6 | whole (the decode cache, and a function that tells an instruction's length) | done, E088 |
| P2b | 16-bit operands (prefix 66) of `cmp`, `test`, `add` and the immediate groups: only MOV has 16-bit kinds | 16.2 | the design | left for the 64-bit count |
| P2c | First executions: the decode cache (131,072 slots) loses entries under X's amount of code | 6.8 | whole | left for the 64-bit count |
| P3 | CMOVcc | 6.4 | the design | done, E087 |
| P4 | IMUL by a constant, BT and its group, XCHG of a byte with memory, SHLD and SHRD, CMPXCHG, INC and DEC of a byte | 16.5 | the design | left for the 64-bit count |
| P5 | PUSHF and CLI in blocks (the kernel's "save the interrupt flag and turn it off") | 3.0 | the design | left for the 64-bit count |
| P6 | The strings with REP inside generated code | 4.9 | the design | left for the 64-bit count |
| P7 | The far way predicts: a RET goes back where its CALL was, which the block that called can leave word of | 119 arrivals, 30 host instructions each | the design and the stub | not started: under 3% to be had (E089, E090), and the aim is met |
| P8 | Count again, and count trips this time: what ended each block that was left | | whole (the method) | done, E089 |
| P9 | The TLB: 256 entries for each privilege level are too few for X; 27% of the trips are a page it does not have | 19.3 trips | whole | done, E090: 4,096 entries for each level |

## How far

| After | Entries, `startx` to the desktop | Host | Guest instructions a second |
|---|---:|---:|---:|
| E085 (the count) | 90.0 million | 12.26 s | 250 million |
| E087 (P1, P3) | 73.1 million | 11.20 s | 280 million |
| E088 (P2a) | 72.1 million | 6.5% less than E087 in one sitting (10.96 s against 11.72) | 299 million, on E087's 280 |
| E090 (P9, the TLB) | 54.3 million | 12.3% less than E088 in one sitting (9.23 s against 10.52) | 341 million, on E088's 299 |

`--speed 4` wants 305 million, and after E090 the host has it by this measure. What the
measure is: the host's time for a fixed stretch of the guest's work, with the guest's clock
not held to the host's. It does not say that every moment of a session keeps up; that is
for the owner's eyes.

After P8, or when the host keeps up with `--speed 4` under X, whichever is first: x86_64.
