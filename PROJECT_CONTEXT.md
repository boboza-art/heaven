# Haven Project Context


## Identity

Name:

Haven


Category:

AI emotional support application


## Mission

帮助正在经历压力、焦虑、情绪低落的人，
获得基础、温和、持续的心理支持。


## Product Boundary

Haven:

✓ 情绪记录工具

✓ AI 陪伴

✓ 自助练习工具

✓ 自我觉察空间


Haven is NOT:

✗ 医疗诊断工具

✗ 心理治疗替代品

✗ 危机干预机构


## Core Experience

用户感受到困难

↓

打开 Haven

↓

表达状态

↓

获得理解

↓

完成一个小行动

↓

离开


## Design Philosophy

陪伴优先。

不要急于解决。

不要制造压力。


## Current Technical Status

**v0.8.0 — 离线缓存 + 全栈完整 ✅** (2026-07-26)

### Mobile (Flutter + Dart)

| 模块 | 状态 | 文件数 |
|------|------|--------|
| 🏠 Onboarding | ✅ | 2 |
| 🔐 Auth | ✅ | 6 |
| 😊 Mood Check + History | ✅ | 9 |
| 💬 AI Chat | ✅ | 9 |
| 🧘 Toolbox (4 练习全部实现) | ✅ | 11 |
| 🧠 Memory Management | ✅ | 6 |
| 🌐 Core/Network + Cache | ✅ | 8 |
| 🎨 Design System | ✅ | 7 |
| 🔧 Project Config | ✅ | 2 |

- 54 个 Dart 文件，完整前后端闭环 + 离线缓存
- Riverpod 状态管理 + GoRouter 路由 (9 条路由 + 认证守卫) + 统一 Barrel Export
- **Repository 装饰器模式** — Caching*Repository 包裹 Api*Repository，在线缓存/离线降级
- Dio HTTP 客户端 + JWT 自动刷新拦截器
- SharedPreferences 持久化 token + LocalCache 离线数据缓存
- 4 种自助练习全部实现 (呼吸/感官/感恩/身体扫描)
- 情绪趋势可视化 (CustomPainter 折线图)
- 记忆管理页面 (双 Tab + CRUD + Badge 提醒)

### Backend (FastAPI + Python)

**v0.6.0 — 完整实现 ✅**

| 模块 | 状态 | 功能 |
|------|------|------|
| 🔐 Auth | ✅ | JWT 注册/登录/刷新 + bcrypt 密码哈希 |
| 😊 Mood API | ✅ | 记录/历史/趋势 |
| 💬 Chat API | ✅ | AI 对话 (DeepSeek LLM) + 历史存储 + 异步记忆提取 |
| 🧘 Exercises API | ✅ | 列表/详情/完成记录 |
| 🧠 Memory API | ✅ | CRUD + 自动提取 + 去重 + Prompt 注入 |
| 🗄️ Database | ✅ | PostgreSQL 16 + SQLAlchemy 2.0 + Alembic |
| 🐳 Deploy | ✅ | Docker + docker-compose 一键启动 |

- 34 个 Python 文件
- 16 个 API 端点全部实现并测试通过
- DeepSeek deepseek-chat 真实 LLM 接入 + Mock 回退
- 危机关键词拦截 + 心理援助热线响应
- 记忆系统：LLM 自动提取 → bigram 去重 → 用户审批 → Prompt 注入

### AI System

**4 层管线 (Safety → Context → LLM → Validator):**
- Safety Layer — 9 个危机关键词前置拦截，不调用 API
- Context Builder — 对话历史 + 当前情绪 + 已批准记忆 → system prompt
- LLM (DeepSeek) — OpenAI 兼容 API，失败自动回退 Mock
- Validator — 截断/空值/安全检查
- 异步记忆提取 — fire-and-forget，不阻塞响应

### Offline Support

**v0.8.0 — Repository 装饰器模式 ✅**
- ConnectivityService — 5s DNS 轮询追踪在线/离线状态
- LocalCache — SharedPreferences JSON 缓存
- Caching*Repository — 在线缓存/离线降级
- 离线聊天 — 降级到本地 AIChatService (Mock)，标注"（离线模式）"

## Artifacts

- `docs/index.html` — Haven Web 应用 (完整可交互 SPA, 10 页面, localStorage 持久化)
- `showcase.html` — 项目展示页面 (交互式手机模拟器, 架构图, 版本时间线)
- `CHANGELOG.md` — 完整版本历史 (v0.1 ~ v0.8.0)
- `project_manifest.yaml` — 机器可读项目清单
- `backend/README.md` — 后端 API 文档
- `docker-compose.yml` — 一键部署

## Deployment

- **GitHub Pages**: https://boboza-art.github.io/heaven/ (source: main /docs)
- **CloudStudio**: https://cbc312208f314a1081d474060d0f9f12.app.codebuddy.work
- **GitHub Repo**: https://github.com/boboza-art/heaven

## Next Milestone

用户资料系统 · 更多练习 (渐进式肌肉放松/正念冥想) · 数据同步队列 (离线写入恢复后自动同步)
