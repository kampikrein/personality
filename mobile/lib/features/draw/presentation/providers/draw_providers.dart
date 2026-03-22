import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/deck/presentation/providers/deck_providers.dart';
import '../../../../features/shuffle/presentation/providers/shuffle_providers.dart';
import '../../../../features/shuffle/domain/entities/shuffle_result.dart';
import '../../../../features/settings/presentation/providers/settings_providers.dart';
import '../../../../features/settings/domain/entities/user_settings.dart';

part 'draw_providers.g.dart';

/// Level 1/2 뽑기에서 사용할 셔플 실행 use case.
/// 호출 시 UserSettings의 selectedDeckId를 사용하여 셔플하고,
/// ShuffleState에 결과를 세팅한 뒤 ShuffleResult를 반환.
@riverpod
Future<ShuffleResult> executeDraw(ExecuteDrawRef ref) async {
  final settings = ref.read(userSettingsProvider).valueOrNull ??
      UserSettings(updatedAt: DateTime.now());

  final deckId = settings.selectedDeckId;
  final cards = await ref.read(deckCardsProvider(deckId).future);

  final useCase = ref.read(shuffleDeckUseCaseProvider);
  final strategy = ref.read(shuffleStrategyProvider);
  final result = useCase.execute(cards: cards, strategy: strategy);

  ref.read(shuffleStateProvider.notifier).setResult(result);

  return result;
}
