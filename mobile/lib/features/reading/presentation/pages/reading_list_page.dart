import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/mystical_scaffold.dart';
import '../../domain/entities/reading.dart';
import '../../domain/entities/layout_type.dart';
import '../providers/reading_providers.dart';

class ReadingListPage extends ConsumerStatefulWidget {
  const ReadingListPage({super.key});

  @override
  ConsumerState<ReadingListPage> createState() => _ReadingListPageState();
}

class _ReadingListPageState extends ConsumerState<ReadingListPage> {
  LayoutType? _filterType;

  @override
  Widget build(BuildContext context) {
    final readingsAsync = _filterType == null
        ? ref.watch(watchReadingsProvider)
        : ref.watch(watchReadingsBySpreadTypeProvider(_filterType!));

    return MysticalScaffold(
      title: '리딩 기록',
      body: Column(
        children: [
          // ── 필터 칩 행 ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _GoldFilterChip(
                  label: '전체',
                  selected: _filterType == null,
                  onSelected: (_) => setState(() => _filterType = null),
                ),
                const SizedBox(width: 8),
                for (final type in LayoutType.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _GoldFilterChip(
                      label: type.displayName,
                      selected: _filterType == type,
                      onSelected: (_) => setState(() {
                        _filterType = _filterType == type ? null : type;
                      }),
                    ),
                  ),
              ],
            ),
          ),

          const GoldHairline(opacity: 0.2),

          // ── 리딩 목록 ──
          Expanded(
            child: readingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
              error: (e, _) => Center(
                child: Text('오류: $e', style: const TextStyle(color: kTextSecondary)),
              ),
              data: (readings) => readings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 40, color: kTextSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            _filterType == null
                                ? '아직 리딩이 없습니다.'
                                : '${_filterType!.displayName} 리딩이 없습니다.',
                            style: const TextStyle(color: kTextSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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

class _GoldFilterChip extends StatelessWidget {
  const _GoldFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kGold.withValues(alpha: 0.18) : kDeepPurple.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kGold.withValues(alpha: 0.7) : kSoftPurple.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? kGold : kTextSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _ReadingListTile extends StatelessWidget {
  const _ReadingListTile({required this.reading});
  final Reading reading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kDeepPurple.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGold.withValues(alpha: 0.18), width: 0.7),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.pushNamed(
            'reading-detail',
            pathParameters: {'readingId': reading.id},
          ),
          borderRadius: BorderRadius.circular(14),
          splashColor: kGold.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kGold.withValues(alpha: 0.1),
                    border: Border.all(color: kGold.withValues(alpha: 0.35), width: 0.7),
                  ),
                  child: Icon(
                    _layoutTypeIcon(reading.spreadType),
                    color: kGold,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${reading.spreadType.displayName} (${reading.drawnCards.length}장)',
                        style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reading.question ?? '질문 없음',
                        style: const TextStyle(color: kTextSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(reading.createdAt),
                  style: const TextStyle(color: kTextSecondary, fontSize: 10, letterSpacing: 0.2),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: kTextSecondary.withValues(alpha: 0.5), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _layoutTypeIcon(LayoutType type) {
    return switch (type) {
      LayoutType.linear => Icons.view_stream,
      LayoutType.tShape => Icons.view_quilt,
      LayoutType.grid3x3 => Icons.grid_view,
    };
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
