"""Mood-related Pydantic schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class MoodCreate(BaseModel):
    mood_level: int = Field(ge=1, le=5)
    note: str | None = Field(default=None, max_length=2000)


class MoodOut(BaseModel):
    id: UUID
    mood_level: int
    note: str | None
    created_at: datetime

    class Config:
        from_attributes = True


class MoodTrendPoint(BaseModel):
    """A single point in the mood trend chart."""
    date: datetime
    mood_level: int


class MoodTrendResponse(BaseModel):
    points: list[MoodTrendPoint]
    average: float | None
    count: int
