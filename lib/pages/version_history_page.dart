import 'package:flutter/material.dart';
import '../constants.dart';

class VersionHistoryPage extends StatelessWidget {
  const VersionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('版本记录')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: versionHistory.length,
        itemBuilder: (context, index) {
          final v = versionHistory[index];
          final isLatest = v['isLatest'] as bool;
          final changes = v['changes'] as List<String>;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLatest
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLatest
                            ? theme.colorScheme.primary
                                .withValues(alpha: 0.1)
                            : theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('v${v['version']}',
                          style: TextStyle(
                              color: isLatest
                                  ? theme.colorScheme.primary
                                  : null,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                    if (isLatest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('最新',
                            style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                    const Spacer(),
                    Text(v['date'] as String,
                        style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.4))),
                  ],
                ),
                const SizedBox(height: 16),
                ...changes.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 7),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(c,
                                  style:
                                      const TextStyle(height: 1.5))),
                        ],
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}
