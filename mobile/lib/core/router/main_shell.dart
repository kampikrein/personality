import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/mystical_scaffold.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkSurface,
      body: navigationShell,
      bottomNavigationBar: _MysticalNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _MysticalNavBar extends StatelessWidget {
  const _MysticalNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: '뽑기'),
    (icon: Icons.bookmark_border_outlined, activeIcon: Icons.bookmark, label: '저장'),
    (icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: '채팅'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: '유저'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kDarkSurface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: kGold.withValues(alpha: 0.18), width: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: kGold.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isSelected = i == currentIndex;
              return _NavItem(
                icon: isSelected ? item.activeIcon : item.icon,
                label: item.label,
                isSelected: isSelected,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? kGold.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? kGold : kTextSecondary.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? kGold : kTextSecondary.withValues(alpha: 0.6),
                letterSpacing: isSelected ? 0.5 : 0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
