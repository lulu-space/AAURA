from fastapi import APIRouter

from app.models.recommendation import RecommendationRequest, RecommendationResponse
from app.services.recommendation_engine import generate_recommendations

router = APIRouter()


@router.post("/generate", response_model=RecommendationResponse)
def generate(payload: RecommendationRequest) -> RecommendationResponse:
    items = generate_recommendations(payload.user_id, payload.interests, payload.limit)
    return RecommendationResponse(source="rule_based", items=items)
