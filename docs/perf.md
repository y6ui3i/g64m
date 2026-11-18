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
| P2b | 16-bit operands (prefix 66) of `cmp`, `test`, `add` and the immediate groups: only MOV has 16-bit kinds | 16.2 | the design | |
| P2c | First executions: the decode cache (131,072 slots) loses entries under X's amount of code | 6.8 | whole | |
| P3 | CMOVcc | 6.4 | the design | done, E087 |
| P4 | IMUL by a constant, BT and its group, XCHG of a byte with memory, SHLD and SHRD, CMPXCHG, INC and DEC of a byte | 16.5 | the design | |
| P5 | PUSHF and CLI in blocks (the kernel's "save the interrupt flag and turn it off") | 3.0 | the design | |
| P6 | The strings with REP inside generated code | 4.9 | the design | |
| P7 | The far way predicts: a RET goes back where its CALL was, which the block that called can leave word of | 119 arrivals, 30 host instructions each | the design and the stub | |
| P8 | Count again, and count trips this time: what ended each block that was left. What an entry costs once the trips are fewer; whether MMX and SSE moves want a translation | | | |

## How far

| After | Entries, `startx` to the desktop | Host | Guest instructions a second |
|---|---:|---:|---:|
| E085 (the count) | 90.0 million | 12.26 s | 250 million |
| E087 (P1, P3) | 73.1 million | 11.20 s | 280 million |
| E088 (P2a) | 72.1 million | 6.5% less than E087 in one sitting (10.96 s against 11.72) | 299 million, on E087's 280 |

`--speed 4` wants 305 million.

After P8, or when the host keeps up with `--speed 4` under X, whichever is first: x86_64.
