from pydantic import BaseModel, Field


class ShamsChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)


class ShamsExtractionResult(BaseModel):
    reply: str
    traits: dict[str, str]
    interests: list[str]
    skills: list[str] = Field(default_factory=list)
    keywords: list[str]
    major: str | None = None
    year: str | None = None
    academic_year: int | None = None
    goals: list[str] = Field(default_factory=list)
    profile_summary: str
    profile_text: str
    confidence: float
    needs_detail: bool = False
