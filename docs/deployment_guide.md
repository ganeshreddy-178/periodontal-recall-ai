# Deployment Guide

## Local Development

### Prerequisites
- Python 3.11+
- MySQL 8.0+
- Flutter 3.3+
- Docker (optional)

### Backend Setup

```bash
# 1. Clone repo, navigate to backend
cd backend

# 2. Create virtual environment
python -m venv venv
venv\Scripts\activate        # Windows
source venv/bin/activate     # Linux/Mac

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment
copy .env.example .env
# Edit .env with your MySQL credentials

# 5. Create database
mysql -u root -p -e "CREATE DATABASE periodontal_recall_ai CHARACTER SET utf8mb4;"

# 6. Run SQL schema
mysql -u root -p periodontal_recall_ai < ..\database\schema.sql

# 7. Start Flask
python run.py
```

---

## Docker Deployment (Recommended)

```bash
# From project root
cd docker

# Build and start all services
docker-compose up --build -d

# Check logs
docker-compose logs -f backend

# Stop services
docker-compose down
```

---

## Render Deployment

1. Push code to GitHub repository
2. Sign up at https://render.com
3. New Web Service → Connect GitHub repo
4. Render auto-detects `render.yaml`
5. Database provisioned automatically (free tier)
6. After deploy, run schema:
   ```bash
   render run "mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME < database/schema.sql"
   ```

---

## Railway Deployment

1. Install Railway CLI: `npm install -g @railway/cli`
2. `railway login`
3. `railway init`
4. `railway add mysql`  — provision MySQL
5. Set env vars:
   ```bash
   railway variables set FLASK_ENV=production SECRET_KEY=xxx JWT_SECRET_KEY=yyy
   ```
6. `railway up`

---

## Flutter APK Build Guide

### Debug APK
```bash
cd flutter_app
flutter pub get
flutter build apk --debug
```

### Release APK (signed)

1. Generate keystore:
   ```bash
   keytool -genkey -v -keystore periodontal.jks -keyalg RSA -keysize 2048 -validity 10000 -alias periodontal
   ```

2. Create `flutter_app/android/key.properties`:
   ```
   storePassword=your_store_password
   keyPassword=your_key_password
   keyAlias=periodontal
   storeFile=../../periodontal.jks
   ```

3. Update `flutter_app/android/app/build.gradle` to reference keystore.

4. Build:
   ```bash
   flutter build apk --release
   ```

APK location: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`

---

## Environment Variables Reference

| Variable          | Description                          | Example                    |
|-------------------|--------------------------------------|----------------------------|
| FLASK_ENV         | App environment                      | production                 |
| SECRET_KEY        | Flask session secret                 | random-64-char-string      |
| JWT_SECRET_KEY    | JWT signing key                      | random-64-char-string      |
| DB_HOST           | MySQL host                           | localhost                  |
| DB_PORT           | MySQL port                           | 3306                       |
| DB_USER           | MySQL username                       | app_user                   |
| DB_PASSWORD       | MySQL password                       | strong_password            |
| DB_NAME           | Database name                        | periodontal_recall_ai      |
| MODEL_PATH        | CNN model file path                  | ai_module/models_saved/... |
| UPLOAD_FOLDER     | Image upload directory               | uploads                    |
