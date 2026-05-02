import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/developer_provider.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import '../widgets/custom_toast.dart';
import 'leaderboard_page.dart';

class DeveloperPage extends StatefulWidget {
  const DeveloperPage({super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  String _version = '...';
  String _buildNumber = '...';
  String _userId = '...';

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
      _userId = prefs.getString('userIdentifier') ?? '未生成';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('开发者模式'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: '退出开发者模式',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('退出开发者模式'),
                  content: const Text('退出后将隐藏开发者功能，需要重新激活才能使用。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<DeveloperProvider>().disableDeveloperMode();
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('确认退出'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 提示卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFF59E0B), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '当前处于开发者模式，部分功能可能不稳定。',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 功能列表
          _buildSectionTitle(theme, '实验性功能'),
          const SizedBox(height: 12),
          _buildDevItem(
            context,
            icon: Icons.leaderboard_rounded,
            title: '积分排行榜',
            subtitle: '查看积分排名（云函数连接中）',
            color: const Color(0xFFEF4444),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardPage()),
            ),
          ),
          const SizedBox(height: 12),
          _buildDevItem(
            context,
            icon: Icons.system_update_rounded,
            title: '检查更新',
            subtitle: '手动检查是否有新版本',
            color: const Color(0xFF4361EE),
            onTap: () => _checkUpdate(context),
          ),
          const SizedBox(height: 12),
          _buildDevItem(
            context,
            icon: Icons.bug_report_rounded,
            title: '清除缓存数据',
            subtitle: '清除本地缓存并重置应用状态',
            color: const Color(0xFF10B981),
            onTap: () => _showClearCacheDialog(context),
          ),
          const SizedBox(height: 12),
          _buildDevItem(
            context,
            icon: Icons.copy_rounded,
            title: '复制用户标识',
            subtitle: _userId,
            color: const Color(0xFF8B5CF6),
            onTap: () {
              Clipboard.setData(ClipboardData(text: _userId));
              CustomToast.success(context, '用户标识已复制到剪贴板');
            },
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(theme, '高级权限'),
          const SizedBox(height: 12),
          _buildDevItem(
            context,
            icon: Icons.admin_panel_settings_rounded,
            title: '强制检查更新（忽略版本）',
            subtitle: '无论当前版本如何都弹出更新提示',
            color: const Color(0xFFEC4899),
            onTap: () => _forceCheckUpdate(context),
          ),
          const SizedBox(height: 12),
          _buildDevItem(
            context,
            icon: Icons.data_usage_rounded,
            title: '查看本地存储',
            subtitle: '查看 SharedPreferences 中的所有数据',
            color: const Color(0xFF06B6D4),
            onTap: () => _showLocalStorage(context),
          ),
          const SizedBox(height: 12),
          _buildDevItem(
            context,
            icon: Icons.restart_alt_rounded,
            title: '重置首次启动状态',
            subtitle: '模拟首次安装应用',
            color: const Color(0xFFF97316),
            onTap: () => _resetFirstLaunch(context),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(theme, '调试信息'),
          const SizedBox(height: 12),
          _buildInfoCard(theme, isDark),
        ],
      ),
    );
  }

  Future<void> _checkUpdate(BuildContext context) async {
    CustomToast.info(context, '正在检查更新...');
    try {
      final versionInfo = await updateService.checkForUpdate();
      if (!context.mounted) return;
      if (versionInfo != null) {
        // ignore: use_build_context_synchronously
        showUpdateDialog(context, versionInfo);
      } else {
        // ignore: use_build_context_synchronously
        CustomToast.success(context, '当前已是最新版本');
      }
    } catch (e) {
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      CustomToast.error(context, '检查更新失败: $e');
    }
  }

  Future<void> _forceCheckUpdate(BuildContext context) async {
    try {
      final versionInfo = await updateService.checkForUpdate();
      if (!context.mounted) return;
      if (versionInfo != null) {
        // ignore: use_build_context_synchronously
        showUpdateDialog(context, versionInfo);
      } else {
        // 即使没有新版本，也构造一个假的更新信息用于测试
        final fakeInfo = AppVersionInfo(
          version: '$_version (force)',
          buildNumber: int.tryParse(_buildNumber) ?? 0,
          downloadUrl: null,
          changelog: '这是强制检查更新的测试弹窗，当前已是最新版本。',
          forceUpdate: false,
        );
        // ignore: use_build_context_synchronously
        showUpdateDialog(context, fakeInfo);
      }
    } catch (e) {
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      CustomToast.error(context, '检查更新失败: $e');
    }
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除本地缓存数据吗？这不会删除你的账户数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              // 保留开发者模式和用户标识
              final devMode = prefs.getBool('developerMode');
              final userId = prefs.getString('userIdentifier');
              await prefs.clear();
              if (devMode == true) await prefs.setBool('developerMode', true);
              if (userId != null) await prefs.setString('userIdentifier', userId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                // ignore: use_build_context_synchronously
                CustomToast.success(context, '缓存已清除');
              }
            },
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocalStorage(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final buffer = StringBuffer();
    for (final key in keys.toList()..sort()) {
      final value = prefs.get(key);
      buffer.writeln('$key = $value');
    }
    if (!context.mounted) return;
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('本地存储数据'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              buffer.toString().isEmpty ? '(空)' : buffer.toString(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: buffer.toString()));
              Navigator.pop(ctx);
              CustomToast.success(context, '已复制到剪贴板');
            },
            child: const Text('复制'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetFirstLaunch(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch', true);
    if (context.mounted) {
      // ignore: use_build_context_synchronously
      CustomToast.success(context, '已重置首次启动状态，下次启动将显示引导页');
    }
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDevItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.45))),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.05) ??
                    Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        children: [
          _infoRow(theme, 'App 版本', _version),
          Divider(color: theme.dividerTheme.color, height: 20),
          _infoRow(theme, '构建号', _buildNumber),
          Divider(color: theme.dividerTheme.color, height: 20),
          _infoRow(theme, '用户标识', _userId),
          Divider(color: theme.dividerTheme.color, height: 20),
          _infoRow(theme, '开发者模式', '已启用'),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.6))),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}