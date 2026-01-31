import 'package:flutter_test/flutter_test.dart';
import 'package:zombie_lifesim/data/repositories/game_data_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GameDataRepository.loadAll completes and loads core datasets', () async {
    final repo = GameDataRepository();
    await repo.loadAll();

    expect(repo.items, isNotEmpty);
    expect(repo.lootTables, isNotEmpty);
    expect(repo.factions, isNotEmpty);
    expect(repo.events, isNotEmpty);
  });
}

