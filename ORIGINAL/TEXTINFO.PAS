{--------------------------------------------------------------}
{                        TextInfo                              }
{                                                              }
{             Text video information library                   }
{                                                              }
{                             by Jeff Duntemann                }
{                             Turbo Pascal V5.0                }
{                             Last update 11/20/88             }
{--------------------------------------------------------------}

UNIT TextInfo;

INTERFACE

USES DOS;


TYPE
  AdapterType  = (None,MDA,CGA,EGAMono,EGAColor,VGAMono,
                 VGAColor,MCGAMono,MCGAColor);

  FontSize     = (Font8,Font14,Font16);

  { The following type definition *requires* Turbo Pascal 5.0! }
  OverrideProc = PROCEDURE(VAR ForceX : Byte; VAR ForceY : Byte);


VAR
  TextBufferOrigin  : Pointer;
  TextBufferSize    : Word;
  VisibleX,VisibleY : Byte;


FUNCTION  GetBIOSTextMode : Byte;          { Returns BIOS text mode }

FUNCTION  GetFontSize : FontSize;          { Returns font height code }

FUNCTION  GetTextBufferOrigin : Pointer;   { Returns pointer to text buffer }

{ Returns visible X and Y extent plus buffer size in bytes: }

PROCEDURE GetTextBufferStats(VAR BX : Byte;
                             VAR BY : Byte;
                             VAR BuffSize : Word;
                             CheckForOverride : OverrideProc);

FUNCTION  Monochrome : Boolean;       { Returns True if monochrome display }

PROCEDURE NullOverride(VAR ForceX : Byte; VAR ForceY : Byte);

FUNCTION  QueryAdapterType : AdapterType;      { Returns installed display }

FUNCTION  FontCode(Height : Byte) : FontSize;  { Returns font height code }

FUNCTION  FontHeight(Code : FontSize) : Byte;  { Returns font height value}



IMPLEMENTATION


FUNCTION GetBIOSTextMode : Byte;

VAR
  Regs : Registers; { Type Registers is exported by the DOS unit }

BEGIN
  Regs.AH := $0F;   { BIOS VIDEO Service $F: Get Current Video Mode }
  Intr($10,Regs);
  GetBIOSTextMode := Regs.AL;  { Mode is returned in AL }
END;



FUNCTION QueryAdapterType : AdapterType;

VAR
  Regs : Registers; { Type Registers is exported by the DOS unit }
  Code : Byte;

BEGIN
  Regs.AH := $1A;  { Attempt to call VGA Identify Adapter Function }
  Regs.AL := $00;  { Must clear AL to 0 ... }
  Intr($10,Regs);
  IF Regs.AL = $1A THEN  { ...so that if $1A comes back in AL...  }
    BEGIN                { ...we know a PS/2 video BIOS is out there. }
      CASE Regs.BL OF    { Code comes back in BL }
        $00 : QueryAdapterType := None;
        $01 : QueryAdapterType := MDA;
        $02 : QueryAdapterType := CGA;
        $04 : QueryAdapterType := EGAColor;
        $05 : QueryAdapterType := EGAMono;
        $07 : QueryAdapterType := VGAMono;
        $08 : QueryAdapterType := VGAColor;
        $0A,$0C : QueryAdapterType := MCGAColor;
        $0B : QueryAdapterType := MCGAMono;
        ELSE QueryAdapterType := CGA
      END { CASE }
    END
  ELSE
  { If it's not PS/2 we have to check for the presence of an EGA BIOS: }
    BEGIN
      Regs.AH := $12;       { Select Alternate Function service }
      Regs.BX := $10;       { BL=$10 means return EGA information }
      Intr($10,Regs);       { Call BIOS VIDEO }
      IF Regs.BX <> $10 THEN { BX unchanged means EGA is NOT there...}
        BEGIN
          Regs.AH := $12;   { Once we know Alt Function exists... }
          Regs.BL := $10;   { ...we call it again to see if it's... }
          Intr($10,Regs);   { ...EGA color or EGA monochrome. }
          IF (Regs.BH = 0) THEN QueryAdapterType := EGAColor
            ELSE QueryAdapterType := EGAMono
        END
      ELSE  { Now we know we have an CGA or MDA; let's see which: }
        BEGIN
          Intr($11,Regs);   { Equipment determination service }
          Code := (Regs.AL AND $30) SHR 4;
          CASE Code of
            1 : QueryAdapterType := CGA;
            2 : QueryAdapterType := CGA;
            3 : QueryAdapterType := MDA
            ELSE QueryAdapterType := None
          END { Case }
        END
    END;
END;



{ All we're doing here is converting numeric font heights }
{ to their corresponding values of type FontSize.         }

FUNCTION FontCode(Height : Byte) : FontSize;

BEGIN
  CASE Height OF
     8 : FontCode := Font8;
    14 : FontCode := Font14;
    16 : FontCode := Font16;
  END { CASE }
END;


{ Likewise, this function converts values of type FontSize }
{ to their corresponding numeriuc values.                  }

FUNCTION FontHeight(Code : FontSize) : Byte;

BEGIN
  CASE Code OF
    Font8  : FontHeight := 8;
    Font14 : FontHeight := 14;
    Font16 : FontHeight := 16;
  END { CASE }
END;



FUNCTION GetFontSize : FontSize;

VAR
  Regs : Registers;  { Type Registers is exported by the DOS unit }

BEGIN
  CASE QueryAdapterType OF
    CGA       : GetFontSize := Font8;
    MDA       : GetFontSize := Font14;
    MCGAMono,
    MCGAColor : GetFontSize := Font16; { Wretched thing knows but 1 font! }
    EGAMono,        { These adapters may be using any of several different }
    EGAColor,       { font cell heights, so we need to query the BIOS to }
    VGAMono,        { find  out which is currently in use. }
    VGAColor  : BEGIN
                  WITH Regs DO
                    BEGIN
                      AH := $11;  { EGA/VGA Information Call }
                      AL := $30;
                      BH := 0;
                    END;
                  Intr($10,Regs); { On return, CX contains the font height }
                  GetFontSize := FontCode(Regs.CX);
                END
  END  { CASE }
END;



FUNCTION GetTextBufferOrigin : Pointer;

{ The rule is:  For boards attached to monochrome monitors, the buffer }
{ origin is $B000:0; for boards attached to color monitors (including  }
{ all composite monitors and TV's) the buffer origin is $B800:0.       }

BEGIN
  CASE QueryAdapterType OF
    CGA,MCGAColor,EGAColor,VGAColor : GetTextBufferOrigin := Ptr($B800,0);
    MDA,MCGAMono, EGAMono, VGAMono  : GetTextBufferOrigin := Ptr($B000,0);
  END  { CASE }
END;


{ This proc provides initial values for the dimensions of the visible }
{ display and (hence) the size of the visible refresh buffer.  It is  }
{ called  by the initialization section during startup *BUT* you must }
{ call it again after any mode change or font change to be sure of    }
{ having accurate values in the three variables! }

PROCEDURE GetTextBufferStats(VAR BX : Byte;        { Visible X dimension }
                             VAR BY : Byte;        { Visible Y dimension }
                             VAR BuffSize : Word;  { Refresh buffer size }
{ This requires TP5.0! }     CheckForOverride : OverrideProc);

CONST
  ScreenLinesMatrix : ARRAY[AdapterType,FontSize] OF Integer =
                   { Font8:  Font14: Font16: }
  {      None: }     ((25,     25,     25),
  {       MDA: }      (-1,     25,     -1),
  {       CGA: }      (25,     -1,     -1),
  {   EGAMono: }      (43,     25,     -1),
  {  EGAColor: }      (43,     25,     -1),
  {   VGAMono: }      (50,     28,     25),
  {  VGAColor: }      (50,     28,     25),
  {  MCGAMono: }      (-1,     -1,     25),
  { MCGAColor: }      (-1,     -1,     25));

VAR
  Regs : Registers;   { Type Registers is exported by the DOS unit }

BEGIN
  Regs.AH := $0F; { BIOS VIDEO Service $F: Get Current Video Mode }
  Intr($10,Regs);
  BX := Regs.AH;  { Number of characters in a line returned in AH }

  BY := ScreenLinesMatrix[QueryAdapterType,GetFontSize];
  IF BY > 0 THEN
    BEGIN
      CheckForOverride(BX,BY);  { See if something weird is on the bus... }
      BuffSize := (BX * 2) * BY { Calculate the buffer size in bytes }
    END
  ELSE BuffSize := 0;
END;

{ This is the default override proc, and is called anytime you're }
{ not concerned about finding a nonstandard text adapter on the   }
{ bus.  (Funny graphics cards with normal text modes don't matter }
{ to this library.)  If you want to capture any weird cards, you  }
{ must provide your own override proc that can detect the card    }
{ and return correct values for the visible X and Y dimensions.   }

PROCEDURE NullOverride(VAR ForceX : Byte; VAR ForceY : Byte);

BEGIN
  { Like I said; Null... }
END;


FUNCTION Monochrome : Boolean;

BEGIN
  CASE QueryAdapterType OF
    None,MDA,EGAMono,VGAMono,MCGAMono : Monochrome := True;
    CGA,EGAColor,VGAColor,MCGAColor   : Monochrome := False
  END {CASE }
END;



{ The initialization section provides some initial values for the   }
{ exported variables TextBufferOrigin, VisibleX, VisibleY, and      }
{ TextBufferSize, so that you can use the variables without further }
{ kafeuthering. }

BEGIN
  TextBufferOrigin := GetTextBufferOrigin;
  GetTextBufferStats(VisibleX,VisibleY,TextBufferSize,NullOverride);
END.

