"""Unit tests for the AI service (clinical scoring + fusion + recall)."""
import pytest
from app.services.ai_service import AIService

svc = AIService()

CLINICAL_HIGH = {
    "age": 60, "plaque_index": 2.8, "bleeding_on_probing": 90,
    "pocket_depth": 7, "attachment_loss": 6, "oral_hygiene_score": 2,
    "smoking_status": "current", "diabetes_status": "type2",
    "family_history": True, "previous_periodontal": True,
}

CLINICAL_LOW = {
    "age": 25, "plaque_index": 0.2, "bleeding_on_probing": 5,
    "pocket_depth": 1.5, "attachment_loss": 0.5, "oral_hygiene_score": 9,
    "smoking_status": "never", "diabetes_status": "none",
    "family_history": False, "previous_periodontal": False,
}


def test_clinical_high_risk():
    result = svc.clinical_risk_score(CLINICAL_HIGH)
    assert result["score"] >= 65
    assert result["level"] == "high"


def test_clinical_low_risk():
    result = svc.clinical_risk_score(CLINICAL_LOW)
    assert result["score"] < 30
    assert result["level"] == "low"


def test_fusion_no_image():
    clinical = svc.clinical_risk_score(CLINICAL_LOW)
    fused    = svc.fuse(None, None, clinical)
    assert fused["final_severity"] in ("healthy", "mild", "moderate", "severe")
    assert fused["final_risk_level"] in ("low", "moderate", "high")


def test_fusion_with_severe_cnn():
    clinical = svc.clinical_risk_score(CLINICAL_HIGH)
    fused    = svc.fuse("severe", 98.0, clinical)
    assert fused["final_severity"] == "severe"
    assert fused["final_risk_level"] == "high"


def test_recall_healthy():
    rec = svc.recall_recommendation("healthy")
    assert rec["min_months"] == 6
    assert rec["max_months"] == 12


def test_recall_severe():
    rec = svc.recall_recommendation("severe")
    assert rec["min_months"] == 1
    assert rec["max_months"] == 3
