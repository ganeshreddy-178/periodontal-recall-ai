# How To Run — Periodontal Recall AI

## STEP 1 — Setup Database (run once)

Double-click: `setup_database.bat`

Enter your MySQL root password when asked.
This creates the database and imports all tables.

---

## STEP 2 — Install Python Packages (run once)

Double-click: `install_packages.bat`

This installs all Flask/AI packages inside the virtual environment.

---

## STEP 3 — Start Backend API

Double-click: `start_backend.bat`

Backend runs at: http://localhost:5000
Health check: http://localhost:5000/api/health/

Keep this window open while using the app.

---

## STEP 4 — Run Flutter App

### Android (connect phone or start emulator first):
Double-click: `run_flutter_android.bat`

### Windows Desktop:
1. Enable Developer Mode:
   - Press Win+I → Search "Developer" → For developers → Toggle ON
2. Double-click: `run_flutter_windows.bat`

---

## STEP 5 — Build Release Versions

### Android APK:
Double-click: `build_apk.bat`
Output: `flutter_app\build\app\outputs\flutter-apk\app-release.apk`

### Windows EXE:
Double-click: `build_windows_exe.bat`
Output: `flutter_app\build\windows\x64\runner\Release\periodontal_recall_ai.exe`

---

## Project Status

| Component         | Status  |
|-------------------|---------|
| MySQL Database    | Ready   |
| Flask Backend     | Ready   |
| AI Service        | Ready   |
| Flutter Android   | Ready   |
| Flutter Windows   | Ready * |
| Docker            | Ready   |
| Render Deployment | Ready   |

* Windows needs Developer Mode ON in Windows Settings

---

## API Base URL
- Local: http://localhost:5000/api
- Change in: flutter_app/lib/utils/constants.dart
