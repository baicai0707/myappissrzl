import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/course.dart';
import '../models/course_override.dart';

class CourseService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'courses.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createOverrideTable(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        teacher TEXT DEFAULT '',
        classroom TEXT DEFAULT '',
        weekday INTEGER NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        startWeek INTEGER DEFAULT 1,
        endWeek INTEGER DEFAULT 20,
        color TEXT
      )
    ''');
    await _createOverrideTable(db);
  }

  Future<void> _createOverrideTable(Database db) async {
    await db.execute('''
      CREATE TABLE course_overrides (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseId INTEGER,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        newName TEXT,
        newTeacher TEXT,
        newClassroom TEXT,
        newWeekday INTEGER,
        newStartTime TEXT,
        newEndTime TEXT,
        reason TEXT,
        FOREIGN KEY (courseId) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── 课程 CRUD ──

  Future<List<Course>> getAllCourses() async {
    final db = await database;
    final maps = await db.query('courses', orderBy: 'weekday ASC, startTime ASC');
    return maps.map((m) => Course.fromMap(m)).toList();
  }

  Future<List<Course>> getCoursesByWeekday(int weekday) async {
    final db = await database;
    final maps = await db.query(
      'courses',
      where: 'weekday = ?',
      whereArgs: [weekday],
      orderBy: 'startTime ASC',
    );
    return maps.map((m) => Course.fromMap(m)).toList();
  }

  Future<int> insertCourse(Course course) async {
    final db = await database;
    return db.insert('courses', course.toMap()..remove('id'));
  }

  Future<int> updateCourse(Course course) async {
    final db = await database;
    return db.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<int> deleteCourse(int id) async {
    final db = await database;
    // 同时删除关联的调整记录
    await db.delete('course_overrides', where: 'courseId = ?', whereArgs: [id]);
    return db.delete('courses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('course_overrides');
    await db.delete('courses');
  }

  Future<void> insertCourses(List<Course> courses) async {
    final db = await database;
    final batch = db.batch();
    for (final course in courses) {
      batch.insert('courses', course.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  // ── 调整记录 CRUD ──

  Future<List<CourseOverride>> getAllOverrides() async {
    final db = await database;
    final maps = await db.query('course_overrides', orderBy: 'date DESC');
    return maps.map((m) => CourseOverride.fromMap(m)).toList();
  }

  Future<List<CourseOverride>> getOverridesForDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'course_overrides',
      where: 'date = ?',
      whereArgs: [date],
    );
    return maps.map((m) => CourseOverride.fromMap(m)).toList();
  }

  Future<int> insertOverride(CourseOverride override) async {
    final db = await database;
    return db.insert('course_overrides', override.toMap()..remove('id'));
  }

  Future<int> deleteOverride(int id) async {
    final db = await database;
    return db.delete('course_overrides', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllOverrides() async {
    final db = await database;
    await db.delete('course_overrides');
  }

  // ── 核心逻辑：获取某天的实际课程（含调整） ──

  /// 获取指定日期的实际课程列表（已应用调课/停课/加课）
  List<ResolvedCourse> getResolvedCoursesForDate(
    List<Course> allCourses,
    List<CourseOverride> allOverrides,
    DateTime date,
  ) {
    final dateStr = _formatDate(date);
    final weekday = date.weekday;
    final dayOverrides = allOverrides.where((o) => o.date == dateStr).toList();

    // 被取消的课程ID
    final cancelledIds = dayOverrides
        .where((o) => o.isCancel)
        .map((o) => o.courseId)
        .toSet();

    // 被调走的课程ID（当天不在原位置上）
    final movedAwayIds = dayOverrides
        .where((o) => o.isMove)
        .map((o) => o.courseId)
        .toSet();

    final result = <ResolvedCourse>[];

    // 1. 当天正常课程（排除被取消和被调走的）
    final normalCourses = allCourses.where((c) => c.weekday == weekday).toList();
    for (final course in normalCourses) {
      if (cancelledIds.contains(course.id)) {
        // 标记为已取消
        result.add(ResolvedCourse(
          course: course,
          status: ResolvedStatus.cancelled,
          overrideReason: dayOverrides
              .firstWhere((o) => o.courseId == course.id && o.isCancel)
              .reason,
        ));
      } else if (movedAwayIds.contains(course.id)) {
        // 不显示在原位置（会在目标位置显示）
        final moveOverride = dayOverrides
            .firstWhere((o) => o.courseId == course.id && o.isMove);
        result.add(ResolvedCourse(
          course: course,
          status: ResolvedStatus.movedAway,
          overrideReason: moveOverride.reason,
        ));
      } else {
        result.add(ResolvedCourse(course: course, status: ResolvedStatus.normal));
      }
    }

    // 2. 调课到今天的课程（从其他天调过来的）
    final moveOverrides = dayOverrides.where((o) => o.isMove).toList();
    for (final ov in moveOverrides) {
      final original = allCourses.where((c) => c.id == ov.courseId).toList();
      final originalCourse = original.isNotEmpty ? original.first : null;
      result.add(ResolvedCourse(
        course: Course(
          name: ov.newName ?? originalCourse?.name ?? '调课',
          teacher: ov.newTeacher ?? originalCourse?.teacher ?? '',
          classroom: ov.newClassroom ?? originalCourse?.classroom ?? '',
          weekday: weekday,
          startTime: ov.newStartTime ?? originalCourse?.startTime ?? '08:00',
          endTime: ov.newEndTime ?? originalCourse?.endTime ?? '09:40',
          color: originalCourse?.color,
        ),
        status: ResolvedStatus.movedHere,
        overrideReason: ov.reason,
        originalCourse: originalCourse,
      ));
    }

    // 3. 临时加课
    final addOverrides = dayOverrides.where((o) => o.isAdd).toList();
    for (final ov in addOverrides) {
      result.add(ResolvedCourse(
        course: Course(
          name: ov.newName ?? '临时加课',
          teacher: ov.newTeacher ?? '',
          classroom: ov.newClassroom ?? '',
          weekday: weekday,
          startTime: ov.newStartTime ?? '08:00',
          endTime: ov.newEndTime ?? '09:40',
        ),
        status: ResolvedStatus.added,
        overrideReason: ov.reason,
      ));
    }

    // 按时间排序
    result.sort((a, b) => a.course.startTime.compareTo(b.course.startTime));
    return result;
  }

  /// 获取今天及之后最近的一节课（考虑调课）
  Course? getNextCourse(List<Course> allCourses, {DateTime? now, List<CourseOverride>? overrides}) {
    now ??= DateTime.now();
    overrides ??= [];

    // 检查未来7天
    for (int dayOffset = 0; dayOffset <= 7; dayOffset++) {
      final targetDate = DateTime(now.year, now.month, now.day + dayOffset);
      final resolved = getResolvedCoursesForDate(allCourses, overrides, targetDate);

      for (final rc in resolved) {
        if (rc.status == ResolvedStatus.cancelled || rc.status == ResolvedStatus.movedAway) {
          continue;
        }
        final (h, m) = rc.course.startParsed;
        final courseDateTime = DateTime(targetDate.year, targetDate.month, targetDate.day, h, m);
        if (courseDateTime.isAfter(now)) {
          return rc.course;
        }
      }
    }
    return null;
  }

  /// 计算到下一节课的倒计时
  Duration? getCountdown(Course course, {DateTime? now}) {
    now ??= DateTime.now();
    final (h, m) = course.startParsed;

    final currentWeekday = now.weekday;
    int daysUntil = course.weekday - currentWeekday;
    if (daysUntil < 0) daysUntil += 7;

    final target = DateTime(
      now.year, now.month, now.day + daysUntil, h, m,
    );

    final diff = target.difference(now);
    if (diff.isNegative) return null;
    return diff;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 课程解析状态
enum ResolvedStatus {
  normal,      // 正常上课
  cancelled,   // 已停课
  movedAway,   // 已调走（不在原位置显示）
  movedHere,   // 从别处调来
  added,       // 临时加课
}

/// 解析后的课程（含调整信息）
class ResolvedCourse {
  final Course course;
  final ResolvedStatus status;
  final String? overrideReason;
  final Course? originalCourse;

  ResolvedCourse({
    required this.course,
    this.status = ResolvedStatus.normal,
    this.overrideReason,
    this.originalCourse,
  });

  bool get isCancelled => status == ResolvedStatus.cancelled;
  bool get isAdjusted => status != ResolvedStatus.normal;
}

final courseService = CourseService();