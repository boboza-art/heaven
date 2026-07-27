"""Memory Service — extracts and manages AI-accumulated user context.

Architecture:
    Conversation → Extraction LLM → Dedup → Store (approved=False)
    Next Conversation → Inject approved memories into system prompt

Categories:
    - situation: 用户当前处境（工作、学习、关系等）
    - preference: 用户偏好（喜欢/不喜欢什么）
    - concern: 持续的担忧或困扰
    - pattern: 行为模式（如"经常深夜使用"）
    - event: 重要事件
    - coping: 用户觉得有用的应对方式
"""

import json
import logging
from typing import Any

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

# ── Extraction Prompt ────────────────────────────────────────────

_EXTRACTION_SYSTEM_PROMPT = """你是一个信息提取助手。你的任务是从用户与AI陪伴者的对话中，提取值得长期记住的用户信息。

只提取有意义的信息，忽略寒暄和闲聊。每条记忆用一句话描述，简洁客观。

分类规则：
- situation: 用户的处境或背景（如"工作压力大""正在考研""刚搬家"）
- preference: 用户偏好（如"不喜欢呼吸练习""喜欢晚上聊天"）
- concern: 持续的担忧（如"担心健康""对未来感到迷茫"）
- pattern: 行为模式（如"经常在深夜寻求倾诉"）
- event: 重要事件（如"最近分手了""考试通过了"）
- coping: 用户觉得有用的应对方式（如"写日记有帮助""散步能缓解"）

输出格式：JSON 数组，每个元素包含 category 和 content 字段。如果没有值得记住的信息，返回空数组 []。

示例输出：
[
  {"category": "situation", "content": "最近工作压力大，项目赶deadline"},
  {"category": "coping", "content": "散步能帮助放松"}
]"""


def _build_extraction_user_prompt(
    conversation: list[dict[str, str]],
) -> str:
    """Build the user prompt for memory extraction."""
    lines = []
    for msg in conversation:
        role_label = "用户" if msg.get("role") == "user" else "AI"
        lines.append(f"{role_label}: {msg.get('content', '')}")
    conversation_text = "\n".join(lines)

    return f"请分析以下对话，提取值得长期记住的用户信息：\n\n{conversation_text}"


# ── Deduplication ────────────────────────────────────────────────


def _char_bigrams(text: str) -> set[str]:
    """Extract character bigrams — works for Chinese (no spaces needed)."""
    text = text.replace(" ", "").replace("\n", "").lower()
    if len(text) < 2:
        return {text} if text else set()
    return {text[i : i + 2] for i in range(len(text) - 1)}


def _similarity(a: str, b: str) -> float:
    """Jaccard similarity based on character bigrams — works for Chinese text."""
    if not a or not b:
        return 0.0
    grams_a = _char_bigrams(a)
    grams_b = _char_bigrams(b)
    if not grams_a or not grams_b:
        return 0.0
    intersection = grams_a & grams_b
    union = grams_a | grams_b
    return len(intersection) / len(union) if union else 0.0


def is_duplicate(
    new_content: str,
    existing_contents: list[str],
    threshold: float = 0.5,
) -> bool:
    """Check if new_content is too similar to any existing memory.

    Uses both bigram similarity and substring containment —
    substring check catches cases like "工作压力大" vs "工作压力大，项目很忙".
    """
    new_lower = new_content.lower().strip()
    for existing in existing_contents:
        existing_lower = existing.lower().strip()
        # Substring containment — one contains the other
        if len(new_lower) >= 4 and new_lower in existing_lower:
            return True
        if len(existing_lower) >= 4 and existing_lower in new_lower:
            return True
        # Bigram similarity
        if _similarity(new_content, existing) >= threshold:
            return True
    return False


# ── Memory Formatting for Prompt Injection ───────────────────────


def format_memories_for_prompt(memories: list[dict[str, str]]) -> str:
    """Format approved memories into a prompt section.

    Args:
        memories: List of {"category": ..., "content": ...} dicts.

    Returns:
        A formatted string for the system prompt, or empty string if no memories.
    """
    if not memories:
        return ""

    lines = ["\n\n## 你对用户的了解", "以下是你之前了解到的关于用户的信息。请在对话中自然地运用这些了解，但不要生硬地罗列或重复这些内容：\n"]
    for m in memories:
        lines.append(f"- {m['content']}")
    return "\n".join(lines)


# ── Memory Extraction Service ───────────────────────────────────


class MemoryExtractionService:
    """Extracts memories from conversations using LLM.

    In Mock mode (no LLM_API_KEY), extraction is skipped — returns empty list.
    """

    def __init__(
        self,
        api_key: str = "",
        api_base: str = "",
        model: str = "",
        temperature: float = 0.3,
        max_tokens: int = 500,
        timeout: int = 15,
    ):
        self.api_key = api_key or settings.llm_api_key
        self.api_base = (api_base or settings.llm_api_base).rstrip("/")
        self.model = model or settings.llm_model
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.timeout = timeout

    @property
    def is_available(self) -> bool:
        """Whether LLM-based extraction is available."""
        return bool(self.api_key)

    async def extract_memories(
        self,
        conversation: list[dict[str, str]],
        existing_contents: list[str] | None = None,
    ) -> list[dict[str, str]]:
        """Extract memories from a conversation.

        Args:
            conversation: List of {"role": "user"|"assistant", "content": ...}
            existing_contents: Existing memory contents for deduplication.

        Returns:
            List of {"category": ..., "content": ...} — deduplicated, non-empty.
        """
        if not self.is_available:
            logger.debug("Memory extraction skipped — no LLM configured")
            return []

        if not conversation or len(conversation) < 2:
            return []

        existing_contents = existing_contents or []

        try:
            raw = await self._call_extraction_llm(conversation)
            candidates = self._parse_extraction_response(raw)
        except Exception as e:
            logger.warning("Memory extraction failed: %s", e)
            return []

        # Deduplicate
        result = []
        for item in candidates:
            content = item.get("content", "").strip()
            category = item.get("category", "situation").strip().lower()
            if not content or len(content) < 4:
                continue
            if category not in (
                "situation", "preference", "concern", "pattern", "event", "coping"
            ):
                category = "situation"
            if is_duplicate(content, existing_contents):
                continue
            if is_duplicate(content, [r["content"] for r in result]):
                continue
            result.append({"category": category, "content": content})

        return result

    async def _call_extraction_llm(
        self, conversation: list[dict[str, str]]
    ) -> str:
        """Call the LLM for memory extraction."""
        messages = [
            {"role": "system", "content": _EXTRACTION_SYSTEM_PROMPT},
            {"role": "user", "content": _build_extraction_user_prompt(conversation)},
        ]

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}",
        }
        payload: dict[str, Any] = {
            "model": self.model,
            "messages": messages,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
            "response_format": {"type": "json_object"},
        }

        url = f"{self.api_base}/chat/completions"
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            resp = await client.post(url, json=payload, headers=headers)
            resp.raise_for_status()
            data = resp.json()

        choices = data.get("choices", [])
        if not choices:
            raise ValueError("Extraction LLM returned no choices")
        return choices[0]["message"]["content"]

    def _parse_extraction_response(
        self, raw: str
    ) -> list[dict[str, str]]:
        """Parse LLM JSON response into memory items.

        Handles both bare JSON arrays and {"memories": [...]} wrappers,
        and gracefully tolerates malformed JSON.
        """
        raw = raw.strip()
        if not raw:
            return []

        # Try direct parse first
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            # Try to extract JSON array from text
            start = raw.find("[")
            end = raw.rfind("]")
            if start != -1 and end != -1:
                try:
                    data = json.loads(raw[start : end + 1])
                except json.JSONDecodeError:
                    logger.warning("Failed to parse extraction response: %s", raw[:200])
                    return []
            else:
                logger.warning("No JSON array found in extraction response: %s", raw[:200])
                return []

        if isinstance(data, dict):
            # Could be {"memories": [...]} or single item
            if "memories" in data:
                data = data["memories"]
            elif "category" in data and "content" in data:
                data = [data]
            else:
                data = []

        if not isinstance(data, list):
            return []

        result = []
        for item in data:
            if isinstance(item, dict) and "content" in item:
                result.append({
                    "category": item.get("category", "situation"),
                    "content": item.get("content", ""),
                })
        return result


# ── Module-level singleton ───────────────────────────────────────

memory_service = MemoryExtractionService()
