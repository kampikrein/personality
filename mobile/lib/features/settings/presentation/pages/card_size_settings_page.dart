import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('카드 크기')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (settings) {
          final currentPreset = settings.cardSizePreset;
          final aspectRatio = settings.cardAspectRatio;

          // Initialize controllers once from settings
          if (!_controllersInitialized) {
            _widthController.text =
                settings.customCardWidthMm.toStringAsFixed(1);
            _heightController.text =
                settings.customCardHeightMm.toStringAsFixed(1);
            _controllersInitialized = true;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Preview card
              _CardPreview(aspectRatio: aspectRatio),
              const SizedBox(height: 24),

              // Preset list
              ...CardSizePreset.values.map((preset) {
                final isSelected = preset == currentPreset;
                return _PresetTile(
                  preset: preset,
                  isSelected: isSelected,
                  customSubtitle: preset == CardSizePreset.custom
                      ? '${_widthController.text} × ${_heightController.text} mm'
                      : null,
                  onTap: () {
                    ref
                        .read(userSettingsRepositoryProvider)
                        .updateCardSizePreset(preset.name);
                  },
                );
              }),

              // Custom size inputs
              if (currentPreset == CardSizePreset.custom) ...[
                const SizedBox(height: 16),
                _CustomSizeInput(
                  widthController: _widthController,
                  heightController: _heightController,
                  onApply: _applyCustomSize,
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
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D1B4E),
                border: Border.all(color: const Color(0xFFD4A84B)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '미리보기',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFD4A84B),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '종횡비: ${aspectRatio.toStringAsFixed(3)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
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
    final theme = Theme.of(context);
    final subtitle = customSubtitle ?? preset.subtitle;

    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      title: Text(preset.label),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widthController,
              decoration: const InputDecoration(
                labelText: '가로 (mm)',
                isDense: true,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              onSubmitted: (_) => onApply(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('×'),
          ),
          Expanded(
            child: TextField(
              controller: heightController,
              decoration: const InputDecoration(
                labelText: '세로 (mm)',
                isDense: true,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              onSubmitted: (_) => onApply(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onApply,
            child: const Text('적용'),
          ),
        ],
      ),
    );
  }
}
