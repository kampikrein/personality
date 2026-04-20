/// Reading 레이어용 배치 타입 enhanced enum.
///
/// Brief 011 Model Anchors 의 3 배치 매트릭스 (linear / tShape / grid3x3) 를
/// 런타임 표현으로 제공. drawIndex → slotIndex 매핑, 빈 슬롯 패턴, slotCount
/// 계산, generic `카드 N` positions 를 enum 내부에 포함한다 (Research 007
/// enhanced enum 패턴).
enum LayoutType {
  linear(
    cardCountMin: 1,
    cardCountMax: 10,
    defaultCardCount: 3,
    cardsPerRowOverride: null,
    displayName: '나열',
  ),
  tShape(
    cardCountMin: 4,
    cardCountMax: 10,
    defaultCardCount: 4,
    cardsPerRowOverride: 3,
    displayName: 'T모양',
  ),
  grid3x3(
    cardCountMin: 9,
    cardCountMax: 10,
    defaultCardCount: 9,
    cardsPerRowOverride: 3,
    displayName: '3x3',
  );

  const LayoutType({
    required this.cardCountMin,
    required this.cardCountMax,
    required this.defaultCardCount,
    required this.cardsPerRowOverride,
    required this.displayName,
  });

  final int cardCountMin;
  final int cardCountMax;
  final int defaultCardCount;
  final int? cardsPerRowOverride;
  final String displayName;

  /// drawIndex (뽑은 순서, 0-indexed) 를 레이아웃 상의 slotIndex 로 변환.
  ///
  /// - linear: identity (뽑은 순서 그대로 좌→우 배치)
  /// - tShape: 기본 4장은 가로 3 + 세로 1 (자리 4·6 은 빈 슬롯), 5장째부터는
  ///   drawIndex + 2 로 좌→우 확장
  /// - grid3x3: 기본 9장은 좌 기둥 아래→위 (6,3,0), 우 기둥 아래→위 (8,5,2),
  ///   중앙 기둥 아래→위 (7,4,1). 10장째부터는 단순 좌→우
  int drawToSlot(int drawIndex, int cardCount) {
    return switch (this) {
      LayoutType.linear => drawIndex,
      LayoutType.tShape => switch (drawIndex) {
        0 => 0,
        1 => 1,
        2 => 2,
        3 => 4,
        _ => drawIndex + 2,
      },
      LayoutType.grid3x3 => switch (drawIndex) {
        0 => 6,
        1 => 3,
        2 => 0,
        3 => 8,
        4 => 5,
        5 => 2,
        6 => 7,
        7 => 4,
        8 => 1,
        _ => drawIndex,
      },
    };
  }

  /// 기본 배치에서 카드가 채워지지 않는 슬롯 인덱스 집합 (Brief Model Anchors
  /// "기본 빈 슬롯" 정의).
  ///
  /// cardCount 는 현재 구현에서 사용되지 않지만 시그니처를 유지한다 — 향후
  /// 가변 빈 슬롯 전략 확장 시 API 호환성 보존.
  Set<int> emptySlots(int cardCount) {
    return switch (this) {
      LayoutType.linear => const <int>{},
      LayoutType.tShape => const <int>{3, 5},
      LayoutType.grid3x3 => const <int>{},
    };
  }

  /// 현재 cardCount 에 필요한 총 슬롯 수 (빈 슬롯 포함, 행 단위 올림).
  ///
  /// cells = cardsPerRowOverride ?? 3,
  /// visible = cardCount + emptySlots.length,
  /// slotCount = ceil(visible / cells) * cells.
  int slotCount(int cardCount) {
    final cells = cardsPerRowOverride ?? 3;
    final visible = cardCount + emptySlots(cardCount).length;
    return ((visible + cells - 1) ~/ cells) * cells;
  }

  /// 각 카드 자리에 표시할 라벨. Brief Decision 8 에 따라 전 배치 공통
  /// generic 라벨 (`카드 1`, `카드 2`, ...) 을 반환.
  List<String> resolvePositions(int actualCardCount) {
    return List.generate(actualCardCount, (i) => '카드 ${i + 1}');
  }

  /// 각 자리의 해석 가이드. Brief 011 Out of Scope #4 (guidance 콘텐츠는 별도
  /// cycle) 로 현재 cycle 에서는 빈 리스트 반환. 계약 호환성 유지용 placeholder.
  List<String> resolveGuidances(int actualCardCount) {
    return const <String>[];
  }
}
