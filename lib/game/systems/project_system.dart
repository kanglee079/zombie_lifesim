import '../state/game_state.dart';
import '../../data/repositories/game_data_repo.dart';
import '../engine/effect_engine.dart';
import '../engine/requirement_engine.dart';
import '../../core/rng.dart';
import '../../core/logger.dart';

/// System for handling long-term base projects
class ProjectSystem {
  final GameDataRepository data;
  final EffectEngine effectEngine;
  final RequirementEngine requirementEngine;
  final GameRng rng;

  late Map<String, dynamic> _projectsData;

  ProjectSystem({
    required this.data,
    required this.effectEngine,
    required this.requirementEngine,
    required this.rng,
  }) {
    _loadProjectsData();
  }

  void _loadProjectsData() {
    _projectsData = data.getSystemData('projects') ?? {'projects': []};
  }

  /// Get all available projects for current game state
  List<Map<String, dynamic>> getAvailableProjects(GameState state) {
    final projects = _projectsData['projects'] as List<dynamic>? ?? [];
    final unlockConditions =
        _projectsData['unlockConditions'] as Map<String, dynamic>? ?? {};
    final available = <Map<String, dynamic>>[];

    for (final project in projects) {
      final projectId = project['id'] as String? ?? '';

      // Skip if already active or completed
      if (state.activeProjects.containsKey(projectId)) continue;
      if (state.completedProjects.contains(projectId)) continue;

      // Check unlock conditions
      final conditions =
          unlockConditions[projectId] as Map<String, dynamic>? ?? {};

      // Check minDay
      final minDay = conditions['minDay'] as int? ?? 1;
      if (state.day < minDay) continue;

      // Check required flags
      final requiredFlags =
          (conditions['flags'] as List<dynamic>?)?.cast<String>() ?? [];
      bool hasAllFlags = true;
      for (final flag in requiredFlags) {
        if (!state.flags.contains(flag)) {
          hasAllFlags = false;
          break;
        }
      }
      if (!hasAllFlags) continue;

      available.add(Map<String, dynamic>.from(project));
    }

    return available;
  }

  /// Check if player can start a project (has required resources)
  bool canStartProject(GameState state, String projectId) {
    final project = _getProject(projectId);
    if (project == null) return false;

    final requirements = project['requirements'] as Map<String, dynamic>? ?? {};
    final requiredItems = requirements['items'] as List<dynamic>? ?? [];

    for (final req in requiredItems) {
      final itemId = req['id'] as String? ?? '';
      final qty = req['qty'] as int? ?? 1;

      final hasItem = effectEngine.hasItem(state, itemId, qty);
      if (!hasItem) return false;
    }

    // Check flags
    final requiredFlags = requirements['flags'] as List<dynamic>? ?? [];
    for (final flag in requiredFlags) {
      if (!state.flags.contains(flag.toString())) return false;
    }

    return true;
  }

  /// Get missing items for a project
  List<Map<String, dynamic>> getMissingItems(
      GameState state, String projectId) {
    final project = _getProject(projectId);
    if (project == null) return [];

    final requirements = project['requirements'] as Map<String, dynamic>? ?? {};
    final requiredItems = requirements['items'] as List<dynamic>? ?? [];
    final missing = <Map<String, dynamic>>[];

    for (final req in requiredItems) {
      final itemId = req['id'] as String? ?? '';
      final qty = req['qty'] as int? ?? 1;

      final currentQty = effectEngine.getItemCount(state, itemId);
      if (currentQty < qty) {
        final item = data.getItem(itemId);
        missing.add({
          'id': itemId,
          'name': item?.name ?? itemId,
          'required': qty,
          'have': currentQty,
          'need': qty - currentQty,
          'hint': item?.hint ?? '',
        });
      }
    }

    return missing;
  }

  /// Start a project
  bool startProject(GameState state, String projectId) {
    if (!canStartProject(state, projectId)) return false;

    final project = _getProject(projectId);
    if (project == null) return false;

    // Consume resources
    final requirements = project['requirements'] as Map<String, dynamic>? ?? {};
    final requiredItems = requirements['items'] as List<dynamic>? ?? [];

    for (final req in requiredItems) {
      final itemId = req['id'] as String? ?? '';
      final qty = req['qty'] as int? ?? 1;
      effectEngine.removeItemFromInventory(state, itemId, qty);
    }

    // Create project state
    final duration = project['duration'] as int? ?? 1;
    state.activeProjects[projectId] = ProjectState(
      projectId: projectId,
      startDay: state.day,
      daysRemaining: duration,
      completed: false,
      lastYieldDay: state.day,
    );

    final projectName = project['name'] as String? ?? projectId;
    state.addLog('🔨 Bắt đầu dự án: $projectName ($duration ngày)');

    GameLogger.game('Project started: $projectId');
    return true;
  }

  /// Process daily project ticks (called during daily tick)
  void dailyTick(GameState state) {
    final toComplete = <String>[];

    // Process active projects
    for (final entry in state.activeProjects.entries) {
      final projectId = entry.key;
      final projectState = entry.value;

      if (projectState.completed) continue;

      // Decrement days remaining
      projectState.daysRemaining -= 1;

      if (projectState.daysRemaining <= 0) {
        toComplete.add(projectId);
      }
    }

    // Complete projects
    for (final projectId in toComplete) {
      _completeProject(state, projectId);
    }

    // Process yields from completed projects
    _processProjectYields(state);
  }

  void _completeProject(GameState state, String projectId) {
    final project = _getProject(projectId);
    if (project == null) return;

    final projectState = state.activeProjects[projectId];
    if (projectState == null) return;

    // Mark as completed
    projectState.completed = true;
    state.completedProjects.add(projectId);
    state.activeProjects.remove(projectId);

    // Execute effects
    final effects = project['effects'] as List<dynamic>? ?? [];
    effectEngine.executeEffects(effects, state);

    final projectName = project['name'] as String? ?? projectId;
    state.addLog('✅ Hoàn thành dự án: $projectName');

    GameLogger.game('Project completed: $projectId');
  }

  void _processProjectYields(GameState state) {
    for (final projectId in state.completedProjects) {
      final project = _getProject(projectId);
      if (project == null) continue;

      // Process daily yield
      final dailyYield = project['dailyYield'] as Map<String, dynamic>?;
      if (dailyYield != null) {
        _processDailyYield(state, projectId, dailyYield);
      }

      // Process cyclic yield
      final cyclicYield = project['cyclicYield'] as Map<String, dynamic>?;
      if (cyclicYield != null) {
        _processCyclicYield(state, projectId, cyclicYield);
      }

      // Process conversion (like solar still)
      final conversion = project['conversion'] as Map<String, dynamic>?;
      if (conversion != null) {
        _processConversion(state, projectId, conversion);
      }

      // Process maintenance (like indoor garden)
      final maintenance = project['maintenance'] as Map<String, dynamic>?;
      if (maintenance != null) {
        _processMaintenance(state, projectId, maintenance);
      }
    }
  }

  void _processDailyYield(
      GameState state, String projectId, Map<String, dynamic> config) {
    final chance = (config['chance'] as num?)?.toDouble() ?? 1.0;

    if (rng.nextDouble() > chance) return;

    final items = config['items'] as List<dynamic>? ?? [];
    for (final item in items) {
      final itemId = item['id'] as String? ?? '';
      final min = item['min'] as int? ?? 1;
      final max = item['max'] as int? ?? min;
      final qty = rng.range(min, max);

      if (qty > 0) {
        effectEngine.addItemToInventory(state, itemId, qty);
        final itemDef = data.getItem(itemId);
        state.addLog('🎁 Thu hoạch: ${itemDef?.name ?? itemId} x$qty');
      }
    }
  }

  void _processCyclicYield(
      GameState state, String projectId, Map<String, dynamic> config) {
    // Find the project state (we need to track last yield day)
    // Since completed projects are removed from activeProjects, we use flags
    final flagKey = 'lastYield_$projectId';
    final lastYield = (state.tempModifiers[flagKey] as int?) ?? 0;
    final interval = config['interval'] as int? ?? 1;

    if (state.day - lastYield < interval) return;

    final items = config['items'] as List<dynamic>? ?? [];
    for (final item in items) {
      final itemId = item['id'] as String? ?? '';
      final min = item['min'] as int? ?? 1;
      final max = item['max'] as int? ?? min;
      final qty = rng.range(min, max);

      if (qty > 0) {
        effectEngine.addItemToInventory(state, itemId, qty);
        final itemDef = data.getItem(itemId);
        state.addLog('🌾 Thu hoạch định kỳ: ${itemDef?.name ?? itemId} x$qty');
      }
    }

    state.tempModifiers[flagKey] = state.day;
  }

  void _processConversion(
      GameState state, String projectId, Map<String, dynamic> config) {
    final input = config['input'] as Map<String, dynamic>? ?? {};
    final output = config['output'] as Map<String, dynamic>? ?? {};

    final inputId = input['id'] as String? ?? '';
    final inputQty = input['qty'] as int? ?? 1;
    final outputId = output['id'] as String? ?? '';
    final outputQty = output['qty'] as int? ?? 1;

    // Check if we have input items
    final hasInput = effectEngine.hasItem(state, inputId, inputQty);
    if (!hasInput) return;

    // Consume input
    effectEngine.removeItemFromInventory(state, inputId, inputQty);

    // Produce output
    effectEngine.addItemToInventory(state, outputId, outputQty);

    final inputDef = data.getItem(inputId);
    final outputDef = data.getItem(outputId);
    state.addLog(
        '⚗️ Chuyển đổi: ${inputDef?.name ?? inputId} → ${outputDef?.name ?? outputId}');
  }

  void _processMaintenance(
      GameState state, String projectId, Map<String, dynamic> config) {
    final waterCost = config['waterCost'] as int? ?? 0;

    // Check if we have water
    if (waterCost > 0) {
      final hasWater = effectEngine.hasItem(state, 'water_bottle', waterCost);
      if (!hasWater) {
        state.addLog('⚠️ Không đủ nước để tưới vườn. Cây héo dần.');
        return;
      }
      effectEngine.removeItemFromInventory(state, 'water_bottle', waterCost);
    }

    // Process yield
    final yield = config['dailyYield'] as List<dynamic>? ?? [];
    for (final item in yield) {
      final itemId = item['id'] as String? ?? '';
      final min = item['min'] as int? ?? 0;
      final max = item['max'] as int? ?? min;
      final qty = rng.range(min, max);

      if (qty > 0) {
        effectEngine.addItemToInventory(state, itemId, qty);
        final itemDef = data.getItem(itemId);
        state.addLog('🥬 Thu hoạch vườn: ${itemDef?.name ?? itemId} x$qty');
      }
    }
  }

  Map<String, dynamic>? _getProject(String projectId) {
    final projects = _projectsData['projects'] as List<dynamic>? ?? [];
    for (final project in projects) {
      if (project['id'] == projectId) {
        return Map<String, dynamic>.from(project);
      }
    }
    return null;
  }

  /// Get project details
  Map<String, dynamic>? getProjectDetails(String projectId) =>
      _getProject(projectId);

  /// Get active project progress
  ProjectProgress? getProjectProgress(GameState state, String projectId) {
    final projectState = state.activeProjects[projectId];
    if (projectState == null) return null;

    final project = _getProject(projectId);
    if (project == null) return null;

    final duration = project['duration'] as int? ?? 1;
    final elapsed = duration - projectState.daysRemaining;
    final progress = elapsed / duration;

    return ProjectProgress(
      projectId: projectId,
      name: project['name'] as String? ?? projectId,
      description: project['description'] as String? ?? '',
      daysRemaining: projectState.daysRemaining,
      totalDays: duration,
      progress: progress,
    );
  }

  /// Get all active project progress
  List<ProjectProgress> getActiveProjectsProgress(GameState state) {
    final list = <ProjectProgress>[];
    for (final projectId in state.activeProjects.keys) {
      final progress = getProjectProgress(state, projectId);
      if (progress != null) list.add(progress);
    }
    return list;
  }
}

class ProjectProgress {
  final String projectId;
  final String name;
  final String description;
  final int daysRemaining;
  final int totalDays;
  final double progress;

  ProjectProgress({
    required this.projectId,
    required this.name,
    required this.description,
    required this.daysRemaining,
    required this.totalDays,
    required this.progress,
  });
}
