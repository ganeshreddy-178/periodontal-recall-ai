"""Recall Reminder model."""
from datetime import datetime
from ..extensions import db


class RecallReminder(db.Model):
    __tablename__ = "recall_reminders"

    id            = db.Column(db.Integer, primary_key=True, autoincrement=True)
    patient_id    = db.Column(db.Integer, db.ForeignKey("patients.id",    ondelete="CASCADE"), nullable=False)
    prediction_id = db.Column(db.Integer, db.ForeignKey("predictions.id", ondelete="CASCADE"), nullable=False)
    due_date      = db.Column(db.Date,    nullable=False)
    status        = db.Column(db.Enum("pending", "sent", "acknowledged", "overdue"), default="pending")
    notes         = db.Column(db.Text)
    sent_at       = db.Column(db.DateTime)
    created_at    = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at    = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    patient    = db.relationship("Patient",    back_populates="reminders")
    prediction = db.relationship("Prediction", back_populates="reminders")

    def to_dict(self) -> dict:
        return {
            "id":            self.id,
            "patient_id":    self.patient_id,
            "prediction_id": self.prediction_id,
            "due_date":      self.due_date.isoformat() if self.due_date else None,
            "status":        self.status,
            "notes":         self.notes,
            "sent_at":       self.sent_at.isoformat() if self.sent_at else None,
            "created_at":    self.created_at.isoformat() if self.created_at else None,
        }
