from pydantic import BaseModel, Field


class StudyPlanGenerateRequest(BaseModel):
    user_id: str
    title: str = Field(min_length=3)
    goals: list[str] = Field(default_factory=list)
    hours_per_week: int = Field(default=10, ge=1, le=60)


class StudyPlanGenerateResponse(BaseModel):
    title: str
    goals: list[str]
    schedule: list[dict[str, str]]
    source: str
