# WriterAgent 版本路线图

> **前端统一使用 Flutter（跨平台，可打包 Windows/macOS/Android/iOS 桌面端和移动端 App）**
> **后端统一使用 Python FastAPI（提供 RESTful API + WebSocket 流式输出）**

---

## V1.0 — MVP：对话式搜索 + 写作

**目标**：用户说一句话，Agent 自动搜素材并写出文章。

### 功能需求

| # | 需求 | 说明 |
|---|------|------|
| 1 | 对话交互 | 用户用自然语言下达写作指令 |
| 2 | 信息收集 | 自动搜索网络资讯和行业报告 |
| 3 | 文章撰写 | 基于素材生成完整文章（支持多种风格） |
| 4 | 短记忆 | 单次会话内保持上下文连贯 |
| 5 | 前端界面 | Flutter 聊天式 UI（桌面端 + 移动端适配） |

### 实现方式

**1. 对话交互**
- 后端：LangChain `ChatOpenAI` 接入 LLM（推荐 DeepSeek API），`Agent` + `tool calling` 实现 ReAct 循环
- 后端：FastAPI 提供 `/chat` 接口（POST）+ `/chat/stream` WebSocket 接口（流式输出）
- 前端：Flutter 聊天页面（`ListView` 消息列表 + `TextField` 输入框），通过 HTTP/WebSocket 调后端 API

**2. 信息收集**
- 工具 A：调用发现报告 MCP API（`mcp_Fa_Xian_Bao_Gao_search_reports`）搜索行业报告
- 工具 B：调用 Tavily/SerpAPI 搜索网页资讯
- 两个工具结果汇总后传给写作引擎

**3. 文章撰写**
- 写一个 `write_article` 工具，接收「主题 + 风格 + 素材」参数
- 内部拼装 Prompt 调用 LLM 生成
- Prompt 模板按风格分：产业分析 / 新闻快讯 / 企业调研（至少实现 2 种）

**4. 短记忆**
- 用一个 `list[Message]` 存会话历史，每次调用 LLM 时带上
- 无需额外组件，LangChain 自带

**5. 前端（Flutter）**
- 项目结构：`flutter run lib/main.dart`
- 核心页面：
  - `chat_page.dart` — 主聊天界面（消息气泡列表、输入框、发送按钮）
  - `article_view.dart` — 文章预览页（Markdown 渲染 + 复制按钮）
  - `settings_page.dart` — 设置页（API Key 配置、风格选择）
- 状态管理：Provider 或 Riverpod
- 网络请求：dio 包调后端 FastAPI
- 流式输出：WebSocketChannel 接收后端流式文本，逐字显示

### 技术依赖

**后端（Python）：**
```
pip install fastapi uvicorn langchain langchain-openai httpx python-dotenv websockets
```

**前端（Flutter）：**
```
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.x        # 状态管理
  dio: ^5.x             # HTTP 请求
  web_socket_channel: ^3.x  # WebSocket 流式输出
  flutter_markdown: ^0.x    # Markdown 渲染
  shared_preferences: ^2.x  # 本地存储设置
```

### 验收标准

- [ ] 输入"写一篇 AI 大模型行业分析"→ 自动出 2000 字文章
- [ ] 支持"换成新闻快讯风格"切换
- [ ] 单篇文章 < 2 分钟完成
- [ ] 连续对话 5 轮上下文不丢
- [ ] Flutter 应用可正常在 Windows 和 Android 上运行

---

## V1.1 — 记忆系统 + 迭代修改

**目标**：Agent 越用越懂用户，支持精准修改段落。

### 功能需求

| # | 需求 | 说明 |
|---|------|------|
| 1 | 长记忆 | 跨会话记住用户偏好、常用风格、历史素材 |
| 2 | 迭代修改 | 用户指定某段落/某种改动，精准改写 |
| 3 | 质量自检 | 生成后自动检查事实错误和逻辑漏洞 |
| 4 | 素材收藏 | 用户标记的有价值素材持久化保存 |

### 实现方式

**1. 长记忆**
- 引入 ChromaDB（本地向量数据库）+ sentence-transformers（中文 embedding 模型）
- 每次对话结束后自动提取关键信息存入：用户偏好、文章风格、常用关键词
- 下次对话前根据用户输入 query 检索相关记忆，注入 System Prompt
- `pip install chromadb sentence-transformers`

**2. 迭代修改**
- 新增 `modify_article` 工具
- Prompt 中明确指令：「定位用户指定的段落 → 仅改该段 → 其余保持不变」
- 支持两种定位方式："第三段"（位置）或"开头那段关于融资的"（内容匹配）

**3. 质量自检**
- 文章生成后自动跑一轮 LLM 检查
- 检查项：数据是否有来源引用、逻辑是否自洽、有无明显事实错误
- 输出问题列表，如有严重问题自动触发重写

**4. 素材收藏**
- 在 ChromaDB 中建独立 collection 存收藏素材
- 前端 Flutter 加"收藏"按钮（`IconButton` + 本地状态），写入时打标签（主题、日期）
- 下次写作时自动检索匹配的收藏素材

### 验收标准

- [ ] 第二次使用时能回忆起之前的偏好
- [ ] "第三段太啰嗦"能精准改第三段
- [ ] 收藏的素材下次自动引用
- [ ] 有记忆管理界面（可查看/删除）

---

## V1.2 — 排版 + 配图

**目标**：输出直接可粘贴到公众号编辑器的精美 HTML。

### 功能需求

| # | 需求 | 说明 |
|---|------|------|
| 1 | 一键排版 | Markdown → 公众号兼容 HTML |
| 2 | 模板库 | 多套预设样式（科技风/商务风/简约风） |
| 3 | 智能配图 | 根据文章内容自动插入配图 |
| 4 | 手机预览 | 排版效果在手机端正常显示 |

### 实现方式

**1. 一键排版**
- 用 `markdown` 库将 Markdown 转 HTML
- 注入公众号专用 CSS（字号、行距、标题样式、引用块样式）
- 关键约束：公众号不支持外部 CSS/JS，必须内联样式
- `pip install markdown beautifulsoup4`

**2. 模板库**
- 定义 3-5 套 CSS 变量配置（颜色、字体、间距）
- 前端 Flutter 放模板选择 `DropdownButton`，用户选后调后端重新渲染 HTML

**3. 智能配图**
- 方案 A（推荐）：调 Unsplash/Pexels API 按关键词搜免费商用图
- 方案 B：调即梦/DALL-E 文生图 API 生成
- LLM 先从文章中提取 2-4 个配图描述词，再调图片 API
- 图片以 `<img>` 标签嵌入 HTML，base64 或外链

**4. 手机预览**
- Flutter 中用 `Container(width: 375)` 模拟手机宽度预览排版效果
- 或用 `flutter_inappwebview` 加载生成的 HTML 做真实预览

### 验收标准

- [ ] 生成的 HTML 直接粘贴到公众号编辑器格式不乱
- [ ] 至少 3 套模板可选
- [ ] 文章自动带 2-4 张配图
- [ ] 手机预览效果正常

---

## V1.3 — 公众号发布

**目标**：写完一键发布，全链路闭环。

### 功能需求

| # | 需求 | 说明 |
|---|------|------|
| 1 | 公众号授权 | OAuth 绑定公众号账号 |
| 2 | 草稿同步 | 文章直接存为公众号草稿 |
| 3 | 一键发布 | 从 Agent 内发布到公众号 |
| 4 | 发布记录 | 查看已发布文章状态 |

### 实现方式

**1. 公众号授权**
- 后端提供授权入口页，用户输入 AppID + AppSecret
- 调微信接口获取 access_token 并缓存（有效期 2 小时，需定时刷新）
- `pip install httpx`（用于调微信 API）

**2. 草稿同步**
- 调用微信「新建草稿」接口：`POST /cgi-bin/draft/add`
- 传入 title + content_html + thumb_media_id
- 封面图可选：用户上传或从配图中选一张

**3. 一键发布**
- 调用微信「发布」接口：`POST /cgi-bin/freepublish/submit`
- 前端 Flutter 加"发布"按钮（`ElevatedButton`），二次确认 `AlertDialog` 后执行
- 发布成功后返回文章 URL，Flutter 用 `url_launcher` 打开预览

**4. 发布记录**
- 本地 SQLite 存发布历史（标题、时间、状态、URL）
- 前端 Flutter 用 `ListView` 展示已发布文章列表页

### 验收标准

- [ ] 成功绑定公众号账号
- [ ] 草稿在公众号后台可见且格式正确
- [ ] 全流程发布 < 30 秒
- [ ] 发布后能在公众号看到文章

---

## 总览

| 版本 | 核心 | 后端新增依赖 | 前端新增依赖（Flutter） | 周期参考 |
|------|------|-------------|----------------------|---------|
| **V1.0** | 对话 → 搜索 → 写作 | fastapi, uvicorn, langchain, httpx, websockets | provider, dio, web_socket_channel, flutter_markdown | 2-3 周 |
| **V1.1** | 记忆 + 修改 | chromadb, sentence-transformers | — | 1-2 周 |
| **V1.2** | 排版 + 配图 | markdown, beautifulsoup4 | flutter_inappwebview | 1-2 周 |
| **V1.3** | 公众号发布 | —（httpx 已有） | url_launcher | 1 周 |

### 项目最终结构

```
wechat-article-writer/
├── backend/                    # Python FastAPI 后端
│   ├── app/
│   │   ├── main.py             # FastAPI 入口 + WebSocket
│   │   ├── agent/
│   │   │   ├── core.py         # Agent ReAct 循环
│   │   │   ├── prompts.py      # 提示词模板
│   │   │   └── tools/          # 工具集合
│   │   │       ├── search.py   # 信息收集
│   │   │       ├── writer.py   # 文章撰写
│   │   │       ├── memory.py   # 记忆读写
│   │   │       └── wechat.py   # 公众号对接
│   │   └── services/
│   │       ├── search_service.py
│   │       ├── writing_service.py
│   │       └── formatting_service.py
│   └── requirements.txt
├── frontend/                   # Flutter 前端
│   ├── lib/
│   │   ├── main.dart
│   │   ├── pages/
│   │   │   ├── chat_page.dart
│   │   │   ├── article_view.dart
│   │   │   ├── settings_page.dart
│   │   │   └── publish_page.dart
│   │   ├── providers/          # 状态管理
│   │   └── services/           # API 调用封装
│   └── pubspec.yaml
└── data/                       # 本地数据（ChromaDB、SQLite）
```
