import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../providers/profile_provider.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  late DateTime _displayMonth;
  int? _justEarned;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  void _doCheckIn() {
    final profile = context.read<ProfileProvider>();
    final earned = profile.checkIn();
    if (earned > 0) {
      setState(() => _justEarned = earned);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final theme = Theme.of(context);
    final level = profile.currentLevel;
    final isMax = level.level >= levels.length;

    return Scaffold(
      appBar: AppBar(title: const Text('每日签到')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildLevelCard(theme, profile, level, isMax),
            const SizedBox(height: 16),
            _buildStatsRow(theme, profile),
            const SizedBox(height: 20),
            _buildCheckInButton(theme, profile),
            const SizedBox(height: 24),
            _buildCalendar(theme, profile),
          ],
        ),
      ),
    );
  }

  // ---------- 等级卡片（点击可查看全部等级） ----------

  Widget _buildLevelCard(
      ThemeData theme, ProfileProvider p, LevelInfo level, bool isMax) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showAllLevels(context, p, theme),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF312E81), const Color(0xFF1E1B4B)]
                : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(level.icon, size: 40, color: level.color),
            const SizedBox(height: 12),
            Text('Lv.${level.level}  ${level.name}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${p.points} 积分',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: isMax ? 1.0 : p.levelProgress,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                color: level.color,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isMax ? '已达最高等级' : '距离下一级还需 ${p.pointsToNextLevel} 积分',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_up,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.5)),
                Text('点击查看全部等级',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 统计卡片 ----------

  Widget _buildStatsRow(ThemeData theme, ProfileProvider p) {
    return Row(
      children: [
        _statItem(theme, Icons.stars, '${p.points}', '总积分'),
        const SizedBox(width: 12),
        _statItem(theme, Icons.local_fire_department,
            '${p.consecutiveDays}', '连续签到'),
        const SizedBox(width: 12),
        _statItem(theme, Icons.calendar_month,
            '${p.monthlyCheckInCount}', '本月签到'),
      ],
    );
  }

  Widget _statItem(
      ThemeData theme, IconData icon, String value, String label) {
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  // ---------- 签到按钮 ----------

  Widget _buildCheckInButton(ThemeData theme, ProfileProvider p) {
    final canCheckIn = p.canCheckInToday;

    if (!canCheckIn && _justEarned == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle,
                color: Color(0xFF10B981), size: 22),
            const SizedBox(width: 8),
            Text(
              '今日已签到  +${p.checkInHistory[DateFormat('yyyy-MM-dd').format(DateTime.now())] ?? 0}积分',
              style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (_justEarned != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration,
                color: Color(0xFF10B981), size: 22),
            const SizedBox(width: 8),
            Text(
              '签到成功  +$_justEarned积分',
              style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _doCheckIn,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('签到', style: TextStyle(fontSize: 17)),
      ),
    );
  }

  // ---------- 日历 ----------

  Widget _buildCalendar(ThemeData theme, ProfileProvider p) {
    final isDark = theme.brightness == Brightness.dark;
    final year = _displayMonth.year;
    final month = _displayMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = firstDay.weekday == 7 ? 0 : firstDay.weekday;
    final now = DateTime.now();
    final canGoForward =
        year < now.year || (year == now.year && month < now.month);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _displayMonth = DateTime(year, month - 1);
                }),
              ),
              Text('$year年$month月',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: canGoForward
                    ? () => setState(() {
                          _displayMonth = DateTime(year, month + 1);
                        })
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: ['日', '一', '二', '三', '四', '五', '六']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.4))),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (ctx, index) {
              if (index < firstWeekday) return const SizedBox();
              final day = index - firstWeekday + 1;
              final dateStr =
                  DateFormat('yyyy-MM-dd').format(DateTime(year, month, day));
              final isChecked = p.checkInHistory.containsKey(dateStr);
              final isToday = now.year == year &&
                  now.month == month &&
                  now.day == day;
              final earned = p.checkInHistory[dateStr];

              return Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isChecked
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : isToday
                            ? theme.colorScheme.primary
                                .withValues(alpha: 0.08)
                            : null,
                    shape: BoxShape.circle,
                    border: isToday && !isChecked
                        ? Border.all(
                            color: theme.colorScheme.primary, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: isChecked
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$day',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary)),
                              Text('$earned',
                                  style: TextStyle(
                                      fontSize: 8,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.7))),
                            ],
                          )
                        : Text('$day',
                            style: TextStyle(
                                fontSize: 13,
                                color: isToday
                                    ? theme.colorScheme.primary
                                    : theme.textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.7),
                                fontWeight: isToday
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------- 全部等级弹窗 ----------

  void _showAllLevels(
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
                      final isCurrent =
                          lv.level == profile.currentLevel.level;
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
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                  color:
                                      lv.color.withValues(alpha: 0.5)),
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
}
