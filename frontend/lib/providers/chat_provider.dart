import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/api_service.dart';

/// 聊天状态管理
class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // 消息列表
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  // 状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _currentStreamText = '';
  String get currentStreamText => _currentStreamText;

  String _statusText = '';
  String get statusText => _statusText;

  int _memoryLength = 0;
  int get memoryLength => _memoryLength;

  /// 发送消息（非流式）
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(role: MessageRole.user, content: text));
    _isLoading = true;
    _statusText = '思考中...';
    notifyListeners();

    try {
      final response = await _api.sendMessage(text);
      _messages.add(
        ChatMessage(role: MessageRole.assistant, content: response.reply),
      );
      _memoryLength = response.memoryLength;
    } catch (e) {
      _messages.add(
        ChatMessage(
          role: MessageRole.assistant,
          content: '请求失败: $e',
          isError: true,
        ),
      );
    } finally {
      _isLoading = false;
      _statusText = '';
      notifyListeners();
    }
  }

  /// 发送消息（流式 WebSocket）
  Future<void> sendMessageStream(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(role: MessageRole.user, content: text));
    _isLoading = true;
    _currentStreamText = '';
    _statusText = '连接中...';
    notifyListeners();

    String lastMemoryJson = '{}';
    try {
      final baseUrl = await _api.getBaseUrl();
      final wsUrl = baseUrl.replaceFirst('http', 'ws');
      final channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/api/chat/stream'),
      );

      // 发送用户消息
      channel.sink.add(jsonEncode({'type': 'message', 'content': text}));

      // 接收流式响应
      StringBuffer articleBuffer = StringBuffer();
      await for (final message in channel.stream) {
        final data = json.decode(message as String) as Map<String, dynamic>;
        final type = data['type'] ?? '';
        final content = data['content'] ?? '';

        if (type == '__done__') {
          lastMemoryJson = json.encode(data);
          break;
        }

        if (type == '__error__') {
          _currentStreamText += '\n\n[错误] $content';
          continue;
        }

        if (type == '__thinking__') {
          _statusText = '正在分析需求...';
          notifyListeners();
          continue;
        }

        if (type == '__tool_call__') {
          _statusText = content;
          notifyListeners();
          continue;
        }

        if (type == '__tool_result__') {
          _statusText = '正在撰写文章...';
          notifyListeners();
          continue;
        }

        if (type == '__writing__' || type == '__response__') {
          _statusText = '生成中...';
        }

        // 普通文本 chunk
        articleBuffer.write(content);
        _currentStreamText = articleBuffer.toString();
        notifyListeners();
      }

      // 流式完成，添加到消息列表
      final finalText = _currentStreamText.trim();
      if (finalText.isNotEmpty) {
        _messages.add(
          ChatMessage(role: MessageRole.assistant, content: finalText),
        );
      }
      if (lastMemoryJson.isNotEmpty && lastMemoryJson != '{}') {
        final memData = json.decode(lastMemoryJson);
        _memoryLength = memData['memory_length'] ?? _memoryLength;
      }
      await channel.sink.close();
    } catch (e) {
      _messages.add(
        ChatMessage(
          role: MessageRole.assistant,
          content: '连接失败: $e',
          isError: true,
        ),
      );
    } finally {
      _isLoading = false;
      _statusText = '';
      _currentStreamText = '';
      notifyListeners();
    }
  }

  /// 重置会话
  Future<void> resetSession() async {
    try {
      await _api.resetSession();
    } catch (_) {}
    _messages.clear();
    _memoryLength = 0;
    notifyListeners();
  }

  /// 检查后端连接
  Future<bool> checkConnection() async {
    return await _api.healthCheck();
  }

  /// 更新后端地址
  Future<void> updateBaseUrl(String url) async {
    await _api.setBaseUrl(url);
  }
}

/// 消息角色
enum MessageRole { user, assistant, system }

/// 单条聊天消息
class ChatMessage {
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isError;
  final String? articleTitle;

  ChatMessage({
    required this.role,
    required this.content,
    this.isError = false,
    this.articleTitle,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
}
