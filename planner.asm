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

Main:		CALL	PlanPath
			LOADI	&HFFFF
			OUT		SSEG2
halt:		JUMP	halt

PlanPath:	LOAD	S_Y
			ADDI	-1
			JPOS	pp1
			LOAD	E_Y
			ADDI	-1
			JPOS	pp_cross
			JUMP	pp_n_cross
	pp1:	LOAD	E_Y
			ADDI	-1
			JPOS	pp_n_cross
			JUMP	pp_cross
  pp_cross: LOAD	S_X
			ADDI	-1
			JPOS	pp_c_mvx
			LOAD	S_T 			; Turn ; move to E_Y
			MULI	90
			CALL	TurnLeft
			LOAD	E_Y				; move
			SUB		S_Y
			CALL	Forward1
			LOADI	90				; Turn ; move to E_X  ( LOADI 90 )
			Call	TurnLeft
			LOAD	E_X				; move
			SUB		S_X
			CALL	Forward1
			RETURN
  pp_c_mvx: LOADI	&HFF
  			OUT		SSEG1
  			LOAD	S_T				; Turn ; move to x = 1
  			ADDI	-1
  			MULI	90
  			CALL	TurnLeft
  			LOAD	S_X
  			ADDI	-1
  			CALL	Forward1		; move
			LOADI	90				; Turn ; move to E_Y
			CALL	TurnLeft
			LOAD	E_Y				; move
			SUB		S_Y
			CALL	Forward1
			LOADI	90
			CALL	TurnLeft		; Turn ; move to E_X
			LOAD	E_X
			SUB		S_X
			CALL	Forward1		; move
			RETURN
pp_n_cross:	LOAD	S_T
			MULI	90
			CALL	TurnLeft
			LOAD	E_X
			SUB		S_X
			CALL	Forward1
			LOADI	90
			CALL	TurnLeft
			LOAD	E_Y
			SUB		S_Y
			CALL	Forward1
			RETURN

STOP:
	Loadi	0
	OUT		LVELCMD
	OUT		RVELCMD
	RETURN

;Load a desired angle greater than 0;
;Call Turn Left
TurnLeft:	;Theta goes Uup
	OUT		LCD
	LOADI	&HA
	OUT		SSEG2
	CALL	WaitForKey
	RETURN
	STORE 	InAngTop
LoopTL:		;Breaks turn into 160 degree segments
	ADDI 	-160
	JNEG	LastTL
	STORE 	InAngTop
	LOADI   160
	Call    TR
	LOAD	InAngTop
	JUMP	LoopTL
LastTL:		;Last turn for angle is less than 160
	ADDI	160
	CALL	TL
	CALL    STOP
	RETURN


TL:
	STORE	InAng
	LOADI 0
	OUT TIMER
	IN		Theta
	STORE   StAng
	ADDI 	-180
	JPOS	TL2
TL1:
	LOADI	-200
	OUT		LVELCMD
	LOADI	200
	OUT		RVELCMD
	;Call Sonar
	LOADI 10
	OUT LCD
	IN TIMER
	ADDI -10
	JNEG TL1
	IN 		Theta
	OUT SSEG1
	SUB		InAng
	SUB	    StAng
	JPOS	TLEnd
	JUMP	TL1
TL2:
	LOADI	-200
	OUT		LVELCMD
	LOADI	200
	OUT		RVELCMD
	;Call Sonar
	LOADI 11
	OUT LCD
	IN TIMER
	ADDI -10
	JNEG TL2
	IN 		Theta
	OUT SSEG1
	ADDI	-180
	JPOS	TL2N
	ADDI	360
TL2N:
	ADDI	180
	SUB		InAng
	SUB	    StAng
	JPOS	TLEnd
	JUMP	TL2
	
TLEnd:
	Return

;Load a desired angle greater than 0
;Call Turn Right
TurnRight:	;Theta goes down.
	OUT		LCD
	LOADI	&HB
	OUT		SSEG2
	CALL	WaitForKey
	RETURN
	STORE 	InAngTop
LoopTR:
	ADDI 	-160
	JNEG	LastTR
	STORE 	InAngTop
	LOADI   160
	Call    TR
	LOAD	InAngTop
	JUMP	LoopTR
LastTR:	
	ADDI	160
	CALL	TR
	CALL    STOP
	RETURN


TR:
	STORE	InAng
	LOADI 0
	OUT TIMER
	IN		Theta
	STORE   StAng
	ADDI 	-180
	JNEG	TR2
TR1:
	LOADI	100
	OUT		LVELCMD
	LOADI	-100
	OUT		RVELCMD
	;Call Sonar
	LOADI 11
	OUT LCD
	IN TIMER
	ADDI -10
	JNEG TR1
	IN 		Theta
	OUT SSEG1
	ADD		InAng
	SUB	    StAng
	JNEG	TREnd
	JUMP	TR1
TR2:
	LOADI	100
	OUT		LVELCMD
	LOADI	-100
	OUT		RVELCMD
	;Call Sonar
	LOADI 11
	OUT LCD
	IN TIMER
	ADDI -10
	JNEG TR2
	IN 		Theta
	OUT SSEG1
	
	ADDI	-180
	JNEG	TR2N
	ADDI	-360
TR2N:
	ADDI	180
	ADD		InAng
	SUB	    StAng
	JNEG	TREnd
	JUMP	TR2
	
TREnd:
	Return
	
	
Forward1:
	OUT		LCD
	LOADI	&HC
	OUT		SSEG2
	CALL	WaitForKey
	RETURN
	Store   InDistTop
	LOADI	100
	STORE	Speed
	Jump	Forward
Forward2:
	Store   InDistTop
	LOADI	250
	STORE	Speed
	Jump	Forward
Forward3:
	Store   InDistTop
	LOADI	500
	STORE	Speed
	Jump	Forward
Forward:

	LOADI	0
	OUT    RESETPOS
F1:
	IN THETA
	STORE DifY
	ADDI -180
	JNEG FY
FR:
	LOAD DifY
	Sub 360
	Store DifY
FY:
	LOAD Speed
	;ADD DifY
	OUT LVELCMD
	LOAD Speed
	;SUB DifY
	OUT RVELCMD
	;Call Sonar
	LOADI 12
	OUT LCD
	In XPOS
	OUT SSEG1
	SUB StX
	SUB InDistTop
	OUT SSEG2
	JPOS FEnd
	JUMP F1
	
FEnd:
	Call Stop
	Return
	
WaitForKey:
	IN		XIO
	AND		Mask2
	JPOS	WaitForKey
w2:	IN		XIO
	AND		Mask2
	JZERO	w2
	RETURN
;***************************************************************
;* Variables
;***************************************************************
Temp:     DW 0 ; "Temp" is not a great name, but can be useful

InAng:	  DW 0
InAngTop: DW 0
StAng:	  DW 0

InDistTop: DW 0
InDist:	  DW 0
StX:	  DW 0
StY:	  DW 0
DifY:	  DW 0
Speed:	  DW 100


S_X:		DW	0
S_Y:		DW	0
S_T:		DW	0
E_X:		DW	0
E_Y:		DW	0