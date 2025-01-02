;---------------------------------------------------------------
;                             EAT.ASM
;                Backhanded advertising program
;
;                                      by Jeff Duntemann
;                                      MASM/TASM
;                                      Last update 3/5/89
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
CRLF       DB      0DH,0AH,'$'

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

           lea  DX,Eat1     ; Load offset of Eat1 message string into DX
           mov  AH,09H      ; Select DOS service 09H: Print String
           int  21H         ; Call DOS

           lea  DX,CRLF     ; Load offset of CRLF string into DX
           mov  AH,09H      ; Select DOS service 09H: Print String
           int  21H         ; Call DOS

           mov  AH,4CH      ; Terminate process DOS service
           mov  AL,0        ; Pass this value back to ERRORLEVEL
           int  21H         ; Control returns to DOS

Main       ENDP

MyProg     ENDS

;----------------------------|
;      END CODE SEGMENT      |
;----------------------------|

           END Start
