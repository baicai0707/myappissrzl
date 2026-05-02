import 'dart:convert';
import 'package:http/http.dart' as http;

/// 视频解析结果
class VideoParseResult {
  final String platform;
  final String title;
  final String? videoUrl; // 无水印视频链接
  final List<String>? imageUrls; // 图文图片链接
  final String? coverUrl;
  final String? authorName;
  final bool isVideo; // true=视频, false=图文

  VideoParseResult({
    required this.platform,
    required this.title,
    this.videoUrl,
    this.imageUrls,
    this.coverUrl,
    this.authorName,
    this.isVideo = true,
  });
}

/// 视频解析服务 - 支持多平台无水印解析
class VideoParserService {
  static const _userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) '
      'Version/16.0 Mobile/15E148 Safari/604.1';

  static final Map<String, String> _headers = {
    'User-Agent': _userAgent,
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
  };

  /// 解析分享链接，返回无水印视频/图文信息
  static Future<VideoParseResult> parse(String shareUrl) async {
    // 清理链接
    final url = _extractUrl(shareUrl);
    if (url == null) {
      throw Exception('未找到有效链接，请检查分享内容');
    }

    // 判断平台
    if (url.contains('douyin.com') || url.contains('iesdouyin.com')) {
      return _parseDouyin(url);
    } else if (url.contains('kuaishou.com') || url.contains('ksapisrv.com')) {
      return _parseKuaishou(url);
    } else if (url.contains('xiaohongshu.com') || url.contains('xhslink.com')) {
      return _parseXiaohongshu(url);
    } else if (url.contains('bilibili.com') || url.contains('b23.tv')) {
      return _parseBilibili(url);
    } else if (url.contains('weibo.com') || url.contains('weibo.cn')) {
      return _parseWeibo(url);
    } else if (url.contains('pipix.com')) {
      return _parsePipixia(url);
    } else if (url.contains('ixigua.com') || url.contains('toutiao.com')) {
      return _parseXigua(url);
    } else if (url.contains('zuiyou.com')) {
      return _parseZuiyou(url);
    } else if (url.contains('huoshan.com')) {
      return _parseHuoshan(url);
    } else {
      throw Exception('暂不支持该平台，目前支持：抖音、快手、小红书、B站、微博、皮皮虾、西瓜视频');
    }
  }

  /// 从分享文本中提取URL
  static String? _extractUrl(String text) {
    final regex = RegExp(r"""https?://[^\s<>"')\]]+""", caseSensitive: false);
    final match = regex.firstMatch(text);
    return match?.group(0);
  }

  /// 跟随重定向获取最终URL
  static Future<String> _followRedirects(String url) async {
    var currentUrl = url;
    for (int i = 0; i < 5; i++) {
      try {
        final response = await http.get(
          Uri.parse(currentUrl),
          headers: _headers,
        );
        if (response.statusCode == 301 || response.statusCode == 302) {
          final location = response.headers['location'];
          if (location != null) {
            currentUrl = location;
            continue;
          }
        }
        break;
      } catch (e) {
        break;
      }
    }
    return currentUrl;
  }

  /// 发送HTTP GET请求
  static Future<http.Response> _get(String url, {Map<String, String>? headers}) async {
    final requestHeaders = Map<String, String>.from(_headers);
    if (headers != null) {
      requestHeaders.addAll(headers);
    }
    return http.get(Uri.parse(url), headers: requestHeaders);
  }

  // ==================== 抖音 ====================
  static Future<VideoParseResult> _parseDouyin(String url) async {
    try {
      // 跟随重定向获取真实链接
      final realUrl = await _followRedirects(url);
      
      // 从URL中提取视频ID
      String? videoId;
      
      // 尝试从URL路径中提取 /video/xxxxx
      final videoRegex = RegExp(r'/video/(\d+)');
      final videoMatch = videoRegex.firstMatch(realUrl);
      if (videoMatch != null) {
        videoId = videoMatch.group(1);
      }
      
      // 尝试从URL中提取 /note/xxxxx (图文)
      final noteRegex = RegExp(r'/note/(\d+)');
      final noteMatch = noteRegex.firstMatch(realUrl);
      
      if (videoId == null && noteMatch == null) {
        // 尝试从页面内容中提取
        final response = await _get(realUrl);
        final body = response.body;
        
        // 尝试提取 video_id
        final idRegex = RegExp(r'"video_id":"([^"]+)"');
        final idMatch = idRegex.firstMatch(body);
        if (idMatch != null) {
          videoId = idMatch.group(1);
        }
        
        // 尝试提取 aweme_id
        if (videoId == null) {
          final awemeRegex = RegExp(r'"aweme_id":"(\d+)"');
          final awemeMatch = awemeRegex.firstMatch(body);
          if (awemeMatch != null) {
            videoId = awemeMatch.group(1);
          }
        }
      }

      if (noteMatch != null) {
        // 图文笔记
        final noteId = noteMatch.group(1);
        return _parseDouyinNote(realUrl, noteId!);
      }

      if (videoId == null) {
        throw Exception('无法提取抖音视频ID');
      }

      // 使用API获取视频信息
      final apiUrl = 'https://www.iesdouyin.com/web/api/v2/aweme/iteminfo/?item_ids=$videoId';
      final response = await _get(apiUrl);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['item_list'] != null && data['item_list'].isNotEmpty) {
          final item = data['item_list'][0];
          final desc = item['desc'] ?? '抖音视频';
          final author = item['author']?['nickname'];
          final cover = item['video']?['cover']?['url_list']?[0];
          
          // 获取无水印视频链接
          String? playUrl;
          final playAddr = item['video']?['play_addr']?['url_list'];
          if (playAddr != null && playAddr.isNotEmpty) {
            playUrl = playAddr[0].toString().replaceAll('playwm', 'play');
          }
          
          return VideoParseResult(
            platform: '抖音',
            title: desc,
            videoUrl: playUrl,
            coverUrl: cover,
            authorName: author,
            isVideo: true,
          );
        }
      }

      // 备用方案：从页面HTML中提取
      return _parseDouyinFromHtml(realUrl);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('抖音解析失败: $e');
    }
  }

  static Future<VideoParseResult> _parseDouyinFromHtml(String url) async {
    final response = await _get(url);
    final body = response.body;
    
    // 尝试提取渲染数据
    final renderRegex = RegExp(r'<script id="RENDER_DATA"[^>]*>([^<]+)</script>');
    final renderMatch = renderRegex.firstMatch(body);
    
    if (renderMatch != null) {
      try {
        final decoded = Uri.decodeComponent(renderMatch.group(1)!);
        final data = json.decode(decoded);
        // 遍历查找视频信息
        final jsonStr = json.encode(data);
        
        final titleRegex = RegExp(r'"desc"\s*:\s*"([^"]*)"');
        final titleMatch = titleRegex.firstMatch(jsonStr);
        final title = titleMatch?.group(1) ?? '抖音视频';
        
        final playRegex = RegExp(r'"play_addr"\s*:\s*\{[^}]*"url_list"\s*:\s*\[([^\]]+)\]');
        final playMatch = playRegex.firstMatch(jsonStr);
        if (playMatch != null) {
          final urls = playMatch.group(1)!;
          final urlRegex = RegExp(r'"([^"]+)"');
          final urlMatches = urlRegex.allMatches(urls);
          for (final m in urlMatches) {
            final u = m.group(1)!;
            if (u.startsWith('http')) {
              return VideoParseResult(
                platform: '抖音',
                title: title,
                videoUrl: u.replaceAll('playwm', 'play'),
                isVideo: true,
              );
            }
          }
        }
      } catch (_) {}
    }
    
    throw Exception('抖音解析失败，请尝试复制完整分享链接');
  }

  static Future<VideoParseResult> _parseDouyinNote(String url, String noteId) async {
    final response = await _get(url);
    final body = response.body;
    
    // 提取图片列表
    final imageRegex = RegExp(r'"image_list"\s*:\s*\[([^\]]+)\]');
    final imageMatch = imageRegex.firstMatch(body);
    
    List<String> imageUrls = [];
    if (imageMatch != null) {
      final urlRegex = RegExp(r'"url_list"\s*:\s*\[([^\]]+)\]');
      final urlMatches = urlRegex.allMatches(imageMatch.group(1)!);
      for (final m in urlMatches) {
        final urls = m.group(1)!;
        final singleUrlRegex = RegExp(r'"(https?://[^"]+)"');
        final singleMatch = singleUrlRegex.firstMatch(urls);
        if (singleMatch != null) {
          imageUrls.add(singleMatch.group(1)!);
        }
      }
    }
    
    final titleRegex = RegExp(r'"desc"\s*:\s*"([^"]*)"');
    final titleMatch = titleRegex.firstMatch(body);
    final title = titleMatch?.group(1) ?? '抖音图文';
    
    return VideoParseResult(
      platform: '抖音',
      title: title,
      imageUrls: imageUrls,
      isVideo: false,
    );
  }

  // ==================== 快手 ====================
  static Future<VideoParseResult> _parseKuaishou(String url) async {
    try {
      final realUrl = await _followRedirects(url);
      
      // 从URL中提取视频ID
      final photoRegex = RegExp(r'/short-video/(\w+)');
      final photoMatch = photoRegex.firstMatch(realUrl);
      
      final photoIdRegex = RegExp(r'photoId=(\w+)');
      final photoIdMatch = photoIdRegex.firstMatch(realUrl);
      
      String? photoId = photoMatch?.group(1) ?? photoIdMatch?.group(1);
      
      if (photoId == null) {
        // 从页面中提取
        final response = await _get(realUrl);
        final body = response.body;
        
        final idRegex = RegExp(r'"photoId"\s*:\s*"(\w+)"');
        final idMatch = idRegex.firstMatch(body);
        if (idMatch != null) {
          photoId = idMatch.group(1);
        }
      }
      
      if (photoId == null) {
        throw Exception('无法提取快手视频ID');
      }

      // 使用快手API
      final apiUrl = 'https://m.gifshow.com/rest/wd/photo/info?photoId=$photoId&is498=true';
      final response = await _get(apiUrl, headers: {
        ..._headers,
        'Referer': 'https://m.gifshow.com/',
        'Cookie': 'did=web_d${DateTime.now().millisecondsSinceEpoch}',
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['photo'] != null) {
          final photo = data['photo'];
          final title = photo['caption'] ?? '快手视频';
          final author = photo['userName'];
          final cover = photo['coverUrl'];
          final videoUrl = photo['mainMvUrl'] ?? photo['photoUrl'];
          
          return VideoParseResult(
            platform: '快手',
            title: title,
            videoUrl: videoUrl,
            coverUrl: cover,
            authorName: author,
            isVideo: true,
          );
        }
      }
      
      throw Exception('快手解析失败，请尝试复制完整分享链接');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('快手解析失败: $e');
    }
  }

  // ==================== 小红书 ====================
  static Future<VideoParseResult> _parseXiaohongshu(String url) async {
    try {
      String realUrl = url;
      
      // 如果是短链接，跟随重定向
      if (url.contains('xhslink.com')) {
        realUrl = await _followRedirects(url);
      }
      
      final response = await _get(realUrl, headers: {
        ..._headers,
        'Referer': 'https://www.xiaohongshu.com/',
      });
      final body = response.body;
      
      // 提取笔记信息
      final titleRegex = RegExp(r'"desc"\s*:\s*"([^"]*)"');
      final titleMatch = titleRegex.firstMatch(body);
      final title = titleMatch?.group(1) ?? '小红书笔记';
      
      // 判断是视频还是图文
      final videoRegex = RegExp(r'"url"\s*:\s*"(https?://[^"]*\.mp4[^"]*)"');
      final videoMatch = videoRegex.firstMatch(body);
      
      if (videoMatch != null) {
        // 视频笔记
        return VideoParseResult(
          platform: '小红书',
          title: title,
          videoUrl: videoMatch.group(1),
          isVideo: true,
        );
      } else {
        // 图文笔记 - 提取图片
        List<String> imageUrls = [];
        final imageRegex = RegExp(r'"url"\s*:\s*"(https?://[^"]*(?:\.jpg|\.jpeg|\.png|\.webp)[^"]*)"');
        final imageMatches = imageRegex.allMatches(body);
        for (final m in imageMatches) {
          final imgUrl = m.group(1)!;
          if (imgUrl.contains('sns-webpic') || imgUrl.contains('ci.xiaohongshu')) {
            imageUrls.add(imgUrl);
          }
        }
        
        // 去重
        imageUrls = imageUrls.toSet().toList();
        
        if (imageUrls.isEmpty) {
          // 尝试另一种格式
          final imgRegex2 = RegExp(r'"imageList"\s*:\s*\[([^\]]+)\]');
          final imgMatch2 = imgRegex2.firstMatch(body);
          if (imgMatch2 != null) {
            final urlRegex = RegExp(r'"(https?://[^"]+)"');
            final urlMatches = urlRegex.allMatches(imgMatch2.group(1)!);
            for (final m in urlMatches) {
              imageUrls.add(m.group(1)!);
            }
          }
        }
        
        return VideoParseResult(
          platform: '小红书',
          title: title,
          imageUrls: imageUrls,
          isVideo: false,
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('小红书解析失败: $e');
    }
  }

  // ==================== B站 ====================
  static Future<VideoParseResult> _parseBilibili(String url) async {
    try {
      String realUrl = url;
      
      // 短链接跟随重定向
      if (url.contains('b23.tv')) {
        realUrl = await _followRedirects(url);
      }
      
      // 提取BV号
      final bvRegex = RegExp(r'(BV\w{10})');
      final bvMatch = bvRegex.firstMatch(realUrl);
      
      if (bvMatch == null) {
        throw Exception('无法提取B站视频BV号');
      }
      
      final bvid = bvMatch.group(1)!;
      
      // 使用B站API获取视频信息
      final apiUrl = 'https://api.bilibili.com/x/web-interface/view?bvid=$bvid';
      final response = await _get(apiUrl, headers: {
        ..._headers,
        'Referer': 'https://www.bilibili.com/',
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 0 && data['data'] != null) {
          final videoData = data['data'];
          final title = videoData['title'] ?? 'B站视频';
          final author = videoData['owner']?['name'];
          final cover = videoData['pic'];
          final cid = videoData['cid'];
          
          // 获取视频播放地址
          String? videoUrl;
          if (cid != null) {
            final playApiUrl = 'https://api.bilibili.com/x/player/playurl?bvid=$bvid&cid=$cid&qn=80&fnval=16';
            final playResponse = await _get(playApiUrl, headers: {
              ..._headers,
              'Referer': 'https://www.bilibili.com/',
            });
            
            if (playResponse.statusCode == 200) {
              final playData = json.decode(playResponse.body);
              if (playData['data'] != null) {
                // DASH格式
                if (playData['data']['dash'] != null) {
                  final dash = playData['data']['dash'];
                  if (dash['video'] != null && dash['video'].isNotEmpty) {
                    videoUrl = dash['video'][0]['baseUrl'] ?? dash['video'][0]['base_url'];
                  }
                }
                // 普通格式
                if (videoUrl == null && playData['data']['durl'] != null) {
                  final durl = playData['data']['durl'];
                  if (durl.isNotEmpty) {
                    videoUrl = durl[0]['url'];
                  }
                }
              }
            }
          }
          
          return VideoParseResult(
            platform: 'B站',
            title: title,
            videoUrl: videoUrl,
            coverUrl: cover?.toString(),
            authorName: author,
            isVideo: true,
          );
        }
      }
      
      throw Exception('B站解析失败');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('B站解析失败: $e');
    }
  }

  // ==================== 微博 ====================
  static Future<VideoParseResult> _parseWeibo(String url) async {
    try {
      final realUrl = await _followRedirects(url);
      final response = await _get(realUrl);
      final body = response.body;
      
      // 提取视频URL
      final videoRegex = RegExp(r'"stream_url"\s*:\s*"(https?://[^"]+)"');
      final videoMatch = videoRegex.firstMatch(body);
      
      final titleRegex = RegExp(r'"status_title"\s*:\s*"([^"]*)"');
      final titleMatch = titleRegex.firstMatch(body);
      final title = titleMatch?.group(1) ?? '微博视频';
      
      if (videoMatch != null) {
        return VideoParseResult(
          platform: '微博',
          title: title,
          videoUrl: videoMatch.group(1)!.replaceAll('\\/', '/'),
          isVideo: true,
        );
      }
      
      // 尝试另一种格式
      final videoRegex2 = RegExp(r'"url"\s*:\s*"(https?://[^"]*\.mp4[^"]*)"');
      final videoMatch2 = videoRegex2.firstMatch(body);
      
      if (videoMatch2 != null) {
        return VideoParseResult(
          platform: '微博',
          title: title,
          videoUrl: videoMatch2.group(1)!.replaceAll('\\/', '/'),
          isVideo: true,
        );
      }
      
      throw Exception('微博解析失败，可能该微博不包含视频');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('微博解析失败: $e');
    }
  }

  // ==================== 皮皮虾 ====================
  static Future<VideoParseResult> _parsePipixia(String url) async {
    try {
      final realUrl = await _followRedirects(url);
      final response = await _get(realUrl);
      final body = response.body;
      
      final videoRegex = RegExp(r'"url"\s*:\s*"(https?://[^"]*\.mp4[^"]*)"');
      final videoMatch = videoRegex.firstMatch(body);
      
      final titleRegex = RegExp(r'"content"\s*:\s*"([^"]*)"');
      final titleMatch = titleRegex.firstMatch(body);
      final title = titleMatch?.group(1) ?? '皮皮虾视频';
      
      if (videoMatch != null) {
        return VideoParseResult(
          platform: '皮皮虾',
          title: title,
          videoUrl: videoMatch.group(1)!.replaceAll('\\/', '/'),
          isVideo: true,
        );
      }
      
      throw Exception('皮皮虾解析失败');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('皮皮虾解析失败: $e');
    }
  }

  // ==================== 西瓜视频 ====================
  static Future<VideoParseResult> _parseXigua(String url) async {
    try {
      final realUrl = await _followRedirects(url);
      final response = await _get(realUrl);
      final body = response.body;
      
      final titleRegex = RegExp(r'"title"\s*:\s*"([^"]*)"');
      final titleMatch = titleRegex.firstMatch(body);
      final title = titleMatch?.group(1) ?? '西瓜视频';
      
      // 提取视频URL
      final videoRegex = RegExp(r'"main_url"\s*:\s*"(https?://[^"]+)"');
      final videoMatch = videoRegex.firstMatch(body);
      
      if (videoMatch != null) {
        return VideoParseResult(
          platform: '西瓜视频',
          title: title,
          videoUrl: Uri.decodeComponent(videoMatch.group(1)!),
          isVideo: true,
        );
      }
      
      throw Exception('西瓜视频解析失败');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('西瓜视频解析失败: $e');
    }
  }

  // ==================== 最右 ====================
  static Future<VideoParseResult> _parseZuiyou(String url) async {
    try {
      final realUrl = await _followRedirects(url);
      final response = await _get(realUrl);
      final body = response.body;
      
      final videoRegex = RegExp(r'"video_url"\s*:\s*"(https?://[^"]+)"');
      final videoMatch = videoRegex.firstMatch(body);
      
      final titleRegex = RegExp(r'"content"\s*:\s*"([^"]*)"');
      final titleMatch = titleRegex.firstMatch(body);
      final title = titleMatch?.group(1) ?? '最右视频';
      
      if (videoMatch != null) {
        return VideoParseResult(
          platform: '最右',
          title: title,
          videoUrl: videoMatch.group(1)!.replaceAll('\\/', '/'),
          isVideo: true,
        );
      }
      
      throw Exception('最右解析失败');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('最右解析失败: $e');
    }
  }

  // ==================== 火山小视频 ====================
  static Future<VideoParseResult> _parseHuoshan(String url) async {
    try {
      final realUrl = await _followRedirects(url);
      final response = await _get(realUrl);
      final body = response.body;
      
      final videoRegex = RegExp(r'"video_url"\s*:\s*"(https?://[^"]+)"');
      final videoMatch = videoRegex.firstMatch(body);
      
      final titleRegex = RegExp(r'"title"\s*:\s*"([^"]*)"');
      final titleMatch = titleRegex.firstMatch(body);
      final title = titleMatch?.group(1) ?? '火山视频';
      
      if (videoMatch != null) {
        return VideoParseResult(
          platform: '火山小视频',
          title: title,
          videoUrl: videoMatch.group(1)!.replaceAll('\\/', '/'),
          isVideo: true,
        );
      }
      
      throw Exception('火山小视频解析失败');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('火山小视频解析失败: $e');
    }
  }

  /// 获取支持的平台列表
  static List<Map<String, String>> getSupportedPlatforms() {
    return [
      {'name': '抖音', 'icon': '🎵', 'example': 'https://v.douyin.com/xxxxx/'},
      {'name': '快手', 'icon': '🎬', 'example': 'https://v.kuaishou.com/xxxxx'},
      {'name': '小红书', 'icon': '📕', 'example': 'https://www.xiaohongshu.com/explore/xxxxx'},
      {'name': 'B站', 'icon': '📺', 'example': 'https://b23.tv/xxxxx'},
      {'name': '微博', 'icon': '🌐', 'example': 'https://weibo.com/xxxxx'},
      {'name': '皮皮虾', 'icon': '🦐', 'example': 'https://h5.pipix.com/s/xxxxx'},
      {'name': '西瓜视频', 'icon': '🍉', 'example': 'https://www.ixigua.com/xxxxx'},
      {'name': '火山小视频', 'icon': '🌋', 'example': 'https://huoshan.com/xxxxx'},
    ];
  }
}