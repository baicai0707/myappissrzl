import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/video_parser_service.dart';
import '../widgets/custom_toast.dart';

class VideoParserPage extends StatefulWidget {
  const VideoParserPage({super.key});

  @override
  State<VideoParserPage> createState() => _VideoParserPageState();
}

class _VideoParserPageState extends State<VideoParserPage> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  VideoParseResult? _result;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _parseUrl() async {
    final text = _urlController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = '请输入分享链接');
      return;
    }

    _focusNode.unfocus();
    setState(() {
      _isLoading = true;
      _result = null;
      _errorMessage = null;
    });

    try {
      final result = await VideoParserService.parse(text);
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _clearInput() {
    _urlController.clear();
    setState(() {
      _result = null;
      _errorMessage = null;
    });
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      CustomToast.success(context, '已复制到剪贴板');
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        CustomToast.error(context, '无法打开链接');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('视频解析'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showSupportedPlatforms(context),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => _focusNode.unfocus(),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputSection(theme, isDark),
                    const SizedBox(height: 20),
                    if (_isLoading) _buildLoadingState(theme),
                    if (_errorMessage != null) _buildErrorState(theme, isDark),
                    if (_result != null) _buildResultSection(theme, isDark),
                    if (!_isLoading &&
                        _errorMessage == null &&
                        _result == null)
                      _buildEmptyState(theme, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4361EE).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link_rounded,
                    color: Color(0xFF4361EE), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('粘贴分享链接',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('支持抖音、快手、小红书等平台',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.45))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            focusNode: _focusNode,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: '粘贴视频/图文分享链接...\n例如: 7.89 复制打开抖音...',
              hintStyle: TextStyle(
                color: theme.textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.3),
                fontSize: 14,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: _urlController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded,
                          size: 18,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.4)),
                      onPressed: _clearInput,
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _parseUrl(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _parseUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4361EE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('解析',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('正在解析...',
                style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 24),
          ),
          const SizedBox(height: 12),
          const Text('解析失败',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444))),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showSupportedPlatforms(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('查看支持的平台',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF4361EE).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.video_library_outlined,
                size: 32,
                color: const Color(0xFF4361EE).withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text('粘贴分享链接开始解析',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.5))),
          const SizedBox(height: 8),
          Text('支持视频和图文内容的无水印解析',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.35))),
          const SizedBox(height: 24),
          _buildSupportedPlatformsChips(),
        ],
      ),
    );
  }

  Widget _buildSupportedPlatformsChips() {
    final platforms = VideoParserService.getSupportedPlatforms();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: platforms.map((p) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(p['icon']!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(p['name']!,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.6))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultSection(ThemeData theme, bool isDark) {
    final result = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 平台标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 14, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text('解析成功 · ${result.platform}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 结果卡片
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和作者
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: result.isVideo
                                ? const Color(0xFF4361EE)
                                    .withValues(alpha: 0.1)
                                : const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            result.isVideo ? '视频' : '图文',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: result.isVideo
                                    ? const Color(0xFF4361EE)
                                    : const Color(0xFFF59E0B)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result.platform,
                            style: TextStyle(
                                fontSize: 13,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.5)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.authorName != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 14,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                          Text(
                            result.authorName!,
                            style: TextStyle(
                                fontSize: 13,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // 分割线
              Divider(
                  height: 1,
                  color: theme.dividerTheme.color),

              // 视频链接
              if (result.isVideo && result.videoUrl != null)
                _buildLinkItem(
                  theme,
                  isDark,
                  icon: Icons.play_circle_outline_rounded,
                  iconColor: const Color(0xFF4361EE),
                  title: '无水印视频链接',
                  subtitle: result.videoUrl!,
                  onCopy: () => _copyToClipboard(result.videoUrl!),
                  onOpen: () => _openUrl(result.videoUrl!),
                ),

              // 图片链接列表
              if (!result.isVideo &&
                  result.imageUrls != null &&
                  result.imageUrls!.isNotEmpty)
                ...result.imageUrls!.asMap().entries.map((entry) {
                  return _buildLinkItem(
                    theme,
                    isDark,
                    icon: Icons.image_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    title: '图片 ${entry.key + 1}',
                    subtitle: entry.value,
                    onCopy: () => _copyToClipboard(entry.value),
                    onOpen: () => _openUrl(entry.value),
                    showDivider: entry.key < result.imageUrls!.length - 1,
                  );
                }),

              // 封面链接
              if (result.coverUrl != null)
                _buildLinkItem(
                  theme,
                  isDark,
                  icon: Icons.photo_size_select_actual_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  title: '封面图片',
                  subtitle: result.coverUrl!,
                  onCopy: () => _copyToClipboard(result.coverUrl!),
                  onOpen: () => _openUrl(result.coverUrl!),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 复制全部按钮
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              final allLinks = <String>[];
              if (result.videoUrl != null) allLinks.add(result.videoUrl!);
              if (result.imageUrls != null) allLinks.addAll(result.imageUrls!);
              _copyToClipboard(allLinks.join('\n'));
            },
            icon: const Icon(Icons.copy_all_rounded, size: 20),
            label: const Text('复制全部链接',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4361EE),
              side: BorderSide(
                  color: const Color(0xFF4361EE).withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 提示信息
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '复制链接后在浏览器中打开即可下载无水印内容。部分平台可能需要登录才能访问。',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.5),
                      height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkItem(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onCopy,
    required VoidCallback onOpen,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: iconColor),
                  const SizedBox(width: 8),
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.8))),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.5)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: onCopy,
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('复制链接',
                            style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: iconColor,
                          side: BorderSide(
                              color: iconColor.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.open_in_browser_rounded,
                            size: 16),
                        label: const Text('打开',
                            style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iconColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: theme.dividerTheme.color),
      ],
    );
  }

  void _showSupportedPlatforms(BuildContext context) {
    final theme = Theme.of(context);
    final platforms = VideoParserService.getSupportedPlatforms();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('支持的平台',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('复制对应平台的分享链接即可解析',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 20),
              ...platforms.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(p['icon']!,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['name']!,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(p['example']!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}