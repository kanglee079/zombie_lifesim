import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/logger.dart';
import '../models/item_def.dart';
import '../models/recipe_def.dart';
import '../models/location_def.dart';
import '../models/loot_table_def.dart';
import '../models/quest_def.dart';
import '../models/faction_def.dart';
import '../models/npc_def.dart';
import '../models/balance_def.dart';

/// Repository for all static game data
class GameDataRepository {
  // Loaded data
  Map<String, ItemDef> items = {};
  Map<String, RecipeDef> recipes = {};
  Map<String, Map<String, dynamic>> events = {};
  Map<String, DistrictDef> districts = {};
  Map<String, LocationDef> locations = {};
  Map<String, LootTableDef> lootTables = {};
  Map<String, QuestDef> quests = {};
  Map<String, FactionDef> factions = {};
  Map<String, TraitDef> traits = {};
  Map<String, NpcTemplate> npcTemplates = {};
  Map<String, Map<String, dynamic>> scripts = {};
  
  Map<String, dynamic> traitConflicts = {};
  Map<String, dynamic> depletionSystem = {};
  Map<String, dynamic> tradeSystem = {};
  
  late BalanceDef balance;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Load all game data
  Future<void> loadAll() async {
    if (_loaded) return;

    try {
      // Load balance first (contains multipliers)
      await _loadBalance();

      // Load all other data in parallel
      await Future.wait([
        _loadItems(),
        _loadRecipes(),
        _loadEvents(),
        _loadLocations(),
        _loadLootTables(),
        _loadQuests(),
        _loadFactions(),
        _loadNpc(),
        _loadSystems(),
        _loadScripts(),
      ]);

      _loaded = true;
      GameLogger.data('All game data loaded successfully');
    } catch (e, stack) {
      GameLogger.error('Failed to load game data', e, stack);
      rethrow;
    }
  }

  /// Load JSON asset
  Future<dynamic> _loadJson(String path) async {
    try {
      final String jsonString = await rootBundle.loadString(path);
      return jsonDecode(jsonString);
    } catch (e) {
      GameLogger.warn('Failed to load: $path');
      return null;
    }
  }

  /// Load balance data
  Future<void> _loadBalance() async {
    final json = await _loadJson('assets/game_data/systems/balance.json');
    if (json != null) {
      balance = BalanceDef.fromJson(json);
      GameLogger.data('Balance loaded');
    } else {
      balance = BalanceDef.defaultBalance();
    }
  }

  /// Load items
  Future<void> _loadItems() async {
    final json = await _loadJson('assets/game_data/items/items_master.json');
    if (json != null && json['items'] != null) {
      for (final item in json['items']) {
        final def = ItemDef.fromJson(item);
        items[def.id] = def;
      }
      GameLogger.data('Loaded ${items.length} items');
    }
  }

  /// Load recipes
  Future<void> _loadRecipes() async {
    final json = await _loadJson('assets/game_data/crafting/recipes_master.json');
    if (json != null && json['recipes'] != null) {
      for (final recipe in json['recipes']) {
        final def = RecipeDef.fromJson(recipe);
        recipes[def.id] = def;
      }
      GameLogger.data('Loaded ${recipes.length} recipes');
    }
  }

  /// Load events
  Future<void> _loadEvents() async {
    final json = await _loadJson('assets/game_data/events/events_master.json');
    if (json != null && json['events'] != null) {
      for (final event in json['events']) {
        final id = event['id'] as String?;
        if (id != null) {
          events[id] = Map<String, dynamic>.from(event);
        }
      }
      GameLogger.data('Loaded ${events.length} events');
    }
  }

  /// Load locations and districts
  Future<void> _loadLocations() async {
    final json = await _loadJson('assets/game_data/world/locations_master.json');
    if (json != null) {
      // Load districts
      if (json['districts'] != null) {
        for (final district in json['districts']) {
          final def = DistrictDef.fromJson(district);
          districts[def.id] = def;
        }
      }

      // Load locations
      if (json['locations'] != null) {
        for (final location in json['locations']) {
          final def = LocationDef.fromJson(location);
          locations[def.id] = def;
        }
      }

      GameLogger.data('Loaded ${districts.length} districts, ${locations.length} locations');
    }
  }

  /// Load loot tables
  Future<void> _loadLootTables() async {
    final json = await _loadJson('assets/game_data/loot/loot_tables_master.json');
    if (json != null && json['tables'] != null) {
      for (final table in json['tables']) {
        final def = LootTableDef.fromJson(table);
        lootTables[def.id] = def;
      }
      GameLogger.data('Loaded ${lootTables.length} loot tables');
    }
  }

  /// Load quests
  Future<void> _loadQuests() async {
    final json = await _loadJson('assets/game_data/quests/quests_master.json');
    if (json != null && json['quests'] != null) {
      for (final quest in json['quests']) {
        final def = QuestDef.fromJson(quest);
        quests[def.id] = def;
      }
      GameLogger.data('Loaded ${quests.length} quests');
    }
  }

  /// Load factions
  Future<void> _loadFactions() async {
    final json = await _loadJson('assets/game_data/factions/factions_master.json');
    if (json != null && json['factions'] != null) {
      for (final faction in json['factions']) {
        final def = FactionDef.fromJson(faction);
        factions[def.id] = def;
      }
      GameLogger.data('Loaded ${factions.length} factions');
    }
  }

  /// Load NPC data
  Future<void> _loadNpc() async {
    // Load traits
    final traitsJson = await _loadJson('assets/game_data/npc/traits_library.json');
    if (traitsJson != null && traitsJson['traits'] != null) {
      for (final trait in traitsJson['traits']) {
        final def = TraitDef.fromJson(trait);
        traits[def.id] = def;
      }
      GameLogger.data('Loaded ${traits.length} traits');
    }

    // Load trait conflicts
    final conflictsJson = await _loadJson('assets/game_data/npc/trait_conflicts.json');
    if (conflictsJson != null) {
      traitConflicts = Map<String, dynamic>.from(conflictsJson);
    }

    // Load NPC templates
    final templatesJson = await _loadJson('assets/game_data/npc/npc_templates_master.json');
    if (templatesJson != null && templatesJson['templates'] != null) {
      for (final template in templatesJson['templates']) {
        final def = NpcTemplate.fromJson(template);
        npcTemplates[def.id] = def;
      }
      GameLogger.data('Loaded ${npcTemplates.length} NPC templates');
    }
  }

  /// Load system data
  Future<void> _loadSystems() async {
    // Load depletion system
    final depletionJson = await _loadJson('assets/game_data/systems/depletion_system.json');
    if (depletionJson != null) {
      depletionSystem = Map<String, dynamic>.from(depletionJson);
    }

    // Load trade system
    final tradeJson = await _loadJson('assets/game_data/systems/trade_system.json');
    if (tradeJson != null) {
      tradeSystem = Map<String, dynamic>.from(tradeJson);
    }
  }

  /// Load scripts
  Future<void> _loadScripts() async {
    final json = await _loadJson('assets/game_data/scripts/scripts_master.json');
    if (json != null && json['scripts'] != null) {
      for (final script in json['scripts']) {
        final id = script['id'] as String?;
        if (id != null) {
          scripts[id] = Map<String, dynamic>.from(script);
        }
      }
      GameLogger.data('Loaded ${scripts.length} scripts');
    }
  }

  // Getters

  ItemDef? getItem(String id) => items[id];
  RecipeDef? getRecipe(String id) => recipes[id];
  Map<String, dynamic>? getEvent(String id) => events[id];
  DistrictDef? getDistrict(String id) => districts[id];
  LocationDef? getLocation(String id) => locations[id];
  LootTableDef? getLootTable(String id) => lootTables[id];
  QuestDef? getQuest(String id) => quests[id];
  FactionDef? getFaction(String id) => factions[id];
  TraitDef? getTrait(String id) => traits[id];
  NpcTemplate? getNpcTemplate(String id) => npcTemplates[id];
  Map<String, dynamic>? getScript(String id) => scripts[id];
}
