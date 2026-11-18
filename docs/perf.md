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

Counts are of the stretch from `startx` to the desktop, in millions of trips.

| # | Item | Trips now | Kept for x86_64 | State |
|---|---|---:|---|---|
| P1 | Indirect CALL and JMP (FF /2, /4) end their block at the far way, as RET does | 12.5, and what follows each | the design | |
| P2 | Why instructions that have executors are on the general path: `cmp`, `mov`, groups 83, 81, C7. Count the reasons (a prefix, more than eight bytes, the page's last bytes), then remove the largest | 23.0 | whole (the decode cache) | |
| P3 | CMOVcc | 6.4 | the design | |
| P4 | IMUL by a constant, BT and its group, XCHG of a byte with memory, SHLD and SHRD, CMPXCHG, INC and DEC of a byte | 16.5 | the design | |
| P5 | PUSHF and CLI in blocks (the kernel's "save the interrupt flag and turn it off") | 3.0 | the design | |
| P6 | The strings with REP inside generated code | 4.9 | the design | |
| P7 | The far way predicts: a RET goes back where its CALL was, which the block that called can leave word of | 119 arrivals, 30 host instructions each | the design and the stub | |
| P8 | Count again. What an entry costs once the trips are fewer; whether MMX and SSE moves want a translation | | | |

After P8, or when the host keeps up with `--speed 4` under X, whichever is first: x86_64.
