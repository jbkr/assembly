



         TITLE  JEDSCRN -- External screen data module for JED editor


CODE     SEGMENT WORD
         ASSUME CS:CODE


JEDHelp  PROC FAR

         PUBLIC JEDHelp

         DB 'ÍÍÍËÍÍÍÍÍÍÍÍÍ»                                                                  '
         DB '   º  ÉÍ»    º     Version 1.0 -- Released 1/8/89  --  ALT-X EXITS!             '
         DB 'º  º  ÌÍ¼ ÉÍÍ¹                                                                  '
         DB 'ÈÍÍ¼  ÈÍÍÍÊÍÍ¼     (c) 1988, 1989  Jeff Duntemann -- ALL RIGHTS RESERVED        '
         DB '                                                                                '
         DB 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ COMMAND SET ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
         DB 'F1:  Display this screen                ³ ^KD: Quit and save file               '
         DB 'F2:  Save current source code file      ³ ^KQ: Quit without saving              '
         DB 'F3:  Invoke DEBUG on current .EXE file  ³ ^KW: Write marked block to disk       '
         DB 'F4:  Update assemble/link command lines ³ ^KR: Read a file to cursor position   '
         DB 'F5:  Shell out to DOS                   ³ ^KH: Hide/unhide the marked block     '
         DB 'F6:  Show last assemble/link screen     ³ ^KY: Delete marked block              '
         DB 'F7:  Mark beginning of block            ³ ^KV: Move marked block                '
         DB 'F8:  Mark end of block                  ³ ^KC: Copy marked block                '
         DB 'F9:  Assemble only                      ³ ^QL: Undo changes to line             '
         DB 'F10: Assemble/link (if needed) and Go!  ³ Alt-F: Change current source code file'
         DB '                                                                                '
         DB '^QR: Move to start of file   ^Y: Delete line   ^T: Delete word  ^QY: Del. to EOL'
         DB '^QC: Move to end of file     ^QF: Find  ^QA: Find/Replace  ^L: Find/repl. again '
         DB '^A:  Move 1 word left        Options: N: Without asking  W: Whole words only    '
         DB '^F:  Move 1 word right                G: Global  U: Ignore case  B: Backwards   '
         DB '                                                                                '
         DB '   <<REMEMBER!!>> If your .ASM file is not a standalone program, but a device   '
         DB '   driver or a library of procedures, pressing F10 may lock up your system!!    '
         DB '                                                                                '
JEDHelp  ENDP

JEDBar   PROC FAR

         PUBLIC JEDBar

         DB 'F1:Help  F2:Save  F3:Debug  F4:Cmds  F5:DOS  F6:Screen  F9:Assemble  F10:Make/Go';

JEDBar   ENDP

JEDFile  PROC FAR

         PUBLIC JEDFile

         DB 'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿'
         DB '³  ÍÍÍËÍÍÍÍÍÍÍÍÍ»  Change work file  ³'
         DB '³     º  ÉÍ»    º                    ³'
         DB '³  º  º  ÌÍ¼ ÉÍÍ¹  Current work file:³'
         DB '³  ÈÍÍ¼  ÈÍÍÍÊÍÍ¼                    ³'
         DB '³                                    ³'
         DB '³ New work file:                     ³'
         DB '³                                    ³'
         DB '³ Enter retains all changes made;    ³'
         DB '³ ESC abandons all changes made;     ³'
         DB '³ CTRL-X clears field.               ³'
         DB 'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'

JEDFile  ENDP

JEDErr   PROC FAR

         PUBLIC JEDErr

         DB 'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿'
         DB '³ JED error!                                                 ³'
         DB '³                                                            ³'
         DB '³                                                            ³'
         DB 'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'

JEDErr   ENDP

CODE     ENDS

         END

