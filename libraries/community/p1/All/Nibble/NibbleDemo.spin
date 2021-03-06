{{
  ┌───────────────────────────────────────────────┐
  │ Nibble Demonstration                          │
  │ Version 1.0                                   │
  │ Copyright (c) 2012 Dennis B. Page             │               
  │ See end of file for terms of use              │     
  ├───────────────────────────────────────────────┤ 
  │ Displays Nibble outputs on host               │
  │   by Dennis B. Page, Page Radio Company       │
  │                                               │
  │ Questions? Please post on the Propeller forum │
  │       http://forums.parallax.com/forums/      │
  └───────────────────────────────────────────────┘

  Version 1.0 January 27, 2012 Initial Release

Demonstrates the following: 
  Pack(Value,Nib,Nibble)         Returns Value after packing the 4-bit Nibble at the specified Nib position (0 - 7)
  UnPack(Value,Nib)              Returns Value of the nibble at position Nib (0 - 7)
  Toggle(Value,Nib)              Returns Value after toggling the bits in the specified Nib position (0 - 7)
  ShiftRightLong(Value)          Returns Value after shifting long Value right one nibble
                                    Shift zero into least significant nibble
  ShiftLeftLong(Value)           Returns Value after shifting long Value left one nibble
                                    Shift most significant nibble into least significant nibble
  RotateRightLong(Value)         Returns Value after rotating long Value right one nibble
                                    Shift least significant nibble into most significant nibble
  RotateLeftLong(Value)          Returns Value after rotating long Value left one nibble
                                    Shift most significant nibble into least significant nibble
  ShiftRightWord(Value)          Returns Value after shifting word Value right one nibble
                                    Shift zero into most significant nibble
  ShiftLeftWord(Value)           Returns Value after shifting word Value left one nibble
                                    Shift zero into least significant nibble
  RotateRightWord(Value)         Returns Value after shifting word Value right one nibble
                                    Shift least significant nibble into most significant nibble
  RotateLeftWord(Value)          Returns Value after rotating word Value left one nibble
                                    Shift most significant nibble into least significant nibble
  ShiftRightByte(Value)          Returns Value after shifting byte Value right one nibble
                                    Shift zero into most significant nibble
  ShiftLeftByte(Value)           Returns Value after shifting byte Value left one nibble
                                    Shift zero into least significant nibble
  RotateRightByte(Value)         Returns Value after rotating byte Value right one nibble
                                    Shift least significant nibble into most significant nibble
  RotateLeftByte(Value)          Returns Value after rotating byte Value left one nibble
                                    Shift most significant nibble into least significant nibble
  ShiftRightSE(Value,Start,End)  Returns Value shifting right one nibble from positions Start (0 - 7) to End (0 - 7)
                                    Shift zero into the End nibble position
  ShiftLeftSE(Value,Start,End)   Returns Value after shifting left one nibble from positions Start (0 - 7) to End (0 - 7) 
                                    Shift zero into the Start nibble position
  RotateRightSE(Value,Start,End) Returns Value after rotating right one nibble from positions Start (0 - 7) to End (0 - 7)
  RotateLeftSE(Value,Start,End)  Returns Value after rotating left one nibble from positions Start (0 - 7) to End (0 - 7) 
  FillLong(Value,Nibble)         Returns Value after filling long Value with Nibble
  FillWord(Value,Nibble)         Returns Value after filling word Value with Nibble
  FillByte(Value,Nibble)         Returns Value after filling byte Value with Nibble
}}

CON  
  _clkmode = xtal1 + pll8x                  ' Clock Mode for SS1           
  _xinfreq = 10_000_000                     ' Clock Speed for SS1                                                        
  CR       = 13

DAT
  MyLongData byte 0,1,2,3,4,5,6,7
  MyWordData byte 0,1,2,$A
  MyByteData byte 1,2
  
VAR
  long MyLong
  word MyWord
  byte MyByte
  
OBJ
  debug  : "SimpleDebug"
  Nib    : "Nibble"
  
PUB main | I
  debug.start(19200)
  debug.str(string("Nibble Manipulation Demonstration"))
  debug.str(string(CR,"Method"))
  debug.str(string(CR," Value Before After"))

' Pack(Value,Nib,Nibble)
  debug.str(string(CR,CR,"Pack Nibble",CR," MyLong "))
  debug.hex(MyLong,8)
  repeat I from 7 to 1
    debug.putc(" ")
    MyLong := Nib.Pack(MyLong,I,MyLongData[I])
    debug.hex(MyLong,8)
  debug.str(string(CR," MyWord "))
  debug.hex(MyWord,4)
  repeat I from 3 to 0
    debug.putc(" ")
    MyWord := Nib.Pack(MyWord,I,MyWordData[I])
    debug.hex(MyWord,4)
  debug.str(string(CR," MyByte "))
  debug.hex(MyByte,2)
  repeat I from 1 to 0
    debug.putc(" ")
    MyByte := Nib.Pack(MyByte,I,MyByteData[I])
    debug.hex(MyByte,2)

' UnPack(Value,Nib)
  debug.str(string(CR,CR,"UnPack Nibble",CR," MyLong "))
  debug.hex(MyLong,8)
  repeat I from 7 to 0
    debug.putc(" ")
    debug.hex(Nib.UnPack(MyLong,I),1)
  debug.str(string(CR," MyWord "))
  debug.hex(MyWord,4)
  repeat I from 3 to 0
    debug.putc(" ")
    debug.hex(Nib.UnPack(MyWord,I),1)
  debug.str(string(CR," MyByte "))
  debug.hex(MyByte,2)
  repeat I from 1 to 0
    debug.putc(" ")
    debug.hex(Nib.UnPack(MyByte,I),1)

' Toggle(Value,Nib)
  debug.str(string(CR,CR,"Toggle",CR," MyLong "))
  debug.hex(MyLong,8)
  repeat I from 7 to 4
    debug.putc(" ")
    debug.hex(Nib.toggle(MyLong,I),8)                 
  debug.str(string(CR," MyWord "))
  debug.hex(MyWord,4)
  repeat I from 3 to 0
    debug.putc(" ")
    debug.hex(Nib.toggle(MyWord,I),4)                 
  debug.str(string(CR," MyByte "))
  debug.hex(MyByte,2)
  repeat I from 1 to 0
    debug.putc(" ")
    debug.hex(Nib.toggle(MyByte,I),2)                 

' ShiftRight(Value)                                  
  debug.str(string(CR,CR,"Shift Right",CR," MyLong "))
  debug.hex(MyLong,8)
  debug.putc(" ")
  debug.hex(Nib.ShiftRightLong(MyLong),8)
  debug.str(string(CR," MyWord "))
  debug.hex(MyWord,4)
  debug.putc(" ")
  debug.hex(Nib.ShiftRightWord(MyWord),4)
  debug.str(string(CR," MyByte "))
  debug.hex(MyByte,2)
  debug.putc(" ")
  debug.hex(Nib.ShiftRightByte(MyByte),2)

' ShiftLeft(Value)                                   
  debug.str(string(CR,CR,"Shift Left",CR," MyLong "))
  debug.hex(MyLong,8)
  debug.putc(" ")
  debug.hex(Nib.ShiftLeftLong(MyLong),8)
  debug.str(string(CR," MyWord "))
  debug.hex(MyWord,4)
  debug.putc(" ")
  debug.hex(Nib.ShiftLeftWord(MyWord),4)
  debug.str(string(CR," MyByte "))
  debug.hex(MyByte,2)
  debug.putc(" ")
  debug.hex(Nib.ShiftLeftByte(MyByte),2)

' ShiftSE(Value,Start,End) | I
  debug.str(string(CR,CR,"Shift SE",CR," MyLong,3,5 "))
  debug.hex(MyLong,8)
  debug.putc(" ")
  debug.hex(Nib.ShiftSE(MyLong,3,5),8)
  debug.str(string(CR," MyWord,2,3 "))
  debug.hex(MyWord,4)
  debug.putc(" ")
  debug.hex(Nib.ShiftSE(MyWord,2,3),4)
  debug.str(string(CR," MyByte,0.1 "))
  debug.hex(MyByte,2)
  debug.putc(" ")
  debug.hex(Nib.ShiftSE(MyByte,0,1),2)
  debug.str(string(CR,CR,"Shift SE",CR," MyLong,5,3 "))
  debug.hex(MyLong,8)
  debug.putc(" ")
  debug.hex(Nib.ShiftSE(MyLong,5,3),8)
  debug.str(string(CR," MyWord,3,2 "))
  debug.hex(MyWord,4)
  debug.putc(" ")
  debug.hex(Nib.ShiftSE(MyWord,3,2),4)
  debug.str(string(CR," MyByte,1,0 "))
  debug.hex(MyByte,2)
  debug.putc(" ")
  debug.hex(Nib.ShiftSE(MyByte,1,0),2)

' RotateRight(Value)                                 
  debug.str(string(CR,CR,"Rotate Right",CR," MyLong "))
  debug.hex(MyLong,8)
  debug.putc(" ")
  debug.hex(Nib.RotateRightLong(MyLong),8)
  debug.str(string(CR," MyWord "))
  debug.hex(MyWord,4)
  debug.putc(" ")
  debug.hex(Nib.RotateRightWord(MyWord),4)
  debug.str(string(CR," MyByte "))
  debug.hex(MyByte,2)
  debug.putc(" ")
  debug.hex(Nib.RotateRightByte(MyByte),2)

' RotateLeft(Value)                                  
  debug.str(string(CR,CR,"Rotate Left",CR," MyLong "))
  debug.hex(MyLong,8)
  debug.putc(" ")
  debug.hex(Nib.RotateLeftLong(MyLong),8)
  debug.str(string(CR," MyWord "))
  debug.hex(MyWord,4)
  debug.putc(" ")
  debug.hex(Nib.RotateLeftWord(MyWord),4)
  debug.str(string(CR," MyByte "))
  debug.hex(MyByte,2)
  debug.putc(" ")
  debug.hex(Nib.RotateLeftByte(MyByte),2)

' RotateSE(Value,Start,End) | A,I
  debug.str(string(CR,CR,"Rotate SE",CR," MyLong,3,5 "))
  debug.hex(MyLong,8)
  debug.putc(" ")
  debug.hex(Nib.RotateSE(MyLong,3,5),8)
  debug.str(string(CR," MyWord,2,3 "))
  debug.hex(MyWord,4)
  debug.putc(" ")
  debug.hex(Nib.RotateSE(MyWord,2,3),4)
  debug.str(string(CR," MyByte,0,1 "))
  debug.hex(MyByte,2)
  debug.putc(" ")
  debug.hex(Nib.RotateSE(MyByte,0,1),2)
  debug.str(string(CR,CR,"Rotate SE",CR," MyLong,5,3 "))
  debug.hex(MyLong,8)
  debug.putc(" ")
  debug.hex(Nib.RotateSE(MyLong,5,3),8)
  debug.str(string(CR," MyWord,3,2 "))
  debug.hex(MyWord,4)
  debug.putc(" ")
  debug.hex(Nib.RotateSE(MyWord,3,2),4)
  debug.str(string(CR," MyByte,1,0 "))
  debug.hex(MyByte,2)
  debug.putc(" ")
  debug.hex(Nib.RotateSE(MyByte,1,0),2)

' Fill
  debug.str(string(CR,CR,"Fill",CR," MyLong "))
  debug.hex(MyLong,8)
  debug.putc(" ")
  debug.hex(Nib.FillLong(MyLong,5),8)
  debug.str(string(CR," MyWord "))
  debug.hex(MyWord,4)
  debug.putc(" ")
  debug.hex(Nib.FillWord(MyWord,5),4)
  debug.str(string(CR," MyByte "))
  debug.hex(MyByte,2)
  debug.putc(" ")
  debug.hex(Nib.FillByte(MyByte,5),2)
  
  debug.str(string(CR,CR,"FillSE",CR," MyLong,7,5 "))
  debug.hex(MyLong,8)
  debug.putc(" ")
  debug.hex(Nib.FillSE(MyLong,6,0,$B),8)
  debug.str(string(CR," MyWord,2,3 "))
  debug.hex(Myword,4)
  debug.putc(" ")
  debug.hex(Nib.FillSE(MyWord,2,0,$B),4)
  debug.str(string(CR," MyByte,0,0 "))
  debug.hex(MyByte,2)
  debug.putc(" ")
  debug.hex(Nib.FillSE(MyByte,0,0,$B),2)
  
  {<end of object code>}
     
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