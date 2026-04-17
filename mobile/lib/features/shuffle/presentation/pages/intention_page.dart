import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/dev_tuner/tunable_var.dart';
import '../../../../core/dev_tuner/tuner_registry.dart';
import '../../../../core/widgets/mystical_scaffold.dart';
import '../../domain/entities/shuffle_mode.dart';

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
  const IntentionPage({
    super.key,
    required this.deckId,
    this.mode = ShuffleMode.perspective,
  });
  final String deckId;
  final ShuffleMode mode;

  @override
  ConsumerState<IntentionPage> createState() => _IntentionPageState();
}

class _IntentionPageState extends ConsumerState<IntentionPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    if (kDebugMode) {
      ref.read(devTunerRegistryProvider).registerIfAbsent('intention', [
        TunableDouble(label: 'iconSize', provider: intentionIconSizeProvider, min: 32, max: 72, step: 4),
        TunableDouble(label: 'padding', provider: intentionPaddingProvider, min: 12, max: 48, step: 4),
      ]);
    }
    final iconSize = ref.watch(intentionIconSizeProvider);
    final contentPadding = ref.watch(intentionPaddingProvider);

    return MysticalScaffold(
      title: '의도 설정',
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // ── 미스틱 아이콘 ──
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kDeepPurple.withValues(alpha: 0.8),
                    border: Border.all(color: kGold.withValues(alpha: 0.4), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: kGold.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.self_improvement,
                    color: kGold,
                    size: iconSize,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── 안내 텍스트 ──
              const Text(
                '잠시 눈을 감고\n마음속 질문을 떠올려보세요.',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  height: 1.6,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── 질문 입력 ──
              MysticalCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GoldSectionTitle('질문 / 의도', icon: Icons.edit_outlined),
                    TextField(
                      controller: _controller,
                      decoration: mysticalInputDecoration(
                        hintText: '질문이나 의도를 적어보세요 (선택)',
                      ),
                      style: const TextStyle(color: kTextPrimary, fontSize: 15),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Text(
                '질문 없이 진행해도 괜찮습니다.\n열린 마음으로 카드를 만나보세요.',
                style: TextStyle(
                  color: kTextSecondary.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── 셔플 이동 버튼 ──
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGold,
                    foregroundColor: kDarkSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    ref.read(readingQuestionProvider.notifier).set(_controller.text);
                    context.pushNamed(
                      'shuffle',
                      pathParameters: {'deckId': widget.deckId},
                      queryParameters: {'mode': widget.mode.code},
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shuffle_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('셔플로 이동', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
