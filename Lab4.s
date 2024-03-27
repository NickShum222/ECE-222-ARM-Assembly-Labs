;*-------------------------------------------------------------------
;* Name:      lab_4_program.s
;* Purpose:   A sample style for lab-4
;* Term:    Winter 2013
;*-------------------------------------------------------------------
       THUMB                 ; Declare THUMB instruction set
       AREA  My_code, CODE, READONLY   ;
       EXPORT    __MAIN          ; Label __MAIN is used externally
                               EXPORT          EINT3_IRQHandler
       ENTRY

__MAIN

; The following lines are similar to previous labs.
; They just turn off all LEDs
       LDR     R10, =LED_BASE_ADR    ; R10 is a  pointer to the base address for the LEDs
       MOV     R3, #0xB0000000   ; Turn off three LEDs on port 1  
       STR     R3, [r10, #0x20]
       MOV     R3, #0x0000007C
       STR     R3, [R10, #0x40]  ; Turn off five LEDs on port 2

       MOV     R4,#0x00200000
       LDR     R5,=ISER0
       STR     R4,[R5] ; Enable the EINT3 interrupt

       MOV     R4, #0x00000400     ; Enable the falling edge interrupt for P2.10
       LDR     R5, =IO2IntEnf			; Load the address of the GPIO Interrupt Enable for port 2 Falling Edge
       STR     R4, [R5]


; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
       MOV     R11, #0xABCD    ; Init the random number generator with a non-zero number
LOOP    BL      RNG
       BL      SCALED_VALUE ;  This will scale the value to the range [50, 250]
       MOV     R10, #1 ; Sets the flag for the interrupt
       CMP     R10, #0 ; Checks if the interrupt has been called
       BEQ     DISPLAY_LOOP

FLASH  MOV     R3, #0xFF ; Turn on all LEDs
       BL      DISPLAY_NUM
       MOV     R0, #1 ; Delay for 0.1s
       BL      DELAY
       MOV     R3, #0 ; Turn off all LEDs
       BL      DISPLAY_NUM
       MOV     R0, #1 ; Delay for 0.1s
       BL      DELAY

       CMP     R10, #0 ; Checks if the interrupt has been called, if not, loop back to FLASH
       BNE     FLASH

DISPLAY_LOOP
       MOV     R3, R6 ; Display the Random Number 
       BL      DISPLAY_NUM 
       MOV     R0, #10 ; Delay for 1 second
       BL      DELAY
       SUBS    R6, #10 ; Decrement the random number by 10
       TST     R6, R6 ; Checks if the number is greater than 0
       BMI     LOOP ; If finish displaying the random number, loop back to the beginning
       MOV     R3, #0 ; Turn off all LEDs
       MOV     R0, #10
       BL      DELAY ; Delay for 1 second
       B     DISPLAY_LOOP ; Loop back to display the next random number

       
       
   ;
   ; Your main program can appear here
   ;
       
       
       
;*-------------------------------------------------------------------
; Subroutine RNG ... Generates a pseudo-Random Number in R11
;*-------------------------------------------------------------------
; R11 holds a random number as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program
; R11 can be read anywhere in the code but must only be written to by this subroutine
RNG       STMFD   R13!,{R1-R3, R14}   ; Random Number Generator
       AND     R1, R11, #0x8000
       AND     R2, R11, #0x2000
       LSL     R2, #2
       EOR     R3, R1, R2
       AND     R1, R11, #0x1000
       LSL     R1, #3
       EOR     R3, R3, R1
       AND     R1, R11, #0x0400
       LSL     R1, #5
       EOR     R3, R3, R1      ; The new bit to go into the LSB is present
       LSR     R3, #15
       LSL     R11, #1
       ORR     R11, R11, R3
       LDMFD   R13!,{R1-R3, R15}


; The formula we use is: scaled_value = (((Rn % 3) + 1) x 100) - 50
; return the scaled value in R6
; Modulo logic: 4/3 = 1, 1 x 3 = 3, 4 - 3 = 1, 4 % 3 = 1

SCALED_VALUE    PUSH {R1,R2,LR}
               MOV            R6,R11 ; copy randomly generated value into R6
               MOV            R2,#21 ; Multiplicand, divisor
               UDIV            R1,R6, R2 ; Divide Rn by 21, drop the remainder this will give us values between 0 and 20
               MUL            R1,R2
               SUB            R6,R1
               MOV            R2,#10 ; Multiply by 10 to give us the range [0, 200]
               MUL            R6,R2
               ADD            R6, #50 ; Add by 50 to shift the range up to [50, 250]
               
               POP {R1,R2,LR}
               BX             LR

;*-------------------------------------------------------------------
; Subroutine DELAY ... Causes a delay of 100ms * R0 times
;*-------------------------------------------------------------------
;     aim for better than 10% accuracy
; This subroutine delays R0 * 0.1s
; The formula used is: delay_value = Clock speed x Delay time / (#clock cycles)
;   Delay time = in units of 100ms = R0 * 100  
;   Clock speed = 4MHz
;   # clock cycles the delay takes = 3 (because 1 cycle for SUBS and 2 for BNE)
; We assume R0 has some random value
; For a 1 second delay, store #10 into R0

DELAY           STMFD       R13!,{R1-R5, R14} ;Push R2, LR to stack, Takes in R0, which can range between 20,000 to 100,000
                ;MOV           R1, #10 ; Divide R0 by 10 to get the amount of seconds we need
                MOV         R1, #100
                ; MOV32     R3,#4000000 ; CPU Clock Speed
                MOV32       R3,#4000    ; CPU Clock Speed
                MOV         R4,#3 ; Amount of cycles the delay takes
               
                MOV         R2,R0 ; Stores R0 into temp Register R2
                ; UDIV      R2,R1 ; divides number by 10
                MUL         R2, R1 ; multiply number by 100
               
                MUL         R2,R3 ; delay time x clock speed
                UDIV        R2,R4 ; divide by #clock cycles
               
               
DELAY_LOOP      SUBS        R2, #1 ; Loops to perform the delay
                BNE         DELAY_LOOP

exitDelay       LDMFD       R13!,{R1-R5, R15} ;Pop R2, PC from stack


DISPLAY_NUM   STMFD   R13!,{R1-R8, R14}
       
       ; Clear the LEDs
       LDR     R1,= FIO1CLR
       LDR     R2,= FIO2CLR
       MOV     R8,#0xFFFFFFFF
       STR     R8,[R1]
       STR     R8,[R2]

       ; Turn on the correct LEDs to display the number stored in R3
       LDR     R1,= FIO1SET
       LDR     R2,= FIO2SET
       
       
       MOV     R4,#0
       MOV     R5,#0
       MOV     R6,#0
       MOV     R7,#0
       
       MOV     R6,R3 ; Copy R3 value into R6
       RBIT    R7,R6 ; Reverse R6 and put into R7
       LSR     R7,#24 ; Shift R7 by 24 bits to the right to get the needed bits
       BFI     R4,R7,#28,#2 ; Insert bits 28 and 29 from R7 into R4
       LSR     R7,#2 ; Shift R7 right by 2
       BFI     R4,R7,#31,#1 ; Copy the first bit from R7 and put into bit 31 of R4
       LSR     R7,#1 ; shift right by 1 bit again
       BFI     R5,R7,#2,#5
     
       
       ; Write to FIO1SET and FIO2SET
       STR     R4,[R1]
       STR     R5,[R2]
       
; Usefull commaands:  RBIT (reverse bits), BFC (bit field clear), LSR & LSL to shift bits left and right, ORR & AND and EOR for bitwise operations

       LDMFD   R13!,{R1-R8, R15}

; The Interrupt Service Routine MUST be in the startup file for simulation
;   to work correctly.  Add it where there is the label "EINT3_IRQHandler
;
;*-------------------------------------------------------------------
; Interrupt Service Routine (ISR) for EINT3_IRQHandler
;*-------------------------------------------------------------------
; This ISR handles the interrupt triggered when the INT0 push-button is pressed
; with the assumption that the interrupt activation is done in the main program
EINT3_IRQHandler  
         STMFD     R13!,{R1, R2, LR}        ; Use this command if you need it  
         MOV       R10, #0 									; Clears the flag, tells the main program that this interrupt has been called
         LDR       R1, = IO2IntClr 					; Clears the interrupt at Pin 2.10

         MOV       R2, #0x400
         STR       R2, [R1] 
         LDMFD    R13!,{R1, R2, LR}        ; Use this command if you used STMFD (otherwise use BX LR)
         BX        LR            ; Return from the interrupt


;*-------------------------------------------------------------------
; Below is a list of useful registers with their respective memory addresses.
;*-------------------------------------------------------------------
LED_BASE_ADR  EQU   0x2009c000    ; Base address of the memory that controls the LEDs
PINSEL3     EQU   0x4002C00C    ; Pin Select Register 3 for P1[31:16]
PINSEL4     EQU   0x4002C010    ; Pin Select Register 4 for P2[15:0]
FIO1DIR     EQU   0x2009C020    ; Fast Input Output Direction Register for Port 1
FIO2DIR     EQU   0x2009C040    ; Fast Input Output Direction Register for Port 2
FIO1SET     EQU   0x2009C038    ; Fast Input Output Set Register for Port 1
FIO2SET     EQU   0x2009C058    ; Fast Input Output Set Register for Port 2
FIO1CLR     EQU   0x2009C03C    ; Fast Input Output Clear Register for Port 1
FIO2CLR     EQU   0x2009C05C    ; Fast Input Output Clear Register for Port 2
IO2IntEnf   EQU   0x400280B4    ; GPIO Interrupt Enable for port 2 Falling Edge
ISER0       EQU   0xE000E100    ; Interrupt Set-Enable Register 0
IO2IntClr   EQU   0x400280AC    ; GPIO Interrupt Clear for port 2

       ALIGN

       END 