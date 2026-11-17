# The JIT

With `--jit`, g86m translates runs of 32-bit guest instructions into arm64 code and executes
that. It is an option, off by default, and arm64 only. This file says how it is built, how to
use it and find a fault in it, where it stands, and what is to be done next. The history, with
every measurement and every wrong turn, is in [experiments.md](experiments.md) from E058 on;
what follows is the state, kept up to date as the tasks at the end are done.

## Use

```
build/g86m --jit --initrd images/initramfs-mini images/vmlinuz-lts
```

At the end of a run the statistics line gains `jit N blocks, M instructions, K left early, B
bytes, F flushes`: blocks translated, guest instructions executed in blocks, times a block left
before its end, bytes of generated code now held, and times the code filled up and was
dropped. A test that means to run blocks and shows `0 blocks` or a
handful of instructions is not testing them (it has happened three times; see "Tests").

`--jit-off N` tells the translator to leave groups of instruction kinds to the interpreter; N
is a sum of the bits in `jit_plain` (jit.goose). It is for finding a wrong translation: see
"Finding a wrong translation". `--jit-size N` makes the room for code N bytes (70,000 at least,
32 MB by default), so that a test can see it fill up.

On a host that is not arm64, `--jit` says so and the run goes on without it.

## How it is built

| Piece | Where | What it is |
|---|---|---|
| Executable memory, the call | [src/jit.c](../src/jit.c) | `jit_alloc`, `jit_write`, `jit_call`, and the address of a Goose array. About fifty lines; everything else is Goose |
| The translator | [src/jit.goose](../src/jit.goose) | An emitter for the arm64 instructions used, the flags' record, one function for each family of guest instructions, `jit_translate`, `jit_blocks` |
| The hook in the interpreter | [src/exec.goose](../src/exec.goose) | `K_BLOCK`, `jit_at`, and three lines in `exec_short` and `exec_one` |
| The arrays | [src/big.goose](../src/big.goose) | Per entry of the decode cache: the block's code, own kind, length, last instruction, generation; per page: its generation |

**A block** is instructions that follow one another in one physical page, from where a run
of the interpreter begins, or where another block ended, to a jump (included) or to an
instruction the translator does not know (excluded). It is found through the decode cache:
the entry of its first instruction has the kind `K_BLOCK` and keeps its own kind beside it.
Nothing is decoded twice; the translator reads what `classify` left in the entries.

**Entering.** `exec_short` meets `K_BLOCK` where it meets a kind with no executor, stores the
entry's slot in `jit_at` and returns. `exec_one` calls `jit_blocks`, which runs that block and
the ones that follow it one after another, then lets `exec_short` go on. Nothing of the JIT is
inside `exec_short` beyond that store: code for it there cost every interpreted instruction 1
to 3% (E060). A block is run only if its page has not been written since it was made
(`code_gen`), the run has time for all of it, and its last instruction is within what the run
may execute; otherwise its first instruction is run by the general path, by its own kind.

**Registers in generated code.** x0 the guest's registers in memory; x19 RAM, x20 the TLB
arrays, x21 `seg_top`, w22 what a physical address in the page is above the instruction
pointer; w8 to w15 the eight guest registers, loaded when a block begins and stored back,
where changed, when it ends; w1 to w3 the flags' record; w4 the half of the TLB for the
current privilege level; w16, w17, w6, w5, w7 scratch. x19 to x22 are callee-saved, so blocks
are entered through twelve generated instructions that save and load them.

**Flags.** The translator knows which instruction set the flags last. The generated code
keeps that instruction's operands and result in w1 to w3 (the record); EFLAGS is written out
from it where the block is left. A conditional jump or SETCC redoes the comparison on the
record with the host's flags where that gives the condition, and works it out from EFLAGS
where it does not. Instructions whose flags depend on the old ones (INC, DEC, shifts, ADC)
have the record written out first.

**Memory.** `j_mem` is the short path of `seg_read` and `seg_write` inline: the offset below
`seg_top`, the access inside one page, the TLB's tag in the right half, then a load or store
in RAM. Anything else (a TLB miss, a fault to come, a store into a page of code) goes to a way
out placed after the block's body, which stores the registers changed so far, writes the
flags out, and returns the address of *that* instruction and the count of instructions
executed before it. The interpreter then executes that instruction. Generated code never
faults and never calls back into Goose.

**When a block is made.** Arrivals are counted where a run begins and where a block ends
(`jit_arrive`); at the eighth, the block is translated. It may run through an instruction
that begins another block (blocks overlap). A block of one instruction is not made; if what
followed it may be translated later (it was not in the decode cache, or not yet classified),
the address is counted afresh. An entry of the decode cache can be driven out by another
address that wants its slot; when it is made again and classified, it gets its block back
(`jit_reclaim`) if the page has not been written since.

**When a block dies.** A store into a page that has decode-cache entries goes the long way
already (E044); it also moves the page's `code_gen` on, and a block made under another
generation is dropped when it is next reached. When the room for code is used up, every
page's generation is moved on, which drops every block, and translation starts again from
empty (`jit_flush`).

## Finding a wrong translation

1. Run the failing program with `--jit --jit-off 1023`. If it is right, a translated kind is
   wrong; if it is still wrong, look at the block machinery (entry, counts, ways out).
2. Halve: `--jit-off` with half of the bits, then the other half, then one bit at a time.
   The Linux boot takes ten seconds, so a group is found in under two minutes (E062 found
   ADC to memory in seven boots).
3. For a small program: `tools/jit-firstbad.sh program.bin` finds, by halving, the first
   instruction count after which the JIT's run is not where the trace is; that instruction
   is in the block that went wrong.
4. If the process hangs, attach a debugger: `lldb -p PID`, `x/12i $pc-24`. Generated code has
   no symbols; a `b .` is a branch that was never filled in.
5. When it is found, add the case to a self-check and a deliberately wrong build that puts
   the bug back, and see the self-check fail.

## Tests

`tools/difftest.sh` runs, with `--jit`: every self-check, a stop after each of 400
instruction counts in `s_pairs` against the trace, and the Linux boot against the boot
without the JIT. The self-checks written for the JIT: `s_jit` (blocks without memory),
`s_jitpage` (a jump into another page), `s_jitmem` (memory operands and ways out),
`s_jitseg` (a segment's limit), `s_jitring` (the privilege level), `s_jitops` (8-bit
operations, shifts, rotates, the arithmetic to memory, ADC, SBB, SETCC), and `s_cslimit`
(a block that runs past the code segment's limit).

Three ways a test has failed to test, each met here: a result that nothing reads; a sum in
which the difference cancels (changes in one bit, summed with an odd multiplier, four times);
and blocks that are never run, because the test stores into its own page of code on every
pass, or because every block leaves at its first instruction. The count of instructions in
blocks, printed with `--jit`, shows the last.

## Where it stands (2026-11-17, after E063)

Linux boot to the shell prompt, Apple M1, medians of six:

| | Host instructions | Cycles |
|---|---:|---:|
| Interpreter (main before the JIT) | 145.8 billion | 28.1 billion |
| This source without `--jit` | 147.4 billion | 28.1 billion |
| `--jit` after E062 | 123.3 billion | 22.1 billion |
| `--jit` | 94.9 billion | 17.7 billion |

- 90% of the guest instructions run in blocks (1,480 of 1,651 million).
- 245.7 million blocks are run, 6.0 instructions each on average; the run comes to a block
  66.2 million times, so 3.7 blocks are run one after another before the interpreter is back.
- 71,482 blocks are translated in a boot and the code is dropped once (32 MB).
- A guest instruction costs 57 host instructions over the whole boot, where the
  interpreter's costs 88. Most of that is still between blocks, not in them.

What stops a chain of blocks now (66 million times): a kind the translator does not know,
31 million (what the interpreter has no executor for 7.9, IMUL 6.8, MOVSW 6.7, `mov` with a
16-bit operand 7.0, LODSB 2.4); the next address in another page, 15 million; a known
instruction that is no block, 13 million (RDTSC after it 6.5, a lone jump 4.7); the block
left before its first instruction, 3 million.

## Tasks

In the order the numbers above suggest. Each becomes a card in the ledger when it is
started; this list is updated when one is done.

| # | Task | Why | State |
|---|---|---|---|
| 1 | A block may run through an instruction that heads another block; a refused translation is tried again when the reason may have passed; a block survives its entry leaving the decode cache | 50 of the 80 million chain stops | done, E063: 37% under the interpreter |
| 2 | `--jit` refused on a host that is not arm64 | It would run arm64 code on any other | done, E063 |
| 3 | The kinds still unknown: `mov` with a 16-bit operand, IMUL, the string instructions without REP, RDTSC | 31 of the 66 million chain stops | |
| 4 | From block to block inside generated code: the guest registers stay in host registers, the time left is counted down there, and Goose is returned to only where a block cannot go on. With it, a block in the next page (15 million chain stops) | Most of the 57 host instructions a guest instruction still costs | |
| 5 | The flags' record kept across the end of a block where the next block sets the flags before anything can read them | Up to thirty instructions at most block ends | |
| 6 | The interpreter's cost of carrying the JIT, measured over layouts again | E062 read 1.1% in one layout; E060 0.1% in three; E063 0.1% in one | |
| 7 | The code cache full: drop everything and start again | The Linux boot fills 32 MB once | done, E063 |
| 8 | A page that is both stored into and run: its blocks are dropped and remade for ever | Not measured | |
| 10 | Blocks are made at many overlapping starts (71 thousand in a boot, 35 MB of code): a block for an address inside an existing block could enter that block's code part way | Translation time and the one flush | |
| 9 | Whether `--jit` becomes the default on arm64 | After 4, with the suite run both ways | |
