"""MoodLog model."""

import uuid
from datetime import datetime, timezone

from sqlalchemy import Column, Integer, Text, DateTime, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class MoodLog(Base):
    """A single mood check-in record."""

    __tablename__ = "mood_logs"
    __table_args__ = (
        Index("ix_mood_logs_user_created", "user_id", "created_at"),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    mood_level = Column(Integer, nullable=False)  # 1-5 scale
    note = Column(Text, nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    def __repr__(self):
        return f"<MoodLog level={self.mood_level}>"
