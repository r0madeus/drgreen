# Botanical Haven — Game Package Architecture Reference
## Data-Driven Game & Engine Separation (Phase 38)

The Botanical Haven Engine establishes a strict architectural boundary between **Generic Engine Systems** and **Game Packages**. Botanical Haven itself is packaged as an official Game Package (`botanical_haven`), allowing developers and modders to build completely new games (Farming, RPG, Simulation, Exploration) on top of the same engine runtime.

---

## 1. Multi-Layer Resolution Hierarchy

All content IDs (`world.*`, `npc.*`, `dialogue.*`, `quest.*`, `item.*`, `crop.*`, `tool.*`, `shop.*`) are resolved in a strict priority order:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. USER OVERRIDES (Highest Priority)                        │
│    user://editor_overrides.json (In-memory staged changes)  │
├─────────────────────────────────────────────────────────────┤
│ 2. ACTIVE MOD OVERRIDES                                     │
│    user://mods/*.bhmod (Priority-sorted mod content)        │
├─────────────────────────────────────────────────────────────┤
│ 3. ACTIVE GAME PACKAGE DATA                                 │
│    res://games/<game_id>/ or user://games/<game_id>/        │
├─────────────────────────────────────────────────────────────┤
│ 4. ENGINE DEFAULTS & FALLBACKS (Lowest Priority)            │
│    Fallback minimal world, default player setup, empty list │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Game Package Contract (`game.json`)

Every Game Package must define a `game.json` manifest at its root:

```json
{
  "game_id": "botanical_haven",
  "name": "Botanical Haven",
  "version": "1.0.0",
  "author": "Botanical Team",
  "description": "The official Botanical Haven farming and social adventure game.",
  "engine_version": "4.7.0",
  "starting_world": "farm",
  "player_definition": {
    "speed": 150.0,
    "max_energy": 100.0,
    "inventory_capacity": 24,
    "default_tools": ["hoe", "watering_can", "pickaxe", "axe"]
  },
  "content_paths": {
    "worlds": "res://data/worlds/",
    "npcs": "res://data/npcs/",
    "dialogue": "res://data/dialogue/",
    "quests": "res://data/quests/",
    "plants": "res://data/plants/",
    "tools": "res://data/tools/",
    "shops": "res://data/shops/",
    "assets": "res://assets/"
  },
  "game_rules": {
    "day_length_seconds": 720.0,
    "stamina_depletion_enabled": true,
    "starting_gold": 500,
    "seasons_enabled": true
  },
  "dependencies": []
}
```

---

## 3. Core Engine Singletons & Systems

- **`GamePackageManager` (`res://core/game_package_manager.gd`):**  
  Discovers, loads, validates, creates, and reloads game packages from `res://games/` and `user://games/`.
- **`EditorDataService` (`res://editor/core/editor_data_service.gd`):**  
  Dynamically maps entity resolution to the active game package's content paths.
- **`ModManager` (`res://editor/core/mod_manager.gd`):**  
  Supports `target_game_id` compatibility checks for `.bhmod` packages.
- **`SaveManager` (`res://systems/save/save_manager.gd`):**  
  SaveData stores `game_id` and `game_version` to prevent cross-game save corruption.
- **`NetworkSession` (`res://systems/network/network_session.gd`):**  
  Multiplayer handshake validates host and client `game_id` equivalence.
