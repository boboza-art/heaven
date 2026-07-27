"""Memory model — AI-accumulated context about the user."""

import uuid
from datetime import datetime, timezone

from sqlalchemy import Column, String, Text, Boolean, DateTime, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class Memory(Base):
    """A piece of information the AI remembers about the user."""

    __tablename__ = "memories"
    __table_args__ = (
        Index("ix_memories_user_approved_created", "user_id", "approved", "created_at"),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    category = Column(String(50), nullable=False)  # e.g. "preference", "event"
    content = Column(Text, nullable=False)
    approved = Column(Boolean, nullable=False, default=False)
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    def __repr__(self):
        return f"<Memory category={self.category}>"
