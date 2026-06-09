"""信息收集工具：网络搜索"""

import httpx
from app.config import settings


class WebSearchTool:
    """网页搜索工具，支持 Tavily API 和 Bing 搜索"""

    name = "web_search"
    description = "搜索网络上的最新资讯和资料"

    async def run(self, query: str, max_results: int = 8) -> str:
        """执行搜索并返回格式化结果

        Args:
            query: 搜索关键词
            max_results: 最大返回结果数

        Returns:
            格式化的搜索结果文本
        """
        # 优先使用 Tavily API（效果好，有免费额度）
        if settings.TAVILY_API_KEY and settings.TAVILY_API_KEY != "your_tavily_api_key_here":
            return await self._search_tavily(query, max_results)
        else:
            # Fallback：使用 Bing 搜索
            return await self._search_bing(query, max_results)

    async def _search_tavily(self, query: str, max_results: int) -> str:
        """通过 Tavily API 搜索"""
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(
                "https://api.tavily.com/search",
                json={
                    "query": query,
                    "max_results": max_results,
                    "include_answer": True,
                    "search_depth": "advanced",
                },
                headers={"Authorization": f"Bearer {settings.TAVILY_API_KEY}"},
            )
            resp.raise_for_status()
            data = resp.json()

        # 格式化输出
        lines = [f"## 搜索结果：{query}\n"]

        # Tavily 的 AI 摘要
        if data.get("answer"):
            lines.append(f"> **摘要**: {data['answer']}\n")

        results = data.get("results", [])
        if not results:
            return f"未找到关于「{query}」的相关结果。请尝试更换关键词。"

        for i, item in enumerate(results, 1):
            title = item.get("title", "无标题")
            content = item.get("content", "")[:200]
            url = item.get("url", "")
            score = item.get("score", 0)

            lines.append(f"### {i}. {title}")
            lines.append(f"- **相关度**: {score:.2f}")
            lines.append(f"- **摘要**: {content}...")
            lines.append(f"- **链接**: {url}")
            lines.append("")

        return "\n".join(lines)

    async def _search_bing(self, query: str, max_results: int) -> str:
        """Bing 搜索 Fallback（无需 API Key）"""
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(
                "https://api.bing.microsoft.com/v7.0/search",
                params={
                    "q": query,
                    "count": max_results,
                    "setLang": "zh-Hans",
                    "mkt": "zh-CN",
                },
                headers={
                    "Ocp-Apim-Subscription-Key": settings.TAVILY_API_KEY or "",
                },
            )
            if resp.status_code == 401 or resp.status_code == 403:
                # 无有效 Key 时返回提示
                return (
                    f"搜索服务未配置。\n"
                    f"请在 .env 文件中配置 TAVILY_API_KEY "
                    f"(申请地址: https://tavily.com)\n"
                    f"当前查询: {query}"
                )

            data = resp.json()

        lines = [f"## 搜索结果：{query}\n"]
        web_pages = data.get("webPages", {}).get("value", [])

        if not web_pages:
            return f"未找到关于「{query}」的相关结果。"

        for i, page in enumerate(web_pages[:max_results], 1):
            lines.append(f"### {i}. {page.get('name', '无标题')}")
            lines.append(f"- **摘要**: {page.get('snippet', '')[:200]}")
            lines.append(f"- **链接**: {page.get('url', '')}")
            lines.append("")

        return "\n".join(lines)


# 全局单例
web_search_tool = WebSearchTool()
