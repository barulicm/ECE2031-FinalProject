org &H000

Init:
	; Always a good idea to make sure the robot
	; stops in the event of a reset.
	LOAD   Zero
	OUT    LVELCMD     ; Stop motors
	OUT    RVELCMD
	OUT    SONAREN     ; Disable sonar (optional)
	
	CALL   SetupI2C    ; Configure the I2C to read the battery voltage
	CALL   BattCheck   ; Get battery voltage (and end if too low).
	OUT    LCD         ; Display batt voltage on LCD

WaitForSafety:
	; Wait for safety switch to be toggled
	IN     XIO         ; XIO contains SAFETY signal
	AND    Mask4       ; SAFETY signal is bit 4
	JPOS   WaitForUser ; If ready, jump to wait for PB3
	IN     TIMER       ; We'll use the timer value to
	AND    Mask1       ;  blink LED17 as a reminder to toggle SW17
	SHIFT  8           ; Shift over to LED17
	OUT    XLEDS       ; LED17 blinks at 2.5Hz (10Hz/4)
	JUMP   WaitForSafety
	
WaitForUser:
	; Wait for user to press PB3
	IN     TIMER       ; We'll blink the LEDs above PB3
	AND    Mask1
	SHIFT  5           ; Both LEDG6 and LEDG7
	STORE  Temp        ; (overkill, but looks nice)
	SHIFT  1
	OR     Temp
	OUT    XLEDS
	IN     XIO         ; XIO contains KEYs
	AND    Mask2       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS   WaitForUser ; not ready (KEYs are active-low, hence JPOS)
	LOAD   Zero
	OUT    XLEDS       ; clear LEDs once ready to continue


;Get initial coords as input from switches
Main:
	load Zero
	store display1
	store display2
	
	in XIO
	and Mask2 ; pb3
	jzero SetCoord
	jump Main
	
Main1:
	in XIO
	and Mask2
	jzero Main1
m:
	in XIO
	and Mask2
	jzero SetCoord1
	jump m
	
SetCoord:
	in SWITCHES
	store Switch15to0
	
	load Switch15to0
	shift -12
	and Mask
	store x1
	
	load Switch15to0
	shift -9
	and Mask
	store y1
	
	load Switch15to0
	shift -6
	and Mask
	store x2
	
	load Switch15to0
	shift -3
	and Mask
	store y2
	
	load Switch15to0
	and Mask
	store x3
	
	load x1
	shift 12
	or display1
	store display1
	
	load y1
	shift 8
	or display1
	store display1
	
	load x2
	shift 4
	or display1
	store display1
	
	load y2
	or display1
	store display1
	out SSEG1
	
	load x3
	shift 12
	or display2
	store display2
	out SSEG2
	
	jump Main1
	
SetCoord1:
	in SWITCHES
	and Mask
	store y3
	shift 8
	or display2
	out SSEG2

;End Input Start Localization on button 2 press
WaitToStart:
	IN     TIMER       ; We'll blink the LEDs above PB2
	AND    Mask1
	SHIFT  3           ; Both LEDG4 and LEDG5
	STORE  Temp        ; (overkill, but looks nice)
	SHIFT  1
	OR     Temp
	OUT    XLEDS
	IN     XIO         ; XIO contains KEYs
	AND    Mask1       ; KEY2 mask (KEY0 is reset and can't be read)
	JPOS   WaitToStart ; not ready (KEYs are active-low, hence JPOS)
	LOAD   Zero
	OUT    XLEDS       ; clear LEDs once ready to continue

;Begin Localization
	call Localize
	call Wait1
	call Wait1

;End Localization Start Pathing
	load coordFound
	shift -4
	store S_X
	load coordFound
	and Mask4Bits
	store S_Y
	load angleFound
	store S_T
	
	load x1
	store E_X
	load y1
	store E_Y
	
	;Call planner/pather here
	call PlanPath
	load Four
	out BEEP
	loadi 6
	call WaitAC
	load Zero
	out BEEP
	
	call Localize
	
	load coordFound
	shift -4
	store S_X
	load coordFound
	and Mask4Bits
	store S_Y
	load angleFound
	store S_T
	
	load x2
	store E_X
	load y2
	store E_Y
	
	call PlanPath
	load Four
	out BEEP
	loadi 6
	call WaitAC
	load Zero
	out BEEP
	
	call Localize
	
	load coordFound
	shift -4
	store S_X
	load coordFound
	and Mask4Bits
	store S_Y
	load angleFound
	store S_T
	
	load x1
	store E_X
	load y1
	store E_Y
	
	call PlanPath
	load Four
	out BEEP
	loadi 6
	call WaitAC
	load Zero
	out BEEP
	
forever:
	jump forever
	
	
	
	
	
	
	
	
	
	
	
;--Subroutines--
;Localize Start=============================
Localize:
;Get perpendicular to a wall and measure all 4 wall distances by cells
	load origMinDist
	store minDist
	load Zero
	store minDistAngle
	store curDist0
	store curDist5
	out RESETPOS
	addi &B00100001 ; enable sonar 0,5
	out SONAREN

SpinAndPing:
	load RSlow
	out LVELCMD
	load FSlow
	out RVELCMD
	
	in THETA
	addi -190	;angle to turn
	jzero EndTurn
	jpos EndTurn
	
	in DIST0
	store curDist0
	in DIST5
	store curDist5
	sub curDist0
	jpos dist0Smaller
	jzero dist0Smaller
	jneg dist5Smaller
	
	
dist0Smaller:
	load curDist0
	sub minDist
	jpos SpinAndPing
	jzero SpinAndPing
	load curDist0
	store minDist
	in THETA
	store minDistAngle
	jump SpinAndPing
	
dist5Smaller:
	load curDist5
	sub minDist
	jpos SpinAndPing
	jzero SpinAndPing
	load curDist5
	store minDist
	in THETA
	store minDistAngle
	jump SpinAndPing
	
	
EndTurn:
	load Zero
	out LVELCMD
	out RVELCMD
	
	load minDistAngle
	call TurnToAngle
	
	load Zero
	addi &B00100001
	out SONAREN
	
	call Wait1
	
	in DIST0
	call GetDistToWall
	store t
	shift 9
	store wallDistances
	load t
	shift 12
	store display
	
	in DIST5
	call GetDistToWall
	store t
	shift 3
	or wallDistances
	store wallDistances
	load t
	shift 4
	or display
	store display
	
	
	out RESETPOS
	load Zero
	addi 270
	call TurnToAngle	;turn 90 degrees
	
	call Wait1

	in DIST0
	call GetDistToWall
	store t
	shift 6
	or wallDistances
	store wallDistances
	load t
	shift 8
	or display
	store display
	
	in DIST5
	call GetDistToWall
	store t
	or wallDistances
	store wallDistances
	load t
	or display
	store display
	
	load display
	out LCD
	
;Pass wall distances to FindCoords and output the cell and angle to sseg	
	load wallDistances
	call FindCoords
	
	load hasFoundCoord
	jzero Relocalize		;if we havent found what cell we are in localize again
	
	load coordFound
	out SSEG2
	load angleFound
	out SSEG1
	jump EndLocalize
	
Relocalize:
	load Zero
	addi 35
	call Turn
	jump Localize
	

EndLocalize:	
	load   Zero        
	out    LVELCMD
	out    RVELCMD
	out    SONAREN
	return
;Localize End=================================

;FindCoords Start=========================================
FindCoords:
	store wallDists
	
	load Zero
	store coordFound
	store angleFound
	store hasFoundCoord
	addi -1
	store numCoordsCount
	load Zero
	addi 18
	store totalNumCoords
	load Zero
	store numShifts
	addi 5
	store totalNumShifts
	load Zero
	addi &B00
	store angle
	load numCoordsCount
	
loop1: 
	load numCoordsCount
	addi 1
	store numCoordsCount
	out SSEG1
	sub totalNumCoords
	jzero loop1End
	
	load wallDistArrayAddr
	add numCoordsCount
	loada
	store curWallDist
	out LCD
	load Zero
	addi 2
	out LEDS

	
loop2:
	load numShifts
	addi 1
	store numShifts
	sub totalNumShifts
	jzero loop2End
	
	load curWallDist
	sub wallDists
	jzero foundWall
	
	load Zero
	addi 16
	out LEDS

	load curWallDist
	call RightRotate3
	store curWallDist
	load angle
	addi 1
	store angle
	addi -3
	jpos resetAng
	jump loop2
	
loop2End:
	load Zero
	store numShifts
	store angle
	jump loop1
	
loop1End:
	load Zero
	store numCoordsCount
	loadi 0
	store hasFoundCoord
	return
	
resetAng:
	load Zero
	store angle
	jump loop2
	
foundWall:
	load Zero
	addi 4
	out LEDS
	load coordArrayAddr
	add numCoordsCount
	loada
	out LCD
	store coordFound
	
	load angle
	store angleFound
	load Zero
	addi 1
	store hasFoundCoord
	load Zero
	addi 8
	out LEDS
	load angleFound
	addi 2
	store angleFound
	addi -4
	jzero angle0
	addi -1
	jzero angle1
	jump angleRet
	
angle0:
	loadi 0
	store angleFound
	jump angleRet
	
angle1:
	loadi 1
	store angleFound
	jump angleRet
	
angleRet:
	return
;FindCoords End==============================

;Right Rotate by 3 Start=====================
rotateMask: dw &B0000000000000111
origVal: dw 0
last3Bits: dw 0
shiftVal: dw 0
RightRotate3:
	store origVal
	and rotateMask
	store last3Bits
	load origVal
	shift -3
	store shiftVal
	load last3Bits
	shift 9
	or shiftVal
	return
;Right Rotate by 3 End=======================

;Turn to a specific angle Start==============
angleToTurnTo: dw 0
TurnToAngle:
	store angleToTurnTo
tta:
	in THETA
	sub angleToTurnTo
	jzero TurnComplete
	load FSlow
	out LVELCMD
	load RSlow
	out RVELCMD
	jump tta
	
TurnComplete:
	load Zero
	out LVELCMD
	out RVELCMD
	return
;Turn to a specific angle End================

;Get dist to wall in cell units Start========
Count: dw 0
Value: dw 0
GetDistToWall:
	store Value
	load Zero
	store Count
	
GetDistToWallHelper:
	load Value
	sub TwoFeet
	store Value
	load Count
	addi 1
	store Count
	load Value
	jpos GetDistToWallHelper
	jzero GetDistToWallHelper
	load Count
	addi -1
	return
;Get dist to wall in cell units End==========
	
;-----------Path Planner---------------;
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
			ADDI	2
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

;--------------Stop--------------------;
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
	Muli 4
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
	LOADI 450 ; Max turning speed
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
	LOADI 350   	;200 is the speed. Can be changed.
	Add Correction
	Out LVELCMD
	Loadi 350
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
	LOADI -350   	;200 is the speed. Can be changed.
	Add Correction
	Out LVELCMD
	Loadi -350
	Sub Correction
	Out RVELCMD
	In LPOS
	Sub StX
	Sub InDist
	JPos Backward
	Call Stop
	return

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
	
; This subroutine will get the battery voltage,
; and stop program execution if it is too low.
; SetupI2C must be executed prior to this.
BattCheck:
	CALL   GetBattLvl
	JZERO  BattCheck   ; A/D hasn't had time to initialize
	SUB    MinBatt
	JNEG   DeadBatt
	ADD    MinBatt     ; get original value back
	RETURN
; If the battery is too low, we want to make
; sure that the user realizes it...
DeadBatt:
	LOAD   Four
	OUT    BEEP        ; start beep sound
	CALL   GetBattLvl  ; get the battery level
	OUT    SSEG1       ; display it everywhere
	OUT    SSEG2
	OUT    LCD
	LOAD   Zero
	ADDI   -1          ; 0xFFFF
	OUT    LEDS        ; all LEDs on
	OUT    XLEDS
	CALL   Wait1       ; 1 second
	Load   Zero
	OUT    BEEP        ; stop beeping
	LOAD   Zero
	OUT    LEDS        ; LEDs off
	OUT    XLEDS
	CALL   Wait1       ; 1 second
	JUMP   DeadBatt    ; repeat forever
	
; Subroutine to read the A/D (battery voltage)
; Assumes that SetupI2C has been run
GetBattLvl:
	LOAD   I2CRCmd     ; 0x0190 (write 0B, read 1B, addr 0x90)
	OUT    I2C_CMD     ; to I2C_CMD
	OUT    I2C_RDY     ; start the communication
	CALL   BlockI2C    ; wait for it to finish
	IN     I2C_DATA    ; get the returned data
	RETURN

; Subroutine to configure the I2C for reading batt voltage
; Only needs to be done once after each reset.
SetupI2C:
	CALL   BlockI2C    ; wait for idle
	LOAD   I2CWCmd     ; 0x1190 (write 1B, read 1B, addr 0x90)
	OUT    I2C_CMD     ; to I2C_CMD register
	LOAD   Zero        ; 0x0000 (A/D port 0, no increment)
	OUT    I2C_DATA    ; to I2C_DATA register
	OUT    I2C_RDY     ; start the communication
	CALL   BlockI2C    ; wait for it to finish

	
BlockI2C:
	LOAD   Zero
	STORE  Temp        ; Used to check for timeout
BI2CL:
	LOAD   Temp
	ADDI   1           ; this will result in ~0.1s timeout
	STORE  Temp
	JZERO  I2CError    ; Timeout occurred; error
	IN     I2C_RDY     ; Read busy signal
	JPOS   BI2CL       ; If not 0, try again
	RETURN             ; Else return
I2CError:
	LOAD   Zero
	ADDI   &H12C       ; "I2C"
	OUT    SSEG1
	OUT    SSEG2       ; display error message
	JUMP   I2CError
	



























;Variables ==============================================
DEAD: dw &HDEAD
Temp:     DW 0 ; "Temp" is not a great name, but can be useful
Switch15to0: dw 0
x1: dw 0
y1: dw 0
x2: dw 0
y2: dw 0
x3: dw 0
y3: dw 0
display1: dw 0
display2: dw 0
Mask: dw &H007
Mask0:    DW &B00000001
Mask1:    DW &B00000010
Mask2:    DW &B00000100
Mask3:    DW &B00001000
Mask4:    DW &B00010000
Mask5:    DW &B00100000
Mask6:    DW &B01000000
Mask7:    DW &B10000000
Mask4bits: dw &H00F

NegOne:   DW -1
Zero:     DW 0
One:      DW 1
Two:      DW 2
Three:    DW 3
Four:     DW 4
Five:     DW 5
Six:      DW 6
Seven:    DW 7
Eight:    DW 8
Nine:     DW 9
Ten:      DW 10

; some useful movement values
OneMeter: DW 961       ; ~1m in 1.05mm units
HalfMeter: DW 481      ; ~0.5m in 1.05mm units
TwoFeet:  DW 450       ; ~2ft in 1.05mm units
SixFeet: DW 1758
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

MinBatt:  DW 130       ; 13.0V - minimum safe battery voltage
I2CWCmd:  DW &H1190    ; write one i2c byte, read one byte, addr 0x90
I2CRCmd:  DW &H0190    ; write nothing, read one byte, addr 0x90

S_X:		DW	0
S_Y:		DW	0
S_T:		DW	0
E_X:		DW	0
E_Y:		DW	0

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

minDist: dw &H7fff
origMinDist: dw &H7fff
minDistAngle: dw 0
curDist0: dw 0
curDist5: dw 0
wallDistances: dw 0

wallDists: dw 0
numCoordsCount: dw -1
totalNumCoords: dw 18
numShifts: dw 0
totalNumShifts: dw 5
angle: dw &B00

hasFoundCoord: dw 0
coordFound: dw 0
angleFound: dw 0

curWallDist: dw 0
wallDistArrayAddr: dw &H350
org &H350
c11: dw &H0603 ; --3300
c21: dw &H0681 ; --3201
c31: dw &h0242 ; --1102
c41: dw &h0203 ; --1003
c12: dw &h04C8 ; --2310
c22: dw &h0489 ; --2211
c32: dw &h004A ; --0112
c42: dw &h000B ; --0013
c13: dw &h0310 ; --1420
c23: dw &h02D1 ; --1321
c33: dw &h0282 ; --1202
c43: dw &h0243 ; --1103
c53: dw &h0204 ; --1004
c14: dw &h0158 ; --0530
c24: dw &h0119 ; --0431
c34: dw &h00CA ; --0312
c44: dw &h008B ; --0213
c54: dw &h004C ; --0114
c64: dw &h0005 ; --0005

coordArrayAddr: dw &H370
org &H370
C11a: dw &B00010001
C21a: dw &B00100001
C31a: dw &B00110001
C41a: dw &B01000001
C12a: dw &B00010010
C22a: dw &B00100010
C32a: dw &B00110010
C42a: dw &B01000010
C13a: dw &B00010011
C23a: dw &B00100011
C33a: dw &B00110011
C43a: dw &B01000011
C53a: dw &B01010011
C14a: dw &B00010100
C24a: dw &B00100100
C34a: dw &B00110100
C44a: dw &B01000100
C54a: dw &B01010100
C64a: dw &B01100100

display: dw 0
t: dw 0