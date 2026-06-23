"""Rule-based recommendation engine (Phase 3 baseline)."""
from __future__ import annotations

from app.models.recommendation import RecommendationItem


def generate_recommendations(
    user_id: str, interests: list[str], limit: int = 5
) -> list[RecommendationItem]:
    base_interests = interests or ["events", "study", "clubs"]
    items: list[RecommendationItem] = []
    for idx, interest in enumerate(base_interests[:limit]):
        rec_type = _map_interest(interest)
        items.append(
            RecommendationItem(
                recommendation_type=rec_type,
                target_id=None,
                reason=f"Matches your interest in {interest}",
                score=round(0.9 - idx * 0.08, 2),
            )
        )
    if len(items) < limit:
        items.append(
            RecommendationItem(
                recommendation_type="event",
                target_id=None,
                reason="Popular upcoming campus event for new students",
                score=0.55,
            )
        )
    return items[:limit]


def _map_interest(interest: str) -> str:
    key = interest.lower()
    if "club" in key:
        return "club"
    if "study" in key or "exam" in key:
        return "study"
    if "volunteer" in key:
        return "volunteer"
    return "event"
