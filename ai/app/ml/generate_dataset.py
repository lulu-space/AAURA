"""Synthetic training data for event success XGBoost model."""
from __future__ import annotations

import csv
import random
from pathlib import Path

from app.ml.features import DEPARTMENTS, EVENT_TYPES, ORGANIZER_TYPES, STUDENT_MAJORS

OUT = Path(__file__).resolve().parent / "data" / "event_success_training.csv"
ROWS = 2400
random.seed(42)

INTEREST_TAGS = [
    "Programming",
    "Entrepreneurship",
    "Study Groups",
    "Volunteering",
    "Sports",
    "Music",
    "Photography",
    "Public Speaking",
]
SKILL_TAGS = [
    "Python Programming",
    "Communication Skills",
    "Teamwork",
    "Research",
    "Leadership",
    "Problem Solving",
]


def _dept_aligns_major(major: str, department: str) -> bool:
    pairs = {
        "Computer Science": {"Computer Science", "Engineering", "Sciences"},
        "Engineering": {"Engineering", "Computer Science", "Sciences"},
        "Business": {"Business", "Student Affairs"},
        "Arts": {"Arts", "Student Affairs"},
        "Medicine": {"Medicine", "Sciences"},
        "Education": {"Student Affairs", "Arts"},
        "Law": {"Business", "Student Affairs"},
        "Architecture": {"Engineering", "Arts"},
    }
    return department in pairs.get(major, set())


def success_probability(
    student_major: str,
    event_type: str,
    department: str,
    organizer_type: str,
    expected_attendance: int,
    interest_match_score: float,
    skill_match_score: float,
    target_major_count: int,
    target_interest_count: int,
) -> float:
    p = 0.18
    p += interest_match_score * 0.34
    p += skill_match_score * 0.22
    p += min(expected_attendance, 300) / 700
    if _dept_aligns_major(student_major, department):
        p += 0.1
    if event_type in ("workshop", "seminar", "career") and student_major in (
        "Computer Science",
        "Engineering",
        "Business",
    ):
        p += 0.07
    if event_type in ("social", "cultural", "sports"):
        p += 0.05
    if organizer_type == "club_student":
        p += 0.06
    elif organizer_type == "student_affairs":
        p += 0.04
    elif organizer_type == "dean_of_faculty":
        p += 0.03
    if target_major_count >= 2:
        p += 0.04
    if target_interest_count >= 2:
        p += 0.05
    if expected_attendance < 25:
        p -= 0.08
    if interest_match_score < 0.35:
        p -= 0.12
    if skill_match_score < 0.3:
        p -= 0.08
    return max(0.05, min(0.95, p))


def _noisy_label(probability: float) -> int:
    label = 1 if probability >= 0.5 else 0
    if random.random() < 0.06:
        return 1 - label
    return label


def main() -> None:
    rows: list[dict[str, str | int | float]] = []
    for _ in range(ROWS):
        student_major = random.choice(STUDENT_MAJORS)
        event_type = random.choice(EVENT_TYPES)
        department = random.choice(DEPARTMENTS)
        organizer_type = random.choice(ORGANIZER_TYPES)
        expected_attendance = random.randint(15, 280)
        interest_match_score = round(random.uniform(0.1, 1.0), 2)
        skill_match_score = round(random.uniform(0.1, 1.0), 2)
        target_major_count = random.randint(0, 4)
        target_interest_count = random.randint(0, 5)
        p = success_probability(
            student_major,
            event_type,
            department,
            organizer_type,
            expected_attendance,
            interest_match_score,
            skill_match_score,
            target_major_count,
            target_interest_count,
        )
        success = _noisy_label(p)
        rows.append(
            {
                "student_major": student_major,
                "event_type": event_type,
                "department": department,
                "organizer_type": organizer_type,
                "expected_attendance": expected_attendance,
                "interest_match_score": interest_match_score,
                "skill_match_score": skill_match_score,
                "target_major_count": target_major_count,
                "target_interest_count": target_interest_count,
                "success": success,
            }
        )

    fieldnames = list(rows[0].keys())
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {len(rows)} rows to {OUT}")


if __name__ == "__main__":
    main()
