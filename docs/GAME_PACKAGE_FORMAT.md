# Botanical Haven — Game Package Format Specification (.bhgame)
## Standard Interchange Format for User-Created Games

`.bhgame` is a self-contained, JSON-structured interchange package holding everything required to run a custom game.

---

## 1. Package Structure

```json
{
  "format": "bhgame",
  "format_version": 1,
  "exported_at": 1756041600,
  "manifest": {
    "game_id": "dungeon_crawler",
    "name": "Dungeon Crawler",
    "version": "1.0.0",
    "author": "TestDev",
    "description": "A dark dungeon quest.",
    "starting_world": "dungeon_f1",
    "content_paths": {}
  },
  "content": {
    "worlds": {
      "dungeon_f1": { ... }
    },
    "npcs": {
      "ancient_chest": { ... }
    },
    "items": {
      "dungeon_key": { ... },
      "legendary_sword": { ... }
    },
    "rules": {
      "chest_unlock": { ... }
    },
    "dialogue": {},
    "quests": {}
  }
}
```

---

## 2. Import & Security Verification

When a `.bhgame` file is imported:
1. Manifest JSON schema validation.
2. Collision check with existing `game_id` (offers rename or overwrite).
3. Target directory extraction into `user://games/<game_id>/`.
4. Live registration with `GamePackageManager`.
