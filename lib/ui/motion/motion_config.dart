import 'dart:convert';
import 'package:flutter/services.dart';

class MotionPreset {
  final int durationMs;
  final double slideY;
  final double blur;
  final bool shake;
  final bool shimmer;
  final bool flicker;

  const MotionPreset({
    required this.durationMs,
    required this.slideY,
    required this.blur,
    this.shake = false,
    this.shimmer = false,
    this.flicker = false,
  });

  MotionPreset copyWith({
    int? durationMs,
    double? slideY,
    double? blur,
    bool? shake,
    bool? shimmer,
    bool? flicker,
  }) {
    return MotionPreset(
      durationMs: durationMs ?? this.durationMs,
      slideY: slideY ?? this.slideY,
      blur: blur ?? this.blur,
      shake: shake ?? this.shake,
      shimmer: shimmer ?? this.shimmer,
      flicker: flicker ?? this.flicker,
    );
  }
}

class MotionConfigCache {
  static final MotionConfigCache instance = MotionConfigCache._();
  MotionConfigCache._();

  Map<String, MotionPreset>? _presets;

  static const _defaults = {
    'default': MotionPreset(durationMs: 260, slideY: 0.04, blur: 0.0),
    'loot': MotionPreset(durationMs: 320, slideY: 0.06, blur: 2.0, shimmer: true),
    'danger': MotionPreset(durationMs: 360, slideY: 0.02, blur: 0.0, shake: true),
    'radio': MotionPreset(durationMs: 420, slideY: 0.05, blur: 2.5, flicker: true),
    'night': MotionPreset(durationMs: 340, slideY: 0.04, blur: 1.5),
  };

  Future<void> load() async {
    if (_presets != null) return;
    try {
      final raw = await rootBundle.loadString('assets/game_data/ui/ui_motion.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final presetsRaw = data['presets'] as Map<String, dynamic>? ?? {};
      final parsed = <String, MotionPreset>{};
      for (final entry in presetsRaw.entries) {
        final map = entry.value as Map<String, dynamic>? ?? {};
        parsed[entry.key] = MotionPreset(
          durationMs: (map['durationMs'] as num?)?.toInt() ?? _defaults['default']!.durationMs,
          slideY: (map['slideY'] as num?)?.toDouble() ?? _defaults['default']!.slideY,
          blur: (map['blur'] as num?)?.toDouble() ?? _defaults['default']!.blur,
          shake: map['shake'] == true,
          shimmer: map['shimmer'] == true,
          flicker: map['flicker'] == true,
        );
      }
      _presets = {..._defaults, ...parsed};
    } catch (_) {
      _presets = {..._defaults};
    }
  }

  MotionPreset preset(String id) {
    final presets = _presets ?? _defaults;
    return presets[id] ?? presets['default']!;
  }
}
