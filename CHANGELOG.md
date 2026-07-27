# Haven Changelog

## v0.8.0 — 离线缓存 + Web 应用部署 (2026-07-26)

### 离线模式 — 无网络也能用

所有数据操作现在都有离线降级策略。网络断开时，App 展示缓存数据而非空白或报错；恢复连接后自动切回在线模式。

**核心设计：Repository 装饰器模式**

每个 Api*Repository 外包一层 Caching*Repository：
- 在线：调 API → 成功后缓存到 LocalCache (SharedPreferences)
- 离线：返回 LocalCache 缓存数据，写操作暂存本地

**新增文件 (3):**
```
mobile/lib/core/
├── network/connectivity_service.dart    # Riverpod StateNotifier<bool> 追踪在线/离线 (5s 轮询 DNS)
├── cache/local_cache.dart              # SharedPreferences JSON 缓存 (saveList/getList/saveJson/getJson)
└── widgets/offline_banner.dart         # 离线时顶部显示琥珀色横幅，点击重试
```

**修改文件 (9):**
```
mood_repository.dart      # +CachingMoodRepository: 读缓存/写暂存/离线趋势计算
chat_repository.dart      # +CachingChatRepository: 离线回退本地 AIChatService + "（离线模式）"标注
exercise_repository.dart  # +CachingExerciseRepository: 缓存练习列表，离线用默认值
memory_repository.dart    # +CachingMemoryRepository: 离线 CRUD 全部映射到缓存
mood_controller.dart      # provider 切换到 CachingMoodRepository
chat_controller.dart      # provider 切换到 CachingChatRepository
exercise_controller.dart  # provider 切换到 CachingExerciseRepository
memory_controller.dart   # provider 切换到 CachingMemoryRepository
today_page.dart           # 顶部添加 OfflineBanner
core.dart                 # barrel export 新文件
dio_provider.dart         # initNetwork() 初始化 LocalCache
```

**离线行为详表：**
| Feature | 在线 | 离线 |
|---------|------|------|
| Mood 记录 | API + 缓存 | 本地暂存，恢复后自动丢弃 |
| Mood 历史 | API + 缓存 | 返回缓存数据 |
| Mood 趋势 | API | 从缓存计算平均 |
| Chat 对话 | API + LLM | 本地 AIChatService (Mock) + "（离线模式）"标注 |
| Chat 历史 | API + 缓存 | 返回缓存数据 |
| Exercise 列表 | API + 缓存 | 缓存或内置默认值 |
| Exercise 完成 | API | 本地标记 |
| Memory 列表 | API + 缓存 | 返回缓存数据 |
| Memory CRUD | API | 本地缓存变更 |

**文件统计：** 109 → 112 (Dart: 51 → 54)

---

### Web 应用部署 — 浏览器直接可用

将 Haven 核心功能完整迁移到 Web，生成单文件可执行应用。

**新增文件 (2):**
```
docs/index.html      # 完整 Haven Web 应用 (SPA, 10 页面, localStorage 持久化)
showcase.html        # 项目展示页面 (交互式手机模拟器, 架构图, 版本时间线)
```

**Web 应用功能:**
| 页面 | 功能 |
|------|------|
| 欢迎页 | 首次使用引导 |
| 今日主页 | 快速心情选择 + 4 功能入口 + 记忆 badge |
| 心情记录 | 5 级 emoji 选择器 + 备注 + 保存 |
| 情绪趋势 | SVG 折线图 + 完整历史列表 |
| AI 陪伴对话 | 完整 Haven Persona (危机拦截/共情/探索/选择) |
| 自助练习 | 4 种全部实现 (呼吸动画/感官/感恩/身体扫描) |
| 记忆管理 | 待审/已保存双 Tab + 批准/编辑/删除/添加 |
| 底部导航 | 5 Tab 切换 |

**技术特性:**
- 单 HTML 文件自包含 (内嵌 CSS/JS, 无外部依赖)
- Hash 路由 SPA
- localStorage 数据持久化
- 首次加载预置演示数据
- 完全还原 Haven 设计系统

**部署:**
- GitHub Pages: https://boboza-art.github.io/heaven/
- CloudStudio: https://cbc312208f314a1081d474060d0f9f12.app.codebuddy.work

**文件统计：** 112 → 114 (含 2 个 HTML 文件)

---

## v0.7.0 — 前端记忆管理 (2026-07-26)

### 记忆管理页面

用户可以在 App 中查看、批准、编辑、删除 AI 提取的记忆，也可以手动添加新记忆。

**新增文件 (6):**
```
mobile/lib/features/memory/
├── memory.dart                              # Barrel export
├── models/memory_model.dart                  # MemoryModel + MemoryListResponse
├── state/memory_state.dart                   # 不可变状态 (list/counts/loading/error)
├── repositories/memory_repository.dart       # 抽象接口 + ApiMemoryRepository
├── controllers/memory_controller.dart        # Riverpod StateNotifier
└── screens/memory_page.dart                  # 记忆管理页面 (双 Tab + CRUD)
```

**修改文件 (2):**
- `mobile/lib/router/app_router.dart` — 新增 `/memories` 路由 (共 9 条)
- `mobile/lib/features/today/today_page.dart` — 新增"我的记忆"入口卡片 + badge

### 页面功能

| 功能 | 说明 |
|------|------|
| 双 Tab 布局 | 待审 (pending) / 已保存 (approved)，各自显示计数 |
| 批准记忆 | 一键采纳 AI 提取的记忆 → 下次对话自动注入 |
| 编辑记忆 | 修改内容和分类，支持 6 种分类选择 |
| 删除记忆 | 确认对话框 → 删除 |
| 手动添加 | 选择分类 + 输入内容 → 自动 approved |
| 下拉刷新 | 重新拉取记忆列表 |
| Badge 提醒 | 有待审记忆时，首页入口显示红色数字角标 |

### 6 种记忆分类

| 分类 | 标签 | 颜色 |
|------|------|------|
| `situation` | 生活状况 | moodGood (绿) |
| `preference` | 个人偏好 | secondary (蓝灰) |
| `concern` | 当前担忧 | moodOkay (橙) |
| `pattern` | 行为模式 | moodLow (珊瑚) |
| `event` | 发生事件 | primary (深绿) |
| `coping` | 应对方式 | moodGreat (浅绿) |

### API 对接

| 端点 | 方法 | 前端调用 |
|------|------|----------|
| `/api/v1/memories` | GET | `getMemories()` — 拉取全部 + 计数 |
| `/api/v1/memories` | POST | `createMemory()` — 手动添加 |
| `/api/v1/memories/{id}` | PATCH | `updateMemory()` — 批准/编辑 |
| `/api/v1/memories/{id}` | DELETE | `deleteMemory()` — 删除 |

### 文件统计

| | v0.6.0 | v0.7.0 | 变化 |
|---|---|---|---|
| 总文件数 | 103 | 109 | +6 |
| Dart 文件 | 46 | 51 | +5 |
| 路由数 | 8 | 9 | +1 |

---

## v0.6.0 — 记忆系统 (2026-07-26)

### AI 记忆积累与上下文感知

让 AI 真正"记住"用户——从对话中自动提取关键信息，在后续对话中注入上下文，实现"越聊越懂你"的个性化支持。

**新增文件:**
- `backend/app/schemas/memory.py` — Memory Pydantic 模型 (Create/Update/Out/List)
- `backend/app/services/memory_service.py` — 记忆提取 + 去重 + 格式化服务
- `backend/app/routers/memory.py` — 记忆 CRUD API (GET/POST/PATCH/DELETE)
- `backend/tests/test_memory_system.py` — 52 项单元测试
- `backend/tests/test_memory_e2e.py` — 6 项真实 LLM 提取测试

**重构文件:**
- `backend/app/routers/chat.py` — 注入已批准记忆 + 对话后异步提取
- `backend/app/services/prompts.py` — `build_system_prompt` 支持 memories 参数
- `backend/app/services/ai_service.py` — `generate_response` 支持 memories 参数
- `backend/app/config.py` — 新增 MEMORY_EXTRACTION_ENABLED / MEMORY_MAX_IN_PROMPT
- `backend/app/main.py` — 注册 memory 路由
- `backend/.env.example` — 新增记忆系统配置项

### 架构设计

```
对话开始
    ↓
查询已批准记忆 (approved=True, limit=MEMORY_MAX_IN_PROMPT)
    ↓
注入 system prompt: "## 你对用户的了解"
    ↓
正常对话流 (Safety → LLM → Validator)
    ↓
返回响应给用户 (不等待提取)
    ↓
异步记忆提取 (fire-and-forget):
    → 对话历史 → 提取 LLM → JSON 解析 → 去重 → 存 DB (approved=False)
```

### 记忆分类

| 分类 | 说明 | 示例 |
|------|------|------|
| `situation` | 用户处境/背景 | "工作压力大，项目赶deadline" |
| `preference` | 用户偏好 | "不喜欢呼吸练习，更喜欢倾诉" |
| `concern` | 持续的担忧 | "担心健康" |
| `pattern` | 行为模式 | "经常在深夜寻求倾诉" |
| `event` | 重要事件 | "最近分手了" |
| `coping` | 有用的应对方式 | "散步能帮助放松" |

### 记忆提取服务 (`MemoryExtractionService`)

- **自动提取**：每次 AI 回复后异步触发 (不阻塞响应)
- **LLM 提取**：使用专门的提取 Prompt，返回结构化 JSON
- **智能去重**：字符 bigram 相似度 + 子串包含检测
- **分类校验**：未知分类自动归入 `situation`
- **Mock 模式跳过**：未配置 LLM 时不提取 (节省资源)
- **短对话跳过**：少于 2 条消息的对话不提取

### 记忆 API

| 端点 | 方法 | 功能 |
|------|------|------|
| `/api/v1/memories` | GET | 列出记忆 (可按 approved 过滤) |
| `/api/v1/memories` | POST | 手动添加记忆 (自动 approved) |
| `/api/v1/memories/{id}` | PATCH | 更新内容/分类/审批状态 |
| `/api/v1/memories/{id}` | DELETE | 删除记忆 |

### 记忆生命周期

```
对话中 AI 自动提取 → approved=False (待审)
    ↓
用户在 App 中查看 → 批准/编辑/删除
    ↓
approved=True → 下次对话注入到 system prompt
```

### 配置项

```bash
# .env
MEMORY_EXTRACTION_ENABLED=true   # 开启自动提取 (需 LLM)
MEMORY_MAX_IN_PROMPT=10           # 注入 system prompt 的最大记忆数
```

### 测试

52 项单元测试 + 6 项真实 LLM 测试，全部通过：

**单元测试 (52/52):**
- Deduplication (7) — 精确匹配/子串包含/bigram 相似度
- Memory Formatting (5) — 空列表/格式化/bullet points
- System Prompt (5) — 记忆+情绪注入/顺序验证
- AI Service (4) — Mock/LLM 接受 memories 参数
- Response Parsing (5) — JSON 数组/包装格式/错误文本提取
- Extraction Dedup (2) — 提取后去重
- Mocked LLM Call (1) — 模拟 HTTP 提取
- No LLM Available (3) — 无 API Key 时的行为
- CRUD Database (7) — 创建/查询/审批/删除
- Chat Router (4) — 记忆注入逻辑
- End-to-End Prompt (8) — 完整 Prompt 验证
- Category Validation (1) — 未知分类归入 situation

**E2E 测试 (6/6, DeepSeek API):**
- 有意义对话 → 提取 2 条记忆 (situation + coping)
- 闲聊寒暄 → 0 条 (正确识别不值得记住)
- 去重验证 → 重复信息被过滤
- 情感对话 → 提取 2 条 (event + coping)
- 完整 Prompt 注入 → 所有部分正确组装

### 文件统计

| | v0.5.0 | v0.6.0 | 变化 |
|---|---|---|---|
| 总文件数 | 95 | 103 | +8 |
| Python 文件 | 28 | 34 | +6 |
| 测试文件 | 1 | 3 | +2 |

### LLM 集成

将后端 Mock AI Service 升级为可接入真实大模型的完整管线，支持任何 OpenAI 兼容 API。

**新增文件:**
- `backend/app/services/prompts.py` — Haven 系统 Prompt (基于 AI_Persona.md)
- `backend/tests/test_ai_service.py` — 33 项 AI 管线测试

**重构文件:**
- `backend/app/services/ai_service.py` — 完全重写，支持双模式 + 工厂选择

### 架构设计

```
User Input
    ↓
Safety Layer (危机关键词拦截 — LLM 前置，始终生效)
    ↓
Context Builder (对话历史 + 当前情绪 → messages 数组)
    ↓
LLM / Mock (工厂自动选择)
    ↓
Validator (截断/空值/安全检查)
    ↓
Response
```

### 双模式服务

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **LLMChatService** | `LLM_API_KEY` 已配置 | 调用 OpenAI 兼容 API，失败时回退到 Mock |
| **MockAIChatService** | `LLM_API_KEY` 为空 | 关键词匹配的模拟回复 (原有行为) |

### 系统 Prompt 设计

基于 AI_Persona.md 构建完整 system prompt：
- **身份**：温和的心理支持陪伴者，不做诊断
- **行为准则**：先理解 → 后探索 → 给选择 → 不强迫
- **禁忌**：不做诊断、不说教、不夸张承诺、不自我指涉
- **风格**：2-4 句话、中文、柔和语气、无 emoji
- **情绪感知**：自动注入用户当前情绪标签

### 上下文层增强

`chat.py` 路由更新——调用 AI 前自动获取：
- 最近 20 条对话历史 (按时间正序)
- 用户最新情绪记录 (mood_level → 中文标签)
- 将两者作为 context 传给 LLM

### 配置项

```bash
# .env
LLM_API_KEY=           # 空 = Mock 模式
LLM_API_BASE=https://api.openai.com/v1
LLM_MODEL=gpt-4o-mini
LLM_TEMPERATURE=0.7
LLM_MAX_TOKENS=500
LLM_TIMEOUT_SECONDS=30
LLM_FALLBACK_TO_MOCK=true
LLM_CONTEXT_WINDOW=10
```

支持任何 OpenAI 兼容 API：OpenAI / DeepSeek / Moonshot / 本地 Ollama 等。

### 安全保障

- 危机关键词拦截在 **LLM 调用之前**，不会触发 API 请求
- 响应验证器：截断超长回复 (>1000字)、替换空回复
- LLM 失败时自动回退到 Mock（可配置关闭）

### 测试

33 项测试全部通过：
- Safety Layer (8 项) — 危机关键词检测 + 正常输入不误报
- Response Validation (4 项) — 空值/超长/正常
- Mock Service (3 项) — 问候/危机/正常回复
- System Prompt (6 项) — 身份/行为/禁忌/风格/情绪注入
- LLM Message Building (6 项) — 消息数组结构/历史截断
- LLM Fallback (2 项) — API 失败回退/危机不调 API
- LLM Mocked Call (1 项) — 模拟 HTTP 响应验证完整流程
- Factory Selection (3 项) — 配置驱动的服务选择

### 文件统计

| | v0.4.0 | v0.5.0 | 变化 |
|---|---|---|---|
| 总文件数 | 92 | 95 | +3 |
| Python 文件 | 26 | 28 | +2 |
| 测试文件 | 0 | 1 | +1 |

---

## v0.4.0 — 前后端对接 (2026-07-26)

### 网络层 (`core/network/`)
- `api_config.dart` — 统一 API 配置 (baseUrl, timeout, 可通过 `--dart-define` 覆盖)
- `token_storage.dart` — SharedPreferences 封装，持久化 access/refresh token
- `auth_interceptor.dart` — Dio 拦截器：自动附加 Bearer token + 401 自动刷新
- `dio_provider.dart` — Riverpod 提供的 Dio 实例 (含拦截器 + debug 日志)

### Auth Feature (`features/auth/`)
- `models/auth_model.dart` — UserModel + TokenPair
- `state/auth_state.dart` — 三态认证 (initial → authenticated/unauthenticated)
- `controllers/auth_controller.dart` — register/login/logout/restoreSession
- `screens/login_page.dart` — 登录页面 (邮箱+密码, 表单验证, 错误提示)
- `screens/register_page.dart` — 注册页面 (邮箱+密码+昵称)
- `auth.dart` — Barrel export

### API Repository 切换
- `mood_repository.dart` — 新增 `ApiMoodRepository` (POST/GET /mood, GET /mood/trend)
- `chat_repository.dart` — 新增 `ApiChatRepository` (POST/GET /chat, 后端处理 AI 回复)
- `exercise_repository.dart` — 新增 `ApiExerciseRepository` (GET /exercises, POST complete)
- 三个 Controller 的 provider 全部切换到 Api 实现
- 保留 InMemory 实现作为离线回退

### 路由守卫
- 新增 `/login` 和 `/register` 路由 (共 8 条)
- GoRouter `redirect`: 未认证 → /login, 已认证且在公开页 → /today
- HavenApp 监听 auth 状态变化，调用 `router.refresh()` 触发重定向
- App 启动时调用 `restoreSession()` 验证存储的 token

### 数据模型更新
- `MoodModel` 新增 `id` 字段 (UUID, 对齐后端 MoodOut)
- `ExerciseModel.fromJson` 兼容后端 `duration_minutes` → 本地 `durationSeconds`

### UI 更新
- WelcomePage 改为双按钮 (登录 / 注册)
- TodayPage 新增退出登录入口 (右上角)
- 聊天逻辑优化: 乐观更新用户消息 → 用后端返回的完整消息替换

### 文件统计
| | v0.3.0 | v0.4.0 | 变化 |
|---|---|---|---|
| 总文件数 | 81 | 92 | +11 |
| Dart 文件 | 35 | 46 | +11 |
| 新增模块 | - | core/network + auth | +2 |

---

## v0.3.0 — 后端实现 (2026-07-26)

### 后端搭建 (FastAPI + PostgreSQL + JWT Auth)

**新增 `backend/` 目录 (21 个文件):**

```
backend/
├── app/
│   ├── main.py                    # FastAPI 入口 + 生命周期 + CORS
│   ├── config.py                  # 环境配置 (pydantic-settings)
│   ├── database.py                # SQLAlchemy 引擎 + Session
│   ├── deps.py                   # 依赖注入: JWT 认证获取当前用户
│   ├── core/
│   │   └── security.py            # bcrypt 密码哈希 + JWT 生成/验证
│   ├── models/                    # SQLAlchemy ORM 模型
│   │   ├── user.py                # Users 表
│   │   ├── mood.py                # MoodLogs 表
│   │   ├── chat.py                # ChatMessages 表
│   │   ├── memory.py              # Memories 表
│   │   └── exercise.py            # ExerciseCompletions 表
│   ├── schemas/                   # Pydantic 请求/响应模型
│   │   ├── auth.py                # 注册/登录/Token
│   │   ├── mood.py                # 心情记录/趋势
│   │   ├── chat.py                # 聊天消息
│   │   └── exercise.py            # 练习信息/完成记录
│   ├── routers/                   # API 路由 (4 个模块)
│   │   ├── auth.py                # /auth/register, /login, /refresh, /me
│   │   ├── mood.py                # /mood (POST/GET), /mood/trend
│   │   ├── chat.py                # /chat (POST/GET)
│   │   └── exercises.py           # /exercises, /{id}, /{id}/complete
│   └── services/
│       └── ai_service.py          # Mock AI 服务 (4 层管线, 从 Flutter 移植)
├── alembic/                       # 数据库迁移配置
│   ├── env.py
│   └── script.py.mako
├── alembic.ini
├── requirements.txt
├── .env.example
├── Dockerfile
└── README.md
```

**根目录新增:**
- `docker-compose.yml` — PostgreSQL + 后端一键启动

### 功能清单

| API 端点 | 方法 | 认证 | 功能 |
|----------|------|------|------|
| `/api/v1/auth/register` | POST | - | 用户注册 (bcrypt + JWT) |
| `/api/v1/auth/login` | POST | - | 用户登录 |
| `/api/v1/auth/refresh` | POST | - | 刷新 Token |
| `/api/v1/auth/me` | GET | JWT | 获取当前用户 |
| `/api/v1/mood` | POST | JWT | 记录心情 |
| `/api/v1/mood` | GET | JWT | 心情历史 |
| `/api/v1/mood/trend` | GET | JWT | 心情趋势 |
| `/api/v1/chat` | POST | JWT | 发送消息给 AI |
| `/api/v1/chat` | GET | JWT | 聊天历史 |
| `/api/v1/exercises` | GET | JWT | 练习列表 |
| `/api/v1/exercises/{id}` | GET | JWT | 练习详情 |
| `/api/v1/exercises/{id}/complete` | POST | JWT | 标记练习完成 |

### 安全特性

- **JWT 认证** — access token (7天) + refresh token (30天)
- **bcrypt 密码哈希** — 不存储明文密码
- **危机关键词拦截** — 危险词汇 → 安全响应 + 心理援助热线
- **CORS 配置** — 可配置允许的前端域名
- **邮箱唯一约束** — 防止重复注册

### AI 服务移植

完整移植 Flutter 端的 4 层管线到 Python:

```
Safety Layer (危机关键词拦截)
    → Emotion Layer (5 类情绪检测)
    → Context Layer (共情 + 确认)
    → Response Layer (Persona 回复 + 选项)
```

- 3 组共情验证句库 (12 句)
- 5 个探索提示
- 2 组选项模板
- 9 个危机关键词 → 安全响应 + 2 个热线号码

### 测试验证

17 项端到端 API 测试全部通过:

```
[PASS] health check
[PASS] register / login / refresh / me
[PASS] mood log / history / trend
[PASS] exercise list / detail / complete
[PASS] chat normal (AI 回复生成)
[PASS] chat crisis detection (热线拦截)
[PASS] duplicate register blocked (409)
[PASS] wrong password rejected (401)
```

### 技术栈

```
Backend:  FastAPI 0.115 + Python 3.13
ORM:      SQLAlchemy 2.0
Auth:     JWT (python-jose) + bcrypt
DB:       PostgreSQL 16 (生产) / SQLite (测试)
Migrate:  Alembic
Deploy:   Docker + docker-compose
```

### 文件统计 (v0.3.0)

| 分类 | 新增文件数 |
|------|------------|
| 后端 Python | 18 |
| 后端配置 | 3 (Dockerfile, alembic.ini, .env.example) |
| 根目录 | 1 (docker-compose.yml) |
| **总计新增** | **22** |
| **项目总文件数** | **71** |

---

## v0.2.0 — 功能扩展 (2026-07-26)

### 项目基础设施

**新增:**
- `mobile/pubspec.yaml` — Flutter 项目依赖配置，项目可构建运行
- `mobile/analysis_options.yaml` — 代码分析规则

### 导航系统修复

统一使用 GoRouter 路由，替换所有 Navigator 1.0 调用:

| 文件 | 变更 |
|------|------|
| `app_router.dart` | 新增 `/mood-check`、`/mood-history` 路由 |
| `welcome_page.dart` | `pushReplacementNamed` → `context.go` |
| `today_page.dart` | `Navigator.push` → `context.push`，加载 mood history |
| `mood_check_page.dart` | `Navigator.pop` → `context.pop` |
| `chat_page.dart` | `Navigator.pop` → `context.pop` |
| `exercise_list_page.dart` | `Navigator.pop` → `context.pop`，路由到新练习页 |
| `breathing_exercise_page.dart` | `Navigator.pop` → `context.pop` |

### S4-01: 5-4-3-2-1 感官练习

**新增 1 个文件:**
```
mobile/lib/features/toolbox/screens/grounding_exercise_page.dart
```

**功能:**
- 5 步感官引导：看(5) → 听(4) → 触(3) → 闻(2) → 尝(1)
- 无计时器，用户自主推进
- 渐入动画过渡，进度指示器
- 完成后温和反馈

### S4-02: 三件好事感恩练习

**新增 1 个文件:**
```
mobile/lib/features/toolbox/screens/gratitude_exercise_page.dart
```

**功能:**
- 3 步引导式记录，每步一个文本输入
- 温柔的引导语，强调"小事"而非"成就"
- 可跳过任意条目
- 完成后展示所有记录的温暖回顾

### S4-03: 快速身体扫描练习

**新增 1 个文件:**
```
mobile/lib/features/toolbox/screens/body_scan_exercise_page.dart
```

**功能:**
- 5 步身体扫描：头面 → 肩臂 → 胸腹 → 臀腰 → 腿脚
- 呼吸式脉动动画 (4 秒循环)
- 每步计时 (20-25 秒)，可暂停/跳过/回退
- 进度条 + 步数指示

### S4-04: 情绪趋势/历史页面

**新增 1 个文件:**
```
mobile/lib/features/mood/screens/mood_history_page.dart
```

**功能:**
- CustomPainter 绘制的折线趋势图 (最近 14 条)
- 5 级心情色点 + 连接线
- 时间线列表 (相对时间显示)
- 空状态引导
- TodayPage 新增"查看心情记录"入口

### 练习模块更新

| 练习 | 之前状态 | 现在状态 |
|------|----------|----------|
| 4-7-8 呼吸法 | ✅ 已实现 | ✅ |
| 5-4-3-2-1 感官练习 | ⏳ 占位 | ✅ 已实现 |
| 三件好事 | ⏳ 占位 | ✅ 已实现 |
| 快速身体扫描 | ⏳ 占位 | ✅ 已实现 |

### 文件统计 (v0.2.0)

| 分类 | 新增文件数 |
|------|------------|
| 项目配置 | 2 |
| 新练习页面 | 3 |
| 情绪历史页面 | 1 |
| **总计新增** | **6** |
| **项目总文件数** | **48** |

---

## v0.1-alpha — MVP Feature-Complete (2026-07-26)

### 项目初始化

创建 Haven 知识包，包含完整的项目上下文、产品设计、技术架构和 AI 系统设计。

**文档 (10 files):**

| 文件 | 内容 |
|------|------|
| `PROJECT_CONTEXT.md` | 项目上下文——身份、使命、边界、核心体验、设计哲学 |
| `project_manifest.yaml` | 机器可读项目清单——技术栈、AI 管线、MVP 目标 |
| `PRODUCT/Product_Vision.md` | 产品愿景与成功定义 |
| `PRODUCT/Product_Charter.md` | 产品承诺与原则 |
| `PRODUCT/Design_Charter.md` | 设计规范——安静、简洁、无压力 |
| `ENGINEERING/Architecture.md` | 系统架构——Feature First + Monorepo + API First |
| `ENGINEERING/Flutter_Architecture.md` | 移动端架构——Riverpod + GoRouter + Dio |
| `ENGINEERING/API_Spec.md` | API 接口定义 |
| `ENGINEERING/Database_Design.md` | 数据库设计——Users / MoodLogs / ChatMessages / Memories |
| `AI_SYSTEM/AI_Persona.md` | AI 角色——温和的心理支持陪伴者 |
| `AI_SYSTEM/Prompt_Framework.md` | Prompt 管线——Safety → Emotion → Context → LLM → Validator |
| `AI_SYSTEM/features/breathing_exercise.md` | 呼吸练习功能模板 |

**Flutter 骨架 (7 files):**

- `main.dart` + `haven_app.dart` — 应用入口
- `router/app_router.dart` — 路由配置
- `theme/colors.dart` / `spacing.dart` / `typography.dart` — 设计系统
- `features/onboarding/welcome_page.dart` — 欢迎页
- `features/today/today_page.dart` — 今日主页

---

### S3-03: Mood Check 心情记录模块

**新增 7 个文件:**

```
mobile/lib/features/mood/
├── mood.dart                          # feature 统一导出
├── models/mood_model.dart             # 5 级心情数据模型 (emoji + 中文标签 + JSON)
├── state/mood_state.dart              # Riverpod 不可变状态
├── controllers/mood_controller.dart   # MoodNotifier 业务逻辑
├── repositories/mood_repository.dart  # 抽象接口 + InMemory 实现 + API 预留
├── widgets/mood_selector.dart         # 5 级心情选择器 (动画过渡)
└── screens/mood_check_page.dart       # 心情记录页 (选择 → 可选笔记 → 保存)
```

**修改 1 个文件:**

- `today_page.dart` — 重构为 `ConsumerStatefulWidget`，集成心情状态

---

### S3-04: Toolbox 自助练习模块

**新增 8 个文件:**

```
mobile/lib/features/toolbox/
├── toolbox.dart                                # feature 导出
├── models/exercise_model.dart                  # 4 种预置练习
├── state/exercise_state.dart                   # Riverpod 状态
├── controllers/exercise_controller.dart         # 业务逻辑
├── repositories/exercise_repository.dart        # 数据层 + API 预留
├── screens/exercise_list_page.dart              # 练习列表
└── screens/breathing_exercise_page.dart         # 4-7-8 呼吸练习
```

**预置练习:**

| 练习 | 分类 | 时长 | 状态 |
|------|------|------|------|
| 4-7-8 呼吸法 | 🌬️ 呼吸 | 3 min | ✅ 已实现 |
| 5-4-3-2-1 感官练习 | 🌱 稳定 | 2 min | ⏳ 即将上线 |
| 三件好事 | 💛 感恩 | 3 min | ⏳ 即将上线 |
| 快速身体扫描 | 🧘 身体 | 4 min | ⏳ 即将上线 |

**修改 1 个文件:**

- `app_router.dart` — 新增 `/exercises` 路由

---

### S3-05: AI Chat 对话模块

**新增 8 个文件:**

```
mobile/lib/features/chat/
├── chat.dart                         # feature 导出
├── models/chat_model.dart            # 消息数据模型
├── state/chat_state.dart             # Riverpod 状态
├── services/ai_chat_service.dart     # 模拟 AI 服务 (核心)
├── repositories/chat_repository.dart # 数据层
├── controllers/chat_controller.dart  # 业务逻辑
├── widgets/chat_bubble.dart          # 聊天气泡组件
└── screens/chat_page.dart            # 聊天页面
```

**AI 模拟服务 4 层管线:**

```
Safety Layer → Emotion Layer → Context Layer → Response
```

- 5 种情绪关键词检测 (sad/anxious/angry/tired/happy)
- 危机关键词拦截 → 安全响应 + 热线号码
- 3 组共情验证句库 + 探索提示
- 严格遵循 AI Persona: 先理解 → 后探索 → 给选择 → 不强迫

**交互特性:**

- 首次进入自动显示随机欢迎语 (3 种)
- 用户/助手气泡左右对齐 (颜色区分)
- 发送中显示 3 点打字动画
- 支持 enter 发送

**修改 2 个文件:**

- `app_router.dart` — 新增 `/chat` 路由
- `today_page.dart` — "聊一聊" 卡片导航

---

## 交付全景

### 文件统计

| 分类 | 文件数 |
|------|--------|
| 📋 产品/工程/AI 文档 | 12 |
| 🎨 主题/基础架构 | 7 |
| 🏠 Onboarding | 2 |
| 😊 Mood Check | 8 |
| 🧘 Toolbox | 8 |
| 💬 AI Chat | 9 |
| **总计** | **42** |

### 功能清单

| 功能 | 状态 |
|------|------|
| 🏠 欢迎页 / 新手引导 | ✅ |
| 😊 5 级心情记录 + 可选笔记 | ✅ |
| 💬 AI 陪伴对话 (模拟服务) | ✅ |
| 🧘 4-7-8 呼吸练习 (含动画) | ✅ |
| 🧘 练习列表 + 3 个占位练习 | ✅ |
| 🎨 完整设计系统 (颜色/间距/排版) | ✅ |
| 📋 路由系统 (Welcome → Today → 子页面) | ✅ |
| 📦 各模块 Barrel Export | ✅ |
| 🔌 API 接口全预留 | ✅ |

### 用户完整流程

```
Welcome (欢迎页)
    ↓
Today (今日主页——问候 + 3 大入口)
    ├─ "记录此刻心情" → MoodCheckPage → 返回刷新
    ├─ "聊一聊"       → ChatPage (AI 陪伴者)
    └─ "练习"         → ExerciseListPage → 4-7-8 呼吸练习
```

### 技术栈

```
Mobile:  Flutter + Dart (Riverpod / GoRouter / Dio)
Backend: FastAPI + Python (Architecture Designed)
DB:      PostgreSQL (Schema Defined)
Cache:   Redis (Planned)
AI:      Prompt Pipeline Designed (Mock Service Implemented)
```

---

## 待推进方向

1. **真实 LLM 接入** — 替换后端 Mock AI Service，接入真实大模型 API
2. **记忆系统** — AI 对话上下文积累 (数据库 Memories 表已建好)
3. **本地持久化** — 离线缓存 (SharedPreferences/SQLite)，无网络时降级到 InMemory
4. **更多练习** — 渐进式肌肉放松、正念冥想等
5. **用户资料** — 个人资料编辑、头像、偏好设置
