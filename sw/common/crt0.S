/*
 * crt0.S: first code to run after reset.
 *
 *   1. set up gp and sp
 *   2. point mtvec at a trap handler so a stray exception ends the run
 *   3. zero .bss
 *   4. call main()
 *   5. report main's return value through tohost and stop
 */

  .section .text.init, "ax"
  .globl _start
_start:
  /* gp must be set without linker relaxation, or the linker would
     rewrite this la into a gp-relative access before gp is valid. */
  .option push
  .option norelax
  la    gp, __global_pointer$
  .option pop

  la    sp, __stack_top

  la    t0, trap_handler
  csrw  mtvec, t0

  /* Zero .bss one word at a time. */
  la    t0, __bss_start
  la    t1, __bss_end
1:
  bgeu  t0, t1, 2f
  sw    zero, 0(t0)
  addi  t0, t0, 4
  j     1b
2:

  call  main
  /* main's return value is already in a0. Fall through to exit. */

/*
 * void exit(int code)
 *
 * Writes (code << 1) | 1 to tohost. Bit 0 set means "program finished";
 * the remaining bits are the exit code, so 0 = pass and anything else = fail.
 */
  .globl exit
exit:
  slli  a0, a0, 1
  ori   a0, a0, 1
  la    t0, tohost
  sw    a0, 0(t0)
  sw    zero, 4(t0)
3:
  j     3b              /* Wait here until the host stops the simulation. */

/*
 * Any unexpected trap (illegal instruction, misaligned access, ...) ends
 * the run with exit code 1337 so it can't hang or pass silently.
 */
  .align 2
trap_handler:
  li    a0, 1337
  j     exit

/* tohost/fromhost: 64-bit words watched by Spike's HTIF and the harness. */
  .section .tohost, "aw", @progbits
  .align 6
  .globl tohost
tohost:   .dword 0
  .align 6
  .globl fromhost
fromhost: .dword 0
