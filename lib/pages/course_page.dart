import 'dart:async';
import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/course_override.dart';
import '../services/course_service.dart';
import 'course_edit_page.dart';
import 'course_override_page.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  List<Course> _allCourses = [];
  List<CourseOverride> _allOverrides = [];
  Course? _nextCourse;
  Duration? _countdown;
  Timer? _timer;
  int _selectedWeekday = DateTime.now().weekday;
  bool _loading = true;

  static const _weekdayNames = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateCountdown();
    });
  }

  Future<void> _loadData() async {
    final courses = await courseService.getAllCourses();
    final overrides = await courseService.getAllOverrides();
    if (!mounted) return;
    setState(() {
      _allCourses = courses;
      _allOverrides = overrides;
      _loading = false;
    });
    _updateCountdown();
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final next = courseService.getNextCourse(_allCourses, now: now, overrides: _allOverrides);
    final countdown = next != null ? courseService.getCountdown(next, now: now) : null;
    if (mounted) {
      setState(() {
        _nextCourse = next;
        _countdown = countdown;
      });
    }
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) {
      return '${d.inDays}天 ${d.inHours.remainder(24).toString().padLeft(2, '0')}:'
          '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
          '${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    }
    return '${d.inHours.toString().padLeft(2, '0')}:'
        '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
        '${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  /// 获取选中日期的解析后课程列表
  List<ResolvedCourse> _getSelectedDayResolved() {
    final now = DateTime.now();
    final daysUntil = _selectedWeekday - now.weekday;
    final targetDate = DateTime(now.year, now.month, now.day + daysUntil);
    return courseService.getResolvedCoursesForDate(_allCourses, _allOverrides, targetDate);
  }

  Future<void> _navigateToEdit({Course? course}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CourseEditPage(course: course)),
    );
    if (result == true) _loadData();
  }

  Future<void> _navigateToOverrides() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CourseOverridePage()),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的课表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: '调课管理',
            onPressed: _navigateToOverrides,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: '添加课程',
            onPressed: () => _navigateToEdit(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  // 倒计时卡片
                  _buildCountdownCard(theme, isDark),
                  const SizedBox(height: 20),

                  // 星期选择器
                  _buildWeekdaySelector(theme, isDark),
                  const SizedBox(height: 16),

                  // 当天课程列表
                  if (_allCourses.isEmpty)
                    _buildEmptyState(theme, isDark)
                  else ...[
                    ..._getSelectedDayResolved().map(
                      (rc) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildResolvedCourseCard(rc, theme, isDark),
                      ),
                    ),
                    if (_getSelectedDayResolved().isEmpty)
                      _buildNoCourseDay(theme),
                  ],
                ],
              ),
            ),
    );
  }

  // ── 倒计时卡片 ──
  Widget _buildCountdownCard(ThemeData theme, bool isDark) {
    final course = _nextCourse;
    final countdown = _countdown;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1F35), const Color(0xFF161B2E)]
              : [const Color(0xFF4361EE), const Color(0xFF5B3FE4)],
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
      child: course == null
          ? Column(
              children: [
                Icon(Icons.school_rounded,
                    size: 40, color: Colors.white.withValues(alpha: 0.6)),
                const SizedBox(height: 12),
                Text(
                  '暂无课程安排',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '点击右上角 + 添加课程',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 12, color: Colors.white.withValues(alpha: 0.9)),
                          const SizedBox(width: 4),
                          Text(
                            countdown != null && !countdown.isNegative
                                ? '距离上课'
                                : '正在上课',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (countdown != null && !countdown.isNegative)
                  Text(
                    _formatDuration(countdown),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _infoChip(Icons.person_outline_rounded, course.teacher),
                          const SizedBox(width: 16),
                          _infoChip(Icons.location_on_outlined, course.classroom),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _infoChip(Icons.calendar_today_rounded,
                              '${course.weekdayName} ${course.startTime}-${course.endTime}'),
                          const SizedBox(width: 16),
                          _infoChip(Icons.date_range_rounded,
                              '第${course.startWeek}-${course.endWeek}周'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ── 星期选择器 ──
  Widget _buildWeekdaySelector(ThemeData theme, bool isDark) {
    final today = DateTime.now().weekday;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: List.generate(7, (i) {
          final wd = i + 1;
          final selected = _selectedWeekday == wd;
          final isToday = wd == today;
          final hasCourse = _allCourses.any((c) => c.weekday == wd);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedWeekday = wd),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      _weekdayNames[wd],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected
                            ? Colors.white
                            : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? Colors.white.withValues(alpha: 0.8)
                            : isToday
                                ? theme.colorScheme.primary
                                : hasCourse
                                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                                    : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── 解析后的课程卡片（含调课状态） ──
  Widget _buildResolvedCourseCard(ResolvedCourse rc, ThemeData theme, bool isDark) {
    final course = rc.course;
    final color = course.color != null
        ? Color(int.parse(course.color!.replaceFirst('#', '0xFF')))
        : theme.colorScheme.primary;

    // 被取消的课程 - 灰色删除线
    if (rc.isCancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: Colors.grey, width: 4)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Column(
                children: [
                  Text(course.startTime,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough)),
                  Container(width: 1, height: 16, color: Colors.grey.withValues(alpha: 0.3),
                      margin: const EdgeInsets.symmetric(vertical: 4)),
                  Text(course.endTime,
                      style: TextStyle(fontSize: 13, color: Colors.grey,
                          decoration: TextDecoration.lineThrough)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(course.name,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('停课',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444))),
                      ),
                    ],
                  ),
                  if (rc.overrideReason != null) ...[
                    const SizedBox(height: 4),
                    Text(rc.overrideReason!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 被调走的课程 - 不显示（movedAway）
    if (rc.status == ResolvedStatus.movedAway) {
      return const SizedBox.shrink();
    }

    // 正常 / 调来 / 加课
    final isAdjusted = rc.isAdjusted;
    final statusLabel = rc.status == ResolvedStatus.movedHere
        ? '调课'
        : rc.status == ResolvedStatus.added
            ? '加课'
            : null;
    final statusColor = rc.status == ResolvedStatus.movedHere
        ? const Color(0xFFF59E0B)
        : rc.status == ResolvedStatus.added
            ? const Color(0xFF10B981)
            : null;

    return GestureDetector(
      onTap: rc.status == ResolvedStatus.normal
          ? () => _navigateToEdit(course: course)
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: isAdjusted ? statusColor! : color,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Column(
                children: [
                  Text(course.startTime,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: isAdjusted ? statusColor : color)),
                  Container(
                    width: 1, height: 16,
                    color: (isAdjusted ? statusColor : color)?.withValues(alpha: 0.3),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  Text(course.endTime,
                      style: TextStyle(fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(course.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      if (statusLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor!.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(statusLabel,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: statusColor)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (course.teacher.isNotEmpty) ...[
                        Icon(Icons.person_outline_rounded, size: 14,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(course.teacher,
                            style: TextStyle(fontSize: 13,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                        const SizedBox(width: 14),
                      ],
                      if (course.classroom.isNotEmpty) ...[
                        Icon(Icons.location_on_outlined, size: 14,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(course.classroom,
                            style: TextStyle(fontSize: 13,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                      ],
                    ],
                  ),
                  if (rc.overrideReason != null) ...[
                    const SizedBox(height: 4),
                    Text(rc.overrideReason!,
                        style: TextStyle(fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4))),
                  ],
                ],
              ),
            ),
            if (rc.status == ResolvedStatus.normal)
              Icon(Icons.arrow_forward_ios_rounded, size: 14,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  // ── 空状态 ──
  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.school_rounded,
                  size: 36, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            const Text('还没有课程',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('点击右上角 + 手动添加课程',
                style: TextStyle(fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCourseDay(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.wb_sunny_outlined,
                size: 40, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              '${_weekdayNames[_selectedWeekday]}没有课',
              style: TextStyle(fontSize: 15,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}