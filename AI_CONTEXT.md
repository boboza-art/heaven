# Haven — AI 上下文交接文档

> 本文件为「机器可读」项目交接文档，供其他 AI 模型快速理解 Haven 项目的完整状态、架构、代码结构和待办事项。
> 生成时间：2026-07-27 18:11 (GMT+8)
> 当前版本：v0.8.1 (commit 88c3490)

---

## 1. 项目身份

| 字段 | 值 |
|------|-----|
| 项目名 | Haven |
| 定位 | AI 情感支持应用 |
| 目标用户 | 压力/焦虑/情绪低落的人群 |
| 设计哲学 | 陪伴优先、不急于解决、不制造压力 |
| 界面语言 | 中文优先 |
| GitHub | https://github.com/boboza-art/heaven |
| GitHub Pages | https://boboza-art.github.io/heaven/ |
| CloudStudio | https://cbc312208f314a1081d474060d0f9f12.app.codebuddy.work |
| 项目根目录 | `/Users/xiaobozhou/Desktop/Work buddy/2026-07-26-16-49-49/haven` |

---

## 2. 技术栈

| 层 | 技术 | 说明 |
|----|------|------|
| Mobile | Flutter + Dart | Riverpod 状态管理 / GoRouter 路由 / Dio HTTP |
| Backend | FastAPI + Python 3.13 | SQLAlchemy 2.0 / Pydantic v2 / pydantic-settings |
| Database | PostgreSQL 16 | SQLAlchemy ORM / Alembic 迁移 |
| Auth | JWT | python-jose + bcrypt / access 7天 + refresh 30天 |
| AI/LLM | DeepSeek (deepseek-chat) | OpenAI 兼容 API / Mock 自动回退 |
| Deploy | Docker + docker-compose | GitHub Pages (Web) / CloudStudio (Web 预览) |
| Web App | 纯 HTML/CSS/JS 单文件 | localStorage 持久化 / 无外部依赖 / Hash 路由 SPA |

---

## 3. 三端代码结构

### 3.1 目录总览

```
haven/
├── mobile/                 # Flutter 移动端 (54 Dart 文件, ~8170 LOC)
│   └── lib/
│       ├── app/            # haven_app.dart (ConsumerStatefulWidget + auth restore)
│       ├── main.dart       # ProviderScope + initNetwork()
│       ├── router/         # app_router.dart (GoRouter, 9 routes + auth redirect)
│       ├── theme/          # colors.dart / spacing.dart / typography.dart
│       ├── core/           # 网络层 + 缓存层 + 离线组件
│       │   ├── core.dart   # Barrel export
│       │   ├── network/    # api_config / token_storage / auth_interceptor / dio_provider / connectivity_service
│       │   ├── cache/      # local_cache.dart (SharedPreferences JSON)
│       │   └── widgets/    # offline_banner.dart (琥珀色横幅)
│       └── features/       # Feature First 架构
│           ├── onboarding/ # welcome_page.dart
│           ├── today/      # today_page.dart (主页枢纽)
│           ├── auth/       # model / state / controller / login / register / barrel (6 files)
│           ├── mood/       # model / state / controller / repo / selector / 2 screens / barrel (9 files)
│           ├── chat/       # model / state / controller / repo / service / bubble / screen / barrel (9 files)
│           ├── memory/     # model / state / controller / repo / screen / barrel (6 files)
│           └── toolbox/    # model / state / controller / repo / 4 exercise pages / list / barrel (11 files)
│
├── backend/                # FastAPI 后端 (34 Python 文件, ~1917 LOC)
│   ├── app/
│   │   ├── main.py         # FastAPI 入口 + lifespan + CORS + 路由注册
│   │   ├── config.py       # pydantic-settings 环境配置
│   │   ├── database.py     # SQLAlchemy 引擎 + Session
│   │   ├── deps.py         # JWT 认证依赖注入
│   │   ├── core/security.py # bcrypt + JWT 生成/验证
│   │   ├── models/         # User / MoodLog / ChatMessage / Memory / ExerciseCompletion
│   │   ├── schemas/        # Pydantic 请求/响应模型 (auth / mood / chat / memory / exercise)
│   │   ├── routers/        # auth / mood / chat / exercises / memory (16 个 API 端点)
│   │   └── services/       # ai_service.py / prompts.py / memory_service.py
│   ├── tests/              # test_ai_service / test_llm_e2e / test_memory_system / test_memory_e2e
│   ├── alembic/            # 数据库迁移
│   ├── Dockerfile
│   ├── docker-compose.yml  # PostgreSQL + 后端
│   ├── requirements.txt
│   └── .env                # 环境变量 (含 API Key, 不提交)
│
├── docs/                   # Web 应用
│   └── index.html          # 完整 SPA (3087 行, 94KB, 57 个函数)
│
├── showcase.html           # 项目展示页 (交互式手机模拟器)
├── AI_SYSTEM/               # AI 设计文档
├── ENGINEERING/            # 架构/API/DB 设计文档
├── PRODUCT/                # 产品愿景/承诺/设计规范
├── PROJECT_CONTEXT.md      # 项目上下文入口
├── project_manifest.yaml   # 机器可读项目清单
├── CHANGELOG.md            # 版本变更记录 (v0.1 ~ v0.8.0)
├── docker-compose.yml      # PostgreSQL + 后端一键启动
└── .gitignore
```

### 3.2 文件统计

| 分类 | 数量 |
|------|------|
| 总文件数 | 119 (不含 .git / __pycache__ / .workbuddy) |
| Dart 文件 | 54 (~8170 LOC) |
| Python 文件 | 34 (~1917 LOC) |
| Web (HTML) | 1 (3087 行, 94KB) |
| 文档文件 | 12 |
| 配置文件 | ~18 |

---

## 4. 架构设计

### 4.1 Mobile — Feature First + Repository 装饰器模式

每个 feature 的层次结构：
```
models → state → controllers → repositories → widgets → screens
```

Repository 继承链：
```
Abstract Interface
  └── Caching*Repository (active, 装饰器)
        ├── 在线: 调 Api*Repository → 成功后缓存到 LocalCache
        └── 离线: 返回 LocalCache 缓存 / 写操作暂存本地
              └── Api*Repository (HTTP)
              └── InMemory*Impl (最终离线回退)
```

核心组件：
- **Dio + AuthInterceptor**: 自动附加 Bearer token + 401 自动刷新 (含去重锁防并发)
- **TokenStorage**: SharedPreferences 持久化 access/refresh token
- **ConnectivityService**: Riverpod StateNotifier<bool>，5s DNS 轮询检测在线/离线
- **LocalCache**: SharedPreferences JSON 封装 (saveList/getList/saveJson/getJson)
- **OfflineBanner**: 离线时顶部琥珀色横幅，点击重试

### 4.2 Backend — FastAPI 分层架构

```
Request → CORS → JWT Auth (deps.py) → Router → Service → ORM Model → DB
                                                         ↓
                                                    AI Service (LLM/Mock)
```

AI Pipeline (4 层)：
```
Safety Layer (危机关键词拦截, LLM 前置)
    ↓
Context Builder (对话历史 + 情绪 + 记忆 → messages 数组)
    ↓
LLM / Mock (工厂自动选择: LLM_API_KEY 有值→LLM, 空→Mock; LLM 失败回退 Mock)
    ↓
Validator (截断 >1000字 / 空值替换 / 安全检查)
    ↓
Response → 异步 Memory Extraction (fire-and-forget)
```

记忆提取流程：
```
对话后异步触发 → LLM 提取结构化 JSON → bigram 相似度去重 → 存 DB (approved=False)
    ↓
用户审批 → approved=True → 下次对话注入 system prompt "## 你对用户的了解"
```

### 4.3 Web App — 纯前端单文件 SPA

- **单 HTML 文件**自包含（内嵌 CSS/JS，无外部依赖）
- **Hash 路由**: `#today`, `#chat`, `#memory`, `#breathing`, `#grounding`, `#gratitude`, `#body_scan`, `#mood_check`, `#mood_history`, `#toolbox`
- **localStorage 持久化**: 5 个 Store key (`onboarded`, `moods`, `chatMessages`, `exercise_completions`, `memories`)
- **真实 AI 调用**: 直接从浏览器调用 DeepSeek API (CORS 已验证通过)
- **AI 连接诊断**: 聊天页顶部状态栏，自动测试连接，绿/红/橙三色指示

---

## 5. AI 系统设计

### 5.1 System Prompt (完整)

```
你是 Haven，一个温和的心理支持陪伴者。你不是心理医生，不做诊断。你是一个愿意倾听、陪伴用户度过情绪起伏的存在。

## 核心行为准则
1. 先理解 — 认真倾听用户说的，先确认你听到了、理解了。不要急于给建议。
2. 后探索 — 温和地询问更多，了解用户的感受。但绝不追问，绝不施压。
3. 给选择 — 在合适的时候提供选项，让用户感到有控制感。不是命令，是邀请。
4. 不强迫 — 如果用户不想说，就尊重。沉默也是一种陪伴。

## 你要避免的
- 不做医学诊断，不说"你有抑郁症"之类的话
- 不说教，不评判，不用"你应该""你不该"
- 不做夸张承诺，不说"一切都会好起来的""别想太多"
- 不提供具体医疗方案或药物建议
- 不使用"作为AI""我是一个语言模型"之类的自我指涉
- 不使用列表式回复（除非用户明确要求选项）

## 回复风格
- 像和朋友的对话，温暖自然，简短有力
- 每次回复 2-4 句话，不超过 150 字
- 适当换行增加可读性
- 用中文回复，语气柔和
- 可以用"嗯""我懂""我听到了"等简短确认词
- 不用emoji，不用感叹号过多

## 情绪感知
你会收到用户当前的情绪状态标签（如有）。请自然地回应这个情绪，但不要生硬地点明。

## 对话结构
- 如果是开场，温和地打招呼，让用户感到安全
- 如果用户在倾诉，先共情和确认，再温和探索
- 如果用户在寻求帮助，给出温和的选项
- 如果用户情绪很重，不要急于做什么，陪伴本身就是力量

记住：你不需要解决所有问题。有时候，有人愿意听，就已经足够了。
```

### 5.2 危机关键词

```javascript
crisisKeywords: ['不想活了', '自杀', '结束生命', '自残', '伤害自己', '活不下去', '想死', '轻生']
```

匹配后返回安全响应 + 心理援助热线（400-161-9995 / 400-821-1215），不触发 API 调用。

### 5.3 记忆分类

| 分类 key | 标签 | 说明 | 示例 |
|----------|------|------|------|
| situation | 生活状况 | 用户处境/背景 | "工作压力大，项目赶deadline" |
| preference | 个人偏好 | 用户偏好 | "不喜欢呼吸练习，更喜欢倾诉" |
| concern | 当前担忧 | 持续的担忧 | "担心健康" |
| pattern | 行为模式 | 行为模式 | "经常在深夜寻求倾诉" |
| event | 发生事件 | 重要事件 | "最近分手了" |
| coping | 应对方式 | 有用的应对方式 | "散步能帮助放松" |

### 5.4 记忆去重算法

- **字符 bigram Jaccard 相似度** (中文友好): 阈值 0.5
- **子串包含检测**: 短文本被长文本包含时判定重复
- 提取后去重 + 与已有记忆去重

---

## 6. API 端点清单

### 6.1 Auth (4 endpoints)

| 端点 | 方法 | 认证 | 功能 |
|------|------|------|------|
| `/api/v1/auth/register` | POST | - | 用户注册 (bcrypt + JWT) |
| `/api/v1/auth/login` | POST | - | 用户登录 |
| `/api/v1/auth/refresh` | POST | - | 刷新 Token |
| `/api/v1/auth/me` | GET | JWT | 获取当前用户 |

### 6.2 Mood (3 endpoints)

| 端点 | 方法 | 认证 | 功能 |
|------|------|------|------|
| `/api/v1/mood` | POST | JWT | 记录心情 |
| `/api/v1/mood` | GET | JWT | 心情历史 |
| `/api/v1/mood/trend` | GET | JWT | 心情趋势 |

### 6.3 Chat (2 endpoints)

| 端点 | 方法 | 认证 | 功能 |
|------|------|------|------|
| `/api/v1/chat` | POST | JWT | 发送消息给 AI (Safety→Context→LLM→Validator) |
| `/api/v1/chat` | GET | JWT | 聊天历史 |

### 6.4 Exercises (3 endpoints)

| 端点 | 方法 | 认证 | 功能 |
|------|------|------|------|
| `/api/v1/exercises` | GET | JWT | 练习列表 |
| `/api/v1/exercises/{id}` | GET | JWT | 练习详情 |
| `/api/v1/exercises/{id}/complete` | POST | JWT | 标记练习完成 |

### 6.5 Memory (4 endpoints)

| 端点 | 方法 | 认证 | 功能 |
|------|------|------|------|
| `/api/v1/memories` | GET | JWT | 列出记忆 (可按 approved 过滤) |
| `/api/v1/memories` | POST | JWT | 手动添加记忆 (自动 approved) |
| `/api/v1/memories/{id}` | PATCH | JWT | 更新内容/分类/审批状态 |
| `/api/v1/memories/{id}` | DELETE | JWT | 删除记忆 |

---

## 7. 数据库模型

### 7.1 Users

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID (PK) | 用户 ID |
| email | String (unique) | 邮箱 |
| nickname | String | 昵称 |
| hashed_password | String | bcrypt 哈希密码 |
| created_at | DateTime(tz) | 创建时间 |

### 7.2 MoodLogs

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID (PK) | 记录 ID |
| user_id | UUID (FK) | 用户 ID |
| mood_level | Integer | 1-5 心情等级 |
| note | Text | 备注 (可选) |
| created_at | DateTime(tz) | 记录时间 |
| 复合索引 | | (user_id, created_at) |

### 7.3 ChatMessages

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID (PK) | 消息 ID |
| user_id | UUID (FK) | 用户 ID |
| role | String | "user" / "assistant" |
| content | Text | 消息内容 |
| created_at | DateTime(tz) | 发送时间 |
| 复合索引 | | (user_id, created_at) |

### 7.4 Memories

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID (PK) | 记忆 ID |
| user_id | UUID (FK) | 用户 ID |
| category | String | situation/preference/concern/pattern/event/coping |
| content | Text | 记忆内容 |
| approved | Boolean | 是否审核通过 |
| created_at | DateTime(tz) | 提取时间 |
| 复合索引 | | (user_id, approved, created_at) |

### 7.5 ExerciseCompletions

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID (PK) | 记录 ID |
| user_id | UUID (FK) | 用户 ID |
| exercise_id | String | 练习 ID |
| duration_seconds | Integer | 完成时长 |
| created_at | DateTime(tz) | 完成时间 |

---

## 8. Web 应用功能清单

### 8.1 页面

| 路由 | 页面名 | 功能 |
|------|--------|------|
| `#welcome` | 欢迎页 | 首次使用引导 |
| `#today` | 今日主页 | 心情选择器 + 练习入口 + AI 对话入口 + 记忆入口 |
| `#mood_check` | 心情记录 | 5 级 emoji 选择器 + 备注 |
| `#mood_history` | 情绪趋势 | SVG 折线图 + 历史列表 |
| `#chat` | AI 陪伴对话 | 真实 DeepSeek API + 上下文记忆 + 危机拦截 + 连接诊断 |
| `#toolbox` | 自助练习 | 4 种练习 |
| `#breathing` | 4-7-8 呼吸法 | 动画引导 + 计时 |
| `#grounding` | 5-4-3-2-1 感官 | 5 步引导 |
| `#gratitude` | 开心事 | 20 图标选择 + 时间戳 + 记忆反馈 |
| `#body_scan` | 身体扫描 | 5 步身体扫描 + 脉动动画 |
| `#memory` | 我的记忆 | 统一时间轴 (心情/练习/聊天/记忆) |

### 8.2 心情系统

```javascript
const MOODS = [
  { level: 1, emoji: '😞', label: '糟糕', color: '#E07A5F' },
  { level: 2, emoji: '😕', label: '难过', color: '#D4A373' },
  { level: 3, emoji: '😐', label: '一般', color: '#B5C0D0' },
  { level: 4, emoji: '🙂', label: '不错', color: '#A3B18A' },
  { level: 5, emoji: '😊', label: '很好', color: '#6B9080' },
];
```

### 8.3 开心事图标 (20 个)

阳光 / 微笑 / 好吃的 / 下雨 / 运动 / 好睡眠 / 拥抱 / 音乐 / 散步 / 朋友 / 阅读 / 宠物 / 花朵 / 咖啡茶 / 看剧 / 创作 / 日落 / 家人 / 整理 / 泡澡

### 8.4 记忆页时间轴

按时间倒序排列，合并 4 类数据：
1. **今天怎样** (moods) — emoji + 标签 + 备注
2. **开心事/练习** (exercise_completions) — 完成详情
3. **AI 陪聊** (chatMessages) — 轮数 + 时长 + 消息预览 + "用 AI 总结对话"按钮
4. **AI 提取记忆** (memories) — 通过/编辑/删除按钮 + 时间戳 + 来源标签

### 8.5 AI 配置

```javascript
const DEEPSEEK_CONFIG = {
  apiKey: '<DeepSeek API Key — 见 backend/.env>',  // 注意: 当前硬编码在前端，仅适合个人测试
  apiBase: 'https://api.deepseek.com/v1',
  model: 'deepseek-chat',
  temperature: 0.7,
  maxTokens: 500,
  contextWindow: 10,  // 携带最近 10 条对话作为上下文
};
```

---

## 9. 配置与环境变量

### 9.1 Backend .env

```bash
# Database
DATABASE_URL=postgresql+psycopg2://haven:haven_dev@localhost:5432/haven

# JWT
JWT_SECRET_KEY=<必须设置，空则启动报错>
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=10080  # 7 天
REFRESH_TOKEN_EXPIRE_DAYS=30

# Server
HOST=0.0.0.0
PORT=8000

# CORS
CORS_ORIGINS=http://localhost:3000,http://localhost:8080

# LLM
LLM_API_KEY=<见 backend/.env 文件>
LLM_API_BASE=https://api.deepseek.com/v1
LLM_MODEL=deepseek-chat
LLM_TEMPERATURE=0.7
LLM_MAX_TOKENS=500
LLM_TIMEOUT_SECONDS=30
LLM_FALLBACK_TO_MOCK=true
LLM_CONTEXT_WINDOW=10

# Memory System
MEMORY_EXTRACTION_ENABLED=true
MEMORY_MAX_IN_PROMPT=10
```

### 9.2 CORS

```python
allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"]
allow_headers=["Authorization", "Content-Type", "Accept"]
```

---

## 10. 版本历史

| 版本 | 文件数 | 关键变更 |
|------|--------|----------|
| v0.1-alpha | 42 | MVP 功能完整 (Mood/Chat/Toolbox/Onboarding) |
| v0.2.0 | 49 | 3 个新练习 + 情绪趋势页 + 导航修复 |
| v0.3.0 | 81 | FastAPI 后端 + PostgreSQL + JWT Auth + Docker |
| v0.4.0 | 92 | Dio 网络层 + JWT 认证 + Auth Feature + API Repository |
| v0.5.0 | 95 | 真实 LLM 接入 (DeepSeek) + 系统 Prompt + 33 单元测试 |
| v0.6.0 | 103 | 记忆系统 (自动提取 + 去重 + CRUD) + 52 单元测试 |
| v0.7.0 | 109 | 前端记忆管理页 (双 Tab + CRUD + badge) |
| v0.8.0 | 112 | 离线缓存 (Caching Repository 装饰器) + Web 应用部署 |
| v0.8.1 | 119 | 代码审查优化 (26 项修复) + DeepSeek 真实接入 + 记忆提取 + 时间轴 + AI 诊断 |

### v0.8.1 详细改动 (当前版本)

**代码审查修复 (26 项):**

Flutter (6 项):
- 修复编译错误 (missing foundation.dart import)
- Token 刷新去重锁 (防并发刷新竞态)
- 登出时清除 LocalCache (防数据泄漏)
- restoreSession 仅 401 清除 token (网络错误保留)
- Chat 滚动改用 ref.listen (消除 build 副作用)
- 呼吸动画暂停同步

Backend (8 项):
- JWT 密钥强制验证 (空值启动报错)
- CORS 收紧 (白名单 methods/headers)
- N+1 查询修复 (memory count 单查询)
- 复合索引 (user_id + created_at)
- 时区感知 datetime (替代 utcnow)
- UUID ValueError 守卫
- Chat 历史 tiebreaker (id 排序)
- async health endpoints

Web (12 项):
- XSS 修复 (escapeHtml map-based)
- 定时器泄漏修复 (navigate clearInterval)
- 危机词误报修复 (移除"死"/"绝望"/"没意义")
- safe-area-inset 适配
- IME Enter 键修复 (isComposing 检查)
- Store.set try/catch (QuotaExceededError)
- 移除 viewport user-scalable=no

**新增功能:**
- DeepSeek API 真实接入 (替代纯 Mock)
- 记忆自动提取 (从对话中 LLM 提炼，移植自后端 memory_service.py)
- 开心事图标化 (20 图标选择 + 时间戳 + 记忆反馈)
- 记忆页统一时间轴 (整合心情/练习/聊天/记忆)
- AI 对话总结功能 (DeepSeek 生成对话摘要存入记忆)
- AI 连接诊断 (状态栏 + 自动测试 + 错误可见化)

---

## 11. 设计约定

| 约定 | 说明 |
|------|------|
| 中文优先 | 界面语言以中文为主 |
| 柔和配色 | HavenColors: warm green primary (#6B9080), soft lavender secondary |
| 5 级心情系统 | 1-5, emoji + 中文标签 |
| Feature First 架构 | 按功能模块组织代码，非按技术层 |
| Barrel Export | 每个 feature 有 `*.dart` 统一导出 |
| Repository 装饰器 | Caching*Repository 包装 Api*Repository |
| AI Persona | 先理解 → 后探索 → 给选择 → 不强迫 |
| 危机拦截 | LLM 前置拦截，不触发 API 调用 |
| 简洁安静设计 | 不使用过多装饰、不制造压力 |
| 部署偏好 | 优先部署到可直接打开的在线网址 |

---

## 12. 测试

| 测试集 | 数量 | 状态 |
|--------|------|------|
| Backend 单元测试 (AI Service) | 33 | 全部通过 |
| Backend 单元测试 (Memory System) | 52 | 全部通过 |
| Backend E2E (LLM) | 22 | 全部通过 (DeepSeek API) |
| Backend E2E (Memory) | 6 | 全部通过 |
| Backend API E2E | 17 | 全部通过 |
| Web App 语法检查 | node --check | 通过 |

---

## 13. 已知问题与注意事项

1. **API Key 暴露**: DeepSeek API Key 硬编码在 `docs/index.html` 前端，任何人可查看源码获取。仅适合个人测试，正式使用需走后端代理。

2. **Mock 回退静默**: Web 应用在 API 调用失败时会回退到 Mock 模板回复。v0.8.1 已加 toast 提示和连接状态栏，但旧聊天记录中的 Mock 回复仍存在 localStorage 中。

3. **GitHub PAT**: 推送代码使用 GitHub PAT（存储在用户处），每次推送后从 remote URL 中清除。

4. **后端未在线运行**: 当前只有 Web 应用 (纯前端) 在 CloudStudio/GitHub Pages 上运行。后端 FastAPI 需要本地启动 (docker-compose up)。

5. **Flutter 未编译**: 移动端代码完整但未在本机构建过 (无 Flutter SDK)。Web 应用是独立于 Flutter 的纯 HTML 实现。

6. **CloudStudio 部署**: 每次更新 `docs/index.html` 后需重新调用 `workbuddy_cloudstudio_deploy` 部署到 CloudStudio。GitHub Pages 从 main 分支 /docs 目录自动更新。

---

## 14. 待推进方向

1. **用户资料编辑** — 头像、偏好设置
2. **更多练习** — 渐进式肌肉放松、正念冥想
3. **数据同步队列** — 离线写入恢复后自动同步到后端
4. **后端代理** — 将 DeepSeek API 调用移到后端，保护 API Key
5. **Flutter 构建** — 在有 Flutter SDK 的环境中构建移动端 APK/iOS
6. **用户测试** — 收集真实用户反馈，迭代 AI Persona

---

## 15. Git 提交历史 (最近 11 条)

```
88c3490 Web: add AI connection diagnostics + error visibility
0b193e6 Web: redesign memory page as unified timeline
325a874 Web: expand gratitude to 20 icons, rename to 开心事, add timestamps + memory feedback
b0301aa Web: remove redundant mood card, redesign gratitude with icon picker
8526f76 Web: exercises on homepage, emoji-only mood, neutral wording
1a47c40 Web: real memory extraction from chat + timestamp/source
f5bba68 Web: connect DeepSeek API for real AI chat
9a6821d v0.8.1: Code review optimizations - security, stability, UX fixes
982a856 Add showcase page as standalone file
257e81b Replace showcase page with full interactive Haven web app
730121a Haven v0.8.0 — AI emotional support app
```

---

## 16. 快速操作指南

### 部署 Web 应用到 CloudStudio
```bash
# 修改 docs/index.html 后
# 在 WorkBuddy 中调用 workbuddy_cloudstudio_deploy 工具
# directory: /Users/xiaobozhou/Desktop/Work buddy/2026-07-26-16-49-49/haven/docs
```

### 推送到 GitHub
```bash
cd "/Users/xiaobozhou/Desktop/Work buddy/2026-07-26-16-49-49/haven"
git add -A
git commit -m "描述"
git remote set-url origin "https://<PAT>@github.com/boboza-art/heaven.git"
git push origin main
git remote set-url origin "https://github.com/boboza-art/heaven.git"  # 清除 PAT
```

### 语法检查 Web 应用 JS
```bash
cd "/Users/xiaobozhou/Desktop/Work buddy/2026-07-26-16-49-49/haven"
python3 -c "
import re
html = open('docs/index.html').read()
scripts = re.findall(r'<script>(.*?)</script>', html, re.DOTALL)
open('/tmp/haven_check.js', 'w').write('\n'.join(scripts))
"
/Users/xiaobozhou/.workbuddy/binaries/node/versions/22.22.2/bin/node --check /tmp/haven_check.js
```

### 测试 DeepSeek API
```bash
curl -s -m 30 -X POST "https://api.deepseek.com/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <你的 DeepSeek API Key>" \
  -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"测试"}],"max_tokens":50}'
```

### 启动后端
```bash
cd backend
# 需要 PostgreSQL 运行在 localhost:5432
# 配置 .env 文件
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
# 或 docker-compose up
```

---

## 17. 用户偏好 (跨项目)

- 倾向于将项目放在 `~/Desktop/Work buddy/` 下按 session 组织
- 使用 `project_manifest.yaml` 作为机器可读项目清单
- Feature First 架构：按功能模块组织代码
- Riverpod 进行 Flutter 状态管理
- 简洁安静的设计风格，中文优先界面
- 要看的是应用本身，不是 API 文档或技术配置过程
- 不要让用户做命令行操作，直接交付可用的结果
- 优先部署到可直接打开的在线网址

---

*本文档由 WorkBuddy 于 2026-07-27 生成，包含 Haven 项目截至 v0.8.1 的完整状态。*
