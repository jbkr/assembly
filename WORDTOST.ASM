
;----------------------------|
;    BEGIN STACK SEGMENT     |
;----------------------------|
MYSTACK    SEGMENT STACK

           DB      64 DUP ('STACK!!!')

MYSTACK    ENDS
;----------------------------|
;     END STACK SEGMENT      |
;----------------------------|


;----------------------------|
;     BEGIN DATA SEGMENT     |
;----------------------------|
MYDATA     SEGMENT     PUBLIC
           PUBLIC      LRXY,CRLF
LRXY       DW      184FH
CRLF       DB      0DH,0AH,'$'

MYDATA     ENDS
;----------------------------|
;      END DATA SEGMENT      |
;----------------------------|

EXTRN      CLRSCR:PROC,GOTOXY:PROC,WRITE:PROC,WRITELN:PROC
EXTRN      BYTETOSTR:PROC,WORDTOSTR:PROC,DISPID:PROC,TRYEGA:PROC,EGACOLOR:PROC,OLDBORDS:PROC

;----------------------------|
;     BEGIN CODE SEGMENT     |
;----------------------------|
MYCODE     SEGMENT     PUBLIC

           ASSUME CS:MYCODE,DS:MYDATA
MAIN       PROC

START:
           MOV  AX,MYDATA
           MOV  DS,AX

           CALL DISPID
           CALL BYTETOSTR
           MOV  DX,SI
           CALL WRITE

           MOV  AH,4CH
           MOV  AL,0
           INT  21H


MAIN       ENDP

MYCODE     ENDS

;----------------------------|
;      END CODE SEGMENT      |
;----------------------------|

           END START

