''**************************************************************************
''*  File   :  MPL115A1                                                    *                     
''*  Purpose:  To read  barometric pressure and temperature values         *
''*            from Sparkfun Breakout MPL115A1 sensor  - SPI Interface     *
''*  Author :  Osman Ardali                                                *
''*  E-Mail :  info@osmanardali.com                                        *
''*  Started:  JAN 2012                                                    *
''**************************************************************************
{{

                                         MPL115A1 Breakout (Sparkfun)
                       
                                        ┌────────────────────────────┐                
                                        │                            │
                                        │                            │                 
                                        │                            │
                                        │SDN CSN SDO SDI SCK GND VDD │     
                                        └─┬───┬───┬───┬───┬───┬───┬──┘     
                                              │   │   │   │   │   │                                                                                  
                                              ┻   ┻   ┻   ┻      ┻
                                             P12 P15 P14 P13  0v 3.3v
                                                

          SDI : Data is received by MPL115A1 on SDI (data in pin)

          SDO : Data is transmitted by MPL115A1 on SDO (data out pin)

    SEE :
    1.  Freescale Semiconductor Aplication Note AN3785 Rev 5, 7/2009
        " How to Implement the Freescale MPL115A Digital Barometer"
    2.  Freescale excel file "MPL115A Pcomp_with Temp reads and Altitude Calculations.xlsx" 16.8 kB - Rev 3              

   NOTE :
   This object uses PARALLAX SERIAL TERMINAL to display MPL115A1 ROM Coefficients, Padc,Tadc, 
   intermediate compansation coefficients and compansated Pcomp and P, T values            

   How to use PARALLAX SERIAL TERMINAL:

 o Run the Parallax Serial Terminal (included with the Propeller Tool) and set it to the connected Propeller
   chip's COM Port with a baud rate of 115200.
 o In the Propeller Tool, press the F10 (or F11) key to compile and load the code.
 o Immediately click the Parallax Serial Terminal's Enable button.  Do not wait until the program is finished
   downloading.

}}
 
CON                                             
_clkmode = XTAL1 + PLL16X
_xinfreq = 5_000_000
                                                           ' MPL115A1 Breakout.1 SDN  Shut Down - NOT CONNECTED           
  CS        =   12                                         ' MPL115A1 Breakout.2 CSN  Chip Select  
  rx_pin    =   15    ' (master)                             MPL115A1 Breakout.3 SDO  DATA OUT (slave)
  tx_pin    =   14    ' (master)                             MPL115A1 Breakout.4 SDI  DATA IN  (slave)       
  Clock     =   13                                         ' MPL115A1 Breakout.5 SCK  DATA CLOCK 
 
  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000
  
VAR                       
  word         Padc                                        ' 10-bit Pressure output of MPL115A1 ADC
  word         Tadc                                        ' 10-bit Temperature output of MPL115A1 ADC                                        
  word         a0, b1, b2, c12, c11, c22                   ' MPL115A1 ROM coefficients
  long         c11x1, c12x2, c22x2                         ' Intermedite compensation coefficints
  long         a1, a2, a11, a1x1, a2x2, y1                 ' Intermedite compensation coefficints             
  word         Pcalc                                       ' Computed Pressure Value ( counts )
  word         P, T                                        ' Pressure and Temperature values ( kPa and C )
  byte         index
  byte         CoefAdr                                   
  word         sum_Padc, sum_Tadc, last, a                    ' averaging values
  
DAT                                                                
  COEF         byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00                   ' MPL115A1 ROM Coefficients
               '     0   1   2   3   4   5   6   7   8   9   10  11
               '     byte 0-1 : 16_bit Pressure offset coefficient  a0                  bitshift : 3
               '     byte 2-3 : 16_bit Pressure sensitivity coefficient   b1            bitshift : 13   
               '     byte 4-5 : 16_bit 1st order Temperature offset coefficient  b2     bitshift : 14   
               '     byte 6-7 : 11_bit 2nd order Pressure linearity coefficient  c12    bitshift : 24   
               '     byte 8-9 : 14_bit Temperature sensitivity coefficient c11          bitshift : 27   
               '     byte 10-11 : 11_bit 2nd order Temperature offset coefficient c22   bitshift : 30   

  
OBJ                                                             
  PST      : "Parallax Serial Terminal"  
  delay    : "Timing"
  
PUB Main   
  DIRA[15..12] := %0111                                     ' set output pins    
  DIRA[23] := 1   
  outa[CS]~~ 
  
  delay.pause1ms(10)
  
  
  PST.Start(115200)                                        ' Start the Parallax Serial Terminal cog                
  PST.Str(String("PARALLAX SERIAL TERMINAL SCREEN"))       ' Heading  
                                               
'......................Read Coefficients..............................................

  repeat index from 0 to 11
    CoefAdr := 136 + 2*index                               ' 136  =  %10001000  =  $88
                                                           ' 138  =  %10001010  =  $8A
                                                           ' 140  =  %10001100  =  $8C
                                                           ' .........
                                                           ' 158  =  %10011110  =  $9E                                                               
    outa[CS]~  
    byte[@COEF][index] := Read_byte (tx_pin, rx_pin, Clock, CoefAdr) 
    outa[CS]~~         
     
  a0.byte[0] := byte[@COEF][1]
  a0.byte[1] := byte[@COEF][0]   
  b1.byte[0] := byte[@COEF][3]   
  b1.byte[1] := byte[@COEF][2]      
  b2.byte[0] := byte[@COEF][5]
  b2.byte[1] := byte[@COEF][4]
  c12.byte[0] := byte[@COEF][7]
  c12.byte[1] := byte[@COEF][6]  
  c11.byte[0] := byte[@COEF][9]
  c11.byte[1] := byte[@COEF][8]  
  c22.byte[0] := byte[@COEF][11]
  c22.byte[1] := byte[@COEF][10]  
    
  c12 ~>= 2                                   ') Eliminate lower LSB 0's in coeff.s with less than 16 bits
  c11 ~>= 5                                   ') NOTE : Bitshift values to be reduced accordingly
  c22 ~>= 5                                   ')  
'.......................................................................................  
  Display_Coeff                               ' Display MPL115A1 ROM Coefficients on PST screen 
  
  waitcnt(CLK_FREQ+ cnt)
       
  last := 0             
  Repeat
    sum_Padc := 0                                                     ' Reset averaging values
    sum_Tadc := 0    
    Repeat 10                                                         ' Read 10 times
      outa[CS]~      
      Write_byte (tx_pin, Clock, $24)                                 ' Start both Pressure and Temperature conversions
      outa[CS]~~
      delay.pause1ms(50)
      outa[CS]~           
      Padc.byte[1] := Read_byte (tx_pin, rx_pin, Clock, %10000000)    ' Read Pressure Hi byte         
      outa[CS]~~
      delay.pause10us(5) 
      outa[CS]~           
      Padc.byte[0] := Read_byte (tx_pin, rx_pin, Clock, %10000010)    ' Read Pressure Lo byte            
      outa[CS]~~
      delay.pause10us(5)  
      outa[CS]~      
      Tadc.byte[1] := Read_byte (tx_pin, rx_pin, Clock, %10000100)    ' Read Temperatur Hi byte              
      outa[CS]~~
      delay.pause10us(5) 
      outa[CS]~       
      Tadc.byte[0] := Read_byte (tx_pin, rx_pin, Clock, %10000110)    ' Read Temperature Lo byte     
      outa[CS]~~            
      delay.pause10us(5) 
      Padc ~>= 6                                                      ') Eliminate lower LSB 0's
      Tadc ~>= 6                                                      ')
      sum_Padc := sum_Padc + Padc
      sum_Tadc := sum_Tadc + Tadc
      delay.pause1ms(30)
    Padc :=  sum_Padc / 10                                            ') Calculate average Padc and Tadc 
    Tadc :=  sum_Tadc / 10                                            ')
    Display_adc 
    if ||(last - Padc) > 1                                            ') if Padc differs not more than 1
       last := Padc                                                   ') from last computed value DISREGARD
    else  
       next       
'...........................COMPANSATION.........................................................

' ........STEP 1 ................c11x1 := c11 * Padc                                                
    c11x1 := ~~c11 * Padc
    c11x1 ~>= 12                                                    '  x 2**-10     
' ........STEP 2 ................a11 := b1 + c11x1      
    a11 := ~~b1~>3 + c11x1                                          '  x 2**-10        
' ........STEP 3 ................c12x2 := c12 * Tadc      
    c12x2 := ~~c12 * Tadc
    c12x2 ~>= 12                                                    '  x 2**-10    
' ........STEP 4 ................a1 := a11 + c12x2          
    a1 := a11 + c12x2                                                     
' ........STEP 5 ................c22x2 := c22 * Tadc                                                
    c22x2 :=  c22 * Tadc
    c22x2 ~>= 15                                                    '  x 2**-10       
' ........STEP 6 ................a2 := b2 + c22x2                                                
    a2 := ~~b2~>4 + c22x2                                           '  x 2**-10     
' ........STEP 7 ................a1x1 := a1 * Padc
    a1x1 := a1 * Padc                                               '  x 2**-10 
' ........STEP 8 ................y1 := a0 + a1x1                                                                               
'   a0 in x2**-3 format ; transform a11 to the same    
    y1 := a0 + a1x1~>7                                              '  x 2**-3     
' ........STEP 9 ................a2x2 := a2 * Tadc
    a2x2 := a2 * Tadc                                               '  x 2**-10                                             
' ........STEP 10 ...............Pcomp := y1 +  a2x2       
    Pcalc := y1~>3 + a2x2~>10
    P := 500 + 650 * Pcalc / 1023                                   ' 0.1 kPa units (milibars)
    T := (605750 - 1000*Tadc)/535 + 50                              ' 0.1 degree units - Temp readout is approx 5C below real
                                                                    '
    Display_PT                                                      ' Display Intermediate Compansation Coefficients and Pcalc, P and T on PST screen

PUB Display_Coeff
  
  PST.Position(0,2)                            
  PST.Str(string("MPL115A1 ROM Coefficients : "))  
  PST.Position(0,3)   
  PST.Str(string("a0 : "))
  PST.dec(a0)
  PST.Str(string("  "))  
  PST.bin(a0,16)
  PST.Position(0,4)   
  PST.Str(string("b1 : "))
  PST.dec(b1)
  PST.Str(string("  "))  
  PST.bin(b1,16)
  PST.Position(0,5)   
  PST.Str(string("b2 : "))
  PST.dec(b2)
  PST.Str(string("  "))  
  PST.bin(b2,16)
  PST.Position(0,6)   
  PST.Str(string("c12 : "))
  PST.dec(c12)
  PST.Str(string("  "))  
  PST.bin(c12,16)   
  PST.Position(0,7)   
  PST.Str(string("c11 : "))
  PST.dec(c11)
  PST.Str(string("     "))  
  PST.bin(c11,16) 
  PST.Position(0,8)   
  PST.Str(string("c22 : "))
  PST.dec(c22)
  PST.Str(string("     "))  
  PST.bin(c22,16)    
    
PUB Display_adc
'...............................DISPLAY ADC PRESSURE AND TEMPERATURE..............................
  PST.Position(0,10)                            
  PST.Str(string("Padc : "))  
  PST.dec(Padc)
  PST.Position(0,11)   
  PST.Str(string("Tadc : "))
  PST.dec(Tadc)


PUB  Display_PT   
'...............................DISPLAY COMPANSATION COEFFs , Pcomp  and T .............................
  PST.Position(0,13)                            
  PST.Str(string("Intermediate Compansation Coefficients , Pcalc, P and T : "))     
  PST.Position(0,14)                            
  PST.Str(string("c11x1 : "))  
  PST.dec(c11x1)
  PST.Position(0,15)   
  PST.Str(string("a11 : "))
  PST.dec(a11)
  PST.Position(0,16)                            
  PST.Str(string("c12x2 : "))  
  PST.dec(c12x2)
  PST.Position(0,17)   
  PST.Str(string("a1 : "))
  PST.dec(a1) 
  PST.Position(0,18)                            
  PST.Str(string("c22x2 : "))  
  PST.dec(c22x2)
  PST.Position(0,19)   
  PST.Str(string("a2 : "))
  PST.dec(a2)
  PST.Position(0,20)                            
  PST.Str(string("a1x1 : "))  
  PST.dec(a1x1)
  PST.Position(0,21)   
  PST.Str(string("y1 : "))
  PST.dec(y1)
  PST.Position(0,22)                            
  PST.Str(string("a2x2 : "))  
  PST.dec(a2x2)
  PST.Position(0,23)   
  PST.Str(string("Pcalc : "))
  PST.dec(Pcalc)
  PST.Position(5,25)   
  PST.Str(string("P  (kPa*10) : "))
  PST.dec(P)
  PST.Position(5,26)              
  PST.Str(string("T  (C*10) : "))
  PST.dec(T)        
    
PUB Read_byte (txpin, rxpin, cpin, addr) | value
   
' Reads a byte from designated memory location of MPL115A1

  outa[cpin] := 0
  addr <<= 24                                       ' pre-align addr msb
  value~                                            ' clear input         
  repeat 8
    outa[txpin] := (addr <-= 1) & 1                 ' transmit command data bit
    delay.pause10us(1)                              ' let it settle
    !outa[cpin]                                     ' clock the bit
    delay.pause10us(1)
    !outa[cpin]
  delay.pause10us(1)
  outa[txpin] := 0             
  repeat 8
    !outa[cpin]                                              
    delay.pause10us(1)
    value := (value << 1) | ina[rxpin]
    !outa[cpin]                                              
    delay.pause10us(1) 
  return value  
    
PUB Write_byte (txpin, cpin, command)

' Transmits a command byte to MPL115A1
                                                     
  outa[cpin] := 0
  command <<= 24                                    ' pre-align command msb 
  repeat 8
    outa[txpin] := (command <-= 1) & 1              ' transmit command data bit
    delay.pause10us(1)                              ' let it settle
    !outa[cpin]                                     ' clock the bit
    delay.pause10us(1)
    !outa[cpin]   
  outa[txpin] := 0
  repeat 8
    delay.pause10us(1)                              
    !outa[cpin]                                     
    delay.pause10us(1)
    !outa[cpin]   

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