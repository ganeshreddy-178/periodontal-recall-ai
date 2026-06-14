@echo off
echo ============================================
echo  Starting Periodontal Recall AI Backend
echo ============================================
cd backend
call venv\Scripts\activate.bat
echo Backend starting at http://localhost:5000
python run.py
pause
