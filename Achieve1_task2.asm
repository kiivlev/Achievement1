; Atmega8 AVR Assembler Program
; Implements two parallel timers with USART output
; Adjusted for minimal interval sum for correct execution

.include "m8def.inc"

; Constants
.equ F_CPU = 8000000            ; CPU frequency in Hz
.equ TIMER1_INTERVAL = 10000    ; Interval for Timer1 (in cycles)
.equ TIMER2_INTERVAL = 20000    ; Interval for Timer2 (in cycles)

.equ BAUD = 9600                ; Baud rate for USART
.equ UBRR_VALUE = F_CPU / 16 / BAUD - 1

.equ MAX_STR_LEN = 16           ; Maximum string length for TIMER_STR

; Define variables in SRAM
.dseg
.org 0x100
TIMER1_COUNTER: .byte 2         ; 16-bit counter for Timer1
TIMER2_COUNTER: .byte 2         ; 16-bit counter for Timer2
TIMER1_STR: .byte MAX_STR_LEN   ; String for Timer1
TIMER2_STR: .byte MAX_STR_LEN   ; String for Timer2

; Code section
.cseg
.org 0x00

; Reset vector
rjmp INIT

; Interrupt vectors
.org INT_TIMER1_COMPA
rjmp TIMER1_ISR

.org INT_TIMER2_COMPA
rjmp TIMER2_ISR

; Subroutines
USART_INIT:
    ldi r16, UBRR_VALUE
    out UBRRL, r16
    out UBRRH, r16
    ldi r16, (1 << TXEN) | (1 << RXEN)
    out UCSRB, r16
    ldi r16, (1 << URSEL) | (1 << UCSZ1) | (1 << UCSZ0)
    out UCSRC, r16
    ret

USART_SEND:
    ; Send a single character in r16
USART_WAIT:
    sbis UCSRA, UDRE
    rjmp USART_WAIT
    out UDR, r16
    ret

USART_SEND_STR:
    ; Send null-terminated string starting at Z
USART_STR_LOOP:
    lpm r16, Z+
    tst r16
    breq USART_STR_DONE
    rcall USART_SEND
    rjmp USART_STR_LOOP
USART_STR_DONE:
    ret

TIMER_INIT:
    ; Configure Timer1
    ldi r16, 0x00
    out TCCR1A, r16
    ldi r16, (1 << WGM12) | (1 << CS10)
    out TCCR1B, r16
    ldi r16, low(TIMER1_INTERVAL)
    out OCR1AL, r16
    ldi r16, high(TIMER1_INTERVAL)
    out OCR1AH, r16

    ; Configure Timer2
    ldi r16, 0x00
    out TCCR2, r16
    ldi r16, TIMER2_INTERVAL
    out OCR2, r16

    ; Enable interrupts
    sei
    ret

TIMER1_ISR:
    ldi ZH, high(TIMER1_STR)
    ldi ZL, low(TIMER1_STR)
    rcall USART_SEND_STR
    reti

TIMER2_ISR:
    ldi ZH, high(TIMER2_STR)
    ldi ZL, low(TIMER2_STR)
    rcall USART_SEND_STR
    reti

INIT:
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    ldi r16, 'p'
    sts TIMER1_STR, r16
    ldi r16, 'i'
    sts TIMER1_STR+1, r16
    ldi r16, 'n'
    sts TIMER1_STR+2, r16
    ldi r16, 'g'
    sts TIMER1_STR+3, r16
    ldi r16, '\r'
    sts TIMER1_STR+4, r16
    ldi r16, '\n'
    sts TIMER1_STR+5, r16
    ldi r16, 0x00
    sts TIMER1_STR+6, r16

    ldi r16, 'p'
    sts TIMER2_STR, r16
    ldi r16, 'o'
    sts TIMER2_STR+1, r16
    ldi r16, 'n'
    sts TIMER2_STR+2, r16
    ldi r16, 'g'
    sts TIMER2_STR+3, r16
    ldi r16, '\r'
    sts TIMER2_STR+4, r16
    ldi r16, '\n'
    sts TIMER2_STR+5, r16
    ldi r16, 0x00
    sts TIMER2_STR+6, r16

    rcall USART_INIT
    rcall TIMER_INIT

    ; Main loop
MAIN_LOOP:
    rjmp MAIN_LOOP
