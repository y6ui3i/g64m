# A JIT for the 64-bit CPU: the design

Written before any of it is built (E116 in [experiments.md](experiments.md)). The 32-bit
machine has a JIT ([jit.md](jit.md), `src/jit.goose`); this is that design carried over to
the 64-bit CPU (`src/cpu64.goose`), with what is the same, what is new, and the order of
work. It is kept up to date as the tasks at the end are done, as jit.md is.

## Why

| | Guest instructions a second | Host instructions for each |
|---|---:|---:|
| The 64-bit CPU, interpreted (after E114) | 62 million | 284 |
| The 32-bit CPU, interpreted | | 88 |
| The 32-bit CPU with its JIT (E073) | 341 million running X | 22 |

NetHack is built by GCC in 71 seconds on the real machine (an Ivy Bridge) and in more than
half an hour by the guest's GCC on g64m. Everything left in the interpreter's plan
([primitives64.md](primitives64.md)) is a factor of two at best.

## The yardstick: QEMU on the same host (E117)

The aim is to get past QEMU's user-mode emulator, which is what Docker runs an x86_64
program with on an arm64 host that has no Rosetta. Million guest instructions a second on
the primitives, Apple M1 (`tools/prim64_qemu.sh`; rough, the programs are short):

| Primitive | QEMU 11.0.3 | Docker's own | g64m | g64m behind QEMU |
|---|---:|---:|---:|---:|
| `p_shift` | 8,200 | 11,354 | 42 | 195 times |
| `p_bitfield` | 5,878 | 7,511 | 38 | 155 times |
| `p_ternary` | 4,925 | 7,164 | 43 | 115 times |
| `p_pixel` | 4,077 | 5,889 | 40 | 102 times |
| `p_sha` | 2,800 | 4,800 | 42 | 67 times |
| `p_bytes` | 2,768 | 5,767 | 44 | 62 times |
| `p_rotate` | 2,594 | 3,978 | 47 | 56 times |
| `p_index` | 1,993 | 6,644 | 41 | 48 times |
| `p_bignum` | 1,596 | 4,257 | 35 | 45 times |
| `p_loop` | 2,000 | 5,000 | 45 | 44 times |
| `p_pointer` | 2,000 | 5,077 | 47 | 43 times |
| `p_simd` | 851 | 4,150 | 24 | 36 times |
| `p_if` | 1,394 | 3,538 | 45 | 31 times |
| `p_recursion` | 841 | 1,743 | 46 | 18 times |
| `p_muldiv` | 832 | 4,400 | 46 | 18 times |
| `p_dbl_cmp` | 620 | 5,357 | 43 | 14 times |
| `p_switch` | 511 | 1,290 | 40 | 13 times |
| `p_dbl_arith` | 369 | 1,394 | 37 | 10 times |
| `p_float` | 376 | 1,650 | 37 | 10 times |
| `p_funcptr` | 292 | 1,020 | 46 | 6 times |
| `p_dbl_conv` | 207 | 5,200 | 37 | 6 times |
| `p_ldbl` | 74 | 35 | 26 | 3 times |
| `p_fill` | 339 | 1,560 | 277 | 1.2 times |

QEMU runs straight-line integer code at 2,000 to 8,000, jumps through a register at 300 to
800, double and float at 200 to 600, the x87 at 74. g64m interpreted is 24 to 47 whatever
the instruction. Each task below is reported as this table again.

**After E120 to E125 (E126)**, with each primitive's work done thirty times so that it can
be timed (`tools/prim64_long.sh`), million guest instructions a second:

| | QEMU | Rosetta | g64m `--jit` | g64m / QEMU |
|---|---:|---:|---:|---:|
| `p_muldiv` | 1405 | 9515 | 5698 | 4.06 |
| `p_recursion` | 1567 | 3319 | 2745 | 1.75 |
| `p_funcptr` | 455 | 1486 | 699 | 1.54 |
| `p_loop` | 3988 | 15023 | 5778 | 1.45 |
| `p_fill` | 536 | 3211 | 593 | 1.11 |
| `p_pointer` | 3495 | 9245 | 3319 | 0.95 |
| `p_bignum` | 3412 | 10083 | 3097 | 0.91 |
| `p_if` | 2439 | 4827 | 2001 | 0.82 |
| `p_index` | 3494 | 14254 | 2833 | 0.81 |
| `p_ternary` | 10743 | 16881 | 8206 | 0.76 |
| `p_bytes` | 5112 | 11531 | 3858 | 0.75 |
| `p_switch` | 834 | 1840 | 584 | 0.70 |
| `p_pixel` | 10316 | 13935 | 6157 | 0.60 |
| `p_shift` | 16598 | 21417 | 7041 | 0.42 |
| `p_ldbl` | 115 | 47 | 35 | 0.31 |
| `p_dbl_conv` | 298 | 7251 | 53 | 0.18 |
| `p_sha` | 7534 | 13643 | 840 | 0.11 |
| `p_dbl_arith` | 505 | 2134 | 52 | 0.10 |
| `p_float` | 589 | 2501 | 52 | 0.09 |
| `p_dbl_cmp` | 885 | 9365 | 59 | 0.07 |
| `p_rotate` | 4091 | 5939 | 270 | 0.07 |
| `p_bitfield` | 11936 | 14847 | 524 | 0.04 |
| `p_simd` | 1477 | 8735 | 36 | 0.02 |

Ahead of QEMU on division, RET and jumps through an operand; within a factor of three
on the rest of the integer code that runs in blocks; ten times and more behind on the
floating point, on rotations and on 16-bit operations, none of which is translated (or,
for rotations, not where their flags are needed).

**After E127 to E130 (E131)**, the same measure again: at or past QEMU on thirteen of the
fourteen integer primitives that run in blocks.

| | QEMU | Rosetta | g64m `--jit` | g64m / QEMU |
|---|---:|---:|---:|---:|
| `p_muldiv` | 1398 | 9515 | 6195 | 4.43 |
| `p_recursion` | 1541 | 3319 | 3726 | 2.42 |
| `p_funcptr` | 461 | 1486 | 1056 | 2.29 |
| `p_loop` | 3756 | 16693 | 7907 | 2.11 |
| `p_switch` | 834 | 1853 | 1426 | 1.71 |
| `p_bignum` | 3378 | 10315 | 4515 | 1.34 |
| `p_pointer` | 3411 | 9245 | 4192 | 1.23 |
| `p_index` | 3454 | 14967 | 3991 | 1.16 |
| `p_shift` | 16154 | 22131 | 18290 | 1.13 |
| `p_bytes` | 5014 | 12504 | 5520 | 1.10 |
| `p_fill` | 541 | 3211 | 587 | 1.09 |
| `p_if` | 2439 | 4827 | 2547 | 1.04 |
| `p_ternary` | 10458 | 16881 | 10743 | 1.03 |
| `p_pixel` | 9929 | 13935 | 9236 | 0.93 |
| `p_ldbl` | 114 | 48 | 36 | 0.31 |
| `p_sha` | 7534 | 13643 | 2305 | 0.31 |
| `p_dbl_conv` | 301 | 9855 | 53 | 0.18 |
| `p_dbl_arith` | 554 | 2155 | 53 | 0.10 |
| `p_float` | 569 | 2566 | 52 | 0.09 |
| `p_rotate` | 4068 | 5979 | 281 | 0.07 |
| `p_dbl_cmp` | 894 | 9605 | 60 | 0.07 |
| `p_bitfield` | 12448 | 15256 | 612 | 0.05 |
| `p_simd` | 1495 | 9958 | 37 | 0.02 |

**With the scalar SSE instructions (E132)**: `p_dbl_conv` 9.6 times QEMU, `p_dbl_cmp` 3.8,
`p_dbl_arith` 2.0, `p_float` 1.7 (they were at 0.07 to 0.18). Eighteen of the
twenty-three primitives are at QEMU's speed or past it.

**Host instructions for a guest instruction (E129, E130)**, net of the emulator's start
(`tools/prim64_net.py`): 1.3 (`p_shift`) to 11.7 (`p_funcptr`), `p_loop` 1.5, `p_if`
4.6, `p_pointer` 4.6. The interpreter is about 280.

## What the guest's code looks like to a translator (the boot, 1,524 million instructions)

Counted with the kinds the short front has now (E110: ALU with ModRM, MOV, the group
80h/81h/83h, TEST, LEA, MOVZX, PUSH, POP, CALL, RET, Jcc, JMP):

| | Share of the instructions | Runs | Mean length |
|---|---:|---:|---:|
| In a run of two or more of those kinds that ends at a jump (the jump included) | 53.3% | 220 million | 3.7 |
| In a run of two or more that ends at an instruction of no kind | 25.4% | 92 million | 4.2 |
| Of a kind, but alone between two instructions of no kind or two jumps | 5.9% | | |
| Of no kind | 13.7% | | |

So a translator that knew only the front's kinds would take 79% of the instructions, in
blocks under four instructions long: too short. What cuts the runs, by first byte (share
of all instructions): shifts and rotations `D3` 3.0%, `C1` 2.2%, `D1` 0.6%; the group
`F6`/`F7` (TEST with a constant, NOT, NEG, MUL, DIV) 2.5%; NOP in its two forms 1.8%;
MOVSXD 0.7%; MOV of a constant to a register (`B8` to `BF`) 0.8% and to an operand
(`C6`, `C7`) 0.5%; ENDBR64 0.5%; the group `FF` 0.2%; the forms with a constant and the A
register 0.3%; CMOV 0.1%. With those the kinds cover 97%.

**With those kinds added (E118)**, and a few more that cut the runs in user programs
(SETcc, IMUL with two and three operands, MOVSX, CDQ and its family, PUSH of a constant):

| | Share of the instructions | Runs | Mean length |
|---|---:|---:|---:|
| In a run of two or more that ends at a jump (the jump included) | 96.1% | 253 million | 5.8 |
| In a run of two or more that ends at an instruction of no kind | 0.8% | 2.2 million | 5.4 |
| Of a kind, but alone | 1.1% | | |
| Of no kind | 0.25% | | |

(The first table's shares do not sum to 100 either: an instruction of a kind that follows
a jump and is followed by one is counted nowhere.) A jump here is any of CALL, RET, JMP
and Jcc, taken or not, the forms through an operand included. What is left without a
kind, by share of all instructions: PUSHF 0.03%, STOSD 0.03%, CMPXCHG 0.03%, CLI 0.02%,
MOV from a segment register 0.02%, BT with a constant 0.02%, LEAVE 0.01%. The integer
primitives run in the front whole; what they leave is the SSE, the x87, BSF and BSR, and
the string instructions.

The boot is the kernel unpacking itself and starting (0.2% of it at privilege level 3).

**A user program (E119)**: NetHack's source compiled in the guest by GCC, 428 billion
instructions, 80% in user mode. With E118's kinds 96.3% of them are of a kind. What is
left is the SSE's moves and PXOR/POR (about 2%: GCC copies and clears structures with
them, in integer code), repetitions of string instructions (about 1%), and BT.

## What is the same as the 32-bit JIT

- **A block** is instructions that follow one another in one physical page, to a jump
  (included) or to an instruction the translator does not know (excluded), found through
  the decode cache: the entry of its first instruction gets the kind `K_BLOCK` and keeps
  its own kind beside it. The translator decodes nothing: it reads the entries (`Ins`,
  E109), which hold the prefixes, the operand size, and the ModRM's base, index, scale
  and displacement already. The cache is 2^20 entries (E152; 2^18 until then) in sets of two ways (E142: a slot
  and its neighbour), and a new instruction takes the way where no block begins, so that
  a block keeps its first instruction's entry; before that, four blocks in five were lost
  to another instruction wanting the slot, and translated again (E141).
- **Entering** from the short front, by one more arm of its jump on the kind. Nothing
  else of the JIT is in the interpreter's path.
- **Generated code never faults and never calls back.** Anything it cannot do (a TLB
  miss, a store into a page that holds code, a fault to come) leaves by a way out placed
  after the block, which gives back the address of that instruction and how many were
  executed before it; the interpreter runs that instruction.
- **Time.** A block takes its length off the time left before it begins. The run loop's
  test after every instruction (E106) needs nothing inside a block: what it asks about
  is set only by instructions that are not translated (STI, SYSCALL, HLT, a port) or at
  a time the run loop knows.
- **The flags as a record**: the last flag-setting instruction's operands and result in
  three host registers and its kind in a fourth; a conditional jump redoes the
  comparison with the host's flags; RFLAGS itself is made only where it is needed.
  Flags that nothing can see are not made.
- **Links** between blocks inside a page (an exit to an address with no block yet waits in a
  chain kept in the room itself, four words behind its branch, and is made a branch when
  the block comes: E145; a table of 65,536 before that, full most of the time), a far way to a block in another page (looked up
  at every arrival, nothing remembered), translation at the eighth arrival (an arrival:
  a jump's landing, or since E137 any instruction the interpreter runs that is in no
  block yet), everything dropped when the room for code (128 MB) is full.
- **When a block dies**: a store into a page that holds decode-cache entries already
  goes the long way (`mem_wr_marked`, E107) and drops them; a generation number for the
  page, moved on there, makes its blocks stale.
- **The C**: `src/jit.c` (the mapping, the copy, the call) is used as it is.
- **Finding a wrong translation** by `--jit-off` with a bit for each group of kinds, and
  the count of instructions run in blocks printed, so that a test that runs none is seen.

## What is new

- **Sixteen registers, in host registers for the whole of a block.** arm64 has 28 that
  generated code may use (x0 to x17 and x19 to x28; it calls nothing, so none is lost to
  a call). Sixteen for the guest's; the memory array, the TLB, the time left, what a
  virtual address in the page is above a physical one; three for the flags' record and
  one for its kind; four scratch. That is 28: there is no room to spare, and the first
  thing to give way, if one more is needed, is the least used guest registers going to
  memory. The way in loads sixteen and the way out stores sixteen (eight instructions
  each with pairs).
- **Operands of 64, 32, 16 and 8 bits.** A 32-bit result clears the upper half, which
  is what a host instruction on a `w` register does. 8 and 16 bits are put into the
  register with a bit-field insert. The flags' record keeps the width in its kind. Since
  E138 the 16-bit ALU operations, CMP, TEST, the shifts by a constant, NOT, NEG and MOV
  of a constant are translated as the byte forms are: the operands shifted up in a 32-bit
  host register, so that the host's flags are the narrow result's. BT, BTS, BTR and BTC
  of registers give a jump right behind them a TST of the bit, and otherwise a record of
  the value and the bit's number, handled as INC and DEC's flags are; SHLD and SHRD of
  registers are one EXTR by a constant, or two shifts and an OR by CL.
- **Addresses relative to RIP, and the return address a CALL pushes.** A block is found
  by its physical address, and one page of a shared library is at different virtual
  addresses in different programs, so RIP cannot be a constant in generated code: it is
  the page's virtual base, held in a register, plus a constant. One instruction more
  where RIP is used.
- **Memory through the 64-bit TLB**: six tables (read, write and fetch, each for
  privilege level 3 and below it), a tag that is the whole page number, so one compare
  says both that the page is there and that the address is canonical. An access that
  runs over a page's end leaves by the way out, as do FS's and GS's bases at first.
- **Two kinds of run.** A program run without a kernel (`build/g64m program`) has no
  paging: its memory operand is a bounds test and an index. The translator makes one or
  the other when it translates.
- **No segments' limits**, which the 32-bit translator tests at every access and every
  jump.
- **A page that is both stored into and run** is given up by the decode cache after 32
  drops (E107), so it never gets blocks: the 32-bit JIT's task 8 does not arise.

## What is not known yet

- How long a block is when it may go on through a jump that is not taken: a run as
  counted above ends at every Jcc, and is 5.8 instructions in the mean (E118).
- Whether 28 registers are enough in practice, or which guest registers go to memory.
- A user program's runs: E119 counted its kinds, not how they fall into runs.
- The cost in the interpreter of carrying the hook (the 32-bit one's was 0.1% to 1.1%).

## Tasks

Each becomes a card in the ledger when it is started. Measured on the primitives
(`tools/prim64_table.py`) and the boot; held to the real CPU by the suites there are
(`tools/difftest64.sh`, `tools/systest64.sh`, `tools/prim64.sh`), each run with and
without `--jit`.

| # | Task | Measured on |
|---|---|---|
| 1 (done, E118) | The kinds that cut the runs: shifts and rotations, `F6`/`F7`, NOP and ENDBR64, MOVSXD, MOV of a constant, the constant-and-A forms, CMOV and SETcc, the indirect CALL and JMP. In the short front first, so that each is tested as interpreted before it is translated | the count above, again |
| 2 (done, E120: `p_shift` 309 → 27, the boot 276 → 201; an entry into a block costs 300 to 500 host instructions, which tasks 4 to 6 take away) | An emitter for arm64 with 64-bit operands (`src/jit64.goose`), the way in and out, and a block of instructions without memory operands, entered from the front; `--jit` on `build/g64m` | `p_loop`, `p_if`, `p_shift` |
| 3 | The flags' record for four widths, and the jump that reads it | `p_ternary`, `p_switch`, the trace tests with `--jit` |
| 4 (done, E121, with the stack and the jumps through an operand: `p_pointer` 247 → 92, `p_index` 247 → 79; a program of branches is still at 190, an entry for every 2.3 instructions, so links come next) | Memory operands for a program without a kernel, with the way out | `p_pointer`, `p_index`, `p_bytes`, all the primitives |
| 5 (done, E133, with links on a page: the boot 180 → 89 host instructions for a guest instruction, 16.9 s → 8.3 s; the far way in a machine, E134: the boot 2.4 s to QEMU's 2.5) | Memory operands through the TLB, and the stack (PUSH, POP, CALL, RET) | the system tests, the boot |
| 6 (links done for a program without a kernel, E122: `p_if` 192 → 23, `p_loop` 107 → 28; the far way for the same, E123: `p_recursion` 60 → 37, `p_funcptr` 121 → 40; neither yet in a machine) | Links inside a page and the far way | the boot, NetHack |
| 7 | What is left by count: the string instructions, MUL and DIV, the rest | the boot, NetHack built in the guest |
| 8 (done, E132, with the XMM registers in memory; in a machine too since E139, the block leaving before an SSE instruction when CR0.TS or EM is set or CR4.OSFXSR clear) | The scalar SSE instructions | `p_dbl_arith`, `p_float`, `y_sse` |
