import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/domain/entities/layout_type.dart';
import '../../../settings/domain/entities/intent_placement.dart';
import '../../../settings/domain/entities/user_settings.dart';
import '../../../settings/domain/repositories/user_settings_repository.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../shuffle/domain/entities/shuffle_mode.dart';
import '../../../shuffle/presentation/providers/shuffle_providers.dart';

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
    final decksAsync = ref.watch(watchDecksProvider);

    final settings = settingsAsync.valueOrNull;
    final experienceLevel = settings?.experienceLevel ?? 4;
    final selectedDeckId = settings?.selectedDeckId ?? 'rws-standard';

    return Scaffold(
      backgroundColor: _darkSurface,
      body: Stack(
        children: [
          // ── 레이어 0: 별이 있는 미스틱 배경 ──
          const _StarfieldBackground(),

          // ── 레이어 1: 단일 스크롤 콘텐츠 ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroSection(
                    initialized: _initialized,
                    glowAnim: _glowAnim,
                    onTap: _initialized
                        ? () => _startDraw(experienceLevel, selectedDeckId)
                        : null,
                  ),
                  _GoldHairline(opacity: 0.35),
                  const SizedBox(height: 16),
                  _DrawSettingsPanel(
                    settings: settings,
                    decksAsync: decksAsync,
                  ),
                ],
              ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
      ),
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
class _DrawSettingsPanel extends ConsumerStatefulWidget {
  const _DrawSettingsPanel({
    required this.settings,
    required this.decksAsync,
  });

  final UserSettings? settings;
  final AsyncValue decksAsync;

  @override
  ConsumerState<_DrawSettingsPanel> createState() => _DrawSettingsPanelState();
}

class _DrawSettingsPanelState extends ConsumerState<_DrawSettingsPanel> {
  // 이전 배치 상태 스냅샷 — 배치 라벨 옆 ↩ 아이콘으로 복원
  ({LayoutType layoutType, int cardCount, int cardsPerRow})? _undoSnapshot;

  /// LayoutType 변경 시 호출 — 자동 조정 + 배치 라벨 옆 ↩ 아이콘 표시.
  Future<void> _onLayoutChanged(
    LayoutType next,
    UserSettings? current,
    UserSettingsRepository repo,
  ) async {
    if (current == null || current.defaultLayoutType == next) return;

    // 이전 상태 스냅샷 저장 → 배치 라벨 옆 ↩ 아이콘 표시
    setState(() {
      _undoSnapshot = (
        layoutType: current.defaultLayoutType,
        cardCount: current.defaultCardCount,
        cardsPerRow: current.cardsPerRow,
      );
    });

    // (1) LayoutType 갱신
    await repo.updateDefaultLayoutType(next.name);
    ref.read(shuffleStateProvider.notifier).clear();

    // (2) cardCount auto-reset (범위 밖이면 defaultCardCount 로)
    final currentCount = current.defaultCardCount;
    if (currentCount < next.cardCountMin || currentCount > next.cardCountMax) {
      await repo.updateDefaultCardCount(next.defaultCardCount);
    }

    // (3) cardsPerRow 강제 적용 (override 있으면)
    final override = next.cardsPerRowOverride;
    if (override != null && current.cardsPerRow != override) {
      await repo.updateCardsPerRow(override);
    }
  }

  /// ↩ 아이콘 탭 시 이전 배치 상태 복원
  Future<void> _restoreSnapshot(UserSettingsRepository repo) async {
    final snap = _undoSnapshot;
    if (snap == null) return;
    setState(() => _undoSnapshot = null);
    await repo.updateDefaultLayoutType(snap.layoutType.name);
    await repo.updateDefaultCardCount(snap.cardCount);
    await repo.updateCardsPerRow(snap.cardsPerRow);
    if (!mounted) return;
    ref.read(shuffleStateProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final decksAsync = widget.decksAsync;
    final repo = ref.read(userSettingsRepositoryProvider);

    final selectedLayout = settings?.defaultLayoutType ?? LayoutType.linear;
    final cardsPerRowDisabled = selectedLayout.cardsPerRowOverride != null;
    final effectiveCardsPerRow =
        selectedLayout.cardsPerRowOverride ?? (settings?.cardsPerRow ?? 3);

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

          // ══════════════════════════════════════════════════════════
          //  [기본 설정] 그룹 — 덱 / 레벨 / 역방향
          // ══════════════════════════════════════════════════════════
          const _PanelSubheader(title: '기본 설정'),

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

          // ── 역방향 허용 ──
          _SettingRow(
            label: '역방향',
            icon: Icons.swap_vert_outlined,
            child: _GoldSwitch(
              value: settings?.allowReversed ?? true,
              onChanged: (v) => repo.updateAllowReversed(v),
            ),
          ),

          // ── 그룹 구분선 (강한) ──
          _GoldHairline(opacity: 0.3),

          // ══════════════════════════════════════════════════════════
          //  [모양] 그룹 — 배치 / 카드 수 / 한 줄 카드 수 / (grid3x3) 드로우 순서
          // ══════════════════════════════════════════════════════════
          const _PanelSubheader(title: '모양'),

          // ── 배치 (LayoutType) ──
          _SettingRow(
            label: '배치',
            icon: Icons.grid_view_outlined,
            labelTrailing: _undoSnapshot != null
                ? IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    iconSize: 16,
                    icon: const Icon(Icons.undo, color: _gold),
                    tooltip: '이전 값 복원',
                    onPressed: () => _restoreSnapshot(repo),
                  )
                : null,
            child: _PillSelector<LayoutType>(
              options: [
                (value: LayoutType.linear, label: LayoutType.linear.displayName),
                (value: LayoutType.tShape, label: LayoutType.tShape.displayName),
                (value: LayoutType.grid3x3, label: LayoutType.grid3x3.displayName),
              ],
              selected: selectedLayout,
              onSelect: (v) => _onLayoutChanged(v, settings, repo),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 기본 카드 수 (동적 min/max) ──
          _SettingRow(
            label: '카드 수',
            icon: Icons.style_outlined,
            child: _CountStepper(
              value: settings?.defaultCardCount ?? selectedLayout.defaultCardCount,
              min: selectedLayout.cardCountMin,
              max: selectedLayout.cardCountMax,
              onChanged: (v) {
                repo.updateDefaultCardCount(v);
                ref.read(shuffleStateProvider.notifier).clear();
              },
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 한 줄 카드 수 (tShape/grid3x3 일 때 비활성) ──
          _SettingRow(
            label: '한 줄 카드 수',
            icon: Icons.view_column_outlined,
            child: IgnorePointer(
              ignoring: cardsPerRowDisabled,
              child: Opacity(
                opacity: cardsPerRowDisabled ? 0.4 : 1.0,
                child: _PillSelector<int>(
                  options: const [
                    (value: 1, label: '1장'),
                    (value: 2, label: '2장'),
                    (value: 3, label: '3장'),
                  ],
                  selected: effectiveCardsPerRow,
                  onSelect: (v) => repo.updateCardsPerRow(v),
                ),
              ),
            ),
          ),

          // ── (조건) 드로우 순서 — grid3x3 전용 (Decision 12) ──
          if (selectedLayout == LayoutType.grid3x3) ...[
            _GoldHairline(opacity: 0.1),
            _SettingRow(
              label: '드로우 순서',
              icon: Icons.swap_horiz_outlined,
              child: _PillSelector<String>(
                options: const [
                  (value: 'default', label: '기본'),
                  (value: 'other', label: '다른 순서 (준비 중)'),
                ],
                selected: 'default',
                onSelect: (v) {
                  // "다른 순서 (준비 중)" 은 비활성 placeholder — no-op.
                },
              ),
            ),
          ],

          // ── 그룹 구분선 (강한) ──
          _GoldHairline(opacity: 0.3),

          // ══════════════════════════════════════════════════════════
          //  [표시 옵션] 그룹 — 앞면 / 카드 이름 / 카드 크기
          // ══════════════════════════════════════════════════════════
          const _PanelSubheader(title: '표시 옵션'),

          // ── 앞면으로 시작 ──
          _SettingRow(
            label: '앞면으로 시작',
            icon: Icons.flip_outlined,
            child: _GoldSwitch(
              value: settings?.showFaceUp ?? false,
              onChanged: (v) => repo.updateShowFaceUp(v),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 카드 이름 표시 ──
          _SettingRow(
            label: '카드 이름',
            icon: Icons.label_outline,
            child: _GoldSwitch(
              value: settings?.showCardName ?? true,
              onChanged: (v) => repo.updateShowCardName(v),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 카드 크기 (별도 페이지 진입) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () => context.push('/settings/card-size'),
              child: Row(
                children: [
                  Icon(Icons.aspect_ratio, size: 14, color: _textSecondary),
                  const SizedBox(width: 8),
                  const Text(
                    '카드 크기',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    settings?.cardSizePreset.label ?? '표준 타로',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: _textSecondary.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          _GoldHairline(opacity: 0.1),

          // ── 의도 입력 (별도 페이지 진입) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () => context.push('/settings/intent-placement'),
              child: Row(
                children: [
                  Icon(Icons.psychology_outlined,
                      size: 14, color: _textSecondary),
                  const SizedBox(width: 8),
                  const Text(
                    '의도 입력',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    settings?.intentPlacement.shortLabel ?? '뽑기 전',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: _textSecondary.withValues(alpha: 0.5),
                  ),
                ],
              ),
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
    this.labelTrailing,
  });

  final String label;
  final IconData icon;
  final Widget child;
  final Widget? labelTrailing;

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
          if (labelTrailing != null) ...[
            const SizedBox(width: 2),
            labelTrailing!,
          ],
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
//  공통 유틸 위젯
// ═══════════════════════════════════════════════════════════════
// ── 패널 서브헤더 ─────────────────────────────────────────────
class _PanelSubheader extends StatelessWidget {
  const _PanelSubheader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: _textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

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
