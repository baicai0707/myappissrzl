import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/developer_provider.dart';
import '../pages/profile_edit_page.dart';
import '../pages/checkin_page.dart';
import '../pages/version_history_page.dart';
import '../pages/about_page.dart';
import '../pages/developer_page.dart';
import 'custom_toast.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final level = profile.currentLevel;

    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // ---------- 头像区域 ----------
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(24, 36, 24, 28),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileEditPage()));
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.08),
                            child: profile.avatarPath != null
                                ? ClipOval(
                                    child: Image.file(
                                      File(profile.avatarPath!),
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Icon(
                                          Icons.person_rounded,
                                          size: 36,
                                          color: theme.colorScheme.primary),
                                    ),
                                  )
                                : Icon(Icons.person_rounded,
                                    size: 36,
                                    color: theme.colorScheme.primary),
                          ),
                        ),
                        // 编辑图标（右下）
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                size: 12, color: Colors.white),
                          ),
                        ),
                        // 等级徽章（左下）
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: level.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(level.icon,
                                size: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(profile.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600,
                          letterSpacing: 0.2)),
                  const SizedBox(height: 6),
                  // 等级信息
                  GestureDetector(
                    onTap: () => _showAllLevels(context, profile, theme),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: level.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(level.icon, size: 12, color: level.color),
                          const SizedBox(width: 4),
                          Text(
                            'Lv.${level.level} ${level.name}',
                            style: TextStyle(
                                fontSize: 11,
                                color: level.color,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 1,
                            height: 10,
                            color: level.color.withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${profile.points} 积分',
                            style: TextStyle(
                                fontSize: 11,
                                color: level.color.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: theme.dividerTheme.color),
            ),
            const SizedBox(height: 8),

            // ---------- 菜单项 ----------
            _menuItem(context, Icons.person_outline_rounded, '个人资料', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProfileEditPage()));
            }),
            _menuItem(context, Icons.calendar_today_rounded, '每日签到', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CheckInPage()));
            }),
            _menuItem(context, Icons.history_rounded, '版本记录', () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const VersionHistoryPage()));
            }),
            _menuItem(context, Icons.info_outline_rounded, '关于', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AboutPage()));
            }),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: theme.dividerTheme.color),
            ),

            // ---------- 深色模式 ----------
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text('深色模式',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.8))),
                    ),
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                      thumbColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return theme.colorScheme.primary;
                        }
                        return null;
                      }),
                      trackColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return theme.colorScheme.primary
                              .withValues(alpha: 0.5);
                        }
                        return null;
                      }),
                    ),
                  ],
                ),
              ),
            ),
            // ---------- 版本信息（隐藏入口） ----------
            GestureDetector(
              onTap: () {
                final devProvider = context.read<DeveloperProvider>();
                final activated = devProvider.handleSecretTap();
                if (activated) {
                  CustomToast.success(context, '开发者模式已激活');
                }
                if (devProvider.isDeveloperMode) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DeveloperPage()),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'v2.3.1',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------- 全部等级弹窗 ----------

  static void _showAllLevels(
      BuildContext context, ProfileProvider profile, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollCtrl) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('全部等级',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  '当前：${profile.points} 积分',
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: levels.length,
                    itemBuilder: (ctx, index) {
                      final lv = levels[index];
                      final isCurrent = lv.level == profile.currentLevel.level;
                      final isUnlocked =
                          profile.points >= lv.requiredPoints;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? lv.color.withValues(alpha: 0.08)
                              : theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? lv.color.withValues(alpha: 0.4)
                                : isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? lv.color.withValues(alpha: 0.15)
                                    : Colors.grey.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                lv.icon,
                                size: 22,
                                color: isUnlocked
                                    ? lv.color
                                    : Colors.grey.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Lv.${lv.level}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: isUnlocked
                                                ? lv.color
                                                : Colors.grey
                                                    .withValues(alpha: 0.5),
                                            fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        lv.name,
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isUnlocked
                                                ? null
                                                : Colors.grey.withValues(
                                                    alpha: 0.4)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lv.requiredPoints == 0
                                        ? '初始等级'
                                        : '需要 ${lv.requiredPoints} 积分',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: theme
                                            .textTheme.bodyMedium?.color
                                            ?.withValues(alpha: 0.4)),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: lv.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('当前',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: lv.color,
                                        fontWeight: FontWeight.w600)),
                              )
                            else if (!isUnlocked)
                              Icon(Icons.lock_outline,
                                  size: 18,
                                  color:
                                      Colors.grey.withValues(alpha: 0.3))
                            else
                              Icon(Icons.check_circle,
                                  size: 18,
                                  color: lv.color.withValues(alpha: 0.5)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      onTap: onTap,
    );
  }
}
