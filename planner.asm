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

PlanPath:	LOAD	S_Y
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
  pp_cross: LOADI	&H1
			STORE	cross_v
			JUMP END
			LOAD	S_X
			ADDI	-1
			JPOS	pp_c_mvx
			; move to E_Y
			; move to E_X
  pp_c_mvx: ; move to x = 1
			; move to E_Y
			; move to E_X
pp_no_cross: LOADI &H0
			 STORE	cross_v
			 JUMP END
			 
END:	LOAD	cross_v
		OUT		LCD
			
L:			JUMP L

S_X:		DW	0
S_Y:		DW	0
S_T:		DW	0
E_X:		DW	0
E_Y:		DW	0
cross_v:	DW	0
PATH_ADDR:	DW	&H100
ORG			&H100
PATH:		DW	0
			DW	0
			DW	1
			DW	2