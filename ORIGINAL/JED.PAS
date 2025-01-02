{--------------------------------------------------------------}
{                           JED                                }
{                                                              }
{  Jeff's Editor & Assembly Language Development Environment   }
{                                                              }
{                             by Jeff Duntemann                }
{                             Turbo Pascal V5.00               }
{                             Last update 4/19/89              }
{                                                              }
{               (c) 1989 by Jeff Duntemann                     }
{      Binary Editor module (c) 1988 Borland International     }
{--------------------------------------------------------------}

{ Version 1.01 -- Rudimentary file error capture }

{$M 16384,8192,148000}


PROGRAM JED;

{ Note well that this program REQUIRES Turbo Pascal 5.0! }

USES
  Bined,     { From the Turbo Pascal Editor Toolbox V4.0 }
  CRT,       { Standard Borland unit }
  DOS,       { Standard Borland unit }
  TextInfo;  { By Jeff Duntemann; published in DDJ 3/89  }

TYPE
  String80         = STRING[80];

CONST
  UP               = True;      { For forcing strings to uc/lc }
  DOWN             = False;
  ConfigFileName   = 'JED.CFG';
  DefaultExtension = '.ASM';
  SUBCHAR          = '~';
  BlackOnWhite     = $70;       { Reverse video attribute' color or mono }

  {Coordinates of the editor window}
  Windx1 = 1;
  Windy1 = 1;
  Windx2 = 80;
  Windy2 = 25;         { 43 for EGA; 50 for VGA; 66 for Genius }
  MakeBackup = True;   { When True, JED creates .BAK files }

  {Commands other than ^K^D to exit editor}
  ExitCommands : array[0..33] of Char =
  (#2, ^K, ^Q,        { Ctrl-KQ: Exit without saving file }
   #2, #0, #33,       { Alt-F:   Change work file  }
   #2, #0, #45,       { Alt-X:   Save and exit     }
   #2, #0, #59,       { F1:      Show help screen  }
   #2, #0, #60,       { F2:      Save current file }
   #2, #0, #61,       { F3:      Invoke DEBUG on current .EXE file }
   #2, #0, #62,       { F4:      Update assemble/link command line }
   #2, #0, #63,       { F5:      Exec to DOS command line }
   #2, #0, #64,       { F6:      Examine last Exec screen }
   #2, #0, #67,       { F9:      Assemble only }
   #2, #0, #68,       { F10:     Simple MAKE: Assemble, link, and go }
   #0);



TYPE
  ScreenSaveRec = RECORD
                    SaveX,SaveY : Integer;
                    SavePtr     : Pointer
                  END;

  ConfigRec     = RECORD
                    Workfile        : String80;
                    CursorInset     : Word;      { Cursor X,Y at last save }
                    AssembleCommand : String80;  { Command with switches   }
                    LinkCommand     : String80;  { Ditto for linker        }
                    TestParms       : String80   { Any parameters for prog }
                  END;                        { under development with JED }

  ConfigFile    = FILE OF ConfigRec;


CONST
  ConfigData    : ConfigRec =
                  (Workfile        : 'NONAME.ASM';
                   CursorInset     : 0;
                   AssembleCommand : 'TASM ~';
                   LinkCommand     : 'TLINK ~';
                   TestParms       : '');




VAR
  EdData       : EdCB;           { Editor control block }
  ExitCode     : Word;           { Status code set by bin. ed. functions }
  ExitCommand  : Integer;        { Code for command used to leave editor }
  Fname        : STRING;         { Input name of file being edited  }
  TempName     : STRING;         { Holds name while changing files  }
  Quit         : Boolean;        { Ends program }
  DOSScreen    : ScreenSaveRec;  { Saves DOS screen under JED       }
  JEDScreen    : ScreenSaveRec;  { Saves JED screen under help or exec }
  ExecScreen   : ScreensaveRec;  { Saves Exec screen for later examination }
  BarAttribute : Byte;           { Video attribute for prompt bar }
  Now          : DateTime;       { For the clock display }
  ConfigStore  : ConfigFile;     { Contains configuration data on disk }
  UpdateConfigData : Boolean;    { If True, update JED.CFG on exit }


{-------------------------------------------------------------------------}
{ The following EXTERNAL definitions are *not* code, but screen patterns  }
{ stored as external assembly language procedures.  They are put to the   }
{ screen using the VidBlast external machine code procedure.  DO NOT TRY  }
{ TO EXECUTE THEM!  Bizarre machine behavior including lockup WILL occur. }
{-------------------------------------------------------------------------}

{$L JEDSCRN}
{$F+}
PROCEDURE JEDHelp; EXTERNAL; { JED's help screen }
PROCEDURE JEDBar;  EXTERNAL; { The prompt bar at the bottom of the screen }
PROCEDURE JEDFile; EXTERNAL; { The file name entry box invoked with Alt-F }
PROCEDURE JEDErr;  EXTERNAL; { The JED error message box }
{$F-}


{$L VIDBLAST}
{$F+}
PROCEDURE VidBlast(ScreenEnd,StoreEnd : Pointer;
                   ScreenX,ScreenY    : Integer;
                   ULX,ULY            : Integer;
                   Width,Height       : Integer;
                   Attribute          : Byte;
                   DeadLines          : Integer);
          EXTERNAL;
{$F-}


{-UhUh-------------------------------------------------------------}
{                                                                  }
{ Bored with beeps?  Try this one..the name is very characteristic }
{ of the sound.                                                    }
{------------------------------------------------------------------}

PROCEDURE UhUh;

VAR
  I : Integer;

BEGIN
  FOR I := 1 TO 2 DO
    BEGIN
      Sound(50);
      Delay(100);
      NoSound;
      Delay(50)
    END
END;


PROCEDURE StripWhite(VAR Target : String80);

CONST
  WhiteSpace : SET OF Char = [#7,#8,#10,#9,#12,#13,' '];

BEGIN
  WHILE (Length(Target) > 0 ) AND (Target[1] IN Whitespace) DO
    Delete(Target,1,1);
END;


{-ForceCase--------------------------------------------------------}
{                                                                  }
{ When Up is True, Target is forced to all upper case.  When Up is }
{ False, Target is forced to all lower case.                       }
{------------------------------------------------------------------}

FUNCTION ForceCase(Up : Boolean; Target : STRING) : STRING;

CONST
  Uppercase : SET OF Char = ['A'..'Z'];
  Lowercase : SET OF Char = ['a'..'z'];

VAR
  I : INTEGER;

BEGIN
  IF Up THEN FOR I := 1 TO Length(Target) DO
    IF Target[I] IN Lowercase THEN
      Target[I] := UpCase(Target[I])
    ELSE { NULL }
  ELSE FOR I := 1 TO Length(Target) DO
    IF Target[I] IN Uppercase THEN
      Target[I] := Chr(Ord(Target[I])+32);
  ForceCase := Target
END;


{-WriteColor-------------------------------------------------------}
{                                                                  }
{ The trick here is to save the current screen attribute, (kept in }
{ the variable TextAttr exported by the Crt unit) set TextAttr to  }
{ the attribute passed in InColor, write WriteData to the screen,  }
{ and finally restore the contents of TextAttr that were in force  }
{ when WriteColor took control.                                    }
{------------------------------------------------------------------}

PROCEDURE WriteColor(InColor : Byte; WriteData : String);

VAR
  SaveAttr : Byte;

BEGIN
  SaveAttr := Crt.TextAttr;
  Crt.TextAttr := InColor;
  Write(WriteData);
  Crt.TextAttr := SaveAttr
END;


{-SaveScreenOut-and-BringScreenBack--------------------------------}
{                                                                  }
{ These two routines are inverses of one another.  SaveScreenOut   }
{ allocates space on the heap and saves the displayed text buffer  }
{ into the allocated space.  The current cursor position is saved  }
{ in the ScreenSaveRec parameter, and the position is reasserted   }
{ when the screen is moved back into the video refresh buffer with }
{ BringScreenBack.  The number of bytes moved is determined by the }
{ TextBufferSixe variable exported by the TextInfo unit.  The      }
{ generic pointer TextBufferOrigin is also exported by TextInfo.   }
{------------------------------------------------------------------}

PROCEDURE SaveScreenOut(VAR OutboundScreen : ScreenSaveRec);

BEGIN
  WITH OutboundScreen DO
    BEGIN
      SaveX := WhereX; SaveY := WhereY;    { Save the underlying cursor pos. }
      { Allocate memory for stored screen: }
      GetMem(SavePtr,TextBufferSize);
      { Save screen out to the heap:  }
      Move(TextBufferOrigin^,SavePtr^,TextBufferSize);
    END
END;


PROCEDURE BringScreenBack(VAR InboundScreen : ScreenSaveRec);

BEGIN
  WITH InboundScreen DO
    BEGIN
      Move(SavePtr^,TextBufferOrigin^,TextBufferSize);  { Bring screen back  }
      FreeMem(SavePtr,TextBufferSize);   { Free up the meap memory          }
      SavePtr := NIL;
      GotoXY(SaveX,SaveY);               { Put the cursor back where it was }
    END
END;


{-WaitForAnyKeystroke----------------------------------------------}
{                                                                  }
{ All this does is print a centered prompt on the last screen line }
{ and wait for a keystroke.                                        }
{------------------------------------------------------------------}

PROCEDURE WaitForAnyKeystroke;

VAR
  Dummy : Char;

BEGIN
  GotoXY(20,VisibleY); Write('Press any key to return to JED...');
  REPEAT UNTIL KeyPressed;             { Wait for a keystroke }
  Dummy := ReadKey;                    { Go get pressed key }
  IF Dummy = Chr(0) THEN Dummy := ReadKey;
END;


{-GetString--------------------------------------------------------}
{                                                                  }
{ Here's your generic field editor.  Pass the string to be edited  }
{ in XString, the location of the left character of the field in X }
{ and Y, the maximum length allowable in MaxLen, the attribute for }
{ foreground/background colors in UseColor, and nothing in         }
{ ESCPressed--that's a return value, indicating that the user hit  }
{ the ESC key.  XString will be displayed left-justified in the    }
{ field, but if the first character pressed is a printable one,    }
{ the field will be blanked, allowing for rapid entry of new       }
{ strings.  Note that if ESC is pressed, XSTRing is not altered.   }
{------------------------------------------------------------------}

PROCEDURE GetString(X,Y             : Integer;
                    VAR XString     : String80;
                    MaxLen          : Integer;
                    UseColor        : Byte;
                    VAR EscPressed  : Boolean);

CONST  Dot        : Char = '.';
       Printables : SET OF Char = [' '..'~'];

VAR I,J        : Integer;
    Ch         : Char;
    ClearIt    : String80;
    Worker     : String80;
    GotChar    : Boolean;
    CR         : Boolean;
    Virgin     : Boolean;

BEGIN
  CR := False; EscPressed := False; Virgin := True;
  FillChar(ClearIt,SizeOf(ClearIt),'.');  { Fill the clear string  }
  ClearIt[0] := Chr(MaxLen);              { Set clear string to MaxLen }

  { Truncate string value to MaxLen: }
  IF Length(XString) > MaxLen THEN XString[0] := Chr(MaxLen);
  GotoXY(X,Y); WriteColor(UseColor,ClearIt);    { Draw the field  }
  GotoXY(X,Y); WriteColor(UseColor,XString);
  IF Length(XString) < MaxLen THEN
    GotoXY(X + Length(XString),Y);

  Worker := XString;      { Fill work string with input string     }

  REPEAT                  { Until ESC or (CR) entered }
                          { Wait here for keypress:   }
    REPEAT
      GotChar := True;
      WHILE NOT KeyPressed DO BEGIN {NULL} END;
      Ch := ReadKey;
      IF Ord(CH) = 0 THEN  { If an extended keycode was received..   }
        BEGIN
          Ch := Readkey;   { ..get the other half of it to ignore it }
          GotChar := False { Set the flag so we loop & get another   }
        END
    UNTIL GotChar;

    IF Ch IN Printables THEN                    { If Ch is printable... }
      BEGIN
        IF Virgin THEN  { We clear the field if first char is printable }
          BEGIN
            Worker := '';
            GotoXY(X,Y);
            WriteColor(UseColor,Clearit);    { Fill the field with dots }
            Virgin := False;
          END;
        IF Length(Worker) >= MaxLen THEN UhUh ELSE   { If we're full... }
          BEGIN
            Worker := CONCAT(Worker,Ch);    { Append it to the work string  }
            GotoXY(X,Y); WriteColor(UseColor,Worker);   { and redisplay it  }
            IF Length(Worker) >= MaxLen THEN  { Keep hardware cursor within }
              GotoXY(X+MaxLen-1,Y);             { the field }
          END
      END
    ELSE   { If Ch is NOT printable... }
      BEGIN
        Virgin := False;
        CASE Ord(Ch) OF
         8,127 : IF Length(Worker) <= 0 THEN UhUh ELSE { Backspace & rubout }
                  BEGIN
                    Delete(Worker,Length(Worker),1);
                    GotoXY(X,Y); WriteColor(UseColor,Worker);
                    IF Length(Worker) < MaxLen THEN WriteColor(UseColor,Dot);
                    GotoXY(X+Length(Worker),Y);
                  END;

         13 : CR := True;          { Carriage return; keep changes }

         24 : BEGIN                { CTRL-X : Blank the field }
                GotoXY(X,Y); WriteColor(UseColor,ClearIt);
                GotoXY(X,Y);
                Worker := '';      { Blank out work string }
              END;

         27 : EscPressed := True;  { ESC; abandon changes }
         ELSE UhUh                 { CASE ELSE; no other legal control chars }
        END; { CASE }
      END
  UNTIL CR OR EscPressed;        { Get keypresses until (CR) or }
                                 { ESC pressed }

  IF CR THEN XString := Worker;  { Don't update XString if ESC hit }

END;  { GetString }



PROCEDURE WriteStatus(msg : string);
  {-Write a status message}

BEGIN                       {WriteStatus}
  GoToXY(1, Windy2);
  TextColor(White);
  Write(msg);
END;                        {WriteStatus}



PROCEDURE ShowJEDErrorMessage(ErrX,ErrY : Integer; Message : STRING);

BEGIN
  VidBlast(TextBufferOrigin,@JEDBar,  { Blast in the JED error frame     }
           VisibleX,VisibleY,         { Dimensions of current screen     }
           ErrX,ErrY,                 { Load it at bottom screen line    }
           62,5,                      { JEDErr is 62 wide and 5 high     }
           07,                        { Use the normal attribute         }
           0);                        { No interspersed blank lines      }
  GotoXY(ErrX+3,ErrY+2);
  Write(Message);
END;



PROCEDURE SaveConfigFile(ConfigData : ConfigRec);

BEGIN
  { Save the last known cursor inset into the edited file: }
  ConfigData.CursorInset := EdData.CursorPos;
  Assign(ConfigStore,ConfigFileName);
  Rewrite(ConfigStore);
  Write(ConfigStore,ConfigData);
  Close(ConfigStore)
END;


{-GetFileName------------------------------------------------------}
{                                                                  }
{ This routine is called when JED starts up, and it returns a file }
{ name to load and edit.  It first looks on the parameter line for }
{ a file name.  If parameters were entered, the configuration file }
{ is opened, and the name of the last file saved will be loaded    }
{ and used.  If the config file can't be read, NONAME.ASM will be  }
{ used as a filename.                                              }
{------------------------------------------------------------------}

FUNCTION GetFileName(VAR ConfigData : ConfigRec) : STRING;

VAR
  TempConfigData : ConfigRec;
  TempName       : String80;
  I              : Integer;


PROCEDURE ReadConfigFile(VAR ConfigFromDisk : ConfigRec);

BEGIN
  Assign(ConfigStore,ConfigFileName);
  {$I-} Reset(ConfigStore); {$I+}
  { IF JED.CFG can't be read, reassert defaults: }
  IF IOResult <> 0 THEN
    BEGIN
      WITH ConfigData DO
        BEGIN
          WorkFile        := 'NONAME.ASM';
          CursorInset     := 0;
          AssembleCommand := 'TASM ~';
          LinkCommand     := 'TLINK ~';
          TestParms       := ''
        END
    END
  ELSE  { Read JED.CFG from disk }
    BEGIN
      Read(ConfigStore,ConfigData);
      Close(ConfigStore);
    END
END;



BEGIN  { GetFileName }
  IF ParamCount > 0 THEN   { If there are parms, read #1 as file name }
    BEGIN
      TempName := ParamStr(1);        { Save command parm #1 in temp string }
      { Force the name to upper case: }
      TempName := Forcecase(UP,TempName);
      { If the name has no extentions, append the default extension: }
      IF Pos('.',TempName) = 0 THEN
        TempName := TempName + DefaultExtension;
      ReadConfigFile(TempConfigData); { Read JED.CFG from disk }
      { If the workfile name in JED.CFG matches parm #1, use rest of JED.CFG }
      IF TempName = TempConfigData.WorkFile THEN
        Configdata := TempConfigData
      ELSE                            { Otherwise, reassert defaults for }
        WITH ConfigData DO            { config data other than work file }
          BEGIN
            WorkFile        := TempName;
            CursorInset     := 0;
            AssembleCommand := 'TASM ~';
            LinkCommand     := 'TLINK ~';
            TestParms       := ''
          END
    END
  ELSE ReadConfigFile(ConfigData);    { No parms; use full JED.CFG data }
  GetFileName := ConfigData.WorkFile;
END;


{-RequestFileName--------------------------------------------------}
{                                                                  }
{ If the user needs to change files within a JED session, this     }
{ routine takes care of prompting for a new file name.  If Enter   }
{ is pressed after field entry, the name entered in the field is   }
{ returned.  If ESC is pressed instead, the name in the config     }
{ file is returned instead and is usually the file being edited.   }
{------------------------------------------------------------------}

FUNCTION RequestFileName(ConfigInfo : ConfigRec) : String;

CONST
  BoxX = 20;
  BoxY = 5;

VAR
  ESCPressed : Boolean;
  TempName   : String80;

BEGIN
  ESCPressed := False;
  SaveScreenOut(JEDScreen); { Save the underlying screen out to the heap }

  VidBlast(TextBufferOrigin,@JEDFile, { Blast in the JED change-file box }
           VisibleX,VisibleY,         { Dimensions of current screen     }
           BoxX,BoxY,                 { Put it at the passed X,Y values  }
           38,12,                     { JEDFile is 38 wide and 12 high   }
           BarAttribute,              { Use an appropriate attribute     }
           0);                        { No interspersed blank lines      }

  TempName := ConfigInfo.WorkFile;    { Use current file as default }
  GotoXY(BoxX+19,BoxY+4); WriteColor(BlackOnWhite,FName);
  GetString(BoxX+19,BoxY+6,TempName,12,BlackOnWhite,ESCPressed);
  IF ESCPressed THEN   { If ESC pressed, keep the name in the config file }
    RequestFileName := ConfigInfo.WorkFile
  ELSE
    RequestFilename := TempName;      { Return the new name }
  BringScreenBack(JEDScreen);         { Bring back the underlying screen }
END;


FUNCTION GetProg(CommandLine : String80) : String80;

BEGIN
  StripWhite(CommandLine);
  IF Length(CommandLine) > 0 THEN
    GetProg := Copy(CommandLine,1,Pos(' ',CommandLine)-1) + '.EXE'
  ELSE GetProg := '';
END;


FUNCTION GetParms(CommandLine : String80;
                  WorkFile    : String80) : String80;

VAR
  Dir    : DirStr;    { These 3 types are defined in the DOS unit... }
  Name   : NameStr;
  Ext    : ExtStr;

  SubPos : Integer;

BEGIN
  FSplit(WorkFile,Dir,Name,Ext);
  StripWhite(CommandLine);
  IF Length(CommandLine) > 0 THEN
    BEGIN
      Delete(CommandLine,1,Pos(' ',CommandLine));
      SubPos := Pos(SUBCHAR,CommandLine);
      IF SubPos = 0 THEN
        CommandLine := Name + ' ' + CommandLine
      ELSE
        BEGIN
          Delete(CommandLine,SubPos,1);
          Insert(Name,CommandLine,SubPos);
        END;
      GetParms := CommandLine
    END
  ELSE
    GetParms := ''
END;



FUNCTION EXEForm(WorkFileName : String80) : String80;

BEGIN
  IF Pos('.',WorkFileName) = 0 THEN EXEForm :=
    WorkFileName + '.EXE'
  ELSE
    EXEForm := Copy(WorkFileName,1,Pos('.',WorkFileName)-1) + '.EXE';
END;


{-ShowHelp---------------------------------------------------------}
{                                                                  }
{ When the user pressed F1, this routine gets control and blasts a }
{ single-screen help summary into the video refresh buffer.  It    }
{ will remain on display until any key is pressed.                 }
{------------------------------------------------------------------}

PROCEDURE ShowHelp;    { Shows a help screen display on press of F1 }

VAR
  Dummy    : Char;


BEGIN  { ShowHelp }
  SaveScreenOut(JEDScreen); { Save the underlying screen out to the heap }
  ClrScr;                   { Clear what's on the visible screen         }

  VidBlast(TextBufferOrigin,@JEDHelp,  { Blast in the JED help screen    }
           VisibleX,VisibleY,          { Dimensions of current screen    }
           1,1,                        { Load it at screen position 1,1  }
           80,24,                      { JEDHelp is 80 wide and 24 high  }
           BarAttribute,               { Use an appropriate text attribute }
           0);                         { No interspersed blank lines       }

  WaitForAnyKeystroke;
  BringScreenBack(JEDScreen);          { Bring back the underlying screen }
END;



PROCEDURE AssembleAndLink;

BEGIN
  WITH ConfigData DO
    BEGIN
      Exec(GetProg(AssembleCommand),GetParms(AssembleCommand,WorkFile));
      Exec(GetProg(LinkCommand),GetParms(LinkCommand,WorkFile))
    END
END;



PROCEDURE CheckInitBinary(ExitCode : Word);
  {-Check the results of the editor load operation}

BEGIN                       {CheckInitBinary}
  IF ExitCode <> 0 THEN
    BEGIN
      {Couldn't load editor}
      case ExitCode of
        1 : WriteStatus('Insufficient heap space for text buffer');
      ELSE
        WriteStatus('Unknown load error');
    END;
    GoToXY(1, Windy2);
    Halt(1);
  END;
END;                        {CheckInitBinary}


{-CheckReadFile----------------------------------------------------}
{                                                                  }
{------------------------------------------------------------------}

PROCEDURE CheckReadFile(ExitCode : Word; Fname : string);
  {-Check the results of the file read}
VAR
  f : file;

BEGIN                       {CheckReadFile}
  IF ExitCode <> 0 THEN
    BEGIN
      {Couldn't read file}
      CASE ExitCode of
        1 : BEGIN
              {New file, assure valid file name}
              {$I-}
              Assign(f, Fname);
              Rewrite(f);
              IF IOResult <> 0 THEN
                BEGIN
                  Close(f);
                  WriteStatus('Illegal file name '+Fname);
                END
              ELSE
                BEGIN
                  Close(f);
                  Erase(f);
                  GotoXY(1,1);
                  ClrEOL;
                  Write('New File');
                  Delay(2000);
                  GoToXY(1,1);
                  ClrEol;
                  Exit;
                END;
                {$I+}
            END;
        2 : WriteStatus('Insufficient text buffer size');
        ELSE WriteStatus('Unknown read error');
      END; { CASE }
      GoToXY(1,Windy2);
      Halt(1);
    END;
  GoToXY(1,1);
  ClrEol;
  UpdateConfigData := True
END;                        {CheckReadFile}


{-CheckSaveFile----------------------------------------------------}
{                                                                  }
{ <this routine is not yet complete>                               }
{------------------------------------------------------------------}

PROCEDURE CheckSaveFile(ExitCode : Word; Fname : string);

BEGIN
  IF ExitCode <> 0 THEN
    BEGIN
      {Couldn't save file}
      CASE ExitCode of
        1 : WriteStatus('Unable to create output file '+Fname);
        2 : WriteStatus('Error while writing output to '+Fname);
        3 : WriteStatus('Unable to close output file '+Fname);
        ELSE WriteStatus('Unknown write error');
      END; { CASE }
      GoToXY(1,Windy2);
      Halt(1);
    END
  ELSE UpdateConfigData := True;
END;


{-MustMake---------------------------------------------------------}
{ If this function returns True, the .EXE file is out of date and  }
{ must be re-MADE.  The decision is based on a comparison of the   }
{ source file time stamp to the .EXE file time stamp.              }
{------------------------------------------------------------------}

FUNCTION MustMake(CurrentFile : String80) : Boolean;

VAR
  TimeText,TimeEXE : LongInt;   { Time stamps for source & .EXE files }
  Target           : File;      { Untyped file allows opening files }
  IO               : Integer;

BEGIN
  Assign(Target,EXEForm(CurrentFile));
  {$I-} Reset(Target); {$I+}
  IO := IOResult;
  IF IO <> 0 THEN MustMake := True
    ELSE
      BEGIN
        GetFTime(Target,TimeEXE); { Get time stamp of .EXE file }
        Close(Target);
        IF Pos('.',CurrentFile) = 0 THEN
          CurrentFile := CurrentFile + DefaultExtension;
        Assign(Target,CurrentFile);
        {$I-} Reset(Target); {$I+}
        IO := IOREsult;
        IF IO <> 0 THEN MustMake := True
          ELSE
            BEGIN
              GetFTime(Target,TimeText);  { Get time stamp of source file }
              Close(Target);
              IF TimeText > TimeEXE THEN MustMake := True
                ELSE MustMake := False
            END
      END
END;


{-Clocker----------------------------------------------------------}
{                                                                  }
{ This proc acts as an event handler for BINED's user event        }
{ dispatcher.  Whenever it isn't busy doing something else, BINED  }
{ passes control out to an address placed in the editor control    }
{ block by the InitWindow proc.  The proc must be FAR and it ought }
{ to be pretty quick about doing whatever it does.  Here, all we   }
{ want to do is display the time in the upper right corner of the  }
{ screen, within the BINED status line.                            }
{------------------------------------------------------------------}

{$F+} { All User-Event procedures must be FAR calls!}
PROCEDURE Clocker(EventNo,Info : Integer);

VAR
  Hours,Minutes,Seconds,Hundredths : word;
  TimeBuf,TimeTemp : String;

BEGIN
  GetTime(Hours,Minutes,Seconds,Hundredths);
  Str(Hours:2,TimeBuf);
  Str(Minutes:2,TimeTemp);
  IF TimeTemp[1] = ' ' THEN TimeTemp[1] := '0';
  TimeBuf := TimeBuf+':'+TimeTemp;
  Str(Seconds:2,TimeTemp);
  IF TimeTemp[1] = ' ' THEN TimeTemp[1] := '0';
  TimeBuf := TimeBuf+':'+TimeTemp;
  CRTPutFast(71,1,TimeBuf);
  IF (EdData.Status AND EdStatTextMod) <> 0 THEN
    CRTPutFast(38,1,'*')
  ELSE
    CRTPutFast(38,1,' ');
END;
{$F-}


{-InitWindow-------------------------------------------------------}
{                                                                  }
{ We're not playing with windows here, but since BINED can be run  }
{ as a self-windowing editor, the jargon speaks of windows that    }
{ simply aren't used in JED.  This proc sets up an editor control  }
{ block to receive a new file.  It does NOT read any file into     }
{ memory.  It doesn't even know the name of the file to come, only }
{ that one must be prepared for.                                   }
{------------------------------------------------------------------}
FUNCTION InitWindow : Boolean;

BEGIN
  {Initialize a window for the file}
  ExitCode :=
  InitBinaryEditor(
  EdData,                     { Editor control block }
  MaxFileSize,                { Size of data area to reserve for}
                              { binary editor text buffer, $FFE0 max}
  Windx1,                     { X of upper left corner; 1..80}
  Windy1,                     { Y of upper left corner}
  VisibleX,                   { X of lower right corner}
  VisibleY-1,                 { Y of lower right corner}
  True,                       { True = wait for retrace on CGA cards}
  EdOptInsert+EdOptIndent,    { Initial editor toggles}
  DefaultExtension,           { Default extension for file names}
  ExitCommands,               { Commands which will exit the editor}
  Addr(Clocker));             { Add a clock in the corner}
  CheckInitBinary(ExitCode);
  IF ExitCode = 0 THEN InitWindow := True
    ELSE InitWindow := False;
END;


{-ReadIntoWindow---------------------------------------------------}
{                                                                  }
{ This proc reads the actual workfile into memory and resets the   }
{ control block to reflect the new file.                           }
{------------------------------------------------------------------}

FUNCTION ReadIntoWindow : Boolean;

BEGIN
  { Read the file into memory: }
  ExitCode := ReadFileBinaryEditor(EdData, Fname);
  CheckReadFile(ExitCode,FileNameBinaryEditor(EdData));
  IF ExitCode = 0 THEN
    BEGIN
      ReadIntoWindow := True;
      { Reset the editor for the new file: }
      ResetBinaryEditor(EdData);
    END
  ELSE ReadIntoWindow := False;
END;


{-FileNameIsValid--------------------------------------------------}
{                                                                  }
{ All this does is filter out some of the more blatant ways to     }
{ enter a bad filename.  Strings with 0 length are passed along as }
{ acceptable, since a zero-length string tells JED to exit to DOS. }
{------------------------------------------------------------------}

FUNCTION FileNameIsValid(TempName : String) : Boolean;

VAR
  TestFile : FILE;
  I        : Integer;

BEGIN
  FileNameIsValid := True;
  IF Length(TempName) < 0 THEN
    FilenameIsValid := False
  ELSE
    IF Length(TempName) > 0 THEN
      IF Pos('.',TempName) > 9 THEN
        FileNameIsValid := False
      ELSE
        BEGIN
          Assign(TestFile,TempName);
          {$I-} Reset(TestFile); {$I+}
          I := IOResult;
          CASE I OF
            0 : Close(TestFile);
            2 : FileNameIsValid := True;
            ELSE FileNameIsValid := False;
          END;  { CASE }

        END;
END;



FUNCTION ExecWasSuccessful(ProgName,Parameters : STRING) : Boolean;

VAR
  ExecError : Integer;

BEGIN
  ExecError := DOSError;
  IF ExecError <> 0 THEN
    BEGIN

    END
END;




{-ExitBinaryEditor-------------------------------------------------}
{                                                                  }
{ This is most important subprogram in the whole system.  When one }
{ of a predefined set of "exit commands" is encountered in the     }
{ BINED edit stream, BINED lets control return to the caller, with }
{ the editor context retained in a largish dfata structure called  }
{ EdData.  As long as EdData isn't corrupted, BINED can be re-     }
{ entered as though control had never left it.                     }
{                                                                  }
{ During these excursions out of BINED, nearly anything can be     }
{ done under the illusion that BINED still has control.  On exit,  }
{ BINED supplies a code indicating which character sequence caused }
{ the exit.  This code can be parsed, and action taken depending   }
{ on the exit code.  Each JED command is in fact an exit command,  }
{ and everything that JED does apart from pure text editing and    }
{ changing edit files is done from subprograms called from within  }
{ ExitBinaryEditor.                                                }
{------------------------------------------------------------------}

FUNCTION ExitBinaryEditor(VAR EdData  : EdCB;
                          ExitCommand : Integer;
                          VAR Quit    : Boolean) : Boolean;

VAR
  ExitCode   : Word;
  FindFile   : SearchRec;
  LineLength : Integer;
  Escape     : Boolean;
  TempName   : String;


FUNCTION YesAnswer(prompt : string) : Boolean;
     {-Return true for a yes answer to the prompt}
VAR
  ch : Char;

BEGIN                     {YesAnswer}
  WriteStatus(prompt);
  REPEAT
    Ch := UpCase(readkey);
  UNTIL ch in ['Y', 'N'];
  Write(ch);
  YesAnswer := (ch = 'Y');
END;                      {YesAnswer}


PROCEDURE SaveCurrentFile;

BEGIN
  CRTPutFast(58,1,'Saving...');
  ExitCode := SaveFileBinaryEditor(EdData, MakeBackup);
  CheckSaveFile(ExitCode, FileNameBinaryEditor(EdData));
  CRTPutFast(58,1,'         ');
END;



  BEGIN                       {ExitBinaryEditor}
    CASE ExitCommand OF
     -1 : BEGIN     { ^K^D: Exit & Save file}
            SaveCurrentFile;
            ExitBinaryEditor := True;
            GoToXY(1,VisibleY);
          END;

      0 : BEGIN     { ^K^Q: Exit without saving }
            IF ModifiedFileBinaryEditor(EdData) THEN
              IF YesAnswer('File modified. Save it? (Y/N) ') THEN
                SaveCurrentFile;
              ExitBinaryEditor := True;
              GoToXY(1,VisibleY);
          END;

      1 : BEGIN      { Alt-F: Change current work file }
            SaveCurrentFile;             { Save file's data }
            ConfigData.CursorInset := EdData.CursorPos;
            { The work is done outside the main command loop... }
            ExitBinaryEditor := True
          END;

      2 : BEGIN      { Alt-X: Save if necessary and exit }
            IF ModifiedFileBinaryEditor(EdData) THEN
              SaveCurrentFile;
            ExitBinaryEditor := True;
            GotoXY(1,VisibleY);
          END;

      3 : BEGIN      { F1: Show help screen }
            ShowHelp;
            ExitBinaryEditor := False
          END;

      4 : BEGIN      { F2: Save File }
            SaveCurrentFile;
            ExitBinaryEditor := False
          END;

      5 : BEGIN      { F3: Invoke DEBUG on current .EXE file }
            IF ModifiedFileBinaryEditor(EdData) THEN
              SaveCurrentFile;            { If modified, save before EXECing! }
            SaveScreenOut(JEDScreen);     { Save out JED screen to heap }
            ClrScr;                       { Clear the screen }
            WITH ConfigData DO            { Exec to DEBUG with current .EXE }
              Exec('DEBUG.COM',EXEForm(WorkFile));
            SaveScreenOut(ExecScreen);    { Save last screen results }
            WaitForAnyKeystroke;          { Wait for a key press }
            BringScreenBack(JEDScreen);   { Bring JED screen back from heap }
            ExitBinaryEditor := False     { And duck back into BINED }
          END;


      6 : BEGIN      { F4: Update assemble/link command lines }
            SaveScreenOut(JEDScreen);
            ClrScr;
            GotoXY(17,1);
            Write('\\JED\\  Assemble/link command edit screen');
            GotoXY(30,5); Write('Assemble command:');
            GotoXY(32,9); Write('Link command:');
            GotoXY(1,13); Writeln('Line editing commands:'); Writeln;
            Writeln('CR:     Accepts changes and continues');
            Writeln('ESC:    Abandons changes and continues');
            Writeln('Ctrl-X: Clears entire field to empty string');
            Writeln('BS:     Destructive backspace');

            WITH ConfigData DO
              BEGIN
                GotoXY(1,6); Write(AssembleCommand);
                GotoXY(1,10);Write(LinkCommand);
                GetString(1,6,AssembleCommand,80,BlackOnWhite,Escape);
                GetString(1,10,LinkCommand,80,BlackOnWhite,Escape);
              END;
            BringScreenBack(JEDScreen);
            ExitBinaryEditor := False;
          END;

      7 : BEGIN      { F5: Exec to DOS command line }
            IF ModifiedFileBinaryEditor(EdData) THEN
              SaveCurrentFile;            { If modified, save before EXECing! }
            SaveScreenOut(JEDScreen);     { Save out JED screen to heap }
            ClrScr;                       { Clear the screen }
            Exec(GetEnv('COMSPEC'),'');   { Execute the DOS command processor }
            BringScreenBack(JEDScreen);   { Bring JED screen back from heap }
            ExitBinaryEditor := False     { And duck back into BINED }
          END;

      8 : BEGIN      { F6: Examine last Exec screen }
            SaveScreenOut(JEDScreen);
            ClrScr;
            IF ExecScreen.SavePtr <> NIL THEN
              BEGIN
                BringScreenBack(ExecScreen);
                SaveScreenOut(ExecScreen);
              END
            ELSE     { NIL SavePtr means no Exec screen has been saved yet }
              BEGIN
                GotoXY(12,11);
                Writeln('No assemble/link display has been generated yet.');
                GotoXY(12,12);
                Writeln('Until you assemble or link by pressing F9 or F10,');
                GotoXY(12,13);
                Writeln('Nothing will be displayable by pressing F6.');
              END;
            WaitForAnyKeystroke;
            BringScreenBack(JEDScreen);
            ExitBinaryEditor := False
          END;


      9 : BEGIN      { F9: Assemble only }
            IF ModifiedFileBinaryEditor(EdData) THEN
              SaveCurrentFile;            { If modified, save before EXECing! }
            SaveScreenOut(JEDScreen);     { Save out JED screen to heap }
            ClrScr;                       { Clear the screen }
            WITH ConfigData DO            { Exec to the assembler }
              BEGIN
                Exec(GetProg(AssembleCommand),
                     GetParms(AssembleCommand,WorkFile));
                IF ExecWasSuccessful(GetProg(AssembleCommand),
                                     GetParms(AssembleCommand,WorkFile))
                THEN SaveScreenOut(ExecScreen);  { Save assembler results }
              END;
            WaitForAnyKeystroke;          { Wait for a key press }
            BringScreenBack(JEDScreen);   { Bring JED screen back from heap }
            ExitBinaryEditor := False     { And duck back into BINED }
          END;

      10: BEGIN      { F10: MAKE: Assemble & link (if necessary), and GO }
            IF ModifiedFileBinaryEditor(EdData) THEN
              SaveCurrentFile;            { In case we EXEC something ugly }
            SaveScreenOut(JEDScreen);     { Save out JED screen to heap }
            ClrScr;
            { If the workfile has been changed since the last Make, }
            { *OR* if the .EXE file does not exist on disk, reMake: }
            IF MustMake(ConfigData.WorkFile) THEN
              BEGIN
                AssembleAndLink;
                SaveScreenOut(ExecScreen); { Save assemble/link results }
                Exec(EXEForm(ConfigData.WorkFile),ConfigData.TestParms);
              END
            ELSE
              BEGIN
                { If it exists, we run it--if not, reMake and run it: }
                Exec(EXEForm(ConfigData.WorkFile),ConfigData.TestParms);
                IF DOSError <> 0 THEN
                  BEGIN
                    AssembleAndLink;
                    SaveScreenOut(ExecScreen);  { Save assemble/link results }
                    Exec(EXEForm(ConfigData.WorkFile),ConfigData.TestParms);
                  END
              END;

            WaitForAnyKeystroke;
            BringScreenBack(JEDScreen);
            ExitBinaryEditor := False     { And duck back into BINED }
          END;


    END; { CASE }
  END;                        { ExitBinaryEditor }



{------------------------------------------------------------------}
{                               JED                                }
{                        MAIN PROGRAM BLOCK                        }
{                                                                  }
{------------------------------------------------------------------}

BEGIN
  { The Monochrome Boolean variable is exported by unit TextInfo }
  { It determines the attribute for the prompt bar: }
  IF Monochrome THEN BarAttribute := $70  { Inverse video  }
    ELSE BarAttribute := $1E;             { Yellow on blue }

  DOSScreen.SavePtr  := NIL; { Make sure all screen pointers are NIL }
  JEDScreen.SavePtr  := NIL;
  ExecScreen.SavePtr := NIL;

  {Begin by saving the current DOS screen onto the heap, }
  { so that we can restore the screen upon exiting JED.  }
  SaveScreenOut(DOSScreen);
  ClrScr;

  Fname := GetFileName(ConfigData);    { Get a file name }
  UpdateConfigData := False;           { Don't update until we know }
                                       { the file is good }

  {------------------------------------------------------------------}
  { This is the edit loop; it repeats until the user quits to DOS    }
  { with Alt-X, Ctrl-KD, or Ctrl-KQ.  On each pass through the loop  }
  { a different text file is loaded and edited.  The name is gotten  }
  { from the user via the IF block on the other side of the main     }
  { command loop; control then loops back here and the file is       }
  { opened for a new edit.                                           }
  {------------------------------------------------------------------}

  REPEAT   { Given a name in FName, This loop loads & edits a file }
    Quit := False;          { When this becomes True, we exit to DOS }
    ExitCommand := 0;       { Exit command 0 = quit without saving   }

    IF InitWindow THEN
      BEGIN
        { Read the file into memory: }
        ExitCode := ReadFileBinaryEditor(EdData, Fname);
        CheckReadFile(ExitCode, FileNameBinaryEditor(EdData));
        { Reset the editor for the new file: }
        ResetBinaryEditor(EdData);
        { Bined allows us to position the cursor by specifying a byte }
        { offset into the text file.  We can "remember" this offset & }
        { set the cursor to it before editing: }
        EdData.CursorPos := ConfigData.CursorInset;
      END
    ELSE
      BEGIN
        ShowJEDErrorMessage(5,20,'Not enough heap space to load a file...');
        WaitForAnyKeystroke;
        Quit := True;
      END;

    VidBlast(TextBufferOrigin,@JEDBar,  { Blast in the JED status line     }
             VisibleX,VisibleY,         { Dimensions of current screen     }
             1,VisibleY,                { Load it at bottom screen line    }
             80,1,                      { JEDBar is 80 wide and 1 high     }
             $1E,                       { Use the yellow on blue attribute }
             0);                        { No interspersed blank lines      }


    {------------------------------------------------------------------}
    {  This is the main command loop; within this loop a single file   }
    {  is edited.                                                      }
    {------------------------------------------------------------------}

    WHILE NOT Quit DO
      BEGIN
        ExitCommand :=
        UseBinaryEditor(
        EdData,                   { Editor control block for this window }
        '');                      { No startup commands passed to editor }
        Quit := ExitBinaryEditor(EdData,ExitCommand,Quit); { Parse commands }
      END;

    {------------------------------------------------------------------}
    {  End main command loop                                           }
    {------------------------------------------------------------------}

    { We've finished with the file being edited in the loop above; now }
    { release the heap space used by the editor text buffer and data   }
    { structure: }
    ReleaseBinaryEditorHeap(EdData);

    {------------------------------------------------------------------}
    {  This IF statement handles changing of the current work file.    }
    {  By this point the old file has been disposed from the heap and  }
    {  a new file needs to be identified and opened.  The file is only }
    {  *identified* here; the file is opened and loaded with the same  }
    {  code that does it to the original file loaded when JED first    }
    {  begins executing
    {------------------------------------------------------------------}

    IF ExitCommand = 1 THEN       { IF Alt-F was pressed, change file }
      BEGIN
        { Prompt the user for a new file name: }
        REPEAT
          TempName := RequestFileName(ConfigData);
          IF Pos('.',TempName) = 0 THEN
            TempName := TempName + DefaultExtension;
        UNTIL FileNameIsValid(TempName);   { Make sure it's a valid name }
        IF Length(TempName) <= 0 THEN Quit := True      { Quit to DOS }
          ELSE
        BEGIN                     { Otherwise, assert new filename }
          FName := ForceCase(UP,TempName);
          IF FName <> Configdata.WorkFile THEN { If same file, skip update }
          WITH ConfigData DO      { Otherwise, update configuration record }
            BEGIN
              WorkFile := FName;
              CursorInset := 0;
            END;
          Quit := False           { And loop back & work on new file }
        END
      END;

  UNTIL Quit;  { When we hit this point and Quit is True, it's back to DOS }

  { Save the updated configuration data to disk: }
  IF UpdateConfigData THEN SaveConfigFile(ConfigData);

  { Finally, we restore the DOS screen saved on the heap before we began: }
  BringScreenBack(DOSScreen)

END.
