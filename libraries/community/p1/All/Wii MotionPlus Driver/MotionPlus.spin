{{

┌──────────────────────────────────────────┐
│ Wii MotionPlus Driver Object v1.1        │
│ Author: Pat Daderko (DogP)               │               
│ Copyright (c) 2009                       │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

Based on a Wii nunchuck example project from John Abshier, which was based on code originally by João Geada

Added in v1.1 is the ability to use the MotionPlus with an extension controller plugged in (Nunchuck or
Classic Controller).  When enabled, this interleaves extension controller data with MotionPlus data on every
other read.  When $04 is written at initialization, the MotionPlus functions alone.  When $05 is written, it runs
in Nunchuck mode, where it passes through Nunchuck data, dropping the least significant bit of each axis of the
accelerometer. When $07 written, it runs in Classic Controller mode, where it passes through Classic Controller
data, dropping the least significant bit of the each axis of the left joystick.  There's no requirement to use
the correct mode for each extension... a Nunchuck will run in Classic Controller mode and vice versa, but the
missing/moved bits don't make sense.

The MotionPlus data can be determined by bits 1 and 0 of the sixth byte being 10.  Extension data can be
determined by the last two bits of the sixth byte being 00.
In Nunchuck mode:
         Bit
Byte     7       6       5       4       3       2       1       0
0       SX<7-----------------------------------------------------0>
1       SY<7-----------------------------------------------------0>
2       AX<9-----------------------------------------------------2>
3       AY<9-----------------------------------------------------2>
4       AZ<9---------------------------------------------3>      1
5       AZ<2-----1>     AY<1>   AX<1>   BC      BZ       0       0

In Classic Controller mode:
         Bit
Byte     7       6       5       4       3       2       1       0
0       RX<4-----3>     LX<5-----------------------------1>     BDU
1       RX<2-----1>     LY<5-----------------------------1>     BDL
2       RX<0>   LT<4-----3>     RY<4-----------------------------0>
3       LT<2-------------0>     RT<4-----------------------------0>
4       BDR     BDD     BLT     B-      BH      B+      BRT      1
5       BZL     BB      BY      BA      BX      BZR      0       0

The rotation data is also now in degrees/second, which is being computed by dividing the raw value by 20 if at
low speed, or dividing by 5 if at high speed (according to the flags). 

The MP_CAL_X, MP_CAL_Y, and MP_CAL_Z values are calibration values for zeroing the rotation and may need to be
adjusted, depending on your specific hardware.  This is the 0 value for no rotation in its axis.  To determine
this value, take the average over a long period of time with the MotionPlus sitting still.

The other CAL values are taken from the my other Wii objects (Nunchuck/Classic Controller), as are the
respective functions/variables.  Note that even though LSBits are lost, the functions keep the other bits in
the same positions to make them compatible with existing code, although with one less bit of precision. 

Diagram below is showing the pinout looking into the connector on the top (which plugs into the Wii Remote)
 _______ 
| 1 2 3 |
|       |
| 6 5 4 |
|_-----_|

1 - SDA
2 - 
3 - VCC
4 - SCL
5 - 
6 - GND

This is an I2C peripheral, and requires a pullup resistor on the SDA line
If using a prop board with an I2C EEPROM, this can be connected directly to pin 28 (SCL) and pin 29 (SDA)

Digital controller bits:
0: R fully pressed
1: Start
2: Home
3: Select
4: L fully pressed
5: Down
6: Right
7: Up
8: Left
9: ZR
10: x
11: a
12: y
13: b
14: ZL
}}

CON
   MotionPlus_Addr_1 = $A6 'for initialization
   MotionPlus_Addr_2 = $A4 'after initialized, goes to $A4
   MP_CAL_X            = 7976
   MP_CAL_Y            = 8180
   MP_CAL_Z            = 8259
   NUN_CAL_X           = 515
   NUN_CAL_Y           = 490
   NUN_CAL_Z           = 525
   NUN_CAL_JOY_X       = 128
   NUN_CAL_JOY_Y       = 128
   CLASSIC_CAL_L_JOY_X = 32
   CLASSIC_CAL_L_JOY_Y = 32
   CLASSIC_CAL_R_JOY_X = 32
   CLASSIC_CAL_R_JOY_Y = 32

   MP_ONLY       = 4 'MotionPlus only
   MP_NUN        = 5 'MotionPlus w/ Nunchuck
   MP_CLASSIC    = 7 'MotionPlus w/ Classic Controller

OBJ
   i2cObject      : "i2cObject"
   fMath : "Float32Full"

VAR
   byte acc_mode
   long rot_x
   long rot_y
   long rot_z
   byte extension
   byte spd_x
   byte spd_y
   byte spd_z
   long joy_x
   long joy_y
   long accel_x
   long accel_y
   long accel_z
   byte button_c
   byte button_z
   long joyL_x
   long joyL_y
   long joyR_x
   long joyR_y
   byte shoulder_L
   byte shoulder_R   
   word digital
   byte data[6]
   long _220uS
   byte i2cSCL, i2cSDA
   
PUB init(_scl, _sda, mode)
   i2cSCL := _scl
   i2cSDA := _sda
   i2cObject.Init(i2cSDA, i2cSCL, false)
   fMath.start
   acc_mode := mode
   _220uS := clkfreq / 100_000 * 22 

PUB enMotionPlus
   ''enables Motion Plus controller (writing $04 to Address $FE in the $A6 address space)
   ''this must be done once, which will remap the Motion Plus to the standard extension $A4 address space
   i2cObject.writeLocation(MotionPlus_Addr_1, $FE, acc_mode, 8, 8)
   waitcnt(_220uS+cnt)
  
PUB readMotionPlus
   ''reads Motion Plus gyro data into memory  
   i2cObject.writeLocation(MotionPlus_Addr_2, $40, $00, 8, 8)
   waitcnt(_220uS+cnt)
   i2cObject.i2cStart
   i2cObject.i2cWrite(MotionPlus_Addr_2, 8)
   i2cObject.i2cWrite(0,8)
   i2cObject.i2cStop
   waitcnt(_220uS+cnt)
   i2cObject.i2cStart
   i2cObject.i2cWrite(MotionPlus_Addr_2|1, 8)
   data[0] := i2cObject.i2cRead(0)
   data[1] := i2cObject.i2cRead(0) 
   data[2] := i2cObject.i2cRead(0) 
   data[3] := i2cObject.i2cRead(0) 
   data[4] := i2cObject.i2cRead(0) 
   data[5] := i2cObject.i2cRead(1)
   i2cObject.i2cStop

   if data[5]&3==%10 'MotionPlus data 
     rot_x := (((data[5]&$FC)<<6)|data[2])-MP_CAL_X
     rot_y := (((data[4]&$FC)<<6)|data[1])-MP_CAL_Y
     rot_z := (((data[3]&$FC)<<6)|data[0])-MP_CAL_Z
     spd_x := data[3]&1
     spd_y := (data[4]&2)>>1
     spd_z := (data[3]&2)>>1      
     extension := data[4]&1
   elseif data[5]&3==%00 'Extension data
     if acc_mode==MP_NUN 'Configured for Nunchuck (removes LSBit of accelerometer readings)
        joy_x := data[0]-NUN_CAL_JOY_X
        joy_y := data[1]-NUN_CAL_JOY_Y
        accel_x := ((data[2]<<2)|((data[5]>>3)&2))-NUN_CAL_X
        accel_y := ((data[3]<<2)|((data[5]>>4)&2))-NUN_CAL_Y
        accel_z := (((data[4]&$FE)<<2)|((data[5]>>5)&6))-NUN_CAL_Z
        button_z := ((data[5]>>2)&1)^1
        button_c := ((data[5]>>3)&1)^1
     elseif acc_mode==MP_CLASSIC 'Configured for Classic Controller (removes LSBit of left analog stick readings)
        joyL_x := (data[0]&$3E)-CLASSIC_CAL_L_JOY_X '6 bits (consistent w/ dedicated Classic Controller data, Motion Plus removes LSBit)
        joyL_y := (data[1]&$3E)-CLASSIC_CAL_L_JOY_Y '6 bits (consistent w/ dedicated Classic Controller data, Motion Plus removes LSBit)
        joyR_x := (((data[0]>>2)&($30))|((data[1]>>4)&($0c))|((data[2]>>6)&2))-CLASSIC_CAL_R_JOY_X 'RX only 5 bits, make 6 bits to be consistent w/ LX
        joyR_y := ((data[2]<<1)&$3E)-CLASSIC_CAL_R_JOY_Y 'RY only 5 bits, make 6 bits to be consistent w/ LY
        shoulder_L := ((data[2]>>2)&($18))|(data[3]>>5) '5 bits
        shoulder_R := data[3]&$1F '5 bits
        digital := !((1<<15)|(data[5]<<7)|(data[4]>>1)|((data[0]&1)<<7)|((data[1]&1)<<8)) 'invert to 0=not pressed, 1=pressed

PUB rotate_x
   ''returns pitch rotation data
   if spd_x
     return rot_x/20
   else
     return rot_x/4

PUB rotate_y
   ''returns roll rotation data
   if spd_y
     return rot_y/20
   else
     return rot_y/4

PUB rotate_z
   ''returns yaw rotation data
   if spd_z
     return rot_z/20
   else
     return rot_z/4
   
PUB ext
   ''returns whether an extension is connected to the MotionPlus or not
   return extension

PUB joyX
   ''returns joystick x axis data
   if acc_mode==MP_NUN
     return joy_x
   else
     return 0

PUB joyY
   ''returns joystick y axis data
   if acc_mode==MP_NUN
     return joy_y
   else
     return 0

PUB accelX
   ''returns x axis accelerometer data
   if acc_mode==MP_NUN
     return accel_x
   else
     return 0

PUB accelY
   ''returns y axis accelerometer data 
   if acc_mode==MP_NUN
     return accel_y
   else
     return 0

PUB accelZ
   ''returns z axis accelerometer data
   if acc_mode==MP_NUN
     return accel_z
   else
     return 0

PUB radius
   ''radius, used for determining pitch
   return ^^(accel_x*accel_x + accel_y*accel_y + accel_z*accel_z) 

PUB pitch | rad
   ''computes pitch
   ''only 180 degrees of pitch (+/- 90) available from y data, since there's no yaw data
   if acc_mode==MP_NUN
     rad := radius
     if rad>0 'radius of 0 during freefall will cause div by 0, so prevent this 
       return fMath.FRound(fMath.Degrees(fMath.ACos(fMath.FDiv(fMath.FFloat(accel_y),fMath.FFloat(radius)))))-90
     else 'return 0 degrees since accel_y=0 (radius=0 means all accelerations were 0) typically corresponds to 0 degrees pitch (no better guess) 
       return 0
   else
     return 0 

PUB roll
   ''computes roll
   ''full 360 degrees of roll (+/- 180) available from x and z data
   if acc_mode==MP_NUN
     return fMath.FRound(fMath.Degrees(fMath.ATan2(fMath.FFloat(accel_x),fMath.FFloat(accel_z))))
   else
     return 0

PUB buttonC
   ''returns button C pressed or not
   if acc_mode==MP_NUN
     return button_c
   else
     return 0

PUB buttonZ
   ''returns button Z pressed or not 
   if acc_mode==MP_NUN
     return button_z
   else
     return 0

PUB joyLX
   ''returns left joystick x axis data
   if acc_mode==MP_CLASSIC
     return joyL_x
   else
     return 0 

PUB joyLY
   ''returns left joystick y axis data
   if acc_mode==MP_CLASSIC
     return joyL_y
   else
     return 0

PUB joyRX
   ''returns right joystick x axis data
   if acc_mode==MP_CLASSIC
     return joyR_x
   else
     return 0 

PUB joyRY
   ''returns right joystick y axis data
   if acc_mode==MP_CLASSIC
     return joyR_y
   else
     return 0 

PUB shoulderL
   ''returns left analog shoulder button value
   if acc_mode==MP_CLASSIC
     return shoulder_L
   else
     return 0 

PUB shoulderR
   ''returns right analog shoulder button value
   if acc_mode==MP_CLASSIC
     return shoulder_R
   else
     return 0 

PUB buttons
   ''returns button data (see table at top for details)
   if acc_mode==MP_CLASSIC
     return digital
   else
     return 0 
 
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