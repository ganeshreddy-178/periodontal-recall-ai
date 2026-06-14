# API Documentation

Base URL: `http://localhost:5000/api`

All protected endpoints require:
```
Authorization: Bearer <access_token>
```

---

## Authentication

### POST /auth/register
Create a new dentist/staff account.

**Request Body:**
```json
{
  "full_name":   "Dr. Alice Smith",
  "email":       "alice@clinic.com",
  "password":    "SecurePass123",
  "role":        "dentist",
  "clinic_name": "SmileCare Dental"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Registration successful.",
  "data": {
    "user": { "id": 1, "full_name": "Dr. Alice Smith", ... },
    "access_token":  "eyJ...",
    "refresh_token": "eyJ..."
  }
}
```

---

### POST /auth/login
Authenticate and receive tokens.

**Request Body:**
```json
{ "email": "alice@clinic.com", "password": "SecurePass123" }
```

**Response (200):** Same structure as register.

---

### GET /auth/me *(Protected)*
Get the authenticated user's profile.

---

### PUT /auth/me *(Protected)*
Update profile fields.

**Request Body (any subset):**
```json
{ "full_name": "Dr. Alice S.", "clinic_name": "New Clinic", "phone": "9876543210" }
```

---

## Patients

### GET /patients/ *(Protected)*
List patients with pagination and search.

**Query Params:** `page`, `per_page`, `q` (search string)

**Response:**
```json
{
  "success": true,
  "data": [ { "id": 1, "full_name": "Jane Doe", "age": 38, ... } ],
  "pagination": { "total": 42, "page": 1, "per_page": 20, "pages": 3 }
}
```

---

### POST /patients/ *(Protected)*
Create a new patient.

**Required Fields:** `first_name`, `last_name`, `date_of_birth` (YYYY-MM-DD), `gender`

**Optional Fields:** `phone`, `email`, `address`, `smoking_status`, `diabetes_status`,
`family_history`, `previous_periodontal`, `additional_risk_factors`, `notes`

---

### PUT /patients/<id> *(Protected)*
Update patient record.

---

### DELETE /patients/<id> *(Protected)*
Soft-delete a patient (sets `is_active = false`).

---

### GET /patients/<id>/history *(Protected)*
Get patient with all their prediction history.

---

## Predictions

### POST /predict/ *(Protected)*
Run AI analysis — multipart/form-data.

**Form Fields:**
| Field                | Type   | Required | Range    |
|----------------------|--------|----------|----------|
| patient_id           | int    | Yes      | —        |
| plaque_index         | float  | Yes      | 0–3      |
| bleeding_on_probing  | float  | Yes      | 0–100%   |
| pocket_depth         | float  | Yes      | mm       |
| attachment_loss      | float  | Yes      | mm       |
| oral_hygiene_score   | float  | Yes      | 0–10     |
| image                | file   | No       | JPG/PNG  |

**Response (201):**
```json
{
  "success": true,
  "data": {
    "prediction": {
      "id": 1,
      "final_severity":  "moderate",
      "final_risk_level": "moderate",
      "final_confidence": 87.5,
      "cnn_severity":    "moderate",
      "cnn_confidence":  91.2,
      "clinical_risk_score": 58.0,
      "recall_interval_min": 3,
      "recall_interval_max": 6,
      "recommendations": "Scaling and root planing required..."
    },
    "reminder": {
      "due_date": "2026-10-09",
      "status": "pending"
    }
  }
}
```

---

## History

### GET /history/predictions *(Protected)*
List all predictions for the logged-in user.

**Query Params:** `page`, `per_page`, `severity` (filter)

---

### GET /history/reminders *(Protected)*
List recall reminders.

**Query Params:** `page`, `per_page`, `status` (pending/sent/acknowledged/overdue)

---

### PUT /history/reminders/<id> *(Protected)*
Update reminder status.

---

## Dashboard

### GET /dashboard/ *(Protected)*
Returns aggregate stats.

**Response:**
```json
{
  "total_patients": 48,
  "total_predictions": 112,
  "risk_distribution":  { "low": 30, "moderate": 15, "high": 3 },
  "severity_distribution": { "healthy": 25, "mild": 12, "moderate": 8, "severe": 3 },
  "recent_predictions": [...],
  "upcoming_reminders": [...]
}
```

---

### GET /dashboard/trends *(Protected)*
Monthly prediction counts (last 12 months).

---

## Health

### GET /health/
System health check (no auth required).

**Response:**
```json
{ "success": true, "data": { "status": "healthy", "database": "connected" } }
```
