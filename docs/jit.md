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

At the end of a run the statistics line gains `jit N blocks, M instructions, E entries, L
links, B bytes, F flushes`: blocks translated, guest instructions executed in blocks, times
generated code was entered, link slots filled in, bytes of generated code now held, and times
the code filled up and was dropped. A test that means to run blocks and shows `0 blocks` or a
handful of instructions is not testing them (it has happened three times; see "Tests").

`--jit-off N` tells the translator to leave groups of instruction kinds to the interpreter; N
is a sum of the bits in `jit_plain` (jit.goose). It is for finding a wrong translation: see
"Finding a wrong translation". `--jit-size N` makes the room for code N bytes (70,000 at least,
64 MB by default), so that a test can see it fill up.

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
entry's slot in `jit_at` and returns. `exec_one` calls `jit_blocks`, which enters generated
code at that block and, when it comes back, at whatever block it came back for, then lets
`exec_short` go on. Nothing of the JIT is
inside `exec_short` beyond that store: code for it there cost every interpreted instruction 1
to 3% (E060). A block is run only if its page has not been written since it was made
(`code_gen`), the run has time for all of it, and its last instruction is within what the run
may execute; otherwise its first instruction is run by the general path, by its own kind.

**Registers in generated code.** x0 the guest's registers in memory; x19 RAM, x20 the TLB
arrays, x21 `seg_top`, w22 what a physical address in the page is above the instruction
pointer; w8 to w15 the eight guest registers; w1 to w3 the flags' record; w4 the half of the
TLB for the current privilege level; x23 the time left, x24 what it was on the way in, x25
the virtual time then; w16, w17, w6, w5, w7 scratch. The way in (at the start of the
mapping) saves x19 to x25, loads all of these and jumps to a block; the way out (behind it)
stores the eight guest registers and returns.

**From block to block.** A block begins by taking its length off the time left; if there is
not that much, it leaves at once. Where a block ends at a fixed address (a jump either way,
a CALL, the instruction after its last), it writes the flags' record out and goes through a
*link slot*: one branch, which at first goes to the way out with that address and the
slot's own. `jit_blocks`, seeing generated code come back through a slot for an address that
begins a good block in the same page, makes the slot a branch to that block, and from then
on generated code goes straight on, with the guest's registers still in the host's. Links
are only made inside a page: a store into the page makes every block in it stale together,
and a stale block is entered only from Goose, which checks. Where the code segment's limit
cuts into the page, generated code is given time for one block at a time and nothing is
linked.

**To another page, and from a RET.** A block that ends at a RET, or at a fixed address in
another page, branches to *the far way*: code after the way out that is given an address
and does what a run of the interpreter does when it changes page, then what Goose does
before it enters a block. The page has to be whole inside the code segment's limit
(`jit_ctx[0]`, set before each call); the TLB has to have it for reading at this privilege
level; `jit_head` and `jit_gen` of the address's slot have to say a block begins there that
was made under the page's present `code_gen`. Then w22 becomes the new page's and the block
is entered. Otherwise the way out. Nothing is remembered between arrivals, so a store into
either page, a change of the paging and a new limit are all seen. `--jit-off 32768` turns
it off.

**Kinds.** The translator reads what `classify` left in the decode cache's entries: it
decodes nothing. An instruction the interpreter has a short executor for has a kind from 1
to `K_LAST`; one it has none for, but the translator knows, has a kind from there to
`K_JLAST`, given only when the JIT is on, which a run leaves to the general path (E073).
`--jit-off 131072` turns those off.

**Flags.** The translator knows which instruction set the flags last in the block. The
generated code keeps that instruction's operands and result in w1 to w3 (the record), and
where a block ends it puts the record's kind in w26 (0: EFLAGS in memory is right) and goes
on: the next block nearly always sets the flags anew (E070). A block begins not knowing
the kind. A conditional jump or SETCC redoes the comparison on the record with the host's
flags where the block made the record and that gives the condition. Where EFLAGS itself
is needed (an instruction whose flags depend on the old ones: INC, DEC, shifts, rotates,
ADC; a condition the record does not give), a record the block made is written out inline,
and one it inherited by a call to *the flags' code* after the far way, which does it by
the kind in w26. The way out calls that too, so Goose always finds EFLAGS right.

Flags that nothing can see are not made (E071). `j_dead` looks ahead in the block: if an
instruction that sets all six flags comes before any that reads one, has a memory operand
(a way out) or ends the block, then a shift, a rotate, INC, DEC, IMUL, ADC or SBB here is
the bare host instruction. Otherwise INC and DEC put only the carry of the block's own
record into EFLAGS, and ADC and SBB take the carry from the record. `--jit-off 65536`
turns the look ahead off.

**Memory.** `j_mem` is the short path of `seg_read` and `seg_write` inline: the offset below
`seg_top`, the TLB's tag in the right half compared with the page of the access's *last*
byte (which also says the access is inside one page: a tag has its index's low eight bits,
and the next page has not; E072), then a load or store in RAM. Anything else (a TLB miss, a fault to come, a store into a page of code) goes to a way
out placed after the block's body, which stores the registers changed so far, writes the
flags out, and returns the address of *that* instruction and the count of instructions
executed before it (the time for the rest is given back). The interpreter then executes that
instruction. Generated code never faults and never calls back into Goose.

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
operations, shifts, rotates, the arithmetic to memory, ADC, SBB, SETCC), `s_jitslot` (a block
whose decode-cache entry goes and comes back), `s_jitchain` (blocks that lead to one another;
the stops are taken here), `s_jitfar` (the far way's four tests), `s_jitflags` (the record from block to block), `s_jitdead` (flags never seen, the carry
alone, and what a fault's handler finds), `s_jitkinds` (the kinds without executors, and
divisions that fault), `s_jitstr` (string instructions, 16-bit moves, IMUL), `s_jittsc`
(RDTSC), and `s_cslimit` (blocks at the code segment's limit). The JIT's self-checks are
also run with room for 70,000 bytes of code, so that it fills up while they run.

Three ways a test has failed to test, each met here: a result that nothing reads; a sum in
which the difference cancels (changes in one bit, summed with an odd multiplier, four times);
and blocks that are never run, because the test stores into its own page of code on every
pass, or because every block leaves at its first instruction, or because the program is over
before the eighth arrival anywhere (the first stop sweep). The count of instructions in
blocks, printed with `--jit`, shows the last. A fourth: an instruction the assembler encodes
another way than the one meant (`test al, imm` and `mov cx, dx` have two encodings each).

## Where it stands (2026-11-18, after E073)

Linux boot to the shell prompt, Apple M1, medians of five in one hour:

| | Host instructions | Cycles |
|---|---:|---:|
| Interpreter (main before the JIT) | 145.6 billion | 27.59 billion |
| `--jit` after E066 (kinds with executors) | 58.0 billion | 13.35 billion, an hour earlier |
| `--jit` after E072 (the far way, the flags) | 41.1 billion | 9.32 billion |
| `--jit` after E073 (kinds without executors) | 35.9 billion | 8.40 billion |

- 70% fewer cycles than the interpreter. A guest instruction costs 22 host instructions
  over the whole boot, where the interpreter's costs 88.
- 98.2% of the guest instructions run in blocks (1,621 of 1,651 million).
- Generated code is entered 11.3 million times in a boot; the far way finds a block 25.7
  million times; 36 thousand link slots are filled.
- 66.6 thousand blocks are translated, 24.1 MB of code, no flush (the room is 64 MB).

## Tasks

In the order the numbers above suggest. Each becomes a card in the ledger when it is
started; this list is updated when one is done.

| # | Task | Why | State |
|---|---|---|---|
| 1 | A block may run through an instruction that heads another block; a refused translation is tried again when the reason may have passed; a block survives its entry leaving the decode cache | 50 of the 80 million chain stops | done, E063: 37% under the interpreter |
| 2 | `--jit` refused on a host that is not arm64 | It would run arm64 code on any other | done, E063 |
| 3 | The kinds still unknown: `mov` with a 16-bit operand, IMUL, the string instructions without REP, RDTSC | 31 of the 66 million chain stops | done, E066: 55% under the interpreter |
| 4 | From block to block inside generated code: the guest registers stay in host registers, the time left is counted down there, and Goose is returned to only where a block cannot go on | Most of the 57 host instructions a guest instruction cost | done, E065 |
| 4b | From a block to a block in another page, and from a RET | 16 million of 34.5 million trips (E067) | done, E069: the far way looks the block up at every arrival; nothing is linked across pages |
| 4c | A block of one instruction where that is a jump | 4.5 million trips (E067) | done, E068 |
| 5 | The flags' record kept across the end of a block | Up to thirty instructions at most block ends | done, E070: 5% of the instructions, 9% of the cycles, a fifth of the code |
| 6 | The interpreter's cost of carrying the JIT, measured over layouts again | E062 read 1.1% in one layout; E060 0.1% in three; E063 0.1% in one | |
| 7 | The code cache full: drop everything and start again | The Linux boot fills 32 MB once | done, E063; the room is 64 MB since E069 |
| 8 | A page that is both stored into and run: its blocks are dropped and remade for ever | Not measured | |
| 11 | A loop with no instruction for the general path in it never gets a block: arrivals are counted only where a run begins and where a block ends | Found in E065; the Linux boot hides it because the timer ends runs | |
| 12 | The instructions with no executor that blocks stop at get kinds above `K_LAST` that only the translator knows | 6.95 of the 16.5 million trips (E067, E069) | first part done, E073: `mov eax, moffs` and back, LEAVE, `push imm` and `push r/m`, XCHG, BSWAP, CDQ, CLD and STD, a rotate by one, MOVSX, MUL, IMUL, DIV, IDIV. 11.3 million trips |
| 12b | The rest: REP string instructions, CMPXCHG, SHRD and SHLD, PUSHF, group 83 with a prefix or longer than eight bytes, indirect CALL and JMP | Count again first: E067's list is from before E073 | |
| 13 | INC and DEC in a block that inherited a record: the carry alone, by a second entry of the flags' code | 29 million whole records written for one bit (E071) | |
| 14 | A shift or rotate whose flags may be seen, after a record the block made: only what it keeps (the auxiliary carry, the overflow) written | 19 million (E071) | |
| 10 | Blocks are made at many overlapping starts (71 thousand in a boot, 35 MB of code): a block for an address inside an existing block could enter that block's code part way | Translation time and the one flush | |
| 9 | Whether `--jit` becomes the default on arm64 | After 4, with the suite run both ways | |
