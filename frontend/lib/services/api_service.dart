import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API 服务：管理与后端 FastAPI 的所有通信
class ApiService {
  static const String _defaultBaseUrl = "http://127.0.0.1:8000";
  late final Dio _dio;
  WebSocketChannel? _wsChannel;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _defaultBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 120), // 写作可能耗时较长
      ),
    );
  }

  /// 获取当前配置的后端地址
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? _defaultBaseUrl;
  }

  /// 设置后端地址
  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', url);
    _dio.options.baseUrl = url;
  }

  /// 非流式对话
  Future<ChatResponse> sendMessage(String message) async {
    final baseUrl = await getBaseUrl();
    final response = await _dio.post(
      '$baseUrl/api/chat',
      data: {'message': message},
    );
    return ChatResponse.fromJson(response.data);
  }

  /// 重置会话
  Future<void> resetSession() async {
    final baseUrl = await getBaseUrl();
    await _dio.post('$baseUrl/api/session/reset');
  }

  /// 健康检查
  Future<bool> healthCheck() async {
    try {
      final baseUrl = await getBaseUrl();
      await _dio.get('$baseUrl/api/health');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 建立 WebSocket 连接（流式对话）
  Stream<WsMessage> connectStream({
    required void Function(WsMessage) onMessage,
    required void Function() onDone,
    required void Function(dynamic error) onError,
  }) async* {
    final baseUrl = await getBaseUrl();
    final wsUrl = baseUrl.replaceFirst('http', 'ws');

    _wsChannel = WebSocketChannel.connect(Uri.parse('$wsUrl/api/chat/stream'));

    await for (final message in _wsChannel!.stream) {
      final data = json.decode(message as String);
      yield WsMessage.fromJson(data);
    }
  }

  /// 关闭 WebSocket
  void closeStream() {
    _wsChannel?.sink.close();
    _wsChannel = null;
  }
}

/// HTTP 对话响应模型
class ChatResponse {
  final String reply;
  final int memoryLength;

  ChatResponse({required this.reply, required this.memoryLength});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'] ?? '',
      memoryLength: json['memory_length'] ?? 0,
    );
  }
}

/// WebSocket 消息模型
class WsMessage {
  final String type; // chunk / __done__ / __error__
  final String content;
  final int? memoryLength;

  WsMessage({required this.type, this.content = '', this.memoryLength});

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    return WsMessage(
      type: json['type'] ?? 'chunk',
      content: json['content'] ?? '',
      memoryLength: json['memory_length'],
    );
  }

  bool get isDone => type == '__done__';
  bool get isError => type == '__error__';
  bool get isChunk => type == 'chunk';
}
