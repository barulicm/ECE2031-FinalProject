org &H000
num: dw &H0603 ;1,1 angle 0
num1: dw &H06C0 ;1,1 angle 1
num2: dw &H00D8 ;1,1 angle 2
num3: dw &H001B ;1,1 angle 3
num4: dw &H0840 ;5,3 ang: 2
Main:
	load num4
	call FindCoords
	
	load hasFoundCoord
	addi -1
	jneg coordNotFound
	
	load coordFound
	out SSEG2
	load angleFound
	out SSEG1
	jump Stop

coordNotFound:
	load One
	out LEDS

Stop:
	jump Stop
	

;--Subroutines--
;FindCoords Start=========================================
FindCoords:
	store wallDists
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
	;store MultiplyB
	;out LCD
	;load Zero
	;addi 90
	;store MultiplyA
	;call Multiply
	;load MultiplyB
	;out LCD
	;call Wait1
	;call Wait1
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

	
; Multiply Start=============================
; try to put smaller value into B when calling
MultiplyA: dw 0
MultiplyB: dw 0
multTemp: dw 0
Multiply:
	load MultiplyB
	out SSEG1
	load MultiplyA
	out SSEG2
	call Wait1
	call Wait1
	call Wait1
	load MultiplyB
	store multTemp
multiplyHelper:
	load multTemp
	addi -1
	store multTemp
	jneg multiplyEnd
	load MultiplyA
	add MultiplyA
	store MultiplyA
	jump multiplyHelper
multiplyEnd:
	load MultiplyA
	return
; Multiply End===============================
	
Wait1:
	OUT    TIMER
Wloop:
	IN     TIMER
	ADDI   -10         ; 1 second in 10Hz.
	JNEG   Wloop
	RETURN	


Zero: dw 0
One:      DW 1
DEAD: dw &HDEAD
	
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

SSEG1:    EQU &H04  ; seven-segment display (4-digits only)
SSEG2:    EQU &H05  ; seven-segment display (4-digits only)
LCD:      EQU &H06  ; primitive 4-digit LCD display
LEDS:     EQU &H01  ; red LEDs
TIMER:    EQU &H02  ; timer, usually running at 10 Hz

