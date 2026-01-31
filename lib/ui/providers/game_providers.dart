import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/game_data_repo.dart';
import '../../game/game_loop.dart';
import '../../game/state/game_state.dart';
import '../../game/state/save_manager.dart';

/// Provider for GameDataRepository
final gameDataProvider = FutureProvider<GameDataRepository>((ref) async {
  final repo = GameDataRepository();
  await repo.loadAll();
  return repo;
});

/// Provider for SaveManager
final saveManagerProvider = Provider<SaveManager>((ref) {
  return SaveManager();
});

/// Provider for GameLoop
final gameLoopProvider = FutureProvider<GameLoop>((ref) async {
  final data = await ref.watch(gameDataProvider.future);
  final saveManager = ref.watch(saveManagerProvider);
  
  final loop = GameLoop(data: data, saveManager: saveManager);
  loop.initialize();
  
  return loop;
});

/// StateNotifier for GameState
class GameStateNotifier extends StateNotifier<GameState?> {
  final GameLoop loop;
  
  GameStateNotifier(this.loop) : super(null);
  
  void updateState() {
    if (loop.hasState) {
      state = loop.state;
    }
  }
  
  Future<void> newGame() async {
    await loop.newGame();
    state = loop.state;
  }
  
  Future<bool> loadGame() async {
    final success = await loop.loadGame();
    if (success) {
      state = loop.state;
    }
    return success;
  }
  
  void morningPhase() {
    loop.morningPhase();
    state = loop.state;
  }
  
  void processChoice(int index) {
    loop.processChoice(index);
    state = loop.state;
  }

  bool isChoiceEnabled(Map<String, dynamic> choice) {
    if (!loop.hasState) return false;
    final requirements = choice['requirements'] ?? choice['conditions'];
    if (requirements == null) return true;
    return loop.requirementEngine.check(requirements, loop.state);
  }
  
  void doScavenge({
    required String locationId,
    required dynamic time,
    required dynamic style,
  }) {
    loop.doScavenge(
      locationId: locationId,
      time: time,
      style: style,
    );
    state = loop.state;
  }
  
  void doCraft(String recipeId) {
    loop.doCraft(recipeId);
    state = loop.state;
  }
  
  void doTrade({
    required String itemId,
    required int qty,
    required String factionId,
    required bool isBuying,
  }) {
    loop.doTrade(
      itemId: itemId,
      qty: qty,
      factionId: factionId,
      isBuying: isBuying,
    );
    state = loop.state;
  }
  
  void useItem(String itemId) {
    loop.useItem(itemId);
    state = loop.state;
  }
  
  void rest() {
    loop.rest();
    state = loop.state;
  }
  
  void fortifyBase() {
    loop.fortifyBase();
    state = loop.state;
  }
  
  void useRadio() {
    loop.useRadio();
    state = loop.state;
  }

  void toggleTerminalOverlay() {
    if (loop.hasState) {
      loop.state.terminalOverlayEnabled = !loop.state.terminalOverlayEnabled;
      state = loop.state;
    }
  }
  
  void nightPhase() {
    loop.nightPhase();
    state = loop.state;
  }
  
  Future<void> saveGame() async {
    await loop.saveGame();
  }
  
  bool unlockDistrict(String districtId) {
    final success = loop.unlockDistrict(districtId);
    state = loop.state;
    return success;
  }
}

/// Provider for GameStateNotifier
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState?>((ref) {
  final loopAsync = ref.watch(gameLoopProvider);
  
  return loopAsync.when(
    data: (loop) => GameStateNotifier(loop),
    loading: () => GameStateNotifier(GameLoop(
      data: GameDataRepository(),
      saveManager: SaveManager(),
    )),
    error: (_, __) => GameStateNotifier(GameLoop(
      data: GameDataRepository(),
      saveManager: SaveManager(),
    )),
  );
});

/// Current day provider
final currentDayProvider = Provider<int>((ref) {
  final state = ref.watch(gameStateProvider);
  return state?.day ?? 1;
});

/// Current time of day provider  
final timeOfDayProvider = Provider<String>((ref) {
  final state = ref.watch(gameStateProvider);
  return state?.timeOfDay ?? 'morning';
});

/// Inventory provider
final inventoryProvider = Provider<List<InventoryItem>>((ref) {
  final state = ref.watch(gameStateProvider);
  return state?.inventory ?? [];
});

/// Log entries provider
final logEntriesProvider = Provider<List<LogEntry>>((ref) {
  final state = ref.watch(gameStateProvider);
  return state?.log ?? [];
});

/// Player stats provider
final playerStatsProvider = Provider<PlayerStats?>((ref) {
  final state = ref.watch(gameStateProvider);
  return state?.playerStats;
});

/// Base stats provider
final baseStatsProvider = Provider<BaseStats?>((ref) {
  final state = ref.watch(gameStateProvider);
  return state?.baseStats;
});

/// Current event provider
final currentEventProvider = Provider<dynamic>((ref) {
  final state = ref.watch(gameStateProvider);
  return state?.currentEvent;
});

/// Party members provider
final partyProvider = Provider<List<PartyMember>>((ref) {
  final state = ref.watch(gameStateProvider);
  return state?.party ?? [];
});

/// Game over provider
final gameOverProvider = Provider<bool>((ref) {
  final state = ref.watch(gameStateProvider);
  return state?.gameOver ?? false;
});

/// Ending type provider
final endingTypeProvider = Provider<String?>((ref) {
  final state = ref.watch(gameStateProvider);
  return state?.endingType;
});
