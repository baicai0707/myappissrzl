class Course {
  final int? id;
  final String name;        // 课程名称
  final String teacher;     // 教师
  final String classroom;   // 教室
  final int weekday;        // 星期几 1-7 (周一到周日)
  final String startTime;   // 开始时间 "08:00"
  final String endTime;     // 结束时间 "09:40"
  final int startWeek;      // 起始周
  final int endWeek;        // 结束周
  final String? color;      // 颜色标识

  Course({
    this.id,
    required this.name,
    required this.teacher,
    required this.classroom,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.startWeek = 1,
    this.endWeek = 20,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
      'classroom': classroom,
      'weekday': weekday,
      'startTime': startTime,
      'endTime': endTime,
      'startWeek': startWeek,
      'endWeek': endWeek,
      'color': color,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as int?,
      name: map['name'] as String,
      teacher: map['teacher'] as String? ?? '',
      classroom: map['classroom'] as String? ?? '',
      weekday: map['weekday'] as int,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      startWeek: map['startWeek'] as int? ?? 1,
      endWeek: map['endWeek'] as int? ?? 20,
      color: map['color'] as String?,
    );
  }

  Course copyWith({
    int? id,
    String? name,
    String? teacher,
    String? classroom,
    int? weekday,
    String? startTime,
    String? endTime,
    int? startWeek,
    int? endWeek,
    String? color,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      classroom: classroom ?? this.classroom,
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startWeek: startWeek ?? this.startWeek,
      endWeek: endWeek ?? this.endWeek,
      color: color ?? this.color,
    );
  }

  /// 获取开始时间的小时和分钟
  (int hour, int minute) get startParsed {
    final parts = startTime.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }

  /// 获取结束时间的小时和分钟
  (int hour, int minute) get endParsed {
    final parts = endTime.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }

  /// 获取星期几的中文名
  String get weekdayName {
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekday >= 1 && weekday <= 7 ? names[weekday] : '';
  }
}