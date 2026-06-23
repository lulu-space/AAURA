"""Rule-based study plan generator (Phase 3 baseline)."""
from __future__ import annotations

from datetime import datetime, timedelta


def generate_schedule(goals: list[str], hours_per_week: int) -> list[dict[str, str]]:
    sessions = max(1, min(7, hours_per_week // 2))
    start = datetime.utcnow().replace(hour=9, minute=0, second=0, microsecond=0)
    schedule: list[dict[str, str]] = []
    for i in range(sessions):
        slot_start = start + timedelta(days=i)
        slot_end = slot_start + timedelta(hours=2)
        goal = goals[i % len(goals)] if goals else "General review"
        schedule.append(
            {
                "title": f"Study block: {goal}",
                "starts_at": slot_start.isoformat() + "Z",
                "ends_at": slot_end.isoformat() + "Z",
            }
        )
    return schedule
