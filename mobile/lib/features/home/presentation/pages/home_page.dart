import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../deck/presentation/providers/deck_providers.dart';
import '../../../reading/presentation/providers/reading_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (_initialized) return;
    final repo = ref.read(deckRepositoryProvider);
    await repo.seedRwsDeck();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(watchReadingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Personality Tarot', style: theme.textTheme.headlineLarge),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.pushNamed('deck'),
                child: const Text('셔플 시작', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 32),
            Text('최근 리딩', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Expanded(
              child: readingsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('오류: $err')),
                data: (readings) => readings.isEmpty
                    ? Center(
                        child: Text(
                          '아직 리딩이 없습니다.\n셔플을 시작해보세요.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        itemCount: readings.length,
                        itemBuilder: (context, index) {
                          final reading = readings[index];
                          return Card(
                            child: ListTile(
                              title: Text(reading.spreadType.displayName),
                              subtitle: Text(reading.question ?? '질문 없음'),
                              trailing: Text(
                                _formatDate(reading.createdAt),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
