import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/dev_tuner/tunable_var.dart';
import '../../../../core/dev_tuner/tuner_registry.dart';

part 'intention_page.g.dart';

// ── Dev Tuner 변수 ──
final intentionIconSizeProvider = StateProvider<double>((ref) => 48);
final intentionPaddingProvider = StateProvider<double>((ref) => 24);

@Riverpod(keepAlive: true)
class ReadingQuestion extends _$ReadingQuestion {
  @override
  String build() => '';

  void set(String question) => state = question;
  void clear() => state = '';
}

class IntentionPage extends ConsumerStatefulWidget {
  const IntentionPage({super.key, required this.deckId});
  final String deckId;

  @override
  ConsumerState<IntentionPage> createState() => _IntentionPageState();
}

class _IntentionPageState extends ConsumerState<IntentionPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 새 리딩 시작 시 이전 질문 초기화.
    // addPostFrameCallback 사용: initState 내에서 ref.read 호출 가능하나
    // provider 알림이 build 완료 후 안전하게 전파되도록 한다.
    // shuffleStateProvider.clear()는 여기서 금지 — DrawResultPage가 상류(shuffleStateProvider)의
    // 결과를 소비하므로 IntentionPage가 결과를 비워선 안 된다 (Brief MA-3).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(readingQuestionProvider.notifier).clear();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (kDebugMode) {
      ref.read(devTunerRegistryProvider).registerIfAbsent('intention', [
        TunableDouble(label: 'iconSize', provider: intentionIconSizeProvider, min: 32, max: 72, step: 4),
        TunableDouble(label: 'padding', provider: intentionPaddingProvider, min: 12, max: 48, step: 4),
      ]);
    }
    final iconSize = ref.watch(intentionIconSizeProvider);
    final contentPadding = ref.watch(intentionPaddingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('의도 설정')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(Icons.self_improvement,
                color: theme.colorScheme.primary, size: iconSize),
            const SizedBox(height: 16),
            Text(
              '잠시 눈을 감고\n마음속 질문을 떠올려보세요.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '질문이나 의도를 적어보세요 (선택)',
                hintStyle: TextStyle(color: theme.colorScheme.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.secondary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.secondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              style: theme.textTheme.bodyLarge,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Text(
              '질문 없이 진행해도 괜찮습니다.\n열린 마음으로 카드를 만나보세요.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ref
                      .read(readingQuestionProvider.notifier)
                      .set(_controller.text);
                  context.pushNamed(
                    'shuffle',
                    pathParameters: {'deckId': widget.deckId},
                  );
                },
                child:
                    const Text('셔플로 이동', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
