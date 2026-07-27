"""Tests for Haven AI Service — LLM integration + safety + fallback.

Run: python test_ai_service.py
"""

import asyncio
import os
import sys
import json
from unittest.mock import AsyncMock, MagicMock, patch

# Ensure backend is on path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

# Set test env — no LLM key → mock mode
os.environ.setdefault("DATABASE_URL", "sqlite:///test.db")
os.environ.setdefault("LLM_API_KEY", "")

from app.services.ai_service import (
    detect_crisis,
    validate_response,
    SAFETY_RESPONSE,
    MockAIChatService,
    LLMChatService,
    get_ai_service,
)
from app.services.prompts import build_system_prompt, SYSTEM_PROMPT

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


# ── 1. Safety Layer ──────────────────────────────────────────────

print("\n1. Safety Layer (Crisis Detection)")
print("-" * 50)

for kw in ["不想活了", "自杀", "结束生命", "自残", "活不下去"]:
    test(f'detect_crisis("{kw}")', detect_crisis(kw))

test('detect_crisis("今天天气不错")', not detect_crisis("今天天气不错"))
test('detect_crisis("我有点累")', not detect_crisis("我有点累"))
test('detect_crisis("死了这条心")', detect_crisis("死了这条心"))  # contains "死"


# ── 2. Response Validation ──────────────────────────────────────

print("\n2. Response Validation")
print("-" * 50)

test("empty → fallback", validate_response("") == "嗯，我在听。你想继续说说吗？")
test("whitespace → fallback", validate_response("   \n  ") == "嗯，我在听。你想继续说说吗？")

long_text = "a" * 1500
validated = validate_response(long_text)
test("truncate long response", len(validated) <= 1001 and validated.endswith("…"))

test("normal passthrough", validate_response("我听到了。") == "我听到了。")


# ── 3. Mock Service ──────────────────────────────────────────────

print("\n3. Mock AI Service")
print("-" * 50)

mock = MockAIChatService()

greeting = mock.get_random_greeting()
test("greeting non-empty", len(greeting) > 10)

async def test_mock_crisis():
    resp = await mock.generate_response("我不想活了")
    return resp == SAFETY_RESPONSE

async def test_mock_normal():
    resp = await mock.generate_response("今天有点焦虑")
    return len(resp) > 10 and "焦虑" not in resp or len(resp) > 5  # shouldn't crash

asyncio.run(async_test("crisis → safety response", test_mock_crisis()))
asyncio.run(async_test("normal → persona response", test_mock_normal()))


# ── 4. System Prompt ─────────────────────────────────────────────

print("\n4. System Prompt")
print("-" * 50)

test("prompt has persona identity", "温和的心理支持陪伴者" in SYSTEM_PROMPT)
test("prompt has behavior rules", "先理解" in SYSTEM_PROMPT and "后探索" in SYSTEM_PROMPT)
test("prompt has avoidance rules", "不做医学诊断" in SYSTEM_PROMPT)
test("prompt has style guide", "2-4 句话" in SYSTEM_PROMPT)

prompt_with_mood = build_system_prompt("焦虑")
test("mood appended to prompt", "焦虑" in prompt_with_mood)
prompt_no_mood = build_system_prompt(None)
test("no mood → no mood section", "用户当前情绪状态" not in prompt_no_mood)


# ── 5. LLM Service — Message Building ────────────────────────────

print("\n5. LLM Service — Message Building")
print("-" * 50)

llm = LLMChatService(
    api_key="test-key",
    api_base="https://api.openai.com/v1",
    model="gpt-4o-mini",
    context_window=5,
    fallback=MockAIChatService(),
)

# Build messages with history
history = [
    {"role": "user", "content": "你好"},
    {"role": "assistant", "content": "嗨，很高兴见到你。"},
    {"role": "user", "content": "今天有点累"},
    {"role": "assistant", "content": "累的时候确实会让人感觉很无力。"},
]
messages = llm._build_messages("想聊聊", history, mood_label="不太好")

test("messages starts with system", messages[0]["role"] == "system")
test("system prompt has mood", "不太好" in messages[0]["content"])
test("messages ends with user input", messages[-1] == {"role": "user", "content": "想聊聊"})
test("correct total messages (system + 4 history + 1 input)", len(messages) == 6)

# Build without history
messages_no_hist = llm._build_messages("你好", None, None)
test("no history → system + user only", len(messages_no_hist) == 2)

# Build with long history (should truncate to context_window=5)
long_history = [{"role": "user" if i % 2 == 0 else "assistant", "content": f"msg{i}"} for i in range(20)]
messages_trunc = llm._build_messages("current", long_history, None)
# system + 5 history + 1 current = 7
test("history truncated to context_window", len(messages_trunc) == 7)


# ── 6. LLM Service — Fallback on Error ──────────────────────────

print("\n6. LLM Service — Fallback on Error")
print("-" * 50)

async def test_llm_fallback():
    """When LLM call fails, should fall back to mock."""
    with patch.object(llm, "_call_llm", side_effect=Exception("API error")):
        resp = await llm.generate_response("今天有点累")
        return len(resp) > 5  # mock returned something

asyncio.run(async_test("LLM failure → mock fallback", test_llm_fallback()))

async def test_llm_crisis_no_api_call():
    """Crisis input should never call the LLM API."""
    call_count = 0
    original_call = llm._call_llm

    async def counting_call(messages):
        nonlocal call_count
        call_count += 1
        return "should not reach here"

    with patch.object(llm, "_call_llm", side_effect=counting_call):
        resp = await llm.generate_response("我不想活了")
        return resp == SAFETY_RESPONSE and call_count == 0

asyncio.run(async_test("crisis → no LLM API call", test_llm_crisis_no_api_call()))


# ── 7. LLM Service — Successful API Call (mocked) ───────────────

print("\n7. LLM Service — Mocked API Call")
print("-" * 50)

async def test_llm_success():
    """Mock the HTTP response and verify the flow."""
    fake_response_data = {
        "choices": [
            {
                "message": {
                    "role": "assistant",
                    "content": "我听到了，谢谢你愿意说出来。这种感觉是真实的。",
                }
            }
        ]
    }

    mock_response = MagicMock()
    mock_response.raise_for_status = MagicMock()
    mock_response.json = MagicMock(return_value=fake_response_data)

    mock_client = AsyncMock()
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=None)
    mock_client.post = AsyncMock(return_value=mock_response)

    with patch("httpx.AsyncClient", return_value=mock_client):
        resp = await llm.generate_response("我今天很难过")
        return "谢谢你愿意说出来" in resp

asyncio.run(async_test("LLM success → validated response", test_llm_success()))


# ── 8. Factory Selection ────────────────────────────────────────

print("\n8. Factory Selection")
print("-" * 50)

# With no API key → mock
from app.config import settings as test_settings
original_key = test_settings.llm_api_key

test_settings.llm_api_key = ""
service = get_ai_service()
test("no API key → MockAIChatService", isinstance(service, MockAIChatService))

test_settings.llm_api_key = "test-key"
service = get_ai_service()
test("with API key → LLMChatService", isinstance(service, LLMChatService))
test("LLM service has fallback", service._fallback is not None)

test_settings.llm_api_key = original_key


# ── Summary ──────────────────────────────────────────────────────

print("\n" + "=" * 50)
print(f"Results: {passed} passed, {failed} failed")
print("=" * 50)

sys.exit(1 if failed > 0 else 0)
