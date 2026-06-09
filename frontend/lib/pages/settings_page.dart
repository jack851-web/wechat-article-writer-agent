import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';

/// 设置页面 — Apple 风格：分组列表、utility card
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _urlController = TextEditingController();
  bool _isTesting = false;
  bool _connectionOk = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text =
          prefs.getString('base_url') ?? 'http://127.0.0.1:8000';
    });
    _testConnection();
  }

  Future<void> _testConnection() async {
    if (_isTesting) return;
    setState(() {
      _isTesting = true;
      _connectionOk = false;
    });

    try {
      final api = ApiService();
      await api.setBaseUrl(_urlController.text.trim());
      final ok = await api.healthCheck();
      if (mounted) setState(() => _connectionOk = ok);
    } catch (_) {
      if (mounted) setState(() => _connectionOk = false);
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppTheme.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '设置',
          style: AppTheme.captionStrong.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppTheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLg,
          vertical: AppTheme.spaceLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Section: 服务配置 ===
            Text(
              '服务配置',
              style: AppTheme.captionStrong.copyWith(
                fontSize: 13,
                letterSpacing: -0.224,
                color: AppTheme.inkMuted48,
              ),
            ),
            SizedBox(height: AppTheme.spaceSm),

            // 服务地址卡片 — store-utility-card 风格
            _UtilityCard(
              children: [
                // URL 输入行
                Row(
                  children: [
                    Icon(Icons.dns_outlined, size: 20, color: AppTheme.primary),
                    SizedBox(width: AppTheme.spaceMd),
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        style: AppTheme.body.copyWith(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'http://127.0.0.1:8000',
                          hintStyle: AppTheme.caption.copyWith(fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _testConnection(),
                      ),
                    ),
                    // 连接状态指示器
                    _ConnectionDot(isOk: _connectionOk, isLoading: _isTesting),
                  ],
                ),

                Divider(height: 24, color: AppTheme.dividerSoft),

                // 测试连接按钮 — button-secondary-pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _isTesting ? null : _testConnection,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfacePearl,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isTesting)
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppTheme.primary,
                                ),
                              )
                            else
                              Icon(
                                Icons.wifi_tethering_rounded,
                                size: 16,
                                color: AppTheme.primary,
                              ),
                            SizedBox(width: AppTheme.spaceXs),
                            Text(
                              _isTesting ? '测试中...' : '测试连接',
                              style: AppTheme.buttonUtility,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: AppTheme.spaceXxl),

            // === Section: 模型信息 ===
            Text(
              '模型信息',
              style: AppTheme.captionStrong.copyWith(
                fontSize: 13,
                letterSpacing: -0.224,
                color: AppTheme.inkMuted48,
              ),
            ),
            SizedBox(height: AppTheme.spaceSm),

            // 信息卡片
            _UtilityCard(
              children: [
                _InfoRow('LLM 引擎', 'DeepSeek Chat / GPT-4o / Claude'),
                _InfoRow('后端框架', 'Python FastAPI'),
                _InfoRow('通信协议', 'HTTP + WebSocket'),
                Divider(height: 24, color: AppTheme.dividerSoft),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'API Key 请在后端 backend/.env 文件中配置',
                    style: AppTheme.finePrint,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppTheme.spaceXxl),

            // === Section: 关于 ===
            Text(
              '关于',
              style: AppTheme.captionStrong.copyWith(
                fontSize: 13,
                letterSpacing: -0.224,
                color: AppTheme.inkMuted48,
              ),
            ),
            SizedBox(height: AppTheme.spaceSm),

            // 关于卡片
            _UtilityCard(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 20,
                        color: AppTheme.primary,
                      ),
                    ),
                    SizedBox(width: AppTheme.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WriterAgent', style: AppTheme.bodyStrong),
                          Text('v1.0.0 — 公众号文章撰写智能体', style: AppTheme.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: AppTheme.spaceXxl),

            // 保存按钮 — button-store-hero 风格
            Center(
              child: _PillButton(
                label: '保存设置',
                icon: Icons.check_rounded,
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('base_url', _urlController.text.trim());
                  if (mounted) {
                    context.read<ChatProvider>().updateBaseUrl(
                      _urlController.text.trim(),
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white70,
                          ),
                          SizedBox(width: 8),
                          Text('设置已保存'),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: AppTheme.spaceXxl),
          ],
        ),
      ),
    );
  }
}

// ============ Utility Card — store-utility-card 风格 ============

class _UtilityCard extends StatelessWidget {
  final List<Widget> children;
  const _UtilityCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.canvas,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.hairline, width: 0.5),
      ),
      padding: EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// 信息行
Widget _InfoRow(String label, String value) {
  return Padding(
    padding: EdgeInsets.only(bottom: AppTheme.spaceSm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTheme.captionStrong.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.inkMuted80,
            ),
          ),
        ),
        Expanded(child: Text(value, style: AppTheme.body)),
      ],
    ),
  );
}

/// 连接状态圆点
class _ConnectionDot extends StatelessWidget {
  final bool isOk;
  final bool isLoading;
  const _ConnectionDot({required this.isOk, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 1.2,
          color: AppTheme.primary,
        ),
      );
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOk ? const Color(0xFF34c759) : AppTheme.inkMuted48,
      ),
    );
  }
}

/// Pill 按钮
class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppTheme.onPrimary),
              SizedBox(width: AppTheme.spaceXs),
              Text(label, style: AppTheme.buttonLarge),
            ],
          ),
        ),
      ),
    );
  }
}
