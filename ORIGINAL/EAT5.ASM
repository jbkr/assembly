;---------------------------------------------------------------
;                             EAT5.ASM
;   Backhanded advertising program, full screen, with macros
;
;                                      by Jeff Duntemann
;                                      MASM/TASM
;                                      Last update 12/27/89
;---------------------------------------------------------------

INCLUDE MYLIB.MAC               ; Load in screen control macro library

;----------------------------|
;    BEGIN STACK SEGMENT     |
;----------------------------|
MYSTACK    SEGMENT STACK        ; STACK word ensures loading of SS by DOS

           DB      64 DUP ('STACK!!!') ; This reserves 512 bytes for the stack

MYSTACK    ENDS
;----------------------------|
;     END STACK SEGMENT      |
;----------------------------|


;----------------------------|
;     BEGIN DATA SEGMENT     |
;----------------------------|
MyData     SEGMENT

LRXY       DW      184FH ; 18H = 24D; 4FH = 79D; 0-based XY of LR screen corner

VidOrigin  DD      0B8000000H   ; Change to 0B0000000H if you have a mono CRT!
Eat1       DB      "Eat at Joe's..."
Eat1Length EQU $-Eat1
Eat2       DB      "...ten million flies can't ALL be wrong!"
Eat2Length EQU $-Eat2
CRLF       DB      0DH,0AH

MyData     ENDS
;----------------------------|
;      END DATA SEGMENT      |
;----------------------------|

;----------------------------|
;     BEGIN CODE SEGMENT     |
;----------------------------|

MyProg     SEGMENT

           assume CS:MyProg,DS:MyData
Main       PROC

Start:     ; This is where program execution begins:
           mov  AX,MyData   ; Set up our own data segment address in DS
           mov  DS,AX       ; Can't load segment reg. directly from memory

           Clear VidOrigin,07B0H,4000  ; Replace B0 with 20 for space clear

           GotoXY 14H,09H              ; Position cursor
           Write Eat1,Eat1Length       ;  and display first text line

           GotoXY 14H,0AH              ; Position cursor
           Writeln Eat2,Eat2Length     ;  and display second text line

           mov  AH,4CH      ; Terminate process DOS service
           mov  AL,0        ; Pass this value back to ERRORLEVEL
           int  21H         ; Control returns to DOS

Main       ENDP

MyProg     ENDS

;----------------------------|
;      END CODE SEGMENT      |
;----------------------------|

           END Start    ; The procedure named Start becomes the main program
