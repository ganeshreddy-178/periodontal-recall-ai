"""History & recall reminder endpoints."""
from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity

from ..extensions import db
from ..models.prediction import Prediction
from ..models.reminder import RecallReminder
from ..models.patient import Patient
from ..utils.responses import success, error, paginated

history_bp = Blueprint("history", __name__)


@history_bp.get("/predictions")
@jwt_required()
def list_predictions():
    uid      = int(get_jwt_identity())
    page     = int(request.args.get("page",     1))
    per_page = int(request.args.get("per_page", 20))
    severity = request.args.get("severity")

    query = Prediction.query.filter_by(user_id=uid)
    if severity:
        query = query.filter_by(final_severity=severity)

    total = query.count()
    preds = query.order_by(Prediction.created_at.desc()) \
                 .offset((page - 1) * per_page).limit(per_page).all()
    return paginated([p.to_dict() for p in preds], total, page, per_page)


@history_bp.get("/reminders")
@jwt_required()
def list_reminders():
    uid      = int(get_jwt_identity())
    page     = int(request.args.get("page",     1))
    per_page = int(request.args.get("per_page", 20))
    status   = request.args.get("status")

    # Only reminders for patients belonging to this user
    query = (RecallReminder.query
             .join(Patient, RecallReminder.patient_id == Patient.id)
             .filter(Patient.user_id == uid))
    if status:
        query = query.filter(RecallReminder.status == status)

    total     = query.count()
    reminders = query.order_by(RecallReminder.due_date.asc()) \
                     .offset((page - 1) * per_page).limit(per_page).all()
    return paginated([r.to_dict() for r in reminders], total, page, per_page)


@history_bp.put("/reminders/<int:reminder_id>")
@jwt_required()
def update_reminder(reminder_id: int):
    uid      = int(get_jwt_identity())
    reminder = (RecallReminder.query
                .join(Patient, RecallReminder.patient_id == Patient.id)
                .filter(Patient.user_id == uid, RecallReminder.id == reminder_id)
                .first())
    if not reminder:
        return error("Reminder not found.", 404)

    data = request.get_json(silent=True) or {}
    if "status" in data:
        if data["status"] not in ("pending", "sent", "acknowledged", "overdue"):
            return error("Invalid status.")
        reminder.status = data["status"]
    if "notes" in data:
        reminder.notes = data["notes"]

    db.session.commit()
    return success(reminder.to_dict(), "Reminder updated.")
