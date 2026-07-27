"""Haven Backend — FastAPI Application Entry Point.

Run: uvicorn app.main:app --reload
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import Base, engine
from app.routers import auth, mood, chat, exercises, memory


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifecycle: validate config on startup."""
    # Validate JWT secret is set (not using default)
    if not settings.jwt_secret_key:
        raise ValueError(
            "JWT_SECRET_KEY environment variable is required. "
            "Please set a strong secret key."
        )
    yield


app = FastAPI(
    title="Haven API",
    description="AI 情感支持应用后端 — 温和、安全、不急于解决",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
)

# Routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(mood.router, prefix="/api/v1")
app.include_router(chat.router, prefix="/api/v1")
app.include_router(exercises.router, prefix="/api/v1")
app.include_router(memory.router, prefix="/api/v1")


@app.get("/", tags=["health"])
async def health_check():
    """Health check endpoint."""
    return {"status": "ok", "service": "Haven API", "version": "0.1.0"}


@app.get("/api/v1", tags=["health"])
async def api_info():
    """API version info."""
    return {
        "version": "v1",
        "endpoints": {
            "auth": ["/auth/register", "/auth/login", "/auth/refresh", "/auth/me"],
            "mood": ["", "/mood/trend"],
            "chat": ["", ""],
            "exercises": ["", "/{exercise_id}", "/{exercise_id}/complete"],
            "memories": ["", "/{memory_id}"],
        },
    }
