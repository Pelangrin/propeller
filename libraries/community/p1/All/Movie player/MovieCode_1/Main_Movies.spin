{
Propeller Movie player by James Moxham, November, 2010
See also the vb.net program to create the movie files
}
CON

  _clkfreq = 80_000_000
  _clkmode = xtal1 + pll16x

  _clockDataPin = 29
  _clockClockPin = 28

  _cardDataOutPin = 12
  _cardClockPin = 13
  _cardDataInPin = 14
  _cardChipSelectPin = 15

  _pinGroup = 2
  _switchRate = 5

  ' Keyboard
  NUM        = %100
  CAPS       = %010
  SCROLL     = %001
  RepeatRate = 40

  MaxIcons = 15

OBJ

  pix: "VGA64_PIXEngine.spin"            ' thanks to Kye 160x120
  fat: "SD2.0_FATEngine.spin"            ' thanks to Kye
  kb : "keyboard"                 ' keyboard

VAR
  Word Key
  long i

PUB Main 

  ifnot(pix.PIXEngineStart(_pinGroup))
    reboot

  ifnot(fat.FATEngineStart(_cardDataOutPin, _cardClockPin, _cardDataInPin, _cardChipSelectPin, _clockDataPin, _clockClockPin))
    reboot
  fat.mountPartition(0,0)     ' mount the sd card

  kb.startx(26, 27, NUM, RepeatRate)                  'Start Keyboard Driver if required

  Wallpaper                     ' startup splash screen
  repeat i from 1 to 600000     ' delay for vga screen to warm up
  Movie(837)                    ' play n frames in the movie



PUB Wallpaper
    fat.openfile(string("prop160.vga"),"R")      ' 160x120
    fat.readdata(pix.displaypointer,19200)
    fat.closefile


  
PUB Movie(n) 
    fat.openfile(string("taz.pmv"),"R")      ' 160x120 per frame, saved as a binary file
    repeat i from 1 to n ' number of frames
      fat.readdata(pix.displaypointer,19200)
    fat.closefile
                       