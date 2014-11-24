ORG		&H000

;***************************************************************
;* IO address space map
;***************************************************************
SWITCHES: EQU &H00  ; slide switches
LEDS:     EQU &H01  ; red LEDs
TIMER:    EQU &H02  ; timer, usually running at 10 Hz
XIO:      EQU &H03  ; pushbuttons and some misc. inputs
SSEG1:    EQU &H04  ; seven-segment display (4-digits only)
SSEG2:    EQU &H05  ; seven-segment display (4-digits only)
LCD:      EQU &H06  ; primitive 4-digit LCD display
XLEDS:    EQU &H07  ; Green LEDs (and Red LED16+17)
BEEP:     EQU &H0A  ; Control the beep
CTIMER:   EQU &H0C  ; Configurable timer for interrupts
LPOS:     EQU &H80  ; left wheel encoder position (read only)
LVEL:     EQU &H82  ; current left wheel velocity (read only)
LVELCMD:  EQU &H83  ; left wheel velocity command (write only)
RPOS:     EQU &H88  ; same values for right wheel...
RVEL:     EQU &H8A  ; ...
RVELCMD:  EQU &H8B  ; ...
I2C_CMD:  EQU &H90  ; I2C module's CMD register,
I2C_DATA: EQU &H91  ; ... DATA register,
I2C_RDY:  EQU &H92  ; ... and BUSY register
UART_DAT: EQU &H98  ; UART data
UART_RDY: EQU &H98  ; UART status
SONAR:    EQU &HA0  ; base address for more than 16 registers....
DIST0:    EQU &HA8  ; the eight sonar distance readings
DIST1:    EQU &HA9  ; ...
DIST2:    EQU &HAA  ; ...
DIST3:    EQU &HAB  ; ...
DIST4:    EQU &HAC  ; ...
DIST5:    EQU &HAD  ; ...
DIST6:    EQU &HAE  ; ...
DIST7:    EQU &HAF  ; ...
SONALARM: EQU &HB0  ; Write alarm distance; read alarm register
SONARINT: EQU &HB1  ; Write mask for sonar interrupts
SONAREN:  EQU &HB2  ; register to control which sonars are enabled
XPOS:     EQU &HC0  ; Current X-position (read only)
YPOS:     EQU &HC1  ; Y-position
THETA:    EQU &HC2  ; Current rotational position of robot (0-359)
RESETPOS: EQU &HC3  ; write anything here to reset odometry to 0
; Some bit masks.
; Masks of multiple bits can be constructed by ORing these
; 1-bit masks together.
Mask0:    DW &B00000001
Mask1:    DW &B00000010
Mask2:    DW &B00000100
Mask3:    DW &B00001000
Mask4:    DW &B00010000
Mask5:    DW &B00100000
Mask6:    DW &B01000000
Mask7:    DW &B10000000
LowByte:  DW &HFF      ; binary 00000000 1111111
LowNibl:  DW &HF       ; 0000 0000 0000 1111
Low10Bits:		DW	&H03FF
Const_LOADI:	DW	&H17
Const_CALL:		DW	&H10

Main:		CALL	PlanPath
			LOAD	PATH_ADDR
			SETTMP
	loop:	READTMP
			LOADA
			OUT		LCD
	wait:	IN		XIO
			AND		Mask2
			OUT		LEDS
			JPOS	wait
	wait2:	IN		XIO
			AND		Mask2
			OUT		LEDS
			JZERO	wait2
			CALL	INC_TMP
			JUMP	loop

PlanPath:	LOAD	PATH_ADDR
			SETTMP
			LOAD	S_Y
			ADDI	-1
			JPOS	pp1
			LOAD	E_Y
			ADDI	-1
			JPOS	pp_cross
			JUMP	pp_no_cross
	pp1:	LOAD	E_Y
			ADDI	-1
			JPOS	pp_no_cross
			JUMP	pp_cross
  pp_cross: LOAD	S_X
			ADDI	-1
			JPOS	pp_c_mvx
			LOAD	S_T 			; Turn ; move to E_Y
			MULI	90
			AND		Low10Bits
			LOAD	Const_LOADI
			SHIFT	8
		L2:	OUT		SSEG2
			JUMP	L2
			STOREA
			CALL	INC_TMP
			CALL 	pp_Add_TurnLeft
			LOAD	S_Y				; move
			SUB		E_Y
			AND		Low10Bits
			OR		Const_LOADI
			STOREA
			CALL	INC_TMP
			CALL	pp_Add_Move	
			LOADI	90	
			OR		Const_LOADI			; Turn ; move to E_X  ( LOADI 90 )
			STOREA
			CALL	INC_TMP
			CALL	pp_Add_TurnLeft
			LOAD	S_X				; move
			SUB		E_X
			AND		Low10Bits
			OR		Const_LOADI
			STOREA
			CALL	INC_TMP
			CALL	pp_Add_Move
			RETURN
  pp_c_mvx: 				; Turn ; move to x = 1
  							; move
							; Turn ; move to E_Y
							; move
							; Turn ; move to E_X
							; move
pp_no_cross: JUMP	pp_no_cross

; Increments the TMP register
; Note: this will destroy the AC
INC_TMP:	READTMP
			ADDI	1
			SETTMP
			RETURN

; Inserts a call to TurnLeft
; Note: this will destroy the AC
pp_Add_TurnLeft:	LOADI	Const_CALL ; Load the call instruction
					STOREA
					CALL	INC_TMP
					RETURN

; Inserts a call to Move
; Note: this will destroy the AC
pp_Add_Move:		LOADI	Const_CALL ; Load the call instruction
					STOREA
					CALL	INC_TMP
					RETURN

L:			JUMP	L

S_X:		DW	0
S_Y:		DW	0
S_T:		DW	0
E_X:		DW	0
E_Y:		DW	3
PATH_ADDR:	DW	&H100
ORG			&H100
PATH:		DW	1
			DW	2
			DW	3
			DW	4
			DW	5
			DW	6
			DW	7
			DW	8
			DW	9