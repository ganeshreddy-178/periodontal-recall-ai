"""Prediction model."""
from datetime import datetime
from ..extensions import db


class Prediction(db.Model):
    __tablename__ = "predictions"

    id                   = db.Column(db.Integer, primary_key=True, autoincrement=True)
    patient_id           = db.Column(db.Integer, db.ForeignKey("patients.id",    ondelete="CASCADE"),
                                     nullable=False, index=True)
    user_id              = db.Column(db.Integer, db.ForeignKey("users.id",       ondelete="CASCADE"),
                                     nullable=False, index=True)
    # Clinical
    age                  = db.Column(db.SmallInteger,    nullable=False)
    plaque_index         = db.Column(db.Numeric(4, 2),   nullable=False)
    bleeding_on_probing  = db.Column(db.Numeric(5, 2),   nullable=False)
    pocket_depth         = db.Column(db.Numeric(4, 2),   nullable=False)
    attachment_loss      = db.Column(db.Numeric(4, 2),   nullable=False)
    oral_hygiene_score   = db.Column(db.Numeric(4, 2),   nullable=False)
    # Image
    image_path           = db.Column(db.String(500))
    image_filename       = db.Column(db.String(255))
    # AI outputs
    cnn_severity         = db.Column(db.Enum("healthy", "mild", "moderate", "severe"))
    cnn_confidence       = db.Column(db.Numeric(5, 2))
    clinical_risk_score  = db.Column(db.Numeric(5, 2))
    clinical_risk_level  = db.Column(db.Enum("low", "moderate", "high"))
    final_severity       = db.Column(db.Enum("healthy", "mild", "moderate", "severe"), nullable=False)
    final_risk_level     = db.Column(db.Enum("low", "moderate", "high"),               nullable=False)
    final_confidence     = db.Column(db.Numeric(5, 2))
    # Recall
    recall_interval_min  = db.Column(db.SmallInteger, nullable=False)
    recall_interval_max  = db.Column(db.SmallInteger, nullable=False)
    recommendations      = db.Column(db.Text)
    # Meta
    model_version_id     = db.Column(db.Integer, db.ForeignKey("model_versions.id"))
    processing_time_ms   = db.Column(db.Integer)
    created_at           = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    patient       = db.relationship("Patient",      back_populates="predictions")
    user          = db.relationship("User",          back_populates="predictions")
    model_version = db.relationship("ModelVersion")
    reminders     = db.relationship("RecallReminder", back_populates="prediction",
                                     lazy="dynamic", cascade="all, delete-orphan")

    def to_dict(self) -> dict:
        return {
            "id":                  self.id,
            "patient_id":          self.patient_id,
            "user_id":             self.user_id,
            "age":                 self.age,
            "plaque_index":        float(self.plaque_index),
            "bleeding_on_probing": float(self.bleeding_on_probing),
            "pocket_depth":        float(self.pocket_depth),
            "attachment_loss":     float(self.attachment_loss),
            "oral_hygiene_score":  float(self.oral_hygiene_score),
            "image_path":          self.image_path,
            "image_filename":      self.image_filename,
            "cnn_severity":        self.cnn_severity,
            "cnn_confidence":      float(self.cnn_confidence) if self.cnn_confidence else None,
            "clinical_risk_score": float(self.clinical_risk_score) if self.clinical_risk_score else None,
            "clinical_risk_level": self.clinical_risk_level,
            "final_severity":      self.final_severity,
            "final_risk_level":    self.final_risk_level,
            "final_confidence":    float(self.final_confidence) if self.final_confidence else None,
            "recall_interval_min": self.recall_interval_min,
            "recall_interval_max": self.recall_interval_max,
            "recommendations":     self.recommendations,
            "processing_time_ms":  self.processing_time_ms,
            "created_at":          self.created_at.isoformat() if self.created_at else None,
        }
