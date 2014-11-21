org &H000

Main:
	load Zero
	addi &B00101101 ; enable sonars 0,2,3,5
	out SONAREN

GetPerp:	
	load DIST0
	sub NoReading
	jzero NoPing
	
	load DIST2
	sub NoReading
	jzero NoPing
	
	load DIST3
	sub NoReading
	jzero NoPing
	
	load DIST5
	sub NoReading
	jzero NoPing
	jump PerpToWall 

NoPing:
	load FSlow
	out LVELCMD
	load RSlow
	out RVELCMD
	jump GetPerp

PerpToWall:
	load Zero
	out LVELCMD
	out RVELCMD
	
	load DIST0
	call GetDistToWall
	shift 12
	or WallDistances
	store WallDistances
	out LCD
	
	load DIST2
	call GetDistToWall
	shift 8
	or WallDistances
	store WallDistances
	out LCD
	
	load DIST5
	call GetDistToWall
	shift 4
	or WallDistances
	store WallDistances
	out LCD
	
	out    RESETPOS
turning:	
	load RSlow
	out RVELCMD
	load FSlow
	out LVELCMD
	in THETA
	sub Deg270
	jpos turning
;turned 90degs

	load DIST5
	call GetDistToWall
	or WallDistances
	store WallDistances
	out LCD
	
End:
	jump End


;Subroutines

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



	
WallDistances: dw 0

Zero:     DW 0
TwoFeet:  DW 586       ; ~2ft in 1.05mm units
NoReading: dw &H7FFF
FSlow:    DW 100       ; 100 is about the lowest velocity value that will move
RSlow:    DW -100
Deg90:    DW 90        ; 90 degrees in odometry units
Deg270:   DW 270       ; 270

LCD:      EQU &H06  ; primitive 4-digit LCD display
THETA:    EQU &HC2  ; Current rotational position of robot (0-359)
LVELCMD:  EQU &H83  ; left wheel velocity command (write only)
RVELCMD:  EQU &H8B  ; ...
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
RESETPOS: EQU &HC3  ; write anything here to reset odometry to 0