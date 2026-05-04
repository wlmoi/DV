# UART learning notes

- UART is asynchronous serial communication using separate TX and RX lines.
- A frame typically includes a start bit (0), data bits LSB-first, optional parity, and stop bit (1).
- 8N1 means 8 data bits, no parity, 1 stop bit.
- Baud rate is derived from the system clock using a divider or counter.
- Sampling is often done at mid-bit to reduce jitter sensitivity.
- Common errors include framing error (missing stop bit) and parity error.
