"""AI Chat Service — Haven's emotional support companion.

Architecture follows AI_SYSTEM/Prompt_Framework.md:
    User Input → Safety Layer → LLM (or Mock) → Validator → Response

Two implementations:
    - MockAIChatService: keyword-based fallback (no external dependencies)
    - LLMChatService: calls OpenAI-compatible API (OpenAI, DeepSeek, Moonshot, etc.)

Selection is automatic: if LLM_API_KEY is configured, use LLM;
otherwise, use mock. When LLM call fails, optionally fall back to mock.

Follows Haven AI Persona strictly:
    - 温和的心理支持陪伴者
    - 先理解 → 后探索 → 给选择 → 不强迫
    - No: 诊断、说教、夸张承诺
"""

import asyncio
import logging
import random
from typing import Any

import httpx

from app.config import settings
from app.services.prompts import build_system_prompt

logger = logging.getLogger(__name__)


# ── Shared safety layer ──────────────────────────────────────────

CRISIS_KEYWORDS = [
    "不想活了",
    "自杀",
    "结束生命",
    "自残",
    "伤害自己",
    "活不下去",
    "绝望",
    "没意义",
    "死",
]

SAFETY_RESPONSE = (
    "我听到了，谢谢你愿意告诉我。\n\n"
    "我想让你知道，你现在的感受是重要的，也值得被认真对待。\n\n"
    "但是我不能假装我能够处理这么深的问题。如果你现在感到非常难受，"
    "请考虑联系：\n\n"
    "• 全国心理援助热线：400-161-9995\n"
    "• 生命热线：400-821-1215\n\n"
    "你并不孤单。"
)

MAX_RESPONSE_CHARS = 1000


def detect_crisis(text: str) -> bool:
    """Check for crisis keywords in user input."""
    lowered = text.lower()
    return any(kw in lowered for kw in CRISIS_KEYWORDS)


def validate_response(text: str) -> str:
    """Post-LLM response validation.

    - Truncate if too long
    - Replace empty responses with a gentle fallback
    """
    text = text.strip()
    if not text:
        return "嗯，我在听。你想继续说说吗？"
    if len(text) > MAX_RESPONSE_CHARS:
        text = text[:MAX_RESPONSE_CHARS].rsplit("\n", 1)[0] + "…"
    return text


# ── Mock AI Service (fallback) ────────────────────────────────────

class MockAIChatService:
    """Keyword-based mock AI service. Used when no LLM is configured or as fallback."""

    _greetings = [
        "嗨，很高兴见到你。\n\n这里是一个可以安心说话的地方，你想聊点什么都可以。",
        "你好呀。\n\n不用有压力，说什么都行，或者不说也行。我在这里。",
        "欢迎你来。\n\n今天感觉怎么样？不管是什么感受，都没有对错。",
    ]

    _empathetic_responses = [
        [
            "我听到了。谢谢你愿意说出来。",
            "听起来这对你来说很重要。",
            "我能感受到你在很认真地对待这件事。",
            "谢谢你信任我，把这些告诉我。",
        ],
        [
            "嗯，我明白。",
            "这种感觉很真实。",
            "你描述得很清楚，我能理解。",
        ],
        [
            "这不是小事。",
            "你有权利这样感受。",
            "很多人都会有类似的感觉。",
        ],
    ]

    _exploration_prompts = [
        "想多说说吗？",
        "这种感觉是从什么时候开始的？",
        "你希望我帮你梳理一下吗？",
        "如果需要的话，我们可以一起做一个呼吸练习。",
        "你觉得现在最需要的是什么？",
    ]

    _offering_choices = [
        "如果你愿意，我们可以：\n\n"
        "• 继续聊聊这件事\n"
        "• 做一个简单的呼吸练习\n"
        "• 写一写你的感受\n\n"
        "或者，只是安静地待一会儿也可以。",
        "你现在想做什么呢？\n\n"
        "• 继续聊下去\n"
        "• 换个话题\n"
        "• 试试一个小练习\n"
        "• 今天就先到这里\n\n"
        "没有哪个选择更好，选你需要的。",
    ]

    _emotion_keywords = {
        "sad": ["难过", "伤心", "哭", "低落", "抑郁", "糟糕"],
        "anxious": ["焦虑", "担心", "害怕", "紧张", "不安"],
        "angry": ["生气", "愤怒", "烦", "讨厌"],
        "tired": ["累", "疲惫", "困", "没力气"],
        "happy": ["开心", "高兴", "好", "不错"],
    }

    _emotion_acknowledgments = {
        "sad": "我能感受到你现在有些难过。",
        "anxious": "焦虑的感觉确实很不舒服，我能理解。",
        "angry": "生气是正常的，你不需要为这个感觉道歉。",
        "tired": "累的时候确实会让人感觉很无力。",
        "happy": "很高兴你愿意分享这个。",
        "neutral": "",
    }

    def get_random_greeting(self) -> str:
        return random.choice(self._greetings)

    async def generate_response(
        self,
        user_input: str,
        history: list[dict[str, str]] | None = None,
        mood_label: str | None = None,
        memories: list[dict[str, str]] | None = None,
    ) -> str:
        """Generate a mock response. History and mood are accepted but lightly used."""
        await asyncio.sleep(random.uniform(0.8, 2.0))

        text = user_input.strip().lower()

        if detect_crisis(text):
            return SAFETY_RESPONSE

        emotion = self._detect_emotion(text)
        return self._build_persona_response(text, emotion)

    def _detect_emotion(self, text: str) -> str:
        for emotion, keywords in self._emotion_keywords.items():
            if any(kw in text for kw in keywords):
                return emotion
        return "neutral"

    def _build_persona_response(self, text: str, emotion: str) -> str:
        validation_group = random.choice(self._empathetic_responses)
        validate = random.choice(validation_group)
        acknowledge = self._emotion_acknowledgments.get(emotion, "")
        explore = random.choice(self._exploration_prompts)
        offer_choices = random.random() > 0.55

        parts: list[str] = []
        if acknowledge:
            parts.append(acknowledge)
            parts.append("")
        parts.append(validate)
        if random.random() > 0.4:
            parts.append("")
            parts.append(explore)
        if offer_choices:
            parts.append("")
            parts.append("")
            parts.append(random.choice(self._offering_choices))

        return "\n".join(parts).strip()


# ── LLM AI Service ────────────────────────────────────────────────

class LLMChatService:
    """Real LLM-backed AI service using OpenAI-compatible Chat Completions API.

    Works with OpenAI, DeepSeek, Moonshot, local Ollama, and any provider
    that exposes the /v1/chat/completions endpoint.
    """

    def __init__(
        self,
        api_key: str = "",
        api_base: str = "",
        model: str = "",
        temperature: float = 0.7,
        max_tokens: int = 500,
        timeout: int = 30,
        context_window: int = 10,
        fallback: MockAIChatService | None = None,
    ):
        self.api_key = api_key or settings.llm_api_key
        self.api_base = (api_base or settings.llm_api_base).rstrip("/")
        self.model = model or settings.llm_model
        self.temperature = temperature or settings.llm_temperature
        self.max_tokens = max_tokens or settings.llm_max_tokens
        self.timeout = timeout or settings.llm_timeout_seconds
        self.context_window = context_window or settings.llm_context_window
        self._fallback = fallback

    def get_random_greeting(self) -> str:
        """Greeting still uses mock (cheap, no API call needed)."""
        return MockAIChatService().get_random_greeting()

    async def generate_response(
        self,
        user_input: str,
        history: list[dict[str, str]] | None = None,
        mood_label: str | None = None,
        memories: list[dict[str, str]] | None = None,
    ) -> str:
        """Generate an AI response through the pipeline.

        Pipeline: Safety → Build Messages → LLM → Validate → Response
        Falls back to mock if LLM call fails and fallback is enabled.
        """
        text = user_input.strip()

        # Layer 1 — Safety (pre-LLM gate, always active)
        if detect_crisis(text):
            return SAFETY_RESPONSE

        # Layer 2+3 — Build context + system prompt (with memories)
        messages = self._build_messages(text, history, mood_label, memories)

        # Layer 4 — Call LLM
        try:
            raw_response = await self._call_llm(messages)
            return validate_response(raw_response)
        except Exception as e:
            logger.warning("LLM call failed: %s. Falling back to mock.", e)
            if self._fallback:
                return await self._fallback.generate_response(
                    text, history, mood_label, memories
                )
            raise

    def _build_messages(
        self,
        user_input: str,
        history: list[dict[str, str]] | None,
        mood_label: str | None,
        memories: list[dict[str, str]] | None = None,
    ) -> list[dict[str, str]]:
        """Build the OpenAI-compatible messages array."""
        messages: list[dict[str, str]] = [
            {"role": "system", "content": build_system_prompt(mood_label, memories)}
        ]

        # Include recent conversation history (oldest → newest)
        if history:
            recent = history[-(self.context_window):]
            for msg in recent:
                role = msg.get("role", "user")
                content = msg.get("content", "")
                if role in ("user", "assistant") and content:
                    messages.append({"role": role, "content": content})

        # Current user input
        messages.append({"role": "user", "content": user_input})

        return messages

    async def _call_llm(self, messages: list[dict[str, str]]) -> str:
        """Call the OpenAI-compatible Chat Completions API."""
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}",
        }
        payload: dict[str, Any] = {
            "model": self.model,
            "messages": messages,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
        }

        url = f"{self.api_base}/chat/completions"
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            resp = await client.post(url, json=payload, headers=headers)
            resp.raise_for_status()
            data = resp.json()

        # Extract assistant message
        choices = data.get("choices", [])
        if not choices:
            raise ValueError("LLM returned no choices")
        return choices[0]["message"]["content"]


# ── Factory ───────────────────────────────────────────────────────

_mock_service = MockAIChatService()


def get_ai_service() -> MockAIChatService | LLMChatService:
    """Return the appropriate AI service based on configuration.

    If LLM_API_KEY is set → LLMChatService (with mock fallback)
    Otherwise → MockAIChatService
    """
    if settings.llm_api_key:
        return LLMChatService(fallback=_mock_service if settings.llm_fallback_to_mock else None)
    return _mock_service


# Module-level singleton (auto-selected at import time)
ai_service = get_ai_service()
