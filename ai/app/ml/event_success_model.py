from __future__ import annotations

from pathlib import Path

import joblib
import numpy as np

from app.ml.features import CATEGORICAL_COLUMNS, NUMERIC_COLUMNS, UNK_TOKEN

MODEL_PATH = Path(__file__).resolve().parent / "models" / "event_success_xgb.joblib"


class EventSuccessModel:
    def __init__(self) -> None:
        self._bundle: dict | None = None

    def _load(self) -> dict:
        if self._bundle is None:
            if not MODEL_PATH.exists():
                raise FileNotFoundError(
                    f"Model not found at {MODEL_PATH}. Run: py -m app.ml.train_event_success"
                )
            self._bundle = joblib.load(MODEL_PATH)
        return self._bundle

    def _encode_row(self, features: dict[str, str | int | float]) -> np.ndarray:
        bundle = self._load()
        encoders: dict = bundle["encoders"]
        unk = bundle.get("unk_token", UNK_TOKEN)
        row: dict[str, int | float] = {}

        for col in CATEGORICAL_COLUMNS:
            le = encoders[col]
            value = str(features.get(col, unk))
            if value not in le.classes_:
                value = unk if unk in le.classes_ else le.classes_[0]
            row[col] = int(le.transform([value])[0])

        for col in NUMERIC_COLUMNS:
            row[col] = float(features.get(col, 0))

        cols = CATEGORICAL_COLUMNS + NUMERIC_COLUMNS
        return np.array([[row[c] for c in cols]])

    def predict(self, features: dict[str, str | int | float]) -> dict[str, float | int | dict]:
        bundle = self._load()
        model = bundle["model"]
        row = self._encode_row(features)
        proba = float(model.predict_proba(row)[0][1])
        label = int(proba >= 0.5)
        attendance = float(features.get("expected_attendance", 50))
        interest = float(features.get("interest_match_score", 0.5))
        skill = float(features.get("skill_match_score", 0.5))
        engagement_score = round(min(100.0, proba * 55 + interest * 25 + skill * 20), 2)
        return {
            "success_probability": round(proba, 4),
            "success_label": label,
            "engagement_score": engagement_score,
            "expected_attendance_used": attendance,
            "features_used": {
                key: features.get(key)
                for key in CATEGORICAL_COLUMNS + NUMERIC_COLUMNS
            },
            "model_cv_accuracy": float(bundle.get("cv_accuracy", 0)),
        }


event_success_model = EventSuccessModel()
