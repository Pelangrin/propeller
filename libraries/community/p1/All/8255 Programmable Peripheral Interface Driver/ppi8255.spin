'' 8255 Programmable Peripheral Interface Driver - version 1.0
''
'' Written 2006 by Dennis Ferron
'' For questions or comments email me at:  System.Windows.CodeSlinger@gmail.com
''
'' This object is designed to operate the 8255 ports in Mode 0 only.  It
'' is possible to use this object to set other modes, and they may work just
'' fine, but only Mode 0 is tested and supported.
''
'' This object allows you to connect as many 8255 chips as you wish together
'' on a shared bus.  They can share a bus because only 1 chip is selected at a time.
''
'' There are two ways you can set up the chip select circuit:  with an address
'' decoder, or without an address decoder.  In both cases, BusCsMsb through BusCsLsb
'' indicates a range of pins, which may total 2 to 4 pins depending on your needs.
'' (Your choice.)
''
'' With an address decoder, you would
'' connect the BusCsMsb through BusCsLsb pins to the address lines of a demux
'' chip such as the 74154.  Connect the outputs of the 74154 to the CS lines
'' of each 8255.  Then the address written to the BusCsMsb to BusCsLsb lines
'' will cause the demux to select the correct 8255 chip.  The number of pins
'' used for addressing (BusCsMsb to BusCsLsb) can be anything from 1 to 4, so
'' you can have up to 16 different 8255 chips on the bus.
''
'' To use the 8255 object without an address decoder, simply connect the CS
'' pins of the 8255's directly to the BusCsMsb to BusCsLsb pins of the Propeller.
'' Then for your CS "addresses" you would use bit masks which select only
'' one of the 8255's at a time.  For instance, if you have 3 8255 chips, then
'' your addresses would be %110, %101, and %011.  (Addresses like %001 or %000
'' would not be valid for reads because they select more than one chip at a
'' time and would cause bus contention.  These addresses could be used to write identical
'' data to multiple chips at once.  Each 0 bit enables a chip select line.)
'' Using this method, you can have 1 to 4 8255's.
''
'' --------------------------------------------------------------------------------
''
''  Example Circuit without address decoding: 
''
'' ┌───────────┐
'' │ Propeller │     Data bus        ┌──────┐    ┌──────┐    ┌──────┐
'' │  BusD0..D7│────────────────────│      │───│      │───│      │
'' │           │    Control bus      │ 8255 │    │ 8255 │    │ 8255 │
'' │ BusRd, Wr,│────────────────────│      │───│      │───│      │
'' │ BusA0, A1,│                     └──────┘    └──────┘    └──────┘
'' │     Reset │                         CS         CS         CS
'' │           │          CsAddr = %110 │           │           │
'' │ BusCsLsb  │────────────────────────┘    = %101 │           │
'' │   ...     │────────────────────────────────────┘    = %011 │
'' │ BusCsMsb  │────────────────────────────────────────────────┘
'' └───────────┘
''
'' (Note that the parallel lines indicate shared data and control buses;
''    it does NOT mean that the 8255's are daisy chained on the previous chip's ports.)
''
''  For my test setup, I used these pin configurations:
''
''      BusD0 = pin 0           BusA0 = pin 16
''      BusD7 = pin 7           BusA1 = pin 17
''      BusRd = pin 18          BusCsLsb = pin 21
''      BusWr = pin 19          BusCsMsb = pin 23
''      BusReset = pin 20       
''
'' ---------------------------------------------------------------------------------------
''
''  Example Circuit with address decoding: 
''
'' ┌───────────┐
'' │ Propeller │     Data bus              ┌──────┐    ┌──────┐    ┌──────┐    ┌──────┐
'' │  BusD0..D7│──────────────────────────│      │───│      │───│      │───│      │
'' │           │    Control bus            │ 8255 │    │ 8255 │    │ 8255 │    │ 8255 │ 
'' │ BusRd, Wr,│──────────────────────────│      │───│      │───│      │───│      │
'' │ BusA0, A1,│                           └──────┘    └──────┘    └──────┘    └──────┘
'' │     Reset │                               CS         CS         CS         CS
'' │           │     ┌───────┐  CsAddr = %00  │           │           │           │
'' │ BusCsLsb  │────│ 74154 │────────────────┘     = %01 │           │           │
'' │ BusCsMsb  │────│   or  │────────────────────────────┘     = %10 │           │
'' │           │     │similar│────────────────────────────────────────┘      =%11 │
'' └───────────┘     │       │────────────────────────────────────────────────────┘
''                   └───────┘
''
'' (Note that the parallel lines indicate shared data and control buses;
''    it does NOT mean that the 8255's are daisy chained on the previous chip's ports.)
'' ---------------------------------------------------------------------------------------
''
VAR

  ' This section defines the pins that the 8255(s) are connected on.
  ' Your 8255 chips will all share control and data bus pins on the Prop. 

  ' Use the Setup function to set these values for the io8255 object. 
  
  ' 8255 Control bus
  byte BusA0
  byte BusA1
  byte BusRd
  byte BusWr
  byte BusReset

  ' 8255 Data bus
  byte BusD0
  byte BusD7

  ' Used to select which 8255 to enable.
  ' May be any number of pins, but if
  ' you use more than 3, you may need more
  ' than 8 slots in the control words array. 
  byte BusCsLsb
  byte BusCsMsb

VAR

  ' This array stores the mode set control
  ' words so that you can individually change
  ' the direction of each port without clobbering
  ' the directions of the other ports.  Each individual
  ' 8255 on the bus needs its own separate control word.
  ' The address of the chip select on the BusCs pins
  ' is used to index this array. 
  byte ControlWords[16]  

CON

  ' Cw stands for "control word" (of the 8255s)
  ' Each of these bit masks sets a specific bit
  ' associated with a function of the chip.
  CwModeSet =   %1000_0000
  CwModeA =     %0110_0000
  CwDirA =      %0001_0000
  CwDirUpperC = %0000_1000
  CwModeB =     %0000_0100
  CwDirB =      %0000_0010
  CwDirLowerC = %0000_0001
  
  ' The 8255 direction register operates the opposite
  ' of the Propeller's direction register -
  ' for the 8255 control word, a low makes
  ' and output and a high makes an input.
  BusOutput = 0
  BusInput = 1

  ' These are the addresses of the 8255 ports.
  PortA = 0
  PortB = 1
  PortC = 2
  Control = 3 

PRI ChangeMode(CsAddr, Mode)

  ' Changes the mode control word of an 8255 and also
  ' records the value in the ControlWords array.  For
  ' internal use only.
  
  ' The mode change bit must be 1 when changing
  ' a port direction, because 0 would indicate a port C bit set. 
  Mode |= CwModeSet

  ' Store the last control word set so it can be recalled
  ' when the direction of one of the ports needs to be changed.
  ControlWords[CsAddr] := Mode

  ' Then we simply write the byte to the control register.
  Write(CsAddr, Control, Mode)

PUB SetPins(pBusA0, pBusA1, pBusRd, pBusWr, pBusReset, pBusD0, pBusD7, pBusCsLsb, pBusCsMsb)

  '' Indicate which Propeller pins the 8255 interface bus is on.
  
  BusA0 := pBusA0
  BusA1 := pBusA1
  BusRd := pBusRd
  BusWr := pBusWr
  BusReset := pBusReset
  BusD0 := pBusD0
  BusD7 := pBusD7
  BusCsLsb := pBusCsLsb
  BusCsMsb := pBusCsMsb

  ' Data bus is inputs in resting state.
  DirA[BusD0..BusD7]~

  ' Make the control bus all outputs.
  ' (The 8255s can't output to these lines anyway.)
  DirA[BusA1..BusA0]~~
  DirA[BusRd]~~
  DirA[BusWr]~~
  DirA[BusReset]~~
  DirA[BusCsMsb..BusCsLsb]~~

  ' Clear the read and write signals.  (High = inactive.)
  OutA[BusRd]~~
  OutA[BusWr]~~

  ' Turn off chip select
  OutA[BusCsMsb..BusCsLsb]~~
  

PUB Reset

  '' Resets all of the 8255's connected to the propeller.

  ' A high on the reset pin clears the control registers
  ' and sets all pins to inputs.
  OutA[BusReset]~~

  ' We need to wait long enough for the  8255s to reset.
  ' The first reset after power on has to be 50,000 ns;
  ' subsequent resets can be shorter - just 500 ns - but
  ' it is simpler to just wait the longer time in both cases.
  waitcnt(cnt+1_000_000)

  ' Now we bring the reset pin low again to take the
  ' 8255s out of reset so they can operate normally.
  OutA[BusReset]~

PUB SetMode(CsAddr, PortAddr, ModeNum) | Magic

  '' Use to set the mode of an 8255 port.
  ''    CsAddr:                 the chip select address to use.
  ''    PortAddr:               0 = PortA, 1 = PortB
  ''    ModeNum:                0 or 1 for PortB; 0, 1, or 2 for PortA
  ''                            (Modes other than 0 not tested.)   

  ' First, we need to get the old value to avoid nuking
  ' the direction settings of the other registers.
  Magic := ControlWords[CsAddr]

  ' Only ports A and B can have their modes set.
  ' Only port A can select mode 2.
  ' The mode number is simply shifted to a specific bit position.
  CASE PortAddr
    PortA:
      Magic &= !CwModeA 
      Magic |= ModeNum << 5
    PortB:
      Magic &= !CwModeB
      Magic |= ModeNum << 2

  ChangeMode(CsAddr, Magic)

PUB SetDir(CsAddr, PortAddr, Dir) | Magic, Mask

  '' Use to set the direction of an 8255 port.
  ''    CsAddr:                 the chip select address to use
  ''    PortAddr:               0 = PortA, 1 = PortB, 2 = PortC (lower),
  ''                            3 = PortC (upper)
  ''    Dir:                    0 = Output, 1 = Input
  ''                            (Yes, it is opposite of DirA behavior.)     

  ' We must build a magic number to use to set up
  ' the control register for the 8255.

  ' First, we need to get the old value to avoid nuking
  ' the direction settings of the other registers.
  Magic := ControlWords[CsAddr]

  ' Depending on which port direction is being
  ' changed, a different set of bits needs to
  ' be put into the mask.  Port C has two parts;
  ' the magic code to set the direction of upper C is
  ' the same as (conflicts with) the address of
  ' the control word, but you cannot set control word
  ' direction so it doesn't really cause a problem. 
  CASE PortAddr
    PortA:  Mask := CwDirA
    PortB:  Mask := CwDirB
    PortC:  Mask := CwDirLowerC
    PortC+1:  Mask := CwDirUpperC

  ' Set the direction bit.
  IF Dir == 0  ' If doing an 8255 output
    Magic &= !Mask  ' then clear the bit
  ELSE         ' else doing an input 
    Magic |= Mask   ' so set the bit

  ChangeMode(CsAddr, Magic)

PUB SetBitC(CsAddr, BitPos, Value)

  '' Use to set a single bit in port C.  Useful for bit-banging
  '' control lines on PortC so you can change one bit without
  '' glitching the others as could happen if you wrote 8 bits.
  ''    CsAddr:                 The chip select address to use
  ''    BitPos:                 0 to 7, indicates which bit of port C to change
  ''    Value:                  0 = clear the bit, 1 = set the bit

  ' Bit3 to Bit1 define bit position, Bit0 sets or clears the bit,
  ' and all other control word bits are 0 to do Port C bit changes.
  Write(CsAddr, Control, (BitPos << 1) | Value)

PUB Write(CsAddr, PortAddr, Data)

  '' Use to write to a port in an 8255.  Has no effect if the
  '' direction of the port is not set to output (use SetDir).
  ''    CsAddr:                 the chip select address to use
  ''    PortAddr:               0 = PortA, 1 = PortB, 2 = PortC,
  ''                            3 = Control (for internal use only).
  ''    Data:                   The data byte to write.                   

  ' We set the address early so it can stabilize and to
  ' give the 8255 time to recognize it.
  OutA[BusA1..BusA0] := PortAddr

  ' Enable the specific 8255 we want
  OutA[BusCsMsb..BusCsLsb] := CsAddr

  ' We actually pull down the write line before we set
  ' the data lines, so that when we finish the 8255 will be ready.
  OutA[BusWr]~

  ' The data bus needs to be outputs so we can write the data value
  DirA[BusD7..BusD0]~~

  ' Here is where we actually put the data byte on the data bus
  OutA[BusD7..BusD0] := Data

  ' Pulling the write line high latches the data.
  OutA[BusWr]~~

  ' Since the data has been latched, we can now make the Propeller's
  ' data bus pins to be inputs to free up the data bus. 
  DirA[BusD0..BusD7]~

  ' No need to deselect the 8255 - we will simply select a different
  ' one next time. 

  ' Write is finished.      

PUB Read(CsAddr, PortAddr) : Data

  '' Use to read a port from an 8255.  Behavior undefined
  '' if the port is not set to an input (use SetDir).
  ''    CsAddr:                 the chip select address to use
  ''    PortAddr:               0 = PortA, 1 = PortB, 2 = PortC
  ''                            3 = Control (reads strange values, do not use)
  ''    returns:                the data byte from the given port.                    

  ' We set the address early so it can stabilize and to
  ' give the 8255 time to recognize it.
  OutA[BusA1..BusA0] := PortAddr

  ' Enable the specific 8255 we want
  OutA[BusCsMsb..BusCsLsb] := CsAddr

  ' The data bus needs to be inputs so we can read the data value
  DirA[BusD7..BusD0]~

  ' We must pull down the read line before we read
  ' the data lines, so that the 8255 will put out the data.
  OutA[BusRd]~

  ' When the data is stabilized we read the data byte from the data bus.
  Data := InA[BusD7..BusD0]

  ' We have to return the read line to high after every read.
  OutA[BusRd]~~

  ' No need to deselect the 8255 - we will simply select a different
  ' one next time. 

  ' Read is finished.      
    