# RWDebugHelper
Autohotkey (windows only) tool to help automate launching Rimworld in debug mode to debug mods.

The tool will attempt to automate the process of launching Rimworld, as well as swapping between stock and debug mono.dll files if enabled, and then connecting your IDE's debugger to the Rimworld process.

You will still need to do some work to get things setup from https://ludeon.com/forums/index.php?topic=25603.0
This takes the place of Steps 9, 10, and 11 (if following Xamarin) as well as Steps 8, 9, and 10 of the Visual Studio path.

NOTE: For now Visual Studio hasn't been coded, this only works for the Xamarin path.

Notes regarding Xamarin path:
-I couldn't get Xamarin to respond to most of the Autohotkey commands so I ended up using mouse clicks, color checks,and a little typing here and there.  I built this around Xamarin 6's default layout.
-I tried to do things so that screen resolution and weather or not Xamarin is windowed/fullscreen doesn't matter. If you have a screen resolution different from 1080p and/or running in windowed mode (with standard layout) doesn't work,put up an issue.


On first run the script will prompt you several times with different questions and information.
1st: Prompted for your IDE, select from drop down and hit OK.
2nd: A notice about the default hotkey and how to change it.  You may need to visit the following links to change this:
     https://autohotkey.com/docs/Hotkeys.htm#Symbols
     https://autohotkey.com/docs/KeyList.htm#Keyboard
3rd: A question asking if you want the tool to automatically swap between debug mono.dll and stock mono.dll.
--If enabled auto swaping in 3rd step--
4th: A dialog appears asking you to select Rimworld's mono.dll file.
5th: A question on if the dll you selected is the stock file or not.
   - If you select yes then you will be prompted for a new name for the backup.
    - The file will then be copied to the backup selected.
   - If you select no or cancel you will then be prompted for an already existing backup file for Rimworld's stock mono.dll.
    - If the file is named mono.dll you will be prompted for a backup name.
    - If the file is not located in the same directory as Rimworld's mono.dll it will be copied there.
6th: A question of if the dll you selected is the debug file or not.
   - prompts follow along the lines of step 5.
Finally: You will get a message stating that settings were written out along with the file name that they were stored.

If at any time one of the settings is changed to something invalid or something happens to a backup file, you may be prompted
along the lines of the above steps, otherwise subsequent runs will be ready for use.

To use, simply go to your IDE of choice and press the hotkey.  It will (attempt) to step through the process of rebuilding the project, then running Rimworld, and attaching your debugger to Rimworld.

If you've done all the other steps in the Ludeon forum link properly you are good to go.  Just have the IDE you selected in an earlier step active and press the hotkey as if this were built into the IDE.


Potential Issues:
If you've got a different layout for Xamarin than I do.  Different language shouldn't make THAT much difference but it could.
I detect the IDE being active based on filename so if your file is different from the IDE executable I used (ie Xamarin.exe) the hotkey won't fire.
When the hotkey fires it hides the key from the IDE so you may need to change hotkeys somewhere.
