"""Audit logging helper."""
from flask import request
from ..extensions import db
from ..models.audit import AuditLog


def log_action(user_id, action: str, entity: str = None,
               entity_id: int = None, details: dict = None) -> None:
    try:
        entry = AuditLog(
            user_id    = user_id,
            action     = action,
            entity     = entity,
            entity_id  = entity_id,
            ip_address = request.remote_addr,
            user_agent = request.headers.get("User-Agent", "")[:500],
            details    = details,
        )
        db.session.add(entry)
        db.session.commit()
    except Exception:
        db.session.rollback()
