MYDATA        SEGMENT     PUBLIC
              PUBLIC DISPTYPE,VIDORIGIN,VIDSEGMENT,VISIBLEX,VISIBLEY
              PUBLIC VIDBUFSIZE,FONTSIZE,BORDNAME,LRXY

DISPTYPE      DB          0
VIDORIGIN     DW          0
VIDSEGMENT    DW          0B000H
VISIBLEX      DB          80
VISIBLEY      DB          25
VIDBUFSIZE    DW          4000
FONTSIZE      DB          8
BORDNAME      DW          ?
LRXY          DW          184FH

              PUBLIC VIDINFOTBL,DIGITS,CRLF,IDSTRING,LIDSTRING
              PUBLIC AUTHORSTR,LAUTHORSTR,VIDIDSTR,LVIDIDSTR
              PUBLIC ORGIDSTR,LORGIDSTR,FONTSZSTR,LFONTSZSTR
              PUBLIC SCRNLNSTR,LSCRNLNSTR,BUFSIZSTR,LBUFSIZSTR
              PUBLIC DIGITSTR,LDIGITSTR

VIDINFOTBL    DB          'NO ADAPTER IDENTIFIED      '    ; CODE 0
              DW          0B000H
              DB          25,25,25
              DB          'MONOCHROME DISPLAY ADAPTER '    ; CODE 1
              DW          0B000H
              DB          25,25,25
              DB          'COLOR GRAPHICS ADAPTER     '    ; CODE 2
              DW          0B800H
              DB          25,25,25
              DB          'CODE 3: UNDEFINED          '    ; CODE 3
              DW          0B000H
              DB          25,25,25
              DB          'EGA WITH COLOR MONITOR     '    ; CODE 4
              DW          0B800H
              DB          43,25,25
              DB          'EGA WITH MONO MONITOR      '    ; CODE 5
              DW          0B000H
              DB          43,25,25
              DB          'CODE 6: UNDEFINED          '    ; CODE 6
              DW          0B000H
              DB          25,25,25
              DB          'VGA WITH MONO MONITOR      '    ; CODE 7
              DW          0B000H
              DB          50,27,25
              DB          'VGA WITH COLOR MONITOR     '    ; CODE 8
              DW          0B800H
              DB          50,27,25
              DB          'CODE 9: UNDEFINED          '    ; CODE 9
              DW          0B000H
              DB          25,25,25
              DB          'MCGA WITH DIGITAL COLOR    '    ; CODE 0AH
              DW          0B800H
              DB          25,25,25
              DB          'MCGA WITH MONOCHROME       '    ; CODE 0BH
              DW          0B000H
              DB          25,25,25
              DB          'MCGA WITH ANALOG COLOR     '    ; CODE 0CH
              DW          0B800H
              DB          25,25,25

DIGITS        DB          '0123456789ABCDEF'
CRLF          DB          0DH,0AH        ; NEWLINE STRING
IDSTRING      DB          '>>>INFO V1.0'
LIDSTRING     EQU         $-IDSTRING
AUTHORSTR     DB          '   BY JEFF DUNTEMANN'
LAUTHORSTR    EQU         $-AUTHORSTR
VIDIDSTR      DB          '   THE INSTALLED VIDEO BOARD IS: '
LVIDIDSTR     EQU         $-VIDIDSTR
ORGIDSTR      DB          '   THE SEGMENT OF THE VIDEO REFRESH BUFFER IS: '
LORGIDSTR     EQU         $-ORGIDSTR
FONTSZSTR     DB          '   THE SIZE OF THE CURRENT TEXT FONT IS: '
LFONTSZSTR    EQU         $-FONTSZSTR
SCRNLNSTR     DB          '   THE NUMBER OF LINES CURRENTLY ON THE SCREEN IS: '
LSCRNLNSTR    EQU         $-SCRNLNSTR
BUFSIZSTR     DB          '   THE SIZE OF THE REFRESH BUFFER IN BYTES IS: '
LBUFSIZSTR    EQU         $-BUFSIZSTR
DIGITSTR      DB          '       '
LDIGITSTR     EQU         $-DIGITSTR

MYDATA        ENDS


MYCODE        SEGMENT     PUBLIC
              ASSUME DS:MYDATA,CS:MYCODE
              PUBLIC BYTETOSTR,WORDTOSTR

DISPID        PROC
              MOV  AH,1AH
              XOR  AL,AL
              INT  10H
              CMP  AL,1AH
              JNE  TRYEGA
              MOV  AL,BL
              RET
TRYEGA:       MOV  AH,12H
              MOV  BX,10H
              INT  10H
              CMP  BX,10H
              JE   OLDBORDS
              CMP  BH,0
              JE   EGACOLOR
              MOV  AL,5
              RET
EGACOLOR:     MOV  AL,4
              RET
OLDBORDS:     INT  11H
              AND  AL,30H
              CMP  AL,30H
              JNE  CGA
              MOV  AL,1
              RET
CGA:          MOV  AL,2
              RET
DISPID        ENDP

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
              SUB  SI,2
              RET
WORDTOSTR     ENDP

MYCODE        ENDS

              END



