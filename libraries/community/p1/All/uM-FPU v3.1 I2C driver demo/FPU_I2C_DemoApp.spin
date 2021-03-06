{{
┌───────────────────────────┬───────────────────┬────────────────────────┐
│ FPU_I2C_DemoApp.spin v1.2 │ Author: I.Kövesdi │ Release:   25 08 2008  │
├───────────────────────────┴───────────────────┴────────────────────────┤
│                    Copyright (c) 2008 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │ 
│  This is a HyperTerminal application to demonstrate the  usage of the  │
│ uM-FPU v3.1 with I2C data transfer protocol. It uses 4 driver objects: │ 
│ one for the debug terminal, one for the I2C bus, one for the FPU and   │
│ one for the DS1621 thermometer IC. These last 3 drivers are implemented│
│ in SPIN. This application uses 2 COGs including the one for the SPIN   │
│ interpreter.                                                           │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  With I2C protocol you can connect your FPU onto an existing I2C bus in│
│ your application. Data burst transfer rate with the applied I2C driver │
│ is more than 2 Kbyte/sec. In not speed critical or in well organized   │
│ applications (see e.g. user defined functions in the FPU!) this        │
│ communication speed might be sufficient.                               │
│  In this demo many capabilities of the FPU are exercised and a digital │
│ thermometer is used to demonstrate real-time data processing, unit     │
│ conversion, etc... with the FPU.                                       │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  If you want to use more than one uM-FPU on the I2C bus, you have to   │
│ build a serial debug interface to the FPU to change the default I2C    │
│ address of the device(s).                                              │
│                                                                        │        
└────────────────────────────────────────────────────────────────────────┘                                                                        


Hardware: 
Organization of the I2C bus + uM-FPU MASTER CLEAR line

                    10K
             ┌──────────┳─ 3.3V        3.3V           3.3V
             │            │               │              │
             │     4.7K   │      ┌──────┐ │  ┌─────────┐ │
             │ ┌────────┫      │DS1621├─┘  │uM-FPU3.1├─┘  
    ├─       │ │ ┌──────┘      └─┬──┬─┘    └─┬──┬──┬─┘
   P│        │ │ │                 │  │        │  │  │   
   8├A18─────┼─┻─┼─────────────────┻──┼────────┼──┻──┼──── SDA
   X│        │   │       I2C          │        │     │
   3├A19─────┼───┻────────────────────┻────────┼─────┻──── SCL
   2│        │                                 │
   A├A20─────┻─────────────────────────────────┘ uM-FPU/MCLR
    │                                               
    ├─


Connections:
                        
                                   3.3V
                  ┌───────────────┐ │
               ┌──┤A0          VDD├─┘
               ┣──┤A1   DS1621    │  
               ┣──┤A2             │                                      
               ┣──┤GND            │                                        
               │  │               │             ──┳──┳── 3.3V                              
               │  │  SDA     SCL  │               │  │                  
               ┴  └───┬───────┬───┘               │  │ 
              GND     │       │              4.4K    4.7K
                      │       │                   │  │ 
    │                 │       │                   │  │
    ├A18─────────┳────┻───────┼───────────────────┻──┼──────  SDA                   
   P│            │            │         I2C          │ 
    │            │            │         BUS          │
   8├A19─────────┼───────┳────┻──────────────────────┻──────  SCL                                   
   X│            │       │
    │            │       │                  3.3V       
   3├A20─────────┼───────┼───────┳─────────┫                            
   2│            │       │       │    10K    │
                 │       │       │           │
                 │       │       │           │
              ┌──┴───────┴───────┴──┐        │           
              │SDA12   SCL11   /MCLR│        │                  
              │                     │        │
              │                 AVDD├────────┫     
              │                  VDD├────────┫
              │                   CS├────────┘
              │     uM-FPU v3.1     │
              │                     │       
           ┌──┤TSTIN9               │         
           ┣──┤AVSS                 │             
           ┣──┤VSS                  │         
           │  │                     │         
           ┴  └─────────────────────┘
          GND

The CS pin of the FPU is tied to HIGH to select I2C mode at Reset and must
remain HIGH during operation.    
}}


CON
  _clkmode       = xtal1 + pll16x
  _xinfreq       = 5_000_000


'Hardware  
  _SDA           = 18
  _SCL           = 19
  _FPU_MCLR      = 20

'I2C Addresses  
  _DS1621_Addr   = %1001_0000   'Dec 144, A0, A1, A2 all tied to GND
  _FPU_Address   = %1100_1000   'Dec 200, Default I2C address of FPU

'FPU registers for DS1621 data
  _8BITR         = 1
  _9BITR         = 2
  _CNTREM        = 3
  _SLOPE         = 4
  _M1Q           = 5
  _HIREST        = 6
  
  
VAR

  long  okay, ds16, fpu3
  long floats[12]


OBJ

  Debug   : "FullDuplexSerialPlus"   'From Parallax Inc.
                                     'Propeller Education Kit
                                     'Objects Lab v1.1
  I2C      : "I2C_Driver"            'v1.2
  FPU      : "FPU_I2C_Driver"        'v1.2
  DS1621   : "DS1621_I2C_Driver"     'v1.2

  
PUB DoIt
'-------------------------------------------------------------------------
'------------------------------------┌──────┐-----------------------------
'------------------------------------│ DoIt │-----------------------------
'------------------------------------└──────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Starts driver objects
''             Checks I2C bus
''             Checks devices
''             Makes a MASTER CLEAR for the FPU
''             Calls FPU and DS1621 demo procedures
'' Parameters: None
''    Results: None
''+Reads/Uses: Device addresses and hardware constants from CON section
''    +Writes: None
''      Calls: FullDuplexSerialPlus->Debug.Start
''             I2C_Driver ---------->I2C.Init
''             Ds1621_I2C_Driver---->DS1621.Init
''             FPU_I2C_Driver------->FPU.Init
''             I2CScan, FPU_Demo, H48C_Demo
'-------------------------------------------------------------------------
'Start FullDuplexSerialPlus Debug terminal
Debug.Start(31, 30, 0, 57600)
  
waitcnt(6 * clkfreq + cnt)

Debug.Str(string(10, 13, "uM-FPU V3.1 and DS1621 demo with I2C protocol"))
Debug.Str(string(10, 13))

waitcnt(clkfreq + cnt)

ds16 := false
fpu3 := false

'Setup I2C
if I2C.Init(_SDA, _SCL) == true
  Debug.Str(string(10, 13))
  Debug.Str(string("I2C lines are HIGH and STABLE!", 10, 13))

  waitcnt(clkfreq + cnt)

  'Scan the I2C bus
  I2CScan 
  
  'Init DS1621 thermometer 
  okay := DS1621.Init(_DS1621_Addr, _SDA, _SCL)
  if okay == true
    Debug.Str(string(10, 13)) 
    Debug.Str(string("DS1621 Present!", 10, 13))
    ds16 := true
  else
    Debug.Str(string(10, 13))
    Debug.Str(string("DS1621 Missing!", 10, 13))
        
  'Init FPU
  okay := FPU.Init(_FPU_Address, _SDA, _SCL)
  if okay == true
    Debug.Str(string(10, 13)) 
    Debug.Str(string("uM-FPU Present!", 10, 13))
    Debug.Str(string(10, 13))
    fpu3 := true
  else
    Debug.Str(string(10, 13))
    Debug.Str(string("uM-FPU Missing!", 10, 13))
    Debug.Str(string(10, "Trying FPU MASTER CLEAR...", 10, 13)) 
    outa[_FPU_MCLR]~~ 
    dira[_FPU_MCLR]~~
    outa[_FPU_MCLR]~
    waitcnt(clkfreq + cnt)
    outa[_FPU_MCLR]~~
    dira[_FPU_MCLR]~
    okay := FPU.Init(_FPU_Address, _SDA, _SCL)
    if okay == true 
      Debug.Str(string("uM-FPU Present!", 10, 13))
      fpu3 := true
    else  
      Debug.Str(string("Fatal uM-FPU error!", 10, 13))
      repeat

  if fpu3
    Debug.Str(string(10, "FPU MASTER CLEAR...", 10, 13)) 
    outa[_FPU_MCLR]~~ 
    dira[_FPU_MCLR]~~
    outa[_FPU_MCLR]~
    waitcnt(clkfreq + cnt)
    outa[_FPU_MCLR]~~
    dira[_FPU_MCLR]~
   
  if (fpu3 and ds16)
    FPU_Demo
    DS1621_Demo
    Debug.Str(string(10, 13))
    Debug.Str(string("FPU & DS1621 demo terminated normally..."))
    Debug.Str(string(10, 13))
  else
    if fpu3
      FPU_Demo
      Debug.Str(string(10, 13))
      Debug.Str(string("FPU demo terminated normally..."))
      Debug.Str(string(10, 13))
    else
      Debug.Str(string(10, 13))
      Debug.Str(string("FPU not found! Quitting..."))
      Debug.Str(string(10, 13))         
 
else
  Debug.Str(string(10, 13))    
  Debug.Str(string("I2C lines are NOT HIGH or NOT STABLE!", 10, 13))
  Debug.Str(string("Please check hardware and restart...!", 10, 13))

  'FPU might hang on. Try an FPU Master Clear again as a last resort...
  outa[_FPU_MCLR]~~ 
  dira[_FPU_MCLR]~~
  outa[_FPU_MCLR]~
  waitcnt(clkfreq + cnt)
  outa[_FPU_MCLR]~~
  dira[_FPU_MCLR]~
'-------------------------------------------------------------------------
   

PRI I2CScan | i2cAddress, address, ackbit, cntr
'-------------------------------------------------------------------------
'---------------------------------┌─────────┐-----------------------------
'---------------------------------│ I2CScan │-----------------------------
'---------------------------------└─────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Scans even addresses on the I2C bus up to 254 Dec
'             Counts responding devices
' Parameters: None
'    Results: None
'+Reads/Uses: None
'    +Writes: None
'      Calls: FullDuplexSerialPlus->Debug.Str
'             FullDuplexSerialPlus->Debug.Dec
'             I2C_Driver ---------->I2C.PingDeviceAt
'-------------------------------------------------------------------------
  Debug.Str(string(10, 13))
  Debug.Str(string("-----------------I2C Scan----------------"))
  Debug.Str(string(10, 13))

  waitcnt(clkfreq + cnt)
  
  cntr := 0
  repeat i2cAddress from 0 to 127
    address :=  i2cAddress << 1 | 0   'Multiply it with 2 
    'Send the address byte and listen for a device to ACKnowledge it   
    ackbit := I2C.PingDeviceAt(address)

    'Display address and response
    Debug.Str(string(10, 13, "Scan Addr. : "))
    Debug.Dec(address)
    if ackbit==true            'i.e. zero
      Debug.Str(string(" ACKNOWLEDGED"))
      waitcnt(clkfreq/2+cnt)
      cntr++                  'Count device
    else
      Debug.Str(string(" NAK"))      
  '      
   'Slow the scan slightly    
    waitcnt(clkfreq/100 + cnt)

  Debug.Str(string(10, 10, 13, 13, "No. of responding I2C devices: "))
  Debug.Dec(cntr)
  Debug.Str(string(10, 10, 13))      
'-------------------------------------------------------------------------
 

PRI FPU_Demo | ackBits, i, char, strPtr
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ FPU_Demo │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Demonstrates many FPU features by calling FPU_SPI_Driver
'             procedures and shows several methods of data exchange
'             between the Propeller and the FPU.
'             Demonstrates matrix operations
'             Demonstrates FFT 
' Parameters: None
'    Results: None
'+Reads/Uses: Some constants from the FPU object
'    +Writes: None
'      Calls: FullDuplexSerialPlus->Debug.Str
'                                   Debug.Dec
'                                   Debug.Hex
'                                   Debug.Bin   
'             FPU_I2C_Driver ------>FPU.Reset
'                                   FPU.ReadSyncChar
'                                   FPU.ReadVersionString
'                                   FPU.ReadVersionCode
'                                   FPU.ReadCheckSum
'-------------------------------------------------------------------------
  Debug.Str(string(10, 10, 13, 13))
  Debug.Str(string("---------------uM-FPU-V3.1 demo------------"))
  Debug.Str(string(10, 13))

  waitcnt(clkfreq + cnt)

  Debug.Str(string(10, 13))
  Debug.Str(string("FPU Software Reset...", 10, 13)) 
  
  FPU.Reset

  char := FPU.ReadSyncChar
  Debug.Str(string(10, 13))
  Debug.Str(string("Response to _SYNC: "))
  Debug.Dec(char)
  if (char== FPU#_SYNC_CHAR)
    Debug.Str(string("    (OK)")) 
  else
    Debug.Str(string("   Not OK!"))   
  Debug.Str(string(10, 13))

  if char <> FPU#_SYNC_CHAR
    Debug.Str(string("No Sync, trying a MASTER CLEAR first..."))
    Debug.Str(string(10, 13))
    outa[_FPU_MCLR]~~ 
    dira[_FPU_MCLR]~~
    outa[_FPU_MCLR]~
    waitcnt(clkfreq + cnt)
    outa[_FPU_MCLR]~~
    dira[_FPU_MCLR]~

    Debug.Str(string("Than trying an FPU Software Reset...", 10, 13))
    ackBits := FPU.Reset
    char := FPU.ReadSyncChar
    Debug.Str(string("Response to _SYNC:"))
    Debug.Dec(char)
    if (char== FPU#_SYNC_CHAR)
      Debug.Str(string("    (OK)")) 
    else
      Debug.Str(string("   Not OK!"))   
      Debug.Str(string(10, 13, 13))
      Debug.Str(string("FPU not synchronised! Stop..."))
      Debug.Str(string(10, 13, 13))
      repeat                           'forever (until power is off)

  Debug.Str(string(10, 10, 13))    
  Debug.Str(string("   Version String: "))
  ackBits := FPU.WriteCmd(FPU#_VERSION)
  FPU.Wait
  ackBits := FPU.WriteCmd(FPU#_READSTR)
  strPtr := FPU.ReadStr
  Debug.Str(strPtr)
  Debug.Str(string(10, 13))

  Debug.Str(string(10, 13))
  Debug.Str(string(" Clock ticks / ms: "))
  Debug.Dec(FPU.ReadInterVar(FPU#_TICKS))
  Debug.Str(string(10, 10, 13, 13))

  waitcnt(2*clkfreq + cnt)
'-------------------------------------------------------------------------


PRI DS1621_Demo | ackBits,tempVar,tempCheck,cntr,slope,htAlert,ltAlert
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ DS1621_Demo │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Demonstrates many DS1621 features with the use of FPU  
' Parameters: None
'    Results: None
'+Reads/Uses: /Some constants from the DS1621 and FPU I2C driver objects
'    +Writes: None
'      Calls: FullDuplexSerialPlus->Debug.Str
'                                   Debug.Dec
'                                   Debug.Bin
'             DS1621_I2C_Driver---->DS1621.ReadConfig
'                                   DS1621.WriteConfig
'                                   DS1621.OrWithConfig 
'                                   DS1621.StartConversion
'                                   DS1621.Read8BitTemp
'                                   DS1621.Read9BitTemp
'                                   DS1621.ReadSlope
'                                   DS1621.ReadCounter
'                                   DS1621.ReadTH
'                                   DS1621.WriteTH
'                                   DS1621.ReadTL
'                                   DS1621.WriteTL
'             FPU_I2C_Driver ------>FPU.WriteCmd
'                                   FPU.WriteCmdByte
'                                   FPU.FPU.WriteCmdRnLong
'                                   FPU.ReadRaFloatAsStr
'-------------------------------------------------------------------------
  Debug.Str(string(10, 10, 13, 13))
  Debug.Str(string("-----DS1621 & uM-FPU-v3.1 demo with I2C------"))
  Debug.Str(string(10, 13))

  waitcnt(2*clkfreq + cnt)

  Debug.Str(string(10, 13))
  Debug.Str(string("Read Configuration Register..."))
  Debug.Str(string(10, 13))
  tempVar := DS1621.ReadConfig
  Debug.Str(string("           ConfigReg: %"))
  Debug.Bin(tempVar,8)
  Debug.Str(string(10, 10, 13))
  Debug.Str(string("Clear 7 LSB bits of Conf. Reg. ..."))
  Debug.Str(string(10, 13))
  ackBits := DS1621.WriteConfig(0)
  waitcnt(DS1621#_NVMemWrDelay + cnt)   'Wait for 10 ms
  tempVar := DS1621.ReadConfig
  Debug.Str(string("       New ConfigReg: %"))
  Debug.Bin(tempVar,8)
  Debug.Str(string(10, 10, 13))
  'Setup the Config Reg. for one shot conversion mode
  Debug.Str(string("Setup Conf. Reg. for One Shot Mode..."))
  Debug.Str(string(10, 13))
  ackBits := DS1621.OrWithConfig(DS1621#_OneShotModeBit)
  waitcnt(DS1621#_NVMemWrDelay + cnt)   'Wait for 10 ms
  'Note that for typical thermostat application the continuous operation
  'mode should be used. This demo, however, is not a typical thermostat
  'application.
  
  tempVar := DS1621.ReadConfig
  Debug.Str(string("       New ConfigReg: %"))
  Debug.Bin(tempVar,8)
  Debug.Str(string(10, 13))
  
  waitcnt(3*clkfreq + cnt)
  
  Debug.Str(string(10, 10, 13))
  Debug.Str(string("Read thermostat settings..."))
  Debug.Str(string(10, 13))
  
  'Read the TH register. It is in 9 bit format! 
  tempVar := DS1621.ReadTH
  FPU.WriteCmdRnLong(FPU#_LWRITE, _9BITR, tempVar)
  FPU.WriteCmdByte(FPU#_SELECTA, _9BITR)
  'Convert it to float from long
  FPU.WriteCmd(FPU#_FLOAT)
  'Convert it to C
  FPU.WriteCmdByte(FPU#_FDIVI, 2)
  Debug.Str(string("        Current TH: "))
  Debug.Str(FPU.ReadRaFloatAsStr(51))
  Debug.Str(string("  C"))
  Debug.Str(string(10, 13))

  'Read the TL register 
  tempVar := DS1621.ReadTL
  FPU.WriteCmdRnLong(FPU#_LWRITE, _9BITR, tempVar)
  FPU.WriteCmdByte(FPU#_SELECTA, _9BITR)
  'Convert it to float from long
  FPU.WriteCmd(FPU#_FLOAT)
  'Convert it to C
  FPU.WriteCmdByte(FPU#_FDIVI, 2)
  Debug.Str(string("        Current TL: "))
  Debug.Str(FPU.ReadRaFloatAsStr(51))
  Debug.Str(string("  C"))
  Debug.Str(string(10, 13))

  waitcnt(3*clkfreq + cnt) 
      
  Debug.Str(string(10, 13))
  Debug.Str(string("Do 7 One Shot temperature readings..."))
  Debug.Str(string(10, 10, 13))
  
  'Do 7 One Shot readings 
  repeat 7
    'Init temp conversion
    ackBits := DS1621.StartConversion
    Debug.Str(string("--------------------> Start conversion..."))
    Debug.Str(string(10, 13))  
    'Wait for conversion ready (i.e. MSBit of ConfigReg=1)
    'This will take 1 s approximately    
    tempVar := DS1621.ReadConfig 
    repeat until (tempVar>127) 
      tempVar := DS1621.ReadConfig
      Debug.Str(string("           ConfigReg: %"))
      Debug.Bin(tempVar,8)
      if (tempVar<128)
        Debug.Str(string(" Not ready..."))
      else
        Debug.Str(string(" Ready!"))
      Debug.Str(string(10, 13))
      'Check High Temp Alert
      htAlert := tempVar & DS1621#_TempHighFlag 
      'Check Low Temp Alert
      ltAlert := tempVar & DS1621#_TempLowFlag
      'Wait a little
      waitcnt(clkfreq/4+cnt)         'Wait for 250 msec
    
    'Conversion done. Read low resolution (1 C) 8 bit TEMP_READ data
    tempVar := DS1621.Read8BitTemp
    Debug.Str(string("     8 bit TEMP_READ: "))
    Debug.Dec(tempVar)
    Debug.Str(string(10, 13))
    'Store it in an FPU register for later use
    FPU.WriteCmdRnLong(FPU#_LWRITE, _8BITR, tempVar)
    FPU.WriteCmdByte(FPU#_SELECTA, _8BITR)
    'Convert it to float from long
    FPU.WriteCmd(FPU#_FLOAT) 

    'Read 0.5 C resolution 9 bit TEMP_READ data
    tempVar := DS1621.Read9BitTemp
    tempCheck := tempVar
    Debug.Str(string("     9 bit TEMP_READ: "))
    Debug.Dec(tempVar)
    Debug.Str(string(10, 13))
    'Store it in an FPU register for later use)
    FPU.WriteCmdRnLong(FPU#_LWRITE, _9BITR, tempVar)
    FPU.WriteCmdByte(FPU#_SELECTA, _9BITR)
    'Convert it to float from long
    FPU.WriteCmd(FPU#_FLOAT)
  
    'Now obtain parameters for high resolution temperature
    'Read COUNT_PER_C slope value
    slope := DS1621.ReadSlope
    Debug.Str(string("         COUNT_PER_C: "))
    Debug.Dec(slope)
    Debug.Str(string(10, 13))
    FPU.WriteCmdRnLong(FPU#_LWRITE, _SLOPE, slope)
    FPU.WriteCmdByte(FPU#_SELECTA, _SLOPE)
    FPU.WriteCmd(FPU#_FLOAT)
  
    'Read COUNT_REMAIN counter
    cntr := DS1621.ReadCounter
    Debug.Str(string("        COUNT_REMAIN: "))
    Debug.Dec(cntr)
    Debug.Str(string(10, 13))
    FPU.WriteCmdRnLong(FPU#_LWRITE, _CNTREM, cntr)
    FPU.WriteCmdByte(FPU#_SELECTA, _CNTREM)
    FPU.WriteCmd(FPU#_FLOAT)  

    'Load -0.25 into an FPU register
    FPU.WriteCmdRnFloat(FPU#_FWRITE, _M1Q, -0.25)  


    Debug.Str(string("--------------------> Calculated temperatures..."))
    Debug.Str(string(10, 13))

    
    'Now display low resolution (1 C) 8 bit TEMP_READ
    FPU.WriteCmdByte(FPU#_SELECTA, _8BITR)
    Debug.Str(string("with  1 C resolution:"))
    Debug.Str(FPU.ReadRaFloatAsStr(30))
    Debug.Str(string("    C"))
    Debug.Str(string(10, 13))
        
    'Now calculate middle resolution (0.5 C) temp (9 bit TEMP_READ)/2)
    FPU.WriteCmdByte(FPU#_SELECTA, _9BITR)
    FPU.WriteCmdByte(FPU#_FDIVI, 2)
    Debug.Str(string("with .5 C resolution:"))
    Debug.Str(FPU.ReadRaFloatAsStr(51))
    Debug.Str(string("  C"))
    Debug.Str(string(10, 13))
  
    'Now calculate high resolution temperature value with the FPU as
    'TEMP=(8bit)TEMP_READ+(COUNT_PER_C-COUNT_REMAIN)/COUNT_PER_C-0.25
    FPU.WriteCmdByte(FPU#_SELECTA, _HIREST) 'Select Reg[A]
    FPU.WriteCmdByte(FPU#_FSET, _SLOPE)     'A=C_PER_C
    FPU.WriteCmdByte(FPU#_FSUB, _CNTREM)    'A=C_PER_C-C_REMAIN
    FPU.WriteCmdByte(FPU#_FDIV, _SLOPE)     'A=(C_PER_C-C_REMAIN)/C_PER_C
    FPU.WriteCmdByte(FPU#_FADD, _8BITR)     'A=A+(8bit)TEMP_READ
    FPU.WriteCmdByte(FPU#_FADD, _M1Q)       'A=A-0.25
    Debug.Str(string("with high resolution:"))
    Debug.Str(FPU.ReadRaFloatAsStr(62))
    Debug.Str(string(" C"))
    Debug.Str(string(10, 13))
    
    'Convert C to F with the FPU in one shot
    FPU.WriteCmdByte(FPU#_FCNV, FPU#_C_F)
    Debug.Str(string("high resolution temp:"))
    Debug.Str(FPU.ReadRaFloatAsStr(62))
    Debug.Str(string(" F"))
    Debug.Str(string(10, 13))
    'Debug.Str(string(10, 13))

    'Now display temperature over/downshoot alerts
    if (htAlert>0)
      Debug.Str(string("Temperature was (at least once) above TH!"))
      Debug.Str(string(10, 13))    
    if (ltAlert>0)
      Debug.Str(string("Temperature was (at least once) below TL!"))
      Debug.Str(string(10, 13))
    if ((htAlert+ltAlert)==0)
      Debug.Str(string("Temperature was (always) within TH-TL limits!"))
      Debug.Str(string(10, 13))   

    Debug.Str(string(10, 13))
    
    'Wait some time so you might see some change in high.res. temperature
    waitcnt(6*clkfreq+cnt)

  'Demo thermostat parameter management...
  Debug.Str(string(10, 13))
  if (tempCheck > 0) and (tempCheck < 140)  'Between 0-70 C. Write OK.  
    Debug.Str(string("Read, Update & Read back thermostat parameters..."))
  else
    Debug.Str(string("Read thermostat parameters..."))  
  Debug.Str(string(10, 13)) 
  'Read the TH register. It is in 9 bit format! 
  tempVar := DS1621.ReadTH
  FPU.WriteCmdRnLong(FPU#_LWRITE, _9BITR, tempVar)
  FPU.WriteCmdByte(FPU#_SELECTA, _9BITR)
  'Convert it to float from long
  FPU.WriteCmd(FPU#_FLOAT)
  'Convert it to C
  FPU.WriteCmdByte(FPU#_FDIVI, 2)
  Debug.Str(string("        Current TH: "))
  Debug.Str(FPU.ReadRaFloatAsStr(51))
  Debug.Str(string("  C"))
  Debug.Str(string(10, 13))

  if (tempCheck > 0) and (tempCheck < 140)  'Write to nonvolatile memory
    tempVar++
    if (tempVar > 65) or (tempVar<49)
      tempVar:= 49                          'Whatever
    ackBits := DS1621.WriteTH(tempVar)
    waitcnt(DS1621#_NVMemWrDelay + cnt)     'Wait for 10 ms
    'Read the updated TH register. It is in 9 bit format! 
    tempVar := DS1621.ReadTH
    FPU.WriteCmdRnLong(FPU#_LWRITE, _9BITR, tempVar)
    FPU.WriteCmdByte(FPU#_SELECTA, _9BITR)
    'Convert it to float from long
    FPU.WriteCmd(FPU#_FLOAT)
    'Convert it to C
    FPU.WriteCmdByte(FPU#_FDIVI, 2)
    Debug.Str(string("            New TH: "))
    Debug.Str(FPU.ReadRaFloatAsStr(51))
    Debug.Str(string("  C"))
    Debug.Str(string(10, 13))

  'Read the TL register 
  tempVar := DS1621.ReadTL
  FPU.WriteCmdRnLong(FPU#_LWRITE, _9BITR, tempVar)
  FPU.WriteCmdByte(FPU#_SELECTA, _9BITR)
  'Convert it to float from long
  FPU.WriteCmd(FPU#_FLOAT)
  'Convert it to C
  FPU.WriteCmdByte(FPU#_FDIVI, 2)
  Debug.Str(string("        Current TL: "))
  Debug.Str(FPU.ReadRaFloatAsStr(51))
  Debug.Str(string("  C"))
  Debug.Str(string(10, 13))

  if (tempCheck > 0) and (tempCheck < 140)  'Write to nonvolatile memory  
    tempVar--
    if (tempVar < 35) or (tempVar>48)
      tempVar := 48                         'Whatever-1
    ackBits := DS1621.WriteTL(tempVar)
    waitcnt(DS1621#_NVMemWrDelay + cnt)     'Wait for 10 ms
    'Read the updated TL register 
    tempVar := DS1621.ReadTL
    FPU.WriteCmdRnLong(FPU#_LWRITE, _9BITR, tempVar)
    FPU.WriteCmdByte(FPU#_SELECTA, _9BITR)
    'Convert it to float from long
    FPU.WriteCmd(FPU#_FLOAT)
    'Convert it to C
    FPU.WriteCmdByte(FPU#_FDIVI, 2)
    Debug.Str(string("            New TL: "))
    Debug.Str(FPU.ReadRaFloatAsStr(51))
    Debug.Str(string("  C"))
    Debug.Str(string(10, 13))
  

{{
┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}                                            