"""Dashboard analytics endpoints."""
from flask import Blueprint
from flask_jwt_extended import jwt_required, get_jwt_identity
from sqlalchemy import func

from ..extensions import db
from ..models.patient import Patient
from ..models.prediction import Prediction
from ..models.reminder import RecallReminder
from ..utils.responses import success

dashboard_bp = Blueprint("dashboard", __name__)


@dashboard_bp.get("/")
@jwt_required()
def overview():
    uid = int(get_jwt_identity())

    total_patients   = Patient.query.filter_by(user_id=uid, is_active=True).count()
    total_predictions = Prediction.query.filter_by(user_id=uid).count()

    # Risk distribution
    risk_dist = (
        db.session.query(Prediction.final_risk_level, func.count(Prediction.id))
        .filter_by(user_id=uid)
        .group_by(Prediction.final_risk_level)
        .all()
    )
    risk_map = {r: c for r, c in risk_dist}

    # Severity distribution
    sev_dist = (
        db.session.query(Prediction.final_severity, func.count(Prediction.id))
        .filter_by(user_id=uid)
        .group_by(Prediction.final_severity)
        .all()
    )
    sev_map = {s: c for s, c in sev_dist}

    # Recent predictions (5)
    recent = (Prediction.query.filter_by(user_id=uid)
              .order_by(Prediction.created_at.desc()).limit(5).all())

    # Upcoming reminders (5)
    from datetime import date
    upcoming = (
        RecallReminder.query
        .join(Patient, RecallReminder.patient_id == Patient.id)
        .filter(Patient.user_id == uid,
                RecallReminder.status.in_(["pending"]),
                RecallReminder.due_date >= date.today())
        .order_by(RecallReminder.due_date.asc())
        .limit(5).all()
    )

    return success({
        "total_patients":    total_patients,
        "total_predictions": total_predictions,
        "risk_distribution": {
            "low":      risk_map.get("low",      0),
            "moderate": risk_map.get("moderate", 0),
            "high":     risk_map.get("high",     0),
        },
        "severity_distribution": {
            "healthy":  sev_map.get("healthy",  0),
            "mild":     sev_map.get("mild",     0),
            "moderate": sev_map.get("moderate", 0),
            "severe":   sev_map.get("severe",   0),
        },
        "recent_predictions": [p.to_dict() for p in recent],
        "upcoming_reminders": [r.to_dict() for r in upcoming],
    })


@dashboard_bp.get("/trends")
@jwt_required()
def trends():
    uid = int(get_jwt_identity())

    monthly = (
        db.session.query(
            func.date_format(Prediction.created_at, "%Y-%m").label("month"),
            func.count(Prediction.id).label("count")
        )
        .filter_by(user_id=uid)
        .group_by("month")
        .order_by("month")
        .limit(12)
        .all()
    )

    return success({
        "monthly_predictions": [
            {"month": m, "count": c} for m, c in monthly
        ]
    })
