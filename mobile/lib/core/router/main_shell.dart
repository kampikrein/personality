import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.style), label: '뽑기'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: '저장소'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
          NavigationDestination(icon: Icon(Icons.person), label: '사용자'),
        ],
      ),
    );
  }
}
