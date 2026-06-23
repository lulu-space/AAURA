"""Shared match-score helpers for training and inference."""

from __future__ import annotations


def list_match_score(items: list[str], event_text: str, *, empty_default: float = 0.2) -> float:
    cleaned = [item.strip() for item in items if item and item.strip()]
    if not cleaned:
        return empty_default

    text = event_text.lower()
    hits = 0
    for item in cleaned:
        normalized = item.lower()
        tokens = [token for token in normalized.split() if len(token) > 3]
        if normalized in text or any(token in text for token in tokens):
            hits += 1
    return round(min(1.0, hits / len(cleaned)), 2)


def blended_audience_match(
    *,
    interests: list[str],
    skills: list[str],
    tags: list[str],
    event_text: str,
) -> tuple[float, float]:
    interest_pool = [*interests, *tags]
    skill_pool = [*skills, *tags]
    interest_score = list_match_score(interest_pool, event_text)
    skill_score = list_match_score(skill_pool, event_text)
    return interest_score, skill_score
