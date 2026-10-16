#include "uart.h"

int main(void)
{
    uart_puts("Hello from RV32!\n");

    /* A little arithmetic so the commit log shows the M extension at work.
       volatile stops the compiler from computing 6 * 7 at compile time. */
    volatile uint32_t a = 6, b = 7;
    uart_puts("6 * 7 = ");
    uart_puthex(a * b);
    uart_puts("\n");

    return 0;
}
