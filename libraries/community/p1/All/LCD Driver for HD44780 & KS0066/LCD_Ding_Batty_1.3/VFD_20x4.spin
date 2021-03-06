{{
┌────────────────────────────────┐
│ 20x4 VFD Driver                │
├────────────────────────────────┴────────────────────┐
│  Version : 1.3                                      │
│  By      : Tom Dinger                               │   
│            propeller@tomdinger.net                  │
│  Date    : 2010-11-14                               │
│  (c) Copyright 2010 Tom Dinger                      │
│  See end of file for terms of use.                  │
├─────────────────────────────────────────────────────┤
│  Width      : 20 Characters (columns)               │
│  Height     : 4 Lines (rows)                        │
│  Controller : similar to HD44780                    │
└─────────────────────────────────────────────────────┘
}}
{
  Version History:
  1.1 -- 2010-09-23 -- Initial release of 20x4 VFD driver, in
                       the LCD_Ding_Batty package.

  1.3 -- 2010-11-14 -- changed the pin variable names to allow for
                       use of either the 4-bit or the 8-bit lowest-
                       level driver; added an alternate OBJ
}

{{

This is a driver for a 20 character, 4 line VFD display.

The display used for testing is part number CU20045SCPB-U1J, manufactured
by Noritake Itron.

I found the correct (old) datasheet for my exact display at:
    https://www1.elfa.se/data1/wwwroot/assets/datasheets/07556087.pdf
Note that this model is no longer available, but newer versions should
be compatible with this one.

It seems to use its own display controller that is command-compatible
with the HD44780 display controller, with a few small differences.

This driver provides direct access to the functions of the display:
- writing text
- positioning the cursor
- setting the cursor mode: invisible, underline, blinking block
- shifting the display left and right
- shifting the cursor left and right.
- adjusting the display brightness.

This driver uses a lower-level driver object that manages initialization
of the display and data and command I/O, so that this object (and other
objects at this level) can focus on management of displayed data for
a particular geometry of display. 

Resources:
---------
Noritake Itron display CU20045SCPB-U1J datasheet (from 1997):
    https://www1.elfa.se/data1/wwwroot/assets/datasheets/07556087.pdf
    
Hitachi HC44780U datasheet:
  http://www.sparkfun.com/datasheets/LCD/HD44780.pdf
Samsung KS0066U datasheet:
  http://www.datasheetcatalog.org/datasheet/SamsungElectronic/mXuuzvr.pdf
Samsung S6A0069 datasheet (successor to KS0066U):
  http://www.datasheetcatalog.org/datasheet/SamsungElectronic/mXruzuq.pdf
  

Interface Pins to the Display Module:
------------------------------------
Note that the actual assignments of functions to pins is done by
the code that uses this object -- the pin numbers are passed into
the Init() method.

   R/S  [Output] Indicates if the operation is a command or data:
                   0 - Command (write) or Busy Flag + Address (read)
                   1 - Data
   R/W  [Output] I/O Direction:
                   0 - Write to Module
                   1 - Read From Module
   E    [Output] Enable -- triggers the I/O operation 
   DB0  [In/Out] Data Bus Pin 0 -- bidirectional, tristate 
   DB1  [In/Out] Data Bus Pin 1 -- bidirectional, tristate
   DB2  [In/Out] Data Bus Pin 2 -- bidirectional, tristate
   DB3  [In/Out] Data Bus Pin 3 -- bidirectional, tristate
   DB4  [In/Out] Data Bus Pin 4 -- bidirectional, tristate 
   DB5  [In/Out] Data Bus Pin 5 -- bidirectional, tristate
   DB6  [In/Out] Data Bus Pin 6 -- bidirectional, tristate
   DB7  [In/Out] Data Bus Pin 7 -- bidirectional, tristate


DDRAM Address Map:
------------------   
   DDRAM ADDRESS USAGE FOR A 4-LINE DISPLAY (up to 20 columns)

    00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19   <- CHARACTER POSITION
   ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
   │00│01│02│03│04│05│06│07│08│09│0A│0B│0C│0D│0E│0F│10│11│12│13│  <- ROW0 DDRAM ADDRESS
   │20│21│22│23│24│25│26│27│28│29│2A│2B│2C│2D│2E│2F│30│31│32│33│  <- ROW1 DDRAM ADDRESS
   │40│41│42│43│44│45│46│47│48│49│4A│4B│4C│4D│4E│4F│50│51│52│53│  <- ROW2 DDRAM ADDRESS
   │60│61│62│63│64│65│66│67│68│69│6A│6B│6C│6D│6E│6F│70│71│72│73│  <- ROW3 DDRAM ADDRESS
   └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘

}}      

CON

  ' Display dimensions
  NumLines =  4
  NumCols  = 20
  
  Line0Col0Addr       = $00
  Line1Col0Addr       = $20
  Line2Col0Addr       = $40
  Line3Col0Addr       = $60

  ' CharsInOneLine is the number of character positions in display RAM
  ' for one line. It does not necessarily correspond to the number
  ' of visible characters in one row of the display. This is used to
  ' determine when the cursor has moved off the end of a "line" in
  ' display memory.
  CharsInOneLine      = 20  

  LF  = 10


OBJ
  ' The LCDBase object provides access to the actual display device,
  ' and manages the details of the data interface (4 or 8 bit) and
  ' the other signals to the controller.
  '
  ' Pick only one of thexe lines, and make sure that the top-level
  ' program passes in the proper values for the data pins:
  ' 4 consecutive pins for the 4-bit interface, or 8 consecutive
  ' pins for the 8-bit interface.
  
  LCDBase : "LCDBase_4bit_direct_HD44780"
  'LCDBase : "LCDBase_8bit_direct_HD44780"

VAR
  ' CurDisplayCmd contains the most recent settings for the
  ' Display: display on/off, and cursor mode. It is used when changing
  ' only some of the display properties in methods of this obejct.
  byte CurDisplayCmd

  ' CurDisplayShift is the amount the display has been shifted,
  ' relative to the position after a Clear.
  ' Another way to interpret this value is that it is the display RAM
  ' address shown in the leftmost character position on the display.
  ' So, a left-shift of the display will increment this value.
  byte CurDisplayShift
  

PUB Init( Epin, RSpin, RWpin, DBHighPin, DBLowPin )
'' Initialize the display: assign I/O pins to functions, initialize the
'' communication, clear it, turn the display on, turn the
'' cursor off.

  ' This display ignores the 1-line/2-line flag in the initialization
  ' commands as it is a 4-line display.
  LCDBase.Init( true, Epin, RSpin, RWpin, DBHighPin, DBLowPin )

  ' The following is how LCDBase initialized the display.
  ' If we wanted something different, we could issue the command
  ' ourselves at this point, or retrieve it from LCDBase.
  CurDisplayCmd   := LCDBase#DispCtlCmd_On_CrsrOff_NoBlink
  CurDisplayShift := 0
  

PUB RawSetPos(addr)
'' Setthe next display RAM address that will be written, without
'' doing any adjustments for the geometry of the display.
'' This method is intended for special uses, and will not be used
'' by typical applications.

  LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + addr )


PUB RawWriteChr( chr )
'' Write a character to the display, without adjustments for cursor
'' positioning on the display. Primarily used for "special effects".
'' Generally, PrintChr() will be more useful.

  return LCDBase.WriteByte( chr )
  ' no other adjustments
  

PUB RawWriteStr( str )
'' Write a series of characters (a string) to the display, without
'' adjusting for cursor positioning on the display. Primarily used for
'' "special effects". Generally, PrintStr() will be more useful.

  LCDBase.WriteData( str, strsize(str) )

PUB RawReadData : chr
'' read the data at the current position
'' NOTE: this does not always work as expected -- see the
'' relevant data sheets. It should always work right
'' after a cursor shift or cursor address operation.

  chr := LCDBase.ReadData
  'return chr


PUB Clear
'' Clear the display: write all spaces to the Display RAM, set the
'' display back to unshifted, cursor back to first character (leftmost)
'' on the display.

  LCDBase.WriteCommand( LCDBase#ClearDisplayCmd )
  CurDisplayShift := 0

  ' This display controller does not share the same "bug" that
  ' the KS0066 seems to have: it does not need a delay after
  ' issuing the Clear command before the display RAM address
  ' returned when no longer busy is correct.
  'usDelay( 20 )


PUB GetPos : RowAndCol
  return MapAdrToPos( LCDBase.WaitUntilReady )

  
PUB SetPos(pos)
'' Sets the cursor position, to the row and column encoded into the
'' position value:
'' pos -- row and column, encoded as (row << 8) | col

  return SetRowCol( (pos >> 8), pos & $FF )


PUB SetRowCol(line,col) | addr
'' Position the cursor to a specific line and character position (column)
'' within that line.
'' line -- 0-based line number, masked to range 0..3
'' col  -- 0-based column number, or character position, in the line,
''         limited to 0..19.

  case line & $03 ' limit line to 0..3
    3: addr := Line3Col0Addr
    2: addr := Line2Col0Addr
    1: addr := Line1Col0Addr
    0: addr := Line0Col0Addr

  ' We want these positions to correspond to what is showing on the
  ' display, so we adjust the location to write to, based on the
  ' amount the display has been shifted.
  addr += (col + CurDisplayShift) // CharsInOneLine

  return LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + addr )

' QUESTION: How does the cursor increment when writing to the display?
' ANSWER: The cursor advances correctly through all four lines of the
'         display, so we don't need to do any special cursor
'         position control when writing characters.


PUB PrintChr( chr ) : curadr | col, row
'' Displays the character passed in at the current cursor position, and
'' advances the cursor position.
'' Returns the display RAM address of the cursor before writing the char

  ' Note that there is no need for special handling when writing,
  ' since the cursor advances through the lines the way we want,
  ' but only if the display is unshifted.

  if ( chr == LF )
    return Newline

  curadr := LCDBase.WriteByte( chr )

  ' This display handles cursor advance when the display is shifted
  ' a little differently, so we have to compensate here:
  ' - if the cursor is on the last character of the line in display
  '   RAM as if _unshifted_, the cursor advances to the next line, even
  '   if it looks like there are more characters on the line. We have
  '   to adjust for this.
  ' - if the cursor _appears_ to be on the last character of a line,
  '   when the display is shifted, it will seem to wrap back to the
  '   start of the current line, instead of advancing to the next line.

  if ( CurDisplayShift <> 0 )
    ' Adjust for the various boundary conditions
    row := MapAdrToLine( curadr )
    col := curadr & $1F
    if ( col == constant(CharsInOneLine - 1) )
      ' don't change lines
      RawSetPos( curadr & $60 ) ' offset 0 in the current line
      return curadr

  ' Check for line wrap...
    if ( MapAdrToCol( curadr ) == constant(CharsInOneLine-1) )
      ' change lines
      SetRowCol( row + 1, 0 )
     
  ' return curadr


PUB PrintStr( str )
'' Prints out each character of the string by calling PrintChr().

  ' For each character of the string
  '   printchr(c)
  repeat strsize(str)
    PrintChr( byte[str++] )


PUB Newline
'' Advance to the start of the next line of the display.

  ' TODO: do we clear the next line?

  return SetRowCol( MapAdrToLine(LCDBase.WaitUntilReady)+ 1, 0 )

PUB Home
'' Move the cursor (and the next write address) to the first character
'' position on the display.

  ' TODO: Use the LCDBase#CursorHomeCmd -- this will also "unshift"
  ' a shifted display.

  SetRowCol( 0, 0 )

PUB GetDisplayAddr : adr
'' Returns the next RAM address (the current cursor position).

  return LCDBase.WaitUntilReady '  & LCDBase#DisplayRamAddrMask

PUB usDelay(us)
'' Delay the specified number of microseconds, but not less than 382 us.

  LCDBase.usDelay(us)

PUB CursorOff
'' Turns the cursor off

  CurDisplayCmd &= !(LCDBase#DispCtl_CursorOn | LCDBase#DispCtl_Blinking)
  'CurDisplayCmd |= LCDBase#DispCtl_CursorOff  ' = $00
  LCDBase.WriteCommand( CurDisplayCmd )

PUB CursorBlink
'' Turn the cursor on, as a blinking rectange: the character cell
'' alternates between the character shown at that positino, and all
'' pixels on (bright blue box).

  'CurDisplayCmd &= !(LCDBase#DispCtl_CursorOn | LCDBase#DispCtl_Blinking)
  CurDisplayCmd |= LCDBase#DispCtl_CursorOn | LCDBase#DispCtl_Blinking
  LCDBase.WriteCommand( CurDisplayCmd )

PUB CursorSteady
'' Turns the cursor on
'' This display does not have an underline line -- there are exactly 5x7
'' pixels in the character. So "Steady" is the same as Blink.

  CursorBlink

  'CurDisplayCmd &= !(LCDBase#DispCtl_CursorOn | LCDBase#DispCtl_Blinking)
  'CurDisplayCmd |= LCDBase#DispCtl_CursorOn ' | LCDBase#DispCtl_NoBlinking
  'LCDBase.WriteCommand( CurDisplayCmd )
 
PUB DisplayOff
'' Turns the dislpay off.

  CurDisplayCmd &= !LCDBase#DispCtl_DisplayOn
  LCDBase.WriteCommand( CurDisplayCmd )

PUB DisplayOn
'' Turns the display on -- makes no change to the contents of display RAM,
'' it just enabled the display of what is already in RAM.

  CurDisplayCmd |= LCDBase#DispCtl_DisplayOn
  LCDBase.WriteCommand( CurDisplayCmd )

PUB ShiftCursorLeft | curadr, col
'' Shift the cursor position to the left one character.

  curadr := LCDBase.WriteCommand( LCDBase#CursorShiftCmd_Left )

  ' TODO: Is that enough?
  ' NOTE that the cursor _will_ change lines when shifted.

PUB ShiftCursorRight | curadr, col
'' Shift the cursor position to the right one character.

  curadr := LCDBase.WriteCommand( LCDBase#CursorShiftCmd_Right )

  ' TODO: Is that enough?
  ' NOTE that the cursor _will_ change lines when shifted.

' QUESTION: How do lines rotate?
' ANSWER: The four lines rotate independently, so all column
'         calculations are done within a single row.

PUB ShiftDisplayLeft | addr
'' This shifts the entire display contents to the left one character.
'' The cursor "moves" with the display, so that it appears to stay
'' on the same character being displayed.

  addr := LCDBase.WriteCommand( LCDBase#DisplayShiftCmd_Left )
  CurDisplayShift += 1
  if ( CurDisplayShift => CharsInOneLine )
    CurDisplayShift -= CharsInOneLine ' limit to $00..$13
  

PUB ShiftDisplayRight | addr
'' This shifts the entire display contents to the right one character.
'' The cursor "moves" with the display, so that it appears to stay
'' on the same character being displayed.

  addr := LCDBase.WriteCommand( LCDBase#DisplayShiftCmd_Right )
  if ( CurDisplayShift == 0 )
    CurDisplayShift := constant(CharsInOneLine-1) ' limit to $00..$13
  else
    CurDisplayShift -= 1


PUB SetBrightness( percent ) | level
'' Sets the brightness of the VFD:
'' percent -- sets the brighness of the display, from 0% to 100%
'' Note that there are really only 4 brightness levels: 25%, 50%
'' 75% and 100%. For brightness below 25%, we turn the display off.
'' Brightness is rounded down.

  if ( percent < 25 )
    return DisplayOff

  ' Now, (percent / 25) gives 0 for off, 1 for 25%, 2 for 50% 3 for 75% and 4 for 100%
  ' We map that to command levels:
  '     1 --> 3, 2 --> 2, 3 --> 1, 4 --> 0
  level := 4 - ((percent <# 100) / 25)

  LCDBase.ResendFunctionSetCmd ' send the current Function Set Cmd value
  LCDBase.WriteByte( level )
  return DisplayOn ' make sure the display is on -- we might have turned it off.


PUB WriteCharGen( index, pRows ) | c, curadr
'' Write the supplied pattern to the character generator RAM.
'' index -- The character index to write, from 0..7
''          The value is masked to that range
'' pRows -- a pointer to the character cell row data; only the low
''          order 5 bits are used for the character.
''          Any byte outside the range $00..$1F will end the range
''          written to the Char Gen RAM

  ' We save the current cursor position so we can restore it later...
  curadr := LCDBase.WriteCommand( LCDBase#SetCgRamAddrCmd + ((index & $07) << 3) )
  
  c := byte[ pRows++ ]   ' get the first character  
  repeat while ( (c & $E0) == 0 )
    ' The high bits are not set
    ' NOTE: This assumes addresses auto-increment 
    LCDBase.WriteByte( c )
    c := byte[ pRows++ ]

  ' Now that we have written all the CG data, restore the
  ' current cursor position
  LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + curadr )


PUB WriteCharGenCnt( index, line, pRows, len ) | curadr
'' Write the supplied pattern to the character generator RAM.
'' index -- The character index to write, from 0..7
''          The value is masked to that range
'' line -- Scan line to start within the character, from 0..7
''         The value is masked to that range.
'' pRows -- A pointer to the character cell row data; only the low
''          order 5 bits are used for the character.
''          Any byte outside the range $00..$1F will end the range
''          written to the Char Gen RAM
'' len -- Number of character scan lines to write -- one character
''        contains 8 scan lines. NOTE: Not range-limited!

  ' We save the current cursor position so we can restore it later...
  curadr := LCDBase.WriteCommand( LCDBase#SetCgRamAddrCmd + ((index & $07) << 3) + (line & $07) )
  
  repeat len
    ' The high bits are not set
    ' NOTE: This assumes addresses auto-increment 
    LCDBase.WriteByte( byte[ pRows++ ] )

  ' Now that we have written all the CG data, restore the
  ' current cursor position
  LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + curadr )

    
' ---------------------------------------------------------------
' We define some helper functions: convert between an address and a
' row/column position

PRI MapAdrToLine( adr ) : line
  ' Given a display RAM address, determine the display row
  ' containing it, using the current display shift.
  return (adr >> 5) & $03

PRI MapAdrToCol( adr ) : col
  ' Given a display RAM address, determine the display column
  ' containing it, using the current display shift.

  return ( (adr & $1F) + CharsInOneLine - CurDisplayShift ) // CharsInOneLine
  ' return col

PUB MapAdrToPos( adr ) : RowAndCol
  RowAndCol := (adr << 3) & $0300

  ' Now, adjust for the disploay shift
  RowAndCol += ( (adr & $1F) + CharsInOneLine - CurDisplayShift ) // CharsInOneLine
  ' return RowAndCol


' TODO:
' - Clear to EOL method?
'
' Open questions:
' - Do we need, for the FunctionSet command:
'   - IncrementingAddresses
'   - DecrementingAddresses
'   - Enable/Disable display shift on write

{{
Detailed Display Information:
----------------------------

The display controller for this display uses the same command set
as the Samsung KS0066 and Hitachi HD44780 controllers, but it
behaves slightly differently in a number of respects.

Firstly, it is a real 4-line display controller, in that when the
display is shifted, each line rotates independently. In a 20x4
display using a "real" HD44780 controller, it is really a 40x2
display, with the right half of the first two lines under the left
halves, as the second two lines, so that when rotated, lines 1 and 3
rotate together, as do lines 0 and 2.

This means that we don't need to adjust the cursor position when it
moves off the right end of a line, because it will advance correctly
to the start of the next line.

Secondly, this display has a coarse brightness control available through
the command set, and it does not respond to the usual "contrast" control
pin voltage like LCD displays. So this driver as a SetBrightness method.

This driver also goes to a lot of trouble to get character output to "flow"
from one line to the next, even if the underlying display has been shifted.
So there is logic in the PrintChr method to handle the line boundary
cases when the display is shifted.


DDRAM Address Map:
------------------   
   DDRAM ADDRESS USAGE FOR A 4-LINE DISPLAY (up to 20 columns)

    00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19   <- CHARACTER POSITION
   ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
   │00│01│02│03│04│05│06│07│08│09│0A│0B│0C│0D│0E│0F│10│11│12│13│  <- ROW0 DDRAM ADDRESS
   │20│21│22│23│24│25│26│27│28│29│2A│2B│2C│2D│2E│2F│30│31│32│33│  <- ROW1 DDRAM ADDRESS
   │40│41│42│43│44│45│46│47│48│49│4A│4B│4C│4D│4E│4F│50│51│52│53│  <- ROW2 DDRAM ADDRESS
   │60│61│62│63│64│65│66│67│68│69│6A│6B│6C│6D│6E│6F│70│71│72│73│  <- ROW3 DDRAM ADDRESS
   └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
}}
{{

  (c) Copyright 2010 Tom Dinger

┌────────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                           │                                                            
├────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a     │
│copy of this software and associated documentation files (the               │
│"Software"), to deal in the Software without restriction, including         │
│without limitation the rights to use, copy, modify, merge, publish,         │
│distribute, sublicense, and/or sell copies of the Software, and to          │
│permit persons to whom the Software is furnished to do so, subject to       │
│the following conditions:                                                   │
│                                                                            │
│The above copyright notice and this permission notice shall be included     │
│in all copies or substantial portions of the Software.                      │
│                                                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS     │
│OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                  │
│MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.      │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, │
│DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR       │
│OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE   │
│USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└────────────────────────────────────────────────────────────────────────────┘
}}
  