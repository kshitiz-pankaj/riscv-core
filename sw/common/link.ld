/*
 * Linker script for bare-metal programs.
 *
 * Everything lives in RAM at 0x8000_0000 (QEMU virt / Spike layout).
 * The CPU starts at _start, which crt0.S places first in .text.init.
 */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 128M
}

STACK_SIZE = 16K;

SECTIONS
{
  /* Code. .text.init comes first so _start sits exactly at 0x8000_0000. */
  .text : {
    *(.text.init)
    *(.text .text.*)
  } > RAM

  /* Read-only data: string constants, lookup tables. */
  .rodata : ALIGN(4) {
    *(.rodata .rodata.*)
    *(.srodata .srodata.*)
  } > RAM

  /*
   * Host-communication words. A program ends by writing to tohost;
   * Spike and the simulation harness watch this address.
   * 64-byte aligned, as Spike's HTIF expects.
   */
  .tohost : ALIGN(64) {
    *(.tohost)
  } > RAM

  /* Initialized global variables. */
  .data : ALIGN(4) {
    *(.data .data.*)
    /* gp points 2 KB into small data so 12-bit offsets reach both ways. */
    __global_pointer$ = . + 0x800;
    *(.sdata .sdata.*)
  } > RAM

  /* Zero-initialized globals. crt0.S clears this range before main(). */
  .bss : ALIGN(4) {
    __bss_start = .;
    *(.sbss .sbss.*)
    *(.bss .bss.*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end = .;
  } > RAM

  /* Stack grows down from __stack_top. */
  .stack (NOLOAD) : ALIGN(16) {
    . += STACK_SIZE;
    __stack_top = .;
  } > RAM

  _end = .;
}
