; -----------------------------------------------------------
; Mikrokontroller alapú rendszerek házi feladat
; Készítette: Mózer József
; Neptun code: DPBR72
; Feladat leírása:
;		Belső memóriában lévő két darab 32 bites előjel nélküli egész
;		összeadása, túlcsordulás figyelése. Bemenet: a két operandus és
;		az eredmény kezdőcímei (mutatók). Kimenet: eredmény (a kapott
; 		címen), CY.
; -----------------------------------------------------------

$NOMOD51 ; a sztenderd 8051 regiszter definíciók nem szükségesek

$INCLUDE (SI_EFM8BB3_Defs.inc) ; regiszter és SFR definíciók

; Két 32 bites szám kezdőcímére (Least Significant) mutató pointerek
input1 EQU 0x0000		; 1000h-1003h-ig tart a memóriában, LS - MS
input2 EQU 0x0004		; 1004h-1007h-ig tart a memóriában, LS - MS

; A 32 bites kimenet kezdőcímére mutató pointer (Least Significant)
output EQU 0x0008

; Carry state kimentése
maxCarry EQU 0x000C

; Ugrótábla létrehozása
	CSEG AT 0
	SJMP Main

myprog SEGMENT CODE			;saját kódszegmens létrehozása
RSEG myprog 				;saját kódszegmens kiválasztása
; ------------------------------------------------------------
; Főprogram
; ------------------------------------------------------------
; Feladata: a szükséges inicializációs lépések elvégzése és a
;			feladatot megvalósító szubrutin(ok) meghívása
; ------------------------------------------------------------
Main:
	CLR IE_EA ; interruptok tiltása watchdog tiltás idejére
	MOV WDTCN,#0DEh ; watchdog timer tiltása
	MOV WDTCN,#0ADh
	SETB IE_EA ; interruptok engedélyezése

	; Tesztadatok betöltése
	MOV 0x0000, #0xFF
	MOV 0x0001, #0xFF
	MOV 0x0002, #0xFF
	MOV 0x0003, #0xFF
	MOV 0x0004, #0x01
	MOV 0x0005, #0x00
	MOV 0x0006, #0x00
	MOV 0x0007, #0x00

	; Két, a belső memóriában tárolt 32 bites operandus összeadása és memóriába mentése
	CALL LongWordAdderSubroutine

	JMP $ ; végtelen ciklusban várunk

; -----------------------------------------------------------
; Sample szubrutin
; -----------------------------------------------------------
; Funkci�: 		8 bites szám maszkolása
; Bementek:		R1 - maszkolandó szám
;			 	R2 - maszk
; Kimenetek:  	R3 - maszkolt szám
; Regisztereket módosítja:
;				A
; -----------------------------------------------------------
SampleSubroutine:
	MOV A, R1 ; csak az akkumulátor értékén tudjuk elvégezni a maszkolást, ezért töltjük az akkumulátort
	ANL A, R2 ; elvégezz�k a maszkolást
	MOV	R3, A ; tároljuk az eredményt
	RET


; -----------------------------------------------------------
; Read Operand szubrutin
; -----------------------------------------------------------
; Funkci�: 		2 32 bites szó felhozása a belső memóriából
; Bementek:		1. szó kezdőcíme (LSB first)
;			 	2. szó kezdőcíme (MSB first)
; Kimenetek:  	R3...R0 - 1. szó
;				R7...R4 - 2.szó
; Regisztereket módosítja:
;				A, R7...R0
; -----------------------------------------------------------
ReadOperandsSubroutine:
	; Két 32 bites szám a belső memóriából regiszterekbe való töltése.
	MOV R0, input1		; Első bemenet legkisebb helyiértéke
	MOV R1, input1+1
	MOV R2, input1+2
	MOV R3, input1+3		; Első bemenet legnagyobb helyiértéke
	MOV R4, input2		; Második bemenet legkisebb helyiértéke
	MOV R5, input2+1
	MOV R6, input2+2
	MOV R7, input2+3		; Második bemenet legnagyobb helyiértéke
	RET

; -----------------------------------------------------------
; Long Word Adder szubrutin
; -----------------------------------------------------------
; Funkci�: 		2 32 bites szó összeadása a belső memóriából
; Bementek:		1. szó kezdőcíme (LSB first)
;			 	2. szó kezdőcíme (MSB first)
; Kimenetek:  	R3...R0 - 1. szó
;				R7...R4 - 2.szó
; Regisztereket módosítja:
;				A, PSW, R7...R0
; -----------------------------------------------------------
LongWordAdderSubroutine:

	PUSH PSW
	MOV maxCarry, #0x00

; Elsőnek be kell tölteni a két számot a regisztereinkbe.
	CALL ReadOperandsSubroutine
; Össze kell adni őket és kimenteni az eredményt a memóriába.
; Ehhez alulról fölfelé bájtonként összeadom őket,
; a CY flag minden összeadás után való figyelembevétel mellett.
FIRST8BIT:
	MOV A, R0				; Első szám alsó 8 bitjét az akkumulátorba mozgatjuk
	ADD A, R4				; Második szám alsó 8 bitjét hozzáadjuk
	MOV output, A			; Akkumulátor tartalmát kimentjük az eredmény memóriacímére
	JNC SECOND8BIT			; Ha nincs carry, továbbmegyünk
	MOV A, R1				; ..., ha van akkor hozzáadjuk az egyik eggyel nagyobb helyiértékhez
	ADD A, #0x01			; Ez a herce-hurca itt azért van, mert az INC nem
	MOV R1, A				; 	tud flaget állítani.
	JNC SECOND8BIT
	MOV A, R2
	ADD A, #0x01
	MOV R2, A
	JNC SECOND8BIT
	MOV A, R3
	ADD A, #0x01
	MOV R3, A
	JNC SECOND8BIT
	MOV maxCarry, #0x01		; ..., ha van, jelezzük, hogy mindenképpen be kell
							;	állítani a carry flaget a szubrutin végén,
							; 	mert a teljes művelet túlcsordul.

SECOND8BIT:
	MOV A, R1
	ADD A, R5
	MOV output+1, A
	JNC THIRD8BIT
	MOV A, R2
	ADD A, #0x01
	MOV R2, A
	JNC THIRD8BIT
	MOV A, R3
	ADD A, #0x01
	MOV R3, A
	JNC THIRD8BIT
	MOV maxCarry, #0x01

THIRD8BIT:
	MOV A, R2
	ADD A, R6
	MOV output+2, A
	JNC FOURTH8BIT
	MOV A, R3
	ADD A, #0x01
	MOV R3, A
	JNC FOURTH8BIT
	MOV maxCarry, #0x01

FOURTH8BIT:
	MOV A, R3
	ADD A, R7
	MOV output+3, A

	; Carry flag beállítása, ha be kell (ha a maxCarry-n tárolt érték be lett
	; állítva egyre, akkor ha hozzáadunk FF-et, be fogja állítani a carry flaget).
	JC CFLAGNOSET
	MOV A, maxCarry
	ADD A, #0xFF

	; Ezen a ponton az eredmények ki vannak írva a megfelelő memóriatartományba
	; a megfelelő sorrendben (LSB first) és a Carry Flag is a teljes művelet
	; carryjét tartalmazza. A szubrutin így elvégezte feladatát és visszatérhet.
CFLAGNOSET:
	POP PSW

	RET

