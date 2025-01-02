;---------------------------------------------------------------
;                             WHATAMI.ASM
;
; Program to demonstrate runtime detection of the installed CPU
;
; Many thanks to Nicholas Wilt for providing me the algorithm!
;
;                                      by Jeff Duntemann
;                                      MASM/TASM
;                                      Last update 2/9/92
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
MyData     SEGMENT

MsgTbl     DB      "You have an 88. "
           DB      "You have a 286. "
           DB      "You have a 386. "
           DB      "You have a 486. "

MyData     ENDS
;----------------------------|
;      END DATA SEGMENT      |
;----------------------------|

;----------------------------|
;     BEGIN CODE SEGMENT     |
;----------------------------|

MyProg     SEGMENT

           assume CS:MyProg,DS:MyData


; CPUID -- determines the installed CPU
;
;          Returns a value in AL that has the following meaning:
;          0 - 8086 or 8088
;          1 - 80286
;          2 - 80386, DX or SX
;          3 - 80486

CPUID      PROC
.386
           ; Assume we have an 8086/8088 for now...
           xor  DX,DX       ; Clear DX to 0
           push DX          ; Push 16 bits of 0's on the stack
           popf             ; Pop 16 bits of 0's off stack & into flags
           pushf            ; Push state of flags back onto stack..
           pop  AX          ; ..so that we can pop them off & look at them
           cmp  AX,0F000H   ; Test the high 4 bits of what was in flags
           je   Done        ; If top 4 bits are set, it's an 8086/8088
           inc  DX          ; Otherwise, we have at least a 286, so we can
                            ;   increment the ID code & keep on testing..
           push 0F000H      ; Push the value 0F000H on the stack
           popf             ; Pop 0F000H off stack into the flags
           pushf            ; Push state of flags back onto stack..
           pop  AX          ; ..so that we can pop them off & look at them
           and  AX,0F000H   ; Check to see if they still contain 0F000H
           jz   Done        ; This time, if the flags are *not* 0F000H,
                            ;   we have a 286
           inc  DX          ; Otherwise, we have at least a 386, so we can
                            ;   increment the ID code & keep on testing..

; Testing for the 486 -- algorithm from Hummel
           mov  ECX,ESP     ; Save the stack pointer in EDX
           and  ESP,NOT 3   ; Force stack pointer to align on a DWORD
           pushfd           ; Push extended flags register onto the stack
           pop  EAX         ; Pop extended flags values off stack into EAX
           mov  EBX,EAX     ; Save a copy of the extended flags for later
           xor  EAX,00040000H      ; Try to toggle AC bit in extended flags
           push EAX         ; Push flags test value from EAX onto stack..
           popfd            ; ..and pop it back into the extended flags reg.
           pushfd           ; Push extended flags value back onto stack..
           pop  EAX         ; ..and pop it back into EAX for inspection
           xor  EAX,EBX     ; Compare altered against unaltered flags value
           jz   FixESP      ; If toggle of AC bit didn't "take," it's a 386..
           inc  DX          ; ..but if it did, we have a 486, so inc DX to 3

FixESP:    mov  ESP,ECX     ; Put the original stack pointer back into ESP
Done:      mov  AX,DX       ; Let's return the CPU code in AX
           ret              ; and go back to the caller

CPUID      ENDP


; BEGIN MAIN PROGRAM

Main       PROC

Start:     ; This is where program execution begins:
           mov  AX,MyData   ; Set up our own data segment address in DS
           mov  DS,AX       ; Can't load segment reg. directly from memory

           ; Identifying the CPU is just a matter of calling the CPUID proc:
           call CPUID       ; Go out and test for the installed CPU
           push AX          ; Save the return code on stack for ERRORLEVEL

           ; Now we print the message based on the CPU code:
           xor  AH,AH       ; Clear AH so the code stands alone
           mov  DI,AX       ; Put AL with CPU ID code value into DI
           mov  CL,4        ; Load shift count value into CL
           shl  DI,CL       ; Multiply code by 16 to get offset into table
           lea  DX,MsgTbl   ; Load address of start of message table into BX
           add  DX,DI       ; Add calculated offset to address
           mov  CX,16       ; All messages in table are 16 bytes long
           mov  BX,1        ; Selects DOS file handle #1: Standard Output
           mov  AH,40H      ; Select DOS service 40: Print String
           int  21H         ; Make the DOS call

           pop  AX          ; Make sure code is still in AL
           mov  AH,4CH      ; Terminate process DOS service
           int  21H         ; Control returns to DOS

Main       ENDP

MyProg     ENDS

;----------------------------|
;      END CODE SEGMENT      |
;----------------------------|

           END Start    ; The procedure named Start becomes the main program
