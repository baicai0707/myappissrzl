import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../providers/profile_provider.dart';
import '../widgets/app_drawer.dart';
import 'password_book_page.dart';
import 'accounting_page.dart';
import 'notepad_page.dart';
import 'course_page.dart';
import 'notification_page.dart';
import 'video_parser_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasUnread = false;
  List<String> _featureOrder = ['password', 'accounting', 'notepad', 'course', 'videoParser'];

  @override
  void initState() {
    super.initState();
    _checkUnread();
    _loadFeatureOrder();
  }

  Future<void> _loadFeatureOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('featureOrder');
    if (saved != null && saved.length == 5) {
      if (mounted) setState(() => _featureOrder = saved);
    }
  }

  Future<void> _saveFeatureOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('featureOrder', _featureOrder);
  }

  Future<void> _checkUnread() async {
    final prefs = await SharedPreferences.getInstance();
    final readList = prefs.getStringList('readAnnouncements') ?? [];
    final readSet = readList.toSet();
    final hasUnread = announcements.any((a) => !readSet.contains(a.id));
    if (mounted) setState(() => _hasUnread = hasUnread);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 12) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  String _getDateText() {
    final now = DateTime.now();
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final dateStr = '${now.month}月${now.day}日 · 周${weekdays[now.weekday - 1]}';
    final festival = _getFestival(now);
    if (festival != null) {
      return '$dateStr · $festival';
    }
    return dateStr;
  }

  String? _getFestival(DateTime date) {
    // 公历节日
    const solarFestivals = <String, String>{
      '1-1': '元旦',
      '2-14': '情人节',
      '3-8': '妇女节',
      '3-12': '植树节',
      '4-1': '愚人节',
      '4-22': '地球日',
      '5-1': '劳动节',
      '5-4': '青年节',
      '6-1': '儿童节',
      '7-1': '建党节',
      '8-1': '建军节',
      '9-10': '教师节',
      '10-1': '国庆节',
      '10-31': '万圣节',
      '11-11': '双十一',
      '12-24': '平安夜',
      '12-25': '圣诞节',
      '12-31': '跨年夜',
    };

    // 农历节日（固定公历日期，近似值，2025-2026年适用）
    const lunarFestivals = <String, String>{
      '1-29': '除夕',
      '1-30': '春节',
      '2-12': '元宵节',
      '4-4': '清明节',
      '5-31': '端午节',
      '10-6': '中秋节',
      '9-21': '重阳节',
    };

    // 特殊日期
    const specialDates = <String, String>{
      '5-20': '表白日',
      '5-21': '表白日',
      '11-11': '光棍节',
    };

    final key = '${date.month}-${date.day}';

    // 优先显示农历节日
    return lunarFestivals[key] ?? solarFestivals[key] ?? specialDates[key];
  }

  Map<String, _FeatureItem> _buildFeatureMap() {
    return {
      'password': _FeatureItem(
        Icons.shield_outlined,
        '密码本',
        '安全管理账号密码',
        const Color(0xFF4361EE),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PasswordBookPage())),
      ),
      'accounting': _FeatureItem(
        Icons.pie_chart_outline_rounded,
        '记账工具',
        '记录每一笔收支',
        const Color(0xFF10B981),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AccountingPage())),
      ),
      'notepad': _FeatureItem(
        Icons.edit_note_rounded,
        '记事本',
        '记录重要事项',
        const Color(0xFFF59E0B),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotepadPage())),
      ),
      'course': _FeatureItem(
        Icons.school_rounded,
        '我的课表',
        '查看课程安排与倒计时',
        const Color(0xFF8B5CF6),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CoursePage())),
      ),
      'videoParser': _FeatureItem(
        Icons.video_library_outlined,
        '视频解析',
        '获取无水印视频与图文',
        const Color(0xFFEC4899),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const VideoParserPage())),
      ),
    };
  }

  void _showReorderSheet() {
    final featureMap = _buildFeatureMap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const Text('调整功能顺序',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('长按拖动调整顺序',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey[500])),
                  const SizedBox(height: 20),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    itemCount: _featureOrder.length,
                    onReorder: (oldIndex, newIndex) {
                      setModal(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _featureOrder.removeAt(oldIndex);
                        _featureOrder.insert(newIndex, item);
                      });
                      setState(() {});
                      _saveFeatureOrder();
                    },
                    itemBuilder: (ctx, index) {
                      final key = _featureOrder[index];
                      final f = featureMap[key]!;
                      return Container(
                        key: ValueKey(key),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: f.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(f.icon, color: f.color, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(f.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(f.subtitle,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500])),
                                ],
                              ),
                            ),
                            Icon(Icons.drag_handle_rounded,
                                color: Colors.grey[400]),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final theme = Theme.of(context);
    final level = profile.currentLevel;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: _buildAvatar(profile, theme, level),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()}，${profile.name}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getDateText(),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.45),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildNotificationButton(theme),
                  ],
                ),
              ),
            ),

            // ── Hero Card ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildHeroCard(context, isDark),
              ),
            ),

            // ── Section Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Row(
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
                    const Text(
                      '功能',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _showReorderSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_vert_rounded,
                                size: 14,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text('排序',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Feature Cards ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: _buildFeatureList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(
      ProfileProvider profile, ThemeData theme, LevelInfo level) {
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            child: profile.avatarPath != null
                ? ClipOval(
                    child: Image.file(
                      File(profile.avatarPath!),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(Icons.person_rounded,
                          size: 20, color: theme.colorScheme.primary),
                    ),
                  )
                : Icon(Icons.person_rounded,
                    size: 20, color: theme.colorScheme.primary),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: level.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: Icon(level.icon, size: 7, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationButton(ThemeData theme) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationPage()));
        _checkUnread();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.08) ??
                Colors.transparent,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 22,
                color: theme.textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.7)),
            if (_hasUnread)
              Positioned(
                right: 9,
                top: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1A1F35),
                  const Color(0xFF161B2E),
                ]
              : [
                  const Color(0xFF4361EE),
                  const Color(0xFF5B3FE4),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF1A1F35) : const Color(0xFF4361EE))
                .withValues(alpha: isDark ? 0.5 : 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.9)),
                        const SizedBox(width: 4),
                        Text(
                          '私人助理',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '让生活更简单',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '永远相信美好的事情\n即将发生',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    final featureMap = _buildFeatureMap();
    final orderedFeatures =
        _featureOrder.map((key) => featureMap[key]!).toList();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final f = orderedFeatures[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFeatureCard(context, f, isDark),
          );
        },
        childCount: orderedFeatures.length,
      ),
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, _FeatureItem f, bool isDark) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: f.onTap,
      onLongPress: _showReorderSheet,
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
                color: f.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(f.icon, color: f.color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(f.subtitle,
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
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  _FeatureItem(
      this.icon, this.title, this.subtitle, this.color, this.onTap);
}