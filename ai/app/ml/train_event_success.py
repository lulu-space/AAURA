"""Train XGBoost classifier for campus event success prediction."""
from __future__ import annotations

from pathlib import Path

import joblib
import pandas as pd
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import cross_val_score, train_test_split
from sklearn.preprocessing import LabelEncoder
from xgboost import XGBClassifier

from app.ml.features import (
    CATEGORICAL_COLUMNS,
    NUMERIC_COLUMNS,
    TARGET,
    UNK_TOKEN,
)

DATA_PATH = Path(__file__).resolve().parent / "data" / "event_success_training.csv"
MODEL_PATH = Path(__file__).resolve().parent / "models" / "event_success_xgb.joblib"


def encode_features(df: pd.DataFrame, encoders: dict[str, LabelEncoder] | None = None):
    encoded = df.copy()
    fitted: dict[str, LabelEncoder] = {}

    for col in CATEGORICAL_COLUMNS:
        le = LabelEncoder()
        if encoders and col in encoders:
            le = encoders[col]
            values = encoded[col].astype(str)
            safe = values.where(values.isin(le.classes_), UNK_TOKEN)
            encoded[col] = le.transform(safe)
        else:
            values = encoded[col].astype(str).tolist()
            classes = sorted(set(values) | {UNK_TOKEN})
            le.fit(classes)
            encoded[col] = le.transform(encoded[col].astype(str))
        fitted[col] = le

    feature_cols = CATEGORICAL_COLUMNS + NUMERIC_COLUMNS
    return encoded[feature_cols], fitted


def main() -> None:
    if not DATA_PATH.exists() or DATA_PATH.stat().st_size < 200:
        import subprocess
        import sys

        subprocess.run([sys.executable, str(Path(__file__).parent / "generate_dataset.py")], check=True)

    df = pd.read_csv(DATA_PATH)
    X, encoders = encode_features(df)
    y = df[TARGET]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    model = XGBClassifier(
        n_estimators=220,
        max_depth=5,
        learning_rate=0.06,
        min_child_weight=2,
        subsample=0.88,
        colsample_bytree=0.88,
        reg_lambda=1.2,
        eval_metric="logloss",
        random_state=42,
    )
    model.fit(X_train, y_train)

    cv_scores = cross_val_score(model, X, y, cv=5, scoring="accuracy")
    print(f"Cross-validation accuracy: {cv_scores.mean():.3f} (+/- {cv_scores.std():.3f})")

    preds = model.predict(X_test)
    acc = accuracy_score(y_test, preds)
    print(f"Test accuracy: {acc:.3f}")
    print(classification_report(y_test, preds, target_names=["low_success", "high_success"]))

    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(
        {
            "model": model,
            "encoders": encoders,
            "categorical_columns": CATEGORICAL_COLUMNS,
            "numeric_columns": NUMERIC_COLUMNS,
            "unk_token": UNK_TOKEN,
            "training_accuracy": float(acc),
            "cv_accuracy": float(cv_scores.mean()),
        },
        MODEL_PATH,
    )
    print(f"Model saved to {MODEL_PATH}")


if __name__ == "__main__":
    main()
