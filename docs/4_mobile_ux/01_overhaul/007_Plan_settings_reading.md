---
id: "007"
type: plan
title: "Cycle 2 설정 + 리딩 기능 — 구현 계획"
created: 2026-03-22
traces_scope: "002"
traces_brief: "001"
traces_research: "003"
traces_plan_c1: "004"
traces_eval_c1: "006"
cycle: 2
area: "설정 + 리딩 기능 (Settings & Reading)"
status: in-progress
summary: >
  설정 페이지 UI, 리딩 목록/상세 페이지, 자동 저장, "+1 한 장 더" 기능 구현 계획.
  ReadingRepository 확장(update/notes), ReadingDao 확장(update/filterBySpreadType),
  설정 페이지 신규, 리딩 목록/상세 신규, ReadingPage 대폭 수정(자동 저장 + +1 버튼).
  7단계, 신규 4파일 + 수정 7파일, 코드 생성 재실행 포함.
keywords: [settings-page, reading-list, reading-detail, auto-save, incremental-draw, notes]
---

# Cycle 2 설정 + 리딩 기능 — 구현 계획

## 실행 개요

| 항목 | 값 |
|------|---|
| 사이클 | 2 / 3 |
| 영역 | 설정 + 리딩 기능 (Settings & Reading) |
| Brief 앵커 | MA-5 (리딩 저장 & 메모), MA-7 (카드 표시 방식), MA-8 (한 장 더 뽑기) |
| 신규 파일 | 4개 |
| 수정 파일 | 7개 |
| 코드 생성 | `build_runner build` 필수 (Riverpod codegen, ReadingDao) |

## Cycle 1 의존 입력

Cycle 1에서 생성된 항목 중 이 사이클에서 직접 사용하는 것:

| # | 항목 | 사용처 |
|---|------|-------|
| 1 | `userSettingsProvider` (Stream) | 설정 페이지 watch, ReadingPage에서 showFaceUp 적용 |
| 2 | `userSettingsRepositoryProvider` | 설정 변경 시 개별 update 메서드 호출 |
| 3 | `SpreadType.custom` + `resolvePositions/Guidances` | 리딩 목록 필터, "+1" 뽑기 시 동적 positions |
| 4 | `DrawMode` enum | 덱 선택 UI에서 지원 뽑기 방식 표시 |
| 5 | `UserSettings.defaultCardCount` | 설정 페이지 기본 카드 수 표시/변경 |
| 6 | `ShuffleResult.cards[currentCount]` | "+1" 기능에서 다음 카드 접근 |

## Eval(006) 발견사항 반영

| ID | 발견 | 이 Plan에서의 대응 |
|----|------|-------------------|
| EV-006-D1 | `userSettingsProvider`가 AutoDispose → 설정 페이지에서 lifecycle 주의 | 설정 페이지에서 `ref.watch(userSettingsProvider)`를 사용하되, 페이지가 dispose되면 자연스럽게 구독 해제됨. AutoDispose가 문제 되는 것은 GoRouter redirect(Cycle 3)에서이므로, 이 사이클에서는 영향 없음 |
| EV-006-D2 | `_ensureDefaultRow`에서 다중 행 edge case | 설정 저장 시 항상 `id=1` 대상 update. DAO의 `where((s) => s.id.equals(1))` 패턴 유지 |
| EV-006-A1 | `custom.cardCount == 0` sentinel → 카드 수 관리 주의 | ReadingPage에서 custom일 때 `UserSettings.defaultCardCount`를 초기값으로 사용. `_currentCardCount` 상태 변수로 실제 장수 추적. "+1" 시 이 변수를 증가시키며, DB 저장 시 DrawnCards 행 수로 복원 |

## Step 1: ReadingRepository & ReadingDao 확장

"+1 뽑기" 후 기존 Reading에 카드 추가 + notes 인라인 편집을 위해 기존 Repository/DAO에 update 메서드를 추가한다.

### 1-1. ReadingDao 확장

**수정 파일**: `mobile/lib/core/database/daos/reading_dao.dart`

추가할 메서드:

```dart
/// 리딩의 notes 필드 업데이트.
Future<void> updateNotes(String readingId, String? notes) async {
  await (update(readings)..where((r) => r.id.equals(readingId))).write(
    ReadingsCompanion(
      notes: Value(notes),
      updatedAt: Value(DateTime.now()),
    ),
  );
}

/// 리딩에 drawn card 1장 추가. "+1 한 장 더" 기능용.
Future<void> addDrawnCard(DrawnCardsCompanion card) async {
  await into(drawnCards).insert(card);
  // Reading의 updatedAt도 갱신
  await (update(readings)..where((r) => r.id.equals(card.readingId.value)))
      .write(ReadingsCompanion(updatedAt: Value(DateTime.now())));
}

/// spreadType 기준 필터 조회 (리딩 목록 페이지용).
Stream<List<Reading>> watchReadingsBySpreadType(String spreadType) {
  return (select(readings)
        ..where((r) => r.spreadType.equals(spreadType))
        ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
      .watch();
}
```

**설계 판단:**
- `updateNotes`: notes 인라인 편집 시 Reading 전체를 재저장하지 않고 해당 필드만 업데이트.
- `addDrawnCard`: "+1" 시 Reading 행을 통째로 삭제/재삽입하지 않고 DrawnCards에 1행 추가 + Reading.updatedAt 갱신. 기존 `insertReading`의 transaction 패턴과 달리 단일 카드 INSERT.
- `watchReadingsBySpreadType`: 리딩 목록 페이지에서 필터 UI 적용 시 사용.

### 1-2. ReadingRepository 확장

**수정 파일**: `mobile/lib/features/reading/domain/repositories/reading_repository.dart`

추가할 메서드:

```dart
Future<void> updateNotes(String readingId, String? notes);
Future<void> addDrawnCard(String readingId, DrawnCardInfo card, DateTime createdAt);
Stream<List<Reading>> watchReadingsBySpreadType(SpreadType spreadType);
Future<Reading?> getReadingById(String id);
```

### 1-3. ReadingRepositoryImpl 확장

**수정 파일**: `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart`

```dart
@override
Future<void> updateNotes(String readingId, String? notes) async {
  await db.readingDao.updateNotes(readingId, notes);
}

@override
Future<void> addDrawnCard(
  String readingId, DrawnCardInfo card, DateTime createdAt,
) async {
  await db.readingDao.addDrawnCard(
    DrawnCardsCompanion.insert(
      id: '$readingId-${card.position}',
      readingId: readingId,
      cardId: card.cardId,
      position: card.position,
      isReversed: card.isReversed,
      createdAt: createdAt,
    ),
  );
}

@override
Stream<List<Reading>> watchReadingsBySpreadType(SpreadType spreadType) {
  return db.readingDao
      .watchReadingsBySpreadType(spreadType.name)
      .asyncMap((readings) => Future.wait(readings.map(_toDomainReading)));
}

@override
Future<Reading?> getReadingById(String id) async {
  final rows = await db.readingDao.getAllReadings();
  final row = rows.where((r) => r.id == id).firstOrNull;
  if (row == null) return null;
  return _toDomainReading(row);
}
```

### 1-4. ReadingProviders 확장

**수정 파일**: `mobile/lib/features/reading/presentation/providers/reading_providers.dart`

추가할 provider:

```dart
@riverpod
Stream<List<Reading>> watchReadingsBySpreadType(
  WatchReadingsBySpreadTypeRef ref,
  SpreadType spreadType,
) {
  final repo = ref.watch(readingRepositoryProvider);
  return repo.watchReadingsBySpreadType(spreadType);
}
```

**설계 판단:**
- family provider로 SpreadType을 매개변수로 받아 필터링된 Stream을 반환.
- 리딩 목록 페이지에서 사용자가 필터를 변경하면 `ref.watch(watchReadingsBySpreadTypeProvider(selectedType))`으로 reactive 갱신.

## Step 2: 설정 페이지 UI

**신규 파일**: `mobile/lib/features/settings/presentation/pages/settings_page.dart`

### UI 구조

```
SettingsPage (ConsumerWidget)
├── AppBar: "설정"
├── Section: 덱 선택
│   └── DropdownButton<String> — 덱 목록에서 selectedDeckId 선택
├── Section: 체험 레벨
│   └── SegmentedButton<int> — Level 1 / 2 / 3
├── Section: 기본 카드 수
│   └── Slider(1~10) + 현재 값 표시 Text
├── Section: 카드 표시
│   └── SwitchListTile — "앞면으로 시작" (showFaceUp)
├── Section: 즉시 뽑기
│   └── SwitchListTile — "앱 시작 시 바로 뽑기" (quickDrawEnabled)
└── Section: 기본 스프레드
    └── DropdownButton<SpreadType> — single / threeCard / custom
```

### 코드 스니펫

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final decksAsync = ref.watch(watchDecksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 덱 선택
            _SectionTitle('덱 선택'),
            decksAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('덱 로딩 오류: $e'),
              data: (decks) => DropdownButtonFormField<String>(
                value: settings.selectedDeckId,
                items: decks
                    .map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.name),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(userSettingsRepositoryProvider)
                        .updateSelectedDeckId(v);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // 체험 레벨
            _SectionTitle('체험 레벨'),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('즉시'), icon: Icon(Icons.flash_on)),
                ButtonSegment(value: 2, label: Text('연출'), icon: Icon(Icons.animation)),
                ButtonSegment(value: 3, label: Text('풀셔플'), icon: Icon(Icons.shuffle)),
              ],
              selected: {settings.experienceLevel},
              onSelectionChanged: (s) {
                ref.read(userSettingsRepositoryProvider)
                    .updateExperienceLevel(s.first);
              },
            ),
            const SizedBox(height: 24),

            // 기본 카드 수
            _SectionTitle('기본 카드 수: ${settings.defaultCardCount}장'),
            Slider(
              value: settings.defaultCardCount.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${settings.defaultCardCount}장',
              onChanged: (v) {
                ref.read(userSettingsRepositoryProvider)
                    .updateDefaultCardCount(v.round());
              },
            ),
            const SizedBox(height: 16),

            // 앞면/뒷면
            SwitchListTile(
              title: const Text('앞면으로 시작'),
              subtitle: const Text('카드를 바로 앞면으로 표시합니다'),
              value: settings.showFaceUp,
              onChanged: (v) {
                ref.read(userSettingsRepositoryProvider)
                    .updateShowFaceUp(v);
              },
            ),

            // 즉시 뽑기 토글
            SwitchListTile(
              title: const Text('앱 시작 시 바로 뽑기'),
              subtitle: const Text('다음 실행부터 설정된 방식으로 자동 카드 뽑기'),
              value: settings.quickDrawEnabled,
              onChanged: (v) {
                ref.read(userSettingsRepositoryProvider)
                    .updateQuickDrawEnabled(v);
              },
            ),
            const SizedBox(height: 16),

            // 기본 스프레드
            _SectionTitle('기본 스프레드'),
            DropdownButtonFormField<SpreadType>(
              value: settings.defaultSpreadType,
              items: SpreadType.values
                  .map((st) => DropdownMenuItem(
                        value: st,
                        child: Text(st.displayName),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(userSettingsRepositoryProvider)
                      .updateDefaultSpreadType(v.name);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
```

**MA-7 반영:**
- `showFaceUp` 토글이 UserSettings에 반영되면, ReadingPage에서 이 값을 읽어 CardRevealWidget의 초기 상태를 결정 (Step 5에서 처리).

**EV-006-D2 반영:**
- 모든 update 호출이 `UserSettingsRepositoryImpl`을 경유하고, DAO에서 `where((s) => s.id.equals(1))`로 항상 단일 행을 대상으로 함. 다중 행이 존재하더라도 id=1만 업데이트.

## Step 3: 리딩 목록 페이지

**신규 파일**: `mobile/lib/features/reading/presentation/pages/reading_list_page.dart`

### UI 구조

```
ReadingListPage (ConsumerStatefulWidget)
├── AppBar: "리딩 기록"
│   └── PopupMenuButton: SpreadType 필터 선택
├── Body:
│   ├── FilterChip row: 전체 / 한 장 / 쓰리 카드 / 자유 선택
│   └── ListView.builder:
│       └── ReadingListTile:
│           ├── Leading: spreadType 아이콘
│           ├── Title: spreadType.displayName + 카드 수
│           ├── Subtitle: question (nullable) + 날짜
│           └── onTap → /readings/:id (리딩 상세)
```

### 코드 스니펫

```dart
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
```

**MA-5 반영:**
- spreadType 기준 FilterChip UI로 그룹핑/필터링.
- `watchReadingsBySpreadTypeProvider` family provider로 DB-level 필터링 (전체 로딩 후 클라이언트 필터가 아닌 쿼리 필터).

## Step 4: 리딩 상세 페이지 — notes 인라인 편집

**신규 파일**: `mobile/lib/features/reading/presentation/pages/reading_detail_page.dart`

### UI 구조

```
ReadingDetailPage (ConsumerStatefulWidget)
├── AppBar: spreadType.displayName + 날짜
├── Body: SingleChildScrollView
│   ├── 질문 표시 (있으면)
│   ├── 카드 목록: ListView (drawn cards + position label + 카드 이름)
│   ├── Divider
│   └── Notes 섹션:
│       ├── TextField (multiline, autofocus: false)
│       ├── debounce 자동 저장 (500ms)
│       └── 저장 상태 표시 ("저장됨" / "저장 중...")
```

### 코드 스니펫

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/reading.dart';
import '../../domain/entities/spread_type.dart';
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
```

**MA-5 반영:**
- `notes` 인라인 편집: `TextField` + 500ms debounce 자동 저장.
- `ReadingRepository.updateNotes()`를 사용하여 해당 필드만 DB 업데이트.
- 저장 상태 UI 피드백 ("저장 중..." / "자동 저장됨" + AppBar 아이콘).

## Step 5: ReadingPage 대폭 수정 — 자동 저장 + "+1 한 장 더" + showFaceUp

**수정 파일**: `mobile/lib/features/reading/presentation/pages/reading_page.dart`

### 변경 목록

1. **자동 저장**: 카드 전부 공개 후 자동으로 Reading을 DB에 저장 (기존 수동 저장 버튼 제거)
2. **"+1 한 장 더" 버튼**: 하단에 FloatingActionButton 추가
3. **`showFaceUp` 적용**: UserSettings의 showFaceUp이 true이면 카드를 처음부터 공개 상태로 표시
4. **`_currentCardCount` 상태 관리**: custom 스프레드의 실제 카드 수 추적
5. **`_savedReadingId`**: 자동 저장 후 reading ID 보존 → "+1" 시 기존 Reading에 카드 추가

### 핵심 상태 모델

```dart
class _ReadingPageState extends ConsumerState<ReadingPage> {
  late SpreadType _spreadType;
  late int _currentCardCount;        // 현재 표시 중인 카드 수
  final Set<int> _revealedPositions = {};
  String? _savedReadingId;           // 자동 저장 후 Reading ID
  bool _autoSaved = false;           // 자동 저장 완료 여부
}
```

### 상세 변경 스니펫

```dart
@override
void initState() {
  super.initState();
  _spreadType = widget.spreadType;
  // EV-006-A1 대응: custom일 때 cardCount 0 sentinel 대신 UserSettings의 defaultCardCount 사용
  // named 스프레드는 정적 cardCount 사용
  _currentCardCount = _spreadType == SpreadType.custom
      ? ref.read(userSettingsProvider).valueOrNull?.defaultCardCount ?? 3
      : _spreadType.cardCount;
}

// ── 자동 저장 (allRevealed 시 1회 실행) ──
void _autoSave(List<ShuffledCard> drawnCards, String question) {
  if (_autoSaved) return;
  _autoSaved = true;

  final readingId = const Uuid().v4();
  _savedReadingId = readingId;

  final reading = Reading(
    id: readingId,
    deckId: widget.deckId,
    spreadType: _spreadType,
    question: question.isNotEmpty ? question : null,
    drawnCards: List.generate(
      drawnCards.length,
      (i) => DrawnCardInfo(
        cardId: drawnCards[i].card.id,
        position: i,
        isReversed: drawnCards[i].isReversed,
      ),
    ),
    createdAt: DateTime.now(),
  );

  ref.read(readingRepositoryProvider).saveReading(reading);
}

// ── "+1 한 장 더" ──
void _addOneMore(ShuffleResult shuffleResult) {
  if (_currentCardCount >= shuffleResult.cards.length) return;

  setState(() => _currentCardCount++);

  // 새 카드가 showFaceUp이면 즉시 reveal
  final showFaceUp =
      ref.read(userSettingsProvider).valueOrNull?.showFaceUp ?? false;
  if (showFaceUp) {
    _revealedPositions.add(_currentCardCount - 1);
  }

  // 이미 자동 저장된 Reading에 카드 추가
  if (_savedReadingId != null) {
    final newCard = shuffleResult.cards[_currentCardCount - 1];
    ref.read(readingRepositoryProvider).addDrawnCard(
          _savedReadingId!,
          DrawnCardInfo(
            cardId: newCard.card.id,
            position: _currentCardCount - 1,
            isReversed: newCard.isReversed,
          ),
          DateTime.now(),
        );
  }
}
```

### showFaceUp 적용

```dart
// initState 또는 build에서:
final showFaceUp =
    ref.watch(userSettingsProvider).valueOrNull?.showFaceUp ?? false;

// showFaceUp이 true이면 모든 카드를 초기 revealed 상태로
if (showFaceUp && _revealedPositions.isEmpty) {
  for (var i = 0; i < _currentCardCount; i++) {
    _revealedPositions.add(i);
  }
}
```

**MA-8 반영:**
- "+1" 버튼은 `FloatingActionButton.extended`로 하단에 상시 표시.
- 탭 시 `_addOneMore()` 호출 → `_currentCardCount++` → `shuffleResult.cards.take(_currentCardCount)` → UI 갱신.
- 버튼 비활성화 조건: `_currentCardCount >= shuffleResult.cards.length`.
- 추가된 카드도 `showFaceUp` 설정을 따름.
- "+1" 후 DB에 `addDrawnCard()`로 즉시 반영.

**MA-5 자동 저장 반영:**
- 기존 `IconButton(icon: Icon(Icons.save))` 제거.
- `allRevealed`이 되는 시점에 `_autoSave()` 1회 실행.
- `_autoSaved` 플래그로 중복 저장 방지.
- Level 1/2 즉시 뽑기에서는 이미 모든 카드가 revealed이므로 build 시점에 즉시 자동 저장.

**EV-006-A1 대응:**
- `SpreadType.custom.cardCount == 0` sentinel을 직접 사용하지 않고, `_currentCardCount`를 `UserSettings.defaultCardCount`로 초기화.
- `drawnCards = shuffleResult.cards.take(_currentCardCount).toList()` — 항상 실제 카드 수 기반.

### build() 메서드 변경 요약

```dart
@override
Widget build(BuildContext context) {
  final shuffleResult = ref.watch(shuffleStateProvider);
  final question = ref.watch(readingQuestionProvider);
  final showFaceUp =
      ref.watch(userSettingsProvider).valueOrNull?.showFaceUp ?? false;

  // ... null check ...

  final drawnCards = shuffleResult.cards.take(_currentCardCount).toList();

  // showFaceUp이면 초기 전부 reveal
  if (showFaceUp && _revealedPositions.length < _currentCardCount) {
    for (var i = 0; i < _currentCardCount; i++) {
      _revealedPositions.add(i);
    }
  }

  final allRevealed = _revealedPositions.length >= _currentCardCount;

  // 자동 저장 트리거
  if (allRevealed) _autoSave(drawnCards, question);

  final hasMoreCards = _currentCardCount < shuffleResult.cards.length;

  return Scaffold(
    appBar: AppBar(
      title: Text(_spreadType.displayName),
      // 저장 버튼 제거됨 — 자동 저장
    ),
    // "+1 한 장 더" FAB
    floatingActionButton: allRevealed && hasMoreCards
        ? FloatingActionButton.extended(
            onPressed: () => _addOneMore(shuffleResult),
            icon: const Icon(Icons.add),
            label: Text('+1 한 장 더 (${shuffleResult.cards.length - _currentCardCount}장 남음)'),
          )
        : null,
    body: SingleChildScrollView(
      // ... 기존 body 구조 유지 ...
    ),
  );
}
```

### _saveReading 메서드 제거

기존 `_saveReading()` 메서드와 AppBar의 저장 버튼을 제거하고, `_autoSave()`로 대체.

## Step 6: 라우터 확장 — 신규 라우트 3개

**수정 파일**: `mobile/lib/core/router/app_router.dart`

추가할 라우트:

```dart
GoRoute(
  path: '/settings',
  name: 'settings',
  pageBuilder: (context, state) =>
      _fadePage(key: state.pageKey, child: const SettingsPage()),
),
GoRoute(
  path: '/readings',
  name: 'readings',
  pageBuilder: (context, state) =>
      _fadePage(key: state.pageKey, child: const ReadingListPage()),
),
GoRoute(
  path: '/readings/:readingId',
  name: 'reading-detail',
  pageBuilder: (context, state) {
    final readingId = state.pathParameters['readingId']!;
    return _fadePage(
        key: state.pageKey,
        child: ReadingDetailPage(readingId: readingId));
  },
),
```

**import 추가:**
```dart
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/reading/presentation/pages/reading_list_page.dart';
import '../../features/reading/presentation/pages/reading_detail_page.dart';
```

**Cycle 3 연결**: 홈 허브 재설계에서 이 라우트들로 네비게이션 연결. 현 사이클에서는 라우트만 등록하고, 홈에서의 진입은 Cycle 3에서 처리.

## Step 7: 코드 생성 + 빌드 검증

```bash
cd mobile && dart run build_runner build --delete-conflicting-outputs
```

영향 받는 생성 파일:
- `reading_dao.g.dart` — 새 메서드 3개 (updateNotes, addDrawnCard, watchReadingsBySpreadType)
- `reading_providers.g.dart` — `watchReadingsBySpreadTypeProvider` family provider 추가
- `app_router.g.dart` — GoRouter 재생성 (라우트 추가에 의한 것은 아니지만 같은 codegen 스코프)

빌드 검증:
```bash
flutter analyze
flutter build apk --debug
```

## 파일 변경 요약

| # | 파일 경로 | 작업 | Step |
|---|----------|------|------|
| 1 | `mobile/lib/core/database/daos/reading_dao.dart` | **MODIFY** — updateNotes, addDrawnCard, watchReadingsBySpreadType 추가 | 1-1 |
| 2 | `mobile/lib/features/reading/domain/repositories/reading_repository.dart` | **MODIFY** — updateNotes, addDrawnCard, watchReadingsBySpreadType, getReadingById 추가 | 1-2 |
| 3 | `mobile/lib/features/reading/data/repositories/reading_repository_impl.dart` | **MODIFY** — 4개 메서드 구현 | 1-3 |
| 4 | `mobile/lib/features/reading/presentation/providers/reading_providers.dart` | **MODIFY** — watchReadingsBySpreadType provider 추가 | 1-4 |
| 5 | `mobile/lib/features/settings/presentation/pages/settings_page.dart` | **NEW** — 설정 페이지 UI | 2 |
| 6 | `mobile/lib/features/reading/presentation/pages/reading_list_page.dart` | **NEW** — 리딩 목록 + 필터 | 3 |
| 7 | `mobile/lib/features/reading/presentation/pages/reading_detail_page.dart` | **NEW** — 리딩 상세 + notes 편집 | 4 |
| 8 | `mobile/lib/features/reading/presentation/pages/reading_page.dart` | **MODIFY** — 자동 저장 + "+1" + showFaceUp | 5 |
| 9 | `mobile/lib/core/router/app_router.dart` | **MODIFY** — 3개 라우트 추가 | 6 |
| 10 | `mobile/lib/features/reading/presentation/widgets/spread_layout.dart` | **MODIFY** — "+1"으로 동적 카드 수 변경 시 SpreadLayout 재빌드 지원 확인 | 5 (확인) |
| 11 | `mobile/lib/features/reading/presentation/widgets/card_reveal_widget.dart` | **MODIFY** (조건부) — showFaceUp 시 초기 revealed 상태 지원 확인 | 5 (확인) |

**신규 4파일**: settings_page.dart, reading_list_page.dart, reading_detail_page.dart (+ reading_providers.g.dart 재생성)

**수정 7파일**: reading_dao.dart, reading_repository.dart, reading_repository_impl.dart, reading_providers.dart, reading_page.dart, app_router.dart, (spread_layout.dart — 기능 추가 없이 동작 확인)

## 실행 순서 체크리스트

구현 에이전트가 아래 순서대로 실행한다. 각 항목은 이전 항목의 완료를 전제로 한다.

- [ ] **1-1**: `reading_dao.dart` 수정 — updateNotes, addDrawnCard, watchReadingsBySpreadType 추가
- [ ] **1-2**: `reading_repository.dart` 수정 — 인터페이스에 4개 메서드 추가
- [ ] **1-3**: `reading_repository_impl.dart` 수정 — 4개 메서드 구현
- [ ] **1-4**: `reading_providers.dart` 수정 — watchReadingsBySpreadType provider 추가
- [ ] **2**: `settings_page.dart` 생성 — 설정 페이지 UI
- [ ] **3**: `reading_list_page.dart` 생성 — 리딩 목록 + 필터
- [ ] **4**: `reading_detail_page.dart` 생성 — 리딩 상세 + notes 인라인 편집
- [ ] **5**: `reading_page.dart` 수정 — 자동 저장 + "+1" 버튼 + showFaceUp 적용
- [ ] **6**: `app_router.dart` 수정 — /settings, /readings, /readings/:readingId 라우트 추가
- [ ] **7**: `dart run build_runner build --delete-conflicting-outputs`
- [ ] **8**: 빌드 검증 (`flutter analyze` + `flutter build apk --debug`)

## 검증 기준

| # | 기준 | 검증 방법 |
|---|------|----------|
| 1 | 설정 페이지에서 모든 항목(덱, 레벨, 카드 수, 앞면/뒷면, 즉시 뽑기, 스프레드) 변경 가능 | 설정 변경 후 DB 확인 또는 재진입 시 값 유지 |
| 2 | 리딩 목록에서 spreadType 필터 동작 | FilterChip 선택 시 해당 유형만 표시 |
| 3 | 리딩 상세에서 notes 인라인 편집 + 자동 저장 | TextField 입력 → 500ms 후 DB 반영 확인 |
| 4 | ReadingPage에서 모든 카드 공개 시 자동 저장 | 수동 저장 버튼 없이 DB에 Reading 행 INSERT 확인 |
| 5 | "+1 한 장 더" 버튼 동작 | allRevealed 후 FAB 탭 → 카드 추가 → DB DrawnCards 행 추가 확인 |
| 6 | "+1" 후 남은 카드 수 표시 + 0장 시 비활성화 | FAB label의 카운트 갱신 + disabled 상태 확인 |
| 7 | showFaceUp 설정 적용 | 설정에서 true → ReadingPage 진입 시 카드 앞면으로 표시 |
| 8 | 신규 라우트 3개 접근 가능 | /settings, /readings, /readings/:id 네비게이션 정상 |
| 9 | 코드 생성 성공 | `build_runner build` 에러 없음 |
| 10 | 기존 기능 회귀 없음 | 기존 reading/shuffle 흐름 정상 동작 |

## Cycle 3 인계 사항

이 사이클에서 생성한 산출물 중 Cycle 3(홈 허브 + 뽑기 체험)가 직접 사용할 항목:

1. **`/settings` 라우트** — 홈 허브에서 설정 페이지로 네비게이션 연결
2. **`/readings` 라우트** — 홈 허브에서 리딩 기록 페이지로 네비게이션 연결
3. **`/readings/:readingId` 라우트** — 리딩 목록에서 상세로 이동
4. **자동 저장 로직** — Level 1/2 즉시 뽑기 경로에서 build 시점에 즉시 자동 저장
5. **showFaceUp 적용** — Level 1/2에서 `showFaceUp: true` 기본 적용 가능 (라우터에서 설정값 전달)
6. **ReadingPage의 `_currentCardCount`** — Level 1에서 `UserSettings.defaultCardCount`로 초기화되므로, 즉시 뽑기 시 설정된 장수만큼 표시

## 리스크

| # | 리스크 | 완화 |
|---|--------|------|
| 1 | `_autoSave`가 build에서 호출되므로 중복 호출 가능 | `_autoSaved` 플래그로 1회 제한. `setState` 후 rebuild 시에도 재실행 안 됨 |
| 2 | "+1" 시 SpreadLayout 재빌드 성능 | `_buildGenericGridLayout`의 GridView가 shrinkWrap + NeverScrollable이므로 전체 재빌드. 10장 이내 카드에서는 성능 문제 없음 |
| 3 | notes 자동 저장 debounce 중 페이지 이탈 | `dispose()`에서 `_debounce?.cancel()`. 미저장 텍스트는 손실될 수 있으나, 500ms 이내의 타이핑만 해당. 향후 `WillPopScope`로 경고 추가 가능 |
| 4 | `readingsAsync`에서 전체 리딩 로딩 후 `where`로 ID 검색 | ReadingDetailPage가 `watchReadingsProvider`를 watch하는 현 구조. 최적화로 `getReadingById` provider를 별도 추가할 수 있으나, 리딩 수가 적은 현 단계에서는 불필요 |
| 5 | `ref.read(userSettingsProvider).valueOrNull` initState에서 null 가능 | fallback 기본값 3 적용. Provider 로딩 완료 전에는 3장으로 시작, 이후 build에서 watch로 갱신 |

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 19s | 76045 |
| 3 | user-ai-exchange | 11s | 40778 |
| 4 | user-ai-exchange | 10s | 42195 |
| 5 | user-ai-exchange | 9s | 44183 |
| 6 | user-ai-exchange | 14s | 46529 |
| 7 | user-ai-exchange | 5s | 48356 |
| 8 | user-ai-exchange | 9s | 50568 |
| 9 | user-ai-exchange | 13s | 105037 |
| 10 | user-ai-exchange | 12s | 54453 |
| 11 | user-ai-exchange | 11s | 55874 |
| 12 | user-ai-exchange | 12s | 57359 |
| 13 | user-ai-exchange | 14s | 58996 |
| 14 | user-ai-exchange | 13s | 60582 |
| 15 | user-ai-exchange | 8s | 61831 |
| 16 | user-ai-exchange | 11s | 63033 |
| 17 | user-ai-exchange | 29s | 202688 |
| 18 | user-ai-exchange | 11s | 140060 |
| 19 | user-ai-exchange | 11s | 71985 |
| 20 | user-ai-exchange | 9s | 147944 |
| 21 | user-ai-exchange | 14s | 76148 |
| 22 | user-ai-exchange | 19s | 0 |
| 23 | user-ai-exchange | 10s | 41780 |
| 24 | user-ai-exchange | 13s | 45110 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 341150s |
| Total Tokens | 1591534 |
| Input Tokens | 71 |
| Output Tokens | 8834 |
| Cache Read | 1202235 |
| Cache Creation | 380394 |
