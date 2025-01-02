;---------------------------------------------------------------
;                          INFO.ASM
;     Utility to determine and report system parameters
;
;                                      by Jeff Duntemann
;                                      MASM/TASM
;                                      Last update 12/26/89
;---------------------------------------------------------------

INCLUDE MACRO.MAC
;INCLUDE MYLIB.MAC               ; Load in macro library

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

;---------------------------------------------------------------
; DISPLAY INFORMATION VARIABLES
;
; The following block of variables all relate to the video
; system and are initialized by the VidCheck procedure:
;---------------------------------------------------------------
DispType   DB      0       ; Code for display adapter type
VidOrigin  DW      0       ; Offset for FAR pointer to refresh buffer
VidSegment DW      0B000H  ; Segment of installed display buffer
VisibleX   DB      80      ; Number of columns on screen
VisibleY   DB      25      ; Number of lines on screen
VidBufSize DW      4000    ; Default to 25 X 80 X 2 (char & attribute)
FontSize   DB      8       ; Either 8, 14, or 16; default to 8
BordName   DW      ?       ; NEAR pointer to name string of installed board
; 18H = 24D; 4FH = 79D; Combined 0-based X,Y of 80 x 25 screen LR corner:
LRXY       DW      184FH

;---------------------------------------------------------------
; DISPLAY ADAPTER INFORMATION LOOKUP TABLE
;
; This is the lookup table containing information on all legal
; display adapters.  The first field in each element is a 26-
; character string containing a brief description of the
; adapter.  The next field is the segment of the video refresh
; buffer.  The last three fields are the number of screen lines
; an adapter displays when the 8-pixel, 14-pixel, and 16-pixel
; fonts are loaded, respectively.  Note that not all adapters
; support all fonts, but a screen line count is given for all
; three fonts for all adapter types.  Illegal combinations will
; not be accessed.
;---------------------------------------------------------------
VidInfoTbl DB      'No adapter identified      '    ; Code 0
           DW      0B000H
           DB      25,25,25
           DB      'Monochrome Display Adapter '    ; Code 1
           DW      0B000H
           DB      25,25,25
           DB      'Color Graphics Adapter     '    ; Code 2
           DW      0B800H
           DB      25,25,25
           DB      'Code 3: Undefined          '    ; Code 3
           DW      0B000H
           DB      25,25,25
           DB      'EGA with color monitor     '    ; Code 4
           DW      0B800H
           DB      43,25,25
           DB      'EGA with mono monitor      '    ; Code 5
           DW      0B000H
           DB      43,25,25
           DB      'Code 6: Undefined          '    ; Code 6
           DW      0B000H
           DB      25,25,25
           DB      'VGA with mono monitor      '    ; Code 7
           DW      0B000H
           DB      50,27,25
           DB      'VGA with color monitor     '    ; Code 8
           DW      0B800H
           DB      50,27,25
           DB      'Code 9: Undefined          '    ; Code 9
           DW      0B000H
           DB      25,25,25
           DB      'MCGA with digital color    '    ; Code 0AH
           DW      0B800H
           DB      25,25,25
           DB      'MCGA with monochrome       '    ; Code 0BH
           DW      0B000H
           DB      25,25,25
           DB      'MCGA with analog color     '    ; Code 0CH
           DW      0B800H
           DB      25,25,25

Digits     DB      '0123456789ABCDEF' ; Lookup table for numeric/string conv.

;---------------------------------------------------------------
; These two variables are screen-clear "atoms" useable by the
; Clear macro.  The high byte is the display attribute, while
; the low byte is the character with which Clear fills the
; video refresh buffer to clear the screen.
;---------------------------------------------------------------
HToneAtom  DW      07B0H          ; Clears screen to halftone pattern
ClearAtom  DW      0720H          ; Clears screen to blanks

;---------------------------------------------------------------
; This is where all predefined string variables are stored.
;---------------------------------------------------------------
CRLF       DB      0DH,0AH        ; Newline string
IDString   DB      '>>>INFO V1.0'
LIDString  EQU     $-IDString
AuthorStr  DB      '   by Jeff Duntemann'
LAuthorStr EQU     $-AuthorStr
VidIDStr   DB      '   The installed video board is: '
LVidIDStr  EQU     $-VidIDStr
OrgIDStr   DB      '   The segment of the video refresh buffer is: '
LOrgIDStr  EQU     $-OrgIDStr
FontSzStr  DB      '   The size of the current text font is: '
LFontSzStr EQU     $-FontSzStr
ScrnLnStr  DB      '   The number of lines currently on the screen is: '
LScrnLnStr EQU     $-ScrnLnStr
BufSizStr  DB      '   The size of the refresh buffer in bytes is: '
LBufSizStr EQU     $-BufSizStr
DigitStr   DB      '       '
LDigitStr  EQU     $-DigitStr

MyData     ENDS
;----------------------------|
;      END DATA SEGMENT      |
;----------------------------|

;----------------------------|
;     BEGIN CODE SEGMENT     |
;----------------------------|
MyProg     SEGMENT

           ASSUME CS:MyProg,DS:MyData
Main       PROC

START:
           mov  AX,MyData     ; Set up our own data segment address in DS
           mov  DS,AX         ; Can't load segment reg. directly from memory
           CLEAR
           LEA  DX,IDSTRING
           MOV  AH,40H
           MOV  BX,0001H
           MOV  CX,LIDSTRING
           INT  21H
           LEA  DX,CRLF
           MOV  AH,40H
           MOV  BX,0001H
           MOV  CX,2
           INT  21H
           LEA  DX,AUTHORSTR
           MOV  AH,40H
           MOV  BX,0001H
           MOV  CX,LAUTHORSTR
           INT  21H
           LEA  DX,CRLF
           MOV  AH,40H
           MOV  BX,0001H
           MOV  CX,2
           INT  21H
           LEA  DX,CRLF
           MOV  AH,40H
           MOV  BX,0001H
           MOV  CX,2
           INT  21H
           LEA  DX,VIDIDSTR
           MOV  AH,40H
           MOV  BX,0001H
           MOV  CX,LVIDIDSTR
           INT  21H
           CALL DISPID
           MOV  DISPTYPE,AL
           MOV  VIDORIGIN,AX
           MOV  CL,5
           SHL  VIDORIGIN,CL
           LEA  DX,VIDINFOTBL
           ADD  DX,VIDORIGIN
           MOV  VIDORIGIN,DX
           MOV  AH,40H
           MOV  BX,0001H
           MOV  CX,27
           INT  21H
           LEA  DX,CRLF
           MOV  AH,40H
           MOV  BX,0001H
           MOV  CX,2
           INT  21H
           LEA  DX,ORGIDSTR
           MOV  AH,40H
           MOV  BX,0001H
           MOV  CX,LORGIDSTR
           INT  21H
           MOV  BX,VIDORIGIN
           ADD  BX,27
           MOV  AX,[BX]
           CALL WORD2STR
           SUB  SI,2
           MOV  BYTE PTR [SI+4],'H'
           MOV  DX,SI
           MOV  AH,40H
           MOV  BX,0001H
           MOV  CX,5
           INT  21H










           mov  AH,4CH        ; Terminate process DOS service
           mov  AL,0          ; Pass this value back to ERRORLEVEL
           int  21H           ; Control returns to DOS

Main       ENDP


;---------------------------------------------------------------
;   Byte2Str  --  Converts a byte passed in AL to a string at
;                 DS:SI
;   Last update 3/8/89
;
;   1 entry point:
;
;   Byte2Str:
;      Caller must pass:
;      AL : Byte to be converted
;      DS : Segment of destination string
;      SI : Offset of destination string
;
;      This routine converts 8-bit values to 2-digit hexadecimal
;      string representations at DS:SI.
;---------------------------------------------------------------

Byte2Str   PROC
           mov DI,AX                ; Duplicate byte in DI
           and DI,000FH             ; Mask out high 12 bits of DI
           mov BX,OFFSET Digits     ; Load offset of Digits into DI
           mov AH,BYTE PTR [BX+DI]  ; Load digit from table into AH
           mov [SI+1],AH            ;   and store digit into string
           xor AH,AH                ; Zero out AH
           mov DI,AX                ; And move byte into DI
           shr DI,1                 ; Shift high nybble of byte to
           shr DI,1                 ;   low nybble
           shr DI,1
           shr DI,1
           mov AH,BYTE PTR [BX+DI]  ; Load digit from table into AH
           mov [SI],AH              ;   and store digit into string
           ret                      ; We're done--go home!
Byte2Str   ENDP


;---------------------------------------------------------------
;   Word2Str  --  Converts a word passed in AX to a string at
;                 DS:SI
;   Last update 3/8/89
;
;   1 entry point:
;
;   Word2Str:
;      Caller must pass:
;      AX : Word to be converted
;      DS : Segment of destination string
;      SI : Offset of destination string
;---------------------------------------------------------------

Word2Str   PROC
           mov  CX,AX       ; Save a copy of convertee in CX
           xchg AH,AL       ; Swap high and low AX bytes to do high first
           call Byte2Str    ; Convert AL to string at DS:SI
           add  SI,2        ; Bump SI to point to second 2 characters
           mov  AX,CX       ; Reload convertee into AX
           call Byte2Str    ; Convert AL to string at DS:SI
           ret              ; And we're done!
Word2Str   ENDP


;---------------------------------------------------------------
;   VidCheck  --  Identifies display board & display parameters
;   Last update 3/16/89
;
;   1 entry point:
;
;   VidCheck:
;      Caller need pass no parameters.
;      VidCheck identifies the installed display board by
;      calling DispID.  It then calculates numerous display
;      information values, which it then stores in the block
;      of display information variables in the data segment.
;---------------------------------------------------------------

VidCheck   PROC
           ; First task is to figure out which board is on the bus:
           call DispID        ; Ask BIOS for adapter code; returns in AL
           mov  DispType,AL   ; Store display adapter code in DispType

           ; Next we determine the font size currently in force:
           cmp  AL,0AH        ; See if board is an MCGA
           jl   TryOld        ; If less than code 0AH, it's not an MCGA
           mov  FontSize,16   ; MCGA supports *only* 16 pixel text font
           jmp  GetName       ; Jump ahead to look up adapter name string
TryOld:    cmp  DispType,1    ; Is the display adapter code 1, for MDA?
           jne  TryCGA        ; If not, go test for CGA code 2
           mov  FontSize,14   ; MDA uses *only* 14-pixel text font
           jmp  GetName       ; Jump ahead to look up adapter name string
TryCGA:    cmp  DispType,2    ; Is the display adapter code 2, for CGA?
           jne  TryVGA        ; If not, go test for EGA/VGA font size
           mov  FontSize,8    ; CGA uses *only* 8-pixel text font
           jmp  GetName       ; Jump ahead to look up adapter name string
TryVGA:    mov  AH,11H        ; Select VIDEO Get Font Information subservice
           mov  AL,30H        ;   requires AH = 11H and AL = 30H
           mov  BH,0          ; 0 = Get info about current font
           int  10H           ; Call VIDEO
           mov  FontSize,CL   ; Font size in pixels is returned in CL

           ; Next we get the name string for the board from the info table:
GetName:   mov  AL,DispType   ; Load display adapter code into AL
           xor  AH,AH         ; Zero AH so we don't copy trash into DI
           mov  DI,AX         ; Copy AX (with code in AL) into DI
           mov  CL,5          ; We must shift the code 5 bits to mult. by 32
           shl  DI,CL         ; Multiply code by 32 to act as table index
           lea  BX,VidInfoTbl ; Load address of origin table into BX
           mov  BordName,BX   ; Save pointer to video info. table in BordName
           add  Bordname,DI   ; Add offset into table to right element

           ; Next we get the refresh buffer segment from the table:
           mov  AX,[BX+DI+27] ; Index into table past name string to segment
           mov  VidSegment,AX ; Store segment from table to VidSegment variable

           ; Here we calculate the number of lines on-screen from font size:
           xor  AH,AH         ; Make sure AH has no trash in it
           mov  AL,FontSize   ; Load the font size in pixels into AL
           cmp  AL,8          ; Is it the 8-pixel font?
           jne  Try14         ; If not, try the 14-pixel font
           mov  AL,1          ; The 8-pixel font is table offset 1
           jmp  ReadLns       ; Jump ahead to read screen lines from table
Try14:     cmp  AL,14         ; Is it the 14-pixel font?
           jne  Do16          ; If not, it has to be the 16-pixel font
           mov  AL,2          ; The 14-pixel font is table offset 2
           jmp  ReadLns       ; Jump ahead to read screen lines from table
Do16:      mov  AL,3          ; The 16-pixel font is table offset 3
ReadLns:   add  DI,AX         ; Add font size offset to table element offset
           mov  AL,[BX+DI+28] ; Load the screen lines value from the table
           mov  VisibleY,AL   ;  and store it in the VisibleY variable
           mov  AH,VisibleX   ; Load the screen columns value to AH
           xchg AH,AL         ; Exchange AH & AL for 0-basing
           dec  AL            ; Subtract one from column count for 0-basing
           dec  AH            ; Subtract one from line count for zero-basing
           mov  LRXY,AX       ; And store 0-based X,Y word into LRXY variable

           ; Finally, we calculate the size of the refresh buffer in bytes:
           mov  AL,VisibleY   ; We multiply screen lines time screen columns
           mul  VisibleX      ;  times 2 (for attributes) to get buffer size
           shl  AX,1          ; Multiply lines * columns by 2
           mov  VidBufSize,AX ; Store refresh buffer size in VidBufSize

           ret                ; Return to caller
VidCheck   ENDP


;---------------------------------------------------------------
;   DispID  --  Identifies the installed display adapter
;   Last update 3/8/89
;
;   1 entry point:
;
;   DispID:
;      Caller passes no parameters
;      Routine returns a code value in AX.
;      The codes are these:
;      0 : Adapter is unknown; recommend aborting
;      1 : MDA (Monochrome Display Adapter)
;      2 : CGA (Color Graphics Adapter)
;
;---------------------------------------------------------------

DispID     PROC
           mov  AH,1AH      ; Select PS/2 Identify Adapter Service
           xor  AL,AL       ; Select Get Combination Code Subservice (AL=0)
           int  10H         ; Call VIDEO
           cmp  AL,1AH      ; If AL comes back with 1AH, we have a PS/2
           jne  TryEGA      ; If not, jump down to test for the EGA
           mov  AL,BL       ; Put Combination Code into AL
           ret              ;   and go home!
TryEGA:    mov  AH,12H      ; Select EGA Alternate Function
           mov  BX,10H      ; Select Get Configuration Information subservice
           int  10H         ; Call VIDEO
           cmp  BX,10H      ; If BX comes back unchanged, EGA is *not* there
           je   OldBords    ; Go see whether it's an MDA or CGA
           cmp  BH,0        ; If BH = 0, it's an EGA/color combo
           je   EGAColor    ;   otherwise it's EGA/mono
           mov  AL,5        ; Store code 5 for EGA mono
           ret              ;   and go home!
EGAColor:  mov  AL,4        ; Store code 4 for EGA color
           ret              ;   and go home!
OldBords:  int  11H         ; Call Equipment Configuration interrupt
           and  AL,30H      ; Mask out all but bits 4 & 5
           cmp  AL,30H      ; If bits 4 & 5 are both =1, it's an MDA
           jne  CGA         ;   otherwise it's a CGA
           mov  AL,1        ; Store code 1 for MDA
           ret              ;   and go home!
CGA:       mov  AL,2        ; Store code 2 for CGA
           ret              ;   and go home!
DispID     ENDP


MyProg     ENDS

;----------------------------|
;      END CODE SEGMENT      |
;----------------------------|

           END Start    ; The procedure named Start becomes the main program
