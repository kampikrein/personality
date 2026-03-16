// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shuffle_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShuffleConfigImpl _$$ShuffleConfigImplFromJson(Map<String, dynamic> json) =>
    _$ShuffleConfigImpl(
      shuffleCount: (json['shuffleCount'] as num?)?.toInt() ?? 3,
      useReversals: json['useReversals'] as bool? ?? true,
      reversalProbability:
          (json['reversalProbability'] as num?)?.toDouble() ?? 0.5,
    );

Map<String, dynamic> _$$ShuffleConfigImplToJson(_$ShuffleConfigImpl instance) =>
    <String, dynamic>{
      'shuffleCount': instance.shuffleCount,
      'useReversals': instance.useReversals,
      'reversalProbability': instance.reversalProbability,
    };
