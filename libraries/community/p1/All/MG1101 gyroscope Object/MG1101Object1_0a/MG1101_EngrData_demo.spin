{{

┌─────────────────────────────────────────────────┐
│ MG1101_EngrData_demo, for Gyration gyroscope    │
│ to demonstrate use of MG1101Object Object 1.0   │               
│ Author: Eric Ratliff                            │               
│ Copyright (c) 2008 Eric Ratliff                 │               
│ See end of file for terms of use.               │                
└─────────────────────────────────────────────────┘
to show engineering units data from MG1101 gyro
Revision History:
 -> V1.0 first version 2008.10.12 by Eric Ratliff
 -> V1.0a corrected instructions per Tim Pifer to match code, were pins 0 and 1 of Propeller, now pins 2 and 3 of Propeller

derived from James Burrows' I2C Demo Propeller program of Oct 2007

see MG1101Object for schematic and reference to documentation of the gyro device

this demo uses the following sub OBJECTS:
 -> MG1101Object
 -> basic_i2c_driver
 -> Debug_PC
 -> pcFullDuplexSerial
 -> Simple_Numbers

Instructions (brief):
(1) - setup the propeller - see the Parallax Documentation (www.parallax.com/propeller)
(2) - Use a 5mhz crystal on propeller X1 and X2
(3) - Connect the SDA lines to Propeller Pin3, and SCL lines to Propeller Pin2
         See diagram in Object's code for resistor placements.
(4) - set up Hyperterminal to the com port of the USB connection to the Propeller chip, then dicconnect but do not close Hyperterminal
(5) - download the app, then click 'call' icon in Hyterterminal to connect, may also use 'text capture' to record data on PC


For this demo only, there is an optional pushbutton for setting axis offsets when gyro is known to not be rotating

                                   momentary            
                                   push                 
                            1K     button               
                          ┌─────── ─────────  3.3V 
                          │                             
     Prop Pin 7  ─────────┤ 10K                         
                          └─────────────────── 0V
}}                        

OBJ
  GyroChip      : "MG1101Object"
  debug         : "Debug_PC"
  
CON
  _clkmode      = xtal1 + pll16x
  _xinfreq      = 5_000_000
  _stack        = 50

  ' where to find I2C bus, data pin is one higher    
  i2cSCL        = 2
  ' where to find pushbutton to request read and set of axis rate offses at time of known zero rotation
  StillButton   = 7             ' make this negative if no pushbutton is implemented
  StillButtonMask = 1 << StillButton

  ' debug - USE onboard pins
  pcDebugRX       = 31
  pcDebugTX       = 30

  ' serial baud rates  
  pcDebugBaud     = 115200
  CarrigeReturn   = 13          ' ASCII code for moving cursor to beginning of line
  LineFeed        = 10          ' ASCII code for moving cursor to next row
  Space           = 32          ' ASCII code for space character

VAR
  long  i2cAddress, i2cSlaveCounter
  long  NetPollTime_ms                                  ' how long it took to poll all data without reporting (ms)
  long  PollStartTime                                   '                       (clocks)
  long  PollEndTime                                     '                       (clocks)
  long  NetPollTime                                     '                       (clocks)
  long  YawLSBs                                         ' highest resolution axis rate readings (1/32 degrees/sec)
  long  PitchLSBs
  long  YawDegreesPerSecond                             ' axis rate readings truncated (degrees per second)
  long  PitchDegreesPerSecond
  long  PowerEMFmV                                      ' power supply voltage (mV)
  long  Temperature_C                                   ' temperature inside gyro (Celcius)  

pub Start
    ' start the PC debug object
    debug.startx(pcDebugRX,pcDebugTX,pcDebugBaud)
  
    ' pause 5 seconds to allow user to start Hyperterminal
    repeat 10
        debug.putc(".")
        waitcnt((clkfreq/2)+cnt)
    debug.putc(CarrigeReturn)
  
    ' i2c state
    debug.strln(string("MG1101_EngrData_demo"))
    debug.putc(CarrigeReturn)                      
    debug.putc(LineFeed)

    waitcnt(clkfreq*2 +cnt)

    MG1101B_Demo

PRI MG1101B_Demo | HoldingLong, CalIndex, ResultCode
    '' demo the Gyration Gyroscope

    ' known approximate axis offsets for my gyro device
    YawLSBs := $721E
    PitchLSBs := $7F0C
    ' nominal axis offsets for the gyro devices in general
    'YawLSBs := GyroChip#NominalAxesOffset
    'PitchLSBs := GyroChip#NominalAxesOffset
    GyroChip.SetAxisOffsets(YawLSBs,PitchLSBs)          ' set the axis offsets

    ' prepare gyro for use
    ResultCode := GyroChip.StartupGyro(i2cSCL)
    if ResultCode <> GyroChip#GRNR_WaitOK
      debug.str(string("gyro timed out, status code = "))
      debug.dec(ResultCode)
      debug.putc(CarrigeReturn)
      debug.putc(LineFeed)
    else
      debug.str(string("gyro is stabilizing"))
      debug.putc(CarrigeReturn)
      debug.putc(LineFeed)

      ' optional timed wait for stability
    
      ' poll values a while
      repeat
        ' get voltage
        GyroChip.getVoltageRetults_mV(i2cSCL,@PowerEMFmV)
        debug.str(string("EMF: "))
        debug.dec(PowerEMFmV)
        
        ' get temperature
        GyroChip.getTemperatureRetults_C(i2cSCL,@Temperature_C)
        debug.str(string("(mV) T: "))
        debug.dec(Temperature_C)
        
        ' get rotation rates
        GyroChip.getAxisRetults(i2cSCL,@YawLSBs,@PitchLSBs)
        ' truncate, throwing away resolution to show degrees units
        YawDegreesPerSecond := YawLSBs ~> GyroChip#NominalLSBperDegPerSecP2
        PitchDegreesPerSecond := PitchLSBs ~> GyroChip#NominalLSBperDegPerSecP2

        debug.str(string("(C) Yaw, Pitch rates: "))
        debug.dec(YawDegreesPerSecond)
        debug.putc(Space)                          
        debug.dec(PitchDegreesPerSecond)
        debug.str(string("(deg/sec)"))
        debug.putc(CarrigeReturn)
        debug.putc(LineFeed)

        if StillButton => 0                             ' was a 'reset axis offsets' button specified?
          if ina & StillButtonMask                      ' has user pressed the 'reset axis offsets' button?
            GyroChip.MeasureAndSetAxisOffsets(i2cSCL)
            GyroChip.GetAxisOffsets(@YawLSBs,@PitchLSBs)
            debug.str(string("Resetting Axis Offsets, found yaw offset "))
            debug.dec(YawLSBs)
            debug.str(string(" and pitch offset "))
            debug.dec(PitchLSBs)
            debug.str(string(" (decimal LSBs)"))
            debug.putc(CarrigeReturn)
            debug.putc(LineFeed)
            waitcnt((clkfreq)+cnt)                      ' wait a second for button release to avoid doing this many times

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