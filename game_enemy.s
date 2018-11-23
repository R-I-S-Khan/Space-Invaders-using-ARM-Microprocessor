	AREA game_enemy, CODE, READWRITE
	EXPORT create_enemy
	EXPORT update_enemy
	EXPORT ENEMY1
	EXPORT ENEMY2
	EXPORT ENEMY3
	EXPORT ENEMY4
	EXPORT UPDATE_ENEMY1
	EXPORT UPDATE_ENEMY2
	EXPORT UPDATE_ENEMY3
	EXPORT UPDATE_ENEMY4
	IMPORT call_random_generator
	IMPORT clear_space
	IMPORT what_obstacle
	IMPORT get_next_pos
	IMPORT X_POS_PLAYER
	IMPORT Y_POS_PLAYER
	
; Enemy data kept in this format: [XPOS,YPOS,DIR,STATE] 
; Bit 0 in signifies the state (0 - dead, 1 - alive) 
; Bit 1 in state means (0 - regular, 1 - hard)
ENEMY1 DCD 0x01010202
ENEMY4 DCD 0x03030402	
ENEMY2 DCD 0x02020302
ENEMY3 DCD 0x05050102


UPDATE_ENEMY1 DCD 0x210
UPDATE_ENEMY2 DCD 0x210  
UPDATE_ENEMY3 DCD 0x248 
UPDATE_ENEMY4 DCD 0x292	
	
DIRS_ENEMY DCD 0 ; directions that enemy moves is placed here 

; this function determines the direction the enemy should go in. (enemyXPOS,enemyYPOS) =(r0, r1). Result is placed in DIRS_ENEMY
determine_enemy_dirs
	STMFD sp!, {r0-r6}
	LDR r6, =DIRS_ENEMY
GO_RIGHT  
	MOV r5, #1
	STRB r5, [r6]
	MOV r5, #2  
	STRB r5, [r6,#1]
GO_DOWN ; 
	MOV r5, #3
	STRB r5, [r6,#2]
	MOV r5, #0 
	STRB r5, [r6,#3]
	B determine_enemy_dirs_EXIT

determine_enemy_dirs_EXIT
	LDMFD sp!, {r0-r6}
	BX lr

; This function creates an enemy . 
;enemy structure address gets passed in r0. 
;Board width r1, board height r2
create_enemy
	STMFD sp!, {lr,r0-r6}

	MOV r3, r0 ; placing r0 in r3 to preserve the enemy address
	SUB r1, r1, #2 ; removing walls from width
	SUB r2, r2, #9 ; removing walls from height
	
	; Assigning XPOS in range [1,width-1)
	MOV r0, r1
	MOV r0,#4
	ADD r0, r0, #1
	STRB r0, [r3] ; storing xpos
	MOV r4, r0 ;
	
	; Assigning YPOS in range [8,height-1)
	MOV r0, r2
	
	MOV r0,#4
	
	STRB r0, [r3,#1] ; storing ypos
	MOV r5, r0 ; 
	
	
	MOV r0, #1
	STRB r0, [r3,#2]
	
	; Set bit to alive
	LDRB r0, [r3,#3]
	ORR r0, r0, #1 
	STRB r0, [r3,#3]
	

	
	LDMFD sp!, {lr,r0-r6}
	BX lr

;updates the enemy
;base address of the enemy struct gets passed in r0
update_enemy
	STMFD sp!, {lr,r0-r6}

	; Is enemy dead?
	LDRB r1, [r0,#3]
	AND r1, r1, #1
	CMP r1, #0
	BEQ update_enemy_EXIT
	
	; Loading X -> r0, Y -> r1, dir -> r2
	MOV r3, r0 ; moving r0 out of the way
	LDRB r0, [r3]
	LDRB r1, [r3,#1]
	LDRB r2, [r3,#2]
	MOV r4, r0 ; preserving X
	
	; Can we keep moving in that direction?
	BL what_obstacle
	CMP r0, #0 ; must be 0 which is space
	MOV r0, r4 ; putting x back
	BNE CHANGE_DIRECTION
	
	; go in the next positiobn and save back the new position
	;; updating x,y based on direction
	BL get_next_pos 
	STRB r0, [r3] ; X
	STRB r1, [r3,#1] ; Y
	B update_enemy_EXIT
CHANGE_DIRECTION

	; Picking the direction that we can move in
	MOV r4, r0 ; preserve X
	LDR r6, =DIRS_ENEMY
	BL determine_enemy_dirs
	MOV r5, #0 ; counter for looping
	
LOOP_OF_DIR
	LDRB r2, [r6,r5]
	BL what_obstacle
	CMP r0, #0
	MOV r0, r4 ; restoring the value of  X
	BEQ FOUND_DIR
	ADD r5, r5, #1
	CMP r5, #3
	BLT LOOP_OF_DIR
	
FOUND_DIR
	; saving back the new direction. 
	STRB r2, [r3,#2] 
	
update_enemy_EXIT
	LDMFD sp!, {lr,r0-r6}
	BX lr
	
	END