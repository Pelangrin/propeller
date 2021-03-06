{{
 PS2Test 
 by Chris Cantrell
 Version 1.0 3/24/2011
 Copyright (c) 2011 Chris Cantrell
 See end of file for terms of use.
}}

{{

 This test harness starts the PS2Controller driver in a separate cog and prints the
 response data from the controller on the serial terminal screen.

 The controller is connected to pins 0,1,2, and 3 of the propeller (I used a demo board).
 See PS2Controller.spin for hardware connection details.

 I tested this harness with an official Sony controller, a wired GuitarHero controller,
 and two different wireless GuitarHero controllers.

 The PS2 controller protocol details were extracted from the description and C code
 on this wonderful site:
 http://store.curiousinventor.com/guides/ps2/

}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

OBJ

  PST : "Parallax Serial Terminal"
  PS2 : "PS2Controller"

PUB start | i

  PST.start(115200)         ' Start the terminal

  ' A clock rate of 250KHz works for all the controllers I own including two
  ' different wireless GuitarHero controllers.
  
  PS2.start(0,250_000,100)  ' DAT is pin 0, use 250KHz data clock, poll at 100Hz 
  
  PST.clear            ' Clear the screen
    
  ' This is how to setup the command buffer byte by byte, start a command,
  ' and wait for the command to complete. This is the "long" way. The "short"
  ' way is use for remaining commands.

  ' Execute a standard "get values" command
  PS2.setLength(9)    
  PS2.setCommandByte( $1,0)  
  PS2.setCommandByte($42,1)  
  PS2.setCommandByte( $0,2)
  PS2.setCommandByte( $0,3)
  PS2.setCommandByte( $0,4)
  PS2.setCommandByte( $0,5)
  PS2.setCommandByte( $0,6)
  PS2.setCommandByte( $0,7)
  PS2.setCommandByte( $0,8)
  PS2.setControl(2)               ' Send command
  repeat while PS2.getControl<>0  ' Wait for response    

  ' The "short" way to talk to the driver is to use byte-arrays defined
  ' in the DAT section.  

  ' Put the controller in "escape" mode for configuration
  PS2.setCommandBytes(@escapeMode)
  PS2.executeAndWait

  ' Put the controller in analog mode
  PS2.setCommandBytes(@analogMode)
  PS2.executeAndWait

  ' Exit the excape (configuration) mode
  PS2.setCommandBytes(@exitEscape)
  PS2.executeAndWait
    
  ' Setup the command to be repeated in polling
  PS2.setCommandBytes(@pollCommand)

  ' Start the polling
  PS2.startPolling   
  
  repeat
    PST.Home
    printValues   
 
PUB printValues | i
  repeat i from 0 to PS2.getLength-1
      PST.hex(PS2.getResponseByte(i),2)
      PST.char(" ")
  PST.char(13)

DAT

' Command used to poll for values in the "main" loop
pollCommand     byte   9,   $1,$42,$0,$0,$0,$0,$0,$0,$0

' Command to put the controller in escape (configuration) mode
escapeMode      byte   5,   $1,$43,$0,$1,$0

' Command to put the controller in analog mode (must be in escape mode)
analogMode      byte   9,   $1,$44,$0,$1,$3,$0,$0,$0,$0

' Command to exit the escape mode
exitEscape      byte   9,   $1,$43,$0,$0,$5A,$5A,$5A,$5A,$5A

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