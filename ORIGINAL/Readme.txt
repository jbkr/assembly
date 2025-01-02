READ.ME for JED Version 1 for Turbo Pascal 5.0

JED is a simple editor/shell for experimenting with assembly language
using either TASM or MASM.  I describe it in detail in my book,
ASSEMBLY LANGUAGE STEP BY STEP, Chapter 4.  There is a doc file on
this disk as well, which is basically the book chapter cut loose and
exported as pure ASCII.  Use JREAD to read JEDDOC.ASC.

(c) 2004, 1992 by Jeff Duntemann
Portions of JED and JREAD (c) 1988 Borland International

All rights reserved; rights granted as specified below.  THIS IS
NOT A PUBLIC DOMAIN PRODUCT.  It's what I call Swapware.  If you've
bought my assembly book you've already paid for it. Otherwise, send me
$10 or so worth of something that isn't money.  See below for
suggestions.

Mail contributions to:

Jeff Duntemann
145 Stanwell St.
Colorado Springs CO 80906

Nonetheless, I grant blanket permission to distribute this disk freely.
This includes BBSes, FTP sites, user group libraries, shareware 
anthologies, etc.


                   ////WHAT'S ON THIS DISK\\\\

READ.ME          This file
JED.EXE          JED executable
JED.PAS          JED source code for Turbo Pascal V5.0
JEDSCRN.ASM      External for JED
VIDBLAST.ASM     External for JED
TEXTINFO.PAS     Utility unit for JED
JEDDOC.ASC       JED ASCII documentation

JREAD.EXE        The 25-line JREAD utility (see below)


                //////HOW TO READ THE FILES\\\\\

This disk contains several versions of my JREAD utility.  JREAD.EXE
is a "readme" program.  It's a read-only text editor, derived
from the FIRSTED editor in Borland's wonderful (but now extinct)
Turbo Pascal Editor Toolbox.  You can load a text file into JREAD,
scroll around the file using the standard WordStar control codes, and
mark blocks and write a mark block out to disk.  The only thing
you *can't* do is alter the file or enter new characters.

You invoke JREAD like this:

C:\>JREAD JEDDOC.ASC

This will run JREAD and load the JED ASCII documentation data
file for examination.  To exit JREAD, press Ctrl-KQ.

Within JREAD you can use any of the WordStar cursor control
sequences, plus the cursor keypad keys.  PgUp and PgDn are the
easiest ways to get around.  You can search for keywords using
Ctrl-QF.  You can drop markers with F7 (Ctrl-KB) and F8 (Ctrl-KK)
and then write the block out to disk with Ctrl-KW.

IMPORTANT NOTICE!  I have included the source code for JED on this
disk, but you can't necessarily recompile it.  You *must* have the
Turbo Pascal Editor Toolbox V5.0, which Borland no longer sells, but
which I cannot distribute regardless.  If you can scrounge a copy of the
Toolbox, you're in fine shape, keeping in mind that the Turbo Pascal
.TPU format changes with every major release, and you will probably
need Turbo Pascal V5.0 *specifically* to recompile JED.  This is an
ugly trap but I don't know of any legal way around it.

The same problem befalls JREAD.  I "wrote" it by pulling things out of
FIRSTED, one of the example programs in the Editor Toolbox. So there
again, the source code really belongs to Borland.  I just fooled with
it some.

BUG-ETTE REPORT:  To make sure everything works, put DEBUG and your
assembler in the *same* directory with JED!

NOW! There's a subdirectory called ASMENV on this diskette, and it
contains Gene Fowler's AsmEnv utility.  It does a lot of the same
things that JED does, but it's newer and faster and better.  It's
not explicitly mentioned in the book, but give it a try!


                    ////////SWAPWARE\\\\\\\\

This is an experiment.  Let's call it "Swapware."  The concept is
essentially the shareware concept, with the twist that I don't
want you to send money except, perhaps, as a last resort.

Instead, let's consider it a barter transaction.  I consider the
disk worth $15-$20 or so.  Decide what the disk is worth to you,
and send me the equivalent value of something I can use.  I love
getting surprises in the mail, and lord knows, I could use a
little excitement in my life.

It's not like I'm difficult to please, being a tinkerer, packrat,
curio collector, and genteel eccentric.  Here's a list of things
I favor:

Stamps.  I collect fancy cancels & interesting postmarks of any
vintage.  Also, ANY postal history from Orchard Place, Illinois
(1870's to 1937) where my great-grandfather F. W. Duntemann was
postmaster for nearly 40 years.  I'll even pay extra for this one.
In 25 years of looking I've only seen one specimen, and the owner
wouldn't sell!

Traditional hardware:  Nuts, bolts, washers, spade connectors,
spade bolts, hole plugs, angle brackets, solder, spacers, standoffs,
whatever.

Electronic hardware and parts:  Resistors, capacitors (especially
variables), diodes, transistors, FETs, LEDs, sockets, insulators
(especially antenna dogbone), tinned hook-up wire, speakers,
plugs, jacks, coil forms, antique radio parts (I restore old
sets) including tubes, tube sockets, calibrated knobs, plug-in
shortwave coil forms, IF transformers and other coils; and oddiments
like ground straps, coax connectors, solder, spools of magnet
wire (any guage), heating elements, PC board, whatever.

Some linear ICs: LM386, NE602 and its relatives, and (especially)
the Motorola FM chips: MC3362 and MC2833.  Any chips pertaining to
radio (as opposed to digital stuff) are most enthusiastically
welcome.  It's not all for me; I make "baggie" parts kits for local
kids who want to try building crystal sets and other simple radios.

Stepper motors.  Solar cells.

Tools:  Taps, drills, end mills, allen wrenches, whatever.

Metal stock:  (I have my own lathe and mill.)  Aluminum bar, rod,
tube, hex, sheet stock; ditto in copper & brass; stainless steel;
magnesium; lead; also mercury.

Ham radio and/or electronics magazines from WW-II to the present.
Don't fret duplicates; I give the dupes to local kids to get them
interested.  Also old ARRL handbooks and Allied Radio catalogs
from the Sixties.

Other odd tech:  Lenses, eyepieces, prisms, mirrors, gears,
pulleys, clutches, shaft fittings, racks, pinions, worm wheels,
telescope parts, lamps, bearings, motors, hydraulic and air
fittings, valves, filters, whatever.

Also:  Technology books, audio CD's, collectible comix, esp. Sixties
Crumb et. al., Fifties-type series or parallel Christmas tree
lamp strings and/or bulbs in good condition, Fifties novelty
Christmas tree lights (bubblers, birds, etc.), diecast toys, 
silver coins, pre-'55 S-pennies, 40's/50's deco/kitsch, pole 
insulators, Meccano construction sets & parts.

Or, hey, be creative.  I won't frown at dish detergent, T-shirts 
(medium), or nearly anything else that will survive a trip through 
the mail.  Let's have fun; if we can make this a tradition in the 
fringe software industry we can all have a good time and avoid some 
of the bad karma generated by the passing around of Real Money.

Thanks.  Let's try it!

--73--

--Jeff Duntemann K7JPD, ex-KG7JF, ex-KI6RA, ex-KB2JN, ex-WB9MQY, ex-WN9MQY

Author of COMPLETE TURBO PASCAL editions 1,2, & 3
          TURBO PASCAL SOLUTIONS
          ASSEMBLY LANGUAGE FROM SQUARE ONE
          ASSEMBLY LANGUAGE STEP
          Borland's original OOP GUIDE (TP5.5)
          BORLAND PASCAL FROM SQUARE ONE
          JEFF DUNTEMANN'S WI-FI GUIDE
Co-Author of INSIDE THE POWER PC REVOLUTION with Ron Pronk
Co-Author of DELPHI PROGRAMMING EXPLORER and THE NEW DELPHI 2
PROGRAMMING EXPLORER, with Don Taylor and Jim Mischel.
Co-Author of DEGUNKING WINDOWS with Joli Ballew

Ex-founder/editor of Borland's TURBO TECHNIX (1987-1988)

Founder/editor of PC TECHNIQUES, a magazine for PC programmers, 
which became VISUAL DEVELOPER MAGAZINE in the spring of 1996.
(1989-2000)
