import 'package:flutter/material.dart';

class EntropyProgressIndicator extends StatelessWidget {
  const EntropyProgressIndicator({
    super.key,
    required this.progress,
    required this.sensorsAvailable,
  });

  final double progress;
  final bool sensorsAvailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!sensorsAvailable) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.nights_stay,
              color: theme.colorScheme.primary, size: 24),
          const SizedBox(height: 4),
          Text('우주의 에너지로 배열합니다',
              style: theme.textTheme.bodyMedium),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          progress >= 1.0
              ? '에너지 충전 완료!'
              : '${(progress * 100).toInt()}% 수집 중...',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
