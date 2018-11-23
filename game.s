	AREA game, CODE, READWRITE
	EXPORT start_the_game
	EXPORT check_paused_state
	EXPORT check_for_game_complete
	EXPORT see_collisions
		
	IMPORT PAUSED
	IMPORT ENDPROG
	IMPORT TIMER1
	IMPORT LIVES_PLAYER
	IMPORT output_string
	IMPORT illuminate_RGB_LED
	IMPORT draw_the_board
	IMPORT timer1_reset
	IMPORT timer1_pause
	
	IMPORT Y_POS_PLAYER
	IMPORT X_POS_BULLET
	IMPORT Y_POS_BULLET
	IMPORT ENEMY1
		
	IMPORT timer1_resume
	IMPORT SCORE
	IMPORT UPDATE_ENEMY2
	IMPORT LIVES_PLAYER
	IMPORT X_POS_PLAYER
	IMPORT IS_BULLET_FIRED
	IMPORT create_player
	IMPORT delay
	IMPORT available_character
	IMPORT UPDATE_PLAYER
	IMPORT LEVEL
	IMPORT display_digit_on_7_seg	

pause_prompt = "\n\rGame is Paused. Take a break bro\n\r",0 
	ALIGN

TWO_MIN_DURATION EQU 2211840000 

; initializes all variables
start_the_game
	STMFD SP!, {lr,r0-r2}
	
	; Setting score to 0
	
	
	LDR r0, =SCORE
	MOV r1, #0
	STR r1, [r0]
	
	; Setting player lives to 4
	LDR r0, =LIVES_PLAYER
	MOV r1, #0xF
	STR r1, [r0]
	
	; pause flag reset
	LDR r0, =PAUSED
	MOV r1, #0
	STR r1, [r0]
	
	; enemy update speeds resetted
	LDR r0, =UPDATE_ENEMY2
	MOV r1, #0x210
	STR r1, [r0]
	STR r1, [r0,#4]
	LDR r1, =0x210
	STR r1, [r0,#8]
    LDR r1,=0x210
	STR r1, [r0,#12]
	
	; player update period resetted
	LDR r1, =UPDATE_PLAYER
	MOV r0, #0x210
	STR r0, [r1]
	
	; level reset to 1
	LDR r1, =LEVEL
	MOV r0, #1
	STR r0, [r1]

	; timer of game again reset
	BL timer1_reset
	
	LDMFD SP!, {lr,r0-r2}
	BX lr

; does stuff in paused state
check_paused_state
	STMFD sp!, {lr,r0,r1,r4}

	; See if we are paused
	LDR r0, =PAUSED
	LDR r1, [r0]
	CMP r1, #0
	BEQ check_paused_state_EXIT
	
	; Pause the game timer
	BL timer1_pause
	
	; Indicate that we are paused
	BL draw_the_board
	LDR r4, =pause_prompt
	BL output_string
	MOV r0, #3
	BL illuminate_RGB_LED
	
	; keep looping until unpaused
GAME_PAUSE_LOOP
	LDR r0, =PAUSED
	LDR r1, [r0]
	CMP r1, #0
	BNE GAME_PAUSE_LOOP
	
	; Clearing the serial buffer
GAME_CLEAR_LOOP
	BL available_character
	CMP r0, #0
	BNE GAME_CLEAR_LOOP
	
	; Resuming the timer
	BL timer1_resume
	
check_paused_state_EXIT 
	LDMFD sp!, {lr,r0,r1,r4}
	BX lr
	

; is the game complete? Player has quit, all lives finished or time is up. 
; returns 1 if complete , 0 otherwise
check_for_game_complete
	STMFD sp!, {lr,r1-r3}
	
	; Setting r0 to 0 to start the game
	MOV r0, #0
	
	; Checking TIMER1 to check for 2 mins completion
	LDR r1, =TIMER1
	LDR r2, [r1]
	LDR r3, =TWO_MIN_DURATION
	CMP r2, r3
	BLO TIME_NOT_END 
	MOV r0, #1
TIME_NOT_END

	; Checking to see if all lives have been used up
	LDR r1, =LIVES_PLAYER
	LDR r2, [r1]
	CMP r2, #0
	BNE LIVES_NOT_GONE
	MOV r0, #1
LIVES_NOT_GONE

	; Checking the quit flag
	LDR r1, =ENDPROG
	LDR r2, [r1]
	CMP r2, #0
	BEQ NOT_QUIT
	MOV r0, #1
NOT_QUIT
	
	LDMFD sp!, {lr,r1-r3}
	BX lr
	
; looks for any kind of collisions
see_collisions
	STMFD sp!, {lr, r0-r5}
	
	; Has bullet killed any enemies?
	LDR r0, =IS_BULLET_FIRED
	LDR r1, [r0]
	CMP r1, #0
	BEQ BULLET_WAS_NOT_FIRED
	LDR r0, =X_POS_BULLET
	LDR r4, [r0]
	LDR r0, =Y_POS_BULLET
	LDR r5, [r0]
	MOV r0, #0 ; counter for loop
	LDR r1, =ENEMY1
KILLING_ENEMY_LOOP
	LDRB r2, [r1,#3] ; loading the state
	AND r2, #1 ; isolating the alive bit
	CMP r2, #0
	BEQ CONTINUE_KILLING_ENEMY
	LDRB r2, [r1] ; loading xpos
	CMP r2, r4
	BNE CONTINUE_KILLING_ENEMY
	LDRB r2, [r1,#1] ; loading ypos
	CMP r2, r5
	BNE CONTINUE_KILLING_ENEMY
	
	
	; killing  the enemy here
	
	LDRB r2, [r1,#3]
	LSR r2, #2
	AND r2, #1
	MOV r3, #20
	LSL r3, r2 ; shifting of 0 (A enemy) means 50 points scored, shifting of 1 (M enemy, W enemy) doubles the value
	LDR r4, =SCORE
	LDR r5, [r4]
	ADD r5, r5, r3
	STR r5, [r4] ; saving the score back
	LDRB r2, [r1,#3]
	BIC r2, #1 ; clearing the alive bit
	STRB r2, [r1,#3] ; enemy is dead, it is saved
	LDR r2, =IS_BULLET_FIRED
	MOV r3, #0
	STR r3, [r2] ; setting that bullet is not fired
	B BULLET_WAS_NOT_FIRED ; do not go through next loops
	
CONTINUE_KILLING_ENEMY
	ADD r0, r0, #1 ; increase the loop counter
	ADD r1, r1, #4
	CMP r0, #20
	BLT KILLING_ENEMY_LOOP
BULLET_WAS_NOT_FIRED
	
	; Checking to see if any enemies are touching the player
	LDR r0, =X_POS_PLAYER
	LDR r4, [r0]
	LDR r0, =Y_POS_PLAYER
	LDR r5, [r0]
	MOV r0, #0 ; counter for loop
	LDR r1, =ENEMY1
KILLING_PLAYER_LOOP
	LDRB r2, [r1,#3] ; enemy state is loaded
	AND r2, r2, #1
	CMP r2, #0
	BEQ CONTINUE_KILLING_PLAYER
	LDRB r2, [r1] ; loading xpos
	CMP r2, r4
	BNE CONTINUE_KILLING_PLAYER
	LDRB r2, [r1,#1] ; loading ypos
	CMP r2, r5
	BNE CONTINUE_KILLING_PLAYER
	
	; Decrement the player lives if touched, 
	;creating new player, 
	;drawing board and delaying for 1 second
	LDR r2, =LIVES_PLAYER
	LDR r3, [r2]
	LSR r3, #1 ; decrementing life
	STR r3, [r2]
	BL create_player
	BL draw_the_board
	MOV r0, #1000 ; creating delay to remove side effects
	BL delay
	
CONTINUE_KILLING_PLAYER
	ADD r0, r0, #1 ; incrementing the  loop variable
	ADD r1, r1, #4
	CMP r0, #13
	BLT KILLING_PLAYER_LOOP
	
	LDMFD sp!, {lr,r0-r5}






   BX lr
	
	END