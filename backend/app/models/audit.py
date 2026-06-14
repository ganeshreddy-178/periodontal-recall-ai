"""AuditLog model."""
from datetime import datetime
from ..extensions import db


class AuditLog(db.Model):
    __tablename__ = "audit_logs"

    id         = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    user_id    = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    action     = db.Column(db.String(100), nullable=False, index=True)
    entity     = db.Column(db.String(60))
    entity_id  = db.Column(db.Integer)
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.String(500))
    details    = db.Column(db.JSON)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, index=True)

    user = db.relationship("User", back_populates="audit_logs")

    def to_dict(self) -> dict:
        return {
            "id":         self.id,
            "user_id":    self.user_id,
            "action":     self.action,
            "entity":     self.entity,
            "entity_id":  self.entity_id,
            "ip_address": self.ip_address,
            "details":    self.details,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
