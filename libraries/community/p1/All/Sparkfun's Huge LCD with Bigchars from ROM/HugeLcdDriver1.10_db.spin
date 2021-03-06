'Spin driver for Sparkfun's Graphical LCD 160x128 Huge Display
' Copyright 2008 Raymond Allen 
' Bignum procedures added by Massimo De Marchi  
' Double buffer added on graphics stage
' thanks to Raymond for providing the code and the license
' Version 1.10 Feb 16th 2010
''*  See end of file for terms of use.   *

CON  'Constants Section

  'Control Pins
  WRPin=16 
  RDPin=17 
  CEPin=18 
  CDPin=19 
  BLPin=20 ' drives the back light
           ' control circuit:
           '                           LCD Pin 22 (back light GND)
           '                              │
           '                      5-10k   │
           '     Parallax BLPin────────
           '                              │
           '                              │
           '                              
  
  'Data Pins
  'Note that the PINS are actually backwards from what the Datasheet implies!!!
  'DataBasePin=8   '<===  I thought this was going to be the LSBit
  'DataEndPin=DataBasePin+7
  DataEndPin=7     '<=== Easy to read the pins backwards with Spin
  DataBasePin=DataEndPin-7

  xPixels=160
  yPixels=128
  columns=xPixels/8  '==20
  rows=yPixels/8     '==16
  ScreenChars=columns*rows
  ScreenBytes=xPixels*yPixels/8

  'Setting addresses.
     'End of 32k VRAM is at address $8000
     'Text page size is 320 bytes = $0140
     'Graphics page size is 2560 bytes = $0A00
  'You may want to adjust these addresses based on your needs...
  TextBaseAddress=$0000  'Starting Text and beginning of VRAM
  GraphicsBaseAddress=$1400  'Starting Graphics well above Text
  CustomCharBaseAddress=$7800  'Using last 2k for custom character space 'Note that least significant 11 bits of this address must be zero!

  'Mode Set Options
  ModeSetOr=%1000_0000  'Text and Graphics are Ored together   
  ModeSetExor=%1000_0001  '  ""                  Exored  "
  ModeSetAnd=%1000_0011   '  ""                  Anded  "
  ModeTextAttribute=%0100  'In this mode graphics memory says whether text is reversed, blinking, or invisible
  ModeAllExternalChars=%1000   'Use this to say that all text characters from user VRAM, not just upper 128

  'Display Set Options
  DisplaySetCmd=%1001_0000
  DisplayGraphicsOn=%1000
  DisplayTextOn=%0100
  DisplayCursorOn=%0010
  DisplayCursorBlink=%0001

  'Cursor Size Options
  Cursor1Line=$A0
  Cursor2Line=$A1
  Cursor3Line=$A2
  Cursor4Line=$A3
  Cursor5Line=$A4
  Cursor6Line=$A5
  Cursor7Line=$A6
  Cursor8Line=$A7

  'Various commands
  CursorPositionCmd=$21
  TextAreaCmd=$41
  TextAddressCmd=$40
  GraphicsAddressCmd=$42
  GraphicsAreaCmd=$43
  SetAddressCmd=$24
  StartAutoCmd=$B0
  EndAutoCmd=$B2             
  OffsetRegisterCmd=$22   'set location of custom characters

  'Write and Read
  WriteCmd=%1100_0000
  ReadCmd=%1100_0001
  DisableIncrement=%0100  'add this in to prevent address from auto incrementing
  Decrement=%0010 'add this in to decrement instead of increment                                    
  ROM0 = $8000

VAR
  byte memory_buff[screenbytes] ' buffer for graphics
PUB Start

  dira[BLPin]~~
  'Set control pins to outputs
  ConfigPins
  'Set Text home address
  SetTextBaseAddress(TextBaseAddress)   
  'Set Text area width
  SendCommand2(columns,$00,TextAreaCmd)  'shouldn't change this
  'Set Graphics home address
  SetGraphicsBaseAddress(GraphicsBaseAddress)  
  'Graphics Area Set
  SendCommand2(columns,$00,GraphicsAreaCmd)  'shouldn't change this
  'Custom Character Area Set
  SetCustomCharacterAddress(CustomCharBaseAddress)  
  'Mode Set
  SendCommand(ModeSeteXor)  'Text and Graphics Or'd together
  'Cursor shape Set
  SetCursorSize(1)  
  'Cursor position Set
  MoveCursor(0,0)     'first byte is column, second is row  
  'Display Mode
'  SetMode(true,true,true,true) 
  SetMode(true,true,false,false) 

  'Clear screen
  CLS
  

PUB SetPixel(x,y)
  memory_buff[(y*xpixels+x)>>3]|=$80>>((y*xpixels+x)&%111)

PUB TogglePixel(x,y)
  memory_buff[(y*xpixels+x)>>3]^=$80>>((y*xpixels+x)&%111)

PUB ClearPixel(x,y)
  memory_buff[(y*xpixels+x)>>3]&=!($80>>((y*xpixels+x)&%111))


PUB CLS
  'Clear both text and graphics screens
  CLS_Text
  CLS_Graphics


PUB CLS_inverted
  'Clear both text and graphics screens
  CLS_Text
  CLS_Graphics_inverted


PUB CLS_Text
  'Clear text screen
  Fill(TextBaseAddress,ScreenChars,0)   'character 0 is blank space 

PUB CLS_Graphics
  'Clear graphics buffer
  bytefill(@memory_buff,0,screenbytes)

PUB CLS_Graphics_inverted
  'fills graphics buffer
  bytefill(@memory_buff,%1111_1111,screenbytes)


PUB Goto(column,row)|address
  'Move current writing/reading address to given column,row in text area
  address:=row*columns+column
  SendCommand2(address,address>>8,SetAddressCmd)

PUB PUTC(char)|glyph
  'Write byte character to text area (assumes goto was used to set position prior to this call)
  'Note that built-in font is basically ascii offset by 32 (space character)
  glyph:=char-32
  SendCommand1(glyph,WriteCmd)

PUB STR(pString)
  repeat while byte[pString]<>0
    putc(byte[pString++])

PUB BLON
    outa[BLPin]:=1

PUB BLOFF
    outa[BLPin]:=0
    

PUB SetTextBaseAddress(address)
  'set the base address of the text screen
  'useful for vertical scrolling
  SendCommand2(address,address>>8,TextAddressCmd)

PUB SetGraphicsBaseAddress(address)
  'set the base address of the graphics screen
  'useful for vertical scrolling 
  SendCommand2(address,address>>8,GraphicsAddressCmd)

PUB SetCustomCharacterAddress(address)
  'set the base address for custom characters
  'Note that address must be aligned to 11 bits (i.e., least-significant 11 bits of address must be zero)
  SendCommand2(address>>11,0,OffsetRegisterCmd) 
  
PUB SetCursorSize(nLines)
  'Cursor can be set to between 1 and 8 lines
  if nLines>0 and nLines<9
    SendCommand(Cursor1Line+nLines-1)

PUB MoveCursor(column,row)
  'Move cursor to given column and row
  SendCommand2(column,row,CursorPositionCmd)

PUB SetMode(bTextOn,bGraphicsOn,bCursorOn,bCursorBlinking)|cmd
  'control screens and cursor
  cmd:=DisplaySetCmd
  if bTextOn
    cmd|=DisplayTextOn
  if bGraphicsOn
    cmd|=DisplayGraphicsOn   
  if bCursorOn
    cmd|=DisplayCursorOn  
  if bCursorBlinking
    cmd|=DisplayCursorBlink
  SendCommand(cmd)
    
PUB WriteByte(address, char)
    'write a byte to VRAM
    'Set Address
    SendCommand2(address,address>>8,SetAddressCmd)
    'Write byte
    SendCommand1(char,WriteCmd)

PUB ReadByte(Address):char    
    'read a byte from VRAM
    'Set Address
    SendCommand2(address,address>>8,SetAddressCmd)    
    'Read byte
    SendCommand(ReadCmd)
    char:=GetData
    return char

PUB Smalldot(column,row)| rowindex,colindex
'' writes a small dot at the bottom left edge of the character definition
'' the dot is 4X4 pixels
'' it mus be set after having written the char
rowindex:=row*32+28
colindex:=column*16

   repeat 4
      memory_buff[ ((rowindex++)*xPixels+colindex)>>3]:=(memory_buff[((rowindex)*xPixels+colindex)>>3]^%1111_0000 )



PUB bigfont(Asciichar,column, row ,inverted)| romposition,odd,rowindex,colindex,rowdata,bitpos,char
'' set char from ROM (16X32) in one of the 10X3 slots available
'' input: asciichar number
''        row number [0..3]
''        position   [0..9]
''        inverted [true/false] inverted field
''
''      LCD position definition
''
''  Position 0 | 1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  | 
''          ----------------------------------------------------------|
''         |                                                          |
''  ROW 0  |                                                          |
'' ------  |                                                          |
''         |                                                          |
''  ROW 1  |                                                          |
'' ------  |                                                          |
''         |                                                          |
''  ROW 2  |                                                          |
'' ------  |                                                          |
''         |                                                          |
''  ROW 3  |                                                          |
'' ------  |                                                          |
''         |----------------------------------------------------------|
''
''
''


   ' is it odd?
   if (asciichar&%1)==0
      odd:=0
   else
      odd:=1
      asciichar--   
 
   ' go to upper left corner

   rowindex:=row*32
   colindex:=column*16
   ' iteratively set/clear the pixels, from the first row
   ' choose the even or the odd bits from the char map
'   repeat romindex from 0 to 32 'rompositon to romposition+128 increment by 4
   repeat romposition from Rom0+asciichar<<6 to Rom0+124+asciichar<<6 step 4'rompositon to romposition+128 increment by 4

        
'       rowdata:=long[romposition+romindex*4] ' long, bit flipped
       rowdata:=long[romposition] ' long, bit flipped
       rowdata>>=odd   ' if even bits, take as it is, otherwise strip the first bit
       if inverted
          !rowdata

       char:=0
       repeat  bitpos from 0 to 15  
          if (rowdata&%1)
             char := char|(%1<<(31-bitpos))  ' set bit on the char
          rowdata>>=2 ' next bit
' *************oroginale buono ++++++++++++++++++++++++
'       writebyte(GraphicsBaseAddress+(rowindex*xPixels+colindex)>>3 , char>>24)
'       writebyte(GraphicsBaseAddress+(rowindex*xPixels+colindex+8)>>3, char>>16)
      memory_buff[ (rowindex*xPixels+colindex)>>3]:=(char>>24)
      memory_buff[ (rowindex*xPixels+colindex+8)>>3]:=(char>>16)          


       rowindex++       
       
       
pub bigstring (strpointer,column, row, inverted)|counter
'' writes a string in bigfonts
''        row number [0..3]
''        column     [0..9]
''        inverted [true/false] inverted field
''
''        see Bigfont for bigfont position definition
''
   
   repeat counter from 0 to (strsize (strpointer)-1)<#(9-column)
       bigfont(byte[strpointer][counter],column+counter,row,inverted)               




pub commit|loopcounter ' writes the graphisc screen buffer

' GraphicsBaseAddress,ScreenBytes

  SendCommand2(GraphicsBaseAddress,GraphicsBaseAddress>>8,SetAddressCmd)  
  'Set auto-write mode
  SendCommand(StartAutoCmd)
  WaitStatus
  'loop
  loopcounter:=0
  repeat ScreenBytes
    WaitStatus3
    WriteData(memory_buff[loopcounter++])  
  'End Auto-Write
  WaitStatus3
  WriteCommand(EndAutoCmd)






PRI Fill(address,nBytes,fillChar)
  'Fill memory starting at giving address with nBytes of fillChar
  'Useful for erasing screen  
  'Set Start Address
  SendCommand2(address,address>>8,SetAddressCmd)  
  'Set auto-write mode
  SendCommand(StartAutoCmd)
  WaitStatus
  'loop
  repeat nBytes
    WaitStatus3
    WriteData(fillChar)  
  'End Auto-Write
  WaitStatus3
  WriteCommand(EndAutoCmd)

PRI ConfigPins|i
  'set control pins to outputs
  'setting controls to high first (remember they're active low)
  outa[WRPin]~~
  dira[WRPin]~~
  outa[RDPin]~~
  dira[RDPin]~~
  outa[CEPin]~~
  dira[CEPin]~~
  outa[CDPin]~~
  dira[CDPin]~~

  
PRI WriteData(data)
  dira[DataBasePin..DataEndPin]~~
  outa[DataBasePin..DataEndPin]:=data  
  outa[CDPin]~
  outa[WRPin]~
  outa[CEPin]~
  outa[CEPin]~~
  outa[WRPin]~~
  outa[CDPin]~~
  dira[DataBasePin..DataEndPin]~ 

PRI GetData
  WaitStatus
  return ReadData

PRI ReadData:data
  dira[DataBasePin..DataEndPin]~ 
  outa[CDPin]~
  outa[RDPin]~
  outa[CEPin]~
  data:=ina[DataBasePin..DataEndPin]
  outa[CEPin]~~
  outa[RDPin]~~
  outa[CDPin]~~
  return data

PRI SendCommand2(dLow,dHigh,cmd)
  WaitStatus
  WriteData(dLow)
  WaitStatus
  WriteData(dHigh)
  WaitStatus
  WriteCommand(cmd)

PRI SendCommand1(d,cmd)
  WaitStatus
  WriteData(d)
  WaitStatus
  WriteCommand(cmd)

PRI SendCommand(cmd)
  WaitStatus
  WriteCommand(cmd)   

PRI WriteCommand(cmd)
  dira[DataBasePin..DataEndPin]~~ 
  outa[DataBasePin..DataEndPin]:=cmd
  outa[WRPin]~
  outa[CEPin]~
  outa[CEPin]~~
  outa[WRPin]~~
  dira[DataBasePin..DataEndPin]~ 

PRI WaitStatus
'   waitcnt(clkfreq/2000+cnt)
  repeat
  until ReadStatus==True

PRI ReadStatus:bReady|status,i
  'Check that STA0 and STA1 are both 1
  dira[DataBasePin..DataEndPin]~ 
  outa[CDPin]~~ 
  outa[RDPin]~
  outa[WRPin]~~ 
  outa[CEPin]~
  status:=ina[DataBasePin..DataEndPin]
  outa[CEPin]~~
  outa[RDPin]~~
  if (status & %11)==%11 
    return true
  return false


PRI WaitStatus3
   'waitcnt(clkfreq/2000+cnt)
  repeat
  until ReadStatus3==True
            
PRI ReadStatus3:bReady|status,i
  'Check that STA3 is 1
  dira[DataBasePin..DataEndPin]~ 
  outa[CDPin]~~ 
  outa[RDPin]~
  outa[WRPin]~~ 
  outa[CEPin]~
  status:=ina[DataBasePin..DataEndPin]
  outa[CEPin]~~
  outa[RDPin]~~       
  if (status & %1000)==%1000  
    return true   
  return false

{{

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
  