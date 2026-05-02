import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import '../widgets/custom_toast.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '获取中...';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = info.version);
  }

  Future<void> _checkForUpdate() async {
    if (_checking) return;
    setState(() => _checking = true);
    CustomToast.info(context, '正在检查更新...');
    try {
      final versionInfo = await updateService.checkForUpdate();
      if (!context.mounted) return;
      if (versionInfo != null) {
        // ignore: use_build_context_synchronously
        showUpdateDialog(context, versionInfo);
      } else {
        // ignore: use_build_context_synchronously
        CustomToast.success(context, '当前已是最新版本 ✓');
      }
    } catch (e) {
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      CustomToast.error(context, '检查更新失败: $e');
    } finally {
      if (context.mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            // ── App Icon ──
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF7B8CFF), Color(0xFF5B3FE4)]
                      : const [Color(0xFF4361EE), Color(0xFF5B3FE4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isDark
                            ? const Color(0xFF7B8CFF)
                            : const Color(0xFF4361EE))
                        .withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 44, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text('私人助理',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text('版本 $_version',
                style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.45))),
            const SizedBox(height: 16),

            // ── 检查更新按钮 ──
            GestureDetector(
              onTap: _checking ? null : _checkForUpdate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF7B8CFF), Color(0xFF5B3FE4)]
                        : const [Color(0xFF4361EE), Color(0xFF5B3FE4)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark
                              ? const Color(0xFF7B8CFF)
                              : const Color(0xFF4361EE))
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_checking)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.system_update_rounded,
                          color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _checking ? '检查中...' : '检查版本更新',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),

            // ── 应用介绍 ──
            _card(theme, isDark, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    const Text('关于应用',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '私人助理是一款面向日常生活的个人效率工具，致力于让你的生活更加简单、有序、高效。',
                  style: TextStyle(
                    height: 1.7,
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '我们相信，好的工具应该像一位贴心的助手，默默帮你打理生活中的大小事务。目前应用已涵盖密码管理、记账、记事本与提醒等功能，未来还将持续扩展更多实用模块，全方位提升你的生活品质。',
                  style: TextStyle(
                    height: 1.7,
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            )),
            const SizedBox(height: 12),

            // ── 已上线功能 ──
            _card(theme, isDark, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('已上线功能',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 14),
                _featureItem(theme, Icons.shield_outlined, const Color(0xFF4361EE),
                    '密码本', '安全的本地密码管理，一键复制'),
                _featureItem(theme, Icons.pie_chart_outline_rounded, const Color(0xFF10B981),
                    '记账工具', '分类收支记录，月度统计分析'),
                _featureItem(theme, Icons.edit_note_rounded, const Color(0xFFF59E0B),
                    '记事本', '文本记录与事件提醒'),
                _featureItem(theme, Icons.emoji_events_outlined, const Color(0xFFEC4899),
                    '签到积分', '每日签到，等级成长体系'),
              ],
            )),
            const SizedBox(height: 12),

            // ── 未来规划 ──
            _card(theme, isDark, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('未来规划',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 14),
                _roadmapItem(theme, '习惯打卡', '培养好习惯，追踪每日进度'),
                _roadmapItem(theme, '健康助手', '饮水提醒、作息记录'),
                _roadmapItem(theme, '日程管理', '日历视图，智能日程安排'),
                _roadmapItem(theme, '更多实用工具', '持续迭代，让生活更便利'),
              ],
            )),
            const SizedBox(height: 40),

            Text('© 2026 私人助理',
                style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.3))),
            const SizedBox(height: 8),
            Text('让生活更简单',
                style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.2),
                    letterSpacing: 1)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _card(ThemeData theme, bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }

  Widget _featureItem(
      ThemeData theme, IconData icon, Color color, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(desc,
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.45))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roadmapItem(ThemeData theme, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.textTheme.bodyMedium?.color
                  ?.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.7))),
                const SizedBox(height: 2),
                Text(desc,
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}