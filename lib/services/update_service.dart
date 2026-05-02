import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 应用版本信息（从 CloudBase 云函数获取）
class AppVersionInfo {
  final String version;       // 如 "2.3.0"
  final int buildNumber;      // 如 2
  final String? downloadUrl;  // APK 下载链接
  final String? changelog;    // 更新日志
  final bool forceUpdate;     // 是否强制更新

  AppVersionInfo({
    required this.version,
    required this.buildNumber,
    this.downloadUrl,
    this.changelog,
    this.forceUpdate = false,
  });

  factory AppVersionInfo.fromMap(Map<String, dynamic> map) {
    return AppVersionInfo(
      version: map['version'] as String? ?? '',
      buildNumber: map['buildNumber'] as int? ?? 0,
      downloadUrl: map['downloadUrl'] as String?,
      changelog: map['changelog'] as String?,
      forceUpdate: map['forceUpdate'] as bool? ?? false,
    );
  }
}

class UpdateService {
  /// CloudBase HTTP 云函数地址
  static const String _versionCheckUrl =
      'https://myapp-test-d0g4a6ezn14fde947-1427766726.ap-shanghai.app.tcloudbase.com/getLatestVersion';

  /// 检查是否有新版本
  ///
  /// 调用 CloudBase HTTP 云函数获取最新版本信息，
  /// 与当前 App 版本比较，如果有新版本则返回 [AppVersionInfo]，否则返回 null。
  Future<AppVersionInfo?> checkForUpdate() async {
    try {
      // 获取当前应用版本
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      debugPrint('当前版本: $currentVersion+$currentBuildNumber');

      // 调用 CloudBase HTTP 云函数获取最新版本
      final response = await http.get(
        Uri.parse(_versionCheckUrl),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('请求版本信息失败: ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body);

      // 云函数返回格式可能是直接的对象，也可能是 { data: {...} } 包装
      Map<String, dynamic> versionData;
      if (json is Map<String, dynamic>) {
        if (json.containsKey('data')) {
          final data = json['data'];
          if (data is Map<String, dynamic>) {
            versionData = data;
          } else if (data is List && data.isNotEmpty) {
            versionData = Map<String, dynamic>.from(data[0] as Map);
          } else {
            debugPrint('版本数据格式异常: $json');
            return null;
          }
        } else {
          // 直接返回对象格式
          versionData = json;
        }
      } else {
        debugPrint('版本数据格式异常: $json');
        return null;
      }

      final latestVersion = AppVersionInfo.fromMap(versionData);

      debugPrint('最新版本: ${latestVersion.version}+${latestVersion.buildNumber}');

      // 比较版本号
      if (latestVersion.buildNumber > currentBuildNumber) {
        debugPrint('发现新版本: ${latestVersion.version}');
        return latestVersion;
      }

      debugPrint('已是最新版本');
      return null;
    } catch (e) {
      debugPrint('检查更新失败: $e');
      return null;
    }
  }

  /// 打开下载链接
  Future<bool> downloadUpdate(String url) async {
    try {
      final uri = Uri.parse(url);
      // 直接尝试打开，canLaunchUrl 在某些设备/模拟器上不可靠
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('无法打开链接: $url');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('打开下载链接失败: $e');
      return false;
    }
  }

  /// 获取当前平台类型（用于选择下载链接）
  String get platform {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}

final updateService = UpdateService();