"""User model."""
from datetime import datetime
import bcrypt
from ..extensions import db


class User(db.Model):
    __tablename__ = "users"

    id            = db.Column(db.Integer, primary_key=True, autoincrement=True)
    full_name     = db.Column(db.String(120), nullable=False)
    email         = db.Column(db.String(180), nullable=False, unique=True, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    role          = db.Column(db.Enum("admin", "dentist", "staff"), nullable=False, default="dentist")
    clinic_name   = db.Column(db.String(200))
    phone         = db.Column(db.String(20))
    avatar_url    = db.Column(db.String(500))
    is_active     = db.Column(db.Boolean, nullable=False, default=True)
    last_login_at = db.Column(db.DateTime)
    created_at    = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at    = db.Column(db.DateTime, nullable=False, default=datetime.utcnow,
                              onupdate=datetime.utcnow)

    patients    = db.relationship("Patient",    back_populates="user", lazy="dynamic")
    predictions = db.relationship("Prediction", back_populates="user", lazy="dynamic")
    audit_logs  = db.relationship("AuditLog",   back_populates="user", lazy="dynamic")

    # ------------------------------------------------------------------
    def set_password(self, plain: str) -> None:
        self.password_hash = bcrypt.hashpw(
            plain.encode(), bcrypt.gensalt()
        ).decode()

    def check_password(self, plain: str) -> bool:
        return bcrypt.checkpw(plain.encode(), self.password_hash.encode())

    def to_dict(self) -> dict:
        return {
            "id":          self.id,
            "full_name":   self.full_name,
            "email":       self.email,
            "role":        self.role,
            "clinic_name": self.clinic_name,
            "phone":       self.phone,
            "avatar_url":  self.avatar_url,
            "is_active":   self.is_active,
            "created_at":  self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<User {self.email}>"
