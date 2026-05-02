import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 公告数据模型
class Announcement {
  final String id;
  final String title;
  final String content;
  final String date;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
  });
}

/// ============================================================
/// 📢 公告列表 —— 添加新公告在这里
/// 把新公告加在列表最前面，id 必须唯一且不能重复
/// ============================================================
final List<Announcement> announcements = [
  const Announcement(
    id: '4',
    title: 'v2.2 全新界面升级',
    content:
        '应用界面全面焕新！采用"轻未来感"设计风格，配色更舒适、布局更精致。首页新增个性化功能排序，关于页面展示了未来规划蓝图。让生活更简单，我们一直在路上。',
    date: '2026-04-30',
  ),
  const Announcement(
    id: '3',
    title: 'v2.1 新版本来袭',
    content:
        '应用新增了记事本功能，还加入了每日签到，每天签到可以增加积分，积分可以提升等级哦，积分可有大用处，赶紧来探索体验吧！',
    date: '2026-04-28',
  ),
  const Announcement(
    id: '2',
    title: 'v2.0 全新改版',
    content:
        '应用迎来全新UI设计，采用现代化极简风格。新增个人主页、版本日志、分类管理等功能，快来体验吧！',
    date: '2026-04-28',
  ),
  const Announcement(
    id: '1',
    title: '欢迎使用我的私人助理',
    content:
        '感谢你安装本应用！这是一款能够帮助你的个人效率工具，致力于让你的生活更加简单有序。',
    date: '2026-04-27',
  ),
];

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  Set<String> _readIds = {};

  @override
  void initState() {
    super.initState();
    _loadAndMarkRead();
  }

  Future<void> _loadAndMarkRead() async {
    final prefs = await SharedPreferences.getInstance();
    final readList = prefs.getStringList('readAnnouncements') ?? [];
    setState(() {
      _readIds = readList.toSet();
    });
    // 进入页面后把所有公告标记为已读
    final allIds = announcements.map((a) => a.id).toList();
    await prefs.setStringList('readAnnouncements', allIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('通知中心')),
      body: announcements.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final a = announcements[index];
                final isRead = _readIds.contains(a.id);
                return _buildCard(theme, isDark, a, isRead);
              },
            ),
    );
  }

  /// 空状态：没有公告时的显示
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 40,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '暂无公告',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color
                  ?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '有新消息时会在这里显示',
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color
                  ?.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }

  /// 单条公告卡片
  Widget _buildCard(
    ThemeData theme,
    bool isDark,
    Announcement a,
    bool isRead,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: !isRead
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行：未读圆点 + 标题 + 日期
          Row(
            children: [
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Text(
                  a.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isRead
                        ? theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.6)
                        : null,
                  ),
                ),
              ),
              Text(
                a.date,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 正文内容
          Text(
            a.content,
            style: TextStyle(
              height: 1.6,
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color
                  ?.withValues(alpha: isRead ? 0.5 : 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
