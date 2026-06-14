    # Periodontal Recall AI
### AI-Powered Smart Dental Risk Prediction & Personalized Recall Recommendation System

> Final-Year B.Tech Project | AI + Web + Mobile

---

## Project Overview

Periodontal Recall AI is a complete AI-powered dental health platform that:

- **Classifies periodontal disease severity** from dental images using a CNN (VGG16 transfer learning)
- **Scores clinical risk** using a rule-based engine across 12 clinical & demographic parameters
- **Fuses both** via a multimodal engine (60% CNN + 40% clinical) for a final diagnosis
- **Generates personalized recall intervals** with tailored clinical recommendations
- **Provides a Flutter mobile app** for dentists to manage patients and view AI results

---

## Technology Stack

| Layer        | Technology                                    |
|--------------|-----------------------------------------------|
| Backend      | Python 3.11, Flask 3.0, Flask-JWT-Extended   |
| Database     | MySQL 8 + SQLAlchemy ORM                     |
| AI / ML      | TensorFlow 2.16, Keras, OpenCV, Scikit-Learn |
| Mobile App   | Flutter 3, Provider, Material 3              |
| Deployment   | Docker, Docker Compose, Render / Railway     |

---

## Project Structure

```
periodontal-recall-ai/
├── backend/
│   ├── app/
│   │   ├── api/          # REST API blueprints
│   │   ├── models/       # SQLAlchemy models
│   │   ├── services/     # AI service (inference + scoring)
│   │   └── utils/        # Helpers, validators, responses
│   ├── ai_module/        # CNN training pipeline
│   │   ├── data_loader.py
│   │   ├── augmentation.py
│   │   ├── train.py
│   │   ├── evaluate.py
│   │   └── predict.py
│   ├── tests/            # Pytest test suite
│   ├── Dockerfile
│   └── requirements.txt
├── database/
│   └── schema.sql        # Complete MySQL schema
├── flutter_app/          # Flutter mobile application
│   └── lib/
│       ├── screens/      # All 10 app screens
│       ├── providers/    # State management
│       ├── models/       # Data models
│       ├── services/     # API service layer
│       └── theme/        # Material 3 theme
├── docker/
│   └── docker-compose.yml
├── render.yaml           # Render deployment config
└── docs/                 # Documentation
```

---

## Quick Start

### 1. Database

```sql
mysql -u root -p < database/schema.sql
```

### 2. Backend

```bash
cd backend
cp .env.example .env          # fill in your DB credentials
pip install -r requirements.txt
flask db upgrade               # if using migrations
python run.py
```

API runs at: `http://localhost:5000`

### 3. AI Model Training

```bash
cd backend/ai_module
python train.py --dataset /path/to/dataset --epochs 50
```

Dataset structure:
```
dataset/
  train/  healthy/  mild/  moderate/  severe/
  val/    ...
  test/   ...
```

### 4. Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

Update `lib/utils/constants.dart` with your backend URL.

---

## API Endpoints

| Method | Endpoint                          | Description              |
|--------|-----------------------------------|--------------------------|
| POST   | `/api/auth/register`              | Register user            |
| POST   | `/api/auth/login`                 | Login                    |
| GET    | `/api/auth/me`                    | Get profile              |
| GET    | `/api/patients/`                  | List patients            |
| POST   | `/api/patients/`                  | Create patient           |
| PUT    | `/api/patients/<id>`              | Update patient           |
| DELETE | `/api/patients/<id>`              | Delete patient           |
| GET    | `/api/patients/<id>/history`      | Patient history          |
| POST   | `/api/predict/`                   | Run AI prediction        |
| GET    | `/api/history/predictions`        | Prediction history       |
| GET    | `/api/history/reminders`          | Recall reminders         |
| GET    | `/api/dashboard/`                 | Dashboard stats          |
| GET    | `/api/dashboard/trends`           | Monthly trends           |
| GET    | `/api/health/`                    | Health check             |

---

## AI Module

### Disease Classification (CNN)
- Architecture: VGG16 (transfer learning) + custom head
- Input: 224×224 RGB dental images
- Classes: Healthy, Mild, Moderate, Severe Periodontitis
- Preprocessing: Resize → CLAHE → Denoise → Normalize

### Clinical Risk Scoring (Rule-Based)
| Parameter         | Weight  |
|-------------------|---------|
| Age               | 10 pts  |
| Plaque Index      | 15 pts  |
| Bleeding on Probing | 15 pts |
| Pocket Depth      | 15 pts  |
| Attachment Loss   | 15 pts  |
| Oral Hygiene Score | 10 pts |
| Smoking Status    | 10 pts  |
| Diabetes Status   | 8 pts   |
| Family History    | 5 pts   |
| Previous Perio    | 7 pts   |

### Multimodal Fusion
```
Final Score = CNN Result × 0.60 + Clinical Risk × 0.40
```

### Recall Rules
| Severity  | Recall Interval  |
|-----------|-----------------|
| Healthy   | 6–12 months     |
| Mild      | 6 months        |
| Moderate  | 3–6 months      |
| Severe    | 1–3 months      |

---

## Docker Deployment

```bash
cd docker
docker-compose up --build
```

Services:
- MySQL 8 on port 3306
- Flask API on port 5000
- Redis on port 6379

---

## Deploy to Render

1. Push repo to GitHub
2. Connect to [render.com](https://render.com)
3. `render.yaml` auto-configures web service + managed database

---

## Flutter APK Build

```bash
cd flutter_app
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

---

## Running Tests

```bash
cd backend
pytest tests/ -v
```

---

## Screenshots

| Splash | Dashboard | Patients | Results |
|--------|-----------|----------|---------|
| Login/brand screen | Stats + charts | Patient list + search | AI diagnosis + recall |

---

## License

MIT License — Final Year B.Tech Project
