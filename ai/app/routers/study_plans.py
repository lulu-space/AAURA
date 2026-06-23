from fastapi import APIRouter

from app.models.study_plan import StudyPlanGenerateRequest, StudyPlanGenerateResponse
from app.services.study_plan_generator import generate_schedule

router = APIRouter()


@router.post("/generate", response_model=StudyPlanGenerateResponse)
def generate(payload: StudyPlanGenerateRequest) -> StudyPlanGenerateResponse:
    schedule = generate_schedule(payload.goals, payload.hours_per_week)
    return StudyPlanGenerateResponse(
        title=payload.title,
        goals=payload.goals or ["Stay consistent", "Review weekly"],
        schedule=schedule,
        source="ai",
    )
