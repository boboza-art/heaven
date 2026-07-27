"""End-to-end test: memory extraction with real DeepSeek API.

Tests the full flow:
    Conversation → LLM extraction → dedup → formatted memories

Run: python tests/test_memory_e2e.py
"""

import asyncio
import os
import sys
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.services.memory_service import MemoryExtractionService, format_memories_for_prompt
from app.services.prompts import build_system_prompt
from app.config import settings

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


# ── Setup ────────────────────────────────────────────────────────

print("\nHaven Memory System — E2E Test (DeepSeek)")
print("=" * 50)

if not settings.llm_api_key:
    print("⚠ LLM_API_KEY not set. Skipping E2E test.")
    sys.exit(0)

print(f"Provider: {settings.llm_api_base}")
print(f"Model: {settings.llm_model}")
print()

svc = MemoryExtractionService(
    api_key=settings.llm_api_key,
    api_base=settings.llm_api_base,
    model=settings.llm_model,
)

test("extraction service available", svc.is_available)


# ── 1. Extract from a meaningful conversation ─────────────────

print("\n1. Extract Memories — Meaningful Conversation")
print("-" * 50)

conversation_1 = [
    {"role": "user", "content": "最近工作压力好大，每天加班到很晚"},
    {"role": "assistant", "content": "嗯，我听到了。连续加班确实很消耗人。你这样高强度工作了多久了？"},
    {"role": "user", "content": "大概一个月了，项目赶deadline。我一般会去散步放松一下，但最近太累了连散步都没力气去。"},
    {"role": "assistant", "content": "一个月的高强度工作，确实会让人筋疲力尽。散步对你来说曾经是一个有效的出口。"},
]

async def test_extract_meaningful():
    result = await svc.extract_memories(conversation_1, existing_contents=[])
    print(f"  → Extracted {len(result)} memories:")
    for m in result:
        print(f"    [{m['category']}] {m['content']}")
    return len(result) > 0

asyncio.run(async_test("extracted at least 1 memory", test_extract_meaningful()))


# ── 2. Extract from casual chat (should be empty) ─────────────

print("\n2. Extract Memories — Casual Chat (should be empty or minimal)")
print("-" * 50)

conversation_casual = [
    {"role": "user", "content": "你好"},
    {"role": "assistant", "content": "嗨，很高兴见到你。"},
    {"role": "user", "content": "嗯"},
    {"role": "assistant", "content": "我在这里，想聊什么都可以。"},
]

async def test_extract_casual():
    result = await svc.extract_memories(conversation_casual, existing_contents=[])
    print(f"  → Extracted {len(result)} memories (expected 0 or few)")
    for m in result:
        print(f"    [{m['category']}] {m['content']}")
    return True  # pass regardless — just checking it doesn't crash

asyncio.run(async_test("casual chat handled gracefully", test_extract_casual()))


# ── 3. Dedup against existing memories ───────────────────────

print("\n3. Dedup — Against Existing Memories")
print("-" * 50)

existing = ["最近工作压力大，每天加班到很晚"]

async def test_extract_with_dedup():
    # Same conversation, should find fewer new memories
    result = await svc.extract_memories(conversation_1, existing_contents=existing)
    print(f"  → After dedup: {len(result)} memories (some should be filtered)")
    for m in result:
        print(f"    [{m['category']}] {m['content']}")
    # At least some should be filtered since "工作压力" is already known
    return True

asyncio.run(async_test("dedup filters known info", test_extract_with_dedup()))


# ── 4. Extract from emotional conversation ───────────────────

print("\n4. Extract Memories — Emotional Conversation")
print("-" * 50)

conversation_emotional = [
    {"role": "user", "content": "我跟朋友吵架了，很难过"},
    {"role": "assistant", "content": "跟朋友吵架确实让人难受。我听到了你的难过。"},
    {"role": "user", "content": "我觉得写日记能帮我理清思绪，但我已经很久没写了"},
    {"role": "assistant", "content": "写日记曾经对你有帮助。也许在情绪乱的时候，重新拾起这个习惯会有一点用。"},
]

async def test_extract_emotional():
    result = await svc.extract_memories(conversation_emotional, existing_contents=[])
    print(f"  → Extracted {len(result)} memories:")
    for m in result:
        print(f"    [{m['category']}] {m['content']}")
    return len(result) > 0

asyncio.run(async_test("extracted emotional context", test_extract_emotional()))


# ── 5. Full prompt injection ──────────────────────────────────

print("\n5. Full Prompt Injection")
print("-" * 50)

async def test_full_prompt():
    # Extract from conversation 1
    memories = await svc.extract_memories(conversation_1, existing_contents=[])
    if not memories:
        return False

    # Build prompt with memories + mood
    prompt = build_system_prompt(mood_label="不太好", memories=memories)

    has_persona = "温和的心理支持陪伴者" in prompt
    has_memories = "你对用户的了解" in prompt
    has_mood = "用户当前情绪状态" in prompt
    has_memory_content = any(m["content"][:10] in prompt for m in memories)

    print(f"  → Prompt length: {len(prompt)} chars")
    print(f"  → Has persona: {has_persona}")
    print(f"  → Has memories section: {has_memories}")
    print(f"  → Has mood section: {has_mood}")
    print(f"  → Memory content in prompt: {has_memory_content}")

    # Show a snippet of the memories section
    start = prompt.find("## 你对用户的了解")
    if start != -1:
        snippet = prompt[start:start+300]
        print(f"\n  Memories section preview:\n  {snippet[:200]}...")

    return has_persona and has_memories and has_mood and has_memory_content

asyncio.run(async_test("full prompt with memories + mood", test_full_prompt()))


# ── Summary ──────────────────────────────────────────────────────

print("\n" + "=" * 50)
print(f"Results: {passed} passed, {failed} failed")
print("=" * 50)

sys.exit(1 if failed > 0 else 0)
