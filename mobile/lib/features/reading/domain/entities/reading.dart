import 'package:freezed_annotation/freezed_annotation.dart';

import 'layout_type.dart';

part 'reading.freezed.dart';
part 'reading.g.dart';

@freezed
class Reading with _$Reading {
  const factory Reading({
    required String id,
    required String deckId,
    required LayoutType spreadType,
    String? question,
    String? notes,
    required List<DrawnCardInfo> drawnCards,
    required DateTime createdAt,
  }) = _Reading;

  factory Reading.fromJson(Map<String, dynamic> json) =>
      _$ReadingFromJson(json);
}

@freezed
class DrawnCardInfo with _$DrawnCardInfo {
  const factory DrawnCardInfo({
    required String cardId,
    required int position,
    required bool isReversed,
  }) = _DrawnCardInfo;

  factory DrawnCardInfo.fromJson(Map<String, dynamic> json) =>
      _$DrawnCardInfoFromJson(json);
}
