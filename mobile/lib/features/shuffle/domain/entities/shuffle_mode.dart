/// 셔플 화면의 시각 모드.
///
/// - [flat] 2D: Flame 게임 위에 원근 변환 없이 평면 렌더.
///   카메라 제스처(회전/줌) 비활성. 입문자/접근성 우선.
/// - [perspective] 2.5D: Matrix4 원근 + rotateX/rotateY Transform 적용.
///   제스처로 카메라 회전·줌 가능. 시각 몰입 우선.
enum ShuffleMode {
  flat('2d', '2D'),
  perspective('2.5d', '2.5D');

  const ShuffleMode(this.code, this.label);

  /// URL query 파라미터 값 (예: '2d', '2.5d').
  final String code;

  /// UI 라벨.
  final String label;

  /// query 문자열에서 모드 복원. 매칭 실패 시 [perspective] (기존 기본 동작).
  static ShuffleMode fromCode(String? code) {
    for (final m in ShuffleMode.values) {
      if (m.code == code) return m;
    }
    return ShuffleMode.perspective;
  }
}
