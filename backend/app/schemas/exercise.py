"""Exercise-related Pydantic schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class ExerciseInfo(BaseModel):
    id: str
    title: str
    category: str
    description: str
    duration_minutes: int
    icon: str


class ExerciseComplete(BaseModel):
    duration_seconds: int | None = None


class ExerciseCompletionOut(BaseModel):
    id: UUID
    exercise_id: str
    duration_seconds: int | None
    created_at: datetime

    class Config:
        from_attributes = True
