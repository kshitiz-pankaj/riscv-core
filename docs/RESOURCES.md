# Resources

> Use these links when you need to look something up. Check the spec before trusting memory. Prefer the official specs (section A) as ground truth.

## A. Specifications (ground truth)
| Resource | Use for | Phase |
|---|---|---|
| [RISC-V ISA Manual (GitHub)](https://github.com/riscv/riscv-isa-manual) | Unprivileged spec (RV32I, M, A, Zicsr, Zifencei) and Privileged spec (traps, CSRs, Sv32). Use the latest release PDFs | All |
| [RISC-V Ratified Specifications](https://riscv.org/specifications/ratified/) | Official page for every ratified extension (Sstc, Zicfiss/Zicfilp, etc.) | 3–7 |

## B. Learning material
| Resource | Use for | Phase |
|---|---|---|
| *Digital Design and Computer Architecture: RISC-V Edition* (Harris & Harris), Ch. 6–7 | Single-cycle, multicycle and pipelined RTL | 1–2 |
| *Computer Organization and Design: RISC-V Edition* (Patterson & Hennessy), Ch. 4 | Pipelining and hazards | 1–2 |
| [MIT 6.1810 Operating System Engineering](https://pdos.csail.mit.edu/6.1810/) | xv6 book and labs: traps, page tables, scheduling | 4–5 |
| [One Student One Chip (ysyx)](https://ysyx.org/en) | Staged, difftest-first method for building a processor up to running an OS | 1–5 |

## C. Tools (all run on a Mac)
| Tool | Use for |
|---|---|
| [Homebrew RISC-V tap](https://github.com/riscv-software-src/homebrew-riscv) | GCC toolchain plus Spike |
| [xPack RISC-V GCC](https://xpack-dev-tools.github.io/riscv-none-elf-gcc-xpack/) | Fallback toolchain with native Apple Silicon builds and RV32 support |
| [Spike](https://github.com/riscv-software-src/riscv-isa-sim) | Reference simulator to diff against |
| [Verilator](https://www.veripool.org/verilator/) | Fast RTL simulation (primary) |
| [Icarus Verilog](https://github.com/steveicarus/iverilog) | Quick RTL unit tests |
| [Surfer](https://surfer-project.org/) | Waveform viewer |
| [Konata](https://github.com/shioyadan/Konata) | Pipeline visualizer, good for demos |
| [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build) | Yosys, nextpnr, SymbiYosys: FPGA flow and formal |
| [QEMU](https://www.qemu.org/) | Boot xv6 before your hardware can |

## D. Tests and benchmarks
| Resource | Use for | Phase |
|---|---|---|
| [riscv-tests](https://github.com/riscv-software-src/riscv-tests) | Per-instruction unit tests (rv32ui, um, ua, mi, si, and -v- variants) | 1–4 |
| [riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test) | Official compliance tests | 3–4 |
| [RISCOF](https://github.com/riscv-software-src/riscof) | Framework that runs riscv-arch-test against your core | 3–4 |
| [riscv-dv](https://github.com/chipsalliance/riscv-dv) | Random instruction generator, including MMU stress tests | 4 |
| [riscv-formal](https://github.com/YosysHQ/riscv-formal) ([docs](https://yosyshq.readthedocs.io/projects/riscv-formal)) | Formal verification through the RVFI interface | 8 |
| [CoreMark](https://github.com/eembc/coremark) | Standard performance benchmark | 3, 6 |
| [FreeRTOS Kernel](https://github.com/FreeRTOS/FreeRTOS-Kernel) | RISC-V port under `portable/GCC/RISC-V` | 3 |

## E. Reference cores (read to learn from, don't copy)
| Resource | Why it's useful |
|---|---|
| [ultraembedded/riscv](https://github.com/ultraembedded/riscv) | **Main reference.** Pipelined RV32 in Verilog with a basic MMU |
| [biRISC-V](https://github.com/ultraembedded/biriscv) | Dual-issue version of the same, for the stretch goal |
| [RVSoC paper](https://arxiv.org/abs/2002.03576) | Linux-capable RV32 system in Verilog; Sv32 page walker explained |
| [VSRV](https://www.vlsi.fi/en/vsrv.html) | Published architecture and design spec documents |
| [Raptor](https://github.com/Kingfish404/raptor-chip) | Modern verification setup to imitate (RISCOF, RVFI, difftest) |
| [KianV](https://github.com/splinedrive/kianRiscV) | Hobbyist path to Linux on small FPGA boards, with good notes |
| [SoomRV](https://github.com/mathis-s/SoomRV) | Advanced out-of-order core, for perspective only |
| [mini-rv32ima](https://github.com/cnlohr/mini-rv32ima) | Tiny emulator that boots no-MMU Linux; source of prebuilt images |

## F. xv6 for 32-bit RISC-V
| Resource | Notes |
|---|---|
| [michaelengel/xv6-rv32](https://github.com/michaelengel/xv6-rv32) | **Start here**; boots in QEMU |
| [r1809/xv6-rv32](https://gitlab.com/r1809/xv6-rv32) | Another RV32 port |
| [x653/xv6-riscv-fpga](https://gitlab.com/x653/xv6-riscv-fpga) | FPGA version without virtio; useful for the RAM-disk approach |
| [HackMD: porting xv6 to RV32](https://hackmd.io/@sysprog/BJPdjVCNJe) | Checklist of 32-bit pitfalls |

## G. Research papers and venues
| Resource | Use for |
|---|---|
| [CVA6-CFI (arXiv 2602.04991)](https://arxiv.org/abs/2602.04991) | Control-flow integrity in hardware (Phase 7 Option B) |
| [BluesFL (arXiv 2605.17290)](https://arxiv.org/abs/2605.17290) | LLM fault localization for processors (Option A) |
| [R3A (arXiv 2511.20090)](https://arxiv.org/abs/2511.20090) | LLM agents that repair RTL bugs (Option A) |
| [Spectre on RISC-V Silicon (CISPA)](https://cispa.de/de/research/publications/213214-spectre-on-risc-v-silicon-attacks-and-defenses-on-commercial-out-of-order-processors) | RISC-V security background |
| [CARRV workshop (SIGARCH)](https://www.sigarch.org/call-contributions/the-6th-workshop-on-computer-architecture-research-with-risc-v/) | Target venue; check SIGARCH for the current year's call |

## H. Reuse rules
- For resume-critical parts (hazard unit, trap unit, MMU, caches): study the design, close the reference, write your own.
- Infrastructure (testbench harnesses, Makefiles, linker scripts, xv6 driver ports) may be adapted.
- Credit everything in the README, e.g. "MMU structure informed by RVSoC; verification flow adapted from Raptor."
- Check each repo's license before copying any file.
