; ECE-222 Lab ... Winter 2013 term 
; Lab 3 sample code 
				THUMB 		; Thumb instruction set 
                AREA 		My_code, CODE, READONLY
                EXPORT 		__MAIN
				ENTRY  
__MAIN

; The following lines are similar to Lab-1 but use a defined address to make it easier.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR		; R10 is a permenant pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports

				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [r10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2 
				

			
				
				;BL			DISPLAY_NUM
; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				;MOV			R11, #0xABCD		; Init the random number generator with a non-zero number
				
				
loop 			BL 			RandomNum ; Branch to RandomNum
				;BL			COUNTER
				
REFLEX			PUSH		{R0-R12,LR}
				BL			SCALED_VALUE ; Branch to SCALED_Value to return the scaled value
				
				MOV32		R2,#0 ; Initialize counter for reflex meeter
				LDR			R4,=FIO2PIN ; Get address of FIO2PIN 
				
				BL			DELAY ; Branch to delay to delay 2-10 seconds
				
				MOV			R3,#0x40 ; Display single LED P1.29
				BL			DISPLAY_NUM
				
				MOV			R5,#0x28 ; Timer for 0.1ms
POLL			SUBS		R5,#1 ; Decrement timer
				ADDEQ		R2,#1 ; Increment counter if above operation results in 0
				MOVEQ		R5,#0x28 ; Reset timer if above operation results in 0
				
				LDR			R6,[R4] ; Load value of FIO2PIN into R6 
				LSR			R6,#10 ; Move 10th bit to the lsb
				MOV			R8, #0 ; Put 0 in R8 
				BFI			R8, R6,#0,#1 ; Take lsb of R6 and put at lsb of R8 
				
				
				
				TEQ			R8,#0 ; Polls until the value of R8 is 1
				BNE			POLL
				MOV			R3,#0 ; Resets/Clears all the LEDS
				BL			DISPLAY_NUM
				
DISPLAY_COUNTER	MOV			R7,R2 ; Copies the reaction time value into R7
				MOV			R4,#4 ; Display all 4 8-bit values
DISPLAY_LOOP	AND			R3,R7,#0xFF ; Copies the 8 LSB of the reaction time and puts it in R3
				BL			DISPLAY_NUM ; Displays the 8 Bit number
				MOV			R0,#20000 ; Delays for 2s
				BL			DELAY; If greater than 0, then we still have bits we need to display
				LSR			R7,#8
				SUBS		R4,#1
				BNE			DISPLAY_LOOP 
				MOV			R3,#0 ; Clears/Resets the LED and delays for 5 seconds
				MOV			R0,#50000
				
				BL			DISPLAY_NUM
				BL			DELAY
				B			DISPLAY_COUNTER
				
				POP			{R0-R12,LR}
				
				B loop
				
				
				

COUNTER			PUSH		{R0-R12,LR}
				MOV32 		R3,#0 ; counter that counts from 0 to 255
				
COUNTER_LOOP	
				
				BL			DISPLAY_NUM ; display num
				MOV32		R1,#0x00020805 ; 100ms delay 

COUNTER_DELAY	
				SUBS		R1,#1 ; decrement 100ms delay
				BNE			COUNTER_DELAY
				
				ADD			R3,#1 ; increment counter 
				CMP			R3,#256 ; check if its 255 
				BLT			COUNTER_LOOP ; loop again if counter not at max value
				
				
				MOV			R3,#0 ; reset R3
				BL			DISPLAY_NUM ; display 0
				
				
				
				POP			{R0-R12,LR}
				BX 			LR
				

				
				
;
; Display the number in R3 onto the 8 LEDs
DISPLAY_NUM		STMFD		R13!,{R1-R8, R14}
				
				; Clear the LEDs
				LDR			R1,= FIO1CLR 
				LDR			R2,= FIO2CLR
				MOV			R8,#0xFFFFFFFF
				STR			R8,[R1]
				STR			R8,[R2]

				; Turn on the correct LEDs to display the number stored in R3
				LDR			R1,= FIO1SET
				LDR			R2,= FIO2SET
				
				
				MOV			R4,#0
				MOV			R5,#0
				MOV			R6,#0
				MOV			R7,#0
				
				MOV			R6,R3 ; Copy R3 value into R6
				RBIT		R7,R6 ; Reverse R6 and put into R7
				LSR			R7,#24 ; Shift R7 by 24 bits to the right to get the needed bits
				BFI			R4,R7,#28,#2 ; Insert bits 28 and 29 from R7 into R4 
				LSR			R7,#2 ; Shift R7 right by 2
				BFI			R4,R7,#31,#1 ; Copy the first bit from R7 and put into bit 31 of R4
				LSR			R7,#1 ; shift right by 1 bit again
				BFI			R5,R7,#2,#5 
			
				
				; Write to FIO1SET and FIO2SET
				STR			R4,[R1]
				STR			R5,[R2]
				
; Usefull commaands:  RBIT (reverse bits), BFC (bit field clear), LSR & LSL to shift bits left and right, ORR & AND and EOR for bitwise operations

				LDMFD		R13!,{R1-R8, R15}
				

;
; R11 holds a 16-bit random number via a pseudo-random sequence as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 holds a non-zero 16-bit number.  If a zero is fed in the pseudo-random sequence will stay stuck at 0
; Take as many bits of R11 as you need.  If you take the lowest 4 bits then you get a number between 1 and 15.
;   If you take bits 5..1 you'll get a number between 0 and 15 (assuming you right shift by 1 bit).
;
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program OR ELSE!
; R11 can be read anywhere in the code but must only be written to by this subroutine
RandomNum		STMFD		R13!,{R1, R2, R3, R14}

				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1		; the new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				
				LDMFD		R13!,{R1, R2, R3, R15}

;
;		Delay 0.1ms (100us) * R0 times
; 		aim for better than 10% accuracy
;               The formula to determine the number of loop cycles is equal to Clock speed x Delay time / (#clock cycles)
;               where clock speed = 4MHz and if you use the BNE or other conditional branch command, the #clock cycles =
;               2 if you take the branch, and 1 if you don't.


DELAY			STMFD		R13!,{R1-R5, R14} ;Push R2, LR to stack, Takes in R0, which can range between 20,000 to 100,000
				MOV			R1, #10000 ; Divide R0 by 10,000 to get the amount of seconds we need
				MOV32		R3,#4000000	; CPU Clock Speed
				MOV			R4,#3 ; Amount of cycles the delay takes
				
				MOV			R2,R0 ; Stores R0 into temp Register R2
				UDIV		R2,R1 ; divides number by 10000
				
				MUL			R2,R3 ; delay time x clock speed 
				UDIV		R2,R4 ; divide by #clock cycles
				
				
DELAY_LOOP		SUBS 		R2, #1 ; Loops to perform the delay
				BNE			DELAY_LOOP
				
		; code to generate a delay of 0.1mS * R0 times
		;
exitDelay		LDMFD		R13!,{R1-R5, R15} ;Pop R2, PC from stack

SCALED_VALUE	PUSH {R1,R2,LR}
; Scales the value by using the provided formula: Scaled_Value = ((RN mod 9) + 2) * 10000
				MOV			R0,R11 
				MOV			R2,#9 ; Multiplicand, divisor
				UDIV		R1,R0, R2
				MUL			R1,R2
				SUB			R0,R1
				ADD			R0,#2
				MOV			R2,#10000
				MUL			R0,R2
				
				POP {R1,R2,LR}
				BX 			LR
				

LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002c00c 		; Address of Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002c010 		; Address of Pin Select Register 4 for P2[15:0]
FIO1SET			EQU		0x2009C038
FIO2SET			EQU		0x2009C058	
FIO1CLR			EQU 	0x2009C03C
FIO2CLR			EQU 	0x2009C05C
FIO2PIN			EQU		0x2009C054
;	Usefull GPIO Registers
;	FIODIR  - register to set individual pins as input or output	
;	FIOPIN  - register to read and write pins
;	FIOSET  - register to set I/O pins to 1 by writing a 1
;	FIOCLR  - register to clr I/O pins to 0 by writing a 1
;	1. For 8 bits, the maximum value is 0.0255s or 25.5ms
; 		For 16 bits, the maximum value is 6.5536s
;		For 24 bits, the maximum value is 1677.72s or 27.96 minutes
; 		For 32 bits, the maximum value is 11930.46 Hours
; 	2. Considering the average human reaction time is 250ms, the best size is 16 bits. 
;   3. Given a random value between 1 to 65536, we scale the value to be between 20000 and 100000. This is done 
; 	   using the formula: Scaled_Value = ((RN mod 9) + 2) * 10000. RN mod 9 ranges from 0 to 8 so that means after adding 2, 
; 		we will get values between 2 and 10. Multiplying values between 2 and 10 by 10000 gives values between 20000 and 100000. 
; 		our delay is configured so that it takes a value in R0 where the value represents the delay we want in seconds. so when we pass the scaled value into delay, we divide it by 10000 to get the amount of seconds we need
;			
				ALIGN 

				END 

