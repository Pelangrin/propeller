{{ ******************************************************************************
   * SparkFun's Serial Graphic LCD 128x64 DX160-B Example Object                *
   * James Burrows Feb 08                                                       *
   * Version 1.0                                                                *
   ******************************************************************************
   ┌──────────────────────────────────────────┐
   │ Copyright (c) <2008> <James Burrows>     │               
   │   See end of file for terms of use.      │               
   └──────────────────────────────────────────┘

   This object provides code to run the Serial Graphic LCD 128x64 DX160-B Object
 
   see - http://www.sparkfun.com/commerce/product_info.php?products_id=8358

   this object provides the PUBLIC functions:
    -> Start
    -> Clear
    -> toggleBackLight
    -> Position
    -> tx
    -> str

   this object provides the PRIVATE functions:
    -> None 

   this object uses the following sub OBJECTS:
    -> fullduplexSerial

   Revision History:
    -> V1 - release
  
   LCD's default baud is 57,600
}}
   
CON
    SetLargeFont    = 180
    SetSmallFont    = 181
    ToogleBackLight = 185
    ClearDisplay    = 186
    SplashOnOff     = 187
    SetRowBase      = 126    ' (add row number)
    SetColBase      = 135   '  (add col number)

OBJ
    serial         : "fullduplexserial"


PUB Start(_pin, _baud)
    ' can use "SimpleSerial" if baud < 19200
    'serial.start(-1, _pin, -_baud)
    ' else use fullduplexSerial...
    serial.start(0, _pin, %0000, _baud)
   
PUB Clear
    serial.tx(ClearDisplay)
    waitcnt(clkfreq/4+cnt)    

PUB SplashToggle
    serial.tx(SplashOnOff)
    
PUB toggleBackLight
    serial.tx (ToogleBackLight)

PUB Position(Row,Col)
    serial.tx(setRowBase+Row)
    serial.tx(setColBase+Col)
        
PUB tx(char)
    serial.tx(char)

PUB str(stringPtr)
    serial.str(stringPtr)
    waitcnt(clkfreq/4+cnt)       
    serial.tx(255)

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