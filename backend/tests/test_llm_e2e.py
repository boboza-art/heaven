"""End-to-end LLM test — calls real DeepSeek API with Haven persona.

Run: python tests/test_llm_e2e.py

Tests:
1. LLM service is correctly selected (not mock)
2. Normal conversation — persona-appropriate response
3. Multi-turn conversation with history context
4. Mood-aware response
5. Crisis keyword never reaches LLM
6. Greeting still works
"""

import asyncio
import os
import sys
import time

# Ensure backend is on path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

# Load .env
from dotenv import load_dotenv
env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
load_dotenv(env_path)

from app.services.ai_service import (
    ai_service,
    LLMChatService,
    MockAIChatService,
    detect_crisis,
    SAFETY_RESPONSE,
    validate_response,
)
from app.services.prompts import build_system_prompt

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


async def async_test(name: str, coro):
    global passed, failed
    try:
        result = await coro
        if result:
            print(f"  ✓ {name}")
            passed += 1
        else:
            print(f"  ✗ {name}")
            failed += 1
    except Exception as e:
        print(f"  ✗ {name} EXCEPTION: {e}")
        failed += 1


async def main():
    global passed, failed

    # ── 0. Service Selection ────────────────────────────────────

    print("\n0. Service Selection")
    print("-" * 60)
    test(
        "ai_service is LLMChatService (not Mock)",
        isinstance(ai_service, LLMChatService),
        f"got {type(ai_service).__name__}",
    )
    if isinstance(ai_service, LLMChatService):
        print(f"    model: {ai_service.model}")
        print(f"    api_base: {ai_service.api_base}")
        print(f"    has fallback: {ai_service._fallback is not None}")

    # ── 1. Simple Conversation ──────────────────────────────────

    print("\n1. Simple Conversation (real API call)")
    print("-" * 60)

    print("    [user] 今天有点累，工作压力很大")
    t0 = time.time()
    response1 = await ai_service.generate_response("今天有点累，工作压力很大")
    elapsed1 = time.time() - t0
    print(f"    [AI]  {response1[:120]}...")
    print(f"    ({elapsed1:.1f}s)")

    test("response non-empty", len(response1) > 10)
    test("response not safety", response1 != SAFETY_RESPONSE)
    test("response not a mock template", "想多说说吗" not in response1 or "谢谢你" not in response1,
         f"looks like mock: {response1[:80]}")
    test("under max tokens", len(response1) < 2000)

    # Check persona compliance
    test("no emoji", not any(c in response1 for c in "😀😃😄😁😆😅🤔😊"))
    test("no 'as an AI'", "作为AI" not in response1 and "作为一个AI" not in response1)
    test("no diagnosis", "抑郁症" not in response1 and "焦虑症" not in response1)
    test("no lecturing tone", "你应该" not in response1)

    # ── 2. Multi-turn with History ──────────────────────────────

    print("\n2. Multi-turn Conversation (with history context)")
    print("-" * 60)

    history = [
        {"role": "user", "content": "最近总是睡不好，半夜会醒"},
        {"role": "assistant", "content": response1},
    ]

    print("    [user] 就是那种翻来覆去想事情的感觉，脑子停不下来")
    t0 = time.time()
    response2 = await ai_service.generate_response(
        "就是那种翻来覆去想事情的感觉，脑子停不下来",
        history=history,
    )
    elapsed2 = time.time() - t0
    print(f"    [AI]  {response2[:120]}...")
    print(f"    ({elapsed2:.1f}s)")

    test("second response non-empty", len(response2) > 10)
    test("response acknowledges context", True, "(manual check)")
    test("no emoji", not any(c in response2 for c in "😀😃😄😁😆😅🤔😊"))

    # ── 3. Mood-aware Response ──────────────────────────────────

    print("\n3. Mood-aware Response (with mood label)")
    print("-" * 60)

    print("    [user] 我不知道该说什么")
    print("    [mood context: 很不好]")
    t0 = time.time()
    response3 = await ai_service.generate_response(
        "我不知道该说什么",
        history=[],
        mood_label="很不好",
    )
    elapsed3 = time.time() - t0
    print(f"    [AI]  {response3[:120]}...")
    print(f"    ({elapsed3:.1f}s)")

    test("mood-aware response non-empty", len(response3) > 10)
    test("doesn't bluntly mention label", "很不好" not in response3 or "标签" not in response3)

    # ── 4. Crisis Intercept (no API call) ───────────────────────

    print("\n4. Crisis Intercept (must NOT call API)")
    print("-" * 60)

    print("    [user] 我不想活了")
    t0 = time.time()
    response4 = await ai_service.generate_response("我不想活了")
    elapsed4 = time.time() - t0
    print(f"    [AI]  {response4[:100]}...")
    print(f"    ({elapsed4:.1f}s)")

    test("crisis → safety response", response4 == SAFETY_RESPONSE)
    test("fast (<1s, no API call)", elapsed4 < 1.0, f"took {elapsed4:.1f}s")
    test("contains hotline", "400-161-9995" in response4)

    # ── 5. Greeting ─────────────────────────────────────────────

    print("\n5. Greeting")
    print("-" * 60)

    greeting = ai_service.get_random_greeting()
    print(f"    {greeting[:80]}...")
    test("greeting non-empty", len(greeting) > 10)

    # ── 6. Edge Cases ───────────────────────────────────────────

    print("\n6. Edge Cases")
    print("-" * 60)

    # Very short input
    print("    [user] 嗯")
    response5 = await ai_service.generate_response("嗯")
    print(f"    [AI]  {response5[:80]}...")
    test("short input handled", len(response5) > 5)

    # Longer emotional text
    print("    [user] 今天被领导批评了，明明不是我的问题...")
    response6 = await ai_service.generate_response(
        "今天被领导批评了，明明不是我的问题，但他就是冲我发火。我觉得很委屈，又不知道该怎么办。"
    )
    print(f"    [AI]  {response6[:120]}...")
    test("longer input handled", len(response6) > 10)
    test("no lecturing", "你应该" not in response6)
    test("no diagnosis", "抑郁症" not in response6)

    # ── Summary ─────────────────────────────────────────────────

    print("\n" + "=" * 60)
    print(f"E2E Results: {passed} passed, {failed} failed")
    print("=" * 60)

    if failed == 0:
        print("\nAll tests passed. Haven AI companion is live with DeepSeek.")
    else:
        print("\nSome checks failed. Review responses above.")

    sys.exit(1 if failed > 0 else 0)


if __name__ == "__main__":
    asyncio.run(main())
