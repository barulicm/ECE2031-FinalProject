org &H000

Switch15to0: dw 0
x1: dw 0
y1: dw 0
x2: dw 0
y2: dw 0
x3: dw 0
y3: dw 0
display1: dw 0
display2: dw 0


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
	jump l
	
l:
	load One
	out LEDS
	jump l
	
	
	
	
Mask: dw &H007
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