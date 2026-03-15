import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_meanings.freezed.dart';
part 'card_meanings.g.dart';

@freezed
class CardMeanings with _$CardMeanings {
  const factory CardMeanings({
    @Default([]) List<String> upright,
    @Default([]) List<String> reversed,
    String? customNotes,
  }) = _CardMeanings;

  factory CardMeanings.fromJson(Map<String, dynamic> json) =>
      _$CardMeaningsFromJson(json);
}
