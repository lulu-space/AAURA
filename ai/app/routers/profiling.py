from fastapi import APIRouter

from app.models.profiling import ShamsChatRequest, ShamsExtractionResult
from app.services.shams_profiling import analyze_message

router = APIRouter()


@router.post("/shams/chat", response_model=ShamsExtractionResult)
def shams_chat(payload: ShamsChatRequest) -> ShamsExtractionResult:
    result = analyze_message(payload.message)
    return ShamsExtractionResult(**result)
