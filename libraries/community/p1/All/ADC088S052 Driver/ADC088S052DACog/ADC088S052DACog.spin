{{
                ADC088S052 Data Acquisition cog v1.0
                Written by Jim Miller
                CannibalRobotics, 2008
                This cog free runs sampling constantly
                The ADC088S052 is a good choice to work with the Prop as it uses a 3.3v supply.
                This implementation runs below the rated minimum speed for this ADC but in robotic applications
                sensing pot positions and joystick movement, no problems have been encountered.
                For simplicity Va,Vd can be tied directly to 3.3v and Agnd & Dgnd tied to ground if pot
                 references are the same.
                
                contact: jmiller5@austin.rr.com        Typical Application for pot read
                        ┌──────┐
                   ~CS  ┫1•  16┣  Sclk                 3.3vdc •────────┐
                    Va  ┫2   15┣  Dout                                 
                  Agnd  ┫3   14┣  Din                  INx    •───────  100K Pot
                   IN0  ┫4   13┣  Vd                                   
                   IN1  ┫5   12┣  Dgnd                 gnd    •────────┘
                   IN2  ┫6   11┣  IN7
                   IN3  ┫7   10┣  IN6
                   IN4  ┫7    9┣  IN5
                        └──────┘
}}
VAR
  Byte  bitno,ADdata,ADTemp, Chan                       ' General Purpose bytes
  Byte  AData[8]                                        ' Raw data from AD
  Byte  ADQual[8]                                       ' Qualified Data - see bottom line of 'Main'
  long  ADStack[35]                                     ' Stack area
CON
    _clkmode = xtal1 + pll16x                           ' Not really necessary but good for consistany
    _xinfreq = 5_000_000                                ' This works out to a cycle time of 2mSec
                                                        ' with clock pulses of ~81 uSec yeilding an operational frequency
                                                        ' of about 12.3kHz. This is below the National SemiConductor rated min of 800kHz
                                                        ' but it seems to work fine for sampling pot positions. The occasional 00 shows up
                                                        ' but those can be filtered out
    Delay = 500                                         ' Pin settling & clock delay time (DO NOT GO BELOW 381)
         
PUB Start(CL,DI,DO,CS) :Success
  ' CL = Clock         
  ' DI = Data In       
  ' DO = Data Out      
  ' CS = Chip Select 
  Success := cognew(Main(CL,DI,DO,CS), @ADStack)  

PUB Main(CL,DI,DO,CS)
  dira[CL] ~~                   ' Clock output to AD
  dira[DI] ~~                   ' Data OUT from Prop to AD(in)
  dira[DO] ~                    ' Data IN from AD(out) to Prop
  dira[CS] ~~                   ' Chip select - active low 
                                ' Wake Up chip with some 0's here.
  outa[CS] := 0                 ' CS on to non-active state
  outa[CL] := 0                 ' Make sure clock is low
  outa[DI] := 0                 ' Set DI to AD low
                                '
  waitcnt((20_000 + cnt))       ' Wait to settle I/O 
  outa[CS] := 1                 ' CS HIGH to non-active state
  outa[CL] := 0                 ' Make sure clock is low
  outa[DI] := 0                 ' Set DI to AD low
  waitcnt((20_000 + cnt))       ' Wait for outputs to settle
  Chan := 0                     ' Set Channel to 0 (chan 1 will be first b/c of increment location)
                                ' On very first rotation chan will not be read  
  Repeat                         ' Start read loop on 8 chan AD converter 
    Chan ++                      ' Rotate Channel assignments
    if Chan == 8                 ' If Chan gets to 8 then reset it to 0
      Chan :=0                   '    count will be 0 - 7
    Outa[CL] :=0                 ' Clock in LOW position
    Outa[CS] :=0                 ' Chip Select low   
    Outa[DI] :=0                 ' Set Data IN to 0 - ADC really does not care but...
    waitcnt((Delay + cnt))       ' Wait t_setup  
                          
    ClockAD(CL)                  ' Clock 1     up -> Down
    ClockAD(CL)                  ' Clock 2     up -> Down
                                              
    Outa[DI] := ((Chan &  %00000100) >> 2) ' get Third bit then rotate chan down and put it on DI (bit 1)    
    ClockAD(CL)                  ' Clock 3     up -> Down                                                    
    Outa[DI] := ((Chan &  %00000010) >> 1) ' ' get second bit then rotate chan down and put it on DI (bit 2))
    ClockAD(CL)                  ' Clock 4     up -> Down                                                                                                                                             
    Outa[DI] := (Chan &  %00000001) ' Get First bit of chan and put it on DI (bit 3) 
                                 ' Clock is LOW here
    AdTemp := %10000000          ' Set AdTemp or the bit adder to 1 in MSB position
    AData[Chan] := 0                ' Set data byte to all zeros   
    Repeat bitno from 0 to 7      ' Go around 8 times once per bit     
      if ina[DO] == 1             ' If the input is a 1 add ADTemp to AD[chan] if 0 then pass to next bit  
        AData[Chan] := AdTemp + AData[Chan] ' AD[chan] the bit adder to the data byte
      AdTemp := AdTemp >> 1       ' Rotate the bit adder to the next lower bit position
      ClockAD(CL)                  ' Clock up -> Down , Clock 5 - 13 the AD to move to the next bit 

    Repeat bitno from 1 to 3      ' Use bitno as a holder for this count
      ClockAD(CL)                 ' Clock 14 - 16 per timing diagram this is the sample time
                                  ' Shut down the ADC
    Outa[CS] := 1                 ' Chip Select back to High  
    'waitcnt((20_000 + cnt))       ' Wait for ADC to settle

    ADQual[Chan] := (AData[Chan] + ADQual[Chan])/2 'Average data with last sample

PUB ClockAD(CL)
      ' ----------------------------- Clock AD ------------------
      waitcnt((delay + cnt))        ' Wait t_setup = 240 nS  
      OUTA[CL] := 1                  ' Clock up            
      waitcnt((delay + cnt))        ' Wait t_setup = 240 nS
      OUTA[CL] := 0                  ' Clock Down      
      ' ----------------------------- Clock AD ------------------

PUB GetAD(ChanReq) : AdDataOut                          ' Call this module with 0-7 in ChanReq to get last sample
  case ChanReq
    1:
        AdDataOut := (100 * ADQual[ChanReq])/255        ' This turns the Qualified value into 0 to 100%
    2:
        AdDataOut := (100 * ADQual[ChanReq])/255
    3:
        AdDataOut := (100 * ADQual[ChanReq])/255
    4:
        AdDataOut := (100 * ADQual[ChanReq])/255
    5:
        AdDataOut := (100 * ADQual[ChanReq])/255
    6:
        AdDataOut := (100 * ADQual[ChanReq])/255
    7:                                                   ' This adjusts the output to compensate for pot travel and limits.
        AdDataOut :=(((((100 * ADQual[ChanReq])/255) - 36) * (100/24)) <# 100 ) #> 0

 