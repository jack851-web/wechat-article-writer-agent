import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'pages/chat_page.dart';

void main() {
  // iOS 风格状态栏：深色内容 + 浅色背景
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const WriterAgentApp());
}

class WriterAgentApp extends StatelessWidget {
  const WriterAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WriterAgent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ChatPage(),
    );
  }
}
