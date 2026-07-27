"""Exercise completion record."""

import uuid
from datetime import datetime

from sqlalchemy import Column, String, Integer, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class ExerciseCompletion(Base):
    """Records when a user completes an exercise."""

    __tablename__ = "exercise_completions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    exercise_id = Column(String(100), nullable=False)
    duration_seconds = Column(Integer, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    def __repr__(self):
        return f"<ExerciseCompletion exercise={self.exercise_id}>"
