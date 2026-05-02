import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudBaseClient {
  late String envId;
  late String accessToken;
  late String baseUrl;
  late Map<String, String> headers;

  CloudBaseClient() {
    envId = dotenv.env['CLOUDBASE_ENV_ID'] ?? '';
    accessToken = dotenv.env['CLOUDBASE_ACCESS_TOKEN'] ?? '';
    baseUrl = 'https://$envId.api.tcloudbasegateway.com';
    headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  /// 更新访问令牌
  ///
  /// [newToken] 新的访问令牌
  void updateAccessToken(String newToken) {
    accessToken = newToken;
    headers['Authorization'] = 'Bearer $newToken';
    debugPrint('访问令牌已更新');
  }

  /// 统一的HTTP请求方法
  ///
  /// [method] 请求方法 (GET, POST, PUT, PATCH, DELETE)
  /// [path] API路径 (如 /v1/rdb/rest/table_name)
  /// [body] 请求体数据
  /// [customHeaders] 自定义headers
  ///
  /// 返回响应数据或null
  Future<dynamic> request(
    String method,
    String path, {
    dynamic body,
    Map<String, String>? customHeaders,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final requestHeaders = Map<String, String>.from(headers);

    if (customHeaders != null) {
      requestHeaders.addAll(customHeaders);
    }

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: requestHeaders);
          break;
        default:
          throw Exception('不支持的HTTP方法: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return true;
        }
        return jsonDecode(response.body);
      } else {
        debugPrint('请求失败: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('请求失败: $e');
      return null;
    }
  }
}

final cloudbase = CloudBaseClient();