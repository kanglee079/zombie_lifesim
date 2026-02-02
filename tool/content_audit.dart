import 'dart:convert';
import 'dart:io';

Map<String, dynamic> _loadJson(String path) {
  final file = File(path);
  final raw = file.readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

Iterable<Map<String, dynamic>> _effectsFromChoice(Map<String, dynamic> choice) sync* {
  final collected = <Map<String, dynamic>>[];

  void collect(dynamic list) {
    if (list is! List) return;
    for (final entry in list) {
      if (entry is Map<String, dynamic> && entry['type'] is String) {
        collected.add(entry);
      }
    }
  }

  collect(choice['effects']);
  collect(choice['costEffects']);

  final outcomes = choice['outcomes'];
  if (outcomes is List) {
    for (final out in outcomes) {
      if (out is Map<String, dynamic>) {
        collect(out['effects']);
      }
    }
  }

  final resolve = choice['resolve'];
  if (resolve is Map<String, dynamic>) {
    collect(resolve['successEffects']);
    collect(resolve['failEffects']);
    final success = resolve['success'];
    if (success is Map<String, dynamic>) {
      collect(success['effects']);
    }
    final fail = resolve['fail'];
    if (fail is Map<String, dynamic>) {
      collect(fail['effects']);
    }
  }

  for (final effect in collected) {
    yield effect;
  }
}

void main() {
  final itemsJson = _loadJson('assets/game_data/items/items_master.json');
  final questsJson = _loadJson('assets/game_data/quests/quests_master.json');
  final eventsJson = _loadJson('assets/game_data/events/events_master.json');
  final lootJson = _loadJson('assets/game_data/loot/loot_tables_master.json');
  final worldJson = _loadJson('assets/game_data/world/locations_master.json');
  final projectsJson = _loadJson('assets/game_data/systems/projects.json');

  final itemIds = <String>{};
  for (final item in itemsJson['items'] as List<dynamic>) {
    final id = (item as Map<String, dynamic>)['id']?.toString();
    if (id != null) itemIds.add(id);
  }

  final questIds = <String>{};
  for (final quest in questsJson['quests'] as List<dynamic>) {
    final id = (quest as Map<String, dynamic>)['id']?.toString();
    if (id != null) questIds.add(id);
  }

  final lootIds = <String>{};
  for (final table in lootJson['tables'] as List<dynamic>) {
    final id = (table as Map<String, dynamic>)['id']?.toString();
    if (id != null) lootIds.add(id);
  }

  final districtIds = <String>{};
  for (final district in worldJson['districts'] as List<dynamic>) {
    final id = (district as Map<String, dynamic>)['id']?.toString();
    if (id != null) districtIds.add(id);
  }

  final events = eventsJson['events'] as List<dynamic>;
  final eventIds = <String>{};
  final duplicateIds = <String>{};
  for (final raw in events) {
    final id = (raw as Map<String, dynamic>)['id']?.toString();
    if (id == null) continue;
    if (!eventIds.add(id)) duplicateIds.add(id);
  }

  int warnings = 0;
  void warn(String message) {
    warnings += 1;
    stderr.writeln('WARN: $message');
  }

  if (duplicateIds.isNotEmpty) {
    warn('Duplicate event IDs: ${duplicateIds.join(', ')}');
  }

  void checkProjectItem(String projectId, String itemId, String label) {
    if (!itemIds.contains(itemId)) {
      warn('Project $projectId references unknown item ($label): $itemId');
    }
  }

  final projects = projectsJson['projects'] as List<dynamic>? ?? const [];
  for (final raw in projects) {
    if (raw is! Map<String, dynamic>) continue;
    final projectId = raw['id']?.toString() ?? 'unknown';
    final requirements = raw['requirements'] as Map<String, dynamic>? ?? {};
    final requiredItems = requirements['items'] as List<dynamic>? ?? const [];
    for (final req in requiredItems) {
      if (req is Map<String, dynamic>) {
        final itemId = req['id']?.toString();
        if (itemId != null) {
          checkProjectItem(projectId, itemId, 'requirement');
        }
      }
    }

    final dailyYield = raw['dailyYield'] as Map<String, dynamic>?;
    if (dailyYield != null) {
      final items = dailyYield['items'] as List<dynamic>? ?? const [];
      for (final entry in items) {
        if (entry is Map<String, dynamic>) {
          final itemId = entry['id']?.toString();
          if (itemId != null) {
            checkProjectItem(projectId, itemId, 'dailyYield');
          }
        }
      }
    }

    final cyclicYield = raw['cyclicYield'] as Map<String, dynamic>?;
    if (cyclicYield != null) {
      final items = cyclicYield['items'] as List<dynamic>? ?? const [];
      for (final entry in items) {
        if (entry is Map<String, dynamic>) {
          final itemId = entry['id']?.toString();
          if (itemId != null) {
            checkProjectItem(projectId, itemId, 'cyclicYield');
          }
        }
      }
    }

    final conversion = raw['conversion'] as Map<String, dynamic>?;
    if (conversion != null) {
      final input = conversion['input'] as Map<String, dynamic>?;
      final output = conversion['output'] as Map<String, dynamic>?;
      final inputId = input?['id']?.toString();
      final outputId = output?['id']?.toString();
      if (inputId != null) {
        checkProjectItem(projectId, inputId, 'conversion.input');
      }
      if (outputId != null) {
        checkProjectItem(projectId, outputId, 'conversion.output');
      }
    }

    final maintenance = raw['maintenance'] as Map<String, dynamic>?;
    if (maintenance != null) {
      final items =
          maintenance['dailyYield'] as List<dynamic>? ?? const [];
      for (final entry in items) {
        if (entry is Map<String, dynamic>) {
          final itemId = entry['id']?.toString();
          if (itemId != null) {
            checkProjectItem(projectId, itemId, 'maintenanceYield');
          }
        }
      }
    }
  }

  for (final raw in events) {
    final event = raw as Map<String, dynamic>;
    final eventId = event['id']?.toString() ?? 'unknown';
    final choices = event['choices'] as List<dynamic>? ?? const [];
    for (final choiceRaw in choices) {
      if (choiceRaw is! Map<String, dynamic>) continue;
      for (final effect in _effectsFromChoice(choiceRaw)) {
        final type = effect['type']?.toString();
        if (type == null) continue;

        switch (type) {
          case 'item_add':
          case 'item_remove':
            final itemId = effect['id']?.toString();
            if (itemId != null && !itemIds.contains(itemId)) {
              warn('Event $eventId references unknown item: $itemId');
            }
            break;
          case 'items_add':
          case 'items_remove':
            final items = effect['items'];
            if (items is List) {
              for (final entry in items) {
                if (entry is Map) {
                  final itemId = entry['id']?.toString();
                  if (itemId != null && !itemIds.contains(itemId)) {
                    warn('Event $eventId references unknown item: $itemId');
                  }
                }
              }
            }
            break;
          case 'quest_stage':
          case 'quest_set_stage':
            final questId = effect['questId']?.toString() ?? effect['id']?.toString();
            if (questId != null && !questIds.contains(questId)) {
              warn('Event $eventId references unknown quest: $questId');
            }
            break;
          case 'event':
          case 'event_immediate':
            final nextId = effect['eventId']?.toString() ?? effect['id']?.toString();
            if (nextId != null && !eventIds.contains(nextId)) {
              warn('Event $eventId references unknown event: $nextId');
            }
            break;
          case 'loot_table':
            final table = effect['table']?.toString();
            if (table != null && !lootIds.contains(table)) {
              warn('Event $eventId references unknown loot table: $table');
            }
            break;
          case 'unlock_district':
            final districtId = effect['districtId']?.toString() ?? effect['id']?.toString();
            if (districtId != null && !districtIds.contains(districtId)) {
              warn('Event $eventId references unknown district: $districtId');
            }
            break;
        }
      }
    }
  }

  if (warnings == 0) {
    stdout.writeln('Content audit: OK (no warnings).');
  } else {
    stdout.writeln('Content audit: $warnings warning(s).');
  }
}
