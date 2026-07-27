"""Mood router: log mood, get history, get trend."""

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models.user import User
from app.models.mood import MoodLog
from app.schemas.mood import MoodCreate, MoodOut, MoodTrendPoint, MoodTrendResponse

router = APIRouter(prefix="/mood", tags=["mood"])


@router.post("", response_model=MoodOut, status_code=201)
def log_mood(
    payload: MoodCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Log a new mood check-in."""
    mood = MoodLog(
        user_id=user.id,
        mood_level=payload.mood_level,
        note=payload.note,
    )
    db.add(mood)
    db.commit()
    db.refresh(mood)
    return mood


@router.get("", response_model=list[MoodOut])
def get_mood_history(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Get mood history, newest first."""
    logs = (
        db.query(MoodLog)
        .filter(MoodLog.user_id == user.id)
        .order_by(MoodLog.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return logs


@router.get("/trend", response_model=MoodTrendResponse)
def get_mood_trend(
    days: int = Query(default=14, ge=1, le=90),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Get mood trend for the last N days."""
    since = datetime.now(timezone.utc) - timedelta(days=days)
    logs = (
        db.query(MoodLog)
        .filter(MoodLog.user_id == user.id, MoodLog.created_at >= since)
        .order_by(MoodLog.created_at.asc())
        .all()
    )

    points = [MoodTrendPoint(date=log.created_at, mood_level=log.mood_level) for log in logs]
    avg = sum(p.mood_level for p in points) / len(points) if points else None

    return MoodTrendResponse(points=points, average=avg, count=len(points))
