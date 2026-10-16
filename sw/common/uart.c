#include "uart.h"

/* 16550 register offsets (one byte each, reg-shift 0). */
#define UART_THR 0  /* Transmit holding register (write) */
#define UART_LSR 5  /* Line status register (read)       */

#define LSR_THRE (1u << 5)  /* Transmit holding register empty */

/* volatile: every access must really reach the device, never be cached
   in a register or optimized away by the compiler. */
static volatile uint8_t *const uart = (volatile uint8_t *)UART_BASE;

void uart_putc(char c)
{
    while ((uart[UART_LSR] & LSR_THRE) == 0)
        ;
    uart[UART_THR] = (uint8_t)c;
}

void uart_puts(const char *s)
{
    while (*s) {
        if (*s == '\n')
            uart_putc('\r');
        uart_putc(*s++);
    }
}

void uart_puthex(uint32_t value)
{
    static const char digits[] = "0123456789abcdef";

    uart_puts("0x");
    for (int shift = 28; shift >= 0; shift -= 4)
        uart_putc(digits[(value >> shift) & 0xf]);
}
