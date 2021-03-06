{{
File.......... 4D-Systems-uOLED-160-G1SGC.spin
Purpose....... SW programming interface to the 4D Systems uOLED-160-G1SGC display.
               The software contained here for this display conforms to revision 4.0
               (March 9, 2011) of the GOLDELOX-SGC Command Set Software Interface
               Specification. The PmmC firmware for the GOLDELOX-SGC graphics processor
               on the display board must be up to date in order to fully utilize all
               the software commands implemented here.
Attribution... Much of this code was adapted from the µOLED-160-GMD1 object written
               by Steve McManus.
Author........ Jim Edwards
E-mail........ jim.edwards4@comcast.net
History....... v1.0 - Initial release
Copyright..... Copyright (c) 2011 Jim Edwards
Terms......... See end of file for terms of use.

Hardware used : uOLED-160-G1SGC, 160 pixels (width) by 128 pixels (height)                 

Schematics:
                       P8X32A
                     ┌────┬────┐                   uOLED-160-G1SGC
                     ┤0      31├                 ┌────────────────┐
                     ┤1      30├                 │                │
                     ┤2      29├                 │                │           
   DisplayCpuPinRx   ┤3      28├                 │     SCREEN     │
   DisplayCpuPinTx   ┤4      27├                 │      SIDE      │   1 - Vcc (+3.to - +5V)
   DisplayCpuPinRes  ┤5      26├                 │                │   2 - TX (P3)    
                     ┤6      25├                 │                │   3 - RX (P4)   
                     ┤7      24├                 │ 5 4 3 2 1      │   4 - GND    
                     ┤VSS   VDD├                 └─┬─┬─┬─┬─┬──────┘   5 - Reset~ (Active low) 
                     ┤BOEn   XO├             1K    │  │ │ │                
                     ┤RESn   XI├        P5 ───┳─   │ │ └─ +5V 
                     ┤VDD   VSS├            10K   │   │ └─── P3
                     ┤8      23├                └──┫   ┣───── P4 
                     ┤9      22├                      │
                     ┤10     21├                        10K pullup to avoid autobaud locking onto noise
                     ┤11     20├                       │
                     ┤12     19├                     +3.3V
                     ┤13     18├ 
                     ┤14     17├ 
                     ┤15     16├ 
                     └─────────┘ 
                                 
Information :

The real RGB value is encoded with two bytes :

RRRRRGGG GGGBBBBB

However, in the methods coded below, a value of 0 to 255 for each color is used and then each channel is
approximated to that value.
                                   
Methods:

<<< GSGC General Commands >>>

DisplayReset                                                                         - Toggle the active low reset on the display
DisplayInitialize                                                                    - Start up the Serial port and initialize the display.
DisplayAutobaud                                                                      - Auto baud command to the display
DisplaySetErrorCheckingOff                                                           - Turns error checking off so that methods for this object do not perform extensive error checking on input parameters
DisplaySetErrorCheckingOn                                                            - Turns error checking on so that methods for this object perform extensive error checking on input parameters
DisplayGetDeviceInfo(output, dev_type_ptr, hw_rev_ptr, fw_rev_ptr,                   - Get device/version info from the display
                     hor_res_ptr, vert_res_ptr)
DisplayReplaceBackgndColor(red8, green8, blue8)                                      - Replace background color of the display
DisplayClearScreen                                                                   - Clear the display screen 
DisplaySetPixelsOff                                                                  - Turn the display pixels off
DisplaySetPixelsOn                                                                   - Turn the display pixels on
DisplaySetContrast(value)                                                            - Adjust the display contrast
DisplayFadeoutContrast                                                               - Ramp the display contrast down from highest to lowest
DisplaySetPowerOff                                                                   - Turn the display power off (i.e. low power mode)
DisplaySetPowerOn                                                                    - Turn the display power on
DisplaySetSleep(mode, delayval)                                                      - Put the GOLDELOX-SGC chip into sleep mode, and optionally wake on certain conditions
JoystickGetStatus(option)                                                            - Get joystick status or wait for specific joystick activity
JoystickWaitStatus(option, wait)                                                     - Wait for specific joystick activity with specified timeout period
SoundPlayNoteOrFrequency(note, duration)                                             - Play a specified note or frequency for a specified duration
SoundPlayTune(tune_array_ptr, tune_length)                                           - Play a sequence of specified notes or frequencies, each for a specified duration

<<< GSGC Graphics Commands >>>

GraphicsAddBitmap(char_idx, data1, data2, data3, data4,                              - Add a user defined bitmap character to the internal memory
                  data5, data6, data7, data8)
GraphicsDrawCircle(x, y, radius, red8, green8, blue8)                                - Draw colored circle with the specified radius at the specified location
GraphicsDrawBitmap(char_idx, x, y, red8, green8, blue8)                              - Draw a previously defined user bitmap in the internal memory with the specified color at the specified location
GraphicsDrawTriangle(x1, y1, x2, y2, x3, y3, red8, green8, blue8)                    - Draw colored triangle with the specified vertices
GraphicsDrawImage(x, y, width, height, color_mode, pixel_array_ptr)                  - Draw a bitmap image of specified width and height starting at the specified top left corner
GraphicsSetBackgndColor(red8, green8, blue8)                                         - Set background color of the display for the next erase and draw commands (involving opaque mode text) to be sent
GraphicsDrawLine(x1, y1, x2, y2, red8, green8, blue8)                                - Draw colored line between specified endpoints 
GraphicsDrawPixel(x, y, red8, green8, blue8)                                         - Draw colored pixel at specified location
GraphicsReadPixel(x, y, red8_ptr, green8_ptr, blue8_ptr)                             - Read color value of pixel at specified location
GraphicsScreenCopyPaste(xs, ys, xd, yd, width, height)                               - Copies specified area of the screen as a bitmap block to another specified location on the screen
GraphicsDrawPolygon3(x1, y1, x2, y2, x3, y3, red8, green8, blue8)                    - Draws a wire frame (empty) polygon with the specified 3 vertices
GraphicsDrawPolygon4(x1, y1, x2, y2, x3, y3, x4, y4, red8, green8, blue8)            - Draws a wire frame (empty) polygon with the specified 4 vertices
GraphicsDrawPolygon5(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, red8, green8, blue8)    - Draws a wire frame (empty) polygon with the specified 5 vertices
GraphicsDrawPolygon6(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6,)                - Draws a wire frame (empty) polygon with the specified 6 vertices
                     red8, green8, blue8
GraphicsReplaceColor(x1, y1, x2, y2, old_red8, old_green8, old_blue8,                - Replaces the old color of the selected rectangular region with the new specified color
                     new_red8, new_green8, new_blue8)
GraphicsSetPenModeSolid                                                              - Set pen mode to solid for drawing graphics objects (e.g. circle, triangle, rectangle)
GraphicsSetPenModeWireFrame                                                          - Set pen mode to wire frame for drawing graphics objects (e.g. circle, triangle, rectangle)
GraphicsDrawRectangle(x1, y1, x2, y2, red8, green8, blue8)                           - Draw colored rectangle with the specified corners 

<<< GSGC Text Commands >>>

TextSetFont(font_set)                                                                - Selects one of the available internal fonts to use subsequently as the default for text character drawing operations
TextSetOpaque                                                                        - Set text appearance to opaque
TextSetTransparent                                                                   - Set text appearance to transparent
TextDrawStrScaled(x, y, font_set, red8, green8, blue8, width, height, str)           - Draw string of ASCII text in graphics format (i.e. scaled font) at specified location with specified color and font multipliers
TextDrawNumScaled(x, y, font_set, red8, green8, blue8, width, height, num)           - Draw decimal number in graphics format (i.e. scaled font) at specified location with specified color and font multipliers
TextDrawCharScaled(char, x, y, font_set, red8, green8, blue8, width, height)         - Draw an ASCII character in graphics format (i.e. scaled font) at specified location with specified color and font multipliers 
TextDrawStrFixed(col, row, font_set, red8, green8, blue8, str)                       - Draw string of ASCII text in text format (i.e. fixed font) at specified location with specified color
TextDrawNumFixed(col, row, font_set, red8, green8, blue8, num)                       - Draw decimal number in text format (i.e. fixed font) at specified location with specified color
TextDrawCharFixed(char, col, row, font_set, red8, green8, blue8)                     - Draw an ASCII character in text format (i.e. fixed font) at specified location with specified color
TextDrawButton(state, x, y, btn_red8, btn_green8, btn_blue8, font_set,               - Draw button in specified state with string of ASCII text in graphics format (i.e. scaled font) at specified location with specified color and font multipliers
               str_red8, str_green8, str_blue8, width, height, str)                                                                   

<<< GSGC Display Specific Commands >>>

DisplayScrollDisable                                                                 - Disable display scrolling
DisplayScrollEnable                                                                  - Enable display scrolling
DisplayScrollControl(dir, speed)                                                     - Set display scroll direction and speed
DisplayRegisterWrite(reg, data)                                                      - Write a byte to the specifed display internal register

<<< GSGC Memory Card Commands >>>

MemCardInitialize                                                                    - Initialize the memory card
MemCardSetAddressPointer(mem_addr)                                                   - Set address pointer of the memory card for read/write operations
MemCardReadByte                                                                      - Read one byte from the memory card
MemCardWriteByte(data)                                                               - Write one byte to the memory card
MemCardReadSector(sector_addr, sector_data_ptr)                                      - Read a sector on the memory card at the specified address
MemCardWriteSector(sector_addr, sector_data_ptr)                                     - Write a sector on the memory card at the specified address with the specified data
MemCardSaveImage(x, y, width, height, sector_addr)                                   - Copy an image from the specified area of the display screen to the memory card at the specified sector address
MemCardLoadImage(x, y, width, height, color_mode, sector_addr)                       - Load an image from the memory card at the specified sector address and display it at the specified area of the display screen   
MemCardRunObject(mem_addr)                                                           - Runs a single object (icon or command) stored on the memory card 
MemCardRunScript(mem_addr)                                                           - Runs a script stored on the memory card
MemCardDisplayVideo(x, y, width, height, color_mode, delay_msecs,                    - Play a video-animation clip from the memory card at the specified sector address and display it at the specified area of the display screen
                    frames, sector_addr)  

<<< GSGC Scripting Commands >>>

ScriptExit                                                                           - Terminate a script running from the memory card

<<< Miscellaneous Commands >>>

Red8Blue8Green8_To_Rgb565(red8, green8, blue8)                                       - Converts from 8 bit red, green, blue format to RGB565 format 
}}

OBJ

  Serial  : "FullDuplexSerial"
  Delay   : "Clock"

CON

  ' OLED pin constants
  
  DisplayCpuPinRx                  = 3             ' CPU receive pin from OLED display (i.e. OLED transmit pin)
  DisplayCpuPinTx                  = 4             ' CPU transmit pin to OLED display (i.e. OLED receive pin)
  DisplayCpuPinRes                 = 5             ' CPU reset pin to open collector transistor gives active low reset to OLED display  
  DisplayCPUBaudRate               = 128_000       ' CPU to OLED display serial interface baud rate

  ' GSGC graphics constants

  Rgb565Red                        = $F800         ' 16 bit red RGB value
  Rgb565Green                      = $07E0         ' 16 bit green RGB value
  Rgb565Blue                       = $001F         ' 16 bit blue RGB value
  Rgb565Black                      = $0000         ' 16 bit black Rgb value
  Rgb565White                      = $FFFF         ' 16 bit white RGB value

  ' GSGC general commands constants
  
  DisplayResponseAck               = $06           ' Acknowledge response value
  DisplayResponseNak               = $15           ' Negative acknowledge response value
  
  DisplayModePixels                = $01           ' Mode to turn display pixels on/off 
  DisplayPixelsOff                 = $00
  DisplayPixelsOn                  = $01
  DisplayModeContrast              = $02           ' Mode to adjust display contrast
  DisplayContrastMin               = $00
  DisplayContrastMax               = $0F
  DisplayModePower                 = $03           ' Mode to turn display power on/off
  DisplayPowerOff                  = $00    
  DisplayPowerOn                   = $01
  
  DisplaySleepModeTurnOffSD        = $80           ' Sleep mode to turn off uSD/uSDHC (must reinit manually)
  DisplaySleepModeWakeOnJoystick   = $02           ' Wake from sleep mode on joystick activity
  DisplaySleepModeWakeOnSerial     = $01           ' Wake from sleep mode on serial activity
  
  DisplayInfoOutputSerial          = $00           ' Device/verson info codes
  DisplayInfoOutputSerialScreen    = $01
  DisplayInfoDeviceTypeuOLED       = $00
  DisplayInfoDeviceTypeuLCD        = $01
  DisplayInfoDeviceTypeuVGA        = $02
  DisplayInfoResolution220Pixels   = $22
  DisplayInfoResolution128Pixels   = $28
  DisplayInfoResolution320Pixels   = $32
  DisplayInfoResolution160Pixels   = $60
  DisplayInfoResolution64Pixels    = $64
  DisplayInfoResolution176Pixels   = $76
  DisplayInfoResolution96Pixels    = $96
    
  JoystickOptionReturnStatus       = $08           ' Joystick option to return immediate status 
  JoystickOptionWaitForPressRel    = $0F           ' Joysticks options to wait for specific activity
  JoystickOptionWaitForPress       = $00
  JoystickOptionWaitForUpRel       = $01
  JoystickOptionWaitForLeftRel     = $02
  JoystickOptionWaitForDownRel     = $03
  JoystickOptionsWaitForRightRel   = $04
  JoystickOptionWaitForFireRel     = $05
  JoystickStatusNoPress            = $00           ' Joystick return status codes
  JoystickStatusTimeout            = $00
  JoystickStatusUpPress            = $01
  JoystickStatusLeftPress          = $02
  JoystickStatusDownPress          = $03
  JoystickStatusRightPress         = $04
  JoystickStatusFirePress          = $05
  
  GsgcDisplayAutobaud              = $55           ' Auto baud command
  GsgcDisplayGetDeviceInfo         = $56           ' Get device/version info
  GsgcDisplayReplaceBackgndColor   = $42           ' Replace background color
  GsgcDisplayClearScreen           = $45           ' Clear Screen
  GsgcDisplaySetControlFunction    = $59           ' Set display control function
  GsgcDisplaySleep                 = $5A           ' Put GOLDELOX-SGC chip into sleep mode, optionally wake on certain conditions
  GsgcJoystickGetStatus            = $4A           ' Get joystick status or wait for specific joystick activity
  GsgcJoystickWaitStatus           = $6A           ' Wait for specific joystick activity with specified timeout period
  GsgcSoundPlayNoteOrFrequency     = $4E           ' Play a specified note or frequency for a specified duration
  GsgcSoundPlayTune                = $6E           ' Play a sequence of specified note or frequency for a specified duration
  
  ' GSGC graphics commands constants

  GraphicsXMax                     = 159           ' Maximum x coordinate value
  GraphicsYMax                     = 127           ' Maximum y coordinate value
  GraphicsPixelWidth               = 160           ' Display width in pixels
  GraphicsPixelHeight              = 128           ' Display height in pixels
  GraphicsBitmapIndexMax           = 31            ' Maximum bitmap index value
  GraphicsImageColorMode256        = $08           ' Color modes for drawing an image
  GraphicsImageColorMode65K        = $10
  GraphicsPenModeSolid             = $00           ' Pen modes for drawing a graphics object (e.g. circle, triangle, rectangle)
  GraphicsPenModeWireFrame         = $01
  
  GsgcGraphicsAddBitmap            = $41           ' Add user bitmap
  GsgcGraphicsDrawCircle           = $43           ' Draw circle
  GsgcGraphicsDrawBitmap           = $44           ' Draw user bitmap
  GsgcGraphicsDrawTriangle         = $47           ' Draw triangle
  GsgcGraphicsDrawImage            = $49           ' Draw image/icon
  GsgcGraphicsSetBackgndColor      = $4B           ' Set background color 
  GsgcGraphicsDrawLine             = $4C           ' Draw line
  GsgcGraphicsDrawPixel            = $50           ' Draw pixel
  GsgcGraphicsReadPixel            = $52           ' Read pixel
  GsgcGraphicsScreenCopyPaste      = $63           ' Screen copy/paste
  GsgcGraphicsDrawPolygon          = $67           ' Draw polygon
  GsgcGraphicsReplaceColor         = $6B           ' Replace color of rectangular region
  GsgcGraphicsSetPenMode           = $70           ' Set pen mode to solid/wireframe
  GsgcGraphicsDrawRectangle        = $72           ' Draw rectangle

  ' GSGC text commands constants

  TextFontSet5x7                   = $00           ' Text internal font sets
  TextFontSet8x8                   = $01
  TextFontSet8x12                  = $02
  TextAppearanceTransparent        = $00           ' Text appearance modes
  TextAppearanceOpaque             = $01
  TextButtonStateDown              = $00           ' Text button states 
  TextButtonStateUp                = $01
  TextStringMaxChars               = 256           ' Maximum number of characters in a string that can be displayed by a text draw command

  GsgcTextSetFont                  = $46           ' Set text font
  GsgcTextSetOpacity               = $4F           ' Set text appearance to transparent/opaque
  GsgcTextDrawStrScaled            = $53           ' Draw ASCII string in graphics format (i.e. scaled font)
  GsgcTextDrawCharFixed            = $54           ' Draw ASCII character in text format (i.e. fixed font)
  GsgcTextDrawButton               = $62           ' Draw text button
  GsgcTextDrawStrFixed             = $73           ' Draw ASCII string in text format (i.e. fixed font)
  GsgcTextDrawCharScaled           = $74           ' Draw ASCII character in graphics format (i.e. scaled font)

  ' GSGC display specific constants

  DisplayScrollRegisterMode        = $00           ' Scroll control enable/disable register    
  DisplayScrollRegisterDirection   = $01           ' Scroll control direction register
  DisplayScrollRegisterSpeed       = $02           ' Scroll control speed register
  DisplayScrollOff                 = 0
  DisplayScrollOn                  = 1
  DisplayScrollLeft                = 0
  DisplayScrollRight               = 1
  DisplayScrollSpeedMin            = 0
  DisplayScrollSpeedMax            = 7

  GsgcDisplaySpCmd                 = $24           ' Display specific command header
  GsgcDisplaySpCmdScrollControl    = $53           ' Set display scroll options
  GsgcDisplaySpCmdRegisterWrite    = $57           ' Write byte to display internal register 

  ' GSGC extended commands constants

  GsgcExtendedCommandHeader        = $40           ' Extended command header  

  ' GSGC memory card commands constants

  MemCardMemAddrMax                = 2_147_483_647
  MemCardSectorAddrMax             = 4_194_303     ' Equals ((MemCardMemAddrMax + 1) / MemCardSectorSize) - 1
  MemCardSectorSize                = 512           ' Size of a memory card sector block in bytes
  MemCardScreenSectorSize          = ((2 * GraphicsPixelWidth * GraphicsPixelHeight) / MemCardSectorSize) ' Number of memory card sectors required to store all the 16-bit pixels of a complete display screen 

  GsgcMemCardSetAddressPointer     = $41           ' Set address pointer of memory card
  GsgcMemCardSaveImage             = $43           ' Save display screen image to memory card
  GsgcMemCardLoadImage             = $49           ' Load display screen with image from memory card
  GsgcMemCardRunObject             = $4F           ' Run object from memory card
  GsgcMemCardRunScript             = $50           ' Run 4DSL script program from memory card
  GsgcMemCardReadSector            = $52           ' Read sector of data from memory card
  GsgcMemCardDisplayVideo          = $56           ' Display video clip from memory card
  GsgcMemCardWriteSector           = $57           ' Write sector of data to memory card
  GsgcMemCardInitialize            = $69           ' Initialise memory card
  GsgcMemCardReadByte              = $72           ' Read byte of data from memory card
  GsgcMemCardWriteByte             = $77           ' Write byte of data to memory card
  
  ' GSGC scripting commands constants
  
  GsgcScriptDelay                  = $07           ' Script command for delay
  GsgcScriptSetCounter             = $08           ' Script command to set counter
  GsgcScriptDecrementCounter       = $09           ' Script command to decrement counter
  GsgcScriptJumpNotZero            = $0A           ' Script command to jump to address if counter not zero
  GsgcScriptJump                   = $0B           ' Script command to jump to address
  GsgcScriptExit                   = $0C           ' Script command to exit/terminate program

VAR

  byte uSD_Sector[512]
  byte dev_info[5]
  byte text_font
  long error_checking  ' Determines whether methods for this object do extensive error checking on input parameters. Use DisplaySetErrorCheckingOff/On to turn off/on.

{{

Methods for GSGC general commands

}}

PRI DisplayWaitAck | response  ' Wait for acknowledge response from display

  repeat
    response := Serial.rxtime(1500)
    if (response == DisplayResponseAck)
      return(TRUE)
    elseif (response == DisplayResponseNak)
      return(FALSE)
    else
      Serial.rxflush

PUB DisplayReset  ' Toggle the active low reset on the display

  outa[DisplayCpuPinRes]~ 
  dira[DisplayCpuPinRes]~~
  outa[DisplayCpuPinRes]~~  'Device Reset
  Delay.PauseMSec(750)
  outa[DisplayCpuPinRes]~
  
PUB DisplayInitialize  ' Start up the Serial port and initialize the display

  error_checking := FALSE
  Serial.start (DisplayCpuPinRx, DisplayCpuPinTx, %0000, DisplayCpuBaudRate)
  Delay.PauseMSec(750)
  
  ' Initialize OLED
  
  Serial.rxflush
  Delay.PauseMSec(20)
  DisplayAutobaud
  Delay.PauseMSec(20)
  DisplayClearScreen
  text_font := TextFontSet8x8
  TextSetFont(TextFontSet5x7)

PUB DisplayAutobaud  ' Auto baud command to the display

  Serial.tx(GsgcDisplayAutobaud)
  return(DisplayWaitAck) 

PUB DisplaySetErrorCheckingOff  ' Turns error checking off so that methods for this object do not perform extensive error checking on input parameters

  error_checking := FALSE

PUB DisplaySetErrorCheckingOn  ' Turns error checking on so that methods for this object perform extensive error checking on input parameters

  error_checking := TRUE

PUB DisplayGetDeviceInfo(output, dev_type_ptr, hw_rev_ptr, fw_rev_ptr, hor_res_ptr, vert_res_ptr) | count  ' Get device/version info from the display

  ' <Arguments> 
  ' output:         00 hex: Outputs the version and device info to the serial port only.
  '                 01 hex: Outputs the version and device info to the serial port as well as to the screen.
  '
  ' <Returns (by reference)> 
  ' dev_type_ptr:   The returned byte indicates the device type.
  '                     00 hex:  micro-OLED
  '                     01 hex:  micro-LCD
  '                     02 hex:  micro_VGA
  ' hw_rev_ptr:     The returned byte indicates the device hardware version.
  ' fw_rev_ptr:     The returned byte indicates the device firmware version.
  ' hor_res_ptr:    The returned byte indicates the horizontal resolution of the display.
  '                     22 hex: 220 pixels
  '                     28 hex: 128 pixels
  '                     32 hex: 320 pixels
  '                     60 hex: 160 pixels
  '                     64 hex: 64 pixels
  '                     76 hex: 176 pixels
  '                     96 hex: 96 pixels
  ' vert_res_ptr:   The returned byte indicates the vertical resolution of the display.
  '                     22 hex: 220 pixels
  '                     28 hex: 128 pixels
  '                     32 hex: 320 pixels
  '                     60 hex: 160 pixels
  '                     64 hex: 64 pixels
  '                     76 hex: 176 pixels
  '                     96 hex: 96 pixels
  
  Serial.tx(GsgcDisplayGetDeviceInfo)
  Serial.tx(output)
  repeat count from 0 to 4
    dev_info.byte[count] := Serial.rx
  long[dev_type_ptr] := dev_info.byte[0]
  long[hw_rev_ptr] := dev_info.byte[1]
  long[fw_rev_ptr] := dev_info.byte[2]
  long[hor_res_ptr] := dev_info.byte[3]
  long[vert_res_ptr] := dev_info.byte[4]

PUB DisplayReplaceBackgndColor(red8, green8, blue8) | rgb565  ' Replace background color of the display

  ' <Arguments> 
  ' red8:    Red value in range of 0 to 255.
  ' green8:  Green value in range of 0 to 255.
  ' blue8:   Blue value in range of 0 to 255.
  
  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (rgb565 => 0))
    Serial.tx(GsgcDisplayReplaceBackgndColor)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB DisplayClearScreen  ' Clear the display screen

  Serial.tx(GsgcDisplayClearScreen)
  return(DisplayWaitAck) 

PRI DisplaySetControlFunction(mode, value)  ' Set a display control function

  ' <Arguments> 
  ' mode:   00 hex:  NA
  '         01 hex:  Turn display pixels off/on.
  '                      Off:             when value = 00 hex.
  '                      On:              when value = 01 hex.
  '         02 hex:  Adjust display contrast.
  '                      Contrast range:  where value = 00 hex to 0F hex.
  '         03 hex:  Turn display power off/on. Off is low power mode.
  '                      Off:             when value = 00 hex.
  '                      On:              when value = 01 hex.
  ' value:  See mode description above.

  Serial.tx(GsgcDisplaySetControlFunction)
  Serial.tx(mode)
  Serial.tx(value)
  return(DisplayWaitAck)   

PRI DisplaySetPixels(value)  ' Turn the display pixels off/on

  ' <Arguments> 
  ' value: Off = 00 hex, On = 01 hex.
  
  if ((NOT error_checking) OR (ValidDisplayPixelsValue(value)))
    return(DisplaySetControlFunction(DisplayModePixels, value))
  else
    return(FALSE)

PUB DisplaySetPixelsOff  ' Turn the display pixels off

  return(DisplaySetPixels(DisplayPixelsOff))

PUB DisplaySetPixelsOn  ' Turn the display pixels on

  return(DisplaySetPixels(DisplayPixelsOn))

PUB DisplaySetContrast(value)  ' Adjust the display contrast

  if ((NOT error_checking) OR (ValidDisplayContrastValue(value)))
    return(DisplaySetControlFunction(DisplayModeContrast, value))
  else
    return(FALSE)

PUB DisplayFadeoutContrast(delay_msec) | value ' Ramp the display contrast down from highest to lowest

  REPEAT value from 15 to 0
    DisplaySetContrast(value)
    Delay.PauseMSec(delay_msec)

PRI DisplaySetPower(value)  ' Turn the display power off/on where off is low power mode

  ' <Arguments> 
  ' value: Off = 00 hex, On = 01 hex.
  
  if ((NOT error_checking) OR (ValidDisplayPowerValue(value)))
    return(DisplaySetControlFunction(DisplayModePower, value))
  else
    return(FALSE)

PUB DisplaySetPowerOff  ' Turn the display power off (i.e. low power mode)

  return(DisplaySetPower(DisplayPowerOff))

PUB DisplaySetPowerOn  ' Turn the display power on

  return(DisplaySetPower(DisplayPowerOn))

PUB DisplaySetSleep(mode, delayval) ' Put the GOLDELOX-SGC chip into sleep mode, and optionally wake on certain conditions

  ' <Arguments> 
  ' mode:     80 hex: Sleep mode to turn off uSD/uSDHC (must reinit manually).
  '           02 hex: Wake from sleep mode on joystick activity.
  '           01 hex: Wake from sleep mode on Serial activity.
  ' delayval: Not used.
  '
  ' Note that this command seems to wait on the display ack until the wake event has occurred.

  if ((NOT error_checking) OR (ValidDisplaySleepMode(mode)))
    Serial.tx(GsgcDisplaySleep)
    Serial.tx(mode)
    Serial.tx(delayval)
    return(DisplayWaitAck) 
  else
    return(FALSE)
    
PUB JoystickGetStatus(option) : status  ' Get joystick status or wait for specific joystick activity

  ' <Arguments>
  ' option:     08 hex:  Return immediate joystick status.
  '             0F hex:  Wait until joystick is pressed and released.
  '             00 hex:  Wait until joystick is pressed.
  '             01 hex:  Wait until joystick UP release.
  '             02 hex:  Wait until joystick LEFT release.
  '             03 hex:  Wait until joystick DOWN release.
  '             04 hex:  Wait until joystick RIGHT release.
  '             05 hex:  Wait until joystick FIRE release.
  '
  ' <Returns (by result code)>
  ' status:     00 hex:  No buttons pressed (or pressed button has been released).  
  '             01 hex:  Joystick Up pressed. 
  '             02 hex:  Joystick Left pressed.
  '             03 hex:  Joystick Down pressed.
  '             04 hex:  Joystick Right pressed.
  '             05 hex:  Joystick Fire pressed.
   
  if ((NOT error_checking) OR (ValidJoystickGetOption(option)))
    Serial.tx(GsgcJoystickGetStatus)
    Serial.tx(option)
    status := Serial.rx
  else
    status := JoystickStatusNoPress
    
PUB JoystickWaitStatus(option, wait) : status  ' Wait for specific joystick activity with specified timeout period

  ' <Arguments>
  ' option:     00 hex:  Wait until joystick is pressed.
  '             01 hex:  Wait until joystick UP release.
  '             02 hex:  Wait until joystick LEFT release.
  '             03 hex:  Wait until joystick DOWN release.
  '             04 hex:  Wait until joystick RIGHT release.
  '             05 hex:  Wait until joystick FIRE release.
  ' wait:       2 bytes (big endian, msb:lsb) define the wait time in milliseconds.
  '
  ' <Returns (by result code)>
  ' status:     00 hex:  Time-out (or pressed button has been released), or error in arguments.  
  '             01 hex:  Joystick Up pressed. 
  '             02 hex:  Joystick Left pressed.
  '             03 hex:  Joystick Down pressed.
  '             04 hex:  Joystick Right pressed.
  '             05 hex:  Joystick Fire pressed.
   
  if ((NOT error_checking) OR (ValidJoystickWaitOption(option)))
    Serial.tx(GsgcJoystickWaitStatus)
    Serial.tx(option)
    Serial.tx(wait.byte[1])
    Serial.tx(wait.byte[0])
    status := Serial.rx
  else
    status := JoystickStatusTimeout

PUB SoundPlayNoteOrFrequency(note, duration)  ' Play a specified note or frequency for a specified duration

  ' <Arguments> 
  ' note:      2 bytes (big endian, msb:lsb) define the note or frequency of the sound.
  '                0:          No sound, silence.
  '                1-84:       5 octaves piano range, plus 2 more.
  '                100-20000:  Frequency in Hz.
  ' duration:  2 bytes (big endian, msb:lsb) define the duration of the note in milliseconds.

  if ((NOT error_checking) OR (ValidNote(note) AND (duration > 0))) 
    Serial.tx(GsgcSoundPlayNoteOrFrequency)
    Serial.tx(note.byte[1])
    Serial.tx(note.byte[0])
    Serial.tx(duration.byte[1])
    Serial.tx(duration.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)
  
PUB SoundPlayTune(tune_array_ptr, tune_length) | tune_index, note, duration  ' Play a sequence of specified notes or frequencies, each for a specified duration

  ' <Arguments> 
  ' tune_array_ptr:   Word array of tuples, where each tuple consists of a note (word) and a duration (word).
  '                       note:      2 bytes (big endian, msb:lsb) define the note or frequency of the sound.
  '                                  0:          No sound, silence.
  '                                  1-84:       5 octaves piano range, plus 2 more.
  '                                  100-20000:  Frequency in Hz.
  '                       duration:  2 bytes (big endian, msb:lsb) define the duration of the note in milliseconds.
  ' length:           1 byte, number of note/duration tuples (maximum of 64).    

  if (ValidTuneLength(tune_length))
    repeat tune_index from 0 to (tune_length - 1)
      note := word[tune_array_ptr][2 * tune_index]
      duration := word[tune_array_ptr][(2 * tune_index) + 1]
      if (error_checking)
        ifnot (ValidNote(note) AND (duration > 0))
          return(FALSE)
    Serial.tx(GsgcSoundPlayTune)
    Serial.tx(tune_length)
    repeat tune_index from 0 to (tune_length - 1)
      note := word[tune_array_ptr][2 * tune_index]
      duration := word[tune_array_ptr][(2 * tune_index) + 1]
      Serial.tx(note.byte[1])
      Serial.tx(note.byte[0])
      Serial.tx(duration.byte[1])
      Serial.tx(duration.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)   

{{

Methods for GSGC graphics commands

}}

PUB GraphicsAddBitmap(char_idx, data1, data2, data3, data4, data5, data6, data7, data8)  ' Add a user defined bitmap character to the internal memory

  ' <Arguments>
  ' char_idx:        Bitmap character index to add to memory.
  '                  Range is 0 to GraphicsBitmapIndexMax, (GraphicsBitmapIndexMax + 1) characters in 8x8 format.
  ' data1..data8:    8 data bytes that make up the composition of the bitmap character.
  '                  The 8x8 bitmap composition is 1 byte wide (8 bits) by 8 bytes deep.
  '
  ' <Example>
  ' [b7][b6][b5][b4][b3][b2][b1][b0]  Data Bits
  '               ‣   ‣                data1 (18 hex)
  '           ‣           ‣            data2 (24 hex)
  '       ‣                   ‣        data3 (42 hex)
  '   ‣                           ‣    data4 (81 hex)
  '   ‣                           ‣    data5 (81 hex)
  '       ‣                   ‣        data6 (42 hex)
  '           ‣           ‣            data7 (24 hex)
  '               ‣   ‣                data8 (18 hex)

  if ((NOT error_checking) OR (ValidBitmapIndex(char_idx) AND (ValidBitmapData(data1, data2, data3, data4, data5, data6, data7, data8))))
    Serial.tx(GsgcGraphicsAddBitmap)
    Serial.tx(char_idx)
    Serial.tx(data1)
    Serial.tx(data2)
    Serial.tx(data3)
    Serial.tx(data4)
    Serial.tx(data5)
    Serial.tx(data6)
    Serial.tx(data7)
    Serial.tx(data8)
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB GraphicsDrawCircle(x, y, radius, red8, green8, blue8) | rgb565  ' Draw colored circle with the specified radius at the specified location

  ' <Arguments>
  ' x:         Horizontal display pixel position of the circle center in range of 0 to GraphicsXMax.
  ' y:         Vertical display pixel position of the circle center in range of 0 to GraphicsYMax.
  ' radius:    Radius of the circle in range of 1 to < x or (GraphicsXMax - x) and < y or (GraphicsYMax - y), whichever is less.
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.
  '
  ' The circle can be either solid or a wire frame depending on the value of the pen size (see GraphicsSetPen command).

  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)     
  if ((NOT error_checking) OR (ValidXY(x, y) AND ValidCircleRadius(x, y, radius) AND (rgb565 => 0)))
  
    Serial.tx(GsgcGraphicsDrawCircle)
    Serial.tx(x)
    Serial.tx(y)
    Serial.tx(radius)    
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB GraphicsDrawBitmap(char_idx, x, y, red8, green8, blue8) | rgb565  ' Draw a previously defined user bitmap in the internal memory with the specified color at the specified location

  ' <Arguments>
  ' char_idx:    Bitmap character index of a previously defined user bitmap character in memory to draw.
  '              Range is 0 to GraphicsBitmapIndexMax, (GraphicsBitmapIndexMax + 1) characters in 8x8 format.
  ' x:           Horizontal display pixel position of the bitmap character in range 0 to GraphicsXMax.
  ' y:           Vertical display pixel position of the bitmap character in range of 0 to GraphicsYMax.
  ' red8:        Red value in range of 0 to 255.
  ' green8:      Green value in range of 0 to 255.
  ' blue8:       Blue value in range of 0 to 255.

  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)      
  if ((NOT error_checking) OR (ValidBitmapIndex(char_idx) AND ValidXY(x, y) AND (rgb565 => 0)))
    Serial.tx(GsgcGraphicsDrawBitmap)
    Serial.tx(char_idx)
    Serial.tx(x)
    Serial.tx(y)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB GraphicsDrawTriangle(x1, y1, x2, y2, x3, y3, red8, green8, blue8) | rgb565  ' Draw colored triangle with the specified vertices

  ' <Arguments>
  ' x1, y1:    Horizontal and vertical display pixel pixel position of the first triangle vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x2, y2:    Horizontal and vertical display pixel pixel position of the second triangle vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x3, y3:    Horizontal and vertical display pixel pixel position of the third triangle vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.
  '
  ' The three vertices of the triangle must be specified starting with rightmost top vertice and proceeding in a counter-clockwise manner (i.e. x1 => x2, x3 => x2, y2 => y1, y3 > y1).
  ' The triangle can be either solid or a wire frame depending on the value of the pen size (see GraphicsSetPen command).

  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)      
  if ((NOT error_checking) OR (ValidTriangleVertices(x1, y1, x2, y2, x3, y3) AND (rgb565 => 0)))
    Serial.tx(GsgcGraphicsDrawTriangle)
    Serial.tx(x1)
    Serial.tx(y1)
    Serial.tx(x2)
    Serial.tx(y2)
    Serial.tx(x3)
    Serial.tx(y3)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB GraphicsDrawImage(x, y, width, height, color_mode, pixel_array_ptr) | byte_index, byte_cnt  ' Draw a bitmap image of specified width and height starting at the specified top left corner

  ' <Arguments>
  ' x:                 Horizontal start pixel position (top left corner) of the image in range 0 to GraphicsXMax.
  ' y:                 Vertical start pixel position (top left corner) of the image in range of 0 to GraphicsYMax.
  ' width:             Horizontal size in pixels of the image in range of 0 to GraphicsPixelWidth.
  ' height:            Vertical size in pixels of the image in range of 0 to GraphicsPixelHeight.
  ' color_mode:        08 hex: 256 color mode, 8 bits/1 byte per pixel.
  '                    10 hex: 65K color mode, 16 bits/2 bytes per pixel.
  ' pixel_array_ptr:   Image pixel data array where N is the total number of pixels.
  '                        N = width x height (when color_mode = 08 hex).
  '                        N = 2 x width x height (when color_mode = 10 hex).
  '
  ' Note that if (x + width) > GraphicsXMax or (y + height) > GraphicsYMax the image will be clipped.
  
  if ((NOT error_checking) OR (ValidXY(x, y) AND ValidWidthHeight(width, height) AND ValidImageColorMode(color_mode)))
    Serial.tx(GsgcGraphicsDrawImage)
    Serial.tx(x)
    Serial.tx(y)
    Serial.tx(width)
    Serial.tx(height)
    Serial.tx(color_mode)
    byte_cnt := width * height        
    if (color_mode == GraphicsImageColorMode65K)
      byte_cnt *= 2
    byte_index := 0
    repeat byte_cnt
      Serial.tx(byte[pixel_array_ptr + byte_index++])
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB GraphicsSetBackgndColor(red8, green8, blue8) | rgb565  ' Set background color of the display for the next erase and draw commands (involving opaque mode text) to be sent

  ' <Arguments> 
  ' red8:    Red value in range of 0 to 255.
  ' green8:  Green value in range of 0 to 255.
  ' blue8:   Blue value in range of 0 to 255.
  
  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (rgb565 => 0))
    Serial.tx(GsgcGraphicsSetBackgndColor)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB GraphicsDrawLine(x1, y1, x2, y2, red8, green8, blue8) | rgb565  ' Draw colored line between specified endpoints

  ' <Arguments>
  ' x1, y1:    Horizontal and vertical start pixel position of the line, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x2, y2:    Horizontal and vertical end pixel position of the line, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.

  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (ValidLineEndpoints(x1, y1, x2, y2) AND (rgb565 => 0)))
    Serial.tx(GsgcGraphicsDrawLine)
    Serial.tx(x1)
    Serial.tx(y1)
    Serial.tx(x2)
    Serial.tx(y2)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB GraphicsDrawPixel(x, y, red8, green8, blue8) | rgb565  ' Draw colored pixel at specified location

  ' <Arguments>
  ' x, y:      Horizontal and vertical position of the pixel, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.

  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (ValidXY(x, y) AND (rgb565 => 0)))
    Serial.tx(GsgcGraphicsDrawPixel)
    Serial.tx(x)
    Serial.tx(y)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB GraphicsReadPixel(x, y, red8_ptr, green8_ptr, blue8_ptr) : rgb565  ' Read color value of pixel at specified location

  ' <Arguments>
  ' x, y:        Horizontal and vertical position of the pixel, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  
  ' <Returns (by reference)> 
  ' red8_ptr:    The returned byte is the red value of the pixel in range of 0 to 255.
  ' green8_ptr:  The returned byte is the green value of the pixel in range of 0 to 255.
  ' blue8_ptr:   The returned byte is the blue value of the pixel in range of 0 to 255.

  if ((NOT error_checking) OR (ValidXY(x, y)))
    Serial.tx(GsgcGraphicsReadPixel)
    Serial.tx(x)
    Serial.tx(y)
    rgb565 := 0
    rgb565.byte[1] := Serial.rx
    rgb565.byte[0] := Serial.rx
    long[red8_ptr] := Rgb565_To_Red8(rgb565)
    long[green8_ptr] := Rgb565_To_Green8(rgb565)
    long[blue8_ptr] := Rgb565_To_Blue8(rgb565)
  else
    rgb565 := -1
    long[red8_ptr] := -1
    long[green8_ptr] := -1
    long[blue8_ptr] := -1

PUB GraphicsScreenCopyPaste(xs, ys, xd, yd, width, height)  ' Copies specified area of the screen as a bitmap block to another specified location on the screen 

  ' xs, ys:            Top left horizontal and vertical start pixel position of the screen area to be copied (source) in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' xd, yd:            Top left horizontal and vertical start pixel position of where copied area is to be pasted (destination) in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' width:             Horizontal size in pixels of the screen area to be copied (source)in range of 0 to GraphicsPixelWidth.
  ' height:            Vertical size in pixels of the screen area to be copied (source) in range of 0 to GraphicsPixelHeight.
  '
  ' Note that if (xd + width) > GraphicsXMax or (yd + height) > GraphicsYMax the image that is copied will be clipped.

  if ((NOT error_checking) OR (ValidXY(xs, ys) AND ValidWidthHeight(width, height) AND ValidXY(xd, yd)))
    Serial.tx(GsgcGraphicsScreenCopyPaste)
    Serial.tx(xs)
    Serial.tx(ys)
    Serial.tx(xd)
    Serial.tx(yd)
    Serial.tx(width)
    Serial.tx(height)
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB GraphicsDrawPolygon3(x1, y1, x2, y2, x3, y3, red8, green8, blue8) | num_vertices, rgb565  ' Draws a wire frame (empty) polygon with the specified 3 vertices

  ' x1, y1:    Horizontal and vertical display pixel position of the first polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x2, y2:    Horizontal and vertical display pixel position of the second polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x3, y3:    Horizontal and vertical display pixel position of the third polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.

  num_vertices := 3
  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (ValidXY(x1, y1) AND ValidXY(x2, y2) AND ValidXY(x3, y3) AND (rgb565 => 0)))
    Serial.tx(GsgcGraphicsDrawPolygon)
    Serial.tx(num_vertices)
    Serial.tx(x1)
    Serial.tx(y1)
    Serial.tx(x2)
    Serial.tx(y2)
    Serial.tx(x3)
    Serial.tx(y3)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB GraphicsDrawPolygon4(x1, y1, x2, y2, x3, y3, x4, y4, red8, green8, blue8) | num_vertices, rgb565  ' Draws a wire frame (empty) polygon with the specified 4 vertices

  ' x1, y1:    Horizontal and vertical display pixel position of the first polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x2, y2:    Horizontal and vertical display pixel position of the second polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x3, y3:    Horizontal and vertical display pixel position of the third polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x4, y4:    Horizontal and vertical display pixel position of the fourth polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively. 
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.

  num_vertices := 4
  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (ValidXY(x1, y1) AND ValidXY(x2, y2) AND ValidXY(x3, y3) AND ValidXY(x4, y4) AND (rgb565 => 0)))
    Serial.tx(GsgcGraphicsDrawPolygon)
    Serial.tx(num_vertices)
    Serial.tx(x1)
    Serial.tx(y1)
    Serial.tx(x2)
    Serial.tx(y2)
    Serial.tx(x3)
    Serial.tx(y3)
    Serial.tx(x4)
    Serial.tx(y4)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB GraphicsDrawPolygon5(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, red8, green8, blue8) | num_vertices, rgb565  ' Draws a wire frame (empty) polygon with the specified 5 vertices

  ' x1, y1:    Horizontal and vertical display pixel position of the first polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x2, y2:    Horizontal and vertical display pixel position of the second polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x3, y3:    Horizontal and vertical display pixel position of the third polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x4, y4:    Horizontal and vertical display pixel position of the fourth polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x5, y5:    Horizontal and vertical display pixel position of the fifth polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively. 
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.

  num_vertices := 5
  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (ValidXY(x1, y1) AND ValidXY(x2, y2) AND ValidXY(x3, y3) AND ValidXY(x4, y4) AND ValidXY(x5, y5) AND (rgb565 => 0)))
    Serial.tx(GsgcGraphicsDrawPolygon)
    Serial.tx(num_vertices)
    Serial.tx(x1)
    Serial.tx(y1)
    Serial.tx(x2)
    Serial.tx(y2)
    Serial.tx(x3)
    Serial.tx(y3)
    Serial.tx(x4)
    Serial.tx(y4)
    Serial.tx(x5)
    Serial.tx(y5)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB GraphicsDrawPolygon6(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6, red8, green8, blue8) | num_vertices, rgb565  ' Draws a wire frame (empty) polygon with the specified 6 vertices

  ' x1, y1:    Horizontal and vertical display pixel position of the first polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x2, y2:    Horizontal and vertical display pixel position of the second polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x3, y3:    Horizontal and vertical display pixel position of the third polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x4, y4:    Horizontal and vertical display pixel position of the fourth polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x5, y5:    Horizontal and vertical display pixel position of the fifth polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x6, y6:    Horizontal and vertical display pixel position of the sixth polygon vertice, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.  
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.

  num_vertices := 6
  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (ValidXY(x1, y1) AND ValidXY(x2, y2) AND ValidXY(x3, y3) AND ValidXY(x4, y4) AND ValidXY(x5, y5) AND ValidXY(x6, y6) AND (rgb565 => 0)))
    Serial.tx(GsgcGraphicsDrawPolygon)
    Serial.tx(num_vertices)
    Serial.tx(x1)
    Serial.tx(y1)
    Serial.tx(x2)
    Serial.tx(y2)
    Serial.tx(x3)
    Serial.tx(y3)
    Serial.tx(x4)
    Serial.tx(y4)
    Serial.tx(x5)
    Serial.tx(y5)
    Serial.tx(x6)
    Serial.tx(y6)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB GraphicsReplaceColor(x1, y1, x2, y2, old_red8, old_green8, old_blue8, new_red8, new_green8, new_blue8) | old_rgb565, new_rgb565  ' Replaces the old color of the selected rectangular region with the new specified color

  ' <Arguments>
  ' x1, y1:        Top left horizontal and vertical start pixel position of the rectangular region whose background color is to be replaced, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x2, y2:        Bottom right horizontal and vertical end pixel position of the rectangular region whose background color is to be replaced, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' old_red8:      Red value of old background color to be replaced in range of 0 to 255.
  ' old_green8:    Green value of old background color to be replaced in range of 0 to 255.
  ' old_blue8:     Blue value of old background color to be replaced in range of 0 to 255.
  ' new_red8:      Red value of new background color to be used for replacement in range of 0 to 255.
  ' new_green8:    Green value of new background color to be used for replacement in range of 0 to 255.
  ' new_blue8:     Blue value of new background color to be used for replacement in range of 0 to 255.
  
  old_rgb565 := Red8Blue8Green8_To_Rgb565(old_red8, old_green8, old_blue8)
  new_rgb565 := Red8Blue8Green8_To_Rgb565(new_red8, new_green8, new_blue8)
  if ((NOT error_checking) OR (ValidXY(x1, y1) AND ValidXY(x2, y2) AND (old_rgb565 => 0) AND (new_rgb565 => 0)))
    Serial.tx(GsgcGraphicsReplaceColor)
    Serial.tx(x1)
    Serial.tx(y1)
    Serial.tx(x2)
    Serial.tx(y2)
    Serial.tx(old_rgb565.byte[1])
    Serial.tx(old_rgb565.byte[0])
    Serial.tx(new_rgb565.byte[1])
    Serial.tx(new_rgb565.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)

PRI GraphicsSetPenMode(mode)  ' Set pen mode to solid or wire frame for drawing graphics objects (e.g. circle, triangle, rectangle)

  ' <Arguments> 
  'mode: Solid pen = 00 hex, Wire frame  = 01 hex.
  
  if ((NOT error_checking) OR (ValidPenMode(mode)))
    Serial.tx(GsgcGraphicsSetPenMode)
    Serial.tx(mode)
    return(DisplayWaitAck) 
  else
    return(FALSE)
    
PUB GraphicsSetPenModeSolid  ' Set pen mode to solid for drawing graphics objects (e.g. circle, triangle, rectangle)

  return(GraphicsSetPenMode(GraphicsPenModeSolid))

PUB GraphicsSetPenModeWireFrame  ' Set pen mode to wire frame for drawing graphics objects (e.g. circle, triangle, rectangle)

  return(GraphicsSetPenMode(GraphicsPenModeWireFrame))

PUB GraphicsDrawRectangle(x1, y1, x2, y2, red8, green8, blue8) | rgb565  ' Draw colored rectangle with the specified corners

  ' <Arguments>
  ' x1, y1:    Top left horizontal and vertical start pixel position of the rectangle in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' x2, y2:    Bottom right horizontal and vertical end pixel position of the rectangle, in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.
  '
  ' The rectangle can be either solid or a wire frame depending on the value of the pen size (see GraphicsSetPen command).
  
  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (ValidXY(x1, y1) AND ValidXY(x2, y2) AND (rgb565 => 0)))
    Serial.tx(GsgcGraphicsDrawRectangle)
    Serial.tx(x1)
    Serial.tx(y1)
    Serial.tx(x2)
    Serial.tx(y2)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0])
    return(DisplayWaitAck) 
  else
    return(FALSE)
  
{{

Methods for GSGC text commands

}}

PUB TextSetFont(font_set)  ' Selects one of the available internal fonts to use subsequently as the default for text character drawing operations

  ' <Arguments> 
  ' font_set:  00 hex: 5x7 internal font set
  '            01 hex: 8x8 internal font set
  '            02 hex: 8x12 internal font set
    
  if ((NOT error_checking) OR (ValidTextFontSet(font_set)))
    if (text_font <> font_set)
      Serial.tx(GsgcTextSetFont)
      Serial.tx(font_set)
      result := DisplayWaitAck
      if (result)
        text_font := font_set
      return(result)
    else
      return(TRUE)
  else
    return(FALSE)
    
PRI TextSetOpacity(mode)  ' Set the text appearance to transparent/opaque

  ' <Arguments> 
  ' mode:  00 hex: Transparent, objects behind text are visible.
  '        01 hex: Opaque, objects behind text are blocked by background
  
  if ((NOT error_checking) OR (ValidTextAppearanceMode(mode)))
    Serial.tx(GsgcTextSetOpacity)
    Serial.tx(mode)
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB TextSetOpaque  ' Set text appearance to opaque

  return(TextSetOpacity(TextAppearanceOpaque))

PUB TextSetTransparent  ' Set text appearance to transparent

  return(TextSetOpacity(TextAppearanceTransparent))

PUB TextDrawStrScaled(x, y, font_set, red8, green8, blue8, width, height, str) | rgb565  ' Draw string of ASCII text in graphics format (i.e. scaled font) at specified location with specified color and font multipliers

  ' <Arguments>
  ' x, y:      Top left horizontal and vertical start pixel position of the string to be drawn in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively. 
  ' font_set:  00 hex: 5x7 internal font set.
  '            01 hex: 8x8 internal font set.
  '            02 hex: 8x12 internal font set.
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.
  ' width:     Font width scaling factor ("width" times normal character width for selected font set).
  ' height:    Font height scaling factor ("height" times normal character height for selected font set).
  ' str:       Null terminated string to draw on display. Maximum string length is 256 bytes.

  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (ValidXY(x, y) AND ValidTextFontSet(font_set) AND (rgb565 => 0) AND (strsize(str) =< TextStringMaxChars)))    
    Serial.tx(GsgcTextDrawStrScaled)
    Serial.tx(x)
    Serial.tx(y)
    Serial.tx(font_set)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0]) 
    Serial.tx(width)
    Serial.tx(height)
    repeat strsize(str)
      Serial.tx(byte[str++])
    Serial.tx(0)
    return(DisplayWaitAck) 
  else
    return(FALSE)
    
PUB TextDrawNumScaled(x, y, font_set, red8, green8, blue8, width, height, num) | rgb565  ' Draw decimal number in graphics format (i.e. scaled font) at specified location with specified color and font multipliers

  ' <Arguments>
  ' x, y:      Top left horizontal and vertical start pixel position of the decimal number to be drawn in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively. 
  ' font_set:  00 hex: 5x7 internal font set.
  '            01 hex: 8x8 internal font set.
  '            02 hex: 8x12 internal font set.
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.
  ' width:     Font width scaling factor ("width" times normal character width for selected font set).
  ' height:    Font height scaling factor ("height" times normal character height for selected font set).
  ' num:       Decimal number to draw on display.

  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (ValidXY(x, y) AND ValidTextFontSet(font_set) AND (rgb565 => 0)))    
    Serial.tx(GsgcTextDrawStrScaled)
    Serial.tx(x)
    Serial.tx(y)
    Serial.tx(font_set)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0]) 
    Serial.tx(width)
    Serial.tx(height)
    Serial.dec(num)
    Serial.tx(0)
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB TextDrawCharScaled(char, x, y, font_set, red8, green8, blue8, width, height) | rgb565  ' Draw an ASCII character in graphics format (i.e. scaled font) at specified location with specified color and font multipliers 

  ' <Arguments>
  ' char:      Character to draw on display in range of 20 hex to 7F hex.
  ' x, y:      Top left horizontal and vertical start pixel position of the character to be drawn in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively. 
  ' font_set:  00 hex: 5x7 internal font set.
  '            01 hex: 8x8 internal font set.
  '            02 hex: 8x12 internal font set.
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.
  ' width:     Font width scaling factor ("width" times normal character width for selected font set).
  ' height:    Font height scaling factor ("height" times normal character height for selected font set).

  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (ValidChar(char) AND ValidXY(x, y) AND ValidTextFontSet(font_set) AND (rgb565 => 0)))
    TextSetFont(font_set)    
    Serial.tx(GsgcTextDrawCharScaled)
    Serial.tx(char)
    Serial.tx(x)
    Serial.tx(y)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0])
    Serial.tx(width)
    Serial.tx(height) 
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB TextDrawStrFixed(col, row, font_set, red8, green8, blue8, str) | rgb565  ' Draw string of ASCII text in text format (i.e. fixed font) at specified location with specified color

  ' <Arguments> 
  ' col:       Column start position of the string to be drawn in range of 0-25 for 5x7 text font, 0-19 for 8x8 and 8x12 text fonts.
  ' row:       Row start position of the string to be drawn in range of 0-15 for 5x7 and 8x8 text fonts, 0-9 for 8x12 text font.
  ' font_set:  00 hex: 5x7 internal font set.
  '            01 hex: 8x8 internal font set.
  '            02 hex: 8x12 internal font set.
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.
  ' str:       Null terminated string to draw on display. Maximum string length is 256 bytes.

  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (ValidTextFontSet(font_set) AND ValidColRow(col, row, font_set) AND (rgb565 => 0) AND (strsize(str) =< TextStringMaxChars)))    
    Serial.tx(GsgcTextDrawStrFixed)
    Serial.tx(col)
    Serial.tx(row)
    Serial.tx(font_set)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0]) 
    repeat strsize(str)
      Serial.tx(byte[str++])
    Serial.tx(0)
    return(DisplayWaitAck) 
  else
    return(FALSE)
    
PUB TextDrawNumFixed(col, row, font_set, red8, green8, blue8, num) | rgb565  ' Draw decimal number in text format (i.e. fixed font) at specified location with specified color

  ' <Arguments>
  ' col:       Column start position of the decimal number to be drawn in range of 0-25 for 5x7 text font, 0-19 for 8x8 and 8x12 text fonts.
  ' row:       Row start position of the decimal number to be drawn in range of 0-15 for 5x7 and 8x8 text fonts, 0-9 for 8x12 text font.
  ' font_set:  00 hex: 5x7 internal font set.
  '            01 hex: 8x8 internal font set.
  '            02 hex: 8x12 internal font set.
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.
  ' num:       Decimal number to draw on display. 

  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (ValidTextFontSet(font_set) AND ValidColRow(col, row, font_set) AND (rgb565 => 0)))
    Serial.tx(GsgcTextDrawStrFixed)
    Serial.tx(col)
    Serial.tx(row)
    Serial.tx(font_set)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0]) 
    Serial.dec(num)
    Serial.tx(0)
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB TextDrawCharFixed(char, col, row, font_set, red8, green8, blue8) | rgb565  ' Draw an ASCII character in text format (i.e. fixed font) at specified location with specified color

  ' <Arguments>
  ' char:      Character to draw on display in range of 20 hex to 7F hex.
  ' col:       Column start position of the character to be drawn in range of 0-25 for 5x7 text font, 0-19 for 8x8 and 8x12 text fonts.
  ' row:       Row start position of the character to be drawn in range of 0-15 for 5x7 and 8x8 text fonts, 0-9 for 8x12 text font.
  ' font_set:  00 hex: 5x7 internal font set.
  '            01 hex: 8x8 internal font set.
  '            02 hex: 8x12 internal font set.
  ' red8:      Red value in range of 0 to 255.
  ' green8:    Green value in range of 0 to 255.
  ' blue8:     Blue value in range of 0 to 255.

  rgb565 := Red8Blue8Green8_To_Rgb565(red8, green8, blue8)
  if ((NOT error_checking) OR (ValidChar(char) AND ValidTextFontSet(font_set) AND ValidColRow(col, row, font_set) AND (rgb565 => 0)))
    TextSetFont(font_set)    
    Serial.tx(GsgcTextDrawCharFixed)
    Serial.tx(char)
    Serial.tx(col)
    Serial.tx(row)
    Serial.tx(rgb565.byte[1])
    Serial.tx(rgb565.byte[0]) 
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB TextDrawButton(state, x, y, btn_red8, btn_green8, btn_blue8, font_set, str_red8, str_green8, str_blue8, width, height, str) | btn_rgb565, str_rgb565  ' Draw button in specified state with string of ASCII text in graphics format (i.e. scaled font) at specified location with specified color and font multipliers

  ' <Arguments>
  ' state:       00 hex: Draw button down (pressed).
  '              01 hex: Draw button up (not pressed).
  ' x, y:        Top left horizontal and vertical start pixel position of the button to be drawn in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively. 
  ' btn_red8:    Button red value in range of 0 to 255.
  ' btn_green8:  Button green value in range of 0 to 255.
  ' btn_blue8:   Button blue value in range of 0 to 255.
  ' font_set:    00 hex: 5x7 internal font set.
  '              01 hex: 8x8 internal font set.
  '              02 hex: 8x12 internal font set.
  ' str_red8:    Text string red value in range of 0 to 255.
  ' str_green8:  Text string green value in range of 0 to 255.
  ' str_blue8:   Text string blue value in range of 0 to 255.
  ' width:       Font width scaling factor ("width" times normal character width for selected font set).
  ' height:      Font height scaling factor ("height" times normal character height for selected font set).
  ' str:         Null terminated string to draw on display within button. Maximum string length is 256 bytes.

  btn_rgb565 := Red8Blue8Green8_To_Rgb565(btn_red8, btn_green8, btn_blue8)
  str_rgb565 := Red8Blue8Green8_To_Rgb565(str_red8, str_green8, str_blue8)  
  if ((NOT error_checking) OR (ValidTextButtonState(state) AND ValidXY(x, y) AND (btn_rgb565 => 0) AND ValidTextFontSet(font_set) AND (str_rgb565 => 0) AND (strsize(str) =< TextStringMaxChars)))    
    Serial.tx(GsgcTextDrawButton)
    Serial.tx(state)  
    Serial.tx(x)
    Serial.tx(y)
    Serial.tx(btn_rgb565.byte[1])
    Serial.tx(btn_rgb565.byte[0]) 
    Serial.tx(font_set)
    Serial.tx(str_rgb565.byte[1])
    Serial.tx(str_rgb565.byte[0]) 
    Serial.tx(width)
    Serial.tx(height)
    repeat strsize(str)
      Serial.tx(byte[str++])
    Serial.tx(0)
    return(DisplayWaitAck) 
  else
    return(FALSE)
    
{{

Methods for GSGC display specific commands

}}

PRI DisplayScrollMode(mode)  ' Enable/disable display scrolling

  ' <Arguments> 
  ' mode: Disable = 0, Enable = 1.
  
  if ((NOT error_checking) OR (ValidDisplayScrollMode(mode)))
    Serial.tx(GsgcDisplaySpCmd)    
    Serial.tx(GsgcDisplaySpCmdScrollControl)
    Serial.tx(DisplayScrollRegisterMode)   
    Serial.tx(mode)  
    return(DisplayWaitAck) 
  else
    return(FALSE)

PUB DisplayScrollDisable  ' Disable display scrolling

  return(DisplayScrollMode(DisplayScrollOff))
  
PUB DisplayScrollEnable  ' Enable display scrolling

  return(DisplayScrollMode(DisplayScrollOn))

PUB DisplayScrollControl(dir, speed)  ' Set display scroll direction and speed

  ' <Arguments> 
  ' dir:    Left = 0, Right = 1.
  ' speed:  Speed in range of 0 (slowest) to 7 (fastest)

  if ((NOT error_checking) OR (ValidDisplayScrollDirection(dir) AND ValidDisplayScrollSpeed(speed)))
    Serial.tx(GsgcDisplaySpCmd)    
    Serial.tx(GsgcDisplaySpCmdScrollControl)
    Serial.tx(DisplayScrollRegisterDirection)   
    Serial.tx(dir)  
    if (DisplayWaitAck)
      Serial.tx(GsgcDisplaySpCmd)    
      Serial.tx(GsgcDisplaySpCmdScrollControl)
      Serial.tx(DisplayScrollRegisterSpeed)   
      Serial.tx(speed)
      return(DisplayWaitAck)
    else
      return(FALSE)  
  else
    return(FALSE)

PUB DisplayRegisterWrite(reg, data)  ' Write a byte to the specifed display internal register

  ' <Arguments> 
  ' reg:   Display register to write. See SEPS525 driver datasheet for register details.
  ' data:  Byte to write to the specified register.
  ' 

  if ((NOT error_checking) OR (ValidData8(data)))  
    Serial.tx(GsgcDisplaySpCmd)    
    Serial.tx(GsgcDisplaySpCmdRegisterWrite)
    Serial.tx(reg)   
    Serial.tx(data)  
    return(DisplayWaitAck) 
  else
    return(FALSE)
  
{{

Methods for GSGC memory card commands

}}

PUB MemCardInitialize  ' Initialize the memory card

  ' The memory card, if present, is always initialized automatically upon a power-up or reset cycle. If the memory
  ' card is inserted after the power-up or a reset cycle, this command must be used to initialize the card.
  
  Serial.tx(GsgcExtendedCommandHeader)
  Serial.tx(GsgcMemCardInitialize)
  return(DisplayWaitAck)   
    
PUB MemCardSetAddressPointer(mem_addr) | index  ' Set address pointer of the memory card for read/write operations

  ' <Arguments> 
  ' mem_addr:  32 bit memory address
  
  if (ValidMemCardMemAddr(mem_addr))
    Serial.tx(GsgcExtendedCommandHeader)
    Serial.tx(GsgcMemCardSetAddressPointer)
    repeat index from 3 to 0
      Serial.tx(mem_addr.byte[index])
    return(DisplayWaitAck)
  else
    return(FALSE)

PUB MemCardReadByte : data  ' Read one byte from the memory card

  ' <Returns (by result code)>
  ' data:  byte read from memory card
  '
  ' The byte is read at the current address in the memory address pointer. The memory address pointer value may
  ' be set by a call to MemCardSetAddressPointer. The memory address pointer is automatically incremented on each
  ' read/write byte operation to the next sequential address location

  Serial.tx(GsgcExtendedCommandHeader)
  Serial.tx(GsgcMemCardReadByte)
  data := Serial.rx
 
PUB MemCardWriteByte(data)  ' Write one byte to the memory card

  ' <Arguments> 
  ' data:  Byte to write to memory card
  '
  ' The byte is written at the current address in the memory address pointer. The memory address pointer value may
  ' be set by a call to MemCardSetAddressPointer. The memory address pointer is automatically incremented on each
  ' read/write byte operation to the next sequential address location

  if ((NOT error_checking) OR (ValidData8(data)))   
    Serial.tx(GsgcExtendedCommandHeader)
    Serial.tx(GsgcMemCardWriteByte)
    Serial.tx(data)  
    return(DisplayWaitAck)
  else
    return(FALSE)
  
PUB MemCardReadSector(sector_addr, sector_data_ptr) | index  ' Read a sector on the memory card at the specified address

  ' <Arguments>
  ' sector_addr:      Memory card sector address to start reading at.
  ' sector_data_ptr:  512 byte buffer to copy data read from the specified sector of the memory card.

  if ((NOT error_checking) OR (ValidMemCardSectorAddr(sector_addr)))
    Serial.tx(GsgcExtendedCommandHeader)
    Serial.tx(GsgcMemCardReadSector)  
    repeat index from 2 to 0
      Serial.tx(sector_addr.byte[index])
    repeat index from 0 to (MemCardSectorSize - 1)
      byte[sector_data_ptr][index] := Serial.rx
    return(TRUE)   
  else
    return(FALSE)
    
PUB MemCardWriteSector(sector_addr, sector_data_ptr) | index  ' Write a sector on the memory card at the specified address with the specified data

  ' <Arguments>
  ' sector_addr:      Memory card sector address to start writing at.
  ' sector_data_ptr:  512 byte buffer of sector data to be written to the memory card. The data length must be MemCardSectorSize bytes.
  '
  ' If the data block to be written is less than MemCardSectorSize, then the rest of the remaining data must be padded out.

  if ((NOT error_checking) OR (ValidMemCardSectorAddr(sector_addr)))
    Serial.tx(GsgcExtendedCommandHeader)
    Serial.tx(GsgcMemCardWriteSector)  
    repeat index from 2 to 0
      Serial.tx(sector_addr.byte[index])
    repeat index from 0 to (MemCardSectorSize - 1)
      Serial.tx(byte[sector_data_ptr][index])
    return(DisplayWaitAck)   
  else
    return(FALSE)

PUB MemCardSaveImage(x, y, width, height, sector_addr) | index  ' Copy an image from the specified area of the display screen to the memory card at the specified sector address

  ' <Arguments>
  ' x, y:         Top left horizontal and vertical start pixel position of the screen area for the image to be copied (source) in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' width:        Horizontal size in pixels of the screen area for the image to be copied (source) in range of 0 to GraphicsPixelWidth.
  ' height:       Vertical size in pixels of the screen area for the image to be copied (source) in range of 0 to GraphicsPixelHeight.
  ' sector_addr:  Memory card starting sector address to copy display screen image to. 

  if ((NOT error_checking) OR (ValidXY(x, y) AND ValidWidthHeight(width, height) AND ValidMemCardSectorAddr(sector_addr)))
    Serial.tx(GsgcExtendedCommandHeader) 
    Serial.tx(GsgcMemCardSaveImage)
    Serial.tx(x)
    Serial.tx(y)
    Serial.tx(width)
    Serial.tx(height)
    repeat index from 2 to 0
      Serial.tx(sector_addr.byte[index])
    return(DisplayWaitAck)   
  else
    return(FALSE)
    
PUB MemCardLoadImage(x, y, width, height, color_mode, sector_addr) | index  ' Load an image from the memory card at the specified sector address and display it at the specified area of the display screen  

  ' <Arguments>
  ' x, y:         Top left horizontal and vertical start pixel position of the screen area where the image is to be displayed in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' width:        Horizontal size in pixels of the image on the memory card in range of 0 to GraphicsPixelWidth.
  ' height:       Vertical size in pixels of the image on the memory card in range of 0 to GraphicsPixelHeight.
  ' color_mode:   08 hex: 256 color mode, 8 bits/1 byte per pixel.
  '               10 hex: 65K color mode, 16 bits/2 bytes per pixel.
  ' sector_addr:  Memory card starting sector address to copy image to the display screen. 

  if ((NOT error_checking) OR (ValidXY(x, y) AND ValidWidthHeight(width, height) AND ValidImageColorMode(color_mode) AND ValidMemCardSectorAddr(sector_addr)))
    Serial.tx(GsgcExtendedCommandHeader) 
    Serial.tx(GsgcMemCardLoadImage)
    Serial.tx(x)
    Serial.tx(y)
    Serial.tx(width)
    Serial.tx(height)
    Serial.tx(color_mode)
    repeat index from 2 to 0
      Serial.tx(sector_addr.byte[index])
    return(DisplayWaitAck)                                
  else
    return(FALSE)

PUB MemCardRunObject(mem_addr) | index  ' Runs a single object (icon or command) stored on the memory card

  ' <Arguments> 
  ' mem_addr:  32 bit memory address of object.
  '
  ' The 32 bit address of the object on the uSD card must be known to use this command
    
  if (ValidMemCardMemAddr(mem_addr))
    Serial.tx(GsgcExtendedCommandHeader)
    Serial.tx(GsgcMemCardRunObject)  
    repeat index from 3 to 0
      Serial.tx(mem_addr.byte[index])
    return(DisplayWaitAck)
  else
    return(FALSE)
    
PUB MemCardRunScript(mem_addr) | index  ' Runs a script stored on the memory card

  ' <Arguments> 
  ' mem_addr:  32 bit memory start address of script.
  '
  ' The 32 bit address of the script on the uSD card must be known to use this command. A script
  ' is a series of objects (icons or commands). Note that there is no ACK response to this
  ' command as the script may never end.
    
  if (ValidMemCardMemAddr(mem_addr))
    Serial.tx(GsgcExtendedCommandHeader)
    Serial.tx(GsgcMemCardRunScript)  
    repeat index from 3 to 0
      Serial.tx(mem_addr.byte[index])
    ' No ACK on this command, only a NACK if error or the memory card is not present
  else
    return(FALSE)

PUB MemCardDisplayVideo(x, y, width, height, color_mode, delay_msecs, frames, sector_addr) | index  ' Play a video-animation clip from the memory card at the specified sector address and display it at the specified area of the display screen  

  ' <Arguments>
  ' x, y:         Top left horizontal and vertical start pixel position of the screen area where the video is to be displayed in range of 0 to GraphicsXMax and 0 to GraphicsYMax, respectively.
  ' width:        Horizontal size in pixels of the video on the memory card in range of 0 to GraphicsPixelWidth.
  ' height:       Vertical size in pixels of the video on the memory card in range of 0 to GraphicsPixelHeight.
  ' color_mode:   08 hex: 256 color mode, 8 bits/1 byte per pixel.
  '               10 hex: 65K color mode, 16 bits/2 bytes per pixel.
  ' delay_msecs:  1 byte inter-frame delay between frames in milliseconds.
  ' frames:       2 bytes (msb:lsb) total frame count for the video-animation clip.
  ' sector_addr:  Memory card starting sector address to copy video-animation clip to the display screen. 

  if ((NOT error_checking) OR (ValidXY(x, y) AND ValidWidthHeight(width, height) AND ValidImageColorMode(color_mode) AND ValidData8(delay_msecs) AND ValidData16(frames) AND ValidMemCardSectorAddr(sector_addr)))
    Serial.tx(GsgcExtendedCommandHeader) 
    Serial.tx(GsgcMemCardDisplayVideo)
    Serial.tx(x)
    Serial.tx(y)
    Serial.tx(width)
    Serial.tx(height)
    Serial.tx(color_mode)
    Serial.tx(delay_msecs)
    repeat index from 1 to 0
      Serial.tx(frames.byte[index])
    repeat index from 2 to 0
      Serial.tx(sector_addr.byte[index])
    return(DisplayWaitAck)                                
  else
    return(FALSE)
    
{{

Methods for GSGC scripting commands

}}
   
PUB ScriptExit  ' Terminate a script running from the memory card

  Serial.tx(GsgcScriptExit)
  DisplayWaitAck
    
{{

Methods for performing conversions and validating parameters

}}

PUB Red8Blue8Green8_To_Rgb565(red8, green8, blue8)  ' Converts from 8 bit red, green, blue format to RGB565 format

  ' <Arguments> 
  ' red8:    Red value in range of 0 to 255.
  ' green8:  Green value in range of 0 to 255.
  ' blue8:   Blue value in range of 0 to 255.
  '
  ' Note that the 16 bit RGB color for the display is 2 bytes in the following format R4R3R2R1R0G5G4G3G2G1G0B4B3B2B1B0, where msb=R4R3R2R1R0G5G4G3, lsb=G2G1G0B4B3B2B1B0.
  ' R := (red >> 3) << 11
  ' G := (green >> 2) << 5 
  ' B := blue >> 3
  
  if ((NOT error_checking) OR (ValidData8(red8) AND ValidData8(blue8) AND ValidData8(green8)))
    return(((red8 >> 3) << 11) | ((green8 >> 2) << 5) | (blue8 >> 3))
  else
    return(-1)

PRI Rgb565_To_Red8(rgb565) : red8

  ' <Arguments> 
  ' rgb565:  RGB color value in 565 format.
  '
  ' Note that the 16 bit RGB color for the display is 2 bytes in 565 format i.e. R4R3R2R1R0G5G4G3G2G1G0B4B3B2B1B0, where msb=R4R3R2R1R0G5G4G3, lsb=G2G1G0B4B3B2B1B0.
  
  if ((NOT error_checking) OR (ValidData16(rgb565))) 
    red8 := ((rgb565 >> 11) & $1F) << 3
  else
    red8 := -1

PRI Rgb565_To_Green8(rgb565) : green8

  ' <Arguments> 
  ' rgb565:  RGB color value in 565 format.
  '
  ' Note that the 16 bit RGB color for the display is 2 bytes in 565 format i.e. R4R3R2R1R0G5G4G3G2G1G0B4B3B2B1B0, where msb=R4R3R2R1R0G5G4G3, lsb=G2G1G0B4B3B2B1B0.
  
  if ((NOT error_checking) OR (ValidData16(rgb565))) 
    green8 := ((rgb565 >> 5) & $3F) << 2
  else
    green8 := -1
    
PRI Rgb565_To_Blue8(rgb565) : blue8

  ' <Arguments> 
  ' rgb565:  RGB color value in 565 format.
  '
  ' Note that the 16 bit RGB color for the display is 2 bytes in 565 format i.e. R4R3R2R1R0G5G4G3G2G1G0B4B3B2B1B0, where msb=R4R3R2R1R0G5G4G3, lsb=G2G1G0B4B3B2B1B0.
  
  if ((NOT error_checking) OR (ValidData16(rgb565)))
    blue8 := (rgb565 & $1F) << 3
  else
    blue8 := -1

PRI ValidDisplayPixelsValue(value)

  return((value == DisplayPixelsOff) OR (value == DisplayPixelsOn))

PRI ValidDisplayContrastValue(value)

  return((value => DisplayContrastMin) AND (value =< DisplayContrastMax))

PRI ValidDisplayPowerValue(value)

  return((value == DisplayPowerOff) OR (value == DisplayPowerOn))

PRI ValidDisplaySleepMode(mode)

  return((mode == DisplaySleepModeTurnOffSD) OR (mode == DisplaySleepModeWakeOnJoystick) OR (mode == DisplaySleepModeWakeOnSerial))

PRI ValidJoystickGetOption(option)

  return((option == JoystickOptionReturnStatus) OR (option == JoystickOptionWaitForPressRel) OR (option == JoystickOptionWaitForPress) OR (option == JoystickOptionWaitForUpRel) OR (option == JoystickOptionWaitForLeftRel) OR (option == JoystickOptionWaitForDownRel) OR (option == JoystickOptionsWaitForRightRel) OR (option == JoystickOptionWaitForFireRel))

PRI ValidJoystickWaitOption(option)

  return((option == JoystickOptionWaitForPress) OR (option == JoystickOptionWaitForUpRel) OR (option == JoystickOptionWaitForLeftRel) OR (option == JoystickOptionWaitForDownRel) OR (option == JoystickOptionsWaitForRightRel) OR (option == JoystickOptionWaitForFireRel))
  
PRI ValidNote(note)

  return(((note => 0) AND (note =< 84)) OR ((note => 100) AND (note =< 20000)))
  
PRI ValidTuneLength(tune_length)

  return((tune_length > 0) AND (tune_length =< 64))
  
PRI ValidXY(x, y)

  return(((x => 0) AND (x =< GraphicsXMax)) AND ((y => 0) AND (y =< GraphicsYMax)))

PRI ValidWidthHeight(w, h)
  return(((w => 0) AND (w =< GraphicsPixelWidth)) AND ((h => 0) AND (h =< GraphicsPixelHeight)))

PRI ValidData8(data)
  return((data => 0) AND (data =< 255))

PRI ValidData16(data)
  return((data => 0) AND (data =< 65535))
  
PRI ValidBitmapIndex(char_idx)

  return((char_idx => 0) AND (char_idx =< GraphicsBitmapIndexMax))

PRI ValidBitmapData(data1, data2, data3, data4, data5, data6, data7, data8)

  return(ValidData8(data1) AND ValidData8(data2) AND ValidData8(data3) AND ValidData8(data4) AND ValidData8(data5) AND ValidData8(data6) AND ValidData8(data7) AND ValidData8(data8))

PRI ValidCircleRadius(x, y, radius) | rmax

  rmax := x <# (GraphicsXMax - x)
  rmax <#= y
  rmax <#= (GraphicsYMax - y) 
  return((radius > 0) AND (radius =< rmax))

PRI ValidTriangleVertices(x1, y1, x2, y2, x3, y3)

  return(ValidXY(x1, y1) AND ValidXY(x2, y2) AND ValidXY(x3, y3) AND (x1 => x2) AND (x3 => x2) AND (y2 => y1) AND (y3 > y1))

PRI ValidLineEndpoints(x1, y1, x2, y2)

  return(ValidXY(x1, y1) AND ValidXY(x2, y2))  

PRI ValidImageColorMode(mode)

  return((mode == GraphicsImageColorMode256) OR (mode == GraphicsImageColorMode65K))

PRI ValidPenMode(mode)

  return((mode == GraphicsPenModeSolid) OR (mode == GraphicsPenModeWireFrame))

PRI ValidTextAppearanceMode(mode)

  return((mode == TextAppearanceOpaque) OR (mode == TextAppearanceTransparent))

PRI ValidTextButtonState(state)

  return((state == TextButtonStateDown) OR (state == TextButtonStateUp))

PRI ValidTextFontSet(font_set)

  return((font_set == TextFontSet5x7) OR (font_set == TextFontSet8x8) OR (font_set == TextFontSet8x12))
  
PRI ValidChar(char)

  return((char => $20) AND (char =< $7F))

PRI ValidColRow(col, row, font_set)

  case font_set
    TextFontSet5x7:
      return((col => 0) AND (col =< 25) AND (row => 0) AND (row =< 15)) 
    TextFontSet8x8:
      return((col => 0) AND (col =< 19) AND (row => 0) AND (row =< 15)) 
    TextFontSet8x12:
      return((col => 0) AND (col =< 19) AND (row => 0) AND (row =< 9)) 
    other:
      return(FALSE)

PRI ValidDisplayScrollMode(mode)

  return((mode == DisplayScrollOff) OR (mode == DisplayScrollOn))

PRI ValidDisplayScrollDirection(dir)

  return((dir == DisplayScrollLeft) OR (dir == DisplayScrollRight))
    
PRI ValidDisplayScrollSpeed(speed)

  return((speed => DisplayScrollSpeedMin) AND (speed =< DisplayScrollSpeedMax))
    
PRI ValidMemCardMemAddr(mem_addr)

  return((mem_addr => 0) AND (mem_addr =< MemCardMemAddrMax))

PRI ValidMemCardSectorAddr(sector_addr)

  return((sector_addr => 0) AND (sector_addr =< MemCardSectorAddrMax))

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
  