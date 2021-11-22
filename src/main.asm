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
input1 EQU 0x1000		; 1000h-1003h-ig tart a memóriában, LS - MS
input2 EQU 0x1004		; 1004h-1007h-ig tart a memóriában, LS - MS

; A 32 bites kimenet kezdőcímére mutató pointer (Least Significant)
output EQU 0x1008

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
END

; -----------------------------------------------------------
; Read Operand szubrutin
; -----------------------------------------------------------
; Funkci�: 		2 32 bites szó felhozása a belső memóriából
; Bementek:		1. szó kezdőcíme (LSB first)
;			 	2. szó kezdőcíme (MSB first)
; Kimenetek:  	R3...R0 - 1. szó
;				R7...R4 - 2.szó
; Regisztereket módosítja:
;				A
; -----------------------------------------------------------
ReadOperandsSubroutine:
	; Két 32 bites szám a belső memóriából regiszterekbe való töltése.
	MOV R0, ptr1		; Első bemenet legkisebb helyiértéke
	MOV R1, ptr1+1
	MOV R2, ptr1+2
	MOV R3, ptr1+3		; Első bemenet legnagyobb helyiértéke
	MOV R4, ptr2		; Második bemenet legkisebb helyiértéke
	MOV R5, ptr2+1
	MOV R6, ptr2+2
	MOV R7, ptr2+3		; Második bemenet legnagyobb helyiértéke

	RET

END

LongWordAdderSubroutine:
; Elsőnek be kell tölteni a két számot a regisztereinkbe.
	CALL ReadOperandsSubroutine
; Össze kell adni őket és kimenteni az eredményt a memóriába.
; Ehhez alulról fölfelé bájtonként összeadom őket,
; a CY flag minden összeadás után való figyelembevétel mellett.
	MOV A, R0		; Első szám alsó 8 bitjét az akkumulátorba mozgatjuk
	ADD R4			; Második szám alsó 8 bitjét hozzáadjuk
	MOV output, A	; Akkumulátor tartalmát kimentjük az eredmény memóriacímére
	MOV A, 0x00		; Akkumulátor kinullázása
	ADD A, C		; Carry hozzáadása

	MOV A, R1		; Első szám alsó 8 bitjét az akkumulátorba mozgatjuk
	ADD R5			; Második szám alsó 8 bitjét hozzáadjuk
	MOV output+1, A	; Akkumulátor tartalmát kimentjük az eredmény memóriacímére
	MOV A, 0x00		; Akkumulátor kinullázása
	ADD A, C		; Carry hozzáadása

	MOV A, R2		; Első szám alsó 8 bitjét az akkumulátorba mozgatjuk
	ADD R6			; Második szám alsó 8 bitjét hozzáadjuk
	MOV output+2, A	; Akkumulátor tartalmát kimentjük az eredmény memóriacímére
	MOV A, 0x00		; Akkumulátor kinullázása
	ADD A, C		; Carry hozzáadása

	MOV A, R3		; Első szám alsó 8 bitjét az akkumulátorba mozgatjuk
	ADD R7			; Második szám alsó 8 bitjét hozzáadjuk
	MOV output+3, A	; Akkumulátor tartalmát kimentjük az eredmény memóriacímére

	; Ezen a ponton az eredmények ki vannak írva a megfelelő memóriatartományba
	; a megfelelő sorrendben (LSB first) és a Carry Flag is a teljes művelet
	; carryjét tartalmazza. A szubrutin így elvégezte feladatát és visszatérhet.

	RET


END
