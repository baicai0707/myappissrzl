import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 黑客风格启动加载界面 - 轻量快速版
class HackerSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const HackerSplashScreen({super.key, required this.onComplete});

  @override
  State<HackerSplashScreen> createState() => _HackerSplashScreenState();
}

class _HackerSplashScreenState extends State<HackerSplashScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _lines = [];
  late AnimationController _pulseController;
  double _progress = 0.0;
  bool _completed = false;
  String _statusText = 'INITIALIZING...';

  static const _bootMessages = [
    '[BOOT] Loading kernel modules...',
    '[NET ] Establishing secure connection...',
    '[AUTH] Verifying credentials...',
    '[DB  ] Connecting to cloud database...',
    '[APP ] Initializing application...',
    '[DONE] System ready.',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _startBootSequence();
  }

  Future<void> _startBootSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (int i = 0; i < _bootMessages.length; i++) {
      if (!mounted) return;
      setState(() {
        _lines.add(_bootMessages[i]);
        _progress = (i + 1) / _bootMessages.length;
      });
      // 快速间隔：80~180ms
      await Future.delayed(Duration(milliseconds: 80 + Random().nextInt(100)));
    }

    // 快速进度条
    if (mounted) setState(() => _statusText = 'LOADING...');
    for (int i = (_progress * 100).toInt(); i <= 100; i += 5) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 20));
      if (mounted) {
        setState(() {
          _progress = i / 100;
          if (i > 50) _statusText = 'BUILDING UI...';
          if (i > 85) _statusText = 'READY';
        });
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() => _completed = true);
      await Future.delayed(const Duration(milliseconds: 400));
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              // Logo
              _buildLogo(),
              const SizedBox(height: 36),
              // 终端输出
              Expanded(child: _buildTerminal()),
              const SizedBox(height: 12),
              // 进度条
              _buildProgressBar(),
              const SizedBox(height: 12),
              // 状态
              _buildStatus(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final glow = _pulseController.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF41),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF41)
                            .withValues(alpha: 0.3 + glow * 0.4),
                        blurRadius: 6 + glow * 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'PRIVATE ASSISTANT',
                  style: TextStyle(
                    color: const Color(0xFF00FF41).withValues(alpha: 0.9),
                    fontSize: 13,
                    fontFamily: 'monospace',
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF00FF41)
                            .withValues(alpha: 0.4 + glow * 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'v2.3.1 // SYSTEM INIT',
              style: TextStyle(
                color: const Color(0xFF00FF41).withValues(alpha: 0.35),
                fontSize: 11,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 180,
              height: 1,
              color: const Color(0xFF00FF41).withValues(alpha: 0.15),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTerminal() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00FF41).withValues(alpha: 0.12),
        ),
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _lines.length,
        itemBuilder: (context, index) {
          final line = _lines[index];
          final isDone = line.contains('[DONE]');
          final isAuth = line.contains('[AUTH]');
          final color = isDone
              ? const Color(0xFF00FF41)
              : isAuth
                  ? const Color(0xFF00BFFF)
                  : const Color(0xFF00FF41).withValues(alpha: 0.65);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              line,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar() {
    final percent = (_progress * 100).toInt();
    final filled = (_progress * 25).toInt();
    final bar = '${'█' * filled}${'░' * (25 - filled)}';

    return Text(
      '[$bar] $percent%',
      style: TextStyle(
        color: const Color(0xFF00FF41).withValues(alpha: 0.75),
        fontSize: 11,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildStatus() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _completed
                    ? const Color(0xFF00FF41)
                    : const Color(0xFFFFD700),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_completed
                            ? const Color(0xFF00FF41)
                            : const Color(0xFFFFD700))
                        .withValues(alpha: 0.3 + _pulseController.value * 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _statusText,
              style: TextStyle(
                color: _completed
                    ? const Color(0xFF00FF41)
                    : const Color(0xFFFFD700),
                fontSize: 11,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ],
        );
      },
    );
  }
}