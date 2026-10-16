# RISC-V Core Project: Master Plan

> **Source of truth.** Read this at the start of every session. Tick boxes as items finish, and add a dated line to the Progress Log at the end of each session.

---

## 0. The project in one paragraph

A **5-stage pipelined RV32IMA processor in SystemVerilog** with **M/S/U privilege modes**, an **Sv32 MMU** (split I/D TLBs plus a hardware page-table walker) and **I/D caches**, wrapped in a small SoC (boot ROM, RAM, UART, CLINT timer, minimal PLIC). It **boots xv6-rv32 to a shell and passes `usertests`**, is **verified instruction-by-instruction against Spike** and the official RISC-V compliance suites in CI, and **logs every real design bug** as a dataset for an LLM-based hardware-debugging study.

**Target audience:** CPU, SoC and design-verification teams (Arm, IBM, Qualcomm, Intel, AMD, TI, Marvell, startups) and summer/research internships.

**Budget:** ~10–12 hours/week, starting late October 2026. About 30 weeks to the write-up, with stretch goals after that.

---

## 1. Aims (the "why")

| # | Aim | What success looks like |
|---|---|---|
| A1 | Learn computer architecture deeply | You can whiteboard every part of the core and explain every design tradeoff without notes |
| A2 | Prove correctness to an outsider | Compliance suites, Spike lockstep diff and CI badge, not "it seems to work" |
| A3 | Build a resume centerpiece | A project that fills a 45-minute interview with questions you can answer well |
| A4 | Produce a research contribution | A workshop paper or poster (CARRV, RISC-V Summit) built on your own bug data |

## 2. Objectives (measurable)

| ID | Objective | Measured by | Phase |
|---|---|---|---|
| O1 | 100% pass on `riscv-tests` and `riscv-arch-test` for RV32IMA + Zicsr + privileged | Test runner report in CI | 1–4 |
| O2 | Zero mismatches against Spike on CoreMark, FreeRTOS and xv6 boot | Commit-log diff script | 1–5 |
| O3 | FreeRTOS running 3+ tasks switched by timer interrupts | UART output in sim | 3 |
| O4 | xv6 boots to shell; `usertests` reports ALL TESTS PASSED | Recorded demo | 5 |
| O5 | CoreMark/MHz, CPI with stall breakdown, cache hit rates, TLB miss rates | Perf counters + results table | 2–6 |
| O6 | 40+ real bugs logged (category, detection, fix, time) | `docs/BUGLOG.md` | 1–6 |
| O7 | All tests run on every push | Green GitHub Actions badge | 1+ |
| O8 | (Stretch) FPGA, no-MMU Linux, dual-issue, CFI, formal | Each has its own demo | 8 |

---

## 3. Ground rules

1. **I write the resume-critical RTL myself:** pipeline, hazard/forwarding unit, trap unit, CSR file, MMU and page-table walker, caches.
2. **Infrastructure is tooling, not the deliverable:** testbenches, Makefiles, scripts, the Spike diff, CI, software ports and linker scripts support the core; the RTL above is the work being demonstrated.
3. **Reference cores are for reading, not copying.** Read the design, close it, then write your own. Credit anything adapted in the README and check licenses first.
4. **Nothing counts until it's tested.** Every feature lands with a test, and every phase ends with its exit criteria actually run.
5. **Log every bug the same day** in `docs/BUGLOG.md`. This is the research dataset; it can't be rebuilt later.
6. **Small commits, one feature at a time.** Never add forwarding *and* stalls *and* branch flush in one commit.
7. **Interview test:** after each phase, answer that phase's interview questions out loud without notes. If you can't, the phase isn't done.

---

## 4. Architecture overview

### 4.1 Pipeline

```
 IF ──► ID ──► EX ──► MEM ──► WB
 │      │      │      │       │
 PC     decode ALU    LSU     regfile write
 I$     regfile branch D$     trap commit point
 (BP)   read   mul/div TLB    CSR write
 I-TLB  hazard  forward
```

- **Branch resolution:** in EX at first (2-cycle penalty on taken branches); move to ID or add prediction in Phase 6.
- **Forwarding paths:** EX/MEM→EX and MEM/WB→EX; register file write-before-read (or a bypass) for WB→ID.
- **Load-use:** one-cycle stall plus bubble insertion.
- **Precise traps:** exceptions travel down the pipe with the instruction and are taken only at the commit point (WB). Everything younger gets flushed.

### 4.2 Memory map (copy QEMU `virt` to make the xv6 port easier)

| Region | Base | Size | Notes |
|---|---|---|---|
| Boot ROM | `0x0000_1000` | 4 KB | Jumps to RAM |
| CLINT | `0x0200_0000` | 64 KB | `mtime`, `mtimecmp`, `msip` |
| PLIC (minimal) | `0x0C00_0000` | 4 MB space | Only the UART source; needed by xv6 |
| UART (16550-compatible subset) | `0x1000_0000` | 256 B | xv6 and QEMU expect this |
| RAM | `0x8000_0000` | 64–128 MB | Code, data, xv6 RAM disk |
| Sim-only "tohost" / exit | from linker symbol | — | Lets tests end the simulation |

> **Design decision to record:** matching QEMU `virt` means xv6 needs fewer driver changes. The cost is implementing a 16550 subset and a minimal PLIC instead of a toy UART.

### 4.3 Repo layout

```
riscv-core/
├── README.md
├── Makefile
├── rtl/
│   ├── core/        fetch, decode, regfile, alu, branch, muldiv, lsu, csr, trap, hazard, core_top
│   ├── mmu/         tlb, ptw, mmu_top
│   ├── cache/       icache, dcache
│   ├── bus/         interconnect, arbiter
│   └── soc/         bootrom, ram, uart, clint, plic, soc_top
├── tb/              Verilator C++ harness, SV testbenches, memory loader
├── sw/
│   ├── common/      crt0.S, linker scripts, syscalls/printf stubs
│   ├── tests/       hand-written asm tests (traps, paging, page faults)
│   ├── coremark/
│   ├── freertos/
│   └── xv6/         git submodule of xv6-rv32 plus your patches
├── verif/
│   ├── spike_diff.py
│   ├── riscv-tests/ (submodule)
│   ├── riscof/      config for riscv-arch-test
│   └── rvfi/        later, for riscv-formal
├── scripts/         build, run, regression, perf report
├── docs/
│   ├── PLAN.md
│   ├── BUGLOG.md
│   ├── RESOURCES.md
│   ├── DESIGN.md    design decisions, diagrams, rationale
│   └── img/         block diagrams, Konata screenshots
└── .github/workflows/ci.yml
```

---

## 5. Phase-by-phase plan

Each phase lists: goal, concepts to master first, week-by-week tasks, tests, exit criteria, common bugs to expect, and interview questions you must be able to answer.

---

### PHASE 0: Setup and software-first sanity (Week 1, late Oct)

**Goal:** every tool works, and you've seen xv6 boot in QEMU *before* building any hardware. You'll know what "working" looks like.

**Concepts to read first**
- [ ] RISC-V Unprivileged spec: Ch. 1–2 (RV32I overview and base instructions)
- [ ] Skim the xv6 book, Ch. 1–2 (OS interfaces, organization)

**Tasks**
- [x] Install Homebrew packages: `verilator`, `icarus-verilog`, `qemu`
- [x] Install the RISC-V toolchain and Spike from the `riscv-software-src/riscv` Homebrew tap; xPack `riscv-none-elf-gcc` is the fallback if the tap fails on Apple Silicon
- [x] Confirm the toolchain builds RV32: `-march=rv32ima_zicsr_zifencei -mabi=ilp32`
- [ ] Install a waveform viewer (Surfer) and Konata *(Surfer done; Konata deferred to Phase 2)*
- [x] Create the repo layout from §4.3, `git init`, first commit, push to GitHub
- [x] Clone `michaelengel/xv6-rv32`, build it, boot it in `qemu-system-riscv32`, run `ls` and `usertests` in QEMU
- [x] Write `sw/common/crt0.S` + a linker script for RAM at `0x8000_0000`
- [x] Compile a hello-world C program to an ELF, convert it to a hex/bin memory image
- [x] Run that program in **Spike** with `--isa=rv32ima` and commit logging on; save the log format sample
- [x] Top-level `Makefile` targets: `make sw`, `make sim`, `make test`, `make clean`
- [x] Create `docs/BUGLOG.md`, `docs/DESIGN.md`, `docs/RESOURCES.md`

**Exit criteria**
- [x] Hello-world compiles to an RV32 image and runs in Spike with a commit log
- [x] xv6-rv32 boots to a shell in QEMU and `usertests` passes there
- [x] Repo is on GitHub with the full folder structure

**Interview questions**
- What's the difference between an ISA and a microarchitecture?
- What do `-march` and `-mabi` control, and why does `ilp32` matter?

---

### PHASE 1: Single-cycle RV32I + verification infrastructure (Weeks 2–4, Nov)

**Goal:** a correct (not fast) RV32I core, plus the testing machinery that every later phase reuses. The infrastructure matters more than the core here.

**Concepts to master first**
- [ ] Instruction formats R/I/S/B/U/J and immediate encoding (especially the scrambled B and J immediates)
- [ ] Harris & Harris Ch. 7.1–7.3 (single-cycle datapath and control)
- [ ] Patterson & Hennessy Ch. 4.1–4.4

**Week 2: datapath pieces (you write)**
- [ ] `regfile.sv`: 32×32, 2 read / 1 write, x0 hardwired to zero
- [ ] `alu.sv`: add, sub, and, or, xor, sll, srl, sra, slt, sltu
- [ ] `imm_gen.sv`: all five immediate formats, sign-extended
- [ ] `decode.sv`: opcode/funct3/funct7 → control signals
- [ ] Unit testbench for each

**Week 3: assemble the core**
- [ ] `core_top.sv`: PC, next-PC mux (PC+4, branch, jal, jalr with LSB cleared)
- [ ] Load/store: lb, lh, lw, lbu, lhu, sb, sh, sw with byte enables
- [ ] Simple instruction and data memories loaded from the hex image
- [ ] Verilator C++ harness: loads the ELF/hex, runs until `tohost` write, prints pass/fail
- [ ] **Commit log output** from the core in Spike's format: PC, instruction, destination register and value

**Week 4: verification infrastructure**
- [ ] `verif/spike_diff.py`: runs both, diffs commit logs, reports the first mismatch with context
- [ ] riscv-tests `rv32ui-p-*` runner: builds every test, runs each, prints a summary table
- [ ] `make regress` runs everything
- [ ] GitHub Actions CI: install tools, run regression on every push, badge in README
- [ ] First entries in `BUGLOG.md` (you will have bugs here; log them)

**Tests**
- [ ] All `rv32ui-p-*` pass (about 40 tests)
- [ ] Spike diff clean on hello-world and a small sorting program

**Exit criteria**
- [ ] 100% `rv32ui` pass, Spike diff clean, CI green

**Common bugs to expect**
- B/J immediate bit ordering wrong
- `jalr` not clearing bit 0
- `sra` vs `srl` (signed shift needs `$signed`)
- `sltu` doing a signed compare
- Load sign extension on `lb`/`lh`
- Writes to x0 not ignored

**Interview questions**
- Walk me through `beq` executing in your datapath.
- Why are B-type immediates encoded so strangely?
- How does your testbench know a test passed?
- Why compare against Spike instead of just running tests?

---

### PHASE 2: 5-stage pipeline (Weeks 5–8, Dec)

**Goal:** the classic IF/ID/EX/MEM/WB pipeline with correct hazard handling, measured.

**Concepts to master first**
- [ ] Patterson & Hennessy Ch. 4.5–4.8 (pipelining, data hazards, forwarding, control hazards)
- [ ] Harris & Harris Ch. 7.5 (pipelined processor)
- [ ] Read how `ultraembedded/riscv` structures its pipeline; then close it

**Week 5: pipeline registers only**
- [ ] Insert IF/ID, ID/EX, EX/MEM, MEM/WB registers, each with valid bit
- [ ] Test with programs that have **no hazards** (NOPs between dependent instructions)
- [ ] Commit log now comes from WB

**Week 6: data hazards**
- [ ] Forwarding unit: EX/MEM→EX, MEM/WB→EX (both ALU operands; store data too)
- [ ] Regfile write-first, or a WB→ID bypass
- [ ] Load-use detection: stall IF/ID, insert bubble into EX
- [ ] Directed tests: back-to-back dependent ALU ops, load followed by use, store after load

**Week 7: control hazards**
- [ ] Branch/jump resolved in EX; flush IF and ID on taken
- [ ] Tests: taken/not-taken branches, branch right after load, jal/jalr chains
- [ ] Full regression: all `rv32ui` still pass

**Week 8: measure and visualize**
- [ ] `mcycle` and `minstret` counters (simple versions now, CSR-accessible in Phase 3)
- [ ] Stall counters: load-use stalls, branch flushes
- [ ] Konata trace output from the harness; screenshot into `docs/img/`
- [ ] Record CPI on a few benchmarks in `docs/DESIGN.md`

**Exit criteria**
- [ ] All `rv32ui` pass; Spike diff clean
- [ ] CPI measured with a breakdown; Konata screenshot committed

**Common bugs to expect**
- Forwarding from an instruction that doesn't write a register (or writes x0)
- Forwarding priority wrong (older result wins over newer)
- Stall and flush asserted together, with the wrong one winning
- Bubble not clearing *all* control signals (a phantom store)
- Store data not forwarded

**Interview questions**
- Draw your forwarding paths. Why does EX/MEM take priority over MEM/WB?
- Why can't forwarding fix a load-use hazard?
- What's your branch penalty, and how would you reduce it?
- What's your CPI, and where do the lost cycles go?

---

### PHASE 3: Machine-mode system (Weeks 9–12, Jan)

**Goal:** a real embedded-class core: multiply/divide, atomics, CSRs, interrupts, a UART, and real software running on it.

**Concepts to master first**
- [ ] Unprivileged spec: M extension, A extension, Zicsr
- [ ] Privileged spec Ch. 3: machine-level ISA (`mstatus`, `mtvec`, `mepc`, `mcause`, `mtval`, `mie`, `mip`)
- [ ] How precise exceptions work in a pipeline

**Week 9: M extension**
- [ ] Multiplier: mul, mulh, mulhsu, mulhu (pipelined or 2–3 cycle)
- [ ] Divider: div, divu, rem, remu (multi-cycle, stalls pipeline). Handle divide-by-zero and overflow exactly as the spec says
- [ ] Pass `rv32um-p-*`

**Week 10: CSRs + M-mode traps (you write the trap unit)**
- [ ] CSR file with all required M-mode CSRs; csrrw/csrrs/csrrc and the immediate forms
- [ ] Exceptions: illegal instruction, misaligned fetch/load/store, ecall, ebreak
- [ ] `mret`; trap vector direct mode (vectored optional)
- [ ] Precise trap at commit; flush younger instructions
- [ ] Pass `rv32mi-p-*`

**Week 11: A extension + SoC peripherals**
- [ ] LR/SC (reservation register) and AMOs (amoswap, amoadd, amoand, amoor, amoxor, amomin/max[u])
- [ ] `fence` and `fence.i` (fence.i must flush/refetch; matters once caches exist)
- [ ] CLINT: `mtime`, `mtimecmp`, `msip`; timer interrupt
- [ ] UART 16550 subset: transmit holding register, line status register; the harness prints TX bytes to the terminal
- [ ] Pass `rv32ua-p-*`

**Week 12: real software**
- [ ] Port CoreMark; measure CoreMark/MHz
- [ ] Port FreeRTOS (RISC-V GCC port); 3+ tasks printing over UART, switched by timer interrupts
- [ ] Set up RISCOF + `riscv-arch-test` for RV32IMA + Zicsr; get it passing
- [ ] Spike diff clean on CoreMark and FreeRTOS (interrupt timing may need care; document how you align it)

**Exit criteria**
- [ ] `rv32ui/um/ua/mi` all pass; arch-test passes; CI runs all of them
- [ ] CoreMark/MHz recorded; FreeRTOS 3+ tasks running

**⭐ CHECKPOINT A (late January):** update the README and resume. This version is already well beyond a typical student core, and it lands in time for summer internship conversations.

**Common bugs to expect**
- `mepc` holding the wrong PC (next instruction instead of faulting one)
- CSR write and trap in the same cycle
- Interrupt taken mid-way through a multi-cycle divide
- `mulh` sign handling
- `sc` succeeding after an intervening trap
- `mtime` comparisons on 64-bit values split across two 32-bit registers

**Interview questions**
- How do you guarantee precise exceptions in a pipeline?
- What happens, cycle by cycle, when a timer interrupt arrives?
- How does LR/SC work, and when must SC fail?
- Why does `fence.i` exist?

---

### PHASE 4: Supervisor/User modes + Sv32 MMU (Weeks 13–17, Feb – early Mar)

**Goal:** the hardware an OS needs: privilege separation and virtual memory. This is what most student cores skip, and it's what makes your project stand out.

**Concepts to master first**
- [ ] Privileged spec Ch. 4: supervisor-level ISA, Sv32 page tables
- [ ] xv6 book: page tables and traps chapters
- [ ] RVSoC paper's page-table walker section
- [ ] Trap delegation (`medeleg`, `mideleg`)

**Week 13: privilege modes**
- [ ] M/S/U current-mode register
- [ ] S-mode CSRs: `sstatus`, `stvec`, `sepc`, `scause`, `stval`, `sie`, `sip`, `satp`, `sscratch`
- [ ] `sret`, trap delegation, privilege checks on CSR access and `mret`/`sret`
- [ ] `mstatus` fields: MPP, SPP, MIE/SIE, MPIE/SPIE, SUM, MXR

**Week 14: TLBs (you write)**
- [ ] I-TLB and D-TLB: small fully-associative (4–16 entries), with ASID support optional
- [ ] Permission checks: R/W/X/U bits, SUM and MXR behavior, A/D bits (decide: hardware update or fault; record it)
- [ ] `sfence.vma` flushes

**Week 15–16: page-table walker (you write)**
- [ ] Shared hardware PTW for Sv32: 2-level walk, superpages (4 MB), arbitration between I and D misses
- [ ] Page faults (instruction, load, store/AMO) with correct `stval`
- [ ] Pipeline interaction: stall on TLB miss, fault carried to commit point

**Week 17: tests**
- [ ] Hand-written tests in `sw/tests/`: set up page tables, enable paging, run in U-mode, trigger and handle each fault type
- [ ] `riscv-tests` `rv32si-p-*` and the virtual-memory (`-v-`) variants
- [ ] `riscv-dv` random tests with MMU enabled (optional but strong)
- [ ] Spike diff clean with paging on

**Exit criteria**
- [ ] All S-mode and VM tests pass; Spike diff clean with paging enabled

**Common bugs to expect**
- Stale TLB entry after `sfence.vma` or `satp` change
- Superpage misalignment check missing
- PTW reading through the D-cache with wrong coherence
- Fault on fetch reported with wrong `stval` (faulting address vs PC)
- Instruction fetched in old mode right after `sret`

**Interview questions**
- Walk me through a TLB miss from fetch to the instruction executing.
- What does `sfence.vma` do in your hardware?
- Why delegate traps to S-mode?
- How do you handle A/D bits, and why that choice?

---

### PHASE 5: xv6 bring-up (Weeks 18–21, Mar)

**Goal:** a real Unix-like OS running on your own core and your own MMU.

**Prerequisites to check before starting**
- [ ] Read the xv6-rv32 port's timer handling. Older xv6 uses an M-mode timer handler that forwards to S-mode; newer versions use the Sstc extension (`stimecmp`). Implement whichever the port needs, or patch it
- [ ] xv6 needs a PLIC for UART interrupts. Build a minimal PLIC (one source), or patch xv6 to poll the UART. Record the choice in DESIGN.md
- [ ] xv6 in QEMU uses a virtio disk. Replace it with a RAM disk (filesystem image preloaded into RAM)

**Week 18: boot to first output**
- [ ] Adapt xv6 memory map, UART driver and boot path
- [ ] Get the first `printf` from the kernel

**Week 19: interrupts and processes**
- [ ] Timer interrupts → scheduler runs
- [ ] First user process (`init`) starts; first syscall works

**Week 20: shell**
- [ ] Boots to `$` prompt; `ls`, `echo hello | wc`, `cat README`
- [ ] Spike diff on the boot sequence (long run; checkpoint and compare in chunks if needed)

**Week 21: `usertests`**
- [ ] Run `usertests`, fix failures one by one (log every one in BUGLOG)
- [ ] Record the **2-minute demo**: boot → shell → commands → `usertests` ALL TESTS PASSED

**Exit criteria**
- [ ] xv6 shell works; `usertests` passes in full; demo video recorded

**⭐ CHECKPOINT B (end of March):** the headline result. Update README, resume and LinkedIn.

**Interview questions**
- What did xv6 need from your hardware that the tests didn't catch?
- Hardest bug during bring-up, and how you found it?
- How does a syscall flow from user code through your trap unit and back?

---

### PHASE 6: Performance (Weeks 22–25, Apr)

**Goal:** make it faster, and prove each improvement with numbers.

**Week 22: baseline**
- [ ] Full stall-reason counters (load-use, branch flush, I-miss, D-miss, TLB miss, mul/div)
- [ ] Baseline numbers on CoreMark and xv6 workloads

**Week 23: caches (you write)**
- [ ] I-cache: direct-mapped, e.g. 4 KB, 16–32 B lines
- [ ] D-cache: direct-mapped, write-back or write-through (record the choice), stalls on miss
- [ ] Add memory latency to the RAM model so caches actually matter
- [ ] `fence.i` now invalidates the I-cache

**Week 24: branch prediction**
- [ ] BTB + 2-bit counters (bimodal); optionally gshare
- [ ] Move to a cheaper misprediction path

**Week 25: results**
- [ ] Before/after table for each feature: CPI, CoreMark/MHz, hit rates, TLB miss rate, mispredict rate
- [ ] Charts into `docs/img/`; analysis into DESIGN.md

**Exit criteria**
- [ ] Results table with per-feature speedup, all tests still passing

**Interview questions**
- Why direct-mapped? What would you change with more area?
- Write-back vs write-through: what did you pick and why?
- What's the speedup from each feature, and does it match what you expected?

---

### PHASE 7: Research and write-up (Weeks 26–30, May)

**Option A (default): LLM-based hardware debugging**
- [ ] Clean and categorize BUGLOG (40+ bugs)
- [ ] For each bug: recreate the buggy commit, give an LLM the failing test + diff + waveform excerpt, measure whether it localizes the bug
- [ ] Compare against your own logged debug time
- [ ] Analyze which bug categories LLMs handle well or badly

**Option B (optional): control-flow integrity**
- [ ] Implement Zicfiss/Zicfilp; measure area/performance cost and xv6 changes

**Write-up**
- [ ] 4–6 page paper → arXiv; target CARRV or a RISC-V Summit poster
- [ ] Polish README: block diagram, features, results table, reproduce steps, credits
- [ ] DESIGN.md as a 4–6 page design document

**Exit criteria**
- [ ] Paper draft done; repo, README and demo polished

---

### PHASE 8: Stretch goals (June onward, any order)

- [ ] **FPGA:** open-source flow (Yosys + nextpnr) on a Gowin or ECP5 board; xv6 over a serial cable; report Fmax and LUT use
- [ ] **No-MMU Linux:** prebuilt image (e.g. from mini-rv32ima)
- [ ] **Dual-issue:** convert the pipeline; xv6 + CoreMark as regression
- [ ] **Formal:** RVFI port + riscv-formal checks

---

## 6. Timeline at a glance

| Phase | Weeks | Month | Headline output |
|---|---|---|---|
| 0 Setup | 1 | late Oct | xv6 in QEMU, toolchain works |
| 1 Single-cycle | 2–4 | Nov | rv32ui passes, CI green |
| 2 Pipeline | 5–8 | Dec | 5-stage, CPI measured |
| 3 M-mode system | 9–12 | Jan | FreeRTOS + CoreMark ⭐ A |
| 4 S/U + MMU | 13–17 | Feb–Mar | Paging works |
| 5 xv6 | 18–21 | Mar | xv6 + usertests ⭐ B |
| 6 Performance | 22–25 | Apr | Caches, BP, results |
| 7 Research | 26–30 | May | Paper draft |
| 8 Stretch | 31+ | Jun+ | FPGA, Linux, dual-issue |

**If you fall behind:** cut in this order: Phase 8, Phase 7 Option B, branch predictor, D-cache. **Never cut** the verification work or the bug log.

---

## 7. Weekly rhythm

| Session | Length | Focus |
|---|---|---|
| Build 1 | 3 hrs | Current phase RTL |
| Build 2 | 3 hrs | Current phase RTL |
| Test/debug | 3 hrs | Run regression, debug, log bugs same day |
| Reading | 1–2 hrs | Spec sections, xv6 book, one reference core for the next phase |

**End-of-week checklist**
- [ ] Regression green
- [ ] BUGLOG updated
- [ ] PLAN.md boxes ticked + Progress Log line
- [ ] Pushed to GitHub

---

## 8. Deliverables

1. GitHub repo: block diagram, README, results table, reproduction steps, green CI badge
2. 2-minute demo video: xv6 boots on your core and `usertests` passes
3. Design document (4–6 pages)
4. Research paper draft or poster on the bug dataset
5. Resume line with real numbers:

> *Designed a 5-stage pipelined RV32IMA processor in SystemVerilog with M/S/U privilege modes, Sv32 MMU (split TLBs, hardware page-table walker) and I/D caches; boots xv6 and passes its full test suite; verified against Spike and RISC-V architectural tests in CI; X CoreMark/MHz. Built a dataset of N real design bugs to evaluate LLM-based hardware debugging.*

---

## 9. Design Decisions

| # | Decision | Options considered | Choice | Why | Date |
|---|---|---|---|---|---|
| D1 | Memory map | Custom vs QEMU `virt` | QEMU `virt` | Fewer xv6 changes | |
| D2 | Branch resolution stage | ID vs EX | | | |
| D3 | Divider | Radix-2 multi-cycle vs faster | | | |
| D4 | A/D bit handling | Hardware update vs fault | | | |
| D5 | xv6 UART interrupts | Minimal PLIC vs polling patch | | | |
| D6 | xv6 timer | M-mode forwarding vs Sstc | | | |
| D7 | D-cache write policy | Write-back vs write-through | | | |

## 10. Open Questions

- [x] Does the Homebrew tap's toolchain support rv32 multilib on Apple Silicon, or do I need xPack? **Tap works (GCC 16.1.0). Bare-metal rv32ima is fine; newlib has rv32im/ilp32 but no rv32ima multilib, so libc-linked code (CoreMark, FreeRTOS) links against rv32im. No xPack needed.**
- [ ] Which xv6-rv32 port fits best (michaelengel vs r1809 vs x653 FPGA version)?
- [ ] How to align Spike and my core on interrupt timing for the diff?

## 11. Progress Log

| Date | Phase | What got done | Next |
|---|---|---|---|
| | 0 | Plan created | Install toolchain |
| 2026-10-16 | 0 | Repo layout + docs, pushed to GitHub. Installed Verilator 5.052 (needed Command Line Tools update to clang 21), QEMU 11.1.2, riscv-gnu-toolchain GCC 16.1.0 + Spike (tap), Surfer 0.7.0. RV32 test ran in Spike with commit log. xv6-rv32 booted in QEMU, `usertests` ALL TESTS PASSED after two xv6 patches: PMP setup in `start.c` (new QEMU enforces PMP) and missing `flags` field in 32-bit `struct proghdr` (`elf.h`). Build needs `TOOLPREFIX=riscv64-unknown-elf-`, rv32 `-march/-mabi`, `ld -m elf32lriscv`, and two `-Wno-error` flags for GCC 16. | crt0.S + linker script, hello-world in Spike, top-level Makefile |
| 2026-10-16 | 0 | `crt0.S`, `link.ld` (RAM at 0x8000_0000, tohost section), 16550 UART driver, `hello.c`, `scripts/bin2hex.py`, top-level Makefile (`sw`, `spike`, `sim` stub, `test`, `clean`). Hello prints over UART in Spike; `make test` PASS. Spike's map matches QEMU virt (UART 0x1000_0000, CLINT 0x0200_0000, PLIC 0x0C00_0000). Commit-log sample in `docs/samples/`. | Phase 0 reading (Unpriv Ch. 1–2); Phase 1: `regfile.sv` + its testbench |
