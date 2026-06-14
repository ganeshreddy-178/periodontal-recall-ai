"""Health-check endpoint."""
from flask import Blueprint
from ..extensions import db
from ..utils.responses import success, error

health_bp = Blueprint("health", __name__)


@health_bp.get("/")
def health_check():
    try:
        db.session.execute(db.text("SELECT 1"))
        db_ok = True
    except Exception:
        db_ok = False

    if db_ok:
        return success({"status": "healthy", "database": "connected"})
    return error("Database connection failed.", 503)
