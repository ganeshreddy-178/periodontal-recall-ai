@echo off
echo ============================================
echo  Installing Python Backend Packages
echo ============================================
cd backend
call venv\Scripts\activate.bat
pip install flask flask-jwt-extended flask-sqlalchemy flask-migrate flask-cors pymysql bcrypt python-dotenv Pillow numpy opencv-python-headless scikit-learn gunicorn marshmallow werkzeug
echo.
echo All packages installed!
pause
