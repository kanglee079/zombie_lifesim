import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/logger.dart';
import 'game_state.dart';

/// Manager for saving and loading game state
class SaveManager {
  static const String _boxName = 'game_saves';
  static const String _currentSaveKey = 'current_save';
  static const int _saveVersion = 1;

  Box? _box;

  /// Initialize the save manager
  Future<void> init() async {
    if (_box != null) return;
    _box = await Hive.openBox(_boxName);
    GameLogger.save('SaveManager initialized');
  }

  /// Get box, initializing if needed
  Future<Box> _getBox() async {
    if (_box == null) {
      await init();
    }
    return _box!;
  }

  /// Save game state
  Future<void> save(GameState state) async {
    try {
      final box = await _getBox();
      final json = state.toJson();
      json['savedAt'] = DateTime.now().toIso8601String();
      json['version'] = _saveVersion;
      
      final encoded = jsonEncode(json);
      await box.put(_currentSaveKey, encoded);
      
      GameLogger.save('Game saved: Day ${state.day}');
    } catch (e, stack) {
      GameLogger.error('Failed to save game', e, stack);
      rethrow;
    }
  }

  /// Load game state
  Future<GameState?> load() async {
    try {
      final box = await _getBox();
      final encoded = box.get(_currentSaveKey) as String?;
      
      if (encoded == null) {
        GameLogger.save('No save found');
        return null;
      }

      final json = jsonDecode(encoded) as Map<String, dynamic>;
      
      // Check version for migrations
      final version = json['version'] as int? ?? 0;
      if (version < _saveVersion) {
        _migrate(json, version);
      }

      final state = GameState.fromJson(json);
      GameLogger.save('Game loaded: Day ${state.day}');
      return state;
    } catch (e, stack) {
      GameLogger.error('Failed to load game', e, stack);
      return null;
    }
  }

  /// Check if save exists
  Future<bool> hasSave() async {
    final box = await _getBox();
    return box.containsKey(_currentSaveKey);
  }

  /// Delete current save
  Future<void> deleteSave() async {
    final box = await _getBox();
    await box.delete(_currentSaveKey);
    GameLogger.save('Save deleted');
  }

  /// Get save metadata without loading full state
  Future<Map<String, dynamic>?> getSaveInfo() async {
    try {
      final box = await _getBox();
      final encoded = box.get(_currentSaveKey) as String?;
      
      if (encoded == null) return null;

      final json = jsonDecode(encoded) as Map<String, dynamic>;
      return {
        'day': json['day'],
        'savedAt': json['savedAt'],
        'version': json['version'],
      };
    } catch (e) {
      return null;
    }
  }

  /// Migrate old save format to current version
  void _migrate(Map<String, dynamic> json, int fromVersion) {
    // Add migration logic here as versions change
    if (fromVersion < 1) {
      // Version 0 to 1 migration
      // No changes needed for initial version
    }
    
    json['version'] = _saveVersion;
    GameLogger.save('Migrated save from version $fromVersion to $_saveVersion');
  }

  /// Export save as string (for backup/sharing)
  Future<String?> exportSave() async {
    final box = await _getBox();
    return box.get(_currentSaveKey) as String?;
  }

  /// Import save from string
  Future<bool> importSave(String encoded) async {
    try {
      // Validate the save data
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      GameState.fromJson(json); // Will throw if invalid
      
      final box = await _getBox();
      await box.put(_currentSaveKey, encoded);
      
      GameLogger.save('Save imported');
      return true;
    } catch (e) {
      GameLogger.error('Failed to import save', e);
      return false;
    }
  }

  /// Create backup with timestamp
  Future<void> backup() async {
    try {
      final box = await _getBox();
      final current = box.get(_currentSaveKey) as String?;
      
      if (current == null) return;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await box.put('backup_$timestamp', current);
      
      // Keep only last 5 backups
      final keys = box.keys.where((k) => k.toString().startsWith('backup_')).toList();
      keys.sort();
      
      while (keys.length > 5) {
        await box.delete(keys.removeAt(0));
      }
      
      GameLogger.save('Backup created');
    } catch (e) {
      GameLogger.error('Failed to create backup', e);
    }
  }

  /// List available backups
  Future<List<String>> listBackups() async {
    final box = await _getBox();
    return box.keys
        .where((k) => k.toString().startsWith('backup_'))
        .map((k) => k.toString())
        .toList();
  }

  /// Restore from backup
  Future<bool> restoreBackup(String backupKey) async {
    try {
      final box = await _getBox();
      final backup = box.get(backupKey) as String?;
      
      if (backup == null) return false;

      await box.put(_currentSaveKey, backup);
      GameLogger.save('Restored from backup: $backupKey');
      return true;
    } catch (e) {
      GameLogger.error('Failed to restore backup', e);
      return false;
    }
  }
}
