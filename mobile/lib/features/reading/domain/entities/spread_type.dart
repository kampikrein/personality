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
  ),
  custom(
    displayName: '자유 선택',
    cardCount: 0,
    positions: [],
    guidances: [],
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

  /// custom 스프레드에서 동적 positions 생성.
  /// named 스프레드(single, threeCard)는 정적 positions 반환.
  List<String> resolvePositions(int actualCardCount) {
    if (this != SpreadType.custom) return positions;
    return List.generate(actualCardCount, (i) => '카드 ${i + 1}');
  }

  /// custom 스프레드에서 동적 guidances 생성.
  List<String> resolveGuidances(int actualCardCount) {
    if (this != SpreadType.custom) return guidances;
    return List.generate(
      actualCardCount,
      (i) => '${i + 1}번째 카드가 전하는 메시지입니다.',
    );
  }
}
