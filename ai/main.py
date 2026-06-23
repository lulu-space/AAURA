import os

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import health, predictions, profiling, recommendations, study_plans
from app.services.shams_profiling import prepare_nltk


@asynccontextmanager
async def lifespan(_app: FastAPI):
    try:
        prepare_nltk()
    except Exception:
        pass
    yield


app = FastAPI(title="AAURA AI", version="0.1.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:4000",
        "http://127.0.0.1:4000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(health.router, prefix="/api", tags=["health"])
app.include_router(profiling.router, prefix="/api/profiling", tags=["profiling"])
app.include_router(recommendations.router, prefix="/api/recommendations", tags=["recommendations"])
app.include_router(study_plans.router, prefix="/api/study-plans", tags=["study-plans"])
app.include_router(predictions.router, prefix="/api/predictions", tags=["predictions"])


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", "8000"))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
