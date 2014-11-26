; SimpleRobotProgram.asm
; Created by Kevin Johnson
; (no copyright applied; edit freely, no attribution necessary)
; This program does basic initialization of the DE2Bot
; and provides an example of some peripherals.

; Section labels are for clarity only.


ORG        &H000       ;Begin program at x000
;***************************************************************
;* Initialization
;***************************************************************
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

;***************************************************************
;* Main code
;***************************************************************
Main: ; "Real" program starts here.


;-----------Test Code for Turn and Forw---------------;
	OUT    RESETPOS
	Call Stop
	loadi &H001
	out LEDS   
        LOADI 540
        out LCD
        CALL Turn
        LOADI 30
        Call WaitAC
        LOAD TwoFeet
        Call Forw
        LOADI 90
        out LCD
        CALL Turn
        LOADI 30
        Call WaitAC
        LOAD TwoFeet
        Call Forw
        LOADI 540
        out LCD
        CALL Turn
        LOADI 30
        Call WaitAC
        LOAD TwoFeet
        Call Forw
        LOADI -90
        CALL Turn
        LOADI 30
        Call WaitAC
        LOAD TwoFeet
        CALL Forw
        LOADI -630
        CALL Turn
        LOADI 30
        Call WaitAC
        LOADI 30
        Call WaitAC
        Jump Die
;-----------End Test Code for Turn and Forw---------------;
        
        
        
        
loop:	load FMid
		out LVELCMD
		out RVELCMD
		in XPOS
		out LCD

		sub TwoFeet
		sub TwoFeet
		out SSEG1
		jneg loop
		
		loadi &H000
		OUT    RESETPOS
		

		
loop2:	load RSlow
		out RVELCMD
		load FSlow
		out LVELCMD
		in THETA
		out LCD
		sub Deg270
		jzero end2
		jump loop2
		
end2:		loadi &H000
		out LVELCMD
		out RVELCMD
		
		





Die:
; Sometimes it's useful to permanently stop execution.
; This will also catch the execution if it accidentally
; falls through from above.
	LOAD   Zero         ; Stop everything.
	OUT    LVELCMD
	OUT    RVELCMD
	OUT    SONAREN
	LOAD   DEAD         ; An indication that we are dead
	OUT    SSEG2
Forever:
	JUMP   Forever      ; Do this forever.
DEAD: DW &HDEAD

	
;***************************************************************
;* Subroutines
;***************************************************************

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
	RETURN
	
; Subroutine to block until I2C device is idle
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

; Subroutine to send AC value through the UART,
; formatted for default base station code:
; [ AC(15..8) | AC(7..0) | \lf ]
; Note that special characters such as \lf are
; escaped with the value 0x1B, thus the literal
; value 0x1B must be sent as 0x1B1B, should it occur.
UARTSend:
	STORE  UARTTemp
	SHIFT  -8
	ADDI   -27   ; escape character
	JZERO  UEsc1
	ADDI   27
	OUT    UART_DAT
	JUMP   USend2
UEsc1:
	ADDI   27
	OUT    UART_DAT
	OUT    UART_DAT
USend2:
	LOAD   UARTTemp
	AND    LowByte
	ADDI   -27   ; escape character
	JZERO  UEsc2
	ADDI   27
	OUT    UART_DAT
	RETURN
UEsc2:
	ADDI   27
	OUT    UART_DAT
	OUT    UART_DAT
	RETURN
	UARTTemp: DW 0

UARTNL:
	LOAD   NL
	OUT    UART_DAT
	SHIFT  -8
	OUT    UART_DAT
	RETURN
	NL: DW &H0A1B

STOP:
	Loadi	0
	OUT		LVELCMD
	OUT		RVELCMD
	OUT 	RESETPOS
	Call    ResetAngle
	Return

;Load a desired angle greater than 0;
;Call Turn Left
TurnLeft:	;Theta goes Up
	STORE 	InAngTop
	IN TIMER
	Store Time
TLT:
	LOADI	-200
	OUT		LVELCMD
	LOADI	200
	OUT		RVELCMD
	IN TIMER
	SUB	TIME
	ADDI -10
	JNEG TLT
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
	STORE 	InAngTop
	IN TIMER
	Store Time
TRT:
	LOADI	200
	OUT		LVELCMD
	LOADI	-200
	OUT		RVELCMD
	IN TIMER
	SUB	TIME
	ADDI -10
	JNEG TRT
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
	
	IN		Theta
	STORE   StAng
	ADDI 	-180
	JNEG	TR2
TR1:
	LOADI	200
	OUT		LVELCMD
	LOADI	-200
	OUT		RVELCMD
	;Call Sonar
	LOADI 11
	OUT LCD
	IN 		Theta
	OUT SSEG1
	ADD		InAng
	SUB	    StAng
	JNEG	TREnd
	JUMP	TR1
TR2:
	LOADI	200
	OUT		LVELCMD
	LOADI	-200
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
	In XPOS
	Store StX

F1:
	IN THETA
	STORE StAng
	LOADI 180
	SUB	StAng
	JNEG FY
FR:
	LOAD DifY
	Sub 360
	Store DifY
FY:
	Call UpdateAngle
	LOAD Speed
	ADD Correction
	OUT LVELCMD
	LOAD Speed
	SUB Correction
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
	ADDI -100
	Store DifTh
	Jump C~0
C<-100:
	ADDI 100
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
	LOAD InAngle
	Sub ChgTh
	JPos Cpos
	Store Temp
	LoadI 0
	Sub Temp
Cpos:
	ADDI 100
Cang:
	Store TurnSpeed ;Always Positive, between 0 and 500;
	return


;-----------Reset Angle---------------;
;Sets CurTh and ChgTh to zero
ResetAngle:
	LoadI 0
	Store CurTh
	LoadI 0
	Store ChgTh
	Return

;-----------Turn---------------;
;Turns the DE2Bot X degrees.
;Inputs: InAngle, degree either positive or negative to turn.
;NOTE: Positive degrees turns left by default. Negative turns right.
Turn:
	Store InAngle
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
	Load TurnSpeed
	Out LVELCMD
	Loadi 0
	Sub TurnSpeed
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
	Out RVELCMD
	Loadi 0
	Sub TurnSpeed
	Out LVELCMD
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
	JNeg Backward
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


;***************************************************************
;* Constants
;* (though there is nothing stopping you from writing to these)
;***************************************************************
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

MinBatt:  DW 130       ; 13.0V - minimum safe battery voltage
I2CWCmd:  DW &H1190    ; write one i2c byte, read one byte, addr 0x90
I2CRCmd:  DW &H0190    ; write nothing, read one byte, addr 0x90

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
