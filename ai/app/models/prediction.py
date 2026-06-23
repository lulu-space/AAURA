from pydantic import BaseModel, Field


class EventSuccessPredictRequest(BaseModel):
    student_major: str = Field(description="Dominant student major category")
    event_type: str = Field(description="Event type category")
    department: str = Field(description="Hosting department category")
    organizer_type: str = Field(
        default="student_affairs",
        description="club_student | club_event | student_affairs | dean_of_faculty",
    )
    expected_attendance: int = Field(gt=0, le=5000, description="Expected attendance count")
    interest_match_score: float = Field(
        ge=0.0, le=1.0, description="How well the event matches student interests (0-1)"
    )
    skill_match_score: float = Field(
        ge=0.0, le=1.0, description="How well the event matches student skills (0-1)"
    )
    target_major_count: int = Field(default=0, ge=0, le=20)
    target_interest_count: int = Field(default=0, ge=0, le=20)


class EventSuccessPredictResponse(BaseModel):
    success_probability: float
    success_label: int
    engagement_score: float
    expected_attendance_used: float
    features_used: dict[str, object] | None = None
    model_cv_accuracy: float | None = None
