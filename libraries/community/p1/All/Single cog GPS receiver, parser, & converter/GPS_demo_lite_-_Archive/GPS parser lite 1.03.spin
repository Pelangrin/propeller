{{┌──────────────────────────────────────────┐  1.03 - latitude and longitude now receive up to five decimal places                          
  │ GPS receiver and string parser - lite    │         Message discriminator now checks the three bytes of the message type                  
  │ Author: Chris Gadd                       │         datePtr restructures a local string - prevents gibberish if no RMC message is received
  │ Copyright (c) 2019 Chris Gadd            │         added method to return number of satellites in view                                   
  │ See end of file for terms of use.        │                                                                                               
  └──────────────────────────────────────────┘
   Reads messages from a GPS receiver, parses the message, and creates text strings from the fields

  To use:
    Start with IO pin and baud
    setLock before reading - this ensures that the values are all from the same reading
    checkStatus to determine if receiver is "A" ok, or "V" navigation receiver warning
    read datePtr, timePtr, latPtr, lonPtr, altPtr, crsPtr, and spdPtr as ASCII strings   (pst.str(gps.timePtr))
    unLock after reading to allow the pasm routine to update the strings
    
                                   ┌────────────────────┐                                           
                                   │ ┌────────────────┐ │                                           
                                   │ │                │ │                                           
                                   │ │    CIROCOMM    │ │                                           
             Prop in    TTL_Tx Yel─┤ │                │ │                                           
             not used   TTL_Rx Blu─┤ │        ┌┐      │ │                                           
             3v3        Vcc    Red─┤ │        └┘      │ │                                           
                        Gnd    Blk─┤ │                │ │                                           
             not used  UART Tx Grn─┤ │           595K │ │                                           
             not used  UART Rx Wht─┤ └────────────────┘ │                                           
                                   └────────────────────┘                                           
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
GGA Global Positioning System Fix Data. Time, Position and fix related data for a GPS receiver
                                               
         1          2         3 4          5 6 7  8   9   10 11   12 13  14   15                                                                   
         |          |         | |          | | |  |   |    | |     | |   |    |                                                                    
  $--GGA,hhmmss.sss,llll.llll,a,yyyyy.yyyy,a,x,xx,x.x,xx.x,M,xxx.x,M,x.x,xxxx*hh                                                                   
                                                                                                                                                   
  1) Time (UTC)                                                                                                                                    
  2) Latitude                                                                                                                                      
  3) N or S (North or South)                                                                                                                       
  4) Longitude                                                                                                                                     
  5) E or W (East or West)                                                                                                                         
  6) GPS Quality Indicator,                                                                                                                        
     0 - fix not available,                                                                                                                        
     1 - GPS fix,                                                                                                                                  
     2 - Differential GPS fix                                                                                                                      
  7) Number of satellites in view, 00 - 12                                                                                                         
  8) Horizontal Dilution of precision                                                                                                              
  9) Antenna Altitude above/below mean-sea-level (geoid)                                                                                           
  10) Units of antenna altitude, meters                                                                                                            
  11) Geoidal separation, the difference between the WGS-84 earth ellipsoid and mean-sea-level (geoid), "-" means mean-sea-level below ellipsoid   
  12) Units of geoidal separation, meters                                                                                                          
  13) Age of differential GPS data, time in seconds since last SC104 type 1 or 9 update, null field when DGPS is not used                          
  14) Differential reference station ID, 0000-1023                                                                                                 
  15) Checksum                                                                                                                                     

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
RMC Recommended Minimum Navigation Information

         1          2 3         4 5          6 7    8      9     10    11 12 13                  
         |          | |         | |          | |    |      |      |     | |  |                   
  $--RMC,hhmmss.sss,A,llll.llll,a,yyyyy.yyyy,a,x.xx,xxx.xx,xxxxxx,xxx.x,e,a*hh                   
                                                                                                 
  1) Time (UTC)                                                                                  
  2) Status, A = ok, V = Navigation receiver warning            
  3) Latitude                                                                                    
  4) N or S                                                                                      
  5) Longitude                                                                                   
  6) E or W                                                                                      
  7) Speed over ground, knots                                                                    
  8) Track made good, degrees true                                                               
  9) Date, ddmmyy                                                                                
  10) Magnetic Variation, degrees                                                                
  11) E or W                                                                                     
  12) Mode (A - Autonomous / D - Differential / E - Estimated / N - Data not valid)              
  13) Checksum                                                                                   

}}                                                                                                                                                
CON
  RMC           = 1
  GGA           = 2

VAR
  byte  status
  byte  lockID
  byte  cog

DAT                                                           '' shared registers, only updated after verifying checksum 
time_str                byte      "12:34:56       ",0         ' all strings reserve 16 bytes
date_str                byte      "12/34/56       ",0       
lat_str                 byte      "89°59.9999 N   ",0
lon_str                 byte      "179°59.9999 W  ",0  
alt_str                 byte      "6553.5M        ",0        
crs_str                 byte      "359.9°         ",0         
spd_str                 byte      "123.4 kts      ",0
sat_str                 byte      "0              ",0

PUB Null                                                '' Not a top level object

PUB Start(GPS_pin,bitrate) | tempPtrs, sharedPtrs, lockNbr, statusPtr, okay
  bitrate := clkfreq / bitrate
  |< GPS_pin
  tempPtrs := @temp_time_str
  sharedPtrs := @time_str
  lockNbr := lockID := locknew
  statusPtr := @status
  okay := cog := cognew(@entry, @GPS_pin) + 1
  waitcnt(clkfreq / 10 + cnt)
  return okay

PUB stop
  if cog
    cogstop(cog~ - 1)
    lockret(lockID)

PUB getStatus
  if status
    return status
  return "V"

PUB setLock | timeout, locked                           '' Set lock to prevent pasm routine from overwriting shared data
  timeout := clkfreq / 1000 + cnt                       ' pasm requires ~70us to update shared data
  repeat until (locked := (lockset(lockID) == 0)) or cnt - timeout > 0
  return locked                                         ' returns true if successful / false if already locked

PUB unLock                                              '' Unlock to allow pasm routine to update shared data
  lockclr(lockID)
      
PUB timePtr                                             '' returns the address of string containing the time "hh:mm:ss",0
  return @time_str

PUB datePtr | strPtr                                    '' returns the address of string containing the date as "20yy/mm/dd",0
  strPtr := string("20??/??/??")                        
  bytemove(strPtr + 2,@date_str + 6,2)
  bytemove(strPtr + 5,@date_str + 3,2)
  bytemove(strPtr + 8,@date_str + 0,2)
' return @date_str                                      ' @date_str contains date as dd/mm/yy
  return strPtr                                         ' strPtr contains date as 20yy,mm,dd
  
PUB latPtr                                              '' returns the address of string containing the latitude "89°59.9999 N",0
  return @lat_str

PUB lonPtr                                              '' returns the address of string containing the longitude "179°59.9999 W",0  
  return @lon_str
  
PUB altPtr                                              '' returns the address of string containing the altitude "6553.5M",0           
  return @alt_str
  
PUB crsPtr                                              '' returns the address of string containing the course "179.0°",0              
  return @crs_str

PUB spdPtr                                              '' returns the address of string containing the speed "100.00 kts",0           
  return @spd_str

PUB satsPtr
  return @sat_str
  
DAT                                                                             '' temporary registers for storing data as it is received
temp_time_str           byte      "00:00:00       ",0
temp_date_str           byte      "00/00/00       ",0
temp_lat_str            byte      "00°00.0000 N   ",0
temp_lon_str            byte      "000°00.0000 W  ",0
temp_alt_str            byte      "0000.0M        ",0
temp_crs_str            byte      "000.0°         ",0
temp_spd_str            byte      "000.0 kts      ",0
temp_sat_val            byte      "0              ",0

DAT                     org
entry
                        mov       rd_ptr,par
                        rdlong    rx_mask,rd_ptr
                        add       rd_ptr,#4                    
                        rdlong    bit_delay,rd_ptr
                        add       rd_ptr,#4
                        rdlong    cog_ptr,rd_ptr                                ' read address of temp_ptrs
                        movd      :load_string_loop,#time_address
                        mov       loop_counter,#8                               ' eight temporary strings
:load_string_loop       mov       0-0,cog_ptr
                        add       :load_string_loop,d1
                        add       cog_ptr,#16                                   ' each string reserves 16 bytes
                        djnz      loop_counter,#:load_string_loop
                        add       rd_ptr,#4
                        rdlong    shared_address,rd_ptr                         ' read address of 1st shared_register
                        add       rd_ptr,#4
                        rdbyte    lock,rd_ptr
                        add       rd_ptr,#4
                        rdword    status_address,rd_ptr
'---------------------------------------------------------------------------------------------------------------------------
Wait_for_start                                                                  
                        call      #Receive_byte                                
                        cmp       UART_byte,#"$"              wz
          if_ne         jmp       #Wait_for_start
                        mov       checksum,#0
                        mov       Message,#0
                        mov       BCD_value,#0
                        movs      parse_byte,#parse_header
Main_loop                                                                                                                                               
                        call      #Receive_byte
                        cmp       UART_byte,#"*"              wz
          if_e          jmp       #End                                      
                        xor       checksum,UART_byte
                        jmp       parse_byte
End
                        call      #Receive_byte                                 ' compare the calculated checksum to the
                        call      #ASCII_to_BCD                                 '  checksum in the message
                        call      #Receive_byte                                
                        call      #ASCII_to_BCD                                
                        and       BCD_value,#$FF
                        cmp       BCD_value,checksum          wz
          if_ne         jmp       #Clear_temps
Copy_temps_to_shared
:set_lock
                        lockset   lock                        wc
          if_c          jmp       #:set_lock
                        mov       rd_ptr,time_address                          
                        mov       wr_ptr,shared_address                        
                        mov       loop_counter,#7 * 4 + 1                       ' copy 7 strings of 4 longs containing 16 characters + 1 long 
:copy_loop
                        rdlong    temp,rd_ptr
                        add       rd_ptr,#4
                        wrlong    temp,wr_ptr
                        add       wr_ptr,#4
                        djnz      loop_counter,#:copy_loop
                        lockclr   lock
                        jmp       #Wait_for_start
Clear_temps                                                                     ' clear temporary registers in case of incomplete message
                        mov       wr_ptr,time_address                          
                        mov       loop_counter,#7 * 4                          
                        mov       temp,#0
:clear_loop
                        wrlong    temp,wr_ptr
                        add       wr_ptr,#4
                        djnz      loop_counter,#:clear_loop
                        jmp       #Wait_for_start
'......................................................................................................................
parse_byte              jmp       #0-0
'......................................................................................................................
parse_header
                        movs      parse_byte,#:parse_header_loop
                        movd      :parse_header_byte,#msg_str
                        mov       byte_counter,#5
:parse_header_loop
                        cmp       UART_byte,#","              wz                
          if_e          jmp       #:End
                        tjz       byte_counter,#Main_loop
:parse_header_byte      mov       0-0,UART_byte
                        add       :parse_header_byte,d1
                        sub       byte_counter,#1
                        jmp       #Main_loop
:End
                        cmp       msg_str + 2,#"G"            wz
          if_e          cmp       msg_str + 3,#"G"            wz
          if_e          cmp       msg_str + 4,#"A"            wz
          if_e          mov       Message,#GGA
                        cmp       msg_str + 2,#"R"            wz
          if_e          cmp       msg_str + 3,#"M"            wz
          if_e          cmp       msg_str + 4,#"C"            wz
          if_e          mov       Message,#RMC
                        tjz       Message,#Wait_for_start                       ' Disregard message if not RMC or GGA
                        movs      parse_byte,#parse_time
                        jmp       #Main_loop
'......................................................................................................................
parse_time                                                                      ' "17:40:46",0 - received as 174046.022
                        movs      parse_byte,#:parse_time_loop
                        mov       wr_ptr,time_address              
                        mov       byte_counter,#8
:parse_time_loop
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        tjz       byte_counter,#Main_loop
                        call      #String_builder
                        cmp       byte_counter,#6             wz
          if_ne         cmp       byte_counter,#3             wz
          if_e          mov       UART_byte,#":"
          if_e          call      #String_builder
                        jmp       #Main_loop          
:End
                        cmp       Message,#RMC                wz
          if_e          movs      parse_byte,#parse_status
          if_ne         movs      parse_byte,#parse_lat
                        jmp       #Main_loop
'......................................................................................................................
parse_status
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        wrbyte    UART_byte,status_address
                        jmp       #Main_loop
:End
                        movs      parse_byte,#parse_lat
                        jmp       #Main_loop
'......................................................................................................................
parse_lat                                                                       ' "12°34.5678 N",0 - received as 1234.5678,N
                        movs      parse_byte,#:parse_lat_loop                   ' always 2 degree digits and 2 minute digits
                        mov       wr_ptr,lat_address                            ' varying number of fractional digits       
                        mov       byte_counter,#10
:parse_lat_loop
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        tjz       byte_counter,#Main_loop
                        call      #String_builder
                        cmp       byte_counter,#8             wz
          if_e          mov       UART_byte,#"°"
          if_e          call      #String_builder
                        jmp       #Main_loop
:End
                        mov       UART_byte,#" "
                        call      #String_builder
                        movs      parse_byte,#parse_ns
                        jmp       #Main_loop
parse_ns
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        call      #String_builder
                        jmp       #Main_loop
:End
                        mov       UART_byte,#0
                        call      #String_builder
                        movs      parse_byte,#parse_lon
                        jmp       #Main_loop
'......................................................................................................................
parse_lon                                                                       ' "123°45.6789 W",0 - received as 12345.6789,W
                        movs      parse_byte,#:parse_lon_loop
                        mov       wr_ptr,lon_address
                        mov       byte_counter,#11
:parse_lon_loop
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        tjz       byte_counter,#Main_loop
                        call      #String_builder
                        cmp       byte_counter,#8             wz
          if_e          mov       UART_byte,#"°"
          if_e          call      #String_builder
                        jmp       #Main_loop
:End
                        mov       UART_byte,#" "
                        call      #String_builder
                        movs      parse_byte,#parse_ew
                        jmp       #Main_loop
parse_ew
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        call      #String_builder
                        cmp       UART_byte,#"W"              wz
                        jmp       #Main_loop
:End
                        mov       UART_byte,#0
                        call      #String_builder
                        cmp       Message,#RMC                wz
          if_e          movs      parse_byte,#parse_speed
          if_ne         movs      parse_byte,#parse_quality
                        jmp       #Main_loop
'......................................................................................................................
parse_speed                                                                     ' "123.45 kts",0 - received as 123.45
                        movs      parse_byte,#:parse_speed_loop                 ' "2 kts",0 - received as 2
                        mov       wr_ptr,spd_address
                        mov       byte_counter,#6
:parse_speed_loop
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        tjz       byte_counter,#Main_loop
                        call      #String_builder
                        jmp       #Main_loop
:End
                        mov       UART_byte,#" "
                        call      #String_builder
                        mov       UART_byte,#"k"
                        call      #String_builder
                        mov       UART_byte,#"t"
                        call      #String_builder
                        mov       UART_byte,#"s"
                        call      #String_builder
                        mov       UART_byte,#0
                        call      #String_builder
                        movs      parse_byte,#parse_track
                        jmp       #Main_loop
'......................................................................................................................
parse_track                                                                     ' "312.12°",0 - received as 312.12
                        movs      parse_byte,#:parse_track_loop                 ' "73°",0 - received as 73 
                        mov       wr_ptr,crs_address
                        mov       byte_counter,#6
:parse_track_loop
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        tjz       byte_counter,#Main_loop
                        call      #String_builder
                        jmp       #Main_loop
:End
                        mov       UART_byte,#"°"
                        call      #String_builder
                        mov       UART_byte,#0
                        call      #String_builder
                        movs      parse_byte,#parse_date
                        jmp       #Main_loop
'......................................................................................................................
parse_date                                                                      ' "05/02/13",0 received as 050213
                        movs      parse_byte,#:parse_date_loop
                        mov       wr_ptr,date_address
                        mov       byte_counter,#8
:parse_date_loop        
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:end
                        tjz       byte_counter,#Main_loop
                        call      #String_builder
                        cmp       byte_counter,#6             wz
          if_ne         cmp       byte_counter,#3             wz
          if_e          mov       UART_byte,#"/"
          if_e          call      #String_builder
                        jmp       #Main_loop
:End
                        mov       UART_byte,#0
                        call      #String_builder
                        movs      parse_byte,#parse_magvar
                        jmp       #Main_loop
'......................................................................................................................
parse_magvar
'                       cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
'                       jmp       #Main_loop
:End
'                       movs      parse_byte,#parse_mag_ew
'                       jmp       #Main_loop
parse_mag_ew
'                       cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
'                       jmp       #Main_loop
:End
                        jmp       #Main_loop                                    ' End of GPRMC message
'......................................................................................................................
parse_quality                                                                   ' GPGGA message branch
                        cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
          if_ne         jmp       #Main_loop
:End
                        movs      parse_byte,#parse_satellites
                        jmp       #Main_loop
'......................................................................................................................
parse_satellites
                        movs      parse_byte,#:parse_satellites_loop
                        mov       wr_ptr,sat_address
                        mov       byte_counter,#3
:parse_satellites_loop
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        tjz       byte_counter,#Main_loop
                        call      #String_builder
                        jmp       #Main_loop
:End
                        movs      parse_byte,#parse_dilution
                        jmp       #Main_loop
'......................................................................................................................
parse_dilution
                        cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
          if_ne         jmp       #Main_loop
:End
                        movs      parse_byte,#parse_altitude
                        jmp       #Main_loop
'......................................................................................................................
parse_altitude                                                                  ' "6553.5M",0 - received as 6553.5,M
                        movs      parse_byte,#:parse_altitude_loop              ' "-0.6M",0 - received as -0.6,M
                        mov       wr_ptr,alt_address
                        mov       byte_counter,#7
:parse_altitude_loop
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        tjz       byte_counter,#Main_loop
                        call      #String_builder
                        jmp       #Main_loop
:End
                        movs      parse_byte,#parse_units
                        jmp       #Main_loop
parse_units
                        cmp       UART_byte,#","              wz
          if_e          jmp       #:End
                        call      #String_builder
                        jmp       #Main_loop
:End
                        mov       UART_byte,#0
                        call      #String_builder
                        rdbyte    UART_byte,alt_address
                        movs      parse_byte,#parse_geo_seperation
                        jmp       #Main_loop
'......................................................................................................................
parse_geo_seperation
'                       cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
'                       jmp       #Main_loop
:End
'                       movs      parse_byte,#parse_geo_units
'                       jmp       #Main_loop
'......................................................................................................................
parse_geo_units
'                       cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
'                       jmp       #Main_loop
:End
'                       movs      parse_byte,#parse_age
'                       jmp       #Main_loop
'......................................................................................................................
parse_age
'                       cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
'                       jmp       #Main_loop
:End
'                       movs      parse_byte,#parse_ID
'                       jmp       #Main_loop
'......................................................................................................................
parse_ID
'                       cmp       UART_byte,#","              wz
'         if_e          jmp       #:End
'                       jmp       #Main_loop
:End
                        jmp       #Main_loop                                    ' End of GPGGA message
'==========================================================================================================================================
String_builder
                        wrbyte    UART_byte,wr_ptr
                        add       wr_ptr,#1
                        sub       byte_counter,#1
String_builder_ret      ret
'------------------------------------------------------------------------------------------------------------------------------------------
Receive_byte
                        mov       Bit_counter,#8
                        mov       Delay_counter,Bit_delay                      
                        shr       Delay_counter,#1                             
                        add       Delay_counter,Bit_delay                      
                        waitpne   Rx_mask,Rx_mask
                        add       Delay_counter,cnt                            
:loop
                        waitcnt   Delay_counter,Bit_delay
                        test      Rx_mask,ina                 wc               
                        rcr       UART_byte,#1                                 
                        djnz      Bit_counter,#:Loop                           
                        shr       UART_byte,#32 - 8                            
                        waitcnt   Delay_counter,Bit_delay                      
Receive_byte_ret        ret
'------------------------------------------------------------------------------------------------------------------------------------------
ASCII_to_BCD                                                                    ' Convert up to eight characters into binary-coded decimal
                        mov       temp,UART_byte
                        cmp       temp,#"A"                   wc
          if_ae         sub       temp,#"0" + 7
          if_b          sub       temp,#"0"
                        shl       BCD_value,#4
                        or        BCD_value,temp
ASCII_to_BCD_ret        ret
'==========================================================================================================================================
d1                      long      |< 9

time_address            res       1
date_address            res       1
lat_address             res       1
lon_address             res       1
alt_address             res       1
crs_address             res       1
spd_address             res       1
sat_address             res       1
shared_address          res       1
lock                    res       1
status_address          res       1

rd_ptr                  res       1
wr_ptr                  res       1
cog_ptr                 res       1

bit_delay               res       1
Delay_counter           res       1
Nibble_counter          res       1
Byte_counter            res       1
Loop_counter            res       1
Bit_counter             res       1
Rx_mask                 res       1
UART_byte               res       1
checksum                res       1
Message                 res       1
msg_str                 res       1

BCD_value               res       1
temp                    res       1

                        fit       496
DAT                     
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