/// 课程临时调整记录
/// 用于处理调课、停课、补课等场景
class CourseOverride {
  final int? id;
  final int? courseId;       // 关联的课程ID，null 表示临时加课
  final String date;         // 调整日期 "2025-05-01"
  final String type;         // "cancel" | "move" | "add"
  // 以下字段仅 move/add 类型使用
  final String? newName;
  final String? newTeacher;
  final String? newClassroom;
  final int? newWeekday;
  final String? newStartTime;
  final String? newEndTime;
  final String? reason;      // 调整原因

  CourseOverride({
    this.id,
    this.courseId,
    required this.date,
    required this.type,
    this.newName,
    this.newTeacher,
    this.newClassroom,
    this.newWeekday,
    this.newStartTime,
    this.newEndTime,
    this.reason,
  });

  bool get isCancel => type == 'cancel';
  bool get isMove => type == 'move';
  bool get isAdd => type == 'add';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'date': date,
      'type': type,
      'newName': newName,
      'newTeacher': newTeacher,
      'newClassroom': newClassroom,
      'newWeekday': newWeekday,
      'newStartTime': newStartTime,
      'newEndTime': newEndTime,
      'reason': reason,
    };
  }

  factory CourseOverride.fromMap(Map<String, dynamic> map) {
    return CourseOverride(
      id: map['id'] as int?,
      courseId: map['courseId'] as int?,
      date: map['date'] as String,
      type: map['type'] as String,
      newName: map['newName'] as String?,
      newTeacher: map['newTeacher'] as String?,
      newClassroom: map['newClassroom'] as String?,
      newWeekday: map['newWeekday'] as int?,
      newStartTime: map['newStartTime'] as String?,
      newEndTime: map['newEndTime'] as String?,
      reason: map['reason'] as String?,
    );
  }
}