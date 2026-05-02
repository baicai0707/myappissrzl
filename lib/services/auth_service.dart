import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _uidKey = 'local_user_uid';

  String? _uid;

  String? get uid => _uid;
  bool get isLoggedIn => _uid != null;

  /// 初始化：从本地缓存恢复或生成新的唯一用户标识
  Future<bool> init() async {
    _uid = await _storage.read(key: _uidKey);

    if (_uid != null) {
      debugPrint('已恢复用户标识: $_uid');
      return true;
    }

    // 生成新的唯一用户标识
    return await _generateUid();
  }

  /// 生成本地唯一用户标识
  Future<bool> _generateUid() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 31 % 999999).toString().padLeft(6, '0');
    _uid = 'user_${timestamp}_$random';

    await _storage.write(key: _uidKey, value: _uid);
    debugPrint('生成新用户标识: $_uid');
    return true;
  }

  /// 清除登录状态
  Future<void> signOut() async {
    _uid = null;
    await _storage.delete(key: _uidKey);
  }
}

final authService = AuthService();
