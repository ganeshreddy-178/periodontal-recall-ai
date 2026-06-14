@echo off
cd /d "C:\Users\DELL\Documents\Project PDD\flutter_app"
echo Building APK...
flutter build apk --release > "C:\Users\DELL\Documents\Project PDD\apk_output.txt" 2>&1
echo Exit code: %ERRORLEVEL%
echo.
echo === Last 30 lines of output ===
powershell -Command "Get-Content 'C:\Users\DELL\Documents\Project PDD\apk_output.txt' | Select-Object -Last 30"
pause
