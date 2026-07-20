"""Admin-only endpoints for user management and system statistics."""
from flask import Blueprint, request
from flask_jwt_extended import get_jwt_identity

from ..extensions import db
from ..models.user import User
from ..models.patient import Patient
from ..models.prediction import Prediction
from ..utils.responses import success, error
from ..utils.rbac import role_required

admin_bp = Blueprint("admin", __name__)


@admin_bp.get("/users")
@role_required("admin")
def list_users():
    """Return all users (admin only)."""
    users = User.query.order_by(User.created_at.desc()).all()
    return success([u.to_dict() for u in users], f"{len(users)} users found.")


@admin_bp.get("/stats")
@role_required("admin")
def system_stats():
    """Return system-wide aggregate statistics (admin only)."""
    total_users       = User.query.count()
    total_patients    = Patient.query.filter_by(is_active=True).count()
    total_predictions = Prediction.query.count()
    return success({
        "total_users":       total_users,
        "total_patients":    total_patients,
        "total_predictions": total_predictions,
    }, "Stats retrieved.")


@admin_bp.put("/users/<int:user_id>/role")
@role_required("admin")
def change_user_role(user_id: int):
    """Change a user's role (admin only)."""
    data     = request.get_json(silent=True) or {}
    new_role = data.get("role", "").strip()
    if new_role not in ("admin", "dentist", "staff"):
        return error("Invalid role. Must be 'admin', 'dentist', or 'staff'.")

    user = db.session.get(User, user_id)
    if not user:
        return error("User not found.", 404)

    requesting_uid = int(get_jwt_identity())
    if user_id == requesting_uid:
        return error("You cannot change your own role.")

    user.role = new_role
    db.session.commit()
    return success(user.to_dict(), f"User role updated to '{new_role}'.")


@admin_bp.delete("/users/<int:user_id>")
@role_required("admin")
def deactivate_user(user_id: int):
    """Soft-deactivate a user account (admin only)."""
    user = db.session.get(User, user_id)
    if not user:
        return error("User not found.", 404)

    requesting_uid = int(get_jwt_identity())
    if user_id == requesting_uid:
        return error("You cannot deactivate your own account.")

    user.is_active = False
    db.session.commit()
    return success(message=f"User '{user.email}' has been deactivated.")
