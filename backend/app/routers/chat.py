"""Chat router: send message to AI, get chat history.

Memory integration:
    1. Before AI call: query approved memories, inject into system prompt
    2. After AI response: async extract new memories (fire-and-forget)
"""

import asyncio
import logging

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db, SessionLocal
from app.deps import get_current_user
from app.models.user import User
from app.models.chat import ChatMessage
from app.models.mood import MoodLog
from app.models.memory import Memory
from app.services.ai_service import ai_service
from app.services.memory_service import memory_service
from app.schemas.chat import ChatSend, ChatMessageOut, ChatResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/chat", tags=["chat"])

# Mood level → Chinese label (matches Flutter MoodModel.label)
_MOOD_LABELS = {1: "很不好", 2: "不太好", 3: "一般", 4: "不错", 5: "很好"}


def _get_approved_memories(db: Session, user_id, limit: int = None) -> list[dict[str, str]]:
    """Fetch approved memories for prompt injection."""
    limit = limit or settings.memory_max_in_prompt
    memories = (
        db.query(Memory)
        .filter(Memory.user_id == user_id, Memory.approved == True)
        .order_by(Memory.created_at.desc())
        .limit(limit)
        .all()
    )
    return [{"category": m.category, "content": m.content} for m in memories]


async def _extract_memories_background(
    user_id,
    conversation: list[dict[str, str]],
):
    """Background task: extract memories from conversation and save to DB.

    Creates its own DB session — independent of the request lifecycle.
    """
    if not settings.memory_extraction_enabled:
        return
    if not memory_service.is_available:
        return
    if len(conversation) < 2:
        return

    db = SessionLocal()
    try:
        # Get existing memory contents for dedup
        existing = (
            db.query(Memory.content)
            .filter(Memory.user_id == user_id)
            .all()
        )
        existing_contents = [row[0] for row in existing]

        # Extract via LLM
        extracted = await memory_service.extract_memories(
            conversation, existing_contents
        )

        # Save new memories (pending approval)
        for item in extracted:
            memory = Memory(
                user_id=user_id,
                category=item["category"],
                content=item["content"],
                approved=False,
            )
            db.add(memory)

        if extracted:
            db.commit()
            logger.info("Extracted %d memories for user %s", len(extracted), user_id)
    except Exception as e:
        logger.warning("Memory extraction background task failed: %s", e)
        db.rollback()
    finally:
        db.close()


@router.post("", response_model=ChatResponse)
async def send_message(
    payload: ChatSend,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Send a message to the AI companion and get a response."""
    content = payload.content.strip()
    if not content:
        raise HTTPException(status_code=400, detail="消息不能为空")

    # Save user message
    user_msg = ChatMessage(
        user_id=user.id,
        role="user",
        content=content,
    )
    db.add(user_msg)
    db.commit()
    db.refresh(user_msg)

    # Fetch recent conversation history (before current message, chronological order)
    history_msgs = (
        db.query(ChatMessage)
        .filter(
            ChatMessage.user_id == user.id,
            ChatMessage.id != user_msg.id,  # Exclude current message
        )
        .order_by(ChatMessage.created_at.desc(), ChatMessage.id.desc())
        .limit(20)
        .all()
    )
    history_msgs.reverse()  # oldest → newest
    history = [
        {"role": msg.role, "content": msg.content} for msg in history_msgs
    ]

    # Fetch user's latest mood for context
    latest_mood = (
        db.query(MoodLog)
        .filter(MoodLog.user_id == user.id)
        .order_by(MoodLog.created_at.desc())
        .first()
    )
    mood_label = _MOOD_LABELS.get(latest_mood.mood_level) if latest_mood else None

    # Fetch approved memories for context injection
    memories = _get_approved_memories(db, user.id)

    # Generate AI response (LLM or mock, auto-selected)
    reply = await ai_service.generate_response(
        content, history=history, mood_label=mood_label, memories=memories
    )

    # Save assistant message
    assistant_msg = ChatMessage(
        user_id=user.id,
        role="assistant",
        content=reply,
    )
    db.add(assistant_msg)
    db.commit()
    db.refresh(assistant_msg)

    # Fire-and-forget: extract memories from this conversation turn
    conversation_for_extraction = history + [
        {"role": "user", "content": content},
        {"role": "assistant", "content": reply},
    ]
    asyncio.create_task(
        _extract_memories_background(user.id, conversation_for_extraction)
    )

    return ChatResponse(
        user_message=ChatMessageOut.model_validate(user_msg),
        assistant_message=ChatMessageOut.model_validate(assistant_msg),
    )


@router.get("", response_model=list[ChatMessageOut])
def get_chat_history(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Get chat history, newest first."""
    messages = (
        db.query(ChatMessage)
        .filter(ChatMessage.user_id == user.id)
        .order_by(ChatMessage.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return messages
