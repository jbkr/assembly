;===========================================================================
;
; V I D B L A S T  -  Blast character pattern into memory, & add attributes
;
;===========================================================================
;
;     by Jeff Duntemann      25 November 1988
;
; VIDBLAST is written to be called from Turbo Pascal V4.0 or 5.0 using the
; EXTERNAL machine-code procedure convention.
;
; Declare the procedure itself as external using this declaration:
;
; PROCEDURE VidBlast(ScreenEnd,StoreEnd : ScrnPtr;
;                    ScreenX,ScreenY    : Integer;
;                    ULX,ULY            : Integer;
;                    Width,Height       : Integer;
;                    Attribute          : Byte;
;                    DeadLines          : Integer);
;           EXTERNAL;
;
; What we have here is a means of moving a rectangular region of a text
; screen (either the visible screen or a screen stored on the heap) from
; the screen array to a storage array.  It is the text analog of a BITBLT
; (BIT BLock Transfer.)  It is an essential component of any windowing or
; menuing system that expects to update the display faster than the eyes
; can follow.
;
; It works like this:  ScreenEnd and StoreEnd are the two pointers pointing
; to the screen array and the storage array, respectively.  If the destination
; pointer is NIL, VidBlast returns without taking any action.  ScreenX and
; ScreenY are the dimensions of the screen in use.  ULX and ULY are the
; coordinates of the upper left hand corner of the rectangular region to be
; written to on the destination screen.  Width and Height are the dimensions
; of the region to be written to on the destination screen.
;
; During the blast itself, the attribute byte passed in the Attribute
; parameter is written to the screen along with the character information
; pointed to by the source pointer.  In effect, this means we do a byte-sized
; read from the source character data, but a word-sized write to the screen.
;
;
; There is a critical difference between a screen array and a storage array.
; A screen array has an implied structure of rows and columns, dictated by
; the ScreenX and ScreenY parameters.  A rectangular region within such an
; array is not one contiguous block of elements, but rather a number of
; blocks of elements separated by some quantity of storage not included in
; the block transfer.  Additionally, the rectangular region begins at some
; offset from the beginning of the screen array.  A storage buffer, by
; contrast, is a simple contiguous array of character/attribute pairs without
; any consideration for the row/column structure of a visible screen.  We
; do it this way for the utmost speed and most efficient use of memory.
;
; Allocation of both screen and storage arrays, of course, is the
; responsibility of the calling logic.  HINT: Use GetMem and FreeMem
; rather than New and Dispose.
;
;
; To reassemble/relink WORDBLT:
;
; Assemble this file with MASM or TASM:  "C>MASM VIDBLAST;"
; (The semicolon is unnecessary with TASM.)
;
;========================
;
; STACK PROTOCOL
;
; This creature puts lots of things on the stack.  Study closely:
;

ONSTACK STRUC
OLDBP   DW ?    ;Caller's BP value saved on the stack
RETADDR DD ?    ;Full 32-bit return address.  (This is a FAR proc!)
DEADLNS DW ?    ;Number of lines of dead space to insert between blasted lines
ATTR    DW ?    ;Attribute to be added to blasted pattern
WHEIGHT DW ?    ;HEIGHT OF WINDOW TO BE MOVED
WWIDTH  DW ?    ;WIDTH OF WINDOW TO BE MOVED
ULY     DW ?    ;Y COORDINATE OF UPPER LEFT CORNER OF WINDOW
ULX     DW ?    ;X COORDINATE OF UPPER LEFT CORNER OF WINDOW
YSIZE   DW ?    ;GENNED MAX Y DIMENSION OF CURRENT VISIBLE SCREEN
XSIZE   DW ?    ;GENNED MAX X DIMENSION OF CURRENT VISIBLE SCREEN
STORE   DD ?    ;32-BIT POINTER TO STORE BUFFER
SCREEN  DD ?    ;32-BIT POINTER TO SCREEN BUFFER
ENDMRK  DB ?    ;DUMMY FIELD FOR SIZE CALCULATION PURPOSES
ONSTACK ENDS


CODE    SEGMENT PUBLIC
        ASSUME  CS:CODE
        PUBLIC  VIDBLAST

VIDBLAST PROC    FAR
         PUSH    BP                      ;SAVE CALLER'S BP VALUE
         MOV     BP,SP                   ;SP BECOMES NEW VALUE OF BP
         PUSH    DS                      ;SAVE CALLER'S DS VALUE

;-------------------------------------------------------------------------
; The increment between window lines must be calculated and stored in DX.
; This includes adding additional instances of the increment for "dead
; space" to avoid lines between forms, things like that.
;-------------------------------------------------------------------------

        MOV     DX,[BP].XSIZE
        SUB     DX,[BP].WWIDTH          ;INCREMENT IS SCREEN WIDTH MINUS
                                        ; WINDOW WIDTH
        SHL     DX,1                    ;INCREMENT IS IN WORDS.  MUST
                                        ; CONVERT TO BYTES FOR USE; HERE
                                        ; WE MULTIPLY IT BY TWO BY
                                        ; SHIFTING LEFT ONE BIT
        MOV     CX,[BP].DeadLns         ;Put deadspace line count in CX
        CMP     CX,0                    ;Is there any dead space needed?
        JE      Inset                   ;If not, go calculate the inset

        MOV     BX,[BP].XSIZE           ;Mov screen width into BX
        SHL     BX,1                    ;Multiply by two for attributes
AddDed: ADD     DX,BX                   ;Add a screen width to increment
        LOOP    AddDed                  ;Dec CX & loop backn if CX <> 0


;-------------------------------------------------------------------------
;  HERE WE CALCULATE THE INSET FROM THE START OF THE VISIBLE
;    SCREEN BUFFER TO THE FIRST BYTE OF THE WINDOW TO BE BLITTED
;-------------------------------------------------------------------------

Inset:  PUSH    DX                      ;Save increment; MUL trashes DX
        MOV     CX,[BP].XSIZE           ;SCREEN MAX X DIMENSION IN CX
        MOV     BX,[BP].ULX             ;UL CORNER X DIMENSION IN BX
        MOV     AX,[BP].ULY             ;UL CORNER Y DIMENSION IN AX
        SUB     BX,1                    ;CORRECT FOR ORIGIN AT 1 NOT 0
        SUB     AX,1                    ;CORRECT FOR ORIGIN AT 1 NOT 0
        MUL     CX                      ;MULTIPLY SCREEN WIDTH BY UL Y
        ADD     AX,BX                   ; AND ADD INDENT FROM LEFT MARGIN
        MOV     CX,AX
        SHL     CX,1


;-------------------------------------------------------------------------
;  NEXT WE HAVE TO FILL THE SOURCE AND DESTINATION SEGMENT AND OFFSET
;    REGISTERS, DEPENDING ON WHICH WAY DATA WILL BE FLOWING.  DS:SI IS
;    ALWAYS THE SOURCE ADDRESS, AND ES:DI IS ALWAYS THE DESTINATION
;    ADDRESS.  TOWARD DETERMINES WHETHER DATA WILL BE FLOWING TOWARD THE
;    SCREEN BUFFER OR TOWARD THE STORAGE BUFFER.  MUCH OF THIS CODE IS
;    CHECKING TO SEE IF EITHER POINTER WAS SET TO NIL, I.E. BOTH WORDS
;    SET TO ZERO.  IF EITHER POINTER WAS PASSED AS NIL, WORDBLT RETURNS
;    WITHOUT TAKING FURTHER ACTION.
;-------------------------------------------------------------------------

        LES     DI,[BP].SCREEN          ;SCREEN IS DESTINATION: ES:DI
        LDS     SI,[BP].STORE           ;STORAGE BUFFER IS SOURCE: DS:SI

        MOV     AX,ES                   ;CAN'T DO A CMP ON A SEGMENT REG.
        CMP     AX,0                    ;A NIL POINTER IS A SEGMENT AND
        JNE     AddIn                   ; OFFSET BOTH SET TO 0
        CMP     DI,0                    ;RETURN WITHOUT ACTING IF BOTH
        JE      GOHOME                  ; ARE SET TO 0

AddIn:  ADD     DI,CX                   ;SCREEN END MUST ADD INSET VALUE
                                        ; TO OFFSET PORTION OF POINTER
        POP     DX                      ;Restore saved increment to DX

;-------------------------------------------------------------------------
;  THE POINTERS ARE NOW READY FOR WORK.  NOW WE SET UP FOR THE LOOPS.
;    THE DIRECTION FLAG MUST BE SET FOR AUTOINCREMENT DURING LOOPS.
;-------------------------------------------------------------------------

        MOV     AX,[BP].WHEIGHT         ;HEIGHT IS COUNT OF LINE MOVES
        MOV     BX,[BP].Attr            ;Move attribute byte into BX
        XCHG    BH,BL                   ;Put attribute info into high byte

;-------------------------------------------------------------------------
;  DOLINE IS THE LABEL FOR THE OUTER LOOP.  THIS LOOP PERFORMS HEIGHT
;    STOSW OPS WHICH EACH MOVE WIDTH WORDS FROM SOURCE TO DESTINATION
;-------------------------------------------------------------------------

DOLINE: MOV     CX,[BP].WWIDTH          ;COUNT VALUE FOR INNER LOOP IS WIDTH

DoChar: MOV     BL,[SI]                 ;Bring source byte into BL
        MOV     ES:[DI],BX              ;Move WORD QUANTITY to ES:DI
        INC     SI                      ;Bump SI to next byte
        INC     DI                      ;Bump DI *by two* to next word
        INC     DI
        LOOP    DoChar                  ;Repeat inner loop until CX is zero

        ADD     DI,DX                   ;ADD DESTINATION INCREMENT TO DI
        DEC     AX                      ;AX IS HEIGHT; I.E. OUTER LOOP COUNTER
        JNZ     DOLINE                  ;AND LOOP UNTIL AX IS ZERO

;-------------------------------------------------------------------------
;  WHEN THE OUTER LOOP IS FINISHED, THE WORK IS DONE.  RESTORE REGISTERS
;    AND GO HOME.
;-------------------------------------------------------------------------

GOHOME: POP     DS                      ;RESTORE CALLER'S DS
        MOV     SP,BP                   ;RESTORE PRIOR STACK POINTER & BP
        POP     BP                      ; IN CONVENTIONAL RETURN
        RET     ENDMRK-RETADDR-4

VIDBLAST ENDP
CODE     ENDS
         END
