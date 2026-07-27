"""Memory schemas — AI-accumulated user context."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class MemoryCreate(BaseModel):
    """Manual memory creation (user or AI adds a memory)."""

    category: str = Field(
        ...,
        max_length=50,
        description="preference, situation, concern, pattern, event, coping",
    )
    content: str = Field(..., min_length=1, max_length=500)


class MemoryUpdate(BaseModel):
    """Update memory content or approval status."""

    content: str | None = Field(default=None, min_length=1, max_length=500)
    approved: bool | None = None
    category: str | None = Field(default=None, max_length=50)


class MemoryOut(BaseModel):
    """Memory response model."""

    id: UUID
    category: str
    content: str
    approved: bool
    created_at: datetime

    class Config:
        from_attributes = True


class MemoryListResponse(BaseModel):
    """Paginated memory list with counts."""

    memories: list[MemoryOut]
    total: int
    approved_count: int
    pending_count: int
