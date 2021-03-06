{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   NTSC Colorbar Generator (C) 2009-04-29 Eric Ball                                           │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                    TERMS OF USE: Parallax Object Exchange License                                            │                                                            
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

'' Automatic hardware detection for Hydra, Demoboard and Hybrid by Graham Coley

CON

  _CLKMODE = RCSlow     ' Start prop in RCSlow mode internal crystal


PUB main

  HWDetect
  
  COGINIT( COGID, @cogstart, @cogstart )

Pub  HWDetect | HWPins

  clkset(%01101000,  12_000_000)                        ' Set internal oscillator to RCFast and set PLL to start
  waitcnt(cnt+120_000)                                  ' wait approx 10ms at 12mhz for PLL to 'warm up'

' Automatic hardware detection based on the use of pins 12 & 13 which results
' in different input states 
' Demoboard = Video Out
' Hydra = Keyboard Data In & Data Out
' Hybrid = Keyboard Data I/O & Clock I/O  
  
  HWPins := INA[12..13]                                 ' Check state of Pins 12-13

  CASE HWPins
    %00 : clkset( %01101111, 80_000_000 )                          ' Demo Board   80MHz (5MHz PLLx16)  
          ivcfg := %0_11_1_0_1_000_00000000000_001_0_01110000      ' demoboard  
          ifrqa := $16E8_BA2F                                      ' (7,159,090.9Hz/80MHz)<<32 NTSC demoboard & Hydra 
          idira := $0000_7000                                      ' demoboard
               
    %01 : clkset( %01110110, 80_000_000 )                          ' Hydra        80MHz (10MHz PLLx8)
          ivcfg := %0_11_1_0_1_000_00000000000_001_0_01110000      ' %0_10_1_0_1_000_00000000000_011_0_00000111      ' Hydra & Hybrid
          ifrqa := $16E8_BA2F                                      ' (7,159,090.9Hz/80MHz)<<32 NTSC demoboard & Hydra 
          idira := $0700_0000                                      ' Hydra & Hybrid
          
    %11 : clkset( %01101111, 96_000_000 )                          ' Hybrid       96MHz (6MHz PLLx16)
          ivcfg := %0_10_1_0_1_000_00000000000_011_0_00000111      ' Hydra & Hybrid
          ifrqa := $1317_45D1                                      ' (7,159,090.9Hz/96MHz)<<32 NTSC Hybrid
          idira := $0700_0000                                      ' Hydra & Hybrid

DAT
{{
The purpose of this code is twofold.  First, it shows the NTSC color gamut for
Propeller baseband video.  Second, this code is intended to be a relatively
simple template which may be used by others to develop Propeller video drivers.
Note: this code creates an 29.97Hz 525 line interlaced display.

Rules for developing video drivers:
1. Start simple.  Hardcode values and static display.
2. Add complexity and changes incrementally.  Verify at each step.
3. If something doesn't work it's either because you have made an incorrect
   assumption or made a coding error.

Video drivers are constrained by WAITVID to WAITVID timing.  In the inner
active display loop, this determines the maximum resolution at a given clock
frequency.  Other WAITVID to WAITVID intervals (e.g. front porch) determine
the minimum clock frequency.
}}
                        ORG     0
cogstart                MOV     VCFG, ivcfg             ' baseband composite mode w/ 2bpp color on appropriate pins 
                        MOV     CTRA, ictra             ' internal PLL mode, PLLA = 16*colorburst frequency
                        MOV     FRQA, ifrqa             ' 2*colorburst frequency 
                        MOV     DIRA, idira             ' enable output on appropriate pins

' Notes:
' MOVI VCFG, #0 will stop the VSCL counters
' Since VSCL is initialized to 0, it will take 4096 PLLA before it reloads
'   (This is also enough time for PLLA to stabilize.)
                         
mainloop                MOV     numline, #9             ' 9 lines of vsync
vsync0                  CMP     numline, #6     WZ      ' lines 4,5,6 serration pulses
              IF_NZ     CMP     numline, #5     WZ      ' lines 1,2,3 / 7,8,9 equalizing pulses
              IF_NZ     CMP     numline, #4     WZ
                        MOV     count, #2               ' 2 pulses per line
:half         IF_NZ     MOV     VSCL, vscleqal          ' equalizing pulse (short)
              IF_Z      MOV     VSCL, vsclselo          ' serration pulse (long)
                        WAITVID sync, #0                ' -40 IRE
              IF_NZ     MOV     VSCL, vscleqhi          ' equalizing pulse (long)
              IF_Z      MOV     VSCL, vsclsync          ' serration pulse (short)
                        WAITVID sync, blank             ' 0 IRE
                        DJNZ    count, #:half
                        DJNZ    numline, #vsync0
                         
                        MOV     numline, #12            ' 12 blank lines
blank0                  MOV     VSCL, vsclsync
                        WAITVID sync, #0                ' -40 IRE
                        MOV     VSCL, vsclblnk
                        WAITVID sync, blank             ' 0 IRE
                        DJNZ    numline, #blank0

' Officially there are 481 active lines (241+240), but on a normal TV
' number of these lines are lost to overscan.  200 per field is a more
' realistic amount padded to 241/240 at the top and bottom.

' The spec says horizontal blanking is only 10.7us (of 63.555us) 
' leaving 83% of the line for active video, but on a normal TV some of this
' time is lost to overscan. 70% of the line (or 2548 PLLA) is more realistic.

' This demo uses 25 PLLA per pixel (vsclactv).  Decreasing the number of PLLA
' per pixel increases the horizontal resolution.  The maximum horizontal
' resolution is limitted by two factors - CLKFREQ and the number of instruction
' cycles per WAITVID loop, and the composite color demodulator.  Since color
' in NTSC is modulated at 3,579,545Hz, pixel frequencies at or near twice
' this frequency (i.e. 8 PLLA) will cause color artifacting.

' Changes to the number of PLLA per pixel and the number of pixels per line
' will also require changes to vsclbp and vsclfp.  

' For an interlaced picture, this is the first, third, fifth ... lines.

                        MOV     numline, #241           ' 241 lines of active video
active0                 MOV     VSCL, vsclsync          ' horizontal sync (0H)
                        WAITVID sync, #0                ' -40 IRE
                        MOV     VSCL, vscls2cb          ' 5.3us 0H to burst
                        WAITVID sync, blank
                        MOV     VSCL, vsclbrst          ' 9 cycles of colorburst
                        WAITVID sync, burst
                        MOV     VSCL, vsclbp            ' backporch 9.2us OH to active video
                        WAITVID sync, blank
                        MOVD    :loop, #colors          ' initialize pointer
                        MOV     count, #(17*6+2)/4      ' number of WAITVIDs
                        MOV     VSCL, vsclactv          ' PLLA per pixel, 4 pixels per frame
:loop                   WAITVID colors, #%%3210
                        ADD     :loop, d1               ' increment pointer
                        DJNZ    count, #:loop
                        MOV     VSCL, vsclfp            ' front porch 1.5us
                        WAITVID sync, blank
                        DJNZ    numline, #active0
                         
' If you only need 240 lines of resolution, then you can create a non-interlaced
' picture by looping back to the start here.  Note: This will create a 262 line
' frame.  A frame with an odd number of lines may provide better color (due to
' the extra half cycle of colorburst).

'                       JMP     #mainloop
                         
                        MOV     VSCL, vsclsync          ' half line
                        WAITVID sync, #0                ' -40 IRE
                        MOV     VSCL, vsclselo
                        WAITVID sync, blank
                         
                        MOV     numline, #9             ' 9 lines of vsync (again)
vsync1                  CMP     numline, #6     WZ      ' lines 4,5,6 serration pulses
              IF_NZ     CMP     numline, #5     WZ      ' lines 1,2,3 / 7,8,9 equalizing pulses
              IF_NZ     CMP     numline, #4     WZ
                        MOV     count, #2               ' 2 pulses per line
:half         IF_NZ     MOV     VSCL, vscleqal          ' equalizing pulse (short)
              IF_Z      MOV     VSCL, vsclselo          ' serration pulse (long)
                        WAITVID sync, #0                ' -40 IRE
              IF_NZ     MOV     VSCL, vscleqhi          ' equalizing pulse (long)
              IF_Z      MOV     VSCL, vsclsync          ' serration pulse (short)
                        WAITVID sync, blank             ' 0 IRE
                        DJNZ    count, #:half
                        DJNZ    numline, #vsync1

                        MOV     VSCL, vsclhalf          ' half line
                        WAITVID sync, blank             ' 0 IRE
                         
                        MOV     numline, #13            ' 12 blank lines
blank1                  MOV     VSCL, vsclsync
                        WAITVID sync, #0                ' -40 IRE
                        MOV     VSCL, vsclblnk
                        WAITVID sync, blank             ' 0 IRE
                        DJNZ    numline, #blank1

' For an interlaced picture, this is the second, fourth, sixth ... lines.
                         
                        MOV     numline, #240           ' 240 lines of active video (again)
active1                 MOV     VSCL, vsclsync          ' horizontal sync (0H)
                        WAITVID sync, #0                ' -40 IRE
                        MOV     VSCL, vscls2cb          ' 5.3us 0H to burst
                        WAITVID sync, blank
                        MOV     VSCL, vsclbrst          ' 9 cycles of colorburst
                        WAITVID sync, burst
                        MOV     VSCL, vsclbp            ' backporch 9.2us OH to active video
                        WAITVID sync, blank
                        MOVD    :loop, #colors          ' initialize pointer
                        MOV     count, #(17*6+2)/4      ' number of WAITVIDs
                        MOV     VSCL, vsclactv          ' PLLA per pixel, 4 pixels per frame
:loop                   WAITVID colors, #%%3210
                        ADD     :loop, d1               ' increment pointer
                        DJNZ    count, #:loop
                        MOV     VSCL, vsclfp            ' front porch 1.5us
                        WAITVID sync, blank
                        DJNZ    numline, #active1

                        JMP     #mainloop

colors                  BYTE    $02                                             ' LONG padding
                        BYTE    $07, $06, $05, $04, $03, $02                    ' white to black (6 levels)
                        BYTE    $0B, $0C, $0D, $0E, $8F, $88                    ' 16 hues, 6 shades/hue
                        BYTE    $1B, $1C, $1D, $1E, $9F, $98
                        BYTE    $2B, $2C, $2D, $2E, $AF, $A0
                        BYTE    $3B, $3C, $3D, $3E, $BF, $B8
                        BYTE    $4B, $4C, $4D, $4E, $CF, $C8
                        BYTE    $5B, $5C, $5D, $5E, $DF, $D8
                        BYTE    $6B, $6C, $6D, $6E, $EF, $E8
                        BYTE    $7B, $7C, $7D, $7E, $FF, $F8
                        BYTE    $8B, $8C, $8D, $8E, $0F, $08
                        BYTE    $9B, $9C, $9D, $9E, $1F, $18
                        BYTE    $AB, $AC, $AD, $AE, $2F, $28
                        BYTE    $BB, $BC, $BD, $BE, $3F, $38
                        BYTE    $CB, $CC, $CD, $CE, $4F, $48
                        BYTE    $DB, $DC, $DD, $DE, $5F, $58
                        BYTE    $EB, $EC, $ED, $EE, $6F, $68
                        BYTE    $FB, $FC, $FD, $FE, $7F, $78
                        BYTE    $02                                             ' LONG padding

numline                 LONG    $0
count                   LONG    $0
d1                      LONG    1<<9                                            ' destination = 1

' Note: for NTSC the colors displayed depend on the phase wrt colorburst.
' Using a different color # for colorburst will cause the colors displayed
' to shift.  i.e. using color #0 for colorburst will cause color #0 to be
' yellow rather than blue.  Dynamic changes to the colorburst color # may
' require several frames for the TV to resynchronize.  

sync                    LONG    $8A0200                                         ' %%0 = -40 IRE, %%1 = 0 IRE, %%2 = burst
blank                   LONG    %%1111_1111_1111_1111                           ' 16 pixels color 1
burst                   LONG    %%2222_2222_2222_2222                           ' 16 pixels color 1

vsclhalf                LONG    1<<12+1820                                      ' NTSC H/2
vsclsync                LONG    1<<12+269                                       ' NTSC sync = 4.7us
vsclblnk                LONG    1<<12+3371                                      ' NTSC H-sync
vsclselo                LONG    1<<12+1551                                      ' NTSC H/2-sync
vscleqal                LONG    1<<12+135                                       ' NTSC sync/2
vscleqhi                LONG    1<<12+1685                                      ' NTSC H/2-sync/2
vscls2cb                LONG    1<<12+304-269                                   ' NTSC sync to colorburst
vsclbrst                LONG    16<<12+16*9                                     ' NTSC 16 PLLA per cycle, 9 cycles of colorburst
vsclbp                  LONG    1<<12+(527-304-16*9)+213                        ' NTSC back porch + overscan (213)
vsclactv                LONG    25<<12+25*4                                     ' NTSC 25 PLLA per pixel, 4 pixels per frame
vsclfp                  LONG    1<<12+214+86                                    ' NTSC overscan (214) + front porch

ivcfg                   LONG    %0_11_1_0_1_000_00000000000_001_0_01110000      ' demoboard
ictra                   LONG    %0_00001_110_00000000_000000_000_000000         ' NTSC
ifrqa                   LONG    $16E8_BA2F                                      ' (7,159,090.9Hz/80MHz)<<32 NTSC demoboard & Hydra 
idira                   LONG    $0000_7000                                      ' demoboard

{ Change log
2009-04-29    first release to forums.parallax.com
2009-04-29    fix cut&paste error (JMP #vsync0 in vsync1)
2009-04-30    make line 285 blank instead of active, add more comments & change log
2009-05-04    use MOVD instead of MOV to initialize WAITVID pointer, fixed vsclbp calculation
2009-05-05    changed burst so colors match PAL
2009-05-14    fixed non-interlaced comment, added comments about horizontal resolution
2009-06-21    added Coley's autodetection code
2009-07-16    added WAITVID note, upload to Object Exchange 
}    