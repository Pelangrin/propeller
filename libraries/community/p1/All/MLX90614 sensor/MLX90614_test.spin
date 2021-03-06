{{

  ┌────────────────────────────────────────────────────────┐
  │ MLX90614 Infrared Temp Module I2C Test                 │
  │ Modified: Tim Moore                                    │               
  │ Copyright (c) Sept 2008 Tim Moore                      │               
  │ See end of file for terms of use.                      │                
  └────────────────────────────────────────────────────────┘

  Started from Paul Baker's MLX90614 non I2C test

  Refer to MLX90614Object.spin for function explanation
}}

CON
  _clkmode      = xtal1 + pll16x
  _xinfreq      = 5_000_000

OBJ
  uarts         : "pcFullDuplexSerial4FC"               '1 COG for 4 serial ports

  mlx           : "MLX90614Object"                      '0 COG

  i2cScan       : "i2cScan"                             '0 COG

  led           : "ppdb_ledds"                          '1 COG

  config        : "config"                              '0 COG

VAR
  byte ledout[8]
   
PUB Main | temp, i2cSCL, addr, flags

  config.Init(@pininfo, @i2cinfo)

  waitcnt(clkfreq*3 + cnt)                              'delay for debugging

  i2cSCL := config.GetPin(CONFIG#I2C_SCL1)
  addr := config.GetI2C(CONFIG#MLX90614)

  uarts.Init
  uarts.AddPort(0,config.GetPin(CONFIG#DEBUG_RX),config.GetPin(CONFIG#DEBUG_TX),{
}   UARTS#PINNOTUSED,UARTS#PINNOTUSED,UARTS#DEFAULTTHRESHOLD, {
}   UARTS#NOMODE,UARTS#BAUD115200)                      'Add debug port
  uarts.Start                                           'Start the ports

  'setup PPDB LED displays
  led.Init(config.GetPin(CONFIG#PPDB_LED_SEGMENTA1),config.GetPin(CONFIG#PPDB_LED_DIGIT_L1), {
}   LED#NOSEGMENTS, LED#NODIGITS)
  
  uarts.str(0,string("MLX90614 Tester V1.0", 13))

  mlx.Init(config.GetPin(CONFIG#MLX90614POWER))         'power up MLX90614

  i2cScan.i2cScan(i2cSCL)                               'will not find MLX90614

  mlx.LeaveSleep(i2cSCL, addr)                          'fiddle with MLX90614 to get it working, i2cScan stops it

  'if mlx.Check(i2cSCL, addr)                            'make sure its working again
  '  uarts.str(0,string("MLX90614 found "))  
  'else
  '  uarts.str(0,string("MLX90614 not found "))  
  'uarts.hex(0, addr>>1, 2)
  'uarts.tx(0, 13)

  'flags := mlx.ReadFlags(i2cSCL, addr)                  'read flags
  'uarts.str(0, string("Flags "))
  'uarts.hex(0, flags, 2)
  'uarts.tx(0, 13)
  
  'mlx.WriteEEPROM(i2cSCL, 0, MLX#SMBus_Address, $0)    'erase eeprom
  'waitcnt(clkfreq/200 + cnt)                           'wait 5ms
  'mlx.WriteEEPROM(i2cSCL, 0, MLX#SMBus_Address, $5a)   'write word
  'uarts.str(0,string("EEPROM Updated", 13))
  'repeat
  
  repeat
    uarts.str(0,string("MLX90614 Temp: "))              'display title string  
    temp := mlx.GetTempK(i2cSCL, addr, 1)               'get the temperature in Kelvin
    uarts.dec(0, temp >> 8)                             'display integer potion
    uarts.tx(0, ".")                                    'display decimal point
    if temp & $FF < 10                                  'insert a 0 if value < 10
      uarts.tx(0, "0")
    uarts.dec(0, temp & $FF)                            'display hundredths of a Kelvin
    uarts.str(0, string(" K, "))                        'display whitespace and unit
    temp := mlx.GetTempC(i2cSCL, addr, 1)               'get temperature in Celsius
    uarts.dec(0, temp >> 8)                             'display integer portion
    uarts.tx(0, ".")                                    'display decimal point
    if temp & $FF < 10                                  'insert a 0 if value < 10
      uarts.tx(0, "0")
    uarts.dec(0, temp & $FF)                            'display hundredths of a degree
    uarts.str(0, string("°C   ", 13))                   'display unit and provide overwrite whitespace
    ledout[3] := (temp >> 8) / 10 + "0"                 'translate temp into string for led display
    ledout[2] := (temp >> 8) // 10 + "0"                'needs to be reversed because of digit wiring
    ledout[1] := (temp & $ff) / 10 + "0"
    ledout[0] := (temp & $ff)// 10 + "0"
    ledout[4] := 0
    led.str(@ledout)
    waitcnt(clkfreq >> 1 + cnt)                         'wait some time before repeating

DAT
'pin configuration table for this project
pininfo       word CONFIG#PPDB_LED_SEGMENTA1    'pin 0
              word CONFIG#PPDB_LED_SEGMENTA2    'pin 1
              word CONFIG#PPDB_LED_SEGMENTB     'pin 2
              word CONFIG#PPDB_LED_SEGMENTC     'pin 3
              word CONFIG#PPDB_LED_SEGMENTD1    'pin 4
              word CONFIG#PPDB_LED_SEGMENTD2    'pin 5
              word CONFIG#PPDB_LED_SEGMENTE     'pin 6
              word CONFIG#PPDB_LED_SEGMENTF     'pin 7
              word CONFIG#PPDB_LED_SEGMENTG1    'pin 8
              word CONFIG#PPDB_LED_SEGMENTG2    'pin 9
              word CONFIG#PPDB_LED_DIGIT_L1     'pin 10
              word CONFIG#PPDB_LED_DIGIT_R1     'pin 11
              word CONFIG#PPDB_LED_DIGIT_L2     'pin 12
              word CONFIG#PPDB_LED_DIGIT_R2     'pin 13
              word CONFIG#PPDB_LED_DIGIT_L3     'pin 14
              word CONFIG#PPDB_LED_DIGIT_R3     'pin 15
              word CONFIG#MLX90614POWER         'pin 16
              word CONFIG#NOT_USED              'pin 17
              word CONFIG#NOT_USED              'pin 18
              word CONFIG#NOT_USED              'pin 19
              word CONFIG#NOT_USED              'pin 20
              word CONFIG#NOT_USED              'pin 21
              word CONFIG#NOT_USED              'pin 22
              word CONFIG#NOT_USED              'pin 23
              word CONFIG#NOT_USED              'pin 24
              word CONFIG#NOT_USED              'pin 25
              word CONFIG#NOT_USED              'pin 26
              word CONFIG#NOT_USED              'pin 27
              word CONFIG#I2C_SCL1              'pin 28 - I2C - eeprom, sensors, rtc, fpu
              word CONFIG#I2C_SDA1              'pin 29
              word CONFIG#DEBUG_TX              'pin 30
              word CONFIG#DEBUG_RX              'pin 31

i2cinfo       byte CONFIG#MLX90614              'MLX90614
              byte %1011_0100
              byte CONFIG#NOT_USED
              byte CONFIG#NOT_USED
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