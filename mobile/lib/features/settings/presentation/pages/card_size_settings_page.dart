import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/mystical_scaffold.dart';
import '../../domain/entities/card_size_preset.dart';
import '../providers/settings_providers.dart';

class CardSizeSettingsPage extends ConsumerStatefulWidget {
  const CardSizeSettingsPage({super.key});

  @override
  ConsumerState<CardSizeSettingsPage> createState() =>
      _CardSizeSettingsPageState();
}

class _CardSizeSettingsPageState extends ConsumerState<CardSizeSettingsPage> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController();
    _heightController = TextEditingController();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _applyCustomSize() {
    final w = double.tryParse(_widthController.text);
    final h = double.tryParse(_heightController.text);
    if (w != null && h != null && w > 0 && h > 0) {
      ref.read(userSettingsRepositoryProvider).updateCustomCardSize(w, h);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return MysticalScaffold(
      title: '카드 크기',
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => Center(child: Text('오류: $e', style: const TextStyle(color: kTextSecondary))),
        data: (settings) {
          final currentPreset = settings.cardSizePreset;
          final aspectRatio = settings.cardAspectRatio;

          if (!_controllersInitialized) {
            _widthController.text = settings.customCardWidthMm.toStringAsFixed(1);
            _heightController.text = settings.customCardHeightMm.toStringAsFixed(1);
            _controllersInitialized = true;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // 미리보기 카드
              MysticalCard(
                child: Column(
                  children: [
                    const GoldSectionTitle('미리보기', icon: Icons.aspect_ratio_outlined),
                    _CardPreview(aspectRatio: aspectRatio),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 프리셋 목록
              MysticalCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ...CardSizePreset.values.map((preset) {
                      final isSelected = preset == currentPreset;
                      final isLast = preset == CardSizePreset.values.last;
                      return Column(
                        children: [
                          _PresetTile(
                            preset: preset,
                            isSelected: isSelected,
                            customSubtitle: preset == CardSizePreset.custom
                                ? '${_widthController.text} × ${_heightController.text} mm'
                                : null,
                            onTap: () {
                              ref.read(userSettingsRepositoryProvider)
                                  .updateCardSizePreset(preset.name);
                            },
                          ),
                          if (!isLast) GoldHairline(opacity: 0.1),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              // 커스텀 크기 입력
              if (currentPreset == CardSizePreset.custom) ...[
                const SizedBox(height: 16),
                MysticalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GoldSectionTitle('커스텀 크기', icon: Icons.edit_outlined),
                      _CustomSizeInput(
                        widthController: _widthController,
                        heightController: _heightController,
                        onApply: _applyCustomSize,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.aspectRatio});
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D1B4E), Color(0xFF1A1028)],
                ),
                border: Border.all(color: kGold, width: 0.8),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: kGold.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: kGold, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '종횡비: ${aspectRatio.toStringAsFixed(3)}',
          style: const TextStyle(color: kTextSecondary, fontSize: 12, letterSpacing: 0.3),
        ),
      ],
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.isSelected,
    required this.onTap,
    this.customSubtitle,
  });

  final CardSizePreset preset;
  final bool isSelected;
  final VoidCallback onTap;
  final String? customSubtitle;

  @override
  Widget build(BuildContext context) {
    final subtitle = customSubtitle ?? preset.subtitle;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? kGold : kSoftPurple.withValues(alpha: 0.4),
                  width: isSelected ? 1.5 : 1,
                ),
                color: isSelected ? kGold.withValues(alpha: 0.15) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.circle, color: kGold, size: 10)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.label,
                    style: TextStyle(
                      color: isSelected ? kGold : kTextPrimary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, color: kGold, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CustomSizeInput extends StatelessWidget {
  const _CustomSizeInput({
    required this.widthController,
    required this.heightController,
    required this.onApply,
  });

  final TextEditingController widthController;
  final TextEditingController heightController;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widthController,
            decoration: mysticalInputDecoration(labelText: '가로 (mm)', isDense: true),
            style: const TextStyle(color: kTextPrimary, fontSize: 14),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            onSubmitted: (_) => onApply(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('×', style: TextStyle(color: kTextSecondary, fontSize: 16)),
        ),
        Expanded(
          child: TextField(
            controller: heightController,
            decoration: mysticalInputDecoration(labelText: '세로 (mm)', isDense: true),
            style: const TextStyle(color: kTextPrimary, fontSize: 14),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            onSubmitted: (_) => onApply(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kGold,
            foregroundColor: kDarkSurface,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onPressed: onApply,
          child: const Text('적용', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
