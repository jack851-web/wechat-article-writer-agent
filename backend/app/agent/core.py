"""Agent 核心逻辑：ReAct 循环（推理-行动循环）"""

import json
from langchain_openai import ChatOpenAI
from langchain_core.messages import (
    HumanMessage,
    AIMessage,
    SystemMessage,
)
from app.agent.prompts import SYSTEM_PROMPT, WRITING_PROMPTS
from app.agent.tools.search import web_search_tool
from app.agent.tools.writer import write_article_tool
from app.config import settings


class WriterAgent:
    """WriterAgent 主类，管理对话、工具调用和记忆"""

    def __init__(self):
        self.llm = ChatOpenAI(
            model=settings.LLM_MODEL,
            base_url=settings.LLM_BASE_URL,
            api_key=settings.LLM_API_KEY,
            temperature=settings.LLM_TEMPERATURE,
            streaming=True,
        )
        self.tools = {
            "web_search": web_search_tool,
            "write_article": write_article_tool,
        }
        # 短记忆：会话消息历史
        self.memory: list = []
        # 当前会话的搜索素材缓存
        self._cached_materials: str = ""

    async def run(self, user_input: str) -> str:
        """执行一次完整的 Agent 循环

        流程：
        1. 将用户输入加入记忆
        2. 让 LLM 判断意图并决定是否调用工具
        3. 如果需要工具 → 调用工具 → 将结果返回 LLM 继续处理
        4. 如果不需要工具 → 直接输出最终回复
        """
        self.memory.append(HumanMessage(content=user_input))

        # 构建带系统提示的消息列表
        messages = [SystemMessage(content=SYSTEM_PROMPT)] + self.memory

        # 第一轮：让 LLM 决定行动
        response = await self.llm.ainvoke(messages)
        response_text = response.content
        self.memory.append(AIMessage(content=response_text))

        # 解析是否需要调用工具
        tool_call = self._parse_tool_call(response_text)

        if tool_call:
            # 执行工具
            tool_result = await self._execute_tool(tool_call)
            tool_message = f"[工具 {tool_call['name']} 返回结果]\n{tool_result}"
            self.memory.append(SystemMessage(content=tool_message))

            # 第二轮：基于工具结果生成最终回复
            final_messages = [SystemMessage(content=SYSTEM_PROMPT)] + self.memory
            final_response = await self.llm.ainvoke(final_messages)
            final_text = final_response.content
            self.memory.append(AIMessage(content=final_text))
            return final_text
        else:
            # 不需要工具，直接回复（可能是纯对话或修改指令）
            return response_text

    async def run_stream(self, user_input: str):
        """流式输出版本的 Agent 循环，逐步 yield 文本片段"""
        self.memory.append(HumanMessage(content=user_input))
        messages = [SystemMessage(content=SYSTEM_PROMPT)] + self.memory

        # 第一轮：判断意图
        response = await self.llm.ainvoke(messages)
        response_text = response.content
        self.memory.append(AIMessage(content=response_text))
        yield f"__thinking__\n{response_text}"

        tool_call = self._parse_tool_call(response_text)

        if tool_call:
            yield f"\n\n__tool_call__\n正在调用 {tool_call['name']}..."

            # 执行工具
            tool_result = await self._execute_tool(tool_call)
            self._cached_materials = tool_result
            tool_message = f"[工具 {tool_call['name']} 返回结果]\n{tool_result}"
            self.memory.append(SystemMessage(content=tool_message))
            yield f"\n\n__tool_result__\n素材收集完成"

            # 第二轮：生成文章（流式）
            yield "\n\n__writing__\n"
            final_messages = [SystemMessage(content=SYSTEM_PROMPT)] + self.memory

            # 流式输出文章内容
            async for chunk in self.llm.astream(final_messages):
                chunk_text = chunk.content
                if chunk_text:
                    yield chunk_text

            # 记录完整回复到记忆
            # （流式模式下需要单独获取完整文本，这里简化处理）
        else:
            # 无需工具，直接输出回复
            yield f"\n\n__response__\n{response_text}"

    def _parse_tool_call(self, text: str) -> dict | None:
        """从 LLM 输出中解析工具调用

        查找 JSON 格式的工具调用标记：
        {"tool": "xxx", "params": {...}}
        """
        import re

        # 尝试匹配 JSON 格式的工具调用
        patterns = [
            r'\{\s*"tool"\s*:\s*"(.*?)"\s*,\s*"params"\s*:\s*(\{.*?\})\s*\}',
            r'\{\s*"name"\s*:\s*"(.*?)"\s*,\s*"params"\s*:\s*(\{.*?\})\s*\}',
            r'```json\s*(\{[^`]*"tool"[^`]*\})\s*```',
        ]

        for pattern in patterns:
            match = re.search(pattern, text, re.DOTALL)
            if match:
                try:
                    if len(match.groups()) == 2:
                        tool_name = match.group(1).strip().lower()
                        params_str = match.group(2)
                    else:
                        full_json = match.group(1)
                        parsed = json.loads(full_json)
                        tool_name = parsed.get("tool", parsed.get("name", "")).lower()
                        params_str = json.dumps(parsed.get("params", {}))

                    params = json.loads(params_str)
                    return {"name": tool_name, "params": params}
                except (json.JSONDecodeError, KeyError):
                    continue

        # 关键词 fallback：检测搜索意图
        search_keywords = ["搜索", "查找", "搜一下", "search", "找资料"]
        write_keywords = ["写", "撰写", "生成", "分析", "写一篇", "帮我写"]

        lower_text = text.lower()
        if any(kw in lower_text for kw in write_keywords):
            # 从上下文推断主题
            topic = self._extract_topic(text)
            return {
                "name": "write_article",
                "params": {"topic": topic, "style": "industry_analysis"},
            }

        if any(kw in lower_text for kw in search_keywords):
            query = self._extract_topic(text)
            return {"name": "web_search", "params": {"query": query}}

        return None

    def _extract_topic(self, text: str) -> str:
        """从用户输入中提取写作/搜索主题"""
        # 简单提取：去掉常见的动词前缀
        prefixes = [
            "帮我写", "写一篇", "写一个", "撰写", "生成",
            "搜索", "查找", "搜一下", "关于", "分析",
            "请帮我", "我想", "我要",
        ]
        topic = text.strip()
        for prefix in prefixes:
            if topic.startswith(prefix):
                topic = topic[len(prefix):].strip()
                break
        # 去掉末尾标点
        topic = topic.rstrip("。，！？、")
        return topic or text

    async def _execute_tool(self, call: dict) -> str:
        """执行工具调用"""
        tool_name = call["name"]
        params = call.get("params", {})

        # 工具名称映射（支持多种命名方式）
        name_map = {
            "web_search": "web_search",
            "search": "web_search",
            "write_article": "write_article",
            "write": "write_article",
            "article_writer": "write_article",
        }

        actual_name = name_map.get(tool_name, tool_name)
        tool = self.tools.get(actual_name)

        if not tool:
            return f"未知工具: {tool_name}，可用工具: {list(self.tools.keys())}"

        try:
            result = await tool.run(**params)
            return result
        except Exception as e:
            return f"工具执行错误 ({tool_name}): {str(e)}"

    def clear_memory(self):
        """清空会话记忆"""
        self.memory = []
        self._cached_materials = ""

    def get_memory_length(self) -> int:
        """获取当前记忆条数"""
        return len(self.memory)
