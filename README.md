# WriterAgent

公众号文章撰写智能体 — 输入一句话，自动搜索素材并生成高质量公众号文章。

## 架构

```
┌─────────────────────┐     HTTP / WebSocket      ┌──────────────────────┐
│   Flutter 前端       │ ◄─────────────────────►  │   Python FastAPI 后端   │
│   (Apple 风格 UI)    │                           │   (Agent + LLM + 工具)  │
└─────────────────────┘                           └──────────┬───────────┘
                                                            │
                                                    ┌───────┴────────┐
                                                    │                │
                                            Tavily 搜索 API    DeepSeek LLM
```

## 功能（V1.0）

- **对话式写作** — 自然语言下达指令，Agent 自动完成搜索 + 写作全流程
- **多风格支持** — 深度产业分析 / 新闻快讯 / 企业调研报告
- **流式输出** — WebSocket 实时展示生成过程
- **跨平台** — Flutter 打包 Windows / macOS / Android / iOS

## 快速开始

### 环境要求

- Python 3.10+
- Flutter 3.12+
- DeepSeek API Key（[申请](https://platform.deepseek.com)）
- Tavily API Key（[免费申请](https://tavily.com)，每月 1000 次免费额度）

### 1. 启动后端

```bash
cd backend

# 安装依赖
pip install -r requirements.txt

# 配置 API Key
cp .env.example .env
# 编辑 .env，填入你的 LLM_API_KEY 和 TAVILY_API_KEY

# 启动服务
python -m app.main
# 或：uvicorn app.main:app --reload --port 8000
```

后端启动后访问 `http://127.0.0.1:8000/api/health` 验证。

### 2. 启动前端

```bash
cd frontend

# 安装依赖
flutter pub get

# 运行（默认 Windows 桌面端）
flutter run

# 打包其他平台
flutter build windows    # Windows 桌面端
flutter build android    # Android APK
flutter build ios        # iOS
```

## 项目结构

```
wechat-article-writer/
├── backend/                        # Python 后端
│   ├── app/
│   │   ├── main.py                 # FastAPI 入口 (HTTP + WebSocket)
│   │   ├── config.py               # 配置管理
│   │   └── agent/
│   │       ├── core.py             # Agent ReAct 循环核心
│   │       ├── prompts.py          # 提示词模板 + 写作风格
│   │       └── tools/
│   │           ├── search.py       # Tavily/Bing 搜索工具
│   │           └── writer.py       # LLM 文章撰写工具
│   ├── .env.example                # 环境变量模板
│   └── requirements.txt            # Python 依赖
│
├── frontend/                       # Flutter 前端 (Apple Design System)
│   ├── lib/
│   │   ├── main.dart               # 应用入口
│   │   ├── theme/
│   │   │   └── app_theme.dart      # Apple 设计系统主题
│   │   ├── pages/
│   │   │   ├── chat_page.dart      # 主聊天界面
│   │   │   ├── article_view.dart   # 文章预览页
│   │   │   └── settings_page.dart  # 设置页
│   │   ├── providers/
│   │   │   └── chat_provider.dart  # 状态管理 (Provider)
│   │   └── services/
│   │       └── api_service.dart    # API / WebSocket 封装
│   └── pubspec.yaml                # Flutter 依赖
│
├── PRD.md                          # 产品需求文档
├── VERSION_ROADMAP.md              # 版本路线图
├── DESIGN.md                       # Apple 设计规范
└── README.md                       # 本文件
```

## 使用方式

### 对话示例

| 输入 | Agent 行为 |
|------|-----------|
| `写一篇 AI 大模型行业分析` | 自动搜索 → 收集素材 → 生成 2000 字深度分析 |
| `帮我分析最近的新能源汽车市场` | 搜索最新资讯 → 生成行业报告 |
| `写一篇关于芯片产业的快讯` | 切换新闻快讯风格 → 生成简明快讯 |
| `第三段太啰嗦，精简一下` | 基于上下文精准修改指定段落 |
| `换成企业调研风格` | 保持主题不变，切换写作风格 |

### API 接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/health` | 健康检查 |
| POST | `/api/chat` | 非流式对话（JSON 请求/响应） |
| WS | `/api/chat/stream` | 流式对话（WebSocket） |
| POST | `/api/session/reset` | 重置会话记忆 |
| GET | `/api/styles` | 获取可用风格列表 |

## 设计风格

前端采用 [Apple Design System](DESIGN.md)，核心特征：

- **Action Blue** (`#0066cc`) — 唯一交互色
- **Parchment** (`#f5f5f7`) — 全局底色
- **SF Pro 字体族** — 17px 正文、负 letter-spacing 标题
- **Pill 按钮** — 圆角 9999px
- **零装饰阴影** — 内容优先的极简美学

## 配置说明

后端 `backend/.env`：

```env
# LLM 配置（必填）
LLM_API_KEY=sk-xxxxxxxx          # DeepSeek / OpenAI API Key
LLM_BASE_URL=https://api.deepseek.com
LLM_MODEL=deepseek-chat
LLM_TEMPERATURE=0.7

# 搜索配置（必填）
TAVILY_API_KEY=tvly-xxxxxxxx    # Tavily 搜索 API Key

# 服务配置
HOST=0.0.0.0
PORT=8000
```

前端在设置页中可配置后端地址。

## 技术栈

| 层 | 技术 |
|---|------|
| LLM | DeepSeek Chat / OpenAI GPT-4o（通过 LangChain 接入） |
| Agent 框架 | LangChain ReAct 循环 |
| 后端 | Python FastAPI + WebSocket |
| 搜索 | Tavily API（AI 优化搜索） |
| 前端 | Flutter 3.x（跨平台） |
| 状态管理 | Provider |
| 设计系统 | Apple Design System |

## 版本规划

详见 [VERSION_ROADMAP.md](VERSION_ROADMAP.md)

| 版本 | 核心 | 状态 |
|------|------|------|
| V1.0 | 对话式搜索 + 写作 | **当前版本** |
| V1.1 | 长期记忆 + 精准修改 | 规划中 |
| V1.2 | 公众号排版 + 智能配图 | 规划中 |
| V1.3 | 一键发布到公众号 | 规划中 |

## License

MIT
