"""Tests for Haven Memory System — extraction, injection, CRUD, integration.

Run: python tests/test_memory_system.py
"""

import asyncio
import os
import sys
import json
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import uuid4

# Ensure backend is on path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

# Set test env
os.environ.setdefault("DATABASE_URL", "sqlite:///test_memory.db")
os.environ.setdefault("LLM_API_KEY", "")
os.environ.setdefault("MEMORY_EXTRACTION_ENABLED", "true")
os.environ.setdefault("MEMORY_MAX_IN_PROMPT", "10")

# ── Setup: use SQLite for testing ─────────────────────────────────

from app.database import Base, engine, SessionLocal
from app.models.user import User
from app.models.memory import Memory
from app.models.chat import ChatMessage
from app.services.memory_service import (
    MemoryExtractionService,
    memory_service,
    format_memories_for_prompt,
    is_duplicate,
    _similarity,
)
from app.services.prompts import build_system_prompt, SYSTEM_PROMPT
from app.services.ai_service import MockAIChatService, LLMChatService
from app.config import settings

# Create tables
Base.metadata.create_all(bind=engine)

passed = 0
failed = 0


def test(name: str, condition: bool, detail: str = ""):
    global passed, failed
    if condition:
        print(f"  ✓ {name}")
        passed += 1
    else:
        print(f"  ✗ {name} {detail}")
        failed += 1


async def async_test(name: str, coro, detail: str = ""):
    global passed, failed
    try:
        result = await coro
        if result:
            print(f"  ✓ {name}")
            passed += 1
        else:
            print(f"  ✗ {name} {detail}")
            failed += 1
    except Exception as e:
        print(f"  ✗ {name} EXCEPTION: {e}")
        failed += 1


# ── Helper: create test user ──────────────────────────────────────

def create_test_user(db, username="memuser"):
    user = User(email=f"{username}@test.com", password_hash="fake", nickname=username)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


# ── 1. Deduplication ─────────────────────────────────────────────

print("\n1. Deduplication")
print("-" * 50)

test(
    "exact same content → duplicate",
    is_duplicate("工作压力大", ["工作压力大"]),
)
test(
    "completely different → not duplicate",
    not is_duplicate("工作压力大", ["喜欢吃甜食"]),
)
test(
    "high overlap → duplicate",
    is_duplicate("工作压力大", ["工作压力大，项目很忙"]),  # substring containment
)
test(
    "reverse containment → duplicate",
    is_duplicate("工作压力大，项目赶deadline", ["工作压力大"]),
)
test(
    "low overlap → not duplicate",
    not is_duplicate("今天天气不错", ["工作压力大"]),
)
test(
    "empty existing list → not duplicate",
    not is_duplicate("anything", []),
)

sim = _similarity("hello world foo", "hello world bar")
test("similarity score in range", 0.0 < sim < 1.0, f"got {sim}")


# ── 2. Memory Formatting for Prompt ──────────────────────────────

print("\n2. Memory Formatting for Prompt")
print("-" * 50)

no_memories = format_memories_for_prompt([])
test("empty list → empty string", no_memories == "")

memories = [
    {"category": "situation", "content": "工作压力大，项目赶deadline"},
    {"category": "coping", "content": "散步能帮助放松"},
]
formatted = format_memories_for_prompt(memories)
test("has section header", "你对用户的了解" in formatted)
test("contains first memory", "工作压力大" in formatted)
test("contains second memory", "散步" in formatted)
test("has bullet points", formatted.count("- ") == 2)


# ── 3. System Prompt with Memories ───────────────────────────────

print("\n3. System Prompt with Memories")
print("-" * 50)

prompt_with_mem = build_system_prompt(mood_label="不太好", memories=memories)
test("prompt has memories section", "你对用户的了解" in prompt_with_mem)
test("prompt has mood section", "用户当前情绪状态" in prompt_with_mem)
test("memories come before mood", prompt_with_mem.index("你对用户的了解") < prompt_with_mem.index("用户当前情绪状态"))

prompt_mem_only = build_system_prompt(memories=memories)
test("memories only, no mood section", "你对用户的了解" in prompt_mem_only and "用户当前情绪状态" not in prompt_mem_only)

prompt_nothing = build_system_prompt()
test("nothing → base prompt only", prompt_nothing == SYSTEM_PROMPT)


# ── 4. Mock Service Accepts Memories (no crash) ──────────────────

print("\n4. AI Service — Memories Parameter")
print("-" * 50)

mock = MockAIChatService()

async def test_mock_with_memories():
    resp = await mock.generate_response("今天有点累", memories=memories)
    return len(resp) > 5

asyncio.run(async_test("mock accepts memories param", test_mock_with_memories()))

# LLM service message building with memories
llm = LLMChatService(
    api_key="test-key",
    api_base="https://api.openai.com/v1",
    model="gpt-4o-mini",
    context_window=5,
    fallback=MockAIChatService(),
)

messages = llm._build_messages("你好", None, mood_label="不太好", memories=memories)
test("system prompt has memories", "你对用户的了解" in messages[0]["content"])
test("system prompt has mood", "不太好" in messages[0]["content"])
test("messages ends with user input", messages[-1] == {"role": "user", "content": "你好"})


# ── 5. Memory Extraction — Parsing ──────────────────────────────

print("\n5. Memory Extraction — Response Parsing")
print("-" * 50)

svc = MemoryExtractionService(api_key="test-key", api_base="https://api.openai.com/v1", model="gpt-4o-mini")

# Test JSON array parsing
raw_json = json.dumps([
    {"category": "situation", "content": "工作压力大"},
    {"category": "coping", "content": "散步能放松"},
])
parsed = svc._parse_extraction_response(raw_json)
test("parse JSON array", len(parsed) == 2 and parsed[0]["category"] == "situation")

# Test wrapped format
raw_wrapped = json.dumps({"memories": [
    {"category": "preference", "content": "不喜欢呼吸练习"},
]})
parsed = svc._parse_extraction_response(raw_wrapped)
test("parse wrapped format", len(parsed) == 1 and parsed[0]["content"] == "不喜欢呼吸练习")

# Test empty response
parsed_empty = svc._parse_extraction_response("")
test("empty string → empty list", parsed_empty == [])

# Test malformed JSON with embedded array
raw_malformed = 'Here are the memories:\n[{"category": "event", "content": "最近分手了"}]\nDone.'
parsed_malformed = svc._parse_extraction_response(raw_malformed)
test("extract JSON from text", len(parsed_malformed) == 1 and parsed_malformed[0]["content"] == "最近分手了")

# Test no JSON at all
parsed_none = svc._parse_extraction_response("no json here at all")
test("no JSON → empty list", parsed_none == [])


# ── 6. Memory Extraction — Dedup Against Existing ──────────────

print("\n6. Memory Extraction — Deduplication")
print("-" * 50)

extracted = [
    {"category": "situation", "content": "工作压力大"},
    {"category": "situation", "content": "工作压力大，项目很忙"},  # dup of existing (substring)
    {"category": "coping", "content": "散步能放松"},
]

existing = ["工作压力大"]
result = []
for item in extracted:
    content = item["content"].strip()
    if is_duplicate(content, existing):
        continue
    if is_duplicate(content, [r["content"] for r in result]):
        continue
    result.append({"category": item["category"], "content": content})

test("dedup removes similar", len(result) == 1)
test("only keeps unrelated item", result[0]["content"] == "散步能放松")


# ── 7. Memory Extraction — Mocked LLM Call ──────────────────────

print("\n7. Memory Extraction — Mocked LLM Call")
print("-" * 50)

async def test_extraction_mocked():
    fake_response = {
        "choices": [{
            "message": {
                "content": json.dumps([
                    {"category": "situation", "content": "最近在准备考试"},
                    {"category": "concern", "content": "担心考不好"},
                ])
            }
        }]
    }
    mock_resp = MagicMock()
    mock_resp.raise_for_status = MagicMock()
    mock_resp.json = MagicMock(return_value=fake_response)

    mock_client = AsyncMock()
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=None)
    mock_client.post = AsyncMock(return_value=mock_resp)

    with patch("httpx.AsyncClient", return_value=mock_client):
        result = await svc.extract_memories(
            [{"role": "user", "content": "我最近在准备考试"},
             {"role": "assistant", "content": "考试确实让人有压力。"}],
            existing_contents=[],
        )
    return len(result) == 2 and result[0]["content"] == "最近在准备考试"

asyncio.run(async_test("extract with mocked LLM", test_extraction_mocked()))


# ── 8. Memory Extraction — No API Key ───────────────────────────

print("\n8. Memory Extraction — No LLM Available")
print("-" * 50)

no_key_svc = MemoryExtractionService(api_key="", api_base="https://api.openai.com/v1", model="gpt-4o-mini")
test("is_available = False when no key", not no_key_svc.is_available)

async def test_no_extraction_without_key():
    result = await no_key_svc.extract_memories(
        [{"role": "user", "content": "hi"}, {"role": "assistant", "content": "hello"}]
    )
    return result == []

asyncio.run(async_test("no key → empty extraction", test_no_extraction_without_key()))

async def test_short_conversation_skipped():
    result = await svc.extract_memories([{"role": "user", "content": "hi"}])
    return result == []

asyncio.run(async_test("short conversation → skipped", test_short_conversation_skipped()))


# ── 9. Memory CRUD — Database Integration ──────────────────────

print("\n9. Memory CRUD — Database")
print("-" * 50)

# Clean up test DB
db = SessionLocal()
try:
    # Clean any existing data
    db.query(Memory).delete()
    db.query(User).delete()
    db.commit()

    user = create_test_user(db)

    # Create a memory
    mem1 = Memory(user_id=user.id, category="situation", content="工作压力大", approved=True)
    mem2 = Memory(user_id=user.id, category="coping", content="散步能放松", approved=False)
    mem3 = Memory(user_id=user.id, category="preference", content="喜欢晚上聊天", approved=True)
    db.add_all([mem1, mem2, mem3])
    db.commit()
    db.refresh(mem1)
    db.refresh(mem2)
    db.refresh(mem3)

    # Query all
    all_mems = db.query(Memory).filter(Memory.user_id == user.id).all()
    test("created 3 memories", len(all_mems) == 3)

    # Query approved only
    approved = db.query(Memory).filter(Memory.user_id == user.id, Memory.approved == True).all()
    test("2 approved memories", len(approved) == 2)

    # Query pending only
    pending = db.query(Memory).filter(Memory.user_id == user.id, Memory.approved == False).all()
    test("1 pending memory", len(pending) == 1)

    # Approve pending
    pending[0].approved = True
    db.commit()
    approved_after = db.query(Memory).filter(Memory.user_id == user.id, Memory.approved == True).all()
    test("approve pending → 3 approved", len(approved_after) == 3)

    # Delete one
    db.delete(mem3)
    db.commit()
    remaining = db.query(Memory).filter(Memory.user_id == user.id).all()
    test("delete → 2 remaining", len(remaining) == 2)

    # Format for prompt injection
    approved_mems = [
        {"category": m.category, "content": m.content}
        for m in db.query(Memory)
        .filter(Memory.user_id == user.id, Memory.approved == True)
        .order_by(Memory.created_at.desc())
        .limit(settings.memory_max_in_prompt)
        .all()
    ]
    test("query memories as dicts", len(approved_mems) == 2)
    test("has category and content", "category" in approved_mems[0] and "content" in approved_mems[0])

    # Clean up
    db.query(Memory).delete()
    db.query(User).delete()
    db.commit()
finally:
    db.close()


# ── 10. Chat Router Memory Injection ───────────────────────────

print("\n10. Chat Router — Memory Injection Logic")
print("-" * 50)

# Simulate what _get_approved_memories does
db = SessionLocal()
try:
    db.query(Memory).delete()
    db.query(User).delete()
    db.commit()

    user = create_test_user(db)
    mems = [
        Memory(user_id=user.id, category="situation", content="工作压力大", approved=True),
        Memory(user_id=user.id, category="coping", content="散步能放松", approved=True),
        Memory(user_id=user.id, category="preference", content="不喜欢呼吸练习", approved=False),
    ]
    db.add_all(mems)
    db.commit()

    # Simulate _get_approved_memories
    from app.routers.chat import _get_approved_memories
    result = _get_approved_memories(db, user.id)
    test("only approved memories returned", len(result) == 2)
    test("no pending memories", all("不喜欢呼吸练习" not in r["content"] for r in result))
    test("dict format correct", "category" in result[0] and "content" in result[0])

    # Test with limit
    result_limited = _get_approved_memories(db, user.id, limit=1)
    test("limit works", len(result_limited) == 1)

    db.query(Memory).delete()
    db.query(User).delete()
    db.commit()
finally:
    db.close()


# ── 11. End-to-End: Prompt with Real Memory Injection ──────────

print("\n11. End-to-End — Full Prompt with Memories")
print("-" * 50)

real_memories = [
    {"category": "situation", "content": "最近工作压力大，项目赶deadline"},
    {"category": "preference", "content": "不喜欢呼吸练习，更喜欢倾诉"},
    {"category": "coping", "content": "散步能帮助放松"},
]

full_prompt = build_system_prompt(mood_label="不太好", memories=real_memories)

test("has persona identity", "温和的心理支持陪伴者" in full_prompt)
test("has memories section", "你对用户的了解" in full_prompt)
test("has all 3 memories", all(m["content"] in full_prompt for m in real_memories))
test("has mood section", "用户当前情绪状态" in full_prompt)
test("memories before mood", full_prompt.index("你对用户的了解") < full_prompt.index("用户当前情绪状态"))
test("memories before persona end", full_prompt.index("你对用户的了解") > full_prompt.index("足够了。"))

# Verify LLM would get memories in context
messages = llm._build_messages("今天又加班了", history=None, mood_label=None, memories=real_memories)
test("LLM system message has memories", "你对用户的了解" in messages[0]["content"])
test("LLM gets user message last", messages[-1] == {"role": "user", "content": "今天又加班了"})


# ── 12. Memory Extraction — Category Validation ────────────────

print("\n12. Memory Extraction — Category Validation")
print("-" * 50)

async def test_category_validation():
    """Unknown categories should be normalized to 'situation'."""
    fake_response = {
        "choices": [{
            "message": {
                "content": json.dumps([
                    {"category": "unknown_cat", "content": "something about the user"},
                    {"category": "coping", "content": "journaling helps"},
                ])
            }
        }]
    }
    mock_resp = MagicMock()
    mock_resp.raise_for_status = MagicMock()
    mock_resp.json = MagicMock(return_value=fake_response)

    mock_client = AsyncMock()
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=None)
    mock_client.post = AsyncMock(return_value=mock_resp)

    with patch("httpx.AsyncClient", return_value=mock_client):
        result = await svc.extract_memories(
            [{"role": "user", "content": "test"}, {"role": "assistant", "content": "test"}],
        )
    return (
        len(result) == 2
        and result[0]["category"] == "situation"  # unknown → situation
        and result[1]["category"] == "coping"
    )

asyncio.run(async_test("unknown category → situation", test_category_validation()))


# ── Summary ──────────────────────────────────────────────────────

print("\n" + "=" * 50)
print(f"Results: {passed} passed, {failed} failed")
print("=" * 50)

# Cleanup test DB
try:
    os.remove("test_memory.db")
except:
    pass

sys.exit(1 if failed > 0 else 0)
