@echo off
echo ============================================
echo  Periodontal Recall AI - Database Setup
echo ============================================

set /p MYSQL_PASS=Enter your MySQL root password: 

echo Creating database...
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p%MYSQL_PASS% -e "CREATE DATABASE IF NOT EXISTS periodontal_recall_ai CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Could not connect to MySQL. Check your password.
    pause
    exit /b 1
)

echo Importing schema...
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p%MYSQL_PASS% periodontal_recall_ai < database\schema.sql

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Schema import failed.
    pause
    exit /b 1
)

echo.
echo Database setup complete!
echo Updating .env with your password...

powershell -Command "(Get-Content 'backend\.env') -replace 'DB_PASSWORD=root', 'DB_PASSWORD=%MYSQL_PASS%' | Set-Content 'backend\.env'"

echo .env updated.
echo.
pause
