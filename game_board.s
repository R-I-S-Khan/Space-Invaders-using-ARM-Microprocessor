	AREA game_board, CODE, READWRITE
	EXPORT draw_the_board
	EXPORT clear_space
	EXPORT board_reset
	EXPORT what_obstacle
	EXPORT WIDTH_BOARD
	EXPORT HEIGHT_BOARD
		
	IMPORT get_next_pos
	IMPORT output_character
	IMPORT X_POS_PLAYER
	IMPORT Y_POS_PLAYER
	IMPORT DIR_PLAYER
	IMPORT X_POS_BULLET
	IMPORT Y_POS_BULLET
	IMPORT IS_BULLET_FIRED
	IMPORT ENEMY4
    IMPORT ENEMY1
	IMPORT output_string
	IMPORT write_register_to_uart
	IMPORT SCORE
		
board =   "|-------------------|"
board1 =  "|                   |"
board2 =  "|                   |"
board3 =  "|                   |"
board4 =  "|                   |"
board5 =  "|                   |"
board6 =  "|                   |"
board7 =  "|                   |"
board8 =  "|                   |"
board9 =  "|  SSS   SSS   SSS  |"
board10 = "|  S S   S S   S S  |"
board11 = "|                   |"
board12 = "|                   |"
board13 = "|                   |"
board14 = "|                   |"
board15 = "|                   |"
board16 = "|-------------------|"

	ALIGN
		
TextScore  = "Score: 0x", 0
playerCharacters = "AAAA"
enemyCharacters = "WOM"
bulletcharacter = "^"
new_line = "\n\r",0
WIDTH_BOARD  EQU 21
HEIGHT_BOARD EQU 17
	
	ALIGN
	
; function to convert x,y coordinate to address of character
;  x is passed in r1, y in r2. Character offset gets returned in r0
offset_position
	STMFD sp!, {r1-r3}
	
	; offset = x + y*width
	LDR r3, =WIDTH_BOARD
	MOV r0, r1
	MUL r1, r2, r3
	ADD r0, r0, r1
	
	LDMFD sp!, {r1-r3}
	BX lr
	
; resetting the board (filling with space)
board_reset
	STMFD sp!, {lr,r0-r6}
	
	MOV r6, #32 ; #
	LDR r5, =board
	LDR r3, =WIDTH_BOARD
	LDR r4, =HEIGHT_BOARD
	SUB r3, r3, #19 ; gets rid of walls
	SUB r4, r4, #19 ; gets rid of walls
	MOV r1, #1 ; x
	MOV r2, #3 ; y
	
reset_LOOP
	BL offset_position
	STRB r6, [r5,r0]
	ADD r1, r1, #1 ; incrementing X coord
	CMP r1, r3
	BLE reset_LOOP
	MOV r1, #1 ; resetting x
	ADD r2, r2, #1 ; incrementing Y coord
	CMP r2, r4
	BLE reset_LOOP
	
	LDMFD sp!, {lr,r0-r6}
	BX lr
	
; Clearing space in the positions (r0,r1)
clear_space
	STMFD sp!, {lr,r0-r3}
	
	; Seeing that position is in range [1,height-2] and [1,width-2] 
	LDR r2, =WIDTH_BOARD
	SUB r2, r2, #2
	LDR r3, =HEIGHT_BOARD
	SUB r3, r3, #2
	CMP r0, #1
	BLT clear_EXIT
	CMP r0, r2
	BGT clear_EXIT
	CMP r1, #1
	BLT clear_EXIT
	CMP r1, r3
	BGT clear_EXIT
	
	; Writing ' ' to the position
	LDR r3, =board
	MOV r2, r1
	MOV r1, r0
	BL offset_position
	MOV r1, #32
	STRB r1, [r3,r0]
	
clear_EXIT
	LDMFD sp!, {lr,r0-r3}
	BX lr
	
; Returns what is the type of obstacle that a player is trying to move. 
; x,y,dir passed in r0,r1,and r2. Obstacle is returned in r0 (0 = air, 2 = brick, 3 =shield , 4 = shield)
what_obstacle
	STMFD sp!, {lr,r1-r2}
	
	BL get_next_pos 
	MOV r2, r1
	MOV r1, r0
	BL offset_position
	LDR r1, =board
	LDRB r2, [r1,r0]
	
	CMP r2, #32
	BNE CHECK_SPACE
	
	MOV r0, #0 ;air
CHECK_SPACE
	CMP r2, #32
	BNE CHECK_BRICK
	MOV r0, #0 ; 
CHECK_BRICK
	CMP r2, #0x7C
	BNE NOT_BRICK1
	MOV r0, #2
NOT_BRICK1
	CMP r2, #0x2D
	BNE NOT_BRICK2
	MOV r0, #2
NOT_BRICK2
	CMP r2, #0
	BNE NOT_NULL
	MOV r0, #2 ; null is treated as brick
NOT_NULL
	CMP r2, #0x53
	BNE NOTSHIELD1
	MOV r0, #3
NOTSHIELD1
	CMP r2, #0x73
	BNE NOTSHIELD2
	MOV r0, #4
NOTSHIELD2	
	LDMFD sp!, {lr,r1-r2}
	BX lr

; draws the board 
draw_the_board
	STMFD sp!, {lr,r0-r12}
	; r0 - char to render, 
	;r1 - x, 
	;r2 - y, 
	;r3 - width, 
	;r4 - height, 
	;r5 - Xposplayer, 
	;r6 - Yposplayer, 
	;r7 - player character, 
	;r8 - enemy address base, 
	;r9 - Xposbullet, 
	;r10 -Yposbullet , 
	;r11 -addresses, 
	;r12 - counter for loop
	
	; Clearing the screen
	MOV r0, #12
	BL output_character
	
	; Loading the positions and data into the memory
	MOV r1, #0
	MOV r2, #0
	LDR r3, =WIDTH_BOARD
	LDR r4, =HEIGHT_BOARD
	LDR r11, =X_POS_PLAYER
	LDR r5, [r11]
	LDR r11, =Y_POS_PLAYER
	LDR r6, [r11]
	LDR r11, =DIR_PLAYER
	LDR r0, [r11]
	LDR r11, =playerCharacters
	LDR r7, [r11,r0]
	LDR r8, ENEMY1
	LDR r11, =X_POS_BULLET
	LDR r9, [r11]
	LDR r11, =Y_POS_BULLET
	LDR r10, [r11]
	
	; Is bullet fired? If not, move the position off board
	LDR r11, =IS_BULLET_FIRED
	LDR r0, [r11]
	CMP r0, #0
	BNE draw_LOOP
	MOV r9, #30 
	MOV r10, #30 
	
draw_LOOP
	; Is r1,r2 a player?
	CMP r1, r5
	BNE NOT_PLAYER
	CMP r2,r6
	BNE NOT_PLAYER
	MOV r0, r7
	BL output_character
	
	B CHAR_DRAWN
	
NOT_PLAYER
	; Is r1,r2 an enemy?
	LDR r11, =ENEMY1
	MOV r12, #0
LOOP_ENEMY
	LDRB r0, [r11] ; loading the xpos
	CMP r1, r0
	BNE LOOP_ENEMY_END
	LDRB r0, [r11,#1] ; loading the ypos
	CMP r2,r0
	BNE LOOP_ENEMY_END
	LDRB r0, [r11,#3] ; state of enemy
	AND r0, r0, #1 ; bit for depicting alive
	CMP r0, #0
	BEQ LOOP_ENEMY_END
	
	; Determining type of enemy and drawing
	LDR r0, [r11,#3] ; state of enemy
	
	AND r0, #7
	LSR r0, #1 ; type of enemy determined in r0: 0 - regular, 1 - hard
	LDR r11, =enemyCharacters
	LDRB r0, [r11,r0]
	BL output_character
	B CHAR_DRAWN
	
LOOP_ENEMY_END
	ADD r11, r11, #4 ; going to next enemy address
	ADD r12, r12, #1 ; incrementing the loop counter
	CMP r12, #20
	BLT LOOP_ENEMY
	
NOT_ENEMY
	; Is r1,r2  bullet?
	CMP r1, r9
	BNE NOT_BULLET
	CMP r2, r10
	BNE NOT_BULLET
	LDR r11, =bulletcharacter
	LDRB r0, [r11]
	BL output_character
	B CHAR_DRAWN
	
NOT_BULLET
	BL offset_position
	LDR r11, =board
	LDRB r0, [r11,r0]
	CMP r0, #0
	BNE NOT_ZERO_CHAR
	MOV r0, #32
NOT_ZERO_CHAR
	BL output_character
	
CHAR_DRAWN ; draw it

	ADD r1, r1, #1 ; incrementing xpos
	CMP r1, r3
	BLT draw_LOOP
	MOV r1, #0 ; resetting X
	ADD r2, r2, #1 ; incrementing ypos
	MOV r11, r4
	LDR r4, =new_line
	BL output_string
	MOV r4, r11
	CMP r2, r4
	BLT draw_LOOP
	
	LDR r4, =TextScore
	BL output_string
	LDR r1, =SCORE
	LDR r0, [r1]
	BL write_register_to_uart
	
	LDMFD sp!, {lr,r0-r12}
	BX lr
	
	END