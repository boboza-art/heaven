# Haven Backend

AI 情感支持应用后端 — FastAPI + PostgreSQL

## 快速开始

### 方式一：Docker Compose（推荐）

```bash
# 在项目根目录执行
docker compose up --build
```

后端将在 `http://localhost:8000` 启动，PostgreSQL 在 5432 端口。
API 文档自动生成在 `http://localhost:8000/docs`。

### 方式二：本地开发

```bash
# 1. 安装依赖
cd backend
pip install -r requirements.txt

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 设置数据库连接等

# 3. 确保 PostgreSQL 运行（可用 Docker 单独启动数据库）
docker run -d --name haven-db -p 5432:5432 \
  -e POSTGRES_USER=haven -e POSTGRES_PASSWORD=haven_dev \
  -e POSTGRES_DB=haven postgres:16-alpine

# 4. 运行数据库迁移
alembic upgrade head
# 或者首次启动时自动创建表（开发模式）

# 5. 启动服务
uvicorn app.main:app --reload
```

## API 端点

### 认证 (Auth)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/auth/register` | 用户注册 |
| POST | `/api/v1/auth/login` | 用户登录 |
| POST | `/api/v1/auth/refresh` | 刷新 Token |
| GET | `/api/v1/auth/me` | 获取当前用户信息 |

### 心情 (Mood)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/mood` | 记录心情 |
| GET | `/api/v1/mood` | 获取心情历史 |
| GET | `/api/v1/mood/trend` | 获取心情趋势 |

### 聊天 (Chat)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/chat` | 发送消息给 AI |
| GET | `/api/v1/chat` | 获取聊天历史 |

### 练习 (Exercises)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/exercises` | 获取练习列表 |
| GET | `/api/v1/exercises/{id}` | 获取练习详情 |
| POST | `/api/v1/exercises/{id}/complete` | 标记练习完成 |

## 项目结构

```
backend/
├── app/
│   ├── main.py              # FastAPI 入口
│   ├── config.py            # 环境配置
│   ├── database.py          # SQLAlchemy 引擎 + Session
│   ├── deps.py             # 依赖注入 (JWT 认证)
│   ├── core/
│   │   └── security.py      # JWT + 密码哈希
│   ├── models/              # SQLAlchemy 模型
│   │   ├── user.py
│   │   ├── mood.py
│   │   ├── chat.py
│   │   ├── memory.py
│   │   └── exercise.py
│   ├── schemas/             # Pydantic 请求/响应模型
│   │   ├── auth.py
│   │   ├── mood.py
│   │   ├── chat.py
│   │   └── exercise.py
│   ├── routers/             # API 路由
│   │   ├── auth.py
│   │   ├── mood.py
│   │   ├── chat.py
│   │   └── exercises.py
│   └── services/
│       └── ai_service.py   # Mock AI 服务 (4 层管线)
├── alembic/                 # 数据库迁移
├── requirements.txt
├── .env.example
├── Dockerfile
└── alembic.ini
```

## AI 服务

当前为 Mock 实现，完整移植了 Flutter 端的 4 层管线：

```
Safety Layer (危机关键词拦截)
    → Emotion Layer (情绪理解)
    → Context Layer (上下文构建)
    → Response Layer (Persona 回复生成)
```

危机关键词检测 → 安全响应 + 热线号码。

后续替换为真实 LLM 时，只需实现新的 `generate_response` 方法。
