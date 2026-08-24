# Botanical Haven — Empty Game Authoring Guide
## Creating Zero-Dependency Games from the Ground Up

When creating a game with the **Empty Template**, the engine ensures absolute isolation from Botanical Haven content.

---

## 1. Clean Slate Guarantees

| Category | Botanical Haven Base Package | Empty Game Package |
| :--- | :--- | :--- |
| **Characters** | Rowan, Elias, Mira, Lyra | None (0 Default NPCs) |
| **Plants & Crops** | 28 Flower / Crop Species | None |
| **Worlds** | Farm, Village, Forest, Cavern | None (Pure Custom Maps) |
| **Quests** | 15 Botanical Haven Storylines | None |
| **Save Namespace** | `user://saves/slot_X.json` | `user://saves/<game_id>/slot_X.json` |

---

## 2. Directory Layout of an Empty Game

```
user://games/<game_id>/
  ├── game.json              # Game Package Manifest
  ├── worlds/                # Custom map definitions (*.json)
  ├── npcs/                  # Custom entities & NPCs (*.json)
  ├── items/                 # Custom items & gear (*.json)
  ├── rules/                 # Custom gameplay triggers (*.json)
  ├── dialogue/              # Custom conversation trees (*.json)
  ├── quests/                # Custom quest lines (*.json)
  └── assets/                # Custom textures, audio, fonts
```
