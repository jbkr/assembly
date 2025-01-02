MYDATA        SEGMENT     PUBLIC

              PUBLIC DIGITS

DIGITS        DB        '0123456789ABCDEF'

MYDATA        ENDS


MYCODE        SEGMENT     PUBLIC
              ASSUME DS:MYDATA,CS:MYCODE

              PUBLIC BYTETOSTR,WORDTOSTR

BYTETOSTR     PROC

              MOV  DI,AX
              AND  DI,000FH
              MOV  BX,OFFSET DIGITS
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

BYTETOSTR     ENDP

WORDTOSTR     PROC
              MOV  CX,AX
              XCHG AH,AL
              CALL BYTETOSTR
              MOV  AX,CX
              ADD  SI,2
              CALL BYTETOSTR
              ADD  SI,-2
              RET
WORDTOSTR     ENDP


MYCODE        ENDS

              END



