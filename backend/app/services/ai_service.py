"""
AI Service — wraps CNN inference + clinical scoring + fusion + recall logic.
"""
from __future__ import annotations
import os
import logging

import numpy as np
import cv2

logger = logging.getLogger(__name__)

SEVERITY_LABELS = ["healthy", "mild", "moderate", "severe"]


class AIService:
    """Lazy-loads the Keras model on first image prediction call."""

    def __init__(self):
        self._model      = None
        self._model_path = os.getenv(
            "MODEL_PATH",
            os.path.join(os.path.dirname(__file__),
                         "../../ai_module/models_saved/periodontal_cnn_model.h5")
        )

    # ------------------------------------------------------------------
    # Image preprocessing
    # ------------------------------------------------------------------
    @staticmethod
    def preprocess_image(path: str) -> np.ndarray:
        """Load, resize to 224×224, CLAHE, denoise, normalize."""
        img = cv2.imread(path)
        if img is None:
            raise ValueError(f"Cannot read image: {path}")

        img = cv2.resize(img, (224, 224))

        # Convert to LAB for CLAHE on L-channel
        lab   = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        l     = clahe.apply(l)
        lab   = cv2.merge([l, a, b])
        img   = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)

        # Denoise
        img = cv2.fastNlMeansDenoisingColored(img, None, 10, 10, 7, 21)

        # Normalize to [0, 1]
        img = img.astype(np.float32) / 255.0

        return np.expand_dims(img, axis=0)  # (1, 224, 224, 3)

    # ------------------------------------------------------------------
    # CNN inference
    # ------------------------------------------------------------------
    def _load_model(self):
        if self._model is not None:
            return
        if not os.path.exists(self._model_path):
            logger.warning("Model file not found at %s — using dummy predictions.", self._model_path)
            self._model = "dummy"
            return
        try:
            import tensorflow as tf
            self._model = tf.keras.models.load_model(self._model_path)
            logger.info("CNN model loaded from %s", self._model_path)
        except Exception as exc:
            logger.error("Failed to load model: %s", exc)
            self._model = "dummy"

    def predict_image(self, image_path: str) -> dict:
        """Returns {severity: str, confidence: float}."""
        self._load_model()

        if self._model == "dummy":
            # Deterministic pseudo-prediction based on filename hash
            idx  = abs(hash(image_path)) % 4
            conf = 85.0 + (abs(hash(image_path)) % 14)
            return {"severity": SEVERITY_LABELS[idx], "confidence": float(conf)}

        img   = self.preprocess_image(image_path)
        probs = self._model.predict(img, verbose=0)[0]  # shape (4,)
        idx   = int(np.argmax(probs))
        conf  = float(probs[idx] * 100)
        return {"severity": SEVERITY_LABELS[idx], "confidence": round(conf, 2)}

    # ------------------------------------------------------------------
    # Clinical risk scoring (rule-based, 0–100)
    # ------------------------------------------------------------------
    @staticmethod
    def clinical_risk_score(params: dict) -> dict:
        """
        Computes a 0–100 risk score from clinical parameters.

        Parameters
        ----------
        params : dict with keys:
            age, plaque_index (0-3), bleeding_on_probing (%), pocket_depth (mm),
            attachment_loss (mm), oral_hygiene_score (0-10),
            smoking_status, diabetes_status, family_history, previous_periodontal
        """
        score = 0.0

        # --- Age (0-10) ---
        age = int(params.get("age", 30))
        if age >= 60:
            score += 10
        elif age >= 45:
            score += 7
        elif age >= 30:
            score += 4
        else:
            score += 1

        # --- Plaque Index 0-3 (0-15) ---
        pi = float(params.get("plaque_index", 0))
        score += min(pi / 3.0 * 15, 15)

        # --- Bleeding on Probing % (0-15) ---
        bop = float(params.get("bleeding_on_probing", 0))
        score += min(bop / 100 * 15, 15)

        # --- Pocket Depth mm avg (0-15) ---
        pd = float(params.get("pocket_depth", 0))
        if pd >= 6:
            score += 15
        elif pd >= 4:
            score += 10
        elif pd >= 3:
            score += 5
        else:
            score += 0

        # --- Attachment Loss mm avg (0-15) ---
        al = float(params.get("attachment_loss", 0))
        if al >= 5:
            score += 15
        elif al >= 3:
            score += 10
        elif al >= 1:
            score += 5

        # --- Oral Hygiene Score 0-10 (inverted, 0-10) ---
        ohs = float(params.get("oral_hygiene_score", 5))
        score += max(0, (10 - ohs) * 1)

        # --- Smoking (0-10) ---
        sm = params.get("smoking_status", "never")
        if sm == "current":
            score += 10
        elif sm == "former":
            score += 5

        # --- Diabetes (0-8) ---
        dm = params.get("diabetes_status", "none")
        if dm in ("type1", "type2"):
            score += 8
        elif dm == "prediabetic":
            score += 4

        # --- Family History (0-5) ---
        if params.get("family_history"):
            score += 5

        # --- Previous Periodontal Disease (0-7) ---
        if params.get("previous_periodontal"):
            score += 7

        score = round(min(score, 100), 2)

        if score < 30:
            level = "low"
        elif score < 65:
            level = "moderate"
        else:
            level = "high"

        return {"score": score, "level": level}

    # ------------------------------------------------------------------
    # Multimodal fusion
    # ------------------------------------------------------------------
    @staticmethod
    def fuse(cnn_severity: str | None, cnn_confidence: float | None,
             clinical_result: dict) -> dict:
        """
        Combines CNN result (60%) and clinical score (40%) to produce
        final severity, risk level, and confidence.
        """
        sev_to_idx = {"healthy": 0, "mild": 1, "moderate": 2, "severe": 3}
        idx_to_sev = {0: "healthy", 1: "mild", 2: "moderate", 3: "severe"}

        clinical_score = clinical_result["score"]  # 0-100

        # Map clinical score to severity index (0-3)
        if clinical_score < 25:
            clinical_idx = 0
        elif clinical_score < 50:
            clinical_idx = 1
        elif clinical_score < 75:
            clinical_idx = 2
        else:
            clinical_idx = 3

        if cnn_severity is not None:
            cnn_idx     = sev_to_idx.get(cnn_severity, 0)
            fused_idx   = round(cnn_idx * 0.6 + clinical_idx * 0.4)
            confidence  = round(
                (cnn_confidence or 0) * 0.6 + (100 - clinical_score) * 0.4, 2
            )
        else:
            # No image — use clinical only
            fused_idx  = clinical_idx
            confidence = round(100 - clinical_score, 2)

        final_severity = idx_to_sev[max(0, min(3, fused_idx))]

        risk_map = {
            "healthy":  "low",
            "mild":     "low",
            "moderate": "moderate",
            "severe":   "high",
        }
        final_risk_level = risk_map[final_severity]

        # Override if clinical score says high even with mild CNN
        if clinical_result["level"] == "high" and final_risk_level != "high":
            final_risk_level = "high"

        return {
            "final_severity":  final_severity,
            "final_risk_level": final_risk_level,
            "final_confidence": round(max(0, min(100, confidence)), 2),
        }

    # ------------------------------------------------------------------
    # Recall recommendation
    # ------------------------------------------------------------------
    @staticmethod
    def recall_recommendation(final_severity: str) -> dict:
        rules = {
            "healthy":  {"min_months": 6,  "max_months": 12,
                         "recommendations": (
                             "Excellent periodontal health. Maintain twice-daily brushing and "
                             "daily flossing. Use fluoride toothpaste. Recall every 6–12 months.")},
            "mild":     {"min_months": 6,  "max_months": 6,
                         "recommendations": (
                             "Mild gingivitis or early periodontitis detected. "
                             "Professional cleaning recommended. Improve oral hygiene routine. "
                             "Consider electric toothbrush. Recall every 6 months.")},
            "moderate": {"min_months": 3,  "max_months": 6,
                         "recommendations": (
                             "Moderate periodontitis. Scaling and root planing required. "
                             "Address risk factors: smoking cessation, diabetes control. "
                             "Antimicrobial rinse may be prescribed. Recall every 3–6 months.")},
            "severe":   {"min_months": 1,  "max_months": 3,
                         "recommendations": (
                             "Severe periodontitis. Immediate specialist referral recommended. "
                             "Surgical intervention may be necessary. "
                             "Strict systemic risk factor management required. Recall every 1–3 months.")},
        }
        return rules.get(final_severity, rules["moderate"])
