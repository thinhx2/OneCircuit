;
; ***********************************
; * (Add program task here)         *
; * (Add AVR type and version here) *
; * (C)2019 by Gerhard Schmidt      *
; ***********************************
;
.nolist
.include "tn13adef.inc" ; Define device ATtiny13A
.list
;
; **********************************
;        H A R D W A R E
; **********************************
;
; (F2 adds ASCII pin-out for device here)
;
; **********************************
;  P O R T S   A N D   P I N S
; **********************************
;
; (Add symbols for all ports and port pins with ".equ" here)
; (e.g. .equ pDirD = DDRB ; Define a direction port
;  or
;  .equ bMyPinO = PORTB0 ; Define an output pin)
;
; **********************************
;   A D J U S T A B L E   C O N S T
; **********************************
;
; (Add all user adjustable constants here, e.g.)
; .equ clock=1200000 ; Define the clock frequency
;
; **********************************
;  F I X  &  D E R I V.  C O N S T
; **********************************
;
  .equ SLL = 10
  .equ SLH = 40
  .equ SHL = 150
  .equ SHH = 220
  .equ FLL = 100
  .equ FLH = 140
  .equ FHL = 180
  .equ FHH = 220
  .equ seed = 0x29
  .equ xori = 0x8B
;
; **********************************
;       R E G I S T E R S
; **********************************
;
; free: R0 to R14
.def rSreg = R15 ; Save/Restore status port

.def SL = r0
.def SH = r1
.def FL = r2
.def FH = r3
.def gen1 = R16 ; Define multipurpose register
.def math1 = r17
.def math2 = r18
.def sramp = r19
.def framp = r20
.def sstatus = r21
.def fstatus = r22
.def randnum = r23
; free: R17 to R29
; used: R31:R30 = Z for ...
;
; **********************************
;           S R A M
; **********************************
;
.dseg
.org SRAM_START
; (Add labels for SRAM locations here, e.g.
; sLabel1:
;   .byte 16 ; Reserve 16 bytes)
;
; **********************************
;         C O D E
; **********************************
;
.cseg
.org 000000
;
; **********************************
; R E S E T  &  I N T - V E C T O R S
; **********************************
rjmp Main ; Reset vector
reti ; INT0
reti ; PCI0
reti ; OVF0
reti ; ERDY
reti ; ACI
reti ; OC0A
reti ; OC0B
reti ; WDT
reti ; ADCC
;
; **********************************
;  I N T - S E R V I C E   R O U T .
; **********************************
;
; (Add all interrupt service routines here)
;
; **********************************
;  M A I N   P R O G R A M   I N I T
; **********************************
;
Main:
ldi gen1,Low(RAMEND)
out SPL,gen1 ; Init LSB stack pointer

  ldi randnum, seed

; start conditions for slow and fast ramps

  rcall GenSlowLow
  rcall GenSlowHigh
  rcall GenFastLow
  rcall GenFastHigh

  ldi sstatus, 1 ; rising
  ldi fstatus, 1 ; rising
  mov sramp, r0
  mov framp, r1

  ldi gen1, 0b00000011
  out DDRB, gen1

  ldi gen1, 0b00111100
  out PORTB, gen1

; hardware pwm on channel A, B
; COMO0A1(1), COMO0A0(0), COMO0B1(1), COMO0B0(0),
; WGM01(1), WGM00(1)
  ldi gen1, 0b10100011
  out TCCR0A, gen1

; hardware pwm on channel B no prescaler
; CS00 (1)
  ldi gen1, 0b00000001
  out TCCR0B, gen1


; ...
sei ; Enable interrupts
;
; **********************************
;    P R O G R A M   L O O P
; **********************************
;
Loop:

  out OCR0A, sramp
  out OCR0B, framp

SlowCheck:

CheckSlowRising:
  ; if rising
  cpi sstatus, 1
  brcs CheckSlowFalling

  ;rise
  subi sramp, -1

  ;at SH?
  cp sramp, SH
  brcs FinishedSlow

  rcall GenSlowLow
  ldi sstatus, 0

CheckSlowFalling:

  ;fall
  subi sramp, 1

  ;at SL?
  cp sramp, SL
  brcc FinishedSlow

  rcall GenSlowHigh
  ldi sstatus, 1

FinishedSlow:

FastCheck:

CheckFastRising:
  ; if rising
  cpi fstatus, 1
  brcs CheckFastFalling

  ;rise
  subi framp, -2

  ;at FH?
  cp framp, FH
  brcs FinishedFast

  rcall GenFastLow
  ldi fstatus, 0

CheckFastFalling:

  ;fall
  subi framp, 2

  ;at FL?
  cp framp, FL
  brcc FinishedFast

  rcall GenFastHigh
  ldi fstatus, 1

FinishedFast:

rcall waitms

rjmp Loop
;

rollarandom:

; high in math1, low in math2, return in r16
  lsl randnum
  brcc maderand
  ldi gen1, xori
  eor randnum, gen1

  maderand:

  checklow:
  cp math1, randnum
  brcc rollarandom

  checkhigh:
  cp math2, randnum
  brcs rollarandom

  mov gen1, randnum

  ret

GenSlowLow:

  ldi math1, SLL
  ldi math2, SLH
  rcall rollarandom
  mov SL, r16

  ret

GenSlowHigh:

  ldi math1, SHL
  ldi math2, SHH
  rcall rollarandom
  mov SH, r16

  ret

GenFastLow:

  ldi math1, FLL
  ldi math2, FLH
  rcall rollarandom
  mov FL, r16

  ret

GenFastHigh:

  ldi math1, FHL
  ldi math2, FHH
  rcall rollarandom
  mov FH, r16

  ret

waitms:

; Generated by delay loop calculator
; at http://www.bretmulvey.com/avrdelay.html
;
; Delay 2 048 cycles
; 16ms at 0.128 MHz

    ldi  math1, 3
    ldi  math2, 140
L1: dec  math2
    brne L1
    dec  math1
    brne L1
    nop

  ret

; End of source code

