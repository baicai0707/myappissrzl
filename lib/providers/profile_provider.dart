import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class ProfileProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  String _name;
  String? _avatarPath;
  int _points;
  String? _lastCheckInDate;
  final Map<String, int> _checkInHistory;

  ProfileProvider(this._prefs)
      : _name = _prefs.getString('userName') ?? '点击编辑昵称',
        _avatarPath = _prefs.getString('avatarPath'),
        _points = _prefs.getInt('userPoints') ?? 0,
        _lastCheckInDate = _prefs.getString('lastCheckInDate'),
        _checkInHistory =
            _parseHistory(_prefs.getString('checkInHistory'));

  static Map<String, int> _parseHistory(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map) {
        return decoded
            .map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
    } catch (_) {}
    return {};
  }

  // ---------- 基础信息 ----------

  String get name => _name;
  String? get avatarPath => _avatarPath;

  void updateName(String name) {
    _name = name;
    _prefs.setString('userName', name);
    notifyListeners();
  }

  void updateAvatar(String? path) {
    _avatarPath = path;
    if (path != null) {
      _prefs.setString('avatarPath', path);
    } else {
      _prefs.remove('avatarPath');
    }
    notifyListeners();
  }

  // ---------- 积分与等级 ----------

  int get points => _points;
  Map<String, int> get checkInHistory => _checkInHistory;

  bool get canCheckInToday {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _lastCheckInDate != today;
  }

  LevelInfo get currentLevel {
    for (int i = levels.length - 1; i >= 0; i--) {
      if (_points >= levels[i].requiredPoints) return levels[i];
    }
    return levels.first;
  }

  double get levelProgress {
    final cur = currentLevel;
    final idx = levels.indexOf(cur);
    if (idx >= levels.length - 1) return 1.0;
    final next = levels[idx + 1];
    final range = next.requiredPoints - cur.requiredPoints;
    return (_points - cur.requiredPoints) / range;
  }

  int get pointsToNextLevel {
    final cur = currentLevel;
    final idx = levels.indexOf(cur);
    if (idx >= levels.length - 1) return 0;
    return levels[idx + 1].requiredPoints - _points;
  }

  int get consecutiveDays {
    if (_lastCheckInDate == null) return 0;
    int count = 0;
    var date = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(date);
    if (!_checkInHistory.containsKey(todayStr)) {
      date = date.subtract(const Duration(days: 1));
    }
    while (true) {
      final ds = DateFormat('yyyy-MM-dd').format(date);
      if (_checkInHistory.containsKey(ds)) {
        count++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return count;
  }

  int get monthlyCheckInCount {
    final now = DateTime.now();
    int count = 0;
    _checkInHistory.forEach((key, _) {
      final d = DateTime.tryParse(key);
      if (d != null && d.year == now.year && d.month == now.month) {
        count++;
      }
    });
    return count;
  }

  static final _random = Random();

  static int _generatePoints() {
    final roll = _random.nextInt(100);
    var cumulative = 0;
    for (var i = 0; i < checkInWeights.length; i++) {
      cumulative += checkInWeights[i + 1]!;
      if (roll < cumulative) return i + 1;
    }
    return 5;
  }

  /// 签到，返回获得的积分；如果今天已签到返回 -1
  int checkIn() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_lastCheckInDate == today) return -1;

    final earned = _generatePoints();
    _points += earned;
    _lastCheckInDate = today;
    _checkInHistory[today] = earned;

    _prefs.setInt('userPoints', _points);
    _prefs.setString('lastCheckInDate', today);
    _prefs.setString('checkInHistory', jsonEncode(_checkInHistory));

    notifyListeners();
    return earned;
  }
}
