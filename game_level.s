	AREA game_level, CODE, READWRITE
	IMPORT delay
	IMPORT ENEMY1
	IMPORT UPDATE_ENEMY1
	IMPORT ENEMY2
	IMPORT UPDATE_ENEMY2
	IMPORT ENEMY3
	IMPORT UPDATE_ENEMY3
	IMPORT ENEMY4
	IMPORT UPDATE_ENEMY4
	IMPORT draw_the_board
	IMPORT board_reset
	IMPORT WIDTH_BOARD
	IMPORT HEIGHT_BOARD
	IMPORT create_enemy
	IMPORT reduce_update_period
	IMPORT create_player
	IMPORT display_digit_on_7_seg
	IMPORT illuminate_RGB_LED
	IMPORT UPDATE_PLAYER
	IMPORT update_player
	IMPORT UPDATE_BULLET
	IMPORT update_bullet
	IMPORT IS_BULLET_FIRED
	IMPORT update_enemy
	IMPORT check_paused_state
	IMPORT check_for_game_complete
	IMPORT illuminate_LEDS
	IMPORT LIVES_PLAYER
	IMPORT see_collisions
	IMPORT SCORE	
	EXPORT LEVEL
	EXPORT level_start
	EXPORT level_loop
	
LEVEL DCD 1

; This function does all stuffs needed for starting a level
level_start
	STMFD sp!, {lr,r0-r2}

	; Resetting the board
	BL board_reset
	
	; Creating new enemies
	LDR r0, =ENEMY2
	LDR r1, =WIDTH_BOARD
	LDR r2, =HEIGHT_BOARD
	BL create_enemy
	ADD r0, r0, #4
	BL create_enemy
	ADD r0, r0, #4
	BL create_enemy
	
	ADD r0, r0, #4
	BL create_enemy
	ADD r0, r0, #4
	BL create_enemy
	ADD r0, r0, #4
	BL create_enemy
	
	
	; creating player
	BL create_player
	
	LDR r1,=LEVEL
	LDR r0,[r1]
	BL display_digit_on_7_seg
	; 7seg
	
	LDMFD sp!, {lr,r0-r2}
	BX lr
	
; completes level 
level_complete
	STMFD sp!, {lr,r0-r2}
	
	; Is each enemy dead or alive? 
	LDR r1, =ENEMY1
	LDRB r2, [r1,#3] ; loading the  state
	AND r2, r2, #1 ; isolating the lsb (0 = dead, 1 alive)
	CMP r2, #1
	BEQ level_complete_EXIT
	
	; next enemy
	ADD r1, r1, #4
	LDRB r2, [r1,#3] 
	AND r2, r2, #1 
	CMP r2, #1
	BEQ level_complete_EXIT
	
	ADD r1, r1, #4
	LDRB r2, [r1,#3] 
	AND r2, r2, #1 
	CMP r2, #1
	BEQ level_complete_EXIT
	
	ADD r1, r1, #4
	LDRB r2, [r1,#3] 
	AND r2, r2, #1 
	CMP r2, #1
	BEQ level_complete_EXIT
	ADD r1, r1, #4
	LDRB r2, [r1,#3] 
	AND r2, r2, #1 
	CMP r2, #1
	BEQ level_complete_EXIT
	ADD r1, r1, #4
	LDRB r2, [r1,#3] 
	AND r2, r2, #1 
	CMP r2, #1
	BEQ level_complete_EXIT
	
	; reached here. so all enemies dead
	
	; go to next level
	LDR r1, =LEVEL
	LDR r2, [r1]
	ADD r2, r2, #1
	STR r2, [r1]
	
	; Updating the enemy periods
	LDR r1, =UPDATE_ENEMY1
	LDR r0, [r1]
	BL reduce_update_period
	STR r0, [r1]
	LDR r0, [r1,#4]
	BL reduce_update_period
	STR r0, [r1,#4]
	LDR r0, [r1,#8]
	BL reduce_update_period
	STR r0, [r1,#8]
	
	; Updating the player periods
	LDR r1, =UPDATE_PLAYER
	LDR r0, [r1]
	BL reduce_update_period
	STR r0, [r1]
	
	; start a new level
	BL level_start
	
level_complete_EXIT
	LDMFD sp!, {lr,r0-r2}
	BX lr
	
; level update loop
level_loop
	STMFD sp!, {lr,r0-r3,r8}
	
	
	; loop counter for determining who to update
	MOV r8, #0 

LEVEL_LOOP
	; Checking to see if we update the player
	LDR r0, =UPDATE_PLAYER
	LDR r1, [r0]
	LSR r1, r8 ; getting the exact bit in lsb
	AND r1, r1, #1 ; isolating it
	CMP r1, #0
	BEQ NOT_PLAYER
	BL update_player 
NOT_PLAYER

	
	LDR r1, =UPDATE_BULLET
	LSR r1, r8
	AND r1, r1, #1
	CMP r1, #0
	BEQ NOT_BULLET
	LDR r1, =IS_BULLET_FIRED
	LDR r2, [r1]
	CMP r2, #0
	BEQ NOT_BULLET
	BL update_bullet
NOT_BULLET
	
	; updating each enemy if it is their turn by looping 
	LDR r0, =ENEMY1
	LDR r1, =UPDATE_ENEMY1
	MOV r2, #0 ; variable for looping
LOOP_ENEMY
	LDRB r3, [r0,#3] ; loadign the enemy state
	AND r3, #1 ; isolating the lsb which has the alive bit
	CMP r3, #0
	BEQ ENEMY_CONT
	LDR r3, [r1] ; loading the update mask
	LSR r3, r8
	AND r3, r3, #1 ; isolating lsb
	CMP r3, #0
	BEQ ENEMY_CONT
	BL update_enemy 
ENEMY_CONT
	ADD r0, r0, #4
	ADD r1, r1, #4
	ADD r2, r2, #1 ; incrementing the loop variable
	CMP r2, #10
	BLT LOOP_ENEMY
	
	; increasing and bounding our loop variable
	ADD r8, r8, #1
	CMP r8, #10
	BLT LOOP_GOOD
	MOV r8, #0
LOOP_GOOD

	; seeing if their are collisions
	BL see_collisions

	; Drawing the board and delaying (0.1s)
	BL draw_the_board
	MOV r0, #100
	BL delay
	
	; Has the player paused the game?
	BL check_paused_state
	
	; Has the player beat the level
	BL level_complete
	
	; Updating the rgb led to green (blue - pausing and red - firing)
	MOV r0, #2
	BL illuminate_RGB_LED
	
	; Updating the lives leds
	LDR r1, =LIVES_PLAYER
	LDR r0, [r1]
	BL illuminate_LEDS
	
	; Checking to see if the game is still supposed to be playing
	BL check_for_game_complete
	CMP r0, #0
	BEQ LEVEL_LOOP
	
	LDMFD sp!, {lr,r0-r3,r8}
	BX lr
	
	END