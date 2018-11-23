	AREA maskmov, CODE, READWRITE
	EXPORT get_next_pos
	EXPORT reduce_update_period
	
MASK_FOR_UPDATE0  DCD 0x0   ; 00 0000 0000 - 0 updates per second
MASK_FOR_UPDATE1  DCD 0x200 ; 10 0000 0000 - 1 updates per second
MASK_FOR_UPDATE2  DCD 0x210 ; 10 0001 0000 - 2 updates per second
MASK_FOR_UPDATE3  DCD 0x248 ; 10 0100 1000 - 3 updates per second
;MASK_FOR_UPDATE4  DCD 0x292 ; 10 1001 0010 - 4 updates per second
;MASK_FOR_UPDATE5  DCD 0x266 ; 10 1010 1010 - 5 updates per second
;MASK_FOR_UPDATE6  DCD 0x2B5 ; 10 1011 0101 - 6 updates per second
;MASK_FOR_UPDATE7  DCD 0x356 ; 11 0101 0110 - 7 updates per second
;MASK_FOR_UPDATE8  DCD 0x3BD ; 11 1011 1110 - 8 updates per second
;MASK_FOR_UPDATE9  DCD 0x3EF ; 11 1110 1111 - 9 updates per second
;MASK_FOR_UPDATE10 DCD 0x3FF ; 11 1111 1111 - 10 updates per second

; getting the next position in the direction moved. 
;ro = x, r1 = y, r2 = dir. 
get_next_pos
	CMP r2, #0 ; is it up?
	BNE RIGHTDIR_CHECK
	SUB r1, r1, #1
	B next_square_EXIT
RIGHTDIR_CHECK
	CMP r2, #1 ; is it right?
	BNE DOWNDIR_CHECK
	ADD r0, r0, #1
	B next_square_EXIT
DOWNDIR_CHECK
	CMP r2, #2 ; is it down?
	BNE LEFTDIR_CHECK
	ADD r1, r1, #1
	B next_square_EXIT
LEFTDIR_CHECK
	CMP r2, #3 ; is it left?
	BNE next_square_EXIT
	SUB r0, r0, #1
	
next_square_EXIT
	BX lr

; Passing the 10-bit update mask in r0. r0 gets the updated mask as a returned value. This function is adding 1 update per second
reduce_update_period
	STMFD SP!, {lr,r1-r3}
	
	; Determining updates per second and place it in r1
	MOV r2, #0 ; looping through 0-9
	MOV r1, #0 ; starting at 0 updates per second
	MOV r3, r0 
LOOP_of_update_period
	LSR r3, r2 ; putting bit to analyze in lsb
	AND r3, r3, #1 
	ADD r1, r1, r3 ; As r3 is either 0 or 1, so we are able to add it
	MOV r3, r0 ; restore value in r0  to r3
	ADD r2, r2, #1 
	CMP r2, #10
	BLT LOOP_of_update_period
	
	; Adding 1 to updates per sec but making sure that it is less than 10
	ADD r1, r1, #1
	CMP r1, #10
	BLE PERIOD_IN_RANGE
	MOV r1, #10
PERIOD_IN_RANGE

	; Loading the new update mask and setting it
	LSL r1, #2 ; left shifting 2( mul by 4) to get into the word offset
	LDR r2, =MASK_FOR_UPDATE0
	LDR r0, [r2,r1]
	
	LDMFD SP!, {lr,r1-r3}
	BX lr
	
	END