---
id: "027"
type: plan
title: "Cycle 2 — 제의적 경험 레이어"
created: 2026-03-16
traces_scope: "025"
summary: >
  비평 보고서 공통 발견 "제의적 스캐폴딩 부재" 해결. 의도 설정 화면, 반성 질문 시스템,
  스프레드 포지션 해석 가이드, 홈 앰비언스, 셔플 절정 시각 표현을 추가하여
  "카드 뷰어"에서 "의식 가이드"로 전환.
keywords: [ritual-layer, intention, reflective-prompts, ambience, cycle-2]
---

# 027 — Cycle 2: 제의적 경험 레이어

## Goal

4개 에이전트 공통 발견 — "제의적 스캐폴딩 부재"를 해결. 의도 설정→셔플→리딩→성찰의 완전한 의식 흐름 구현. 확증 편향 완화(반성 질문)와 운명론 완화(포지션 라벨 재설계)를 동시에 달성.

## Scope

### Included
| # | Item | Source |
|---|------|--------|
| 1 | 스프레드 포지션 해석 가이드 + 라벨 재설계 | 015 타로 [Major] + 016 심리학 |
| 2 | 반성 질문 데이터 (카드 아케타입별) | 016 심리학 [Critical] |
| 3 | 의도 설정 화면 (셔플 전) | 015 타로 [Critical] + 017 Synthesis |
| 4 | 리딩 화면 반성 질문 표시 | 016 심리학 [Critical] |
| 5 | 홈 화면 앰비언스 (RadialGradient) | 014 UX [Critical] |
| 6 | 셔플 절정 시각 표현 | 014 UX [High] |
| 7 | 라우팅 업데이트 (/intention) | 구조 |

### Excluded
| Item | Reason |
|------|--------|
| 5장/켈틱 크로스 스프레드 | Phase 2+ |
| 카드별 상세 해석 문장 | Phase 2+ |
| 저널링/기록 기능 | Phase 2+ |

## Structural Decisions

> No structural decisions required — critique reports provide clear direction.

---

## File Change Summary

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| 1 | mobile/lib/features/reading/domain/entities/reflective_prompts.dart | 아케타입별 반성 질문 |
| 2 | mobile/lib/features/shuffle/presentation/pages/intention_page.dart | 의도 설정 화면 |

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | mobile/lib/features/reading/domain/entities/spread_type.dart | 포지션 해석 가이드 + '미래'→'가능성' |
| 2 | mobile/lib/features/reading/presentation/pages/reading_page.dart | 반성 질문 표시 |
| 3 | mobile/lib/features/home/presentation/pages/home_page.dart | RadialGradient 앰비언스 |
| 4 | mobile/lib/features/shuffle/presentation/pages/shuffle_page.dart | 셔플 절정 표현 + 의도 전달 |
| 5 | mobile/lib/core/router/app_router.dart | /intention 라우트 추가 |

---

## Step 1 — spread_type.dart: 포지션 해석 가이드 + 라벨 재설계

### Approach
Enhanced enum에 포지션별 해석 가이드(`guidance`) 추가. '미래'를 '가능성'으로 변경하여 운명론 완화(Dweck, 2006).

### After Code
```dart
// mobile/lib/features/reading/domain/entities/spread_type.dart
enum SpreadType {
  single(
    displayName: '한 장 뽑기',
    cardCount: 1,
    positions: ['현재'],
    guidances: ['지금 이 순간 당신에게 가장 필요한 메시지입니다.'],
  ),
  threeCard(
    displayName: '쓰리 카드',
    cardCount: 3,
    positions: ['지나온 길', '현재', '가능성'],
    guidances: [
      '지금까지 당신에게 영향을 준 에너지입니다.',
      '현재 당신을 둘러싼 흐름입니다.',
      '이 방향으로 에너지가 흐르고 있습니다. 가능성이지 운명이 아닙니다.',
    ],
  );

  const SpreadType({
    required this.displayName,
    required this.cardCount,
    required this.positions,
    required this.guidances,
  });

  final String displayName;
  final int cardCount;
  final List<String> positions;
  final List<String> guidances;
}
```

---

## Step 2 — reflective_prompts.dart: 카드별 반성 질문

### Approach
Major Arcana 아케타입별 + Minor suit별 반성 질문. 확증 편향 완화를 위해 개방형 질문 사용(Arkes, 1991).

### After Code
```dart
// mobile/lib/features/reading/domain/entities/reflective_prompts.dart (new)

/// 카드 아케타입에 기반한 반성 질문.
/// 확증 편향 완화를 위해 개방형으로 설계 (Arkes, 1991).
class ReflectivePrompts {
  ReflectivePrompts._();

  static String getPrompt(String cardId) {
    // Major Arcana별 질문
    final majorPrompts = {
      'major-00': '지금 당신의 삶에서 새롭게 시작하고 싶은 것은 무엇인가요?',
      'major-01': '당신이 가진 재능 중 아직 활용하지 못한 것이 있나요?',
      'major-02': '당신의 직관이 말하고 있지만 무시하고 있는 것은 무엇인가요?',
      'major-03': '최근 당신이 돌보고 키우고 있는 것은 무엇인가요?',
      'major-04': '지금 당신에게 더 필요한 것은 구조인가요, 자유인가요?',
      'major-05': '당신이 따르고 있는 전통이나 관습 중 재고할 것이 있나요?',
      'major-06': '지금 당신 앞에 놓인 선택에서 마음이 향하는 방향은 어디인가요?',
      'major-07': '어떤 목표를 향해 전진하고 있나요? 그 동력은 무엇인가요?',
      'major-08': '지금 당신에게 진정한 용기가 필요한 상황은 무엇인가요?',
      'major-09': '혼자만의 시간이 당신에게 어떤 의미인가요?',
      'major-10': '최근 당신의 삶에서 변화하고 있는 순환은 무엇인가요?',
      'major-11': '지금 당신에게 공정하게 다뤄지지 않고 있다고 느끼는 것이 있나요?',
      'major-12': '다른 관점에서 바라보면 달라지는 것이 있나요?',
      'major-13': '놓아줄 준비가 된 것은 무엇인가요?',
      'major-14': '당신의 삶에서 균형이 필요한 영역은 어디인가요?',
      'major-15': '당신을 묶고 있다고 느끼는 것은 무엇인가요? 그것은 진짜인가요?',
      'major-16': '최근 흔들린 경험이 당신에게 어떤 성장을 가져왔나요?',
      'major-17': '지금 당신에게 희망을 주는 것은 무엇인가요?',
      'major-18': '불확실함 속에서도 믿고 있는 것은 무엇인가요?',
      'major-19': '당신이 가장 생기 넘치는 순간은 언제인가요?',
      'major-20': '과거의 결정 중 다시 돌아보고 싶은 것이 있나요?',
      'major-21': '지금까지의 여정에서 가장 감사한 것은 무엇인가요?',
    };

    // Minor suit별 기본 질문
    final suitPrompts = {
      'wands': '당신의 열정과 창조적 에너지는 지금 어디로 향하고 있나요?',
      'cups': '지금 당신의 감정이 말하고 있는 것은 무엇인가요?',
      'swords': '당신의 생각 중 정리가 필요한 것은 무엇인가요?',
      'pentacles': '당신의 일상에서 더 돌봐야 할 실질적인 영역은 무엇인가요?',
    };

    if (majorPrompts.containsKey(cardId)) {
      return majorPrompts[cardId]!;
    }

    // Minor: suit 추출
    final suit = cardId.split('-').first;
    return suitPrompts[suit] ?? '이 카드가 지금 당신에게 전하는 메시지는 무엇이라 느끼시나요?';
  }
}
```

---

## Step 3 — intention_page.dart: 의도 설정 화면

### Approach
셔플 전 질문/의도를 설정하는 화면. 간결한 텍스트 입력 + 명상 안내. Riverpod StateProvider로 질문을 저장하여 리딩 화면에서 참조.

### After Code
```dart
// mobile/lib/features/shuffle/presentation/pages/intention_page.dart (new)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'intention_page.g.dart';

@Riverpod(keepAlive: true)
class ReadingQuestion extends _$ReadingQuestion {
  @override
  String build() => '';

  void set(String question) => state = question;
  void clear() => state = '';
}

class IntentionPage extends ConsumerStatefulWidget {
  const IntentionPage({super.key, required this.deckId});
  final String deckId;

  @override
  ConsumerState<IntentionPage> createState() => _IntentionPageState();
}

class _IntentionPageState extends ConsumerState<IntentionPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('의도 설정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(Icons.self_improvement,
                color: theme.colorScheme.primary, size: 48),
            const SizedBox(height: 16),
            Text(
              '잠시 눈을 감고\n마음속 질문을 떠올려보세요.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '질문이나 의도를 적어보세요 (선택)',
                hintStyle: TextStyle(color: theme.colorScheme.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.secondary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.secondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              style: theme.textTheme.bodyLarge,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Text(
              '질문 없이 진행해도 괜찮습니다.\n열린 마음으로 카드를 만나보세요.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(readingQuestionProvider.notifier)
                      .set(_controller.text);
                  context.pushNamed(
                    'shuffle',
                    pathParameters: {'deckId': widget.deckId},
                  );
                },
                child: const Text('셔플로 이동', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Step 4 — app_router.dart: /intention 라우트 추가

### Approach
덱 선택 후 바로 셔플이 아닌 의도 설정 화면을 거치도록 경로 추가. 덱 선택 화면에서 `/intention/:deckId`로 이동.

### After Code (추가 라우트)
```dart
GoRoute(
  path: '/intention/:deckId',
  name: 'intention',
  pageBuilder: (context, state) {
    final deckId = state.pathParameters['deckId']!;
    return _fadePage(
        key: state.pageKey, child: IntentionPage(deckId: deckId));
  },
),
```

import 추가: `import '../../features/shuffle/presentation/pages/intention_page.dart';`

---

## Step 5 — deck_selection_page.dart: 라우팅 변경

### Approach
덱 선택 시 `shuffle` 대신 `intention`으로 네비게이션 변경.

### Current Code
```dart
context.pushNamed('shuffle', pathParameters: {'deckId': deck.id});
```

### After Code
```dart
context.pushNamed('intention', pathParameters: {'deckId': deck.id});
```

---

## Step 6 — home_page.dart: RadialGradient 앰비언스

### Approach
단색 배경을 RadialGradient로 교체. 중앙에서 바깥으로 퍼지는 딥 퍼플 그라디언트. 상단에 달/별 아이콘 추가.

### After Code (build 부분)
```dart
return Scaffold(
  body: Container(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -0.3),
        radius: 1.2,
        colors: [Color(0xFF2A1B3D), Color(0xFF0D0A14)],
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Icon(Icons.nights_stay,
                color: theme.colorScheme.primary, size: 40),
            const SizedBox(height: 8),
            Text('Personality Tarot',
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // ... 나머지 동일
          ],
        ),
      ),
    ),
  ),
);
```

AppBar 제거 → Container + SafeArea로 교체하여 그라디언트가 상단까지 확장.

---

## Step 7 — shuffle_page.dart: 셔플 절정 시각 표현

### Approach
"셔플 중..." 텍스트를 애니메이션 심볼 + 안내 문구로 교체.

### Current Code
```dart
ShufflePhase.shuffling =>
  const Center(child: Text('셔플 중...')),
```

### After Code
```dart
ShufflePhase.shuffling => Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: theme.colorScheme.primary,
      ),
    ),
    const SizedBox(height: 12),
    Text('카드가 당신의 에너지에 응답하고 있습니다...',
        style: theme.textTheme.bodyMedium,
        textAlign: TextAlign.center),
  ],
),
```

---

## Step 8 — reading_page.dart: 반성 질문 표시

### Approach
카드 공개 후 해당 카드의 반성 질문을 하단에 표시. 포지션별 해석 가이드도 함께. 질문이 설정되었으면 상단에 표시.

### After Code (핵심 변경)
reading_page.dart에서:
- import `reflective_prompts.dart` + `intention_page.dart`
- 질문이 있으면 AppBar subtitle에 표시
- 모든 카드 공개 시 반성 질문 + 포지션 가이드 표시 영역 추가

```dart
// 카드 공개 완료 후 표시할 반성 질문
if (_revealedPositions.length == _spreadType.cardCount) ...[
  const SizedBox(height: 16),
  for (var i = 0; i < drawnCards.length; i++) ...[
    Text(
      '${_spreadType.positions[i]}: ${_spreadType.guidances[i]}',
      style: TextStyle(
        color: theme.colorScheme.secondary,
        fontSize: 12,
        fontStyle: FontStyle.italic,
      ),
    ),
    const SizedBox(height: 4),
    Text(
      ReflectivePrompts.getPrompt(drawnCards[i].card.cardId),
      style: theme.textTheme.bodyMedium,
    ),
    const SizedBox(height: 12),
  ],
],
```

---

## Considerations & Trade-offs

### Alternative Approaches
- 반성 질문을 서버 API에서 동적 제공: 향후 Phase 3에서 고려. MVP는 정적 데이터
- 의도 설정을 필수로 강제: 선택적으로 유지하여 사용자 마찰 최소화

### Potential Risks
- SpreadType에 `guidances` 필드 추가 시 기존 코드에서 컴파일 에러 (위치 명시 필요)
- intention_page의 Provider가 build_runner 코드 생성 필요
- home_page AppBar 제거 시 뒤로 가기 동작 확인 필요 (홈은 루트이므로 문제 없음)

## Implementation Checklist

- [ ] Step 1: spread_type.dart 포지션 가이드 + 라벨 재설계
- [ ] Step 2: reflective_prompts.dart 반성 질문 데이터
- [ ] Step 3: intention_page.dart 의도 설정 화면
- [ ] Step 4: app_router.dart /intention 라우트
- [ ] Step 5: deck_selection_page.dart 라우팅 변경
- [ ] Step 6: home_page.dart RadialGradient 앰비언스
- [ ] Step 7: shuffle_page.dart 셔플 절정 표현
- [ ] Step 8: reading_page.dart 반성 질문 표시
- [ ] build_runner 재생성
- [ ] flutter analyze 0 이슈 확인
- [ ] Final verification

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L1-Build | flutter analyze 통과 | `flutter analyze` | 0 이슈 |
| L1-Build | build_runner 성공 | `dart run build_runner build` | 에러 없음 |

## References

| Resource | Path | Related Content |
|----------|------|-----------------|
| Synthesis | docs/11_tarot_shuffle/017_Synthesis_mvp_critique.md | 공통 발견: 제의적 스캐폴딩 |
| 타로 비평 | docs/11_tarot_shuffle/015_Agent_tarot_critique.md | 질문 설정, 스프레드 의미 |
| 심리학 비평 | docs/11_tarot_shuffle/016_Agent_psychology_critique.md | 반성 질문, 운명론 완화 |
| UX 비평 | docs/11_tarot_shuffle/014_Agent_ux_critique.md | 앰비언스, 절정 표현 |
| Scope | docs/11_tarot_shuffle/025_Scope_critique_improvements.md | Cycle 2 정의 |
