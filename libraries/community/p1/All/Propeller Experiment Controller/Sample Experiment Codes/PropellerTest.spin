{{

┌────────────────────────────────────────────┐
│ Propeller Test                             │
│ Author: Christopher A Varnon               │
│ Created: 12-20-2012                        │
│ See end of file for terms of use.          │
└────────────────────────────────────────────┘

  This program is designed to test the QuickStart and the connection to the SD card.
  All the QuickStart's LEDs will flash twice, then a test file will be written to the SD card, then all LEDs will flash twice again.
  If a QuickStart is not being used, the program can still test the SD card connection.
  If all connections are correct, a file called "TESTFILE.TXT" will be created containing the text:
        The SD card is connected properly!
        The Propeller is reading and writing files properly!

  The user will need to provide the SD card pins.

}}

CON
  '' This block of code is called the CONSTANT block. Here constants are defined that will never change during the program.
  '' The constant block is useful for defining constants that will be used often in the program. It can make the program much more readable.

  '' The following two lines set the clock mode.
  '' This enables the propeller to run quickly and accurately.
  '' Every experiment program will need to set the clock mode like this.
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  '' The following four constants are the SD card pins.
  '' Replace these values with the appropriate pin numbers for your device.
  DO  = 0
  CLK = 1
  DI  = 2
  CS  = 3

VAR
  '' The VAR or Variable block is used to define variables that will change during the program.
  '' Variables are different from constants because variables can change, while constants cannot.
  '' The variables only be named in the variable space. They will be assigned values later.
  '' The size of a variable is also assigned in the VAR block.
  '' Byte variables can range from 0-255 and are best for values you know will be very small.
  '' Word variables are larger. They range from 0-65,535. Word variables can also be used to save the location of string (text) values in memory.
  '' Long variables are the largest and range from -2,147,483,648 to +2,147,483,647. Most variables experiments use will be longs.
  '' As there is limited space on the propeller chip, it is beneficial to use smaller sized variables when possible.
  '' It is unlikely that an experiment will use the entire memory of the propeller chip.

  word ResponseName                                                             ' This variable will refer to the text description of the response event that will be saved to the data file.
  word ReinforcementName                                                        ' This variable will refer to the text description of the reinforcement event that will be saved to the data file.

  long Start                                                                    ' This variable will contain the starting time of the experiment. All other times will be compared to this time.
  long ReinforcementStart                                                       ' This variable will contain the starting time of each reinforcement. This is needed to know when to stop delivering the reinforcement.

OBJ
  '' The OBJ or Object block is used to declare objects that will be used by the program.
  '' These objects allow the current program to use code from other files.
  '' This keeps programs organized and makes it easier to share common code between multiple programs.
  '' Additionally, using objects written by others saves time and allows access to complicated functions that may be difficult to create.
  '' The objects are given short reference names. These abbreviations will be used to refer to code in the objects.

  SD : "EXP_FSRW"                                                                ' Loads the SD card object.

PUB Main | read, success
  '' The PUB or Public block is used to define code that can be used in a program or by other programs.
  '' The name listed after PUB is the name of the method.
  '' The program always starts with the first public method. Commonly this method is named "Main."
  '' The program will only run code in the first method unless it is explicitly told to go to another method.

  dira[16..23]:=%11111111                                                       ' Sets all the LEDs to outputs.
  repeat 4                                                                      ' Repeats the following code 4 times.
    !outa[16..23]                                                               ' Toggles the state of the LEDs.
    waitcnt(clkfreq/1000*500+cnt)                                               ' Waits .5 seconds.

  SD.mount_explicit(DO,CLK,DI,CS)                                               ' Mounts SD drive on declared pins.
  SD.popen(string("TestFile.txt"),"w")                                          ' Creates a test file and opens it for writing.
  SD.pputs(string("The SD card is connected properly!",13))                     ' Writes a message.
  SD.pclose                                                                     ' Closes the file.
  SD.popen(string("TestFile.txt"),"r")                                          ' Opens the test file for reading.
  success:=0                                                                    ' Set success to 0. Everything hasn't been tested yet.
  repeat 35                                                                     ' Read until the end of the file is reached.
    read:=SD.pgetc                                                              ' Reads the next character.
    success+=read                                                               ' Add the value of the character to success
  SD.pclose                                                                     ' Closes the file.
  SD.popen(string("TestFile.txt"),"a")                                          ' Opens the test file for writing again.
  if success==3116                                                              ' If all the characters were read correctly.
    SD.pputs(string("The Propeller is reading and writing files properly!"))    ' Write a message.
  SD.pclose                                                                     ' Closes the file.
  SD.unmount                                                                    ' Unmounts the SD card.
  waitcnt(clkfreq/1000*1000+cnt)                                                ' Waits 1 seconds.

  repeat 4                                                                      ' Repeats the following code 4 times.
    !outa[16..23]                                                               ' Toggles the state of the LEDs.
    waitcnt(clkfreq/1000*500+cnt)                                               ' Waits .5 seconds.

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
