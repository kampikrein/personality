import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/reading.dart';
import '../../domain/entities/spread_type.dart';
import '../providers/reading_providers.dart';

class ReadingListPage extends ConsumerStatefulWidget {
  const ReadingListPage({super.key});

  @override
  ConsumerState<ReadingListPage> createState() => _ReadingListPageState();
}

class _ReadingListPageState extends ConsumerState<ReadingListPage> {
  SpreadType? _filterType; // null = 전체 표시

  @override
  Widget build(BuildContext context) {
    final readingsAsync = _filterType == null
        ? ref.watch(watchReadingsProvider)
        : ref.watch(watchReadingsBySpreadTypeProvider(_filterType!));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('리딩 기록')),
      body: Column(
        children: [
          // 필터 칩 행
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('전체'),
                  selected: _filterType == null,
                  onSelected: (_) => setState(() => _filterType = null),
                ),
                const SizedBox(width: 8),
                for (final type in SpreadType.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type.displayName),
                      selected: _filterType == type,
                      onSelected: (_) => setState(() {
                        _filterType = _filterType == type ? null : type;
                      }),
                    ),
                  ),
              ],
            ),
          ),
          // 리딩 목록
          Expanded(
            child: readingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (readings) => readings.isEmpty
                  ? Center(
                      child: Text(
                        _filterType == null
                            ? '아직 리딩이 없습니다.'
                            : '${_filterType!.displayName} 리딩이 없습니다.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: readings.length,
                      itemBuilder: (context, index) =>
                          _ReadingListTile(reading: readings[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingListTile extends StatelessWidget {
  const _ReadingListTile({required this.reading});
  final Reading reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          _spreadTypeIcon(reading.spreadType),
          color: theme.colorScheme.primary,
        ),
        title: Text(
          '${reading.spreadType.displayName} (${reading.drawnCards.length}장)',
        ),
        subtitle: Text(
          reading.question ?? '질문 없음',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatDate(reading.createdAt),
          style: theme.textTheme.bodySmall,
        ),
        onTap: () => context.pushNamed(
          'reading-detail',
          pathParameters: {'readingId': reading.id},
        ),
      ),
    );
  }

  IconData _spreadTypeIcon(SpreadType type) {
    return switch (type) {
      SpreadType.single => Icons.looks_one,
      SpreadType.threeCard => Icons.looks_3,
      SpreadType.custom => Icons.grid_view,
    };
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
