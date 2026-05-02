import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class LeaderboardEntry {
  final String uid;
  final String nickname;
  final int points;
  final int level;
  final String? avatarUrl;
  final DateTime? updatedAt;

  LeaderboardEntry({
    required this.uid,
    required this.nickname,
    required this.points,
    required this.level,
    this.avatarUrl,
    this.updatedAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      uid: json['openid']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '匿名用户',
      points: (json['score'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      avatarUrl: json['avatar_url']?.toString(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}

class LeaderboardService {
  // 云函数HTTP访问地址
  static const String _baseUrl =
      'https://service-myapp-test-d0g4a6ezn14fde947-1427766726.ap-shanghai.apigateway.myqcloud.com/release/leaderboard-http';

  /// 调用云函数的通用方法
  Future<dynamic> _callCloudFunction(String action,
      {Map<String, dynamic>? data}) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': action,
          'data': data ?? {},
        }),
      );

      debugPrint('云函数 $action 响应: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['code'] == 0) {
          return result['data'];
        }
        debugPrint('云函数返回错误: ${result['message']}');
      }
      return null;
    } catch (e) {
      debugPrint('云函数 $action 调用异常: $e');
      return null;
    }
  }

  /// 同步当前用户的积分到云端
  Future<bool> syncPoints({
    required String nickname,
    required int points,
    required int level,
  }) async {
    if (!authService.isLoggedIn) {
      debugPrint('未登录，无法同步积分');
      return false;
    }

    final uid = authService.uid!;

    try {
      final result = await _callCloudFunction('updateScore', data: {
        'openid': uid,
        'nickname': nickname,
        'score': points,
        'level': level,
      });

      debugPrint('同步积分结果: $result');
      return result != null;
    } catch (e) {
      debugPrint('同步积分异常: $e');
      return false;
    }
  }

  /// 获取排行榜（按积分降序）
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 100}) async {
    try {
      final result = await _callCloudFunction('getRanking', data: {
        'limit': limit,
      });

      debugPrint('获取排行榜结果: $result');

      if (result != null && result is List) {
        return result
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('获取排行榜异常: $e');
    }

    return [];
  }

  /// 获取当前用户的排名
  Future<int?> getMyRank() async {
    if (!authService.isLoggedIn) return null;

    try {
      final uid = authService.uid!;
      final result = await _callCloudFunction('getUserRank', data: {
        'openid': uid,
      });

      debugPrint('查询用户排名结果: $result');

      if (result != null && result is Map) {
        return (result['rank'] as num?)?.toInt();
      }
    } catch (e) {
      debugPrint('获取排名异常: $e');
    }

    return null;
  }
}

final leaderboardService = LeaderboardService();