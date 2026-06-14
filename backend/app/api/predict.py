"""Prediction endpoint - image + clinical → AI analysis."""
import os
import uuid
import time
from flask import Blueprint, request, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.utils import secure_filename

from ..extensions import db
from ..models.patient import Patient
from ..models.prediction import Prediction
from ..models.reminder import RecallReminder
from ..models.model_ver import ModelVersion
from ..utils.responses import success, error
from ..utils.audit import log_action
from ..utils.validators import allowed_image
from ..services.ai_service import AIService

predict_bp = Blueprint("predict", __name__)
_ai = None  # lazy singleton


def get_ai():
    global _ai
    if _ai is None:
        _ai = AIService()
    return _ai


@predict_bp.post("/")
@jwt_required()
def predict():
    uid = int(get_jwt_identity())
    t0  = time.time()

    # ------------------------------------------------------------------
    # 1. Parse form fields
    # ------------------------------------------------------------------
    patient_id = request.form.get("patient_id")
    if not patient_id:
        return error("patient_id is required.")

    patient = Patient.query.filter_by(id=int(patient_id), user_id=uid, is_active=True).first()
    if not patient:
        return error("Patient not found.", 404)

    try:
        clinical = {
            "age":                 patient.age,
            "plaque_index":        float(request.form.get("plaque_index",        0)),
            "bleeding_on_probing": float(request.form.get("bleeding_on_probing", 0)),
            "pocket_depth":        float(request.form.get("pocket_depth",        0)),
            "attachment_loss":     float(request.form.get("attachment_loss",     0)),
            "oral_hygiene_score":  float(request.form.get("oral_hygiene_score",  5)),
            "smoking_status":      patient.smoking_status,
            "diabetes_status":     patient.diabetes_status,
            "family_history":      patient.family_history,
            "previous_periodontal": patient.previous_periodontal,
        }
    except ValueError:
        return error("Invalid numeric clinical parameter.")

    # ------------------------------------------------------------------
    # 2. Handle image upload (optional)
    # ------------------------------------------------------------------
    image_path     = None
    image_filename = None
    cnn_severity   = None
    cnn_confidence = None

    if "image" in request.files:
        img_file = request.files["image"]
        if img_file.filename and allowed_image(img_file.filename):
            safe    = secure_filename(img_file.filename)
            ext     = safe.rsplit(".", 1)[-1].lower()
            fname   = f"{uuid.uuid4().hex}.{ext}"
            upload_root = os.path.join(current_app.root_path, "..",
                                       current_app.config["UPLOAD_FOLDER"])
            os.makedirs(upload_root, exist_ok=True)
            full_path = os.path.join(upload_root, fname)
            img_file.save(full_path)
            image_path     = full_path
            image_filename = fname

            # CNN prediction
            cnn_result   = get_ai().predict_image(full_path)
            cnn_severity = cnn_result["severity"]
            cnn_confidence = cnn_result["confidence"]
        else:
            return error("Unsupported image format. Use JPG, JPEG or PNG.")

    # ------------------------------------------------------------------
    # 3. Clinical risk scoring
    # ------------------------------------------------------------------
    clinical_result = get_ai().clinical_risk_score(clinical)

    # ------------------------------------------------------------------
    # 4. Multimodal fusion
    # ------------------------------------------------------------------
    fusion = get_ai().fuse(cnn_severity, cnn_confidence, clinical_result)

    # ------------------------------------------------------------------
    # 5. Recall recommendation
    # ------------------------------------------------------------------
    recall = get_ai().recall_recommendation(fusion["final_severity"])

    # ------------------------------------------------------------------
    # 6. Persist
    # ------------------------------------------------------------------
    mv = ModelVersion.query.filter_by(is_active=True).first()

    pred = Prediction(
        patient_id           = patient.id,
        user_id              = uid,
        age                  = clinical["age"],
        plaque_index         = clinical["plaque_index"],
        bleeding_on_probing  = clinical["bleeding_on_probing"],
        pocket_depth         = clinical["pocket_depth"],
        attachment_loss      = clinical["attachment_loss"],
        oral_hygiene_score   = clinical["oral_hygiene_score"],
        image_path           = image_path,
        image_filename       = image_filename,
        cnn_severity         = cnn_severity,
        cnn_confidence       = cnn_confidence,
        clinical_risk_score  = clinical_result["score"],
        clinical_risk_level  = clinical_result["level"],
        final_severity       = fusion["final_severity"],
        final_risk_level     = fusion["final_risk_level"],
        final_confidence     = fusion["final_confidence"],
        recall_interval_min  = recall["min_months"],
        recall_interval_max  = recall["max_months"],
        recommendations      = recall["recommendations"],
        model_version_id     = mv.id if mv else None,
        processing_time_ms   = int((time.time() - t0) * 1000),
    )
    db.session.add(pred)
    db.session.flush()

    # Schedule recall reminder
    from datetime import date, timedelta
    due_months = (recall["min_months"] + recall["max_months"]) // 2
    due_date   = date.today() + timedelta(days=due_months * 30)
    reminder   = RecallReminder(
        patient_id    = patient.id,
        prediction_id = pred.id,
        due_date      = due_date,
        notes         = f"Recall due based on {fusion['final_severity']} periodontitis assessment.",
    )
    db.session.add(reminder)
    db.session.commit()

    log_action(uid, "prediction.create", "predictions", pred.id)
    return success({
        "prediction": pred.to_dict(),
        "reminder":   reminder.to_dict(),
    }, "Prediction complete.", 201)


@predict_bp.get("/<int:pred_id>")
@jwt_required()
def get_prediction(pred_id: int):
    uid  = int(get_jwt_identity())
    pred = Prediction.query.filter_by(id=pred_id, user_id=uid).first()
    if not pred:
        return error("Prediction not found.", 404)
    return success(pred.to_dict())
