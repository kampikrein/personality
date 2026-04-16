import 'package:flutter/material.dart';

import '../../../../core/widgets/mystical_scaffold.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MysticalScaffold(
      title: '채팅',
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: kGold),
            SizedBox(height: 16),
            Text(
              'AI 타로 채팅',
              style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
            SizedBox(height: 8),
            Text(
              '준비 중입니다.',
              style: TextStyle(color: kTextSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
