	AREA game_player, CODE, READWRITE
	EXPORT update_player
	EXPORT update_bullet
	EXPORT create_player
	EXPORT X_POS_PLAYER
	EXPORT Y_POS_PLAYER
	EXPORT LIVES_PLAYER
	EXPORT UPDATE_PLAYER
	EXPORT UPDATE_BULLET
	EXPORT SCORE
	EXPORT DIR_PLAYER
	EXPORT X_POS_BULLET
	EXPORT Y_POS_BULLET
	EXPORT IS_BULLET_FIRED
	EXPORT DIR_BULLET
		
	IMPORT available_character
	IMPORT ENDPROG
	IMPORT what_obstacle
	IMPORT get_next_pos
	IMPORT clear_space
	IMPORT illuminate_RGB_LED
	

X_POS_PLAYER   DCD 0
Y_POS_PLAYER   DCD 0
DIR_PLAYER    DCD 0
LIVES_PLAYER  DCD 0xF ; 1111 --> each 1 a life. Lives decreased by right shift. It is passed directly to LED function
UPDATE_PLAYER DCD 0x210 ; 10 0001 0000 (updating two times per second )
	
X_POS_BULLET   DCD 7
Y_POS_BULLET   DCD 7
DIR_BULLET    DCD 0
IS_BULLET_FIRED  DCD 0 ; it is set to 1 when fired, when collides reset to 0
UPDATE_BULLET EQU 0x3FF ; 11 1111 1111 (updating 10 times per second)

SCORE         DCD 0

; this function moves the player. The desired direction gets passed into r0
move_the_player
	STMFD sp!, {lr,r0-r5}
	
	MOV r2, r0 
	LDR r3, =X_POS_PLAYER
	LDR r0, [r3]
	LDR r3, =Y_POS_PLAYER
	LDR r1, [r3]
	MOV r4, r0 
	MOV r5, r1 
	
	BL what_obstacle ; the obstacle will be obtained in r0
	CMP r0, #2 ; Are we going through the brick?
	BEQ move_the_player_EXIT
	
	
	CMP r0, #1
	BNE NOTSPACE
	
	MOV r0, r4
	MOV r1, r5
	BL get_next_pos ; based on r2 (dir), updating r0 and r1
	BL clear_space
	
NOTSPACE
	; updating position
	MOV r0, r4 ; x is put back
	MOV r1, r5 ; y is put back
	BL get_next_pos
	MOV r4, r0 
	MOV r5, r1
	
move_the_player_EXIT
	LDR r3, =DIR_PLAYER
	STR r2, [r3] ; saving the new direction
	LDR r3, =X_POS_PLAYER
	STR r4, [r3] 
	LDR r3, =Y_POS_PLAYER
	STR r5, [r3]

	LDMFD sp!, {lr,r0-r5}
	BX lr

; This function is used to create a new player at the loaction provided.
create_player
	STMFD sp!, {lr,r0,r1}
	; Reset X
	LDR r0, =X_POS_PLAYER
	MOV r1, #1
	STR r1, [r0]
	
	; Reset Y
	LDR r0, =Y_POS_PLAYER
	MOV r1, #12 ; the middle if you count the sky
	STR r1, [r0]
	
	; Reset dir
	LDR r0, =DIR_PLAYER
	MOV r1, #1
	STR r1, [r0]
	
	; Clear dirt
	MOV r0, #1
	MOV r1, #12
	BL clear_space
	
	LDMFD sp!, {lr,r0,r1}
	BX lr

; This function updates the player
update_player
	STMFD sp!, {lr,r0-r2}

	BL available_character
	
	; Checking for movement of player
	CMP r0, #119 ; w
	BNE NOT_UP
	MOV r0, #0
	BL move_the_player
	B update_player_EXIT
NOT_UP
	CMP r0, #97 ; a
	BNE NOT_LEFT
	MOV r0, #3
	BL move_the_player
	B update_player_EXIT
NOT_LEFT
	CMP r0, #115 ; s
	BNE NOT_DOWN
	MOV r0, #2
	BL move_the_player
	B update_player_EXIT
NOT_DOWN
	CMP r0, #100 ; d
	BNE NOT_RIGHT
	MOV r0, #1
	BL move_the_player
	B update_player_EXIT
NOT_RIGHT
	CMP r0, #32
	BNE IS_NOT_SHOOTING
	
	; Has the bullet been fired?
	LDR r0, =IS_BULLET_FIRED
	LDR r1, [r0]
	CMP r1, #0
	BNE update_player_EXIT
	
	; Firing the buller
	MOV r1, #1
	STR r1, [r0] ; setting fired to 1(true)
	LDR r0, =X_POS_PLAYER
	LDR r2, =X_POS_BULLET
	LDR r1, [r0]
	STR r1, [r2] ; set xpos to player xpos
	LDR r0, =Y_POS_PLAYER
	LDR r2, =Y_POS_BULLET
	LDR r1, [r0]
	STR r1, [r2] ; set ypos to player ypos
	LDR r0, =DIR_PLAYER
	;MOV r1, #0
	LDR r2, =DIR_BULLET
	LDR r1, [r0]
	STR r1, [r2] ; set dir to player dir
	MOV r0, #1 ; flash RGB LED red
	BL illuminate_RGB_LED
	
	B update_player_EXIT
IS_NOT_SHOOTING
	CMP r0, #113
	BNE update_player_EXIT
	LDR r0, =ENDPROG
	MOV r1, #1
	STR r1, [r0]
	
update_player_EXIT
	LDMFD sp!, {lr,r0-r2}
	BX lr
	
; If the bullet is fired, move it. If the bullet collides with a border or dirt, get rid of it
update_bullet
	STMFD sp!, {lr,r0-r4}
	
	; Checking if bullet has been fired
	LDR r0, =IS_BULLET_FIRED
	LDR r1, [r0]
	CMP r1, #0
	BEQ update_bullet_EXIT
	
	; Position and direction loaded into (r3,r4) and r2
	LDR r0, =X_POS_BULLET
	LDR r3, [r0]
	LDR r0, =Y_POS_BULLET
	LDR r4, [r0]
	LDR r0, =DIR_BULLET
	LDR r2, [r0]
	
	; Checking whether the bullet has hit barrier. Enemies are not included.
	MOV r0, r3 ; putting x and y into argument registers
	MOV r1, r4
	BL what_obstacle
	CMP r0, #0 ; Are we moving in air?
	BNE REMOVE_BULLET
	
	; Determining the new position and updating
	MOV r0, r3 ; putting x back
	BL get_next_pos
	LDR r2, =X_POS_BULLET
	STR r0, [r2]
	LDR r2, =Y_POS_BULLET
	STR r1, [r2]
	B update_bullet_EXIT
	
REMOVE_BULLET
	LDR r0, =IS_BULLET_FIRED
	MOV r1, #0
	STR r1, [r0]
	
update_bullet_EXIT
	LDMFD sp!, {lr,r0-r4}
	BX lr
	
	END