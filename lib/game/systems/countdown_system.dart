import '../state/game_state.dart';

/// System for handling countdown timers and expiry events
class CountdownSystem {
  void tick(GameState state) {
    if (state.countdowns.isEmpty) return;

    final expired = <String>[];
    for (final entry in state.countdowns.entries) {
      final remaining = entry.value;
      if (remaining <= 1) {
        // Countdown has expired (will be 0 or less after decrement)
        expired.add(entry.key);
      } else {
        // Decrement countdown
        state.countdowns[entry.key] = remaining - 1;
      }
    }

    for (final id in expired) {
      state.countdowns.remove(id);
      final eventId = state.countdownEvents[id];
      if (eventId != null && eventId.isNotEmpty) {
        state.eventQueue.add(eventId);
      }
      state.countdownEvents.remove(id);
    }
  }
}
