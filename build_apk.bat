@echo off
echo ============================================
echo  Building Flutter Release APK
echo ============================================
cd flutter_app
flutter pub get
flutter build apk --release
echo.
echo APK built at:
echo flutter_app\build\app\outputs\flutter-apk\app-release.apk
echo.
pause
