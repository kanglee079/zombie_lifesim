import '../../core/logger.dart';
import '../../data/models/recipe_def.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';
import '../engine/effect_engine.dart';

/// Result of a craft attempt
class CraftResult {
  final bool success;
  final String message;
  final List<String> outputItems;

  const CraftResult({
    required this.success,
    required this.message,
    this.outputItems = const [],
  });
}

/// System for handling crafting
class CraftSystem {
  final GameDataRepository data;
  final EffectEngine effectEngine;

  CraftSystem({required this.data, required this.effectEngine});

  /// Check if a recipe can be crafted
  bool canCraft(String recipeId, GameState state) {
    final recipe = data.getRecipe(recipeId);
    if (recipe == null) return false;

    // Check required tools
    for (final tool in recipe.requiresTools) {
      if (!_hasToolRequirement(state, tool)) {
        return false;
      }
    }

    // Check required flags
    for (final flag in recipe.requiresFlags) {
      if (!state.flags.contains(flag)) {
        return false;
      }
    }

    // Check inputs
    for (final input in recipe.inputs) {
      if (!_hasItemQty(state, input.itemId, input.qty)) {
        return false;
      }
    }

    return true;
  }

  /// Get missing requirements for a recipe
  Map<String, dynamic> getMissingRequirements(String recipeId, GameState state) {
    final recipe = data.getRecipe(recipeId);
    if (recipe == null) return {'error': 'Recipe not found'};

    final missingTools = <String>[];
    final missingFlags = <String>[];
    final missingInputs = <Map<String, dynamic>>[];

    // Check required tools
    for (final tool in recipe.requiresTools) {
      if (!_hasToolRequirement(state, tool)) {
        missingTools.add(tool);
      }
    }

    // Check required flags
    for (final flag in recipe.requiresFlags) {
      if (!state.flags.contains(flag)) {
        missingFlags.add(flag);
      }
    }

    // Check inputs
    for (final input in recipe.inputs) {
      final have = _getItemQty(state, input.itemId);
      if (have < input.qty) {
        missingInputs.add({
          'itemId': input.itemId,
          'need': input.qty,
          'have': have,
        });
      }
    }

    return {
      'missingTools': missingTools,
      'missingFlags': missingFlags,
      'missingInputs': missingInputs,
    };
  }

  /// Execute a craft
  CraftResult craft(String recipeId, GameState state) {
    final recipe = data.getRecipe(recipeId);
    if (recipe == null) {
      return CraftResult(success: false, message: 'Không tìm thấy công thức.');
    }

    if (!canCraft(recipeId, state)) {
      return CraftResult(success: false, message: 'Không đủ nguyên liệu hoặc công cụ.');
    }

    // Consume inputs
    for (final input in recipe.inputs) {
      effectEngine.removeItemFromInventory(state, input.itemId, input.qty);
    }

    // Add outputs
    final outputItems = <String>[];
    for (final output in recipe.outputs) {
      effectEngine.addItemToInventory(state, output.itemId, output.qty);
      outputItems.add(output.itemId);
      final item = data.getItem(output.itemId);
      state.addLog('🔨 Chế tạo được ${item?.name ?? output.itemId} x${output.qty}');
    }

    // Execute craft effects
    if (recipe.effectsOnCraft.isNotEmpty) {
      effectEngine.executeEffects(recipe.effectsOnCraft, state);
    }

    // Award XP
    state.playerSkills.setByName(
      'craft',
      state.playerSkills.craft + 1,
    );

    GameLogger.game('Crafted: $recipeId');

    return CraftResult(
      success: true,
      message: 'Chế tạo thành công ${recipe.name}!',
      outputItems: outputItems,
    );
  }

  /// Get all available recipes
  List<RecipeDef> getAvailableRecipes(GameState state) {
    return data.recipes.values.where((r) => canCraft(r.id, state)).toList();
  }

  /// Get all known recipes (shown but maybe not craftable)
  List<RecipeDef> getKnownRecipes(GameState state) {
    return data.recipes.values.where((r) {
      // Check required flags only
      for (final flag in r.requiresFlags) {
        if (!state.flags.contains(flag)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  bool _hasItem(GameState state, String itemId) {
    return state.inventory.any((s) => s.itemId == itemId && s.qty > 0);
  }

  bool _hasToolRequirement(GameState state, String requirement) {
    if (!requirement.startsWith('tool:')) {
      return _hasItem(state, requirement);
    }

    final toolTag = requirement.substring(5);
    for (final stack in state.inventory) {
      if (stack.qty <= 0) continue;
      final item = data.getItem(stack.itemId);
      if (item == null) continue;
      final hasSpecificTag = item.tags.contains(toolTag);
      if (hasSpecificTag) {
        return true;
      }
    }

    return false;
  }

  bool _hasItemQty(GameState state, String itemId, int qty) {
    return _getItemQty(state, itemId) >= qty;
  }

  int _getItemQty(GameState state, String itemId) {
    int total = 0;
    for (final stack in state.inventory) {
      if (stack.itemId == itemId) {
        total += stack.qty;
      }
    }
    return total;
  }
}
