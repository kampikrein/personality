import 'package:flutter/material.dart';

import '../../../../core/widgets/mystical_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MysticalScaffold(
      title: '앱 설정',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_outlined,
                size: 56,
                color: kGold.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 20),
              const Text(
                '환경설정 영역이 준비 중입니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '테마 · 햅틱 · 알림 등이 추가될 예정입니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
