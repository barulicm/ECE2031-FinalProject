org &H000

numInputs: dw 0
tempCoord: dw 0
displayCoord1: dw 0
displayCoord2: dw 0
curSwitch: dw 0

Main:
	in SWITCHES
	store curSwitch
	sub Mask1
	jzero OneC
	load curSwitch
	sub Mask2
	jzero TwoC
	load curSwitch
	sub Mask3
	jzero ThreeC
	load curSwitch
	sub Mask4
	jzero FourC
	load curSwitch
	sub Mask5
	jzero FiveC
	load curSwitch
	sub Mask6
	jzero SixC
	load Zero
	out LCD
	store tempCoord
	jump ShowCoord

OneC:
	load One
	out LCD
	store tempCoord
	jump ShowCoord
	
TwoC:
	load Two
	out LCD
	store tempCoord
	jump ShowCoord
	
ThreeC:
	load Three
	out LCD
	store tempCoord
	jump ShowCoord
	
FourC:
	load Four
	out LCD
	store tempCoord
	jump ShowCoord
	
FiveC:
	load Five
	out LCD
	store tempCoord
	jump ShowCoord
	
SixC:
	load Six
	out LCD
	store tempCoord
	jump ShowCoord

ShowCoord:
	in XIO
	and Mask2 ; pb3
	jzero SetCoord
	jump Main
	
SetCoord:
	load numInputs
	jzero setX1
	load numInputs
	addi -1
	jzero setY1
	load numInputs
	addi -2
	jzero setX2
	load numInputs
	addi -3
	jzero setY2
	load numInputs
	addi -4
	jzero setX3
	load numInputs
	addi -4
	jzero setY3
	load numInputs
	addi 1
	store numInputs
	addi -5
	jzero EndInputs
	jump Main
	
DisplayCoords:	
	load x1
	shift 12
	or displayCoord1
	store displayCoord1
	
	load y1
	shift 8
	or displayCoord1
	store displayCoord1
	
	load x2
	shift 4
	or displayCoord1
	store displayCoord1
	
	load y2
	or displayCoord1
	store displayCoord1
	out SSEG1
	
	load x3
	shift 12
	or displayCoord2
	store displayCoord2
	
	load y3
	shift 8
	or displayCoord2
	store displayCoord2
	out SSEG2
	
	load Zero
	store tempCoord

	jump Main
	
SetX1:
	load tempCoord
	store x1
	jump DisplayCoords
	
SetY1:
	load tempCoord
	store y1
	jump DisplayCoords
	
SetX2:
	load tempCoord
	store x2
	jump DisplayCoords
	
SetY2:
	load tempCoord
	store y2
	jump DisplayCoords
	
SetX3:
	load tempCoord
	store x3
	jump DisplayCoords
	
SetY3:
	load tempCoord
	store y3
	jump DisplayCoords
	

	
EndInputs:
	load One
	out LEDS
	jump EndInputs




Mask0:    DW &B00000001
Mask1:    DW &B00000010
Mask2:    DW &B00000100
Mask3:    DW &B00001000
Mask4:    DW &B00010000
Mask5:    DW &B00100000
Mask6:    DW &B01000000
Mask7:    DW &B10000000

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

XYCoordAddr: dw &H250
org &H250
x1: dw 0
y1: dw 0
x2: dw 0
y2: dw 0
x3: dw 0
y3: dw 0