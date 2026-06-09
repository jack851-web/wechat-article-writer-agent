import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/chat_provider.dart';
import 'article_view.dart';
import 'settings_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _useStream = true;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    final provider = context.read<ChatProvider>();
    if (_useStream) {
      await provider.sendMessageStream(text);
    } else {
      await provider.sendMessage(text);
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: Scaffold(
        backgroundColor: AppTheme.canvasParchment,
        appBar: _buildAppBar(),
        body: Consumer<ChatProvider>(
          builder: (context, provider, _) => SafeArea(
            child: Column(
              children: [
                // 状态指示条 — Apple 风格：极细、无干扰
                if (provider.isLoading) _StatusStrip(text: provider.statusText),

                // 消息列表 / 空状态
                Expanded(
                  child: provider.messages.isEmpty
                      ? _EmptyState(
                          onTap: (text) {
                            _textController.text = text;
                            _handleSend();
                          },
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceLg,
                            vertical: AppTheme.spaceMd,
                          ),
                          itemCount:
                              provider.messages.length +
                              (provider.currentStreamText.isNotEmpty ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == provider.messages.length &&
                                provider.currentStreamText.isNotEmpty) {
                              return _MessageBubble.assistantStreaming(
                                text: provider.currentStreamText,
                              );
                            }
                            final msg = provider.messages[index];
                            return _MessageBubble.fromMessage(
                              msg,
                              onTap: msg.isAssistant && msg.content.length > 200
                                  ? () => _openArticle(msg.content)
                                  : null,
                            );
                          },
                        ),
                ),

                // 输入区域
                _InputBar(
                  controller: _textController,
                  isLoading: provider.isLoading,
                  onSend: _handleSend,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.canvas,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'WriterAgent',
        style: AppTheme.captionStrong.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.374,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined, size: 22, color: AppTheme.ink),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
          splashRadius: 20,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_horiz, size: 22, color: AppTheme.ink),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          elevation: 0,
          color: AppTheme.canvas,
          onSelected: (value) {
            if (value == 'reset') _showResetDialog();
            if (value == 'stream') setState(() => _useStream = !_useStream);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'stream',
              height: 44,
              child: Row(
                children: [
                  Icon(
                    _useStream
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  SizedBox(width: AppTheme.spaceSm),
                  Text('流式输出', style: AppTheme.body),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'reset',
              height: 44,
              child: Text(
                '重置会话',
                style: AppTheme.body.copyWith(color: AppTheme.ink),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openArticle(String content) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArticleViewPage(content: content)),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text('重置会话', style: AppTheme.bodyStrong),
        content: Text('确定要清空所有对话记录吗？', style: AppTheme.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '取消',
              style: AppTheme.body.copyWith(color: AppTheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().resetSession();
              Navigator.pop(ctx);
            },
            child: Text(
              '确定',
              style: AppTheme.body.copyWith(color: const Color(0xFFff3b30)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ 状态条 ============

class _StatusStrip extends StatelessWidget {
  final String text;
  const _StatusStrip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceXs,
      ),
      color: AppTheme.surfacePearl,
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppTheme.primary,
            ),
          ),
          SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Text(
              text.isNotEmpty ? text : '处理中...',
              style: AppTheme.caption,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ 空状态 ============

class _EmptyState extends StatelessWidget {
  final void Function(String) onTap;
  const _EmptyState({required this.onTap});

  static const _suggestions = [
    '写一篇 AI 大模型行业分析',
    '帮我分析最近的新能源汽车市场',
    '写一篇关于芯片产业的快讯',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceXxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo 图标 — Apple 风格：无背景色块，纯图标
            Icon(
              Icons.auto_awesome_rounded,
              size: 56,
              color: AppTheme.inkMuted48.withOpacity(0.3),
            ),
            SizedBox(height: AppTheme.spaceXl),

            // 主标题 — Apple tight tracking
            Text(
              'WriterAgent',
              style: AppTheme.displayLg.copyWith(fontSize: 34),
            ),
            SizedBox(height: AppTheme.spaceSm),

            // 副标题 — 轻量字重
            Text(
              '告诉我你想写什么文章',
              style: AppTheme.body.copyWith(
                fontWeight: FontWeight.w300,
                color: AppTheme.inkMuted48,
              ),
            ),
            SizedBox(height: AppTheme.spaceXxl),

            // 建议胶囊按钮 — pearl capsule 风格
            Wrap(
              spacing: AppTheme.spaceSm,
              runSpacing: AppTheme.spaceSm,
              alignment: WrapAlignment.center,
              children: _suggestions
                  .map((s) => _SuggestionChip(label: s, onTap: () => onTap(s)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pearl Capsule 建议按钮 — Apple 设计系统 button-pearl-capsule
class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfacePearl,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Text(
          label,
          style: AppTheme.captionStrong.copyWith(
            fontSize: 13,
            color: AppTheme.inkMuted80,
          ),
        ),
      ),
    );
  }
}

// ============ 消息气泡 ============

class _MessageBubble extends StatelessWidget {
  final MessageRole role;
  final String text;
  final bool isStreaming;
  final bool isError;
  final VoidCallback? onTap;

  const _MessageBubble({
    required this.role,
    required this.text,
    this.isStreaming = false,
    this.isError = false,
    this.onTap,
  });

  factory _MessageBubble.fromMessage(ChatMessage msg, {VoidCallback? onTap}) {
    return _MessageBubble(
      role: msg.role,
      text: msg.content,
      isError: msg.isError,
      onTap: onTap,
    );
  }

  factory _MessageBubble.assistantStreaming({required String text}) {
    return _MessageBubble(
      role: MessageRole.assistant,
      text: text,
      isStreaming: true,
    );
  }

  bool get isUser => role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spaceLg),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像 — 圆形，Apple 风格：icon-circular
          if (!isUser) ...[
            _Avatar(isUser: false),
            SizedBox(width: AppTheme.spaceSm),
          ],

          // 气泡内容
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppTheme.primary : AppTheme.canvas,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusLg),
                    topRight: Radius.circular(AppTheme.radiusLg),
                    bottomLeft: Radius.circular(
                      isUser ? AppTheme.radiusLg : AppTheme.radiusXs,
                    ),
                    bottomRight: Radius.circular(
                      isUser ? AppTheme.radiusXs : AppTheme.radiusLg,
                    ),
                  ),
                  // 用户消息无阴影；助手消息极淡边框（hairline）
                  border: isUser
                      ? null
                      : Border.all(color: AppTheme.hairline, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectableText(
                      text,
                      style: AppTheme.body.copyWith(
                        fontSize: 15,
                        height: 1.5,
                        color: isUser
                            ? AppTheme.onPrimary
                            : isError
                            ? const Color(0xFFff3b30)
                            : AppTheme.ink,
                      ),
                    ),

                    // 长文章 → 点击查看提示
                    if (!isUser && !isStreaming && text.length > 200)
                      Padding(
                        padding: EdgeInsets.only(top: AppTheme.spaceXs),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 12,
                              color: AppTheme.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '查看全文',
                              style: AppTheme.finePrint.copyWith(
                                color: AppTheme.primary,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 流式加载指示器
                    if (isStreaming)
                      Padding(
                        padding: EdgeInsets.only(top: AppTheme.spaceSm),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.2,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          if (isUser) ...[
            SizedBox(width: AppTheme.spaceSm),
            _Avatar(isUser: true),
          ],
        ],
      ),
    );
  }
}

/// 头像 — icon-circular 风格
class _Avatar extends StatelessWidget {
  final bool isUser;
  const _Avatar({required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser
            ? AppTheme.surfacePearl
            : AppTheme.primary.withOpacity(0.08),
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
        size: 17,
        color: isUser ? AppTheme.inkMuted80 : AppTheme.primary,
      ),
    );
  }
}

// ============ 输入栏 ============

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spaceLg,
        AppTheme.spaceSm,
        AppTheme.spaceLg,
        AppTheme.spaceLg + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.canvasParchment,
        border: Border(
          top: BorderSide(color: AppTheme.dividerSoft, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 输入框 — search-input 风格：pill 形状 + canvas 背景
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.send,
              style: AppTheme.body.copyWith(fontSize: 15),
              decoration: InputDecoration(
                hintText: '输入写作指令...',
                hintStyle: AppTheme.caption.copyWith(fontSize: 15),
                filled: true,
                fillColor: AppTheme.canvas,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  borderSide: BorderSide(color: AppTheme.primary, width: 0.5),
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          SizedBox(width: AppTheme.spaceSm),

          // 发送按钮 — icon-circular 风格
          Material(
            color: isLoading
                ? AppTheme.surfaceChipTranslucent
                : AppTheme.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: InkWell(
              onTap: isLoading ? null : onSend,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 18,
                  color: isLoading ? AppTheme.inkMuted48 : AppTheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
