import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/course_override.dart';
import '../services/course_service.dart';
import '../widgets/custom_toast.dart';

class CourseOverridePage extends StatefulWidget {
  const CourseOverridePage({super.key});

  @override
  State<CourseOverridePage> createState() => _CourseOverridePageState();
}

class _CourseOverridePageState extends State<CourseOverridePage> {
  List<Course> _courses = [];
  List<CourseOverride> _overrides = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final courses = await courseService.getAllCourses();
    final overrides = await courseService.getAllOverrides();
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _overrides = overrides;
      _loading = false;
    });
  }

  String _formatDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      return '${parts[0]}年${int.parse(parts[1])}月${int.parse(parts[2])}日';
    }
    return dateStr;
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'cancel': return '停课';
      case 'move': return '调课';
      case 'add': return '加课';
      default: return type;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'cancel': return const Color(0xFFEF4444);
      case 'move': return const Color(0xFFF59E0B);
      case 'add': return const Color(0xFF10B981);
      default: return const Color(0xFF6B7280);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'cancel': return Icons.cancel_outlined;
      case 'move': return Icons.swap_horiz_rounded;
      case 'add': return Icons.add_circle_outline_rounded;
      default: return Icons.help_outline;
    }
  }

  Future<void> _showAddOverrideSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddOverrideSheet(courses: _courses),
    );
    if (result == true) _loadData();
  }

  Future<void> _deleteOverride(CourseOverride ov) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除调整记录'),
        content: const Text('确定要删除这条调整记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await courseService.deleteOverride(ov.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('调课管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: '添加调整',
            onPressed: _courses.isEmpty ? null : _showAddOverrideSheet,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? _buildNoCourses(theme)
              : _overrides.isEmpty
                  ? _buildEmpty(theme)
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        itemCount: _overrides.length,
                        itemBuilder: (ctx, i) => _buildOverrideCard(_overrides[i], theme, isDark),
                      ),
                    ),
      floatingActionButton: _courses.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddOverrideSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加调整'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
    );
  }

  Widget _buildNoCourses(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 60,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('还没有课程', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('请先添加课程，再来管理调课', style: TextStyle(
              fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline_rounded,
                size: 36, color: const Color(0xFF10B981).withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          const Text('暂无调课记录', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('点击下方按钮添加停课、调课或加课', style: TextStyle(
              fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildOverrideCard(CourseOverride ov, ThemeData theme, bool isDark) {
    final color = _getTypeColor(ov.type);
    final courseName = ov.courseId != null
        ? _courses.where((c) => c.id == ov.courseId).map((c) => c.name).firstOrNull ?? '已删除课程'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getTypeIcon(ov.type), size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(_getTypeLabel(ov.type),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(_formatDate(ov.date),
                  style: TextStyle(fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
              const Spacer(),
              GestureDetector(
                onTap: () => _deleteOverride(ov),
                child: Icon(Icons.close_rounded, size: 18,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (ov.isCancel) ...[
            Text(courseName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (ov.reason != null && ov.reason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(ov.reason!,
                  style: TextStyle(fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
            ],
          ] else if (ov.isMove) ...[
            Row(
              children: [
                Text(courseName,
                    style: TextStyle(fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4))),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 16,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(ov.newName ?? courseName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (ov.newTeacher != null && ov.newTeacher!.isNotEmpty)
                  _infoTag(Icons.person_outline_rounded, ov.newTeacher!),
                if (ov.newClassroom != null && ov.newClassroom!.isNotEmpty)
                  _infoTag(Icons.location_on_outlined, ov.newClassroom!),
                if (ov.newStartTime != null)
                  _infoTag(Icons.access_time_rounded, '${ov.newStartTime}-${ov.newEndTime}'),
              ],
            ),
            if (ov.reason != null && ov.reason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(ov.reason!,
                  style: TextStyle(fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
            ],
          ] else if (ov.isAdd) ...[
            Text(ov.newName ?? '临时加课',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (ov.newTeacher != null && ov.newTeacher!.isNotEmpty)
                  _infoTag(Icons.person_outline_rounded, ov.newTeacher!),
                if (ov.newClassroom != null && ov.newClassroom!.isNotEmpty)
                  _infoTag(Icons.location_on_outlined, ov.newClassroom!),
                if (ov.newStartTime != null)
                  _infoTag(Icons.access_time_rounded, '${ov.newStartTime}-${ov.newEndTime}'),
              ],
            ),
            if (ov.reason != null && ov.reason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(ov.reason!,
                  style: TextStyle(fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
            ],
          ],
        ],
      ),
    );
  }

  Widget _infoTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

// ── 添加调整的底部弹窗 ──
class _AddOverrideSheet extends StatefulWidget {
  final List<Course> courses;
  const _AddOverrideSheet({required this.courses});

  @override
  State<_AddOverrideSheet> createState() => _AddOverrideSheetState();
}

class _AddOverrideSheetState extends State<_AddOverrideSheet> {
  String _type = 'cancel';
  int? _selectedCourseId;
  DateTime _selectedDate = DateTime.now();
  final _reasonCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _teacherCtrl = TextEditingController();
  final _classroomCtrl = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 40);

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_type != 'add' && _selectedCourseId == null) {
      CustomToast.warning(context, '请选择课程');
      return;
    }

    final ov = CourseOverride(
      courseId: _selectedCourseId,
      date: _formatDate(_selectedDate),
      type: _type,
      newName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : null,
      newTeacher: _teacherCtrl.text.trim().isNotEmpty ? _teacherCtrl.text.trim() : null,
      newClassroom: _classroomCtrl.text.trim().isNotEmpty ? _classroomCtrl.text.trim() : null,
      newStartTime: (_type == 'move' || _type == 'add') ? _formatTime(_startTime) : null,
      newEndTime: (_type == 'move' || _type == 'add') ? _formatTime(_endTime) : null,
      reason: _reasonCtrl.text.trim().isNotEmpty ? _reasonCtrl.text.trim() : null,
    );

    await courseService.insertOverride(ov);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _nameCtrl.dispose();
    _teacherCtrl.dispose();
    _classroomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖拽条
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('添加课程调整',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),

            // 调整类型
            _label('调整类型'),
            const SizedBox(height: 8),
            Row(
              children: [
                _typeChip('cancel', '停课', const Color(0xFFEF4444)),
                const SizedBox(width: 8),
                _typeChip('move', '调课', const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _typeChip('add', '加课', const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 16),

            // 选择课程（加课不需要）
            if (_type != 'add') ...[
              _label('选择课程'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedCourseId,
                    hint: Text('请选择课程',
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3))),
                    items: widget.courses.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.name} (${c.weekdayName} ${c.startTime})'),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedCourseId = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 日期
            _label('日期'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                    const SizedBox(width: 10),
                    Text(_formatDate(_selectedDate),
                        style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 调课/加课的额外字段
            if (_type == 'move' || _type == 'add') ...[
              _label('课程名称（可选，留空则沿用原名）'),
              const SizedBox(height: 8),
              _textField(_nameCtrl, '课程名称', theme, isDark),
              const SizedBox(height: 12),

              _label('教师（可选）'),
              const SizedBox(height: 8),
              _textField(_teacherCtrl, '教师姓名', theme, isDark),
              const SizedBox(height: 12),

              _label('教室（可选）'),
              const SizedBox(height: 8),
              _textField(_classroomCtrl, '教室', theme, isDark),
              const SizedBox(height: 12),

              _label('上课时间'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickTime(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(_formatTime(_startTime),
                            style: const TextStyle(fontSize: 15))),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('—', style: TextStyle(fontSize: 16)),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickTime(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(_formatTime(_endTime),
                            style: const TextStyle(fontSize: 15))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // 原因
            _label('原因（可选）'),
            const SizedBox(height: 8),
            _textField(_reasonCtrl, '例如：老师出差、教室维修...', theme, isDark),
            const SizedBox(height: 24),

            // 保存
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('确认添加', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
        ));
  }

  Widget _typeChip(String type, String label, Color color) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : color,
            )),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint, ThemeData theme, bool isDark) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}