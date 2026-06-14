@echo off
echo ============================================
echo  Running Flutter App - Windows Desktop
echo ============================================
echo NOTE: Developer Mode must be ON in Windows Settings
echo Go to: Settings - For developers - Developer Mode ON
echo.
cd flutter_app
flutter pub get
flutter run -d windows
pause
