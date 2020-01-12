.nolist
.include "tn13adef.inc" ; Define device ATtiny13A
.list
.dseg
.org SRAM_START
.cseg
.org 000000
rjmp Main ; Reset vector

Main:
  ldi r16, 0b00001000
  out DDRB, r16
 	sei ; Enable interrupts

Loop:

  in r16, portb
  ldi r17, 0b00001000
  eor r16, r17
  out portb, r16
  rcall delayme
	rjmp loop

delayme:

    ldi  r18, 7
    ldi  r19, 23
    ldi  r20, 107
L1: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1
    nop

