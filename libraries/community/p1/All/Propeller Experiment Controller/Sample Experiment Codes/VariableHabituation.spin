{{

┌────────────────────────────────────────────┐
│ Variable Habituation                       │
│ Author: Christopher A Varnon               │
│ Created: 12-20-2012                        │
│ See end of file for terms of use.          │
└────────────────────────────────────────────┘

  This program will repeatedly present a stimulus. A response can be measured to detect habituation or sensitization to the stimulus.
  The stimulus duration, and the time between stimulus presentations can be variable.
  An optional mastery criterion is available that requires a fixed number of trials without any responses before the experiment ends.
  In case this criterion is never met, an 'escape' input is available to terminate the experiment at any time.

  The user will need to specify the pins used for the stimulus, response, escape input, house lights, and SD card.
  The user will also need to specify the minimum and maximum stimulus duration, the minimum and maximum inter-trial interval, the number of trials, and the mastery requirement.

  Comments and descriptions of the code are provided within brackets and following quotation marks.

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

  '' Replace the following values with whatever is desired for your experiment.
  '' Note that underscores are used in place of commas.
  '' The underscores are unnecessary and do not change the program, they only make the numbers easier to read.
  NumberOfTrials        = 15                                                    ' The number of initial trials.
  MasteryCriterion      = 5                                                     ' The number of consecutive trials without responding before the experiment ends. Set to 0 if no mastery criterion is required.
  StimulusDurationMin   = 500                                                   ' The minimum duration of the stimulus in milliseconds.
  StimulusDurationMax   = 1_000                                                 ' The maximum duration of the stimulus in milliseconds.
  InterTrialIntervalMin = 20_000                                                ' The minimum duration between stimulus presentations in milliseconds.
  InterTrialIntervalMax = 40_000                                                ' The maximum duration between stimulus presentations in milliseconds.

  '' Replace the following values with the pins connected to the devices.
  ResponsePin        = 6
  StimulusPin        = 23
  HouseLightPin      = 17                                                       ' The house lights will activate only while the experiment is running. Leave the pin disconnected if house lights control is not needed.
  DiagnosticLEDPin   = 16                                                       ' The LED will turn on after the experiment is complete and it is safe to remove the SD card. Leave the pin disconnected if a diagnostic LED is not needed.
  EscapePin          = 7

  '' Input Event States
  '' These states are named in the constant block to make the program more readable.
  Off     = 0                                                                   ' Off means that nothing is detected on an input.    Example: The rat is not pressing the lever.
  Onset   = 1                                                                   ' Onset means that the input was just activated.     Example: The rat just pressed the lever.
  On      = 2                                                                   ' On means that the input has been active a while.   Example: The rat pressed the lever recently and is still pressing it.
  Offset  = 3                                                                   ' Offset means that the input was just deactivated.  Example: The rat was pressing the lever, but it just stopped.

  '' Output Event States
  OutOn   = 1                                                                   ' The output is on.
  OutOff  = 3                                                                   ' The output is off.

VAR
  '' The VAR or Variable block is used to define variables that will change during the program.
  '' Variables are different from constants because variables can change, while constants cannot.
  '' The variables only be named in the variable space. They will be assigned values later.
  '' The size of a variable is also assigned in the VAR block.
  '' Byte variables can range from 0-255 and are best for values you know will be very small.
  '' Word variables are larger. They range from 0-65,535. Word variables can also be used to save the location of string (text) values in memory.
  '' Long variables are the largest and range from -2,147,483,648 to +2,147,483,647. Most variables experiments use will be longs.
  '' As there is limited space on the propeller chip, it is beneficial to use smaller sized variables when possible.
  '' It is unlikely that most experiments will use the entire memory of the propeller chip.

  word ResponseName                                                             ' This variable will refer to the text description of the response event that will be saved to the data file.
  word StimulusName                                                             ' This variable will refer to the text description of the stimulus event that will be saved to the data file.

  long Start                                                                    ' This variable will contain the starting time of the experiment. All other times will be compared to this time.
  long StimulusStart                                                            ' This variable will contain the starting time of each reinforcement. This is needed to know when to stop delivering the reinforcement.

  long StimulusDuration                                                         ' This variable will be used to contain the current stimulus duration.
  long InterTrialInterval                                                       ' This variable will be used to contain the current inter-trial interval.

  word Trial                                                                    ' This variable will refer to the number of trials that occurred.
  byte NewTrial                                                                 ' This variable will be used to note if a new trial just started. 1-new trial, 0-not a new trial.
  long TrialLength                                                              ' This variable will be used to determine the length of each trial.
  long TotalTrialLength                                                         ' This variable will refer to the combined length of all previous trials and the current trial.

  word MasteredTrials                                                           ' This variable will be used to record the number of consecutive trials without a response.
  byte Finished                                                                 ' This variable will be used to indicate if the experiment is complete.

OBJ
  '' The OBJ or Object block is used to declare objects that will be used by the program.
  '' These objects allow the current program to use code from other files.
  '' This keeps programs organized and makes it easier to share common code between multiple programs.
  '' Additionally, using objects written by others saves time and allows access to complicated functions that may be difficult to create.
  '' The objects are given short reference names. These abbreviations will be used to refer to code in the objects.

  '' The Experimental Functions object is the master object for experiments. It is responsible for keeping precise time, as well as saving data.
  exp : "Experimental_Functions"                                                ' Loads experimental functions.

  '' The Experimental Event object works in tandem with Experimental Functions.
  '' Each Experimental Event object is dedicated to keeping track of a specific event, and passing this information along to Experimental Functions.
  '' Each event in an experiment such as key pecks, stimulus lights, tones, and reinforcement uses its own experimental event object.
  Response      : "Experimental_Event"                                          ' Loads response as an experimental event.
  Escape        : "Experimental_Event"                                          ' Loads escape as an experimental event.
  Stimulus      : "Experimental_Event"                                          ' Loads reinforcement as an experimental event.
  HouseLight    : "Experimental_Event"                                          ' Loads houselight as an experimental event.

PUB Main
  '' The PUB or Public block is used to define code that can be used in a program or by other programs.
  '' The name listed after PUB is the name of the method.
  '' The program always starts with the first public method. Commonly this method is named "Main."
  '' The program will only run code in the first method unless it is explicitly told to go to another method.

  '' The statement "SetVariables" sets all the variables using a separate method. Scroll down to the SetVariables method to read the code.
  '' A separate method is not needed to set the variables, it can be done in the main method.
  '' However, dividing a program into sections can make it much easier to read.
  exp.startexperiment(DO,CLK,DI,CS)                                             ' Launches all the code in experimental functions related to timing and saving data. Also provides the SD card pins for saving data.
  SetVariables                                                                  ' Implements the setvariables method. Scroll down to read the code.
  houselight.turnon                                                             ' Turns on the house lights.
  start:=exp.time(0)                                                            ' Sets the variable 'start' to time(0) or the time since 0 - the present.
                                                                                ' In other words, the experiment started now.

  repeat until finished==1                                                      ' Repeats the indented code until some aspect of the experiment sets finished to 1.

    '' The next line of code is the basis for conducting experiments using experimental functions.
    '' When in a repeat loop, this code constantly checks the state of an input device.
    '' If anything has changed since the last time it checked, data is automatically recorded.
    '' In this way, the time of the onset and of the offset of every event can be recorded easily.
    exp.record(response.detect, response.ID, exp.time(start))                   ' Detect the state of the response device and record the state if it has changed.
    exp.record(escape.detect, escape.ID, exp.time(start))                       ' Detect the state of the escape button and record the state if it has changed.

    Contingencies                                                               ' Implements the contingencies method. Scroll down to read the code.

    '' This ends the main program loop. The loop will repeat until the session length is over, then drop down to the next line of code.

  '' The session has ended.
  if stimulus.state==OutOn                                                      ' If the stimulus is still occurring after the session ended.
    StopStimulus                                                                ' Stop the stimlus.

  houselight.turnoff                                                            ' Turns off the house lights.
  exp.stopexperiment                                                            ' Stop the experiment. This line is needed before saving data.

  exp.preparedataoutput                                                         ' Prepares a data.cvs file.
  exp.savedata(response.ID,responsename)                                        ' Sorts through memory for all occurrences of the response event and saves them to the data file.
  exp.savedata(stimulus.ID,stimulusname)                                        ' Sorts through memory for all occurrences of the stimulus event and saves them to the data file.
  exp.savedata(escape.ID,string("Experiment Manually Terminated"))              ' If the experiment was terminated with the escape key, a note is saved in the data file.

  exp.shutdown                                                                  ' Closes all the experiment code.

  dira[DiagnosticLEDPin]:=1                                                     ' Makes the diagnostic LED an output.
  repeat                                                                        ' The program enters an infinite repeat loop to flash the LED.
    !outa[DiagnosticLEDPin]                                                     ' Changes the state of the LED.
    waitcnt(clkfreq/10*5+cnt)                                                   ' Waits .5 seconds.
  ' When the LED starts flashing, it is safe to remove the SD card.

PUB SetVariables
  '' Sets up the experiment variables and events.

  responsename:=string("Response")                                              ' This sets the variable responsename to a string. Think of string as a "string of letters."
  stimulusname:=string("Stimulus")                                              ' The name of the stimulus.

  exp.startrealrandom                                                                 ' Activates the realrandom number generator to generate better random numbers.
  StimulusDuration:=exp.randomrange(StimulusDurationMin,StimulusDurationMax)          ' This code uses a method in experimental functions to determine the duration of the first stimulus.
  InterTrialInterval:=exp.randomrange(InterTrialIntervalMin,InterTrialIntervalMax)    ' This code uses a method in experimental functions to determine the first inter-trial interval.
  TrialLength:=StimulusDuration+InterTrialInterval                                    ' Determines the length of the first trial.
  TotalTrialLength+=TrialLength                                                       ' Adds the current trial length to the total trial length.
  newtrial:=1                                                                         ' New trial is set to 1 to indicate a new trial will be starting.
  trial:=1                                                                            ' The experiment starts with the first trial.

  '' The following lines use experimental event code to prepare the events.
  response.declareinput(responsepin,exp.clockID)                                ' This declares that the experimental event 'response' described in the OBJ section is an input on the response pin.
  escape.declareinput(escapepin,exp.clockID)                                    ' This declares that the experimental event 'escape' described in the OBJ section is an input on the escape pin.
  stimulus.declareoutput(stimuluspin,exp.clockID)                               ' This declares that the experimental event 'stimulus' described in the OBJ section is an output on the stimulus pin.
  houselight.declareoutput(houselightpin,exp.clockID)                           ' This declares that the experimental event 'houselight' described in the OBJ section is an output on the light pin.

PUB Contingencies
  '' The contingencies are implemented in a seperate method to increase readability.
  '' Note that the contingencies method is run every program cycle, immediately after the response device is checked.

  if newtrial==1                                                                ' If it is the start of a new trial.
    response.setcount(0)                                                        ' Reset the response count.
    startstimulus                                                               ' Start the stimulus. Scroll down to read the startstimulus method code.

  if stimulus.state==OutOn and stimulus.duration>stimulusduration               ' If the stimulus is on and the current duration (stimulus.duration) is greater than intended duration (stimulusduration).
    stopstimulus                                                                ' Stop the stimulus. Scroll down to read the stopstimulus method code.

  if exp.time(start)>totaltriallength                                           ' If the current time is greater than the combined length of the previous trials and current trial.
    newtrial:=1                                                                 ' Note that it will soon be the start of a new trial.
    trial+=1                                                                    ' Note that another trial has been completed.
    if response.count==0                                                        ' If no responses occurred during the previous trial.
      masteredtrials+=1                                                         ' Note that this trial may be used to meet the mastery criterion. Add 1 to mastered trials.
    else                                                                        ' If there were responses during the previous trial.
      masteredtrials:=0                                                         ' Reset the mastered trials.
    StimulusDuration:=exp.randomrange(StimulusDurationMin,StimulusDurationMax)          ' This code uses a method in experimental functions to determine the duration of the next stimulus.
    InterTrialInterval:=exp.randomrange(InterTrialIntervalMin,InterTrialIntervalMax)    ' This code uses a method in experimental functions to determine the next inter-trial interval.
    TrialLength:=StimulusDuration+InterTrialInterval                                    ' Determines the length of the next trial.
    TotalTrialLength+=TrialLength                                                       ' Adds the next trial length to the total trial length.

  if trial>numberoftrials                                                       ' If all initial trials are complete.
    if masterycriterion==0                                                      ' If no mastery criterion is desired.
      finished:=1                                                               ' Note that the experiment is complete.
    elseif masteredtrials=>masterycriterion                                     ' If enough trials have passed with no responses.
      finished:=1                                                               ' Note that the experiment is complete.

  if escape.count>0                                                             ' If the escape key is pressed.
    if stimulus.state==OutOn                                                    ' If the stimulus is on.
      stopstimulus                                                              ' Turn off the stimulus.
    finished:=1                                                                 ' Note that the experiment is complete.

PUB StartStimulus
  '' This method turns on the stimulus and records the onset.

  exp.record(stimulus.turnon, stimulus.ID, exp.time(start))                     ' Turns on and records that stimulus.
  stimulusstart:=exp.time(start)                                                ' Notes that stimulus started now.
  newtrial:=0                                                                   ' Set newtrial to zero to note that the trial has begun.

PUB StopStimulus
  '' This method turns off the stimulus and records the offset.

  exp.record(stimulus.turnoff, stimulus.ID, exp.time(start))                    ' Turns off and records the stimulus.
  stimulus.setduration(0)

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
