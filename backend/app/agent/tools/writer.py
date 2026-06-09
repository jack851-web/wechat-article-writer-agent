"""文章撰写工具：基于素材 + LLM 生成公众号文章"""

from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage
from app.agent.prompts import WRITING_PROMPTS, STYLE_NAMES, LENGTH_MAP
from app.config import settings


class ArticleWriterTool:
    """文章撰写工具，根据搜索到的素材生成文章"""

    name = "write_article"
    description = "根据收集到的素材撰写公众号文章"

    def __init__(self):
        self.llm = ChatOpenAI(
            model=settings.LLM_MODEL,
            base_url=settings.LLM_BASE_URL,
            api_key=settings.LLM_API_KEY,
            temperature=settings.LLM_TEMPERATURE,
        )

    async def run(
        self,
        topic: str,
        style: str = "industry_analysis",
        materials: str = "",
        length: str = "medium",
    ) -> str:
        """生成文章

        Args:
            topic: 文章主题
            style: 文章风格 (industry_analysis / news_briefing / company_research)
            materials: 搜索到的素材文本
            length: 文章长度 (short / medium / long)

        Returns:
            生成的完整文章文本
        """
        # 验证风格参数
        if style not in WRITING_PROMPTS:
            available = ", ".join(WRITING_PROMPTS.keys())
            return (
                f"不支持的写作风格: {style}\n"
                f"可选风格: {available}\n"
                f"默认使用 industry_analysis 风格。"
            )
            style = "industry_analysis"

        # 获取对应风格的 Prompt 模板
        prompt_template = WRITING_PROMPTS[style]

        # 处理无素材的情况
        if not materials or materials.strip() == "":
            materials = (
                "（暂无外部搜索素材，请基于你的知识库和通用信息进行撰写。\n"
                "注意：建议先使用 web_search 工具收集相关资料以提升文章质量。）"
            )

        # 填充 Prompt
        prompt = prompt_template.format(
            topic=topic,
            materials=materials,
            length=LENGTH_MAP.get(length, length),
        )

        # 调用 LLM 生成文章
        response = await self.llm.ainvoke([HumanMessage(content=prompt)])
        article = response.content

        # 返回带元信息的完整结果
        result = f"""# {topic}

> 风格：{STYLE_NAMES.get(style, style)} | 字数要求：{LENGTH_MAP.get(length, length)}

---

{article}

---

*由 WriterAgent 自动生成*
"""
        return result


# 全局单例
write_article_tool = ArticleWriterTool()
