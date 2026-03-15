import 'package:freezed_annotation/freezed_annotation.dart';

part 'deck_metadata.freezed.dart';
part 'deck_metadata.g.dart';

@freezed
class DeckMetadata with _$DeckMetadata {
  const factory DeckMetadata({
    required String id,
    required String name,
    @Default(true) bool isStandardTarot,
    required int totalCards,
    String? creator,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DeckMetadata;

  factory DeckMetadata.fromJson(Map<String, dynamic> json) =>
      _$DeckMetadataFromJson(json);
}
