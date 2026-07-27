"""Exercises router: list, detail, complete."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models.user import User
from app.models.exercise import ExerciseCompletion
from app.schemas.exercise import (
    ExerciseInfo,
    ExerciseComplete,
    ExerciseCompletionOut,
)

router = APIRouter(prefix="/exercises", tags=["exercises"])

# Static exercise catalog — mirrors the Flutter exercise_repository.dart
EXERCISES: list[ExerciseInfo] = [
    ExerciseInfo(
        id="breathing-478",
        title="4-7-8 呼吸法",
        category="呼吸",
        description="通过 4 秒吸气、7 秒屏息、8 秒呼气的节奏，帮助神经系统放松。",
        duration_minutes=3,
        icon="air",
    ),
    ExerciseInfo(
        id="grounding-54321",
        title="5-4-3-2-1 感官练习",
        category="稳定",
        description="通过五感回到当下，缓解焦虑和过度思考。",
        duration_minutes=2,
        icon="psychology",
    ),
    ExerciseInfo(
        id="gratitude-journal",
        title="三件好事",
        category="感恩",
        description="记录今天三件温暖的小事，培养对美好事物的觉察。",
        duration_minutes=3,
        icon="favorite",
    ),
    ExerciseInfo(
        id="body-scan-brief",
        title="快速身体扫描",
        category="身体",
        description="从头到脚注意身体各部位的感受，释放紧张。",
        duration_minutes=4,
        icon="self_improvement",
    ),
]

EXERCISE_MAP = {e.id: e for e in EXERCISES}


@router.get("", response_model=list[ExerciseInfo])
def list_exercises(user: User = Depends(get_current_user)):
    """List all available exercises."""
    return EXERCISES


@router.get("/{exercise_id}", response_model=ExerciseInfo)
def get_exercise(
    exercise_id: str,
    user: User = Depends(get_current_user),
):
    """Get details of a specific exercise."""
    exercise = EXERCISE_MAP.get(exercise_id)
    if not exercise:
        raise HTTPException(status_code=404, detail="练习不存在")
    return exercise


@router.post("/{exercise_id}/complete", response_model=ExerciseCompletionOut, status_code=201)
def complete_exercise(
    exercise_id: str,
    payload: ExerciseComplete,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Mark an exercise as completed."""
    if exercise_id not in EXERCISE_MAP:
        raise HTTPException(status_code=404, detail="练习不存在")

    completion = ExerciseCompletion(
        user_id=user.id,
        exercise_id=exercise_id,
        duration_seconds=payload.duration_seconds,
    )
    db.add(completion)
    db.commit()
    db.refresh(completion)
    return completion
