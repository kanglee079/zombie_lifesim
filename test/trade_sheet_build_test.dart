import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zombie_lifesim/data/repositories/game_data_repo.dart';
import 'package:zombie_lifesim/game/game_loop.dart';
import 'package:zombie_lifesim/game/state/game_state.dart';
import 'package:zombie_lifesim/game/state/save_manager.dart';
import 'package:zombie_lifesim/ui/providers/game_providers.dart';
import 'package:zombie_lifesim/ui/screens/trade_sheet.dart';

class _FakeSaveManager extends SaveManager {
  @override
  Future<void> init() async {}

  @override
  Future<void> save(GameState state) async {}

  @override
  Future<GameState?> load() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TradeSheet builds and can show offers', (tester) async {
    late final GameDataRepository repo;
    late final GameLoop loop;

    // In widget tests, asset loading and file IO can hang unless executed in
    // a real async zone.
    await tester.runAsync(() async {
      repo = GameDataRepository();
      await repo.loadAll();

      loop = GameLoop(data: repo, saveManager: _FakeSaveManager());
      loop.initialize(seed: 123);
      await loop.newGame();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameLoopProvider.overrideWith((ref) async => loop),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TradeSheet(embedded: true),
          ),
        ),
      ),
    );

    // Let the FutureProvider resolve.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Select a faction chip (at least one should exist).
    final chip = find.byType(ChoiceChip).first;
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    await tester.pump(const Duration(milliseconds: 50));

    // Offers list should render (or at minimum the Buy tab should exist).
    expect(find.text('Mua'), findsWidgets);
  });
}

