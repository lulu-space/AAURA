from pydantic import BaseModel, Field


class RecommendationRequest(BaseModel):
    user_id: str
    interests: list[str] = Field(default_factory=list)
    limit: int = Field(default=5, ge=1, le=20)


class RecommendationItem(BaseModel):
    recommendation_type: str
    target_id: str | None
    reason: str
    score: float


class RecommendationResponse(BaseModel):
    source: str
    items: list[RecommendationItem]
