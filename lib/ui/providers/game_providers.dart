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

  GameState _snapshot(GameState state) => state.snapshot();

  void _emit() {
    if (loop.hasState) {
      state = _snapshot(loop.state);
    }
  }
  
  void updateState() {
    _emit();
  }
  
  Future<void> newGame() async {
    await loop.newGame();
    _emit();
  }
  
  Future<bool> loadGame() async {
    final success = await loop.loadGame();
    if (success) {
      _emit();
    }
    return success;
  }
  
  void morningPhase() {
    loop.morningPhase();
    _emit();
  }
  
  void processChoice(int index) {
    loop.processChoice(index);
    _emit();
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
    _emit();
  }
  
  void doCraft(String recipeId) {
    loop.doCraft(recipeId);
    _emit();
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
    _emit();
  }
  
  void useItem(String itemId) {
    loop.useItem(itemId);
    _emit();
  }
  
  void rest() {
    loop.rest();
    _emit();
  }
  
  void fortifyBase() {
    loop.fortifyBase();
    _emit();
  }
  
  void useRadio() {
    loop.useRadio();
    _emit();
  }

  void toggleTerminalOverlay() {
    if (loop.hasState) {
      loop.state.terminalOverlayEnabled = !loop.state.terminalOverlayEnabled;
      _emit();
    }
  }
  
  void nightPhase() {
    loop.nightPhase();
    _emit();
  }
  
  Future<void> saveGame() async {
    await loop.saveGame();
  }
  
  bool unlockDistrict(String districtId) {
    final success = loop.unlockDistrict(districtId);
    _emit();
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
