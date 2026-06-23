from fastapi import APIRouter, HTTPException

from app.ml.event_success_model import event_success_model
from app.models.prediction import EventSuccessPredictRequest, EventSuccessPredictResponse

router = APIRouter()


@router.post("/event-success", response_model=EventSuccessPredictResponse)
def predict_event_success(payload: EventSuccessPredictRequest) -> EventSuccessPredictResponse:
    try:
        result = event_success_model.predict(payload.model_dump())
    except FileNotFoundError as exc:
        raise HTTPException(
            status_code=503,
            detail=str(exc),
        ) from exc
    return EventSuccessPredictResponse(**result)
