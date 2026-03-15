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
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline,
              color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 8),
          Text('시스템 난수 사용', style: theme.textTheme.bodyMedium),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
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
