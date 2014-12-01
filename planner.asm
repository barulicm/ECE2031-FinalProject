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
; some useful movement values
OneMeter: DW 961       ; ~1m in 1.05mm units
HalfMeter: DW 481      ; ~0.5m in 1.05mm units
TwoFeet:  DW 586       ; ~2ft in 1.05mm units
Deg90:    DW 90        ; 90 degrees in odometry units
Deg180:   DW 180       ; 180
Deg270:   DW 270       ; 270
Deg360:   DW 360       ; can never actually happen; for math only
FSlow:    DW 100       ; 100 is about the lowest velocity value that will move
RSlow:    DW -100
FMid:     DW 350       ; 350 is a medium speed
RMid:     DW -350
FFast:    DW 500       ; 500 is almost max speed (511 is max)
RFast:    DW -500

Main:		CALL	WaitForKey
			LOADI	3
			STORE	S_X
			LOADI	1
			STORE	S_Y
			LOADI	0
			STORE	S_T
			LOADI	3
			STORE	E_X
			STORE	E_Y
			CALL	PlanPath
			LOADI	&HFFFF
			OUT		LEDS
halt:		JUMP	halt

PlanPath:	LOAD	S_Y
			ADDI	-2
			JPOS	pp1
			LOAD	E_Y
			ADDI	-2
			JPOS	pp_cross
			JUMP	pp_n_cross
	pp1:	LOAD	E_Y
			ADDI	-2
			JPOS	pp_n_cross
			JUMP	pp_cross
  pp_cross: LOAD	S_X
			ADDI	-2
			JPOS	pp_c_mvx
			LOADI	4 				; Turn ; move to E_Y
			SUB		S_T
			MULI	90
			ADDI	-360
			CALL	Turn
			LOAD	S_Y				; move
			SUB		E_Y
			MUL		TwoFeet
			CALL	Forw
			LOADI	90				; Turn ; move to E_X  ( LOADI 90 )
			Call	Turn
			LOAD	E_X				; move
			SUB		S_X
			MUL		TwoFeet
			CALL	Forw
			RETURN
  pp_c_mvx: LOADI	5
  			SUB		S_T				; Turn ; move to x = 1
  			MULI	90
  			ADDI	-360
  			CALL	Turn
  			LOAD	S_X
  			ADDI	-2
  			MUL		TwoFeet
  			CALL	Forw		; move
			LOADI	90				; Turn ; move to E_Y
			CALL	Turn
			LOAD	S_Y				; move
			SUB		E_Y
			MUL		TwoFeet
			CALL	Forw
			LOADI	90
			CALL	Turn			; Turn ; move to E_X
			LOAD	E_X
			SUB		S_X
			MUL		TwoFeet
			CALL	Forw		; move
			RETURN
pp_n_cross:	LOADI	4
			SUB		S_T
			MULI	90
			ADDI	-360
			CALL	Turn
			LOAD	E_Y
			SUB		S_Y
			MUL		TwoFeet
			CALL	Forw
			LOADI	90
			CALL	Turn
			LOAD	S_X
			SUB		E_X
			MUL		TwoFeet
			CALL	Forw
			RETURN

STOP:
	Loadi	0
	OUT		LVELCMD
	OUT		RVELCMD
	OUT 	RESETPOS
	LoadI 0
	Store CurTh
	LoadI 0
	Store ChgTh
	LoadI 2
	Call  WaitAC
	Return


;-----------Update Angle---------------;
;Updates the variable ChgTh to reflect the change in Theta
;since the start of the move command. This change is used to
;maintain straight movement using Correction and achieve 
;accurate and rapid turning using TurnSpeed.
;Inputs: InAngle
;Outputs: ChgTh, Correction, TurnSpeed

UpdateAngle:
	LOAD CurTh
	Store PreTh
	IN Theta
	Store CurTh
	Sub PreTh
	Store DifTh
	ADDI -100
	JPOS C>100
	ADDI 200
	JNeg C<-100
	JUMP C~0
C>100:
	Load DifTh
	Addi -360
	Store DifTh
	Jump C~0
C<-100:
	Load DifTh
	Addi 360
	Store DifTh
	Jump C~0
C~0:
	Load ChgTh
	Add DifTh
	Store ChgTh
	Add ChgTh
	Store Correction ;Used in forward. Plus or minus (2 * delta theta)
	
	Load InAngle
	Sub ChgTh
	ADDI -400
	JPOS C-500
	Load InAngle
	Sub ChgTh
	ADDI 400
	JNeg C-500
	Load InAngle
	Sub ChgTh
	JNeg Cneg
	Jump Cpos
C-500:
	LOADI 500
	Jump Cang
Cneg:
	Store Temp
	LoadI 0
	Sub Temp
Cpos:
	ADDI 100
Cang:
	Store TurnSpeed ;Always Positive, between 0 and 500;
	return

;-----------Turn---------------;
;Turns the DE2Bot X degrees.
;Inputs: InAngle, degree either positive or negative to turn.
;NOTE: Positive degrees turns left by default. Negative turns right.
Turn:
	Store InAngle
	Call Stop
	Load InAngle
	JNEG TurnRLoop
	JPOS TurnLLoop
	Call Stop
	return

;-----------Turn Left---------------;
;Turns the DE2Bot to the left X degrees.
;Inputs: InAngle, degree either positive or negative (no difference) to turn.
TurnnLeft:
	Store InAngle
	JPos TurnLLoop ;Turning left increase theta, so InAngle must be positive.
	LoadI 0		   ;If it is not positive, it is negated.
	Sub InAngle
	Store InAngle
	Call Stop	   ;To reset variables
TurnLLoop:
	Call UpdateAngle
	Loadi 0
	Sub TurnSpeed
	Out LVELCMD
	Loadi 0
	Load TurnSpeed
	Out RVELCMD
	Load ChgTh
	Out SSEG1
	Sub InAngle
	Out SSeg2
	JNEG TurnLLoop
	; JPOS TurnRLoop
	Call Stop 
	return

	
;-----------Turn Right---------------;
;Turns the DE2Bot to the right X degrees.
;Inputs: InAngle, degree either positive or negative (no difference) to turn.
TurnnRight: 
	Store InAngle
	JNeg TurnRLoop ;Turning right decreases theta, so InAngle must be negative.
	LoadI 0		   ;If it is not negative, it is negated.
	Sub InAngle
	Store InAngle
	Call Stop 	   ;To reset variables
TurnRLoop:
	Call UpdateAngle
	Load TurnSpeed
	Out LVELCMD
	Loadi 0
	Sub TurnSpeed
	Out RVELCMD
	Load ChgTh
	Out SSeg1
	Sub InAngle
	Out SSeg2
	JPOS TurnRLoop
	; JNEG TurnLLoop ; Will add after testing. Causes the robot to reverse direction until it reaches JZero.
	Call Stop
	return

	
;-----------Forward---------------;
;Moves the robot a distance X in units of 1.05mm.
;Accepts both positve and negative inputs for forward
;and backward, respectively. Uses UpdateAngle to correct
;for deviation from straight movement.
Forw:
	Store InDist
	Call Stop	   ;To reset variables
	In LPOS
	Store StX
	Load InDist
	JNEG Backward
Onward:
	Call UpdateAngle
	LOADI 200   	;200 is the speed. Can be changed.
	Add Correction
	Out LVELCMD
	Loadi 200
	Sub Correction
	Out RVELCMD
	In LPOS
	Sub StX
	Sub InDist
	JNeg Onward
	Call Stop
	return
Backward:
	Call UpdateAngle
	LOADI -200   	;200 is the speed. Can be changed.
	Add Correction
	Out LVELCMD
	Loadi -200
	Sub Correction
	Out RVELCMD
	In LPOS
	Sub StX
	Sub InDist
	JPos Backward
	Call Stop
	return


;***************************************************************
;* Variables
;***************************************************************
Temp:     DW 0 ; "Temp" is not a great name, but can be useful
Time:	  DW 0

InAng:	  DW 0
InAngTop: DW 0
StAng:	  DW 0

InDistTop: DW 0
InDist:	  DW 0
StX:	  DW 0
StY:	  DW 0
DifY:	  DW 0
Speed:	  DW 100

;The Following variables are used for the correction of the
;Forward command and Turn command.
StartAngle:	DW 0
InAngle:  DW 0
CurTh:	  DW 0
PreTh:	  DW 0
DifTh:	  DW 0   ;Change Theta
ChgTh:	  DW 0   ;Total Change
Correction: DW 0 ;Amount to adjust by
TurnSpeed: DW 0  ;The positive rate at which to turn.
;
;

WaitForKey:		IN		XIO
				AND		Mask2
				JPOS	WaitForKey
WaitForKey2:	IN		XIO
				AND		Mask2
				JZERO	WaitForKey2
				RETURN

; Subroutine to wait (block) for 1 second
Wait1:
	OUT    TIMER
Wloop:
	IN     TIMER
	OUT    XLEDS       ; User-feedback that a pause is occurring.
	ADDI   -10         ; 1 second in 10Hz.
	JNEG   Wloop
	RETURN

; Subroutine to wait the number of counts currently in AC
WaitAC:
	STORE  WaitTime
	OUT    Timer
WACLoop:
	IN     Timer
	OUT    XLEDS       ; User-feedback that a pause is occurring.
	SUB    WaitTime
	JNEG   WACLoop
	RETURN
	WaitTime: DW 0     ; "local" variable.

S_X:		DW	0
S_Y:		DW	0
S_T:		DW	0
E_X:		DW	0
E_Y:		DW	0