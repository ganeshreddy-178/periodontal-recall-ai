@echo off
echo ============================================
echo  Running Flutter App - Android
echo ============================================
cd flutter_app
flutter pub get
flutter run -d android
pause
