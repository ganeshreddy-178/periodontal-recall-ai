"""Patient model."""
from datetime import datetime
from ..extensions import db


class Patient(db.Model):
    __tablename__ = "patients"

    id                      = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id                 = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"),
                                        nullable=False, index=True)
    first_name              = db.Column(db.String(80),  nullable=False)
    last_name               = db.Column(db.String(80),  nullable=False)
    date_of_birth           = db.Column(db.Date,        nullable=False)
    gender                  = db.Column(db.Enum("male", "female", "other"), nullable=False)
    phone                   = db.Column(db.String(20))
    email                   = db.Column(db.String(180))
    address                 = db.Column(db.Text)
    smoking_status          = db.Column(db.Enum("never", "former", "current"), default="never")
    diabetes_status         = db.Column(db.Enum("none", "type1", "type2", "prediabetic"), default="none")
    family_history          = db.Column(db.Boolean, default=False)
    previous_periodontal    = db.Column(db.Boolean, default=False)
    additional_risk_factors = db.Column(db.Text)
    notes                   = db.Column(db.Text)
    is_active               = db.Column(db.Boolean, default=True)
    created_at              = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at              = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user        = db.relationship("User",       back_populates="patients")
    predictions = db.relationship("Prediction", back_populates="patient", lazy="dynamic",
                                   cascade="all, delete-orphan")
    reminders   = db.relationship("RecallReminder", back_populates="patient", lazy="dynamic",
                                   cascade="all, delete-orphan")

    @property
    def age(self):
        from datetime import date
        today = date.today()
        dob   = self.date_of_birth
        return today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))

    def to_dict(self) -> dict:
        return {
            "id":                      self.id,
            "user_id":                 self.user_id,
            "first_name":              self.first_name,
            "last_name":               self.last_name,
            "full_name":               f"{self.first_name} {self.last_name}",
            "date_of_birth":           self.date_of_birth.isoformat() if self.date_of_birth else None,
            "age":                     self.age,
            "gender":                  self.gender,
            "phone":                   self.phone,
            "email":                   self.email,
            "address":                 self.address,
            "smoking_status":          self.smoking_status,
            "diabetes_status":         self.diabetes_status,
            "family_history":          self.family_history,
            "previous_periodontal":    self.previous_periodontal,
            "additional_risk_factors": self.additional_risk_factors,
            "notes":                   self.notes,
            "is_active":               self.is_active,
            "created_at":              self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<Patient {self.first_name} {self.last_name}>"
