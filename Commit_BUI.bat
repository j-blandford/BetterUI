cd "%USERPROFILE%\Documents\Elder Scrolls Online\liveeu\AddOns"
xcopy BetterUI "%USERPROFILE%\Documents\GitHub\BetterUI\BetterUI\" /O /X /E /H /K
"%PROGRAMFILES%\WinRAR\rar.exe" a -r -inul BetterUI.zip BetterUI\
move /y BetterUI.zip "%USERPROFILE%\Desktop\BetterUI.zip"
pause