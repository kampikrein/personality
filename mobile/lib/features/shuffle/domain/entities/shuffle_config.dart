import 'package:freezed_annotation/freezed_annotation.dart';

part 'shuffle_config.freezed.dart';
part 'shuffle_config.g.dart';

@freezed
class ShuffleConfig with _$ShuffleConfig {
  const factory ShuffleConfig({
    @Default(3) int shuffleCount,
    @Default(true) bool useReversals,
    @Default(0.5) double reversalProbability,
  }) = _ShuffleConfig;

  factory ShuffleConfig.fromJson(Map<String, dynamic> json) =>
      _$ShuffleConfigFromJson(json);
}
