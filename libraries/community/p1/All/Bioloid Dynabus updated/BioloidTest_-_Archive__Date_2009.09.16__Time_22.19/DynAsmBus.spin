
{{
  sept 09 HJ Kiela, modified wrt timeout calculation

 Dynamixel 1/2 Duplex Bus Object
   
  File....... DynAsmBus
  Purpose.... Propeller driven AX-12 1/2 duplex bus driver
  Author..... Mike Gebhard,  Modified by Richard Ibbotson
  Started.... 1/1/2008
  Updated.... 3/17/2008
  Version....                                                                         

 The Dynamixel Bus Object is a 1/2 duplex serial bus driver for the
 Dynamixel AX-12 network ready servo.

 Credits:
 Driver by Mike Gebhard modified for:
 1) More time at end of byte for processing, by not reading stop bit
 2) Addition of read timeout
 3) Test code for CM-uOLED based on code by Inaki
 
}}
 

CON
 

VAR
  long  cogon, cog
  long  _mode                   'send/recieve mode
  long  _timeout                'receive timeout
  long  _axPin                  'network connection
  long  _bitTicks               'bit ticks
  long  _bufferPointer          'buffer pointer
  long  _packetLength           'buffer length
  byte  _axBuffer[64]           'command/response buffer


  
PUB start(axpin, baudrate) : okay

  _mode := 0                                          ''Transmit mode
  _axPin := axpin                                     ''AX-12 network (pin)
  SetTimeOut(1)                                       ''1ms timeout
  _bitTicks := clkfreq / baudrate                     ''Set baud
  _bufferPointer := @_axBuffer                        ''Put buffer addr into memory

  _packetLength := 0                                  ''Init packet length
  
  okay := cogon := (cog := cognew(@entry,@_mode)) > 0   ''cognew(spinMethod(parmList), stackPointer
    


PUB GetAxBuffer(index) : value
  value := _axBuffer[index]

  
PUB SetAxBuffer(index, value)
  _axBuffer[index] := value

  
' To be implemented in assembly
PUB SetTimeOut(Timems)              'Set new timeout in ms
  _TimeOut := Timems*(clkfreq/12/1000) 'Timems*1000*(clkfreq/12 * 1000000) ''ms timeout

  
PUB ExecuteCommand(length, responseMode)
  _packetLength := length
  _mode :=  responseMode
  


{ **** Utilites *****}  
PUB GetMode : value
  value := _mode

  
PUB GetTimeout : value
  value := _TimeOut

PUB GetResponsePacketLength : value
  value := _packetLength


PUB PurgeAxBuffer
  Bytefill(@_axBuffer, 0, 63)

 
PUB GetAxPin : value
  value := _axPin


PUB GetBitTicks : value
  value :=  _bitTicks


PUB GetCurrentBufferPointer : value
  value :=  _bufferPointer


PUB GetBufferPointer : value
  value := @_axBuffer


DAT

'*********************************************
'* Assembly language Bus Driver              *
'*********************************************
                        org     0 
entry                   mov     t1,par
             
                        'Create mode mask 
                        mov     modemask,#3           '0011
                        
                        'Get timeout
                        add     t1,#4                 'add 1 long
                        rdlong  timeout,t1        
                        'Get Pin
                        add     t1,#4                 'add 1 long
                        rdlong  t2,t1                 'read pin # from memory

                        'Create pin mask
                        mov     axmask,#1             'setup axmask   
                        shl     axmask,t2             'move the bit left t2 times (_axPin)

                        'get bit ticks
                        add     t1,#4                 'add a long to the pointer value
                        rdlong  bitticks,t1           'read bitticks from HUB memory

                        'get buffer pointer
                        add     t1,#4                 'add a long to the pointer value
                        rdlong  buff,t1               'get buffer pointer from HUB memory
                        mov     head, buff            'Remember buffer start address

                        'initialize receive count.
                        ' These guys are used to sync
                        ' the receiver to the Dynamixel
                        ' response packet
                        and     rxcnt,#$0             'init rxcnt to 0
                        add     rxcnt,bitticks        'get bitticks
                        shr     rxcnt,#3              'divide by 8
                                                
modewait                mov     t1,par                'get cog parameter pointer (@cog)
                        'get mode from HUB memory
                        ' mode 0 = Wait
                        ' mode 1 = Send/Receive
                        ' mode 2 = Send only
                        rdlong  mode,t1               'read mode from HUB memory
                        and     mode, modemask  wz, nr
              if_z      jmp     #modewait
                        'get packet length
                        add     t1,#5 << 2                'add #4 << 2 = #16 (_packetLen)
                        rdlong  packetLen,t1          'read HUB memory
                        
                        'Prime counters
                        mov     len,#4                
                        mov     rxcnt2,#2
                                    
'-----------------------[ Transmit ]------------------------------------------------------------                         
transmit                or      outa,axmask           'high
                        or      dira,axmask           'output mode 
                        
 
:incBuffPtr             rdbyte  axData,buff           'read a byte from the buffer
                        add     buff,#1               'increment buffer index

                       'ready byte to transmit 
                        or      axData,#$100          'add stop bit 
                        shl     axData,#1             'add start bit
                        mov     axbits,#10            '10 total bits to shift
                        mov     axcnt,cnt             'init axcnt with current count

                        'output bit
:bit                    test    axData,#1       wc    'AND #1 and set C flag for odd parity
                        muxc    outa,axmask           'send high or low depending on C flag
                        add     axcnt,bitticks        'ready next count
                        
                        'check if the bit transmit period is done
:wait                   mov     t1,axcnt              'move timer value to t1
                        sub     t1,cnt                'remove current count
                        cmps    t1,#0           wc    'what's left? is it less than 0
        if_nc           jmp     #:wait                'if so wait
        
                        'another bit to transmit?
                        shr     axdata,#1             'shift right one time
                        djnz    axbits,#:bit          'decrement value and jump to address if not 0.
                        
                        djnz    packetLen,#:incBuffPtr 'byte done, transmit next byte

                        'sub     buff,t3                 'reset buffer pointer for receiver
                        mov     buff,head
                        and     packetLen,#0            'reset packetLen to zero

                        test    mode,#1         wz      'set C to LSB bit(0) after rotate
        if_z           jmp     #resetMode              'if C is 1 then contiune to receive
                                                        'if C is not set, jump to reset mode.

'-----------------------[ Receive ]------------------------------------------------------------
                        'Get ready to recieve        
                        'high input mode
                        'Get timeout  dynamically
                        mov     t1, par            'hk ' timeout    refresh time out
                        add     t1,#4              'hk ' add 1 long
                        rdlong  timeout,t1        
                        
                        or      outa,axmask             'high
                        xor     dira,axmask             'input
                        
rxstart                 mov     timecount, timeout         ' setup timeout
                          
                        'wait for start bit
waitstart               test    axmask,ina      wc      'Wait for start bit on timeout
        if_nc           jmp     #getbyte                ' loop is 12 clocks lomg
       '                 mov     t1, par            'hk   ' timeout
       '                 wrlong  timecount ,t1       'hk       ' set error mode
                        djnz    timecount, #waitstart
              
' Here if timeout waiting for receive
                        mov     t1, par               ' timeout
                        wrlong  error ,t1              ' set error mode
                        add     t1, #5 << 2
                        wrlong  zero ,t1             ' clear pktlen
                        jmp     #modewait
                        
                       'ready to receive byte  start + 8 + stop
getbyte                 mov     axbits,#8               'Stick the value 8 into axbits
                        mov     axcnt,rxcnt             'init receive counter                                                      
                        add     axcnt,cnt               'add the current count to axcnt 10 + cnt
:bit                    add     axcnt,bitticks          '10+cnt+80

                        'check if bit receive period is done
:wait                   mov     t1,axcnt                'axcnt -> t1
                        sub     t1,cnt                  'sub axcnt from current count
                        cmps    t1,#0           wc      'set C flag if t1 <= #0 (signed)
        if_nc           jmp     #:wait                  'if C is clear jump to #wait

                        'get bit
                        test    axmask,ina      wc      'C is set if odd parity after the AND
                        rcr     axdata,#1               'rotate carry right (MSB) into axdata 1 time
                        djnz    axbits,#:bit            'Decr axbits and jump to :bit if not 0
                        
                        'justify and trim received byte
                        shr     axdata,#32-8            'shift right (32 - 8) = 24         
                        and     axdata,#$FF             'trim

                        'save receive byte in buffer
                        'increment buffer index
:saveByte               wrbyte  axdata,buff             'write to HUB memory buffer
                        add     buff,#1                 'increment buffer pointer

                        'byte[4] is the remaining packet length
                        ' stick the value of byte[4] in len and 
                        ' loop to the end of the response packet
                        djnz    len,#rxstart             'dec and jump (started at 4)
                        add     len,axdata       wz      'get length byte[4] + stick it len
                        djnz    rxcnt2,#rxstart          'counter 2

                        'Write mode to HUB memory 
resetMode               mov     t1,par                  'cog parameter pointer
                        and     mode,#0                 'clear mode
                        wrlong  mode,t1                 'write to HUB address

                        'Calculate response packet length
                        mov     packetLen,buff          'get buffer ending address
                        sub     packetLen, head         'subtract buffer starting address

                        add     t1,#4 << 2              'Add 16 and point to HUB memory
                        wrlong  packetLen,t1            'write packet lenght to HUB memory

                        'reset buffer pointer
                        mov     buff, head
 
                        jmp     #modewait                   'Do it again

'

'error                   long    $00000080       ' error mode
error                   long    $00008880       ' error mode
zero                    long    0
'
' Uninitialized data
'
t1                      res     1
t2                      res     1
t3                      res     1
temp                    res     1

mode                    res     1
axmask                  res     1
bitticks                res     1
buff                    res     1
packetLen               res     1
axData                  res     1
axbits                  res     1
axcnt                   res     1
rxcnt                   res     1
modemask                res     1
len                     res     1
head                    res     1
rxcnt2                  res     1
timeout                 res     1
timecount               res     1
                        fit