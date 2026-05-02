import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../widgets/custom_toast.dart';

// ============================================================
// 数据模型
// ============================================================

class Note {
  String id;
  String title;
  String content;
  int priority;
  String? reminderTimeIso;
  bool isCompleted;
  String createdAtIso;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.priority = 1,
    this.reminderTimeIso,
    this.isCompleted = false,
    required this.createdAtIso,
  });

  DateTime? get reminderTime =>
      reminderTimeIso != null ? DateTime.tryParse(reminderTimeIso!) : null;
  DateTime get createdAt => DateTime.parse(createdAtIso);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'priority': priority,
        'reminderTimeIso': reminderTimeIso,
        'isCompleted': isCompleted,
        'createdAtIso': createdAtIso,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        priority: (json['priority'] as num?)?.toInt() ?? 1,
        reminderTimeIso: json['reminderTimeIso'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAtIso: json['createdAtIso'] as String? ??
            DateTime.now().toIso8601String(),
      );
}

// ============================================================
// 工具函数
// ============================================================

String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

int _notificationId(String noteId) => noteId.hashCode & 0x7FFFFFFF;

const String _storageKey = 'notepad_notes';

const List<String> _priorityLabels = ['低', '中', '高'];
const List<Color> _priorityColors = [
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
];

const List<IconData> _priorityIcons = [
  Icons.arrow_downward_rounded,
  Icons.remove_rounded,
  Icons.arrow_upward_rounded,
];

/// 安全取消提醒，不会因为通知插件异常而阻塞业务逻辑
Future<void> _safeCancelReminder(String noteId) async {
  try {
    await cancelReminder(_notificationId(noteId));
  } catch (_) {
    // 忽略通知取消失败，不影响删除操作
  }
}

/// 安全安排提醒
Future<void> _safeScheduleReminder(
    String noteId, String title, DateTime reminderTime) async {
  try {
    await scheduleReminder(
      _notificationId(noteId),
      '记事本提醒',
      title,
      reminderTime,
    );
  } catch (_) {
    // 忽略通知安排失败
  }
}

// ============================================================
// 页面
// ============================================================

class NotepadPage extends StatefulWidget {
  const NotepadPage({super.key});

  @override
  State<NotepadPage> createState() => _NotepadPageState();
}

class _NotepadPageState extends State<NotepadPage> {
  List<Note> _notes = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // ---------- 数据操作 ----------

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (!mounted) return;
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final list = jsonDecode(jsonStr) as List;
        setState(() {
          _notes = list
              .map((e) => Note.fromJson(e as Map<String, dynamic>))
              .toList();
          _sortNotes();
        });
      }
    } catch (e) {
      // 加载失败时清空数据，避免旧格式数据导致后续操作全部失败
      if (mounted) {
        setState(() => _notes = []);
      }
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_notes.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  void _sortNotes() {
    _notes.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (!a.isCompleted) {
        if (a.priority != b.priority) {
          return b.priority.compareTo(a.priority);
        }
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  List<Note> get _filteredNotes {
    switch (_filter) {
      case 'active':
        return _notes.where((n) => !n.isCompleted).toList();
      case 'completed':
        return _notes.where((n) => n.isCompleted).toList();
      default:
        return _notes;
    }
  }

  // ---------- 删除单条 ----------

  Future<void> _deleteNote(Note note) async {
    // 先从列表中移除并保存，确保删除一定生效
    _notes.remove(note);
    _sortNotes();
    await _saveNotes();
    if (mounted) {
      setState(() {});
      CustomToast.success(context, '记事已删除');
    }
    // 异步取消通知，不阻塞删除流程
    _safeCancelReminder(note.id);
  }

  // ---------- 添加/编辑 ----------

  void _showNoteSheet({Note? note}) {
    final isEditing = note != null;
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final contentCtrl = TextEditingController(text: note?.content ?? '');
    int selectedPriority = note?.priority ?? 1;
    DateTime? reminderTime = note?.reminderTime;
    bool reminderEnabled = reminderTime != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final sheetTheme = Theme.of(ctx);
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Text(isEditing ? '编辑记事' : '添加记事',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                        labelText: '标题', hintText: '例如：明天开会'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: '内容', hintText: '记录详细内容...'),
                  ),
                  const SizedBox(height: 16),
                  Text('优先级',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(3, (i) {
                      final isSelected = selectedPriority == i;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setModal(() => selectedPriority = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _priorityColors[i]
                                      .withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? _priorityColors[i]
                                    : Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _priorityLabels[i],
                              style: TextStyle(
                                color: isSelected
                                    ? _priorityColors[i]
                                    : null,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.alarm,
                          size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text('提醒',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[600])),
                      const Spacer(),
                      Switch(
                        value: reminderEnabled,
                        onChanged: (v) =>
                            setModal(() => reminderEnabled = v),
                        thumbColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return sheetTheme.colorScheme.primary;
                          }
                          return null;
                        }),
                        trackColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return sheetTheme.colorScheme.primary
                                .withValues(alpha: 0.5);
                          }
                          return null;
                        }),
                      ),
                    ],
                  ),
                  if (reminderEnabled) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        final initialDate = (reminderTime != null &&
                                reminderTime!.isAfter(now))
                            ? reminderTime!
                            : now;
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: initialDate,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (date == null || !ctx.mounted) return;
                        final initialTime = reminderTime != null
                            ? TimeOfDay.fromDateTime(reminderTime!)
                            : TimeOfDay.now();
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: initialTime,
                        );
                        if (time == null) return;
                        setModal(() {
                          reminderTime = DateTime(date.year, date.month,
                              date.day, time.hour, time.minute);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: sheetTheme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 18,
                                color: sheetTheme.colorScheme.primary),
                            const SizedBox(width: 10),
                            Text(
                              reminderTime != null
                                  ? DateFormat('yyyy年M月d日 HH:mm')
                                      .format(reminderTime!)
                                  : '点击选择提醒时间',
                              style: TextStyle(
                                color: reminderTime != null
                                    ? null
                                    : Colors.grey[500],
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right,
                                color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) {
                          CustomToast.warning(ctx, '请输入标题');
                          return;
                        }
                        if (reminderEnabled && reminderTime != null) {
                          final now = DateTime.now();
                          final reminderMinute = DateTime(
                              reminderTime!.year,
                              reminderTime!.month,
                              reminderTime!.day,
                              reminderTime!.hour,
                              reminderTime!.minute);
                          final nowMinute = DateTime(now.year, now.month,
                              now.day, now.hour, now.minute);
                          if (reminderMinute.isBefore(nowMinute)) {
                            CustomToast.warning(ctx, '提醒时间不能早于当前时间');
                            return;
                          }
                        }

                        final navigator = Navigator.of(ctx);

                        try {
                          if (isEditing) {
                            note.title = title;
                            note.content = contentCtrl.text.trim();
                            note.priority = selectedPriority;
                            note.reminderTimeIso = reminderEnabled
                                ? reminderTime?.toIso8601String()
                                : null;

                            // 先取消旧提醒，再安排新提醒
                            _safeCancelReminder(note.id);
                            if (reminderEnabled && reminderTime != null) {
                              await _safeScheduleReminder(
                                  note.id, note.title, reminderTime!);
                            }
                          } else {
                            final newNote = Note(
                              id: _generateId(),
                              title: title,
                              content: contentCtrl.text.trim(),
                              priority: selectedPriority,
                              reminderTimeIso: reminderEnabled
                                  ? reminderTime?.toIso8601String()
                                  : null,
                              createdAtIso:
                                  DateTime.now().toIso8601String(),
                            );
                            _notes.add(newNote);

                            if (reminderEnabled && reminderTime != null) {
                              await _safeScheduleReminder(
                                  newNote.id, newNote.title, reminderTime!);
                            }
                          }

                          _sortNotes();
                          await _saveNotes();
                        } finally {
                          if (mounted) {
                            setState(() {});
                            navigator.pop();
                          }
                        }
                      },
                      child: Text(isEditing ? '保存修改' : '添加记事'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- 一键删除 ----------

  Future<void> _deleteFilteredNotes() async {
    final filtered = List<Note>.from(_filteredNotes);
    if (filtered.isEmpty) return;

    String label;
    switch (_filter) {
      case 'active':
        label = '所有未完成的记事';
        break;
      case 'completed':
        label = '所有已完成的记事';
        break;
      default:
        label = '所有记事';
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空'),
        content: Text('确定要删除$label吗？此操作不可撤销。'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('全部删除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 收集需要取消提醒的 noteId
    final idsToDelete = filtered.map((n) => n.id).toList();

    // 先从列表中移除，确保删除一定生效
    _notes.removeWhere((n) => idsToDelete.contains(n.id));
    _sortNotes();
    await _saveNotes();

    if (mounted) {
      setState(() {});
      CustomToast.success(context, '已清空');
    }

    // 异步批量取消通知，不阻塞删除流程
    for (final id in idsToDelete) {
      _safeCancelReminder(id);
    }
  }

  // ---------- 完成切换 ----------

  Future<void> _toggleComplete(Note note) async {
    note.isCompleted = !note.isCompleted;
    if (note.isCompleted) {
      _safeCancelReminder(note.id);
    }
    _sortNotes();
    await _saveNotes();
    if (mounted) setState(() {});
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredNotes;

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('记事本'),
        actions: [
          if (_notes.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(Icons.delete_sweep_outlined,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                tooltip: '一键清空',
                onPressed: _deleteFilteredNotes,
              ),
            ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showNoteSheet(),
          backgroundColor: theme.colorScheme.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                _filterChip('全部', 'all'),
                const SizedBox(width: 8),
                _filterChip('未完成', 'active'),
                const SizedBox(width: 8),
                _filterChip('已完成', 'completed'),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _buildNoteCard(theme, filtered[index], isDark),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final theme = Theme.of(context);
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? theme.colorScheme.primary : null,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(ThemeData theme, Note note, bool isDark) {
    final priorityColor = _priorityColors[note.priority];
    final hasReminder = note.reminderTime != null;

    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除「${note.title}」吗？'),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style:
                    TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await _deleteNote(note);
          return true;
        }
        return false;
      },
      child: GestureDetector(
        onTap: () => _showNoteSheet(note: note),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
              GestureDetector(
                onTap: () => _toggleComplete(note),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: note.isCompleted
                          ? priorityColor
                          : Colors.grey.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    color: note.isCompleted
                        ? priorityColor
                        : Colors.transparent,
                  ),
                  child: note.isCompleted
                      ? const Icon(Icons.check,
                          size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                              decoration: note.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: note.isCompleted
                                  ? theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.4)
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_priorityIcons[note.priority],
                                  size: 10, color: priorityColor),
                              const SizedBox(width: 3),
                              Text(
                                _priorityLabels[note.priority],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: priorityColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (note.content.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note.content,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(
                                  alpha: note.isCompleted ? 0.3 : 0.5),
                          decoration: note.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (hasReminder) ...[
                          Icon(Icons.alarm,
                              size: 14,
                              color: note.isCompleted
                                  ? Colors.grey.withValues(alpha: 0.3)
                                  : theme.colorScheme.primary
                                      .withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('M月d日 HH:mm')
                                .format(note.reminderTime!),
                            style: TextStyle(
                              fontSize: 11,
                              color: note.isCompleted
                                  ? Colors.grey.withValues(alpha: 0.3)
                                  : theme.colorScheme.primary
                                      .withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          DateFormat('M月d日创建')
                              .format(note.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    String message;
    switch (_filter) {
      case 'active':
        message = '没有未完成的记事';
        break;
      case 'completed':
        message = '没有已完成的记事';
        break;
      default:
        message = '暂无记事';
    }

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
            child: Icon(Icons.note_alt_outlined,
                size: 40,
                color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text(message,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          Text('点击右下角 + 添加记事',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.35))),
        ],
      ),
    );
  }
}