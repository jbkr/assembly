;----------------------------|
;         MY LIBRARY         |
;----------------------------|


;----------------------------|
;     BEGIN DATA SEGMENT     |
;----------------------------|
MYDATA     SEGMENT     PUBLIC
CRLF       DB          0DH,0AH,'$'
DIGITS     DB          '0123456789ABCDEF'
ORIGINTBL  DW          0B000H
           DW          0B000H
           DW          0B800H
           DW          0B000H
           DW          0B800H
           DW          0B000H
           DW          0B000H
           DW          0B000H
           DW          0B800H
           DW          0B000H
           DW          0B800H
           DW          0B000H
           DW          0B800H
MYDATA     ENDS
;----------------------------|
;      END DATA SEGMENT      |
;----------------------------|


;----------------------------|
;  BEGIN PROCEDURE SECTION   |
;----------------------------|
MYCODE     SEGMENT     PUBLIC

           ASSUME CS:MYCODE,DS:MYDATA
           PUBLIC WRITE,WRITEC,NEWLINE,WRITELN,EXIT
           PUBLIC BYTETOSTR,WORDTOSTR,DIGITS,ORIGINTBL,DISPID,VIDORG

WRITE      PROC
           MOV  AH,09H       ; WRITE STRING SERVICE
           INT  21H          ; CALL DOS
           RET
WRITE      ENDP

WRITEC     PROC
           MOV  AH,02H
           INT  21H
           RET
WRITEC     ENDP

NEWLINE    PROC
           LEA  DX,CRLF
           CALL WRITE
           RET
NEWLINE    ENDP

WRITELN    PROC
           CALL WRITE
           CALL NEWLINE
           RET
WRITELN    ENDP

BYTETOSTR  PROC
           MOV  DI,AX
           AND  DI,000FH
           LEA  BX,DIGITS
           MOV  AH,BYTE PTR [BX+DI]
           MOV  [SI+1],AH
           XOR  AH,AH
           MOV  DI,AX
           SHR  DI,1
           SHR  DI,1
           SHR  DI,1
           SHR  DI,1
           MOV  AH,BYTE PTR [BX+DI]
           MOV  [SI],AH
           RET
BYTETOSTR  ENDP

WORDTOSTR  PROC
           MOV  CX,AX
           XCHG AH,AL
           CALL BYTETOSTR
           ADD  SI,2
           MOV  AX,CX
           CALL BYTETOSTR
           RET
WORDTOSTR  ENDP

DISPID     PROC
           MOV  AH,1AH
           XOR  AL,AL
           INT  10H
           CMP  AL,1AH
           JNE  TRYEGA
           MOV  AL,BL
           RET
TRYEGA:    MOV  AH,12H
           MOV  BX,10H
           CMP  BX,10H
           JE   OLDBOARDS
           CMP  BH,0
           JE   EGACOLOR
           MOV  AL,5
           RET
EGACOLOR:  MOV  AL,4
           RET
OLDBOARDS: INT  11H
           NOT  AL
           TEST AL,30H
           JNZ  CGA
           MOV  AL,1
           RET
CGA:       MOV  AL,2
           RET
DISPID     ENDP

VIDORG     PROC
           XOR  AH,AH
           MOV  DI,AX
           SHL  DI,1
           LEA  BX,ORIGINTBL
           MOV  AX,[BX+DI]
           RET
VIDORG     ENDP

EXIT       PROC
           MOV  AH,4CH       ; EXIT PROGRAM SERVICE
           MOV  AL,0         ; ERRORLEVEL
           INT  21H          ; CALL DOS
EXIT       ENDP

MYCODE     ENDS

;----------------------------|
;   END PROCEDURE SECTION    |
;----------------------------|

           END

