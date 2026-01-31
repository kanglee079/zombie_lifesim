import '../core/logger.dart';
import '../data/repositories/game_data_repo.dart';
import 'state/game_state.dart';
import 'state/save_manager.dart';
import 'engine/event_engine.dart';
import 'engine/effect_engine.dart';
import 'engine/requirement_engine.dart';
import 'engine/loot_engine.dart';
import 'systems/scavenge_system.dart';
import 'systems/night_system.dart';
import 'systems/craft_system.dart';
import 'systems/trade_system.dart';
import 'systems/npc_system.dart';
import 'systems/quest_system.dart';
import 'systems/daily_tick_system.dart';
import '../core/rng.dart';

/// Main game loop controller
class GameLoop {
  final GameDataRepository data;
  final SaveManager saveManager;
  late final GameRng rng;
  
  // Engines
  late final RequirementEngine requirementEngine;
  late final EffectEngine effectEngine;
  late final EventEngine eventEngine;
  late final LootEngine lootEngine;
  
  // Systems
  late final ScavengeSystem scavengeSystem;
  late final NightSystem nightSystem;
  late final CraftSystem craftSystem;
  late final TradeSystem tradeSystem;
  late final NpcSystem npcSystem;
  late final QuestSystem questSystem;
  late final DailyTickSystem dailyTickSystem;

  GameState? _state;
  GameState get state => _state!;
  bool get hasState => _state != null;

  GameLoop({required this.data, required this.saveManager});

  /// Initialize engines and systems
  void initialize({int? seed}) {
    rng = GameRng(seed ?? DateTime.now().millisecondsSinceEpoch);
    
    requirementEngine = RequirementEngine(data: data);
    effectEngine = EffectEngine(data: data, rng: rng);
    lootEngine = LootEngine(data: data, rng: rng);
    eventEngine = EventEngine(
      data: data,
      requirementEngine: requirementEngine,
      effectEngine: effectEngine,
      rng: rng,
    );
    
    npcSystem = NpcSystem(data: data, rng: rng);
    scavengeSystem = ScavengeSystem(
      data: data,
      lootEngine: lootEngine,
      effectEngine: effectEngine,
      rng: rng,
    );
    nightSystem = NightSystem(data: data, rng: rng);
    craftSystem = CraftSystem(data: data, effectEngine: effectEngine);
    tradeSystem = TradeSystem(data: data, effectEngine: effectEngine, rng: rng);
    questSystem = QuestSystem(data: data, effectEngine: effectEngine);
    dailyTickSystem = DailyTickSystem(data: data, npcSystem: npcSystem);

    GameLogger.game('GameLoop initialized');
  }

  /// Start a new game
  Future<void> newGame() async {
    _state = GameState.newGame();
    
    // Add player to party
    _state!.party.add(PartyMember(
      id: 'player',
      name: 'Bạn',
      role: 'survivor',
      isPlayer: true,
      hp: 100,
      morale: 50,
      traits: [],
      skills: {'combat': 3, 'stealth': 3, 'medical': 3, 'craft': 3, 'scavenge': 3},
    ));
    
    // Initialize starter district
    for (final district in data.districts.values) {
      if (district.startUnlocked) {
        _state!.districtStates[district.id] = DistrictState(unlocked: true);
      }
    }
    
    // Add starter items
    effectEngine.addItemToInventory(_state!, 'bandage', 2);
    effectEngine.addItemToInventory(_state!, 'canned_food', 3);
    effectEngine.addItemToInventory(_state!, 'water_bottle', 2);
    effectEngine.addItemToInventory(_state!, 'knife', 1);
    
    // First day log
    _state!.addLog('☀️ Ngày 1 - Thức dậy sau đại dịch. Cần tìm nơi trú ẩn an toàn.');
    
    await saveManager.save(_state!);
    
    GameLogger.game('New game started');
  }

  /// Load existing game
  Future<bool> loadGame() async {
    final loaded = await saveManager.load();
    if (loaded != null) {
      _state = loaded;
      GameLogger.game('Game loaded: Day ${_state!.day}');
      return true;
    }
    return false;
  }

  /// Save current game
  Future<void> saveGame() async {
    if (_state != null) {
      await saveManager.save(_state!);
      GameLogger.game('Game saved');
    }
  }

  /// Process morning phase
  void morningPhase() {
    if (_state == null) return;
    
    _state!.timeOfDay = 'morning';
    
    // Check quest auto-starts
    questSystem.checkAutoStartQuests(_state!);
    
    // Generate morning event
    final event = eventEngine.selectEvent(_state!, context: 'morning');
    if (event != null) {
      _state!.currentEvent = event;
    }
    
    GameLogger.game('Morning phase: Day ${_state!.day}');
  }

  /// Process player choice for current event
  void processChoice(int choiceIndex) {
    if (_state == null || _state!.currentEvent == null) return;
    
    eventEngine.processChoice(_state!, _state!.currentEvent!, choiceIndex);
    _state!.currentEvent = null;
    
    // Move to next phase
    if (_state!.timeOfDay == 'morning') {
      _state!.timeOfDay = 'day';
    }
  }

  /// Execute scavenge run
  ScavengeResult doScavenge({
    required String locationId,
    required ScavengeTime time,
    required ScavengeStyle style,
  }) {
    if (_state == null) {
      throw StateError('No game state');
    }
    
    final result = scavengeSystem.execute(
      locationId: locationId,
      time: time,
      style: style,
      state: _state!,
    );
    
    // Move to evening
    _state!.timeOfDay = 'evening';
    
    return result;
  }

  /// Execute crafting
  CraftResult doCraft(String recipeId) {
    if (_state == null) {
      throw StateError('No game state');
    }
    
    return craftSystem.craft(recipeId, _state!);
  }

  /// Execute trade
  TradeResult doTrade({
    required String itemId,
    required int qty,
    required String factionId,
    required bool isBuying,
  }) {
    if (_state == null) {
      throw StateError('No game state');
    }
    
    if (isBuying) {
      return tradeSystem.buyFromTrader(
        itemId: itemId,
        qty: qty,
        factionId: factionId,
        state: _state!,
      );
    } else {
      return tradeSystem.sellToTrader(
        itemId: itemId,
        qty: qty,
        factionId: factionId,
        state: _state!,
      );
    }
  }

  /// Use an item
  void useItem(String itemId) {
    if (_state == null) return;
    effectEngine.useItem(_state!, itemId);
  }

  /// Process evening phase (triggers night)
  void eveningPhase() {
    if (_state == null) return;
    
    _state!.timeOfDay = 'evening';
    
    // Evening event
    final event = eventEngine.selectEvent(_state!, context: 'evening');
    if (event != null) {
      _state!.currentEvent = event;
    }
    
    GameLogger.game('Evening phase');
  }

  /// Process night phase
  NightResult nightPhase() {
    if (_state == null) {
      throw StateError('No game state');
    }
    
    _state!.timeOfDay = 'night';
    
    // Resolve night threats
    final result = nightSystem.resolve(_state!);
    
    // Move to next day
    dailyTickSystem.tick(_state!);
    
    // Autosave
    saveGame();
    
    return result;
  }

  /// Rest action (restore fatigue, pass time)
  void rest() {
    if (_state == null) return;
    
    _state!.playerStats.fatigue = (_state!.playerStats.fatigue - 30).clamp(0, 100);
    _state!.playerStats.stress = (_state!.playerStats.stress - 10).clamp(0, 100);
    _state!.addLog('😴 Nghỉ ngơi. Phục hồi thể lực.');
    
    _state!.timeOfDay = 'evening';
    
    GameLogger.game('Player rested');
  }

  /// Fortify base action
  void fortifyBase() {
    if (_state == null) return;
    
    // Check for materials
    bool hasWood = false;
    bool hasNails = false;
    
    for (final stack in _state!.inventory) {
      if (stack.itemId == 'wood' && stack.qty > 0) hasWood = true;
      if (stack.itemId == 'nails' && stack.qty > 0) hasNails = true;
    }
    
    if (hasWood && hasNails) {
      effectEngine.removeItemFromInventory(_state!, 'wood', 1);
      effectEngine.removeItemFromInventory(_state!, 'nails', 1);
      _state!.baseStats.defense = (_state!.baseStats.defense + 5).clamp(0, 100);
      _state!.addLog('🔨 Gia cố căn cứ. Phòng thủ +5.');
    } else {
      _state!.addLog('⚠️ Cần gỗ và đinh để gia cố.');
    }
    
    GameLogger.game('Fortify base attempted');
  }

  /// Use radio (increases signal heat, may trigger events)
  void useRadio() {
    if (_state == null) return;
    
    _state!.signalHeat = (_state!.signalHeat + 10).clamp(0, 100);
    _state!.addLog('📻 Sử dụng radio. Tín hiệu +10.');
    
    // Chance for radio event
    final event = eventEngine.selectEvent(_state!, context: 'radio');
    if (event != null) {
      _state!.currentEvent = event;
    }
    
    GameLogger.game('Radio used');
  }

  /// Check if game is over
  bool get isGameOver => _state?.gameOver ?? false;

  /// Get ending type
  String? get endingType => _state?.endingType;

  /// Get available locations for scavenging
  List<String> getScavengeLocations() {
    if (_state == null) return [];
    return scavengeSystem.getAvailableLocations(_state!);
  }

  /// Get available recipes
  List<dynamic> getAvailableRecipes() {
    if (_state == null) return [];
    return craftSystem.getAvailableRecipes(_state!);
  }

  /// Get known recipes
  List<dynamic> getKnownRecipes() {
    if (_state == null) return [];
    return craftSystem.getKnownRecipes(_state!);
  }

  /// Check if recipe can be crafted
  bool canCraft(String recipeId) {
    if (_state == null) return false;
    return craftSystem.canCraft(recipeId, _state!);
  }

  /// Get available factions for trade
  List<String> getTradeFactions() {
    if (_state == null) return [];
    return tradeSystem.getAvailableFactions(_state!);
  }

  /// Get trade price
  int getTradePrice(String itemId, String factionId, bool isBuying) {
    if (_state == null) return 0;
    if (isBuying) {
      return tradeSystem.getBuyPrice(itemId, factionId, _state!);
    } else {
      return tradeSystem.getSellPrice(itemId, factionId, _state!);
    }
  }

  /// Generate trade offers
  List<TradeOffer> generateTradeOffers(String factionId) {
    if (_state == null) return [];
    return tradeSystem.generateOffers(factionId, _state!);
  }

  /// Unlock a district
  bool unlockDistrict(String districtId) {
    if (_state == null) return false;
    
    final district = data.getDistrict(districtId);
    if (district == null) return false;
    
    final cost = district.unlockCostEP;
    if (_state!.baseStats.explorationPoints < cost) {
      _state!.addLog('⚠️ Không đủ điểm khám phá. Cần $cost EP.');
      return false;
    }
    
    _state!.baseStats.explorationPoints -= cost;
    _state!.districtStates[districtId] = DistrictState(unlocked: true);
    _state!.addLog('🗺️ Mở khóa khu vực: ${district.name}');
    
    GameLogger.game('District unlocked: $districtId');
    return true;
  }
}
