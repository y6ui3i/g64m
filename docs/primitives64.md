# The primitives of the 64-bit CPU's speed

The plan for making the 64-bit CPU faster one primitive at a time (E112 in
[experiments.md](experiments.md); the survey before it is [perf64.md](perf64.md)).

A benchmark measures a mixture. A primitive is one of the things every program is made of:
a loop, an `if`, a pointer, a call through a pointer, a `double` added to another. There is
one small C program for each in `tests/prim64/`, built with GCC as real programs are, and
what is made faster for a primitive is faster in every program that has it.

- `tools/prim64.sh` runs each and compares what it prints with what it printed on the
  real CPU (with `ORACLE_HOST=name`, builds them again there and takes the expected text).
- `tools/prim64_table.py` prints the table below.

## The table (first taken in E112; as of E118, 2026-11-20)

Host instructions for a guest instruction, in user mode. The integer primitives are built
without SSE (`-O2 -mgeneral-regs-only`), the rest with the compiler's defaults, `p_simd`
with `-O3`.

| Primitive | Guest instructions | Host instructions for each | Cycles for each | Run by the front | What the front does not run (share of the program's instructions) |
|---|---:|---:|---:|---:|---|
| `p_fill` | 7.8 million | 83 | 21.6 | 10% | MOVSB 1%, STOSB 1% |
| `p_switch` | 25.8 million | 288 | 53.1 | 100% |  |
| `p_ternary` | 39.4 million | 290 | 48.6 | 100% |  |
| `p_rotate` | 89.5 million | 292 | 48.2 | 99% | BSF 1%, BSR 1% |
| `p_if` | 23.0 million | 294 | 49.8 | 100% |  |
| `p_funcptr` | 20.9 million | 297 | 50.1 | 100% |  |
| `p_muldiv` | 30.8 million | 297 | 48.7 | 100% |  |
| `p_bytes` | 34.6 million | 302 | 48.5 | 100% |  |
| `p_shift` | 73.8 million | 303 | 52.2 | 100% |  |
| `p_recursion` | 12.2 million | 303 | 51.7 | 100% |  |
| `p_pixel` | 26.5 million | 312 | 55.9 | 100% |  |
| `p_pointer` | 33.0 million | 313 | 49.7 | 100% |  |
| `p_sha` | 16.8 million | 313 | 60.0 | 100% |  |
| `p_bitfield` | 67.6 million | 315 | 54.8 | 100% |  |
| `p_loop` | 15.0 million | 319 | 52.6 | 100% |  |
| `p_dbl_cmp` | 37.5 million | 320 | 56.5 | 47% | SSE MOVAPS 22%, SSE COMISS/SD 11%, SSE MOVUPS/SS/SD 5%, SSE MIN 5%, SSE MAX 5% |
| `p_bignum` | 44.7 million | 322 | 56.0 | 100% |  |
| `p_index` | 29.9 million | 337 | 54.0 | 100% |  |
| `p_dbl_conv` | 33.8 million | 371 | 61.2 | 41% | SSE CVTTSS/SD2SI 14%, SSE CVTSI2SS/SD 9%, SSE MUL 9%, SSE CVT ss/sd 9%, SSE PXOR 9% |
| `p_float` | 23.1 million | 378 | 60.6 | 27% | SSE MOVUPS/SS/SD 20%, SSE ADD 20%, SSE MOVAPS 7%, SSE MUL 7%, SSE COMISS/SD 7% |
| `p_dbl_arith` | 21.6 million | 384 | 62.6 | 22% | SSE MOVUPS/SS/SD 21%, SSE ADD 21%, SSE MUL 14%, SSE MOVAPS 7%, SSE SUB 7% |
| `p_simd` | 16.6 million | 471 | 95.9 | 12% | SSE MOVDQA/U 18%, SSE/MMX 0F F4 14%, SSE/MMX 0F 70 12%, SSE/MMX 0F 72 9%, SSE/MMX 0F 73 9% |
| `p_ldbl` | 13.9 million | 475 | 94.8 | 22% | x87 78% |

The numbers are user mode's, whose run loop costs 30 host instructions more for each guest
instruction than the machine's: they compare the primitives with each other, not with the
boot (289).

## What the table says

- The integer primitives are alike, 291 to 339, whether the short front runs all of their
  instructions or two thirds. An instruction that goes to the rest of the CPU costs about
  60 host instructions more.
- Four groups are expensive: a string instruction with a repeat count (369 for every
  byte), division, the XMM registers (373 to 471), the x87 (477).
- What all of them pay, about 290, is the same for every instruction: the lookup, the
  run loop, `modrm` and the helpers (E111).

## The order of work

**Changed on 2026-11-20 (E116): the JIT comes first** ([jit64.md](jit64.md)). The first two
lines below are done; the rest wait behind the JIT, and some of them become its tasks
(the third line is its first task, for another reason: an instruction the front does not
know cuts a block short). The primitives stay what each step is measured on.


Each line is an entry of its own in the ledger, with a card before it and its primitives
and the boot measured after it. The order is (what the group costs) × (how often it is
met: E104 has the opcodes of the boot and of three user programs).

| # | Group | Primitives | Why here |
|---|---|---|---|
| 1 (done, E113: 369 → 84) | String instructions with a repeat count: all the repetitions in one go | `p_fill` | 369 for each byte, where a loop in the CPU is a few; 1.7% of the boot's instructions and 3.9% of user programs' are repetitions, and every library copies and fills this way |
| 2 (done, E114: 369 → 311) | Division | `p_muldiv` | done bit by bit; 14% of the program's instructions make it 369 |
| 3 (done as the JIT's first task, E118) | The front's missing integer kinds: shifts and rotations, CMOV and SETcc, MOV of a constant, MOVSXD, NOT and NEG, IMUL, the indirect CALL and JMP | `p_shift`, `p_bitfield`, `p_rotate`, `p_sha`, `p_pixel`, `p_ternary`, `p_bytes`, `p_funcptr`, `p_switch`, `p_bignum` | 60 host instructions for each such instruction: the widest group, the smallest gain for each |
| 4 | double and float: the scalar SSE instructions by a short way | `p_dbl_arith`, `p_dbl_cmp`, `p_dbl_conv`, `p_float` | 373 to 385; 1% of user programs' instructions, most of a program that computes |
| 5 | Packed SSE | `p_simd` | 471 and 98 cycles; what a drawing library runs |
| 6 | The x87 | `p_ldbl` | 477; 0.5% of user programs' instructions |
| 7 | What all share | all, and the boot | E111's list: the decode cache's entry near, `main`'s loop, `modrm`; and user mode's run loop, which is twice the machine's |

Still to add when a table shows the need: the primitives run inside the machine, with
paging; any instruction GCC makes that no program here has.
