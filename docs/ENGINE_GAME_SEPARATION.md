# Botanical Haven — Engine & Game Separation Report
## Phase 38 Architectural Audit & Decoupling Matrix

This document outlines the systematic separation of generic engine subsystems from Botanical Haven-specific game content.

---

## 1. Subsystem Classification Matrix

| Subsystem | Previous State | Phase 38 Refactored State | Classification |
| :--- | :--- | :--- | :--- |
| **`EditorShell` / `EditorSession`** | Hardcoded category assumptions | Dynamic module outline based on active package | **Generic Engine** |
| **`EditorDataService`** | Hardcoded `["farm", "town", ...]` lists | Dynamic path resolution via `GamePackage.content_paths` | **Generic Engine** |
| **`AssetRegistry`** | Fixed `res://assets/` scanning | Multi-layer asset resolution (`User` > `Mod` > `Game` > `Engine`) | **Generic Engine** |
| **`ModManager`** | Botanical Haven only | `target_game_id` compatibility verification | **Generic Engine** |
| **`SaveManager` / `SaveData`** | Game-agnostic save structure | `game_id` and `game_version` metadata protection | **Generic Engine** |
| **`NetworkSession`** | Mode/peer tracking only | Multi-game handshake verification (`game_id`, `version`) | **Generic Engine** |
| **`WorldManager`** | Hardcoded `DEFAULT_WORLD_ID = "farm"` | Dynamic starting world resolution from active package | **Generic Engine** |
| **`Botanical Haven Data`** | Embedded in `res://data/` | Packaged as official `botanical_haven` Game Package | **Game Package** |
| **`Rowan / Elias / Mira`** | Hardcoded base references | Data-driven NPC profiles within package manifest | **Game Package** |

---

## 2. Safety & Backward Compatibility Guarantees

- **Zero Breaking Changes:** Default engine initialization loads `botanical_haven` automatically.
- **Legacy Fallback:** If `game.json` is missing on disk, `GamePackageManager` automatically synthesizes the official Botanical Haven package in memory.
- **Save Integrity:** Existing save files default to `game_id: "botanical_haven"`.
