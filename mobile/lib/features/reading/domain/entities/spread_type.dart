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
