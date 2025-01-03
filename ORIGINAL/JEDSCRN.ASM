



         TITLE  JEDSCRN -- External screen data module for JED editor


CODE     SEGMENT WORD
         ASSUME CS:CODE


JEDHelp  PROC FAR

         PUBLIC JEDHelp

         DB '������������ͻ                                                                  '
         DB '   �  �ͻ    �     Version 1.0 -- Released 1/8/89  --  ALT-X EXITS!             '
         DB '�  �  �ͼ ��͹                                                                  '
         DB '��ͼ  ������ͼ     (c) 1988, 1989  Jeff Duntemann -- ALL RIGHTS RESERVED        '
         DB '                                                                                '
         DB '����������������������������������� COMMAND SET ��������������������������������'
         DB 'F1:  Display this screen                � ^KD: Quit and save file               '
         DB 'F2:  Save current source code file      � ^KQ: Quit without saving              '
         DB 'F3:  Invoke DEBUG on current .EXE file  � ^KW: Write marked block to disk       '
         DB 'F4:  Update assemble/link command lines � ^KR: Read a file to cursor position   '
         DB 'F5:  Shell out to DOS                   � ^KH: Hide/unhide the marked block     '
         DB 'F6:  Show last assemble/link screen     � ^KY: Delete marked block              '
         DB 'F7:  Mark beginning of block            � ^KV: Move marked block                '
         DB 'F8:  Mark end of block                  � ^KC: Copy marked block                '
         DB 'F9:  Assemble only                      � ^QL: Undo changes to line             '
         DB 'F10: Assemble/link (if needed) and Go!  � Alt-F: Change current source code file'
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

         DB '������������������������������������Ŀ'
         DB '�  ������������ͻ  Change work file  �'
         DB '�     �  �ͻ    �                    �'
         DB '�  �  �  �ͼ ��͹  Current work file:�'
         DB '�  ��ͼ  ������ͼ                    �'
         DB '�                                    �'
         DB '� New work file:                     �'
         DB '�                                    �'
         DB '� Enter retains all changes made;    �'
         DB '� ESC abandons all changes made;     �'
         DB '� CTRL-X clears field.               �'
         DB '��������������������������������������'

JEDFile  ENDP

JEDErr   PROC FAR

         PUBLIC JEDErr

         DB '������������������������������������������������������������Ŀ'
         DB '� JED error!                                                 �'
         DB '�                                                            �'
         DB '�                                                            �'
         DB '��������������������������������������������������������������'

JEDErr   ENDP

CODE     ENDS

         END

