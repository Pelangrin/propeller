{{
─────────────────────────────────────────────────
File: RN-XV Wifly FTP Client V01.spin
Version: 01.0
Copyright (c) 2012 Ben.Thacker.Enterprises
See end of file for terms of use.

Author: Ben Thacker  
─────────────────────────────────────────────────
}}

{    
  Theory of operation:

  The Propeller chip interfaces with a RN-XV Wifly via the serial port.
  The RN-XV Wifly provides Wi-Fi connectivity using 802.11 b/g standards.
  In this simple configuration that I am using, the RN-XV hardware only
  requires four connections (Pwr, Tx, Rx and Gnd) to create a wireless
  data connection.

  If the RN-XV Wifly does not connect to a network the propeller will
  execute a setup procedure and request your password and ssid name
  during the setup of the RN-XV Wifly.

  Once the RN-XV Wifly has joined your wireless network it will try and
  download 'ftp get' a text file called README.TXT from the Parallax FTP
  site containing the source tree for the Propeller C3 at
  ftp.propeller-chip.com in the /PropC3/Docs directory. A lookup is used
  to perform a DNS query on the hostname in case the location to the
  resource has changed in order to get the correct URL (or is it URI?).

  The RN-XV WiFly module acts as a transport and passes the file over it's
  uart interface as the file is being transferred. The Propeller simply
  outputs the data received to Term.

  This works quite fine for text however if you wish to 'ftp get' a
  binary file you will need to prevent displaying the data and provide
  some method of saving the Wifly_Buffer. 

  To upload a file (put) to a FTP site simply change the 'ftp get' to
  'ftp put', change the ftp address, directory, username and password.
  Of course you will need to upload to a FTP site that you have write
  privileges on. Data sent to the RN-XV Wifly uart will be written to
  the file.  

  See Wifly manual for info on the 'ftp put' command on how to close
  the file after a 'ftp put' command.
  
 ======================================================================
  Hardware:  
  
  RN-XV
  Wifly                 Propeller                Terminal/PC                 

  +3.3V
  Gnd
              10Ω
   rx   <──────────<  rn_xv_tx
   tx   >──────────>  rn_xv_rx
                        term_rx   <────────────<  prop_plug_tx
                        term_tx   >────────────>  prop_plug_rx
}

'----------------------------------------------------------------------
CON

  _clkmode         = xtal1 + pll16x              'Use crystal * 16
  _xinfreq         = 5_000_000                   '5MHz * 16 = 80 MHz

  term_rx           = 27                         'Serial Rx line
  term_tx           = 26                         'Serial tx line
  rn_xv_rx          =  9                         'RN-XV serial Rx line
  rn_xv_tx          =  8                         'RN-XV serial tx line

  LF                = 10                         'Line Feed
  CR                = 13                         'Carrage Return
  BUFFERSIZE        = 2048                       'Wifly_Buffer size
  TBUFFERSIZE       = 256                        'Temporary Wifly_Buffer size
  ERASE_BUFFER      = 1                          'Erase flag
  DONT_ERASE_BUFFER = 0                          'Do not erase flag
  
'----------------------------------------------------------------------
OBJ

  RN_XV: "Parallax Serial Terminal Extended"
  Term:  "Parallax Serial Terminal Extended"
  STR:   "Strings2"
  
'----------------------------------------------------------------------
VAR

  long ERR
  long FTP_ERR
  long FTP_TOUT
  long AOK
  long VER
  long CMD
  long OPEN
  long CLOSE
  long EXIT
  byte Tmp_Buffer[TBUFFERSIZE]
  byte Wifly_Buffer[BUFFERSIZE]
  long Wifly_Buffer_Index
  long Wifly_Stack[50]                           '200 bytes stack space for new cog                                        
  Byte SemID
  
'----------------------------------------------------------------------
PUB Main | start, end, len, pos, index, index1, Rx

  RN_XV.StartRxTx( rn_xv_rx, rn_xv_tx, 0, 9600 ) 'Initialize RN-XV serial io
  Term.StartRxTx( term_rx, term_tx, 0, 9600 )    'Initialize term serial io

  Term.Str(@AppHeader)                           'Print info header from string in DAT section.
  Term.Str(String("*** Starting ***",LF,CR))

  if (SemID := locknew) == -1
    Term.Str(String("*** Fatal Error, no locks available *** Propeller Stopped ***",LF,CR))
    repeat
    
  Wifly_Buffer_Index := 0                        'Start index used to read/write Wifly_Buffer at 0
  cognew(Wifly_to_Term,@Wifly_Stack)             'Send Wifly Tx to Term Rx

  Connect
  FTP_Get_Readme
  Clear_Wifly_Buffer
  
  repeat

'----------------------------------------------------------------------
PUB Connect | pos, spos, epos, aerr, bits6to4, bits3to0

  Enter_Command_Mode
  Clear_Wifly_Buffer
  
  RN_XV.Str(String("reboot"))
  RN_XV.Char(CR)
  test_response_with_timeout(ERASE_BUFFER,6000)

  Enter_Command_Mode
  Clear_Wifly_Buffer

  'Displays connection status in this HEX format: 8$$$
  'Check bits 6-4 and 3-0 in hex string returned.
  'see Wifly manual for bit status
  RN_XV.Str(String("show con"))
  RN_XV.Char(CR)
  test_response_with_timeout(DONT_ERASE_BUFFER,1000)
  if(VER => 0)
    pos := STR.strPos(@Wifly_Buffer, string("8"),0)
    bits6to4 := HexByteToLong(Wifly_Buffer[pos+2])
    bits3to0 := HexByteToLong(Wifly_Buffer[pos+3])
    if(bits6to4 == 0) Or ((bits6to4 <> 0) And (bits3to0 <> 0))
      setup
      reboot
  Clear_Wifly_Buffer

'----------------------------------------------------------------------
PUB setup | pos, index, index1

  Enter_Command_Mode
  Clear_Wifly_Buffer
  
  'factory RESET saves the settings to the config file, no need to "save"
  RN_XV.Str(String("factory RESET"))
  RN_XV.Char(CR)
  test_response_with_timeout(ERASE_BUFFER,6000)

  bytefill(@Tmp_Buffer, 0, TBUFFERSIZE)          'Clear Buffer to all 0's
  Term.Str(String("Type your phrase (password) and press Enter."))
  Term.StrIn(@Tmp_Buffer)
  RN_XV.Str(String("set wlan phrase "))
  RN_XV.Str(@Tmp_Buffer)
  RN_XV.Char(CR)
  delay_ms(1000)
  test_response_with_timeout(ERASE_BUFFER,2000)

  bytefill(@Tmp_Buffer, 0, TBUFFERSIZE)          'Clear Buffer to all 0's
  Term.Str(String("Type name of your ssid and press Enter."))
  Term.StrIn(@Tmp_Buffer)
  RN_XV.Str(String("set wlan ssid "))
  RN_XV.Str(@Tmp_Buffer)
  RN_XV.Char(CR)
  test_response_with_timeout(ERASE_BUFFER,2000)

  RN_XV.Str(String("join "))
  RN_XV.Str(@Tmp_Buffer)
  RN_XV.Char(CR)
  test_response_with_timeout(ERASE_BUFFER,2000)

  'Save settings in config file
  RN_XV.Str(String("save"))
  RN_XV.Char(CR)
  test_response_with_timeout(ERASE_BUFFER,2000)

'----------------------------------------------------------------------
PUB FTP_Get_Readme |  start_loc, end_loc, pos, index, index1 

  Enter_Command_Mode
  Clear_Wifly_Buffer

                          
  RN_XV.Str(String("lookup ftp.propeller-chip.com"))
  RN_XV.Char(CR)
  test_response_with_timeout(DONT_ERASE_BUFFER,2000)
  if(VER => 0)
    pos := STR.strPos(@Wifly_Buffer, string("="),0)
    index := 0
    repeat index1 from pos+1 to VER-1
      Tmp_Buffer[index++] := Wifly_Buffer[index1]

    RN_XV.Str(String("set ftp address "))
    RN_XV.Str(@Tmp_Buffer)
    RN_XV.Char(CR)
    test_response_with_timeout(ERASE_BUFFER,2000)
  else
    Clear_Wifly_Buffer

  RN_XV.Str(String("set ftp remote 21"))
  RN_XV.Char(CR)
  test_response_with_timeout(ERASE_BUFFER,2000)

  RN_XV.Str(String("set ftp dir /PropC3/Docs"))
  RN_XV.Char(CR)
  test_response_with_timeout(ERASE_BUFFER,2000)

  RN_XV.Str(String("set ftp user anonymous"))
  RN_XV.Char(CR)
  test_response_with_timeout(ERASE_BUFFER,2000)

  RN_XV.Str(String("set ftp pass password"))
  RN_XV.Char(CR)
  test_response_with_timeout(ERASE_BUFFER,2000)

  RN_XV.Str(String("ftp get README.TXT"))        'Watch the case of the letter's in file name
  RN_XV.Char(CR)

  repeat
    test_response_with_timeout(ERASE_BUFFER,1000)
    delay_ms(1000)
  until (CLOSE => 0) Or (FTP_ERR => 0) Or (FTP_TOUT => 0)

  Exit_CmdMode
  
  Clear_Wifly_Buffer

'----------------------------------------------------------------------
PUB Exit_CmdMode | pos

  RN_XV.Str(String("exit"))
  RN_XV.Char(CR)

'----------------------------------------------------------------------
PUB Enter_Command_Mode

  repeat
      RN_XV.Str(String(CR))
      RN_XV.Char(CR)
      test_response_with_timeout(ERASE_BUFFER,1000)
      if(VER => 0) Or (CMD => 0) Or (ERR => 0)
        quit
      else
        RN_XV.Str(String("$$$"))                   'Enter command mode
        test_response_with_timeout(ERASE_BUFFER,1000)
        if (CMD => 0) Or (ERR => 0)
          quit

'----------------------------------------------------------------------
PUB test_response_with_timeout(erase,ms) | tm

  tm := cnt
  repeat until (cnt - tm) / (clkfreq / 1000) > ms
    repeat until not lockset(SemID)                'Wait until we lock the resource
    ERR      := STR.strPos(@Wifly_Buffer, string("ERR:"),0)
    FTP_ERR  := STR.strPos(@Wifly_Buffer, string("FTP ERR"),0)
    FTP_TOUT := STR.strPos(@Wifly_Buffer, string("FTP timeout="),0)
    AOK      := STR.strPos(@Wifly_Buffer, string("AOK"),0)
    VER      := STR.strPos(@Wifly_Buffer, string("<2.32>"),0)
    CMD      := STR.strPos(@Wifly_Buffer, string("CMD"),0)
    OPEN     := STR.strPos(@Wifly_Buffer, string("*OPEN*"),0)
    CLOSE    := STR.strPos(@Wifly_Buffer, string("*CLOS*"),0)
    EXIT     := STR.strPos(@Wifly_Buffer, string("EXIT"),0)
    lockclr(SemID)                                 'Unlock the resource
    if     (ERR => 0)  Or (FTP_ERR => 0) Or (FTP_TOUT => 0)
      quit
    elseif (AOK => 0)  Or (VER => 0)     Or (CMD => 0)
      quit
    elseif (OPEN => 0) Or (CLOSE => 0)    Or (EXIT => 0)    
      quit

  if(erase)
    Clear_Wifly_Buffer

'----------------------------------------------------------------------
PUB Wifly_to_Term | Rx                           'Continually send Wifly Tx to Term Rx
                                                 'Runs in own cog

  Wifly_Buffer_Index := 0                        'Start index used to read/write Wifly_Buffer at 0
  RN_XV.rxFlush
  repeat
    repeat until not lockset(SemID)              'Wait until we lock the resource
    repeat while (Rx := RN_XV.CharTime(2) ) => 0
      if( Rx > 0)
        Term.Char(Rx)
        Wifly_Buffer[Wifly_Buffer_Index++] := Rx
        if (Wifly_Buffer_Index => BUFFERSIZE)
          Wifly_Buffer_Index := 0                'Loop Wifly_Buffer around
          ' NOTE: Wifly_Buffer overflow
          ' YOU WILL LOSE DATA unless you save the
          ' Wifly_Buffer before getting here.
          
        Wifly_Buffer[Wifly_Buffer_Index] := 0
    lockclr(SemID)                               'Unlock the resource
    delay_ms(100)

'----------------------------------------------------------------------
PUB Clear_Wifly_Buffer

  repeat until not lockset(SemID)                'Wait until we lock the resource
  Wifly_Buffer_Index := 0                        'Start index used to read/write Wifly_Buffer at 0
  bytefill(@Wifly_Buffer, 0, BUFFERSIZE-1)       'Clear Wifly_Buffer to all 0's
  lockclr(SemID)                                 'Unlock the resource

'----------------------------------------------------------------------
PUB HexByteToLong(hex)

  case hex
     "0": result := 0
     "1": result := 1
     "2": result := 2
     "3": result := 3
     "4": result := 4
     "5": result := 5
     "6": result := 6
     "7": result := 7
     "8": result := 8
     "9": result := 9
     "A": result := 10
     "B": result := 11
     "C": result := 12
     "D": result := 13
     "E": result := 14
     "F": result := 15
     OTHER:  result := -1

  return result   

'----------------------------------------------------------------------
PUB Delay_ms(mS)                                 'Delay_ms routine

  waitcnt((clkfreq/1000) * mS + cnt)

'----------------------------------------------------------------------

PUB Delay_us(uS)                                 'Delay_us routine

  waitcnt((clkfreq/1000000) * uS + cnt)

'----------------------------------------------------------------------
DAT

  AppHeader byte  CR,LF,"RN-XV Wifly FTP Client V01.spin is Alive",CR,LF,0

{{

┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}