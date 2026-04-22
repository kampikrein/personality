import 'package:json_annotation/json_annotation.dart';

/// 뽑기 플로우에서 의도(질문) 입력이 나타나는 시점.
///
/// - [beforeShuffle]: 셔플 전 IntentionPage를 통과 (기존 동작, 기본값).
/// - [afterDraw]: deck 선택 후 shuffle로 직행, 결과 화면에서 입력.
/// - [disabled]: 의도 입력 없이 진행, reading.question = null.
///
/// JSON 직렬화 key는 enum 이름 그대로 (camelCase): "beforeShuffle", "afterDraw", "disabled".
@JsonEnum()
enum IntentPlacement {
  beforeShuffle,
  afterDraw,
  disabled;
}

/// UI 표시 문자열 헬퍼. enum 파일에 co-locate하여 import 최소화.
extension IntentPlacementLabel on IntentPlacement {
  /// 설정 페이지 목록에 표시하는 전체 라벨.
  String get displayLabel => switch (this) {
        IntentPlacement.beforeShuffle => '뽑기 전 입력',
        IntentPlacement.afterDraw => '뽑은 후 입력',
        IntentPlacement.disabled => '의도 입력 비활성',
      };

  /// HomePage 패널의 좁은 공간용 단축 라벨.
  String get shortLabel => switch (this) {
        IntentPlacement.beforeShuffle => '뽑기 전',
        IntentPlacement.afterDraw => '뽑은 후',
        IntentPlacement.disabled => '비활성',
      };

  /// 설정 페이지 목록에서 옵션 설명으로 표시할 1줄 문장.
  String get description => switch (this) {
        IntentPlacement.beforeShuffle => '셔플 전에 의도/질문을 정리합니다',
        IntentPlacement.afterDraw => '카드를 먼저 보고 떠오른 질문을 적습니다',
        IntentPlacement.disabled => '의도 입력 없이 빠르게 진행합니다',
      };
}
