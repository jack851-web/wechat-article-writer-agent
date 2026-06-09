"""WriterAgent 后端服务入口

提供：
- POST /api/chat — 非流式对话接口
- WS  /api/chat/stream — WebSocket 流式对话接口
- GET  /api/health — 健康检查
- POST /api/session/reset — 重置会话
"""

import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from app.agent.core import WriterAgent
from app.config import settings


# 全局 Agent 实例（每个会话一个，V1.0 单用户）
agent = WriterAgent()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    print(f"WriterAgent 启动 | LLM: {settings.LLM_MODEL} | 端口: {settings.PORT}")
    yield
    print("WriterAgent 关闭")


app = FastAPI(
    title="WriterAgent API",
    description="公众号文章撰写智能体后端服务",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS：允许 Flutter 前端跨域访问
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============ 数据模型 ============

class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    reply: str
    memory_length: int


class SessionResetResponse(BaseModel):
    status: str
    message: str


# ============ HTTP 接口 ============

@app.get("/api/health")
async def health_check():
    """健康检查"""
    return {
        "status": "ok",
        "service": "WriterAgent",
        "version": "1.0.0",
        "llm_model": settings.LLM_MODEL,
    }


@app.post("/api/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    """非流式对话接口

    用户发送消息 → Agent 执行完整 ReAct 循环 → 返回最终回复
    """
    if not req.message.strip():
        return ChatResponse(reply="请输入内容", memory_length=agent.get_memory_length())

    try:
        reply = await agent.run(req.message)
        return ChatResponse(
            reply=reply,
            memory_length=agent.get_memory_length(),
        )
    except Exception as e:
        return ChatResponse(
            reply=f"抱歉，处理时出现错误：{str(e)}",
            memory_length=agent.get_memory_length(),
        )


@app.post("/api/session/reset", response_model=SessionResetResponse)
async def reset_session():
    """重置会话记忆"""
    agent.clear_memory()
    return SessionResetResponse(status="ok", message="会话已重置")


@app.get("/api/styles")
async def get_styles():
    """获取可用的写作风格列表"""
    from app.agent.prompts import STYLE_NAMES, LENGTH_MAP
    return {
        "styles": STYLE_NAMES,
        "lengths": LENGTH_MAP,
    }


# ============ WebSocket 流式接口 ============

@app.websocket("/api/chat/stream")
async def chat_stream(websocket: WebSocket):
    """WebSocket 流式对话

    协议：
    - 客户端发送 JSON: {"type": "message", "content": "..."}
    - 服务端推送文本片段（逐 token/streaming chunk）
    - 特殊标记:
      - __thinking__: Agent 思考过程
      - __tool_call__: 正在调用工具
      - __tool_result__: 工具返回结果
      - __writing__: 正在生成文章
      - __response__: 最终回复
      - __error__: 错误信息
      - __done__: 完成
    """
    await websocket.accept()

    try:
        while True:
            # 接收客户端消息
            data = await websocket.receive_text()
            import json
            try:
                msg = json.loads(data)
                msg_type = msg.get("type", "message")
                content = msg.get("content", "")
            except json.JSONDecodeError:
                content = data
                msg_type = "message"

            if msg_type == "ping":
                await websocket.send_text(json.dumps({"type": "pong"}))
                continue

            if msg_type == "reset":
                agent.clear_memory()
                await websocket.send_text(json.dumps({"type": "__done__", "content": "会话已重置"}))
                continue

            if not content.strip():
                continue

            try:
                # 流式执行 Agent
                async for chunk in agent.run_stream(content):
                    await websocket.send_text(
                        json.dumps({"type": "chunk", "content": chunk})
                    )

                # 发送完成标记
                await websocket.send_text(
                    json.dumps({
                        "type": "__done__",
                        "memory_length": agent.get_memory_length(),
                    })
                )

            except Exception as e:
                await websocket.send_text(
                    json.dumps({"type": "__error__", "content": f"错误: {str(e)}"})
                )

    except WebSocketDisconnect:
        print("WebSocket 客户端断开连接")
    except Exception as e:
        print(f"WebSocket 异常: {e}")


# ============ 启动入口 ============

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=True,
    )
