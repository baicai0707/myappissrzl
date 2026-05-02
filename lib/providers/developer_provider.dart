import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeveloperProvider extends ChangeNotifier {
  bool _isDeveloperMode = false;
  int _tapCount = 0;
  DateTime? _lastTapTime;

  bool get isDeveloperMode => _isDeveloperMode;

  DeveloperProvider(SharedPreferences prefs) {
    _isDeveloperMode = prefs.getBool('developerMode') ?? false;
  }

  /// 连续快速点击5次激活开发者模式
  /// 返回 true 表示刚激活了开发者模式
  bool handleSecretTap() {
    final now = DateTime.now();

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds > 1500) {
      _tapCount = 0;
    }

    _lastTapTime = now;
    _tapCount++;

    if (_tapCount >= 5) {
      _tapCount = 0;
      if (!_isDeveloperMode) {
        _isDeveloperMode = true;
        _saveToPrefs(true);
        notifyListeners();
        return true;
      }
    }

    return false;
  }

  void disableDeveloperMode() {
    _isDeveloperMode = false;
    _saveToPrefs(false);
    notifyListeners();
  }

  Future<void> _saveToPrefs(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('developerMode', value);
  }
}