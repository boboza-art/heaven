# Prompt Framework

## Pipeline

```
User Input
    ↓
Safety Layer (危机关键词前置拦截 — 始终生效，不调用 LLM)
    ↓
Context Builder (对话历史 + 当前情绪 + 已批准记忆 → messages 数组)
    ↓
LLM (OpenAI 兼容 API) / Mock (关键词匹配回退)
    ↓
Validator (截断超长 / 替换空值)
    ↓
Response → 返回给用户 (不等待提取)
    ↓
Memory Extraction (异步 fire-and-forget: LLM 提取 → 去重 → 存 DB)
```

## 实现

- **Safety Layer**: `detect_crisis()` — 9 个危机关键词，命中即返回安全响应 + 心理援助热线 (400-161-9995 / 400-821-1215)
- **Context Builder**: `chat.py` 路由从 DB 获取:
  - 最近 20 条对话 (按时间正序)
  - 用户最新情绪标签 (mood_level → 中文)
  - 已批准记忆 (approved=True, limit=MEMORY_MAX_IN_PROMPT)
- **LLM**: `LLMChatService._call_llm()` — httpx 异步调用 `/v1/chat/completions`
- **Mock**: `MockAIChatService` — 关键词匹配 + 模板组合 (无外部依赖)
- **Validator**: `validate_response()` — 截断 >1000 字、替换空回复
- **Memory Extraction**: `MemoryExtractionService` — 对话后异步提取，JSON 解析 → 去重 → 存 DB (approved=False)

## 系统 Prompt

定义于 `backend/app/services/prompts.py`，基于 `AI_Persona.md`：

- **身份**: 温和的心理支持陪伴者
- **行为**: 先理解 → 后探索 → 给选择 → 不强迫
- **禁忌**: 不诊断、不说教、不夸张承诺、不自我指涉
- **风格**: 2-4 句话、中文、柔和、无 emoji
- **情绪感知**: 自动注入用户当前情绪标签 (如"焦虑""难过")
- **记忆注入**: 已批准记忆以 "## 你对用户的了解" 注入，在情绪感知之前

### Prompt 结构顺序

```
1. 基础身份与行为准则 (SYSTEM_PROMPT)
2. 你对用户的了解 (approved memories, 如有)
3. 用户当前情绪状态 (mood_label, 如有)
```

## 记忆系统

### 记忆分类

| 分类 | 说明 |
|------|------|
| `situation` | 用户处境/背景 |
| `preference` | 用户偏好 |
| `concern` | 持续的担忧 |
| `pattern` | 行为模式 |
| `event` | 重要事件 |
| `coping` | 有用的应对方式 |

### 记忆生命周期

```
对话中 AI 自动提取 → approved=False (待审)
    ↓
用户在 App 中查看 → 批准/编辑/删除
    ↓
approved=True → 下次对话注入 system prompt
```

### 去重策略

- **子串包含**: "工作压力大" in "工作压力大，项目赶deadline" → 重复
- **字符 bigram 相似度**: Jaccard 系数 ≥ 0.5 → 重复 (适用于中文无空格文本)
- **双重过滤**: 先对比已存记忆，再对比本轮提取结果内去重

## 模式选择

| 条件 | 服务 | 记忆提取 |
|------|------|---------|
| `LLM_API_KEY` 为空 | MockAIChatService | 跳过 (无 LLM 无法提取) |
| `LLM_API_KEY` 已设置 | LLMChatService (失败回退 Mock) | 开启 (可配置关闭) |

## 支持的 LLM 提供商

任何 OpenAI 兼容 API：
- OpenAI (gpt-4o-mini, gpt-4o, ...)
- DeepSeek (deepseek-chat, ...)
- Moonshot (moonshot-v1-8k, ...)
- 本地 Ollama (llama3, qwen2, ...)
- 其他兼容服务
