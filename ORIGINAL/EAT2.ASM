;---------------------------------------------------------------
;                             EAT2.ASM
;          Backhanded advertising program, with procedures
;
;                                      by Jeff Duntemann
;                                      MASM/TASM
;                                      Last update 12/27/89
;---------------------------------------------------------------

;----------------------------|
;    BEGIN STACK SEGMENT     |
;----------------------------|
MyStack    SEGMENT STACK        ; STACK word ensures loading of SS by DOS

           DB      64 DUP ('STACK!!!') ; This reserves 512 bytes for the stack

MyStack    ENDS
;----------------------------|
;     END STACK SEGMENT      |
;----------------------------|


;----------------------------|
;     BEGIN DATA SEGMENT     |
;----------------------------|
MyData     SEGMENT

Eat1       DB      "Eat at Joe's...",'$'
Eat2       DB      "...ten million flies can't ALL be wrong!",'$'
CRLF       DB      0DH,0AH,'$'

MyData     ENDS
;----------------------------|
;      END DATA SEGMENT      |
;----------------------------|

;----------------------------|
;     BEGIN CODE SEGMENT     |
;----------------------------|
MyCode     SEGMENT

           assume CS:MyCode,DS:MyData
Main       PROC

Start:     ; This is where program execution begins:
           mov  AX,MyData   ; Set up our own data segment address in DS
           mov  DS,AX       ; Can't load segment reg. directly from memory

           lea  DX,Eat1     ; Load offset of Eat1 string into DX
           call Writeln     ;   and display it
           lea  DX,Eat2     ; Load offset of Ear2 string into DX
           call Writeln     ;   and display it

           mov  AH,4CH      ; Terminate process DOS service
           mov  AL,0        ; Pass this value back to ERRORLEVEL
           int  21H         ; Control returns to DOS

;----------------------------------------|
;           PROCEDURE SECTION            |
;----------------------------------------|

Write      PROC
           mov AH,09H        ; Select DOS service 9: Print String
           int 21H           ; Call DOS
           ret               ; Return to the caller
Write      ENDP


Writeln    PROC
           call Write           ; Display the string proper through Write
           mov DX,OFFSET CRLF   ; Load address of newline string to DS:DX
           call Write           ; Display the newline string through Write
           ret                  ; Return to the caller
Writeln    ENDP

;----------------------------------------|
;        END PROCEDURE SECTION           |
;----------------------------------------|

Main       ENDP

MyCode     ENDS

;----------------------------|
;      END CODE SEGMENT      |
;----------------------------|

           END Start    ; The procedure named Start becomes the main program
