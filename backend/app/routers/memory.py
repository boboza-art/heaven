"""Memory router — manage AI-accumulated user context."""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, Integer
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models.user import User
from app.models.memory import Memory
from app.schemas.memory import (
    MemoryCreate,
    MemoryUpdate,
    MemoryOut,
    MemoryListResponse,
)

router = APIRouter(prefix="/memories", tags=["memories"])

VALID_CATEGORIES = {
    "situation",
    "preference",
    "concern",
    "pattern",
    "event",
    "coping",
}


@router.get("", response_model=MemoryListResponse)
def list_memories(
    approved: bool | None = Query(default=None, description="Filter by approval status"),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """List user's memories, optionally filtered by approval status."""
    query = db.query(Memory).filter(Memory.user_id == user.id)

    if approved is not None:
        query = query.filter(Memory.approved == approved)

    # Single query for counts (avoids N+1)
    counts = (
        db.query(
            func.count().label("total"),
            func.coalesce(func.sum(Memory.approved.cast(Integer)), 0).label("approved"),
        )
        .filter(Memory.user_id == user.id)
        .first()
    )
    approved_count = counts.approved or 0
    pending_count = (counts.total or 0) - approved_count

    memories = (
        query.order_by(Memory.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    return MemoryListResponse(
        memories=[MemoryOut.model_validate(m) for m in memories],
        total=counts.total or 0,
        approved_count=approved_count,
        pending_count=pending_count,
    )


@router.post("", response_model=MemoryOut, status_code=201)
def create_memory(
    payload: MemoryCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Manually add a memory. Auto-approved when user creates it."""
    if payload.category not in VALID_CATEGORIES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid category. Must be one of: {', '.join(sorted(VALID_CATEGORIES))}",
        )

    memory = Memory(
        user_id=user.id,
        category=payload.category,
        content=payload.content,
        approved=True,  # User-created memories are auto-approved
    )
    db.add(memory)
    db.commit()
    db.refresh(memory)
    return memory


@router.patch("/{memory_id}", response_model=MemoryOut)
def update_memory(
    memory_id: str,
    payload: MemoryUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Update a memory's content, category, or approval status."""
    memory = (
        db.query(Memory)
        .filter(Memory.id == memory_id, Memory.user_id == user.id)
        .first()
    )
    if not memory:
        raise HTTPException(status_code=404, detail="Memory not found")

    if payload.content is not None:
        memory.content = payload.content
    if payload.approved is not None:
        memory.approved = payload.approved
    if payload.category is not None:
        if payload.category not in VALID_CATEGORIES:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid category. Must be one of: {', '.join(sorted(VALID_CATEGORIES))}",
            )
        memory.category = payload.category

    db.commit()
    db.refresh(memory)
    return memory


@router.delete("/{memory_id}", status_code=204)
def delete_memory(
    memory_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Delete a memory."""
    memory = (
        db.query(Memory)
        .filter(Memory.id == memory_id, Memory.user_id == user.id)
        .first()
    )
    if not memory:
        raise HTTPException(status_code=404, detail="Memory not found")

    db.delete(memory)
    db.commit()
    return None
