import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/reading_providers.dart';

class ReadingDetailPage extends ConsumerStatefulWidget {
  const ReadingDetailPage({super.key, required this.readingId});
  final String readingId;

  @override
  ConsumerState<ReadingDetailPage> createState() => _ReadingDetailPageState();
}

class _ReadingDetailPageState extends ConsumerState<ReadingDetailPage> {
  late final TextEditingController _notesController;
  Timer? _debounce;
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _onNotesChanged(String readingId) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _saving = true);
      await ref.read(readingRepositoryProvider).updateNotes(
            readingId,
            _notesController.text.isEmpty ? null : _notesController.text,
          );
      if (mounted) setState(() => _saving = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(watchReadingsProvider);
    final theme = Theme.of(context);

    return readingsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('리딩 상세')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('리딩 상세')),
        body: Center(child: Text('오류: $e')),
      ),
      data: (readings) {
        final reading =
            readings.where((r) => r.id == widget.readingId).firstOrNull;
        if (reading == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('리딩 상세')),
            body: const Center(child: Text('리딩을 찾을 수 없습니다.')),
          );
        }

        // 첫 빌드 시 notes 텍스트 초기화 (한 번만)
        if (!_initialized) {
          _notesController.text = reading.notes ?? '';
          _initialized = true;
        }

        final resolvedPositions =
            reading.spreadType.resolvePositions(reading.drawnCards.length);

        return Scaffold(
          appBar: AppBar(
            title: Text(reading.spreadType.displayName),
            actions: [
              if (_saving)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(Icons.check, size: 16, color: Colors.green),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 날짜
                Text(
                  _formatDateTime(reading.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),

                // 질문
                if (reading.question != null && reading.question!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '"${reading.question}"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 뽑힌 카드 목록
                Text('뽑힌 카드', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (var i = 0; i < reading.drawnCards.length; i++)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${i + 1}'),
                      ),
                      title: Text(resolvedPositions[i]),
                      subtitle: Text(
                        'Card: ${reading.drawnCards[i].cardId}'
                        '${reading.drawnCards[i].isReversed ? ' (역방향)' : ''}',
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // 메모 섹션
                Text('메모', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: null,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: '이 리딩에 대한 메모를 남겨보세요...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (_) => _onNotesChanged(reading.id),
                ),
                const SizedBox(height: 8),
                Text(
                  _saving ? '저장 중...' : '자동 저장됨',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}.${dt.month}.${dt.day} '
        '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
