import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/theme/game_theme.dart';
import 'ui/screens/title_screen.dart';
import 'ui/providers/game_providers.dart';

/// Main app widget
class ZombieLifeSimApp extends ConsumerWidget {
  const ZombieLifeSimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pre-load game data
    ref.watch(gameDataProvider);
    
    return MaterialApp(
      title: 'Zombie Life Sim',
      debugShowCheckedModeBanner: false,
      theme: createGameTheme(),
      home: const _AppLoader(),
    );
  }
}

/// Loader widget that shows loading screen while data loads
class _AppLoader extends ConsumerWidget {
  const _AppLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameData = ref.watch(gameDataProvider);
    final gameLoop = ref.watch(gameLoopProvider);

    return gameData.when(
      loading: () => const _LoadingScreen(),
      error: (error, stack) => _ErrorScreen(error: error.toString()),
      data: (_) => gameLoop.when(
        loading: () => const _LoadingScreen(message: 'Khởi tạo game...'),
        error: (error, stack) => _ErrorScreen(error: error.toString()),
        data: (_) => const TitleScreen(),
      ),
    );
  }
}

/// Loading screen
class _LoadingScreen extends StatelessWidget {
  final String message;

  const _LoadingScreen({this.message = 'Đang tải dữ liệu...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: GameColors.zombie.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '🧟',
                  style: TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: GameColors.danger,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: GameTypography.body.copyWith(
                color: GameColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: GameColors.danger,
              ),
              const SizedBox(height: 24),
              Text(
                'Đã xảy ra lỗi',
                style: GameTypography.heading2.copyWith(
                  color: GameColors.danger,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: GameTypography.body.copyWith(
                  color: GameColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
