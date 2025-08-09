# dzScript
A shitty script to get PowerColor DevilZone to work in tandem with OpenRGB

**Do yourself a favor and just download the AHK file** if you are one of the 4 people on earth this script may help - the installer is just me having fun and figuring out how to make one.

## Why I made this

1. My PC is real bright.
2. I want to leave my PC running overnight for various reasons.
3. I want to save about 3 seconds by just pressing a button to turn off all the RGB instead of opening OpenRGB manually.
4. Oh and I have a PowerColor 5700XT GPU - unsupported by OpenRGB.

So I made this script that loads an OpenRGB profile with all the lights off + opens DevilZone and sets the color to black. 
Press the button again to turn it all on via another OpenRGB profile - fancy stuff!

You will have to use Window Spy and set the mouse position for where the Red value is in DevilZone and the Apply button. You will also have to add G and B values and mouse positions if you dont want it to be red.

## Releases

Do NOT Download the latest installer and binaries from the [Releases page](https://github.com/Nav-one/dzScript/releases) !

I am not sure if this even works yet.


## Notes

I spent around 4 hours on this + the installer to save me 3 seconds a night, meaning this project will break even in roughly 13 years.



You'll have to run the script as administrator and create some actions with Task Scheduler for this to work without all the annoying UAC popups.

If you look at the code you could probably figure it out, maybe not. I'll write the tutorial some other time lol

