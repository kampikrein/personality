import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/spread_type.dart';
import '../../../reading/presentation/providers/reading_providers.dart';
import '../../../settings/domain/entities/user_settings.dart';
import '../../../settings/domain/repositories/user_settings_repository.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../shuffle/domain/entities/shuffle_mode.dart';

// ── 색상 상수 (AppTheme 미러) ──────────────────────────────────
const _gold = Color(0xFFD4A84B);
const _goldLight = Color(0xFFE8C97A);
const _deepPurple = Color(0xFF1A1028);
const _darkSurface = Color(0xFF0D0A14);
const _softPurple = Color(0xFF6B5B95);
const _textPrimary = Color(0xFFE8E0F0);
const _textSecondary = Color(0xFF9B8FB8);

// ── 별 위치 사전 계산 (build 밖, 전역 1회) ────────────────────
final _starPositions = List.generate(90, (i) {
  final rng = math.Random(i * 31 + 7);
  return (
    x: rng.nextDouble(),
    y: rng.nextDouble(),
    r: rng.nextDouble() * 1.3 + 0.25,
    a: rng.nextDouble() * 0.55 + 0.15,
  );
});

// ═══════════════════════════════════════════════════════════════
//  홈 페이지
// ═══════════════════════════════════════════════════════════════
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  bool _initialized = false;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
  }

  Future<void> _initializeApp() async {
    if (_initialized) return;
    await ref.read(deckRepositoryProvider).seedAllDecks();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  void _startDraw(int experienceLevel, String deckId) {
    switch (experienceLevel) {
      case 1:
        context.push('/draw/result');
      case 2:
        context.push('/draw/animated');
      case 3:
        context.pushNamed(
          'intention',
          pathParameters: {'deckId': deckId},
          queryParameters: {'mode': ShuffleMode.flat.code},
        );
      case 4:
        context.pushNamed(
          'intention',
          pathParameters: {'deckId': deckId},
          queryParameters: {'mode': ShuffleMode.perspective.code},
        );
      default:
        context.push('/draw/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final readingsAsync = ref.watch(watchReadingsProvider);
    final decksAsync = ref.watch(watchDecksProvider);
    final size = MediaQuery.sizeOf(context);

    final settings = settingsAsync.valueOrNull;
    final experienceLevel = settings?.experienceLevel ?? 4;
    final selectedDeckId = settings?.selectedDeckId ?? 'rws-standard';

    return Scaffold(
      backgroundColor: _darkSurface,
      body: Stack(
        children: [
          // ── 레이어 0: 별이 있는 미스틱 배경 ──
          const _StarfieldBackground(),

          // ── 레이어 1: 콘텐츠 ──
          SafeArea(
            child: Column(
              children: [
                // 히어로 영역 — 항상 폴드 위에 표시
                SizedBox(
                  height: size.height * 0.44,
                  child: _HeroSection(
                    initialized: _initialized,
                    glowAnim: _glowAnim,
                    onTap: _initialized
                        ? () => _startDraw(experienceLevel, selectedDeckId)
                        : null,
                  ),
                ),

                // 스크롤 가능한 설정 + 최근 리딩
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _GoldHairline(opacity: 0.35),
                        const SizedBox(height: 16),
                        _DrawSettingsPanel(
                          settings: settings,
                          decksAsync: decksAsync,
                        ),
                        const SizedBox(height: 20),
                        _RecentReadingsSection(readingsAsync: readingsAsync),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  별 배경
// ═══════════════════════════════════════════════════════════════
class _StarfieldBackground extends StatelessWidget {
  const _StarfieldBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.1, -0.5),
          radius: 1.5,
          colors: [Color(0xFF2D1F48), Color(0xFF180F2A), _darkSurface],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _StarPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    for (final s in _starPositions) {
      paint.color = Colors.white.withValues(alpha: s.a);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
//  히어로 섹션 (뽑기 버튼)
// ═══════════════════════════════════════════════════════════════
class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.initialized,
    required this.glowAnim,
    required this.onTap,
  });

  final bool initialized;
  final Animation<double> glowAnim;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 앱 이름
        const _AppTitle(),
        const SizedBox(height: 24),
        // 황금 오브 버튼
        _GlowOrb(glowAnim: glowAnim, onTap: onTap),
        const SizedBox(height: 10),
        AnimatedOpacity(
          opacity: initialized ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 600),
          child: const Text(
            '초기화 중...',
            style: TextStyle(color: _textSecondary, fontSize: 11, letterSpacing: 1),
          ),
        ),
      ],
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_gold, _goldLight, _gold],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: const Text(
            'PERSONALITY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 5,
              color: Colors.white, // ShaderMask가 덮어씀
            ),
          ),
        ),
        const Text(
          'TAROT',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: _gold,
            letterSpacing: 9,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.glowAnim, required this.onTap});

  final Animation<double> glowAnim;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnim,
      builder: (context, _) {
        final t = glowAnim.value;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color.lerp(_goldLight, _gold, 0.3 + t * 0.3)!,
                  Color.lerp(_gold, const Color(0xFF7A5510), t * 0.4)!,
                  _deepPurple,
                ],
                stops: const [0.0, 0.52, 1.0],
                radius: 0.82,
              ),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.28 + t * 0.22),
                  blurRadius: 30 + t * 22,
                  spreadRadius: 2 + t * 10,
                ),
                BoxShadow(
                  color: _gold.withValues(alpha: 0.08 + t * 0.08),
                  blurRadius: 70 + t * 40,
                  spreadRadius: 6 + t * 14,
                ),
                BoxShadow(
                  color: _softPurple.withValues(alpha: 0.12 + t * 0.08),
                  blurRadius: 90 + t * 30,
                  spreadRadius: 10 + t * 10,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 38,
                  color: _darkSurface.withValues(alpha: 0.88),
                ),
                const SizedBox(height: 6),
                const Text(
                  '뽑기',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: _darkSurface,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  뽑기 설정 패널
// ═══════════════════════════════════════════════════════════════
class _DrawSettingsPanel extends ConsumerWidget {
  const _DrawSettingsPanel({
    required this.settings,
    required this.decksAsync,
  });

  final UserSettings? settings;
  final AsyncValue decksAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(userSettingsRepositoryProvider);

    return Container(
      decoration: BoxDecoration(
        color: _deepPurple.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.28), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 패널 헤더 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 10),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 15, color: _gold.withValues(alpha: 0.85)),
                const SizedBox(width: 8),
                const Text(
                  '뽑기 설정',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          _GoldHairline(opacity: 0.2),

          // ── 덱 선택 ──
          _SettingRow(
            label: '덱',
            icon: Icons.layers_outlined,
            child: decksAsync.when(
              loading: () => const SizedBox(
                width: 80,
                child: LinearProgressIndicator(color: _gold, backgroundColor: _deepPurple),
              ),
              error: (_, __) => const Text('오류', style: TextStyle(color: _textSecondary)),
              data: (decks) {
                final deckList = decks as List;
                return _GoldDropdown<String>(
                  value: settings?.selectedDeckId,
                  items: deckList
                      .map((d) => DropdownMenuItem<String>(
                            value: d.id as String,
                            child: Text(d.name as String),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) repo.updateSelectedDeckId(v);
                  },
                );
              },
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 체험 레벨 ──
          _SettingRow(
            label: '레벨',
            icon: Icons.speed_outlined,
            child: _PillSelector<int>(
              options: const [
                (value: 1, label: '즉시'),
                (value: 2, label: '연출'),
                (value: 3, label: '2D'),
                (value: 4, label: '2.5D'),
              ],
              selected: settings?.experienceLevel ?? 4,
              onSelect: (v) => repo.updateExperienceLevel(v),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 기본 카드 수 ──
          _SettingRow(
            label: '카드 수',
            icon: Icons.style_outlined,
            child: _CountStepper(
              value: settings?.defaultCardCount ?? 3,
              min: 1,
              max: 10,
              onChanged: (v) => repo.updateDefaultCardCount(v),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 기본 스프레드 ──
          _SettingRow(
            label: '스프레드',
            icon: Icons.grid_view_outlined,
            child: _PillSelector<SpreadType>(
              options: const [
                (value: SpreadType.single, label: '1장'),
                (value: SpreadType.threeCard, label: '3장'),
                (value: SpreadType.custom, label: '자유'),
              ],
              selected: settings?.defaultSpreadType ?? SpreadType.custom,
              onSelect: (v) => repo.updateDefaultSpreadType(v.name),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 역방향 허용 ──
          _SettingRow(
            label: '역방향',
            icon: Icons.swap_vert_outlined,
            child: _GoldSwitch(
              value: settings?.allowReversed ?? true,
              onChanged: (v) => repo.updateAllowReversed(v),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 설정 행 래퍼 ──────────────────────────────────────────────
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          child,
        ],
      ),
    );
  }
}

// ── 골드 드롭다운 ─────────────────────────────────────────────
class _GoldDropdown<T> extends StatelessWidget {
  const _GoldDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: _darkSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _gold.withValues(alpha: 0.25), width: 0.7),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        style: const TextStyle(color: _textPrimary, fontSize: 12),
        dropdownColor: _deepPurple,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down, color: _gold, size: 16),
        isDense: true,
      ),
    );
  }
}

// ── 필 선택기 ─────────────────────────────────────────────────
class _PillSelector<T> extends StatelessWidget {
  const _PillSelector({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<({T value, String label})> options;
  final T selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((opt) {
        final isActive = opt.value == selected;
        return GestureDetector(
          onTap: () => onSelect(opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isActive
                  ? _gold.withValues(alpha: 0.18)
                  : _darkSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? _gold.withValues(alpha: 0.7)
                    : _softPurple.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Text(
              opt.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? _gold : _textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── 카드 수 스텝퍼 ────────────────────────────────────────────
class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepBtn(
          icon: Icons.remove,
          enabled: value > min,
          onTap: () => onChanged(value - 1),
        ),
        Container(
          width: 36,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        _StepBtn(
          icon: Icons.add,
          enabled: value < max,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? _gold.withValues(alpha: 0.12)
              : _darkSurface.withValues(alpha: 0.3),
          border: Border.all(
            color: enabled
                ? _gold.withValues(alpha: 0.45)
                : _softPurple.withValues(alpha: 0.15),
            width: 0.7,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? _gold : _textSecondary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ── 골드 스위치 ───────────────────────────────────────────────
class _GoldSwitch extends StatelessWidget {
  const _GoldSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.82,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: _gold,
        activeTrackColor: _gold.withValues(alpha: 0.25),
        inactiveThumbColor: _textSecondary,
        inactiveTrackColor: _darkSurface.withValues(alpha: 0.6),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _gold.withValues(alpha: 0.5);
          }
          return _softPurple.withValues(alpha: 0.25);
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  최근 리딩 섹션
// ═══════════════════════════════════════════════════════════════
class _RecentReadingsSection extends StatelessWidget {
  const _RecentReadingsSection({required this.readingsAsync});

  final AsyncValue readingsAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 13, color: _textSecondary.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            const Text(
              '최근 리딩',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        readingsAsync.when(
          loading: () => const Center(
            child: SizedBox(
              height: 40,
              child: LinearProgressIndicator(color: _gold, backgroundColor: _deepPurple),
            ),
          ),
          error: (err, _) => Text(
            '오류: $err',
            style: const TextStyle(color: _textSecondary, fontSize: 12),
          ),
          data: (readings) {
            final list = readings as List;
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: _deepPurple.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _softPurple.withValues(alpha: 0.15), width: 0.7),
                ),
                child: const Center(
                  child: Text(
                    '아직 리딩이 없습니다',
                    style: TextStyle(color: _textSecondary, fontSize: 12, letterSpacing: 0.5),
                  ),
                ),
              );
            }
            return Column(
              children: list.take(3).map((reading) {
                return Builder(builder: (context) {
                  return _ReadingCard(
                    reading: reading,
                    onTap: () => context.push('/readings/${reading.id}'),
                  );
                });
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.reading, required this.onTap});

  final dynamic reading;
  final VoidCallback onTap;

  String _formatDate(DateTime dt) =>
      '${dt.month}/${dt.day}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: _deepPurple.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _gold.withValues(alpha: 0.12), width: 0.7),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (reading.spreadType as SpreadType).displayName,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if ((reading.question as String?) != null &&
                      (reading.question as String).isNotEmpty)
                    Text(
                      reading.question as String,
                      style: const TextStyle(color: _textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              _formatDate(reading.createdAt as DateTime),
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 10,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14, color: _textSecondary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  공통 유틸 위젯
// ═══════════════════════════════════════════════════════════════
class _GoldHairline extends StatelessWidget {
  const _GoldHairline({required this.opacity});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.7,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _gold.withValues(alpha: opacity),
            _gold.withValues(alpha: opacity * 1.4),
            _gold.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
