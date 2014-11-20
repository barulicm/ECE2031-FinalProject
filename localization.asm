org &H000

Main:
	load Zero
	addi &B011000000011 ;wall distances 3,0,0,3 +x cw = coord: 1,1 ang: 0
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
	load DEAD
	out LCD

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
	sub totalNumCoords
	jzero loop1End
	
	load wallDistArrayAddr
	add numCoordsCount
	loada
	store curWallDist
	
loop2:
	load numShifts
	addi 1
	store numShifts
	sub totalNumShifts
	jzero loop2End
	
	load curWallDist
	sub wallDists
	jzero foundWall
	
	load curWallDist
	call RightRotate3
	store curWallDist
	load angle
	addi 1
	store angle
	addi 3
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
	load coordArrayAddr
	add numCoordsCount
	loada
	store coordFound
	
	load angle
	store MultiplyB
	loadi 90
	store MultiplyA
	call Multiply
	store angleFound
	loadi 1
	store hasFoundCoord
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
Multiply:
multiplyHelper:
	load multiplyB
multLoop:
	addi -1
	jneg multiplyEnd
	load multiplyA
	add multiplyB
	store multiplyA
	jump multiplyHelper
multiplyEnd:
	load MultiplyA
	return
; Multiply End===============================
	
	
Zero: dw 0
DEAD: dw &HDEAD
	
wallDists: dw 0
numCoordsCount: dw 0
totalNumCoords: dw 19
numShifts: dw 0
totalNumShifts: dw 4
angle: dw &B01

hasFoundCoord: dw 0
coordFound: dw 0
angleFound: dw 0

curWallDist: dw 0
wallDistArrayAddr: dw &H200
org &H200
c11: dw &B011011000000 ; --3300
c21: dw &B011010000001 ; --3201
c31: dw &B001001000010 ; --1102
c41: dw &B001000000011 ; --1003
c12: dw &B010011001000 ; --2310
c22: dw &B010010001001 ; --2211
c32: dw &B000001001010 ; --0112
c42: dw &B000000001011 ; --0013
c13: dw &B001100010000 ; --1420
c23: dw &B001011010001 ; --1321
c33: dw &B001010000010 ; --1202
c43: dw &B001001000011 ; --1103
c53: dw &B001000000100 ; --1004
c14: dw &B000101011000 ; --0530
c24: dw &B000100011001 ; --0431
c34: dw &B000011001010 ; --0312
c44: dw &B000010001011 ; --0213
c54: dw &B000001001100 ; --0114
c64: dw &B000000000101 ; --0005

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