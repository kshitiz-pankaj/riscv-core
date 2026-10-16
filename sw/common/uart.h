#ifndef UART_H
#define UART_H

#include <stdint.h>

/* 16550-compatible UART at the QEMU virt / Spike address. */
#define UART_BASE 0x10000000u

void uart_putc(char c);
void uart_puts(const char *s);
void uart_puthex(uint32_t value);

#endif
