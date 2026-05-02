import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;
  String? _error;
  int? _myRank;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 先同步当前用户的积分
      final profile = context.read<ProfileProvider>();
      await leaderboardService.syncPoints(
        nickname: profile.name,
        points: profile.points,
        level: profile.currentLevel.level,
      );

      // 加载排行榜
      final entries = await leaderboardService.getLeaderboard();
      final rank = await leaderboardService.getMyRank();

      if (mounted) {
        setState(() {
          _entries = entries;
          _myRank = rank;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '加载失败，请稍后重试';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('积分排行榜'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget(theme)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // 我的排名卡片
                      SliverToBoxAdapter(
                        child: _buildMyRankCard(theme, isDark),
                      ),
                      // 前三名
                      if (_entries.length >= 3)
                        SliverToBoxAdapter(
                          child: _buildTopThree(theme, isDark),
                        ),
                      // 排行榜列表
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        sliver: _entries.length <= 3
                            ? SliverToBoxAdapter(
                                child: _buildEmptyOrMore(theme),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final entry = _entries[index + 3];
                                    return _buildRankItem(
                                        theme, isDark, entry, index + 4);
                                  },
                                  childCount: _entries.length - 3,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(_error!,
              style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.5))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankCard(ThemeData theme, bool isDark) {
    final profile = context.watch<ProfileProvider>();
    final level = profile.currentLevel;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1F35), const Color(0xFF161B2E)]
              : [const Color(0xFF4361EE), const Color(0xFF5B3FE4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF1A1F35) : const Color(0xFF4361EE))
                .withValues(alpha: isDark ? 0.5 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _myRank != null ? '$_myRank' : '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(level.icon, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${level.name} · ${profile.points} 积分',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _myRank != null ? '第 $_myRank 名' : '未上榜',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopThree(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _buildPodiumItem(theme, isDark, _entries[1], 2)),
          const SizedBox(width: 8),
          Expanded(child: _buildPodiumItem(theme, isDark, _entries[0], 1)),
          const SizedBox(width: 8),
          Expanded(child: _buildPodiumItem(theme, isDark, _entries[2], 3)),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
      ThemeData theme, bool isDark, LeaderboardEntry entry, int rank) {
    final colors = {
      1: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      2: [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)],
      3: [const Color(0xFFCD7F32), const Color(0xFFA0522D)],
    };
    final heights = {1: 140.0, 2: 110.0, 3: 90.0};
    final gradient = colors[rank]!;
    final height = heights[rank]!;
    final isMe = entry.uid == authService.uid;

    return Column(
      children: [
        // 头像
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 16),
              child: Container(
                width: rank == 1 ? 64 : 52,
                height: rank == 1 ? 64 : 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: gradient[0],
                    width: rank == 1 ? 3 : 2,
                  ),
                  color: theme.cardTheme.color,
                ),
                child: Center(
                  child: Icon(Icons.person_rounded,
                      size: rank == 1 ? 28 : 22,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.4)),
                ),
              ),
            ),
            // 名次徽章
            Positioned(
              top: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: gradient),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: rank == 1
                      ? const Icon(Icons.emoji_events_rounded,
                          size: 16, color: Colors.white)
                      : Text(
                          '$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 昵称
        Text(
          entry.nickname,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
            color: isMe
                ? theme.colorScheme.primary
                : theme.textTheme.bodyMedium?.color,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        // 积分
        Text(
          '${entry.points}',
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        // 柱状体
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient.map((c) => c.withValues(alpha: 0.8)).toList(),
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildRankItem(
      ThemeData theme, bool isDark, LeaderboardEntry entry, int rank) {
    final isMe = entry.uid == authService.uid;
    final level = levels.firstWhere(
      (l) => l.level == entry.level,
      orElse: () => levels.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? theme.colorScheme.primary.withValues(alpha: 0.06)
            : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          // 排名
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // 头像
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            child: Icon(Icons.person_rounded,
                size: 20,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
          ),
          const SizedBox(width: 12),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.nickname,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isMe ? FontWeight.w700 : FontWeight.w500,
                          color: isMe
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodyMedium?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '我',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(level.icon,
                        size: 12,
                        color: level.color),
                    const SizedBox(width: 4),
                    Text(
                      level.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 积分
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '积分',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrMore(ThemeData theme) {
    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.leaderboard_outlined,
                  size: 64,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.15)),
              const SizedBox(height: 16),
              Text(
                '暂无排行数据',
                style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}