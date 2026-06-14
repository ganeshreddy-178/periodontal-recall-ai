"""ModelVersion model."""
from datetime import datetime
from ..extensions import db


class ModelVersion(db.Model):
    __tablename__ = "model_versions"

    id          = db.Column(db.Integer, primary_key=True, autoincrement=True)
    version_tag = db.Column(db.String(30), nullable=False, unique=True)
    model_path  = db.Column(db.String(500), nullable=False)
    accuracy    = db.Column(db.Numeric(5, 2))
    auc_score   = db.Column(db.Numeric(5, 4))
    description = db.Column(db.Text)
    is_active   = db.Column(db.Boolean, default=False)
    trained_at  = db.Column(db.DateTime)
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self) -> dict:
        return {
            "id":          self.id,
            "version_tag": self.version_tag,
            "model_path":  self.model_path,
            "accuracy":    float(self.accuracy) if self.accuracy else None,
            "auc_score":   float(self.auc_score) if self.auc_score else None,
            "description": self.description,
            "is_active":   self.is_active,
            "trained_at":  self.trained_at.isoformat() if self.trained_at else None,
        }
