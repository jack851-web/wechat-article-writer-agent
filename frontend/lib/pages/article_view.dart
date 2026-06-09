import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// 文章预览页面 — Apple 风格：极简、内容为王
class ArticleViewPage extends StatelessWidget {
  final String content;

  const ArticleViewPage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spaceXxl,
          vertical: AppTheme.spaceLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文章正文 — Apple body 风格：17px, SF Pro Text
            SelectableText(
              _extractContent(),
              style: AppTheme.body.copyWith(
                fontSize: 17,
                height: 1.7,
                color: AppTheme.ink,
              ),
            ),

            SizedBox(height: AppTheme.spaceXxl),

            // 底部操作区 — pill 按钮风格
            _ActionBar(content: content),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.canvas,
      surfaceTintColor: Colors.transparent,
      title: Text(
        '文章预览',
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
        splashRadius: 20,
      ),
      actions: [
        // 复制按钮 — text-link 风格
        _AppBarAction(
          icon: Icons.copy_outlined,
          label: '复制',
          onTap: () => _copyToClipboard(context),
        ),
        SizedBox(width: AppTheme.spaceXs),

        // 分享按钮
        _AppBarAction(
          icon: Icons.share_outlined,
          label: '分享',
          onTap: () => _share(context),
        ),
        SizedBox(width: AppTheme.spaceSm),
      ],
    );
  }

  String _extractContent() {
    var cleaned = content;
    final footer = '*由 WriterAgent 自动生成*';
    if (cleaned.contains(footer)) {
      cleaned = cleaned.substring(0, cleaned.indexOf(footer)).trim();
    }
    final lines = cleaned.split('\n');
    return lines
        .where((line) {
          final t = line.trim();
          if (t.startsWith('> 风格') || t.startsWith('> 字数')) return false;
          return true;
        })
        .join('\n')
        .trim();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _extractContent()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 16, color: Colors.white70),
            SizedBox(width: 8),
            Text('已复制到剪贴板'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }

  void _share(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _extractContent()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 16, color: Colors.white70),
            SizedBox(width: 8),
            Text('已复制到剪贴板，可粘贴到公众号编辑器'),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }
}

/// AppBar 操作按钮 — Apple button-utility 风格
class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AppBarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceSm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppTheme.primary),
            SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.finePrint.copyWith(
                color: AppTheme.primary,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 底部操作栏 — button-primary + button-secondary-pill 风格
class _ActionBar extends StatelessWidget {
  final String content;
  const _ActionBar({required this.content});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: AppTheme.spaceSm,
        runSpacing: AppTheme.spaceSm,
        alignment: WrapAlignment.center,
        children: [
          // 主按钮 — button-primary (pill)
          _PillButton(
            label: '复制全文',
            icon: Icons.copy_rounded,
            isPrimary: true,
            onTap: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已复制'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          // 次要按钮 — button-secondary-pill
          _PillButton(
            label: '新建对话',
            icon: Icons.refresh_rounded,
            isPrimary: false,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

/// Pill 按钮 — Apple button-primary / button-secondary-pill
class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? AppTheme.primary : AppTheme.surfacePearl,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPrimary ? AppTheme.onPrimary : AppTheme.primary,
              ),
              SizedBox(width: AppTheme.spaceXs),
              Text(
                label,
                style: isPrimary
                    ? AppTheme.buttonLarge
                    : AppTheme.body.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
