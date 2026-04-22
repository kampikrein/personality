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
