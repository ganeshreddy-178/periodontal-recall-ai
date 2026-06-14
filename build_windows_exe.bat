@echo off
echo ============================================
echo  Building Flutter Windows Desktop EXE
echo ============================================
echo NOTE: Developer Mode must be ON
echo.
cd flutter_app
flutter pub get
flutter build windows --release
echo.
echo EXE built at:
echo flutter_app\build\windows\x64\runner\Release\periodontal_recall_ai.exe
echo.
pause
