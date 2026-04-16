import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/mystical_scaffold.dart';
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

    return readingsAsync.when(
      loading: () => const MysticalScaffold(
        title: '리딩 상세',
        body: Center(child: CircularProgressIndicator(color: kGold)),
      ),
      error: (e, _) => MysticalScaffold(
        title: '리딩 상세',
        body: Center(child: Text('오류: $e', style: const TextStyle(color: kTextSecondary))),
      ),
      data: (readings) {
        final reading = readings.where((r) => r.id == widget.readingId).firstOrNull;
        if (reading == null) {
          return const MysticalScaffold(
            title: '리딩 상세',
            body: Center(child: Text('리딩을 찾을 수 없습니다.', style: TextStyle(color: kTextSecondary))),
          );
        }

        if (!_initialized) {
          _notesController.text = reading.notes ?? '';
          _initialized = true;
        }

        final resolvedPositions =
            reading.spreadType.resolvePositions(reading.drawnCards.length);

        return MysticalScaffold(
          appBar: AppBar(
            title: Text(
              reading.spreadType.displayName,
              style: const TextStyle(color: kTextPrimary, letterSpacing: 0.5),
            ),
            backgroundColor: kDarkSurface.withValues(alpha: 0.85),
            elevation: 0,
            iconTheme: const IconThemeData(color: kTextPrimary),
            actions: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _saving
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: kGold),
                      )
                    : Icon(Icons.check_rounded, size: 18, color: kGold.withValues(alpha: 0.8)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 날짜
                Text(
                  _formatDateTime(reading.createdAt),
                  style: const TextStyle(color: kTextSecondary, fontSize: 11, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),

                // 질문
                if (reading.question != null && reading.question!.isNotEmpty) ...[
                  MysticalCard(
                    child: Row(
                      children: [
                        Icon(Icons.format_quote, color: kGold.withValues(alpha: 0.6), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reading.question!,
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 뽑힌 카드 목록
                const GoldSectionTitle('뽑힌 카드', icon: Icons.auto_awesome_outlined),
                ...List.generate(reading.drawnCards.length, (i) {
                  final card = reading.drawnCards[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: kDeepPurple.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kGold.withValues(alpha: 0.15), width: 0.7),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kGold.withValues(alpha: 0.12),
                            border: Border.all(color: kGold.withValues(alpha: 0.4), width: 0.7),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i < resolvedPositions.length ? resolvedPositions[i] : '카드 ${i + 1}',
                                style: const TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3),
                              ),
                              Text(
                                card.cardId + (card.isReversed ? ' (역방향)' : ''),
                                style: const TextStyle(color: kTextSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (card.isReversed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kSoftPurple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: kSoftPurple.withValues(alpha: 0.4), width: 0.5),
                            ),
                            child: const Text('역', style: TextStyle(color: kSoftPurple, fontSize: 10)),
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),
                GoldHairline(opacity: 0.25),
                const SizedBox(height: 16),

                // 메모 섹션
                const GoldSectionTitle('메모', icon: Icons.edit_note_outlined),
                TextField(
                  controller: _notesController,
                  maxLines: null,
                  minLines: 3,
                  decoration: mysticalInputDecoration(
                    hintText: '이 리딩에 대한 메모를 남겨보세요...',
                  ),
                  style: const TextStyle(color: kTextPrimary, fontSize: 14, height: 1.5),
                  onChanged: (_) => _onNotesChanged(reading.id),
                ),
                const SizedBox(height: 6),
                Text(
                  _saving ? '저장 중...' : '자동 저장됨',
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.7),
                    fontSize: 11,
                    letterSpacing: 0.3,
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
    return '${dt.year}.${dt.month}.${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
