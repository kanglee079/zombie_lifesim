import 'dart:math';

class NumbersStationPuzzle {
  final String sequence;
  final String solution;

  const NumbersStationPuzzle({
    required this.sequence,
    required this.solution,
  });
}

class NumbersStationGenerator {
  static const String tokenSeq = 'numbers_station_seq';
  static const String tokenSolution = 'numbers_station_solution';

  static bool isToken(String value) {
    return value == tokenSeq || value == tokenSolution;
  }

  static NumbersStationPuzzle generate({required int seed, required int day}) {
    final mixedSeed = seed ^ (day * 0x9E3779B1);
    final rng = Random(mixedSeed);

    final district = rng.nextInt(6) + 1; // 1-6 => A-F
    final grid = rng.nextInt(6) + 1;
    final locker = rng.nextInt(6) + 1;

    final group1 = _buildGroup(rng, district);
    final group2 = _buildGroup(rng, grid);
    final group3 = _buildGroup(rng, locker);

    final sequence =
        '${_formatGroup(group1)} | ${_formatGroup(group2)} | ${_formatGroup(group3)}';
    final solution = '${_districtLetter(district)}-$grid-$locker';

    return NumbersStationPuzzle(sequence: sequence, solution: solution);
  }

  static List<int> _buildGroup(Random rng, int targetValue) {
    final group = <int>[];
    int sum = 0;

    for (int i = 0; i < 4; i++) {
      final value = rng.nextInt(57) + 10; // 10..66
      group.add(value);
      sum += value;
    }

    final targetRemainder = targetValue % 6;
    final needed = (targetRemainder - (sum % 6)) % 6;
    final candidates = <int>[];
    for (int value = 10; value <= 66; value++) {
      if (value % 6 == needed) {
        candidates.add(value);
      }
    }
    final pick = candidates.isEmpty
        ? rng.nextInt(57) + 10
        : candidates[rng.nextInt(candidates.length)];
    group.add(pick);
    return group;
  }

  static String _formatGroup(List<int> group) {
    return group.map((v) => v.toString().padLeft(2, '0')).join(' ');
  }

  static String _districtLetter(int value) {
    final index = value.clamp(1, 6);
    return String.fromCharCode(64 + index);
  }
}
