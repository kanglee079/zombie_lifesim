# Zombie LifeSim - Flutter Game

A text-based zombie apocalypse life simulation game built with Flutter.

## Features
- Data-driven gameplay from JSON files
- Scavenge, craft, trade system
- NPC party management
- Multiple endings

## Run
```bash
flutter run
```

## New systems: NightThreat2, Triangulation, Countdown, Listener
- NightThreat2: weighted nightly threat with severity-biased night event cards.
- Triangulation: daily signal-heat checks that can trigger night/base pursuit events.
- Countdown: timed triggers that enqueue events when timers expire.
- Listener: hidden trace meter tied to radio use and signal heat thresholds.
