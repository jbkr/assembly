MYSTACK        SEGMENT        STACK
               DB             64 DUP         ('STACK!!!')
MYSTACK        ENDS

MYDATA         SEGMENT
HELLO          DB     "HELLO,WORLD!$"
MYDATA         ENDS

MYCODE         SEGMENT
               ASSUME DS:MYDATA,CS:MYCODE
MAIN           PROC

START:
               MOV  AX,MYDATA
               MOV  DS,AX
               LEA  DX,HELLO
               MOV  AH,09H
               INT  21H
               MOV  AH,4CH
               MOV  AL,0
               INT  21H



MAIN           ENDP
MYCODE         ENDS
               END START