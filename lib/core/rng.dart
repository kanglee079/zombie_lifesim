import 'dart:math';

/// Deterministic Random Number Generator for game consistency
class GameRng {
  late Random _random;
  int _seed;

  GameRng([int? seed]) : _seed = seed ?? DateTime.now().millisecondsSinceEpoch {
    _random = Random(_seed);
  }

  /// Get current seed
  int get seed => _seed;

  /// Reset with new seed
  void reset([int? newSeed]) {
    _seed = newSeed ?? DateTime.now().millisecondsSinceEpoch;
    _random = Random(_seed);
  }

  /// Generate random integer in range [min, max] inclusive
  int range(int min, int max) {
    if (min >= max) return min;
    return min + _random.nextInt(max - min + 1);
  }

  /// Generate random integer from 0 to max-1
  int nextInt(int max) {
    if (max <= 0) return 0;
    return _random.nextInt(max);
  }

  /// Generate random double from 0.0 to 1.0
  double nextDouble() {
    return _random.nextDouble();
  }

  /// Generate random boolean
  bool nextBool([double chance = 0.5]) {
    return _random.nextDouble() < chance;
  }

  /// Select random item from list
  T? select<T>(List<T> items) {
    if (items.isEmpty) return null;
    return items[_random.nextInt(items.length)];
  }

  /// Select item by weighted probability
  /// Returns index of selected item
  int weightedSelect(List<double> weights) {
    if (weights.isEmpty) return -1;

    double total = 0;
    for (final w in weights) {
      total += w;
    }

    if (total <= 0) return _random.nextInt(weights.length);

    double roll = _random.nextDouble() * total;
    double cumulative = 0;

    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (roll <= cumulative) {
        return i;
      }
    }

    return weights.length - 1;
  }

  /// Shuffle list in place
  void shuffle<T>(List<T> list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

  /// Roll dice: returns sum of n dice with s sides each
  int rollDice(int n, int s, [int modifier = 0]) {
    int total = modifier;
    for (int i = 0; i < n; i++) {
      total += 1 + _random.nextInt(s);
    }
    return total;
  }

  /// Check if roll succeeds against difficulty
  bool skillCheck(int skill, int difficulty) {
    final roll = 1 + _random.nextInt(20); // d20
    return roll + skill >= difficulty;
  }
}
