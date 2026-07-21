# Periodontal Recall AI
### AI-Powered Smart Dental Risk Prediction & Personalized Recall Recommendation System

> Final-Year B.Tech Project | AI + Web + Mobile

---

## Project Overview

Periodontal Recall AI is a full-stack dental health platform that combines computer vision and clinical rule-based scoring to assist dentists in diagnosing periodontal disease and planning patient recall schedules.

**What it does:**

- **Classifies periodontal disease severity** from dental images using a VGG16 CNN (transfer learning) with CLAHE preprocessing
- **Scores clinical risk** from 10 demographic and clinical parameters using a weighted rule-based engine
- **Fuses both signals** via a multimodal engine (60% CNN + 40% clinical) to produce a final diagnosis
- **Generates personalized recall intervals** with tailored clinical recommendations
- **Provides a Flutter mobile app** for dentists to register patients, run AI assessments, and track recall reminders
- **Includes an admin panel** for user management and system-wide statistics

---

## Technology Stack

| Layer        | Technology                                              |
|--------------|---------------------------------------------------------|
| Backend      | Python 3.11, Flask 3.0, Flask-JWT-Extended, Flask-Migrate |
| Database     | MySQL 8 + SQLAlchemy ORM (PostgreSQL-compatible)        |
| AI / ML      | TensorFlow / Keras (VGG16), OpenCV, NumPy, Scikit-Learn |
| Mobile App   | Flutter 3.3+, Provider, Material 3, fl_chart            |
| Deployment   | Docker, Docker Compose, Render / Railway                |

---

## Project Structure

```
periodontal-recall-ai/
├── backend/
│   ├── app/
│   │   ├── api/                  # REST API blueprints
│   │   │   ├── auth.py           # Register, login, profile, change password
│   │   │   ├── forgot_password.py # OTP-based password reset (3-step)
│   │   │   ├── patients.py       # Patient CRUD
│   │   │   ├── predict.py        # AI prediction endpoint
│   │   │   ├── history.py        # Prediction & reminder history
│   │   │   ├── dashboard.py      # Stats + monthly trends
│   │   │   ├── admin.py          # User management (admin only)
│   │   │   └── health.py         # Health check
│   │   ├── models/               # SQLAlchemy ORM models
│   │   │   ├── user.py
│   │   │   ├── patient.py
│   │   │   ├── prediction.py
│   │   │   ├── reminder.py
│   │   │   ├── model_ver.py
│   │   │   └── audit.py
│   │   ├── services/
│   │   │   └── ai_service.py     # CNN inference + clinical scoring + fusion + recall
│   │   └── utils/
│   │       ├── responses.py      # Standardised JSON helpers
│   │       ├── validators.py     # Email, password, image-type validation
│   │       ├── rbac.py           # Role-based access control decorator
│   │       ├── audit.py          # Audit log helper
│   │       ├── otp.py            # OTP generation, storage, email sending
│   │       └── image_utils.py    # Image utilities
│   ├── ai_module/                # Standalone CNN training pipeline
│   │   ├── data_loader.py
│   │   ├── augmentation.py
│   │   ├── train.py
│   │   ├── evaluate.py
│   │   └── predict.py
│   ├── tests/                    # Pytest test suite
│   ├── migrations/               # Flask-Migrate Alembic scripts
│   ├── uploads/                  # Uploaded dental images (runtime)
│   ├── Dockerfile
│   ├── requirements.txt
│   └── run.py
├── flutter_app/
│   └── lib/
│       ├── screens/              # 14 app screens
│       ├── providers/            # Provider state management
│       ├── models/               # Dart data models
│       ├── services/             # API service layer (http)
│       ├── widgets/              # Reusable UI components
│       ├── theme/                # Material 3 theme
│       └── utils/                # Constants, helpers
├── database/
│   └── schema.sql                # Complete MySQL schema + seed data
├── docker/
│   └── docker-compose.yml        # MySQL 8 + Flask + Redis
├── docs/
│   ├── api_documentation.md
│   └── deployment_guide.md
└── README.md
```

---

## Quick Start

### Prerequisites

- Python 3.11+
- MySQL 8 (or use Docker)
- Flutter 3.3+ and Dart SDK
- Node.js (optional, for tooling)

---

### 1. Database Setup

```bash
mysql -u root -p < database/schema.sql
```

This creates the `periodontal_recall_ai` database with all tables and seeds the default model version record.

---

### 2. Backend

```bash
cd backend
cp .env.example .env
```

Edit `.env` with your credentials:

```env
FLASK_ENV=development
SECRET_KEY=your-secret-key
JWT_SECRET_KEY=your-jwt-secret

DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=periodontal_recall_ai

MODEL_PATH=ai_module/models_saved/periodontal_cnn_model.h5
UPLOAD_FOLDER=uploads
```

Install dependencies and run:

```bash
pip install -r requirements.txt
python run.py
```

API runs at: `http://localhost:5000`

> **Railway / Render deployment:** Set the `DATABASE_URL` or `MYSQL_URL` environment variable — the config auto-detects and switches database drivers.

---

### 3. AI Model Training

```bash
cd backend/ai_module
python train.py --dataset /path/to/dataset --epochs 50
```

Expected dataset structure:

```
dataset/
  train/
    healthy/
    mild/
    moderate/
    severe/
  val/
    ...
  test/
    ...
```

The trained model is saved to `ai_module/models_saved/periodontal_cnn_model.h5`.

> **Without a trained model:** The backend runs in *dummy mode*, returning deterministic pseudo-predictions based on the image filename hash. All other features work normally.

---

### 4. Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

Update `lib/utils/constants.dart` with your backend IP/URL:

```dart
// Android on same WiFi
return 'http://192.168.x.x:5000/api';

// Web / emulator
return 'http://localhost:5000/api';
```

Build a release APK:

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## API Reference

All protected endpoints require the `Authorization: Bearer <access_token>` header.

### Authentication

| Method | Endpoint                      | Auth | Description                        |
|--------|-------------------------------|------|------------------------------------|
| POST   | `/api/auth/register`          | —    | Register new user                  |
| POST   | `/api/auth/login`             | —    | Login, returns JWT pair            |
| POST   | `/api/auth/refresh`           | JWT (refresh) | Get new access token      |
| GET    | `/api/auth/me`                | JWT  | Get current user profile           |
| PUT    | `/api/auth/me`                | JWT  | Update profile                     |
| POST   | `/api/auth/change-password`   | JWT  | Change password                    |

### Forgot Password (3-step OTP flow)

| Method | Endpoint                      | Auth | Description                        |
|--------|-------------------------------|------|------------------------------------|
| POST   | `/api/auth/request-otp`       | —    | Send OTP to email                  |
| POST   | `/api/auth/verify-otp`        | —    | Verify OTP, get reset token        |
| POST   | `/api/auth/reset-password`    | —    | Set new password with reset token  |

### Patients

| Method | Endpoint                      | Auth | Description                        |
|--------|-------------------------------|------|------------------------------------|
| GET    | `/api/patients/`              | JWT  | List all patients (paginated)      |
| POST   | `/api/patients/`              | JWT  | Create patient                     |
| GET    | `/api/patients/<id>`          | JWT  | Get patient detail                 |
| PUT    | `/api/patients/<id>`          | JWT  | Update patient                     |
| DELETE | `/api/patients/<id>`          | JWT  | Soft-delete patient                |
| GET    | `/api/patients/<id>/history`  | JWT  | Patient prediction history         |

### AI Prediction

| Method | Endpoint                      | Auth | Description                                         |
|--------|-------------------------------|------|-----------------------------------------------------|
| POST   | `/api/predict/`               | JWT  | Run AI assessment (`multipart/form-data`)           |
| GET    | `/api/predict/<id>`           | JWT  | Get single prediction result                        |

**Prediction request fields** (`multipart/form-data`):

| Field                | Type    | Required | Notes                |
|----------------------|---------|----------|----------------------|
| `patient_id`         | int     | Yes      |                      |
| `plaque_index`       | float   | Yes      | 0–3 scale            |
| `bleeding_on_probing`| float   | Yes      | Percentage 0–100     |
| `pocket_depth`       | float   | Yes      | mm average           |
| `attachment_loss`    | float   | Yes      | mm average           |
| `oral_hygiene_score` | float   | Yes      | 0–10 scale           |
| `image`              | file    | No       | JPG / JPEG / PNG     |

### History

| Method | Endpoint                            | Auth | Description                            |
|--------|-------------------------------------|------|----------------------------------------|
| GET    | `/api/history/predictions`          | JWT  | List predictions (filterable, paged)   |
| GET    | `/api/history/reminders`            | JWT  | List recall reminders (filterable)     |
| PUT    | `/api/history/reminders/<id>`       | JWT  | Update reminder status / notes         |

### Dashboard

| Method | Endpoint                      | Auth | Description                             |
|--------|-------------------------------|------|-----------------------------------------|
| GET    | `/api/dashboard/`             | JWT  | Overview stats + recent items           |
| GET    | `/api/dashboard/trends`       | JWT  | Monthly prediction counts (12 months)   |

### Admin *(role: admin only)*

| Method | Endpoint                         | Auth        | Description              |
|--------|----------------------------------|-------------|--------------------------|
| GET    | `/api/admin/users`               | JWT + admin | List all users           |
| GET    | `/api/admin/stats`               | JWT + admin | System-wide statistics   |
| PUT    | `/api/admin/users/<id>/role`     | JWT + admin | Change user role         |
| DELETE | `/api/admin/users/<id>`          | JWT + admin | Soft-deactivate user     |

### Health

| Method | Endpoint          | Auth | Description |
|--------|-------------------|------|-------------|
| GET    | `/api/health/`    | —    | Health check |

---

## AI Module

### Disease Classification (CNN)

| Property      | Detail                                              |
|---------------|-----------------------------------------------------|
| Architecture  | VGG16 (ImageNet weights) + custom classification head |
| Input size    | 224 × 224 RGB                                       |
| Output        | Softmax over 4 classes                              |
| Classes       | Healthy · Mild · Moderate · Severe Periodontitis    |
| Preprocessing | Resize → CLAHE (LAB L-channel) → Fast NL Denoise → Normalize [0,1] |

### Clinical Risk Scoring (Rule-Based, 0–100 pts)

| Parameter              | Max Points |
|------------------------|------------|
| Age                    | 10 pts     |
| Plaque Index (0–3)     | 15 pts     |
| Bleeding on Probing (%) | 15 pts    |
| Pocket Depth (mm avg)  | 15 pts     |
| Attachment Loss (mm avg)| 15 pts    |
| Oral Hygiene Score (inverted) | 10 pts |
| Smoking Status         | 10 pts     |
| Diabetes Status        | 8 pts      |
| Family History         | 5 pts      |
| Previous Periodontal Tx| 7 pts      |
| **Total**              | **110 pts (capped at 100)** |

Risk levels: Low < 30 · Moderate 30–64 · High ≥ 65

### Multimodal Fusion

```
Final Score = CNN Severity Index × 0.60 + Clinical Severity Index × 0.40
```

If no image is provided, the system falls back to clinical-only scoring. The final risk level is escalated to *high* if the clinical engine independently scores high, regardless of CNN result.

### Recall Rules

| Final Severity | Recall Interval | Action Summary                                         |
|----------------|-----------------|--------------------------------------------------------|
| Healthy        | 6–12 months     | Maintain routine hygiene; standard recall              |
| Mild           | 6 months        | Professional cleaning; improve home care               |
| Moderate       | 3–6 months      | Scaling & root planing; address systemic risk factors  |
| Severe         | 1–3 months      | Immediate specialist referral; surgical evaluation     |

A `recall_reminders` record is automatically created after each prediction.

---

## Flutter App Screens

| Screen               | Description                                              |
|----------------------|----------------------------------------------------------|
| `SplashScreen`       | Launch / brand screen with auth routing                  |
| `LoginScreen`        | Email + password login                                   |
| `RegisterScreen`     | New account creation                                     |
| `ForgotPasswordScreen` | 3-step OTP-based password reset                        |
| `HomeScreen`         | App shell with bottom navigation                         |
| `DashboardScreen`    | Stats cards + risk distribution chart + recent activity  |
| `PatientsScreen`     | Searchable patient list                                  |
| `PatientFormScreen`  | Add / edit patient with clinical fields                  |
| `ImageUploadScreen`  | Camera / gallery image picker before assessment          |
| `ResultsScreen`      | Full AI diagnosis display with recall recommendation     |
| `HistoryScreen`      | Paginated prediction and reminder history                |
| `ProfileScreen`      | User profile + password change                           |
| `SettingsScreen`     | App preferences                                          |
| `AdminScreen`        | User list + system stats (admin role only)               |

**State management:** Provider with four providers — `AuthProvider`, `PatientProvider`, `PredictionProvider`, `DashboardProvider`.

**Key packages:**

| Package                 | Purpose                    |
|-------------------------|----------------------------|
| `provider ^6.1.2`       | State management           |
| `http ^1.2.1`           | REST API calls             |
| `flutter_secure_storage`| JWT token persistence      |
| `image_picker ^1.1.2`   | Camera / gallery access    |
| `fl_chart ^0.67.0`      | Risk distribution charts   |
| `google_fonts ^6.2.1`   | Typography                 |
| `intl ^0.19.0`          | Date formatting            |

---

## Database Schema

Six tables — all InnoDB, `utf8mb4`:

| Table             | Purpose                                           |
|-------------------|---------------------------------------------------|
| `users`           | Dentist / staff / admin accounts                  |
| `patients`        | Patient demographics + risk factor flags          |
| `predictions`     | Full AI assessment results (clinical + CNN + fused) |
| `recall_reminders`| Scheduled recall dates with status tracking       |
| `model_versions`  | Trained model registry with accuracy metadata     |
| `audit_logs`      | JSON-detail audit trail for all user actions      |

---

## Docker Deployment

```bash
cd docker
docker-compose up --build
```

Three services:

| Service    | Image          | Port | Notes                           |
|------------|----------------|------|---------------------------------|
| `db`       | mysql:8.0      | 3306 | Health-checked; schema auto-imported |
| `backend`  | (built)        | 5000 | Waits for db health check       |
| `redis`    | redis:7-alpine | 6379 | Optional — rate limiting / async |

Model files and uploads are persisted via named Docker volumes.

---

## Deploy to Render / Railway

### Render

1. Push repo to GitHub
2. Connect repo at [render.com](https://render.com)
3. `render.yaml` auto-configures the web service and managed database
4. Set `SECRET_KEY`, `JWT_SECRET_KEY`, and `DATABASE_URL` in the Render dashboard

### Railway

1. Create a new project and add a MySQL plugin
2. Set `MYSQL_URL` — the config layer auto-detects it and builds the correct SQLAlchemy URI
3. Deploy the `backend/` directory

---

## Running Tests

```bash
cd backend
pytest tests/ -v
```

Test modules:

| File                  | Coverage area                          |
|-----------------------|----------------------------------------|
| `test_health.py`      | Health check endpoint                  |
| `test_auth.py`        | Register, login, JWT flows             |
| `test_patients.py`    | Patient CRUD                           |
| `test_ai_service.py`  | Clinical scoring + fusion + recall     |

---

## Environment Variables Reference

| Variable              | Default                        | Description                          |
|-----------------------|--------------------------------|--------------------------------------|
| `FLASK_ENV`           | `development`                  | `development` / `production` / `testing` |
| `SECRET_KEY`          | `dev-secret-key-...`           | Flask session secret                 |
| `JWT_SECRET_KEY`      | `dev-jwt-secret-...`           | JWT signing key                      |
| `DB_HOST`             | `localhost`                    | MySQL host                           |
| `DB_PORT`             | `3306`                         | MySQL port                           |
| `DB_USER`             | `root`                         | MySQL user                           |
| `DB_PASSWORD`         | —                              | MySQL password                       |
| `DB_NAME`             | `periodontal_recall_ai`        | Database name                        |
| `DATABASE_URL`        | —                              | Railway/Render PostgreSQL URL (overrides above) |
| `MYSQL_URL`           | —                              | Railway MySQL URL (overrides DB_* vars) |
| `MODEL_PATH`          | `ai_module/models_saved/...h5` | Path to trained Keras model          |
| `UPLOAD_FOLDER`       | `uploads`                      | Image upload directory               |
| `MAX_CONTENT_LENGTH`  | `16777216`                     | Max upload size (bytes, default 16 MB) |
| `REDIS_URL`           | `redis://localhost:6379/0`     | Redis URL (optional)                 |

---

## Roles & Permissions

| Role      | Capabilities                                                  |
|-----------|---------------------------------------------------------------|
| `dentist` | Manage own patients, run predictions, view own history        |
| `staff`   | Same as dentist                                               |
| `admin`   | All of the above + list all users, change roles, deactivate accounts, system stats |

---

## License

MIT License — Final Year B.Tech Project
