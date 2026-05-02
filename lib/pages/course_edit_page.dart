import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/course_service.dart';

class CourseEditPage extends StatefulWidget {
  final Course? course; // null = 新增模式

  const CourseEditPage({super.key, this.course});

  @override
  State<CourseEditPage> createState() => _CourseEditPageState();
}

class _CourseEditPageState extends State<CourseEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _teacherCtrl;
  late TextEditingController _classroomCtrl;
  late TextEditingController _startWeekCtrl;
  late TextEditingController _endWeekCtrl;
  int _weekday = 1;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 40);
  String _selectedColor = '#4361EE';

  bool get isEditing => widget.course != null;

  static const _colorOptions = [
    '#4361EE', '#10B981', '#F59E0B', '#EF4444',
    '#8B5CF6', '#EC4899', '#06B6D4', '#F97316',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _teacherCtrl = TextEditingController(text: c?.teacher ?? '');
    _classroomCtrl = TextEditingController(text: c?.classroom ?? '');
    _startWeekCtrl = TextEditingController(text: '${c?.startWeek ?? 1}');
    _endWeekCtrl = TextEditingController(text: '${c?.endWeek ?? 20}');
    if (c != null) {
      _weekday = c.weekday;
      final (sh, sm) = c.startParsed;
      final (eh, em) = c.endParsed;
      _startTime = TimeOfDay(hour: sh, minute: sm);
      _endTime = TimeOfDay(hour: eh, minute: em);
      _selectedColor = c.color ?? '#4361EE';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _teacherCtrl.dispose();
    _classroomCtrl.dispose();
    _startWeekCtrl.dispose();
    _endWeekCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
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
    if (!_formKey.currentState!.validate()) return;

    final course = Course(
      id: widget.course?.id,
      name: _nameCtrl.text.trim(),
      teacher: _teacherCtrl.text.trim(),
      classroom: _classroomCtrl.text.trim(),
      weekday: _weekday,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      startWeek: int.tryParse(_startWeekCtrl.text) ?? 1,
      endWeek: int.tryParse(_endWeekCtrl.text) ?? 20,
      color: _selectedColor,
    );

    if (isEditing) {
      await courseService.updateCourse(course);
    } else {
      await courseService.insertCourse(course);
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定要删除「${_nameCtrl.text}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && widget.course?.id != null) {
      await courseService.deleteCourse(widget.course!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑课程' : '添加课程'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 课程名称
            _buildLabel('课程名称', theme),
            const SizedBox(height: 8),
            _buildTextField(_nameCtrl, '例如：高等数学', theme, isDark,
                validator: (v) => v == null || v.trim().isEmpty ? '请输入课程名称' : null),
            const SizedBox(height: 20),

            // 教师
            _buildLabel('授课教师', theme),
            const SizedBox(height: 8),
            _buildTextField(_teacherCtrl, '例如：张老师', theme, isDark),
            const SizedBox(height: 20),

            // 教室
            _buildLabel('上课教室', theme),
            const SizedBox(height: 8),
            _buildTextField(_classroomCtrl, '例如：教学楼A301', theme, isDark),
            const SizedBox(height: 20),

            // 星期
            _buildLabel('上课星期', theme),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: List.generate(7, (i) {
                  final wd = i + 1;
                  final selected = _weekday == wd;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _weekday = wd),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          weekdays[wd],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? Colors.white : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // 时间
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('开始时间', theme),
                      const SizedBox(height: 8),
                      _buildTimeButton(_formatTime(_startTime), () => _pickTime(true), theme, isDark),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('结束时间', theme),
                      const SizedBox(height: 8),
                      _buildTimeButton(_formatTime(_endTime), () => _pickTime(false), theme, isDark),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 周数
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('起始周', theme),
                      const SizedBox(height: 8),
                      _buildTextField(_startWeekCtrl, '1', theme, isDark, isNumber: true),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Text(' — ', style: TextStyle(fontSize: 18)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('结束周', theme),
                      const SizedBox(height: 8),
                      _buildTextField(_endWeekCtrl, '20', theme, isDark, isNumber: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 颜色
            _buildLabel('颜色标识', theme),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorOptions.map((hex) {
                final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                final selected = _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: theme.colorScheme.primary, width: 3)
                          : null,
                      boxShadow: selected
                          ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // 保存按钮
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
                child: Text(isEditing ? '保存修改' : '添加课程',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Text(text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
        ));
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint,
    ThemeData theme,
    bool isDark, {
    String? Function(String?)? validator,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildTimeButton(String time, VoidCallback onTap, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time_rounded, size: 18,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}