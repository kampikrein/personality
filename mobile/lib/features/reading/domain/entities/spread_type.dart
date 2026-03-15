enum SpreadType {
  single(
    displayName: '한 장 뽑기',
    cardCount: 1,
    positions: ['현재'],
  ),
  threeCard(
    displayName: '쓰리 카드',
    cardCount: 3,
    positions: ['과거', '현재', '미래'],
  );

  const SpreadType({
    required this.displayName,
    required this.cardCount,
    required this.positions,
  });

  final String displayName;
  final int cardCount;
  final List<String> positions;
}
