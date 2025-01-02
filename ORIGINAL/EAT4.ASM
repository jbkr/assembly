;---------------------------------------------------------------
;                             EAT4.ASM
;    Backhanded advertising program, with external references
;
;                                      by Jeff Duntemann
;                                      MASM/TASM
;                                      Last update 12/27/89
;---------------------------------------------------------------

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
MyData     SEGMENT PUBLIC
           PUBLIC LRXY,CRLF

LRXY       DW      184FH ; 18H = 24D; 4FH = 79D; 0-based XY of LR screen corner


TextPos    DW      ?
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

; Note that the following items are external to EAT4.ASM, and must
;   be linked from the external file VIDLIB.OBJ.  Assemble VIDLIB.ASM
;   first to VIDLIB.OBJ before attempting the link.

           EXTRN GotoXY:PROC,Write:PROC,Writeln:PROC,ClrScr:PROC

MyCode     SEGMENT PUBLIC


           assume CS:MyCode,DS:MyData
Main       PROC

Start:     ; This is where program execution begins:
           mov  AX,MyData   ; Set up our own data segment address in DS
           mov  DS,AX       ; Can't load segment reg. directly from memory

           call ClrScr      ; Clear the full display

           mov  TextPos, 0914H   ; 0914H = X @ 20, Y @ 9

           mov  DX,TextPos  ; TextPos contains X,Y position values
           call GotoXY      ; Position cursor
           lea  DX,Eat1     ; Load offset of Eat1 string into DX
           call Write       ;   and display it

           mov  DX,TextPos  ; Re-use text position variable
           mov  DH,10       ; Put new Y value into DH
           call GotoXY      ; Position cursor
           lea  DX,Eat2     ; Load offset of Ear2 string into DX
           call Writeln     ;   and display it

           mov  AH,4CH      ; Terminate process DOS service
           mov  AL,0        ; Pass this value back to ERRORLEVEL
           int  21H         ; Control returns to DOS

Main       ENDP

MyCode     ENDS

;----------------------------|
;      END CODE SEGMENT      |
;----------------------------|

           END Start    ; The procedure named Start becomes the main program
