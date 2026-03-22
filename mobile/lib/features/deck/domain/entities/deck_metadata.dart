import 'package:freezed_annotation/freezed_annotation.dart';

part 'deck_metadata.freezed.dart';
part 'deck_metadata.g.dart';

/// 덱이 지원하는 뽑기 방식.
/// - freeform: 1~10장 자유 선택 (타로 기본)
/// - namedSpread: 전통 스프레드 유형 선택 (켈틱 크로스 등)
/// - hexagram: I Ching 6효 뽑기
enum DrawMode { freeform, namedSpread, hexagram }

@freezed
class DeckMetadata with _$DeckMetadata {
  const factory DeckMetadata({
    required String id,
    required String name,
    @Default(true) bool isStandardTarot,
    required int totalCards,
    String? creator,
    @Default([DrawMode.freeform, DrawMode.namedSpread])
    List<DrawMode> supportedDrawModes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DeckMetadata;

  factory DeckMetadata.fromJson(Map<String, dynamic> json) =>
      _$DeckMetadataFromJson(json);
}
