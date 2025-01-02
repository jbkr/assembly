;---------------------------------------------------------------
;                          SHOWCHAR.ASM
;       Demonstration of STOSW to disjoint areas of memory
;       through the display of an ASCII table direct to the
;       video refresh buffer
;
;                                      by Jeff Duntemann
;                                      MASM/TASM
;                                      Last update 12/14/91
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

VidOrigin  DD      0B0000000H   ; Change to 0B0000000H if you have a mono CRT!
CRLF       DB      0DH,0AH

ScrnWidth  EQU     80        ; Width of the screen in characters
LineLen    EQU     64        ; Length of one line of the ASCII table
LinesDown  EQU      4        ; Number of lines down to start ASCII table

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
           mov    AX,MyData    ; Set up our own data segment address in DS
           mov    DS,AX        ; Can't load segment reg. directly from memory

           Clear  VidOrigin,0720H,4000  ; Clear full video buffer to spaces

           les    DI,DWORD PTR VidOrigin   ; Put vid seg in ES & offset in DI
           add    DI,ScrnWidth*LinesDown*2 ; Start table display down a ways
           mov    CX,256      ; There are 256 chars in the ASCII set
           mov    AX,0700H    ; Start with char 0, attribute 7

DoLine:    mov    BL,LineLen  ; Each line will consist of 64 characters
DoChar:    stosw              ; Note that there's no REP prefix!
           jcxz   AllDone     ; When the full set is printed, quit
           inc    AL          ; Bump the character value in AL up by 1
           dec    BL          ; Decrement the line counter by one
           loopnz DoChar      ; Go back & do another char until BL goes to 0
           add    DI,(ScrnWidth - LineLen)*2 ; Move DI to start of next line
           jmp    DoLine      ; Start display of the next line

AllDone:   GotoXY 0,12        ; Move hardware cursor down below char. table
           mov    AH,4CH      ; Terminate process DOS service
           mov    AL,0        ; Pass this value back to ERRORLEVEL
           int    21H         ; Control returns to DOS

Main       ENDP

MyProg     ENDS

;----------------------------|
;      END CODE SEGMENT      |
;----------------------------|

           END Start    ; The procedure named Start becomes the main program
