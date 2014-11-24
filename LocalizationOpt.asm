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

	
Main:
;Get perpendicular to a wall and measure all 4 wall distances by cells
	load Zero
	out RESETPOS
	addi &B00100001 ; enable sonar 0
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
	

;	load Zero
;	call TurnToAngle
	
	
;Pass wall distances to FindCoords and output the cell and angle to sseg	
	load wallDistances
	call FindCoords
	
	
	load coordFound
	out SSEG2
	load angleFound
	out SSEG1
	jump Stop

	
Stop:	
	load   Zero        
	out    LVELCMD
	out    RVELCMD
	out    SONAREN
	load   DEAD
	out    LEDS
Forever:
	jump   Forever
	
	
	
;--Subroutines--
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
	jpos resetAngle
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
	
resetAngle:
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
	

DEAD: dw &HDEAD
Temp:     DW 0 ; "Temp" is not a great name, but can be useful

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

minDist: dw &H7fff
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
wallDistArrayAddr: dw &H200
org &H200
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

coordArrayAddr: dw &H220
org &H220
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