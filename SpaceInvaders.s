	AREA interrupts, CODE, READWRITE
	EXPORT lab7
	EXPORT FIQ_Handler
	EXPORT ENDPROG
	EXPORT PAUSED
		
	IMPORT output_string
	IMPORT pin_connect_block_setup_for_gpio
	IMPORT pin_connect_block_setup_for_uart0
	IMPORT uart_init
	IMPORT display_digit_on_7_seg
	IMPORT setup_gpios
	IMPORT output_character
	IMPORT input_character
	IMPORT interrupt_init
	IMPORT write_register_to_uart
	IMPORT multiplication
	IMPORT div_and_mod
	IMPORT timers_enable
	IMPORT illuminate_RGB_LED
	IMPORT start_the_game
	IMPORT level_start
	IMPORT level_loop
	IMPORT SCORE
	IMPORT draw_the_board
	IMPORT available_character
	IMPORT delay
		
ENDPROG DCD 0
PAUSED   DCD 0
	
directiongiven = 12,"Lab 7 - Space Invaders\n\r\tTry to shoot invaders of your space and save humanity!\n\r\tGet points for killing invaders.\n\r\tMove to higher levels by killing all enemies\n\r\n\r",0

control_display = "Controls:\n\r\tw - up\n\r\ta - left\n\r\ts - down\n\r\td - right\n\r\tSpace - Fire air bomb\n\r\tEINT Button - Pause\n\r\n\r",0
legend_display = "Legend:\n\r\t|- = wall (impassable)\n\r\tO = small enemy\n\r\tW = big enemy\n\r\tA = player \n\r\t^ = bullet\n\r\t' '(space) = air\n\r\n\rPress any key to begin",0
score_display = "\n\r\n\rGAME OVER! YOUR SCORE: 0x",0
replay_display = "\n\rPlay again? (Y for Yes/N or anything else for No)",0
exit_display = "\n\rWho will save humanity now? :( \n\r",0
wecouldnotdo = "\n\rWe could not complete some stuff.:( \n\rBut we did implement functionality of moving player and shooting in all directions! :D\n\rThere are 10 invaders moving in each level, not 35.\n\rThe enemies cannot shoot, player dies when comes in contact enemy.\n\rWe do not have a mothership.\n\rThe score is displayed in screen and levels in sevenseg\n\rWe could not implement displaying duration of game played.\n\rBut you can play it for 2 minutes\n\rPress any key to begin\n\r"

	ALIGN
		
lab7
	STMFD SP!, {lr}

	BL pin_connect_block_setup_for_gpio
	BL pin_connect_block_setup_for_uart0
	BL uart_init
	BL setup_gpios
	BL interrupt_init
	BL timers_enable
	
LOOP_OF_GAME
	; Setting 7-seg to 0
	MOV r0, #0
	BL display_digit_on_7_seg
	
	; at first setting rgb to white
	MOV r0, #6
	BL illuminate_RGB_LED
	
	; instructions displayed
	LDR r4, =directiongiven
	BL output_string
	LDR r4, =control_display
	BL output_string
	LDR r4, =legend_display
	BL output_string
	LDR r4, =wecouldnotdo
	BL output_string
	BL input_character 
	
	; start the game 
	BL start_the_game
	BL level_start
	BL level_loop
	
	; Game is over, display purple rgb
	MOV r0, #4
	BL illuminate_RGB_LED
	
	
	LDR r4, =score_display
	BL output_string
	LDR r1, =SCORE
	LDR r0, [r1]
	BL write_register_to_uart
	LDR r4, =replay_display
	BL output_string
	
	; delaying and clearing buffer
	MOV r0, #250
	BL delay
BUFFER_IS_EMPTY
	BL available_character
	CMP r0, #0
	BNE BUFFER_IS_EMPTY
	
	BL input_character
	CMP r0, #121 ; y
	BEQ LOOP_OF_GAME
	
	
	LDR r4, =exit_display
	BL output_string
	
	LDMFD SP!, {lr}
	BX lr
	
FIQ_Handler
		STMFD SP!, {r0-r12,lr}   ; Save registers
		MRS r9, CPSR ; preserve CPSR
		STMFD SP!, {r9}
		
		
		LDR r0, =ENDPROG
		LDR r1, [r0]
		CMP r1, #0
		BNE FIQ_Exit

EINT1_CHECK			; Checking for EINT1_CHECK interrupt
		LDR r0, =0xE01FC140
		LDR r1, [r0]
		TST r1, #2
		BEQ U0IIR_CHECK
			
		LDR r3, =PAUSED
		LDR r4, [r3]
		EOR r4, #1 ; negating the first bit
		STR r4, [r3]
		
		ORR r1, r1, #2		; Clearing the interrupt
		STR r1, [r0]
	
U0IIR_CHECK
		LDR r0, =0xE000C008
		LDR r1, [r0]
		AND r1, r1, #1 ; isolate bit 0
		CMP r1, #0 ; checking to see if interrupt pending
		BNE TIMER1_CHECK
		
		
		
		
TIMER1_CHECK
		LDR r0, =0xE0008000
		LDR r1, [r0]
		AND r1, r1, #2 ; isolating the lsb
		CMP r1, #0
		BEQ FIQ_Exit
		
		; Clearing interrupt
		LDR r1, [r0]
		ORR r1, r1, #2
		STR r1, [r0]
		
		; Handling timer interrupt
	
FIQ_Exit
		LDMFD SP!, {r9}
		MSR CPSR_c, r9 ; restore CPSR
		LDMFD SP!, {r0-r12,lr}
		SUBS pc, lr, #4
		
	END