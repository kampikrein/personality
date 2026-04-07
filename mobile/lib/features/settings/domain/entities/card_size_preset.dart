/// Predefined tarot card size presets based on physical card dimensions.
///
/// The [widthMm] and [heightMm] values represent real-world card sizes.
/// [aspectRatio] (width / height) is what actually drives rendering.
enum CardSizePreset {
  standardTarot(
    label: '표준 타로',
    subtitle: '70 × 120 mm',
    widthMm: 70,
    heightMm: 120,
  ),
  mini(
    label: '미니/포켓',
    subtitle: '44 × 73 mm',
    widthMm: 44,
    heightMm: 73,
  ),
  largeTarot(
    label: '라지 타로',
    subtitle: '89 × 146 mm',
    widthMm: 89,
    heightMm: 146,
  ),
  oracle(
    label: '오라클',
    subtitle: '89 × 127 mm',
    widthMm: 89,
    heightMm: 127,
  ),
  thoth(
    label: 'Thoth',
    subtitle: '73 × 111 mm',
    widthMm: 73,
    heightMm: 111,
  ),
  poker(
    label: '포커',
    subtitle: '63.5 × 89 mm',
    widthMm: 63.5,
    heightMm: 89,
  ),
  custom(
    label: '커스텀',
    subtitle: '직접 입력',
    widthMm: 70,
    heightMm: 120,
  );

  const CardSizePreset({
    required this.label,
    required this.subtitle,
    required this.widthMm,
    required this.heightMm,
  });

  final String label;
  final String subtitle;
  final double widthMm;
  final double heightMm;

  double get aspectRatio => widthMm / heightMm;
}
