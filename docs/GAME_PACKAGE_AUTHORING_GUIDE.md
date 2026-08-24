# Botanical Haven — Game Package Authoring Guide
## Creating Custom Standalone Game Packages

This guide walks through creating, authoring, and testing a completely new game on the Botanical Haven Engine without modifying base engine files.

---

## 1. Quick Start: Creating a New Game Package

To create a new game package programmatically or via editor:

```gdscript
var pm = GamePackageManager.get_instance()
var my_rpg = pm.create_game_package(
    "realm_of_eldoria",
    "Realm of Eldoria",
    "empty",
    "Studio Eldoria",
    "1.0.0",
    "An epic story-driven RPG with branching quests."
)
```

This creates the directory structure under `user://games/realm_of_eldoria/`:
```
user://games/realm_of_eldoria/
  ├── game.json
  ├── worlds/
  ├── npcs/
  ├── dialogue/
  ├── quests/
  ├── plants/
  ├── tools/
  ├── shops/
  └── assets/
```

---

## 2. Setting Up Starting World & Player

In `game.json`:
- Set `"starting_world": "castle_courtyard"`
- Configure `"player_definition"` (custom speed, inventory capacity, starter items).
- Set `"game_rules"` (day cycle length, stamina rules, starter currency).

---

## 3. Authoring Content via In-Game Editor

1. Load your game package: `pm.load_game_package("realm_of_eldoria")`
2. Open the **In-Game Editor (`EditorShell`)**.
3. Create your starting world canvas (`world.castle_courtyard`).
4. Create NPCs, dialogues, and quests.
5. Save changes — all content will be saved atomically under your game package!
