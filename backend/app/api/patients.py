"""Patient CRUD endpoints."""
from datetime import date
from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from sqlalchemy import or_

from ..extensions import db
from ..models.patient import Patient
from ..models.user import User
from ..utils.responses import success, error, paginated
from ..utils.audit import log_action

patients_bp = Blueprint("patients", __name__)


def _parse_date(s: str):
    try:
        return date.fromisoformat(s)
    except Exception:
        return None


@patients_bp.post("/")
@jwt_required()
def create_patient():
    uid  = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}

    required = ["first_name", "last_name", "date_of_birth", "gender"]
    missing  = [f for f in required if not data.get(f)]
    if missing:
        return error(f"Missing required fields: {', '.join(missing)}")

    dob = _parse_date(data["date_of_birth"])
    if not dob:
        return error("Invalid date_of_birth. Use YYYY-MM-DD format.")

    patient = Patient(
        user_id                 = uid,
        first_name              = data["first_name"].strip(),
        last_name               = data["last_name"].strip(),
        date_of_birth           = dob,
        gender                  = data["gender"],
        phone                   = data.get("phone"),
        email                   = data.get("email"),
        address                 = data.get("address"),
        smoking_status          = data.get("smoking_status",  "never"),
        diabetes_status         = data.get("diabetes_status", "none"),
        family_history          = bool(data.get("family_history",       False)),
        previous_periodontal    = bool(data.get("previous_periodontal", False)),
        additional_risk_factors = data.get("additional_risk_factors"),
        notes                   = data.get("notes"),
    )
    db.session.add(patient)
    db.session.commit()
    log_action(uid, "patient.create", "patients", patient.id)
    return success(patient.to_dict(), "Patient created.", 201)


@patients_bp.get("/")
@jwt_required()
def list_patients():
    uid      = int(get_jwt_identity())
    page     = int(request.args.get("page",     1))
    per_page = int(request.args.get("per_page", 20))
    q        = request.args.get("q", "").strip()

    query = Patient.query.filter_by(user_id=uid, is_active=True)
    if q:
        like = f"%{q}%"
        query = query.filter(
            or_(Patient.first_name.ilike(like),
                Patient.last_name.ilike(like),
                Patient.phone.ilike(like),
                Patient.email.ilike(like))
        )
    total    = query.count()
    patients = query.order_by(Patient.created_at.desc()) \
                    .offset((page - 1) * per_page).limit(per_page).all()
    return paginated([p.to_dict() for p in patients], total, page, per_page)


@patients_bp.get("/<int:patient_id>")
@jwt_required()
def get_patient(patient_id: int):
    uid     = int(get_jwt_identity())
    patient = Patient.query.filter_by(id=patient_id, user_id=uid, is_active=True).first()
    if not patient:
        return error("Patient not found.", 404)
    return success(patient.to_dict())


@patients_bp.put("/<int:patient_id>")
@jwt_required()
def update_patient(patient_id: int):
    uid     = int(get_jwt_identity())
    patient = Patient.query.filter_by(id=patient_id, user_id=uid, is_active=True).first()
    if not patient:
        return error("Patient not found.", 404)

    data = request.get_json(silent=True) or {}
    fields = ["first_name", "last_name", "gender", "phone", "email", "address",
              "smoking_status", "diabetes_status", "additional_risk_factors", "notes"]
    for f in fields:
        if f in data:
            setattr(patient, f, data[f])

    if "date_of_birth" in data:
        dob = _parse_date(data["date_of_birth"])
        if not dob:
            return error("Invalid date_of_birth.")
        patient.date_of_birth = dob
    if "family_history" in data:
        patient.family_history = bool(data["family_history"])
    if "previous_periodontal" in data:
        patient.previous_periodontal = bool(data["previous_periodontal"])

    db.session.commit()
    log_action(uid, "patient.update", "patients", patient_id)
    return success(patient.to_dict(), "Patient updated.")


@patients_bp.delete("/<int:patient_id>")
@jwt_required()
def delete_patient(patient_id: int):
    uid  = int(get_jwt_identity())
    user = User.query.get(uid)

    # Staff are not allowed to delete patients
    if user and user.role == "staff":
        return error("Staff cannot delete patients.", 403)

    patient = Patient.query.filter_by(id=patient_id, user_id=uid, is_active=True).first()
    if not patient:
        return error("Patient not found.", 404)

    patient.is_active = False  # soft delete
    db.session.commit()
    log_action(uid, "patient.delete", "patients", patient_id)
    return success(message="Patient deleted.")


@patients_bp.get("/<int:patient_id>/history")
@jwt_required()
def patient_history(patient_id: int):
    uid     = int(get_jwt_identity())
    patient = Patient.query.filter_by(id=patient_id, user_id=uid, is_active=True).first()
    if not patient:
        return error("Patient not found.", 404)

    predictions = patient.predictions.order_by(db.text("created_at DESC")).all()
    return success({
        "patient":     patient.to_dict(),
        "predictions": [p.to_dict() for p in predictions],
    })
