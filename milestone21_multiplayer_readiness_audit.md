# PHASE 1 — MULTIPLAYER READINESS AUDIT & ARCHITECTURE DESIGN
## Comprehensive Architecture, State Classification & Phased Migration Plan (2–4 Player Cooperative Shared World)

---

## 1. Executive Summary

This audit evaluates the codebase of our 2D botanical farming, synthesis, and exploration game to establish clear architectural boundaries for future **2–4 player cooperative multiplayer** (inspired by Stardew Valley and Terraria).

### Core Architectural Principle
* **Shared World State**: World layout, terrain, plants, growth/watered status, NPC schedules/states, time/day, weather, world container contents, shared discoveries, and world unlocks.
* **Player State**: Character identity, active world location, grid position, inventory items, equipment, personal quest progression, personal rewards, and statistics.
* **Local State**: Resolution, window mode, audio volume, keybindings, graphics toggles, camera preferences, and client UI focus.

### Current Architectural Verdict: **`NEEDS REFACTOR`**
* The existing systems are cleanly modularized into Autoload singletons and data-driven catalogs (`JSON`), but several singletons assume a **single global player** (e.g., `InventoryManager`, `EconomyManager`, `PlayerInteraction`, `WorldManager.current_world_id`).
* Before introducing any networking (ENet/WebSocket/RPC), state ownership must be formally decoupled into `SharedWorldState` and `PlayerState` abstractions.

---

## 2. Current Architecture Overview

```
                                  [ GAME CLIENT ]
                                         │
    ┌────────────────────────────────────┼────────────────────────────────────┐
    ↓                                    ↓                                    ↓
[SHARED / GLOBAL MANAGERS]     [PLAYER CONTROLLER]                  [LOCAL & UI SYSTEMS]
- WorldManager                 - Player (CharacterBody2D)           - SettingsManager
- WorldLoader                  - PlayerMovement                     - SettingsUI
- GridManager                  - PlayerInteraction                  - HUD / Menus
- PlantManager                 - PlayerAnimation                    - AudioManager
- TimeManager / Weather        - Camera2D (Local)                   - EffectSpawner
- NPCManager / Dialogue
- ShopManager / EconomyManager (Currently Global Single Player)
- InventoryManager (Currently Global Single Player)
- CombinationManager / JournalManager
- ProgressionManager / QuestManager
```

---

## 3. Shared World State Inventory

| State Variable | Current Owner | Recommended Owner | Category | Multiplayer Rationale & Impact |
| :--- | :--- | :--- | :--- | :--- |
| `tiles` / `grid_data` | `GridManager` / `WorldLoader` | `SharedWorldState` | `SHARED_WORLD` | All players see the same tile types, tilled soil, paths, and obstacles. |
| `plant_instances` | `GridManager` | `SharedWorldState` | `SHARED_WORLD` | Crop species, growth stage, days in stage, and watered state are shared. |
| `current_day` / `time` | `TimeManager` | `SharedWorldState` | `SHARED_WORLD` | All players experience the same in-game calendar, day cycle, and season. |
| `current_weather` | `WeatherManager` | `SharedWorldState` | `SHARED_WORLD` | Rain, sunshine, and storms affect all players and water crops collectively. |
| `npc_positions` / `schedules` | `NPCManager` | `SharedWorldState` | `SHARED_WORLD` | NPC locations, movement paths, and shopkeeper availability are shared. |
| `unlocked_worlds` | `ProgressionManager` | `SharedWorldState` | `SHARED_WORLD` | When Town, Forest, or Botanical Grove unlocks, all players gain access. |
| `discovered_combinations` | `CombinationManager` | `SharedWorldState` | `SHARED_WORLD` | Formulas unlocked in the Synthesis Lab become known in the global Codex. |
| `world_objects` (Chests, Doors) | `WorldLoader` | `SharedWorldState` | `SHARED_WORLD` | Chest placement and inventory contents in world containers are shared. |

---

## 4. Player State Inventory

| State Variable | Current Owner | Recommended Owner | Category | Multiplayer Rationale & Impact |
| :--- | :--- | :--- | :--- | :--- |
| `player_id` | *Implicit (Single Player)* | `PlayerState` | `PLAYER` | Unique peer ID (`peer_id` or session UUID, e.g. `p_1`, `p_2`). |
| `character_data` (Name, Skin) | *Implicit* | `PlayerState` | `PLAYER` | Custom appearance, colors, and player name tag. |
| `current_world` | `WorldManager.current_world_id` | `PlayerState` | `PLAYER` | **Critical**: Player A can be in `farm` while Player B is in `town`. |
| `grid_position` / `facing` | `Player.grid_position` | `PlayerState` | `PLAYER` | Real-time spatial position and look direction per player. |
| `items` (Inventory) | `InventoryManager.items` | `PlayerState` | `PLAYER` | Personal bag items, seed counts, harvested crops, and tools. |
| `selected_item_id` | `InventoryManager` | `PlayerState` | `PLAYER` | Active equipped seed/tool held in hands. |
| `gold` / `wallet` | `EconomyManager.gold` | `PlayerState` | `PLAYER` | Personal currency (or configurable shared wallet). |
| `personal_quests` | `QuestManager.quest_states` | `PlayerState` | `PLAYER` | Tutorial progression, personal task completion, claimed rewards. |
| `player_stats` | *Implicit* | `PlayerState` | `PLAYER` | Personal harvest counts, steps taken, energy levels. |

---

## 5. Local State Inventory

| State Variable | Current Owner | Recommended Owner | Category | Multiplayer Rationale & Impact |
| :--- | :--- | :--- | :--- | :--- |
| `resolution` / `window_mode` | `SettingsManager` / `SettingsData` | `LOCAL_STATE` | `LOCAL` | Display settings must remain strictly client-side. |
| `audio_volumes` (Master/SFX/Music)| `SettingsManager` / `AudioManager` | `LOCAL_STATE` | `LOCAL` | Local user sound mixer preferences. |
| `keybindings` / `input_map` | `SettingsManager` | `LOCAL_STATE` | `LOCAL` | Keyboard and gamepad mapping per client. |
| `screen_shake` / `floating_text` | `SettingsManager` / `EffectSpawner` | `LOCAL_STATE` | `LOCAL` | Visual accessibility and HUD comfort toggles. |
| `camera_zoom` / `camera_target` | `Camera2D` | `LOCAL_STATE` | `LOCAL` | Each player controls their own viewport and zoom level. |
| `open_modals` (UI Visibility) | `InventoryUI`, `JournalUI`, etc. | `LOCAL_STATE` | `LOCAL` | Menu openings are local client overlays, not blocking other peers. |

---

## 6. Unknown / Ambiguous State Analysis

| State Variable | Current Ambiguity | Potential Classifications | Recommended Resolution |
| :--- | :--- | :--- | :--- |
| **Shipping Bin / Sell Box** | Is sold crop revenue shared among all players or given to seller? | `SHARED_WORLD` vs `PLAYER` | **Hybrid**: Shared shipping bin where total morning revenue is deposited into personal wallets or shared farm co-op pool (configurable setting). |
| **NPC Friendship & Romance** | Do NPCs build relationships with the farm collectively or per player? | `SHARED_WORLD` vs `PLAYER` | **`PLAYER`**: Each player maintains separate dialogue progression and friendship points with NPCs (like Stardew Valley). |
| **Story Chapter Quests** | Does completing Chapter 1 advance the chapter for everyone? | `SHARED_WORLD` vs `PLAYER` | **`SHARED_WORLD`**: World unlocks and main storyline chapters are shared; tutorial steps (`quest_01` to `quest_03`) are `PLAYER`. |

---

## 7. Manager Dependency Graph & Refactor Requirements

### Current Dependency Graph
```
[PlayerInteraction] ──(Direct Mutation)──> [InventoryManager] (Global)
                    ──(Direct Mutation)──> [GridManager] (Local Scene)
                    ──(Direct Mutation)──> [WorldManager] (Global Active World)

[CombinationManager] ──(Direct Mutation)──> [InventoryManager] (Deducts & Rewards Global Items)
                     ──(Direct Mutation)──> [JournalManager] (Unlocks Discovery)
```

### Identified Architectural Issues
1. **Global Inventory Single Player Coupling**:
   * `InventoryManager` is a singleton with one `items` dictionary. If Player A plants a seed, `InventoryManager.remove_item()` deducts from the global singleton, affecting Player B.
   * *Fix*: Move inventory data into a `PlayerInventory` resource/component attached to each `Player` instance; `InventoryManager` acts as a local proxy for the local player.
2. **Single Active World Assumption in WorldManager**:
   * `WorldManager.current_world_id` stores only ONE string. If Player A is on Farm and Player B walks into Town, changing `current_world_id` would force-transition or break Player A.
   * *Fix*: `WorldManager` must manage multiple active/cached world instances (`worlds_cache: Dictionary[String, WorldInstance]`), tracking `player_world_locations: Dictionary[player_id, world_id]`.
3. **Synthesis Deduction & Reward Coupling**:
   * `CombinationManager.perform_combination()` currently queries `/root/InventoryManager` directly to remove ingredients and give output items.
   * *Fix*: `perform_combination(player_id: String, input_a: String, input_b: String)`. Ingredients are deducted from `player_id`'s inventory, the discovery is registered to `SharedWorldState`, and the reward is given to `player_id`.

---

## 8. Save Architecture Audit

### Current Save Structure (v7)
```json
{
  "version": 7,
  "timestamp": 1787470000,
  "day": 3,
  "current_world": "farm",
  "player": { "position": [16, 12], "facing": [0, 1] },
  "inventory": { "items": { "seed_red_flower": 4 }, "selected": "seed_red_flower" },
  "economy": { "gold": 150 },
  "world_states": { "farm": { ... }, "town": { ... } },
  "discoveries": { "discovered_combos": ["combo_001"] },
  "progression": { "unlocked_worlds": { "farm": true, "town": true } },
  "quests": { ... }
}
```

### Target Multiplayer-Ready Save Architecture
```
savegame/ (or .json structure)
├── world_data/ (SharedWorldState)
│   ├── calendar.json (day, time, season, weather)
│   ├── world_tiles_and_plants.json (per-world grid & crop states)
│   ├── discoveries.json (shared unlocked formulas)
│   ├── progression.json (unlocked worlds, main chapters)
│   └── shared_chests.json
└── players/ (Per-Player State)
    ├── host_player.json (inventory, gold, position, world_id, personal_quests)
    ├── peer_2.json
    └── peer_3.json
```

* **Backward Compatibility**: `SaveData.from_dict()` will detect legacy v1–v7 single-player saves and automatically map them into `world_data` + `players/host_player` without data loss.

---

## 9. Gameplay Ownership Matrix

| System | Action / Event | State Affected | Owner | Network Sync Scope |
| :--- | :--- | :--- | :--- | :--- |
| **Farming** | Till Soil / Plant Seed | Grid tile & PlantInstance | `SHARED_WORLD` | Broadcast to all players in that world |
| **Farming** | Water Soil | PlantInstance `watered_today` | `SHARED_WORLD` | Broadcast to all players in that world |
| **Farming** | Harvest Crop | Crop removed from tile | `SHARED_WORLD` | Broadcast to all players in that world |
| **Farming** | Receive Harvest Items | Harvested crop added to bag | `PLAYER` | Local to Harvester (`peer_id`) |
| **Synthesis** | Consume Ingredients | 2 crops removed | `PLAYER` | Local to Crafter (`peer_id`) |
| **Synthesis** | Discover Formula | Formula added to Codex | `SHARED_WORLD` | Broadcast to all connected players |
| **Synthesis** | Receive Crafted Reward| 1 crop + seed given | `PLAYER` | Local to Crafter (`peer_id`) |
| **Economy** | Buy Seed / Sell Crop | Gold & Inventory updated | `PLAYER` | Local to Transactor (`peer_id`) |
| **Economy** | Shop Tier Unlock | New seed tiers available | `SHARED_WORLD` | Broadcast to all players |
| **World** | Unlock Forest / Grove | World access granted | `SHARED_WORLD` | Broadcast + Toast Banner to all |
| **World** | Travel to Another Map | Player transitions scene | `PLAYER` | Player world instance assignment |

---

## 10. Combination & Discovery Separation Rule

### Synthesis Rule Definition
When **Player A** combines `Red Flower` + `Blue Flower` in the Laboratory:
1. **Player A State Mutation**:
   * Deduct 1 `red_flower` and 1 `blue_flower` from Player A's inventory.
   * Add 1 `purple_flower` and 1 `seed_purple_flower` to Player A's inventory.
2. **Shared World State Mutation**:
   * Add `combo_001` (`purple_flower`) to `SharedWorldState.discovered_combinations`.
   * Emit `shared_discovery_unlocked("combo_001", "purple_flower")`.
3. **Player B Experience**:
   * Player B's Discovery Journal (`JournalUI`) instantly displays `Purple Flower` as discovered.
   * Player B receives **NO** free inventory items or seeds.
   * Player B can view the formula and craft it themselves using their own materials.

---

## 11. Quest & Progression Separation

* **Shared Quests (World Storyline)**:
  * `quest_06: Visit the Town` ➔ Unlocks Whispering Forest for all players.
  * `quest_09: Wild Specimens` ➔ Unlocks Botanical Grove for all players.
  * `quest_10: The Hidden Grove` ➔ Master Botanist world achievement.
* **Personal Quests (Tutorial & Personal Growth)**:
  * `quest_01: First Seeds` ➔ Personal farming tutorial.
  * `quest_02: Keep Them Alive` ➔ Personal watering exercise.
  * `quest_03: First Harvest` ➔ Personal harvest reward.
  * `quest_04: Botanical Alchemy` ➔ Personal synthesis milestone.

---

## 12. World Builder Authoring vs Runtime Boundary

* **Authoring Data (Static)**:
  * Authored in World Builder: `res://data/worlds/*.json`.
  * Contains immutable definitions: base terrain, tile types, building prefabs, NPC initial placements, spawn points, and world transitions.
* **Runtime World State (Dynamic)**:
  * Initialized from authored JSON upon world creation.
  * Mutated during gameplay: tilled soil, planted crops, growth stages, chest contents, opened doors.
  * Completely separated from the authoring JSON to ensure clean save/load and zero pollution of level editor assets.

---

## 13. Entity ID Hardening Audit

| Entity Type | Current ID Format | Stability / Uniqueness | Multiplayer Suitability | Required Hardening |
| :--- | :--- | :--- | :--- | :--- |
| **Player** | Implicit | N/A | Low | Assign explicit `player_id` (e.g. `p_host`, `p_peer_1`). |
| **World** | String (`farm`, `town`) | High | Excellent | Stable key used across all world caches. |
| **Tile Coord** | `Vector2i(x, y)` | High | Excellent | Perfect spatial hash key for tile/plant lookup. |
| **Plant Instance** | Keyed by `Vector2i` | High | High | `(world_id, Vector2i)` uniquely identifies any plant in the universe. |
| **Chest / Object** | `chest_01`, `tree_02` | Medium | Medium | Prefix with `world_id` (e.g. `farm_chest_01`) to prevent cross-world collision. |
| **Item ID** | `seed_red_flower` | High | Excellent | Immutable string identifier from `AssetRegistry`. |
| **Quest ID** | `quest_01` | High | Excellent | Immutable string identifier from `base_quests.json`. |

---

## 14. Event & Signal Boundary Audit

### Target Decoupled Event Flow
```
[Gameplay Action] (Player clicks till/harvest/craft)
       │
       ▼
[State Mutation] (SharedWorldState or PlayerState modified)
       │
       ▼
[EventBus Signal] (Emits typed signal with entity/player context)
       ├──> [Local UI Update] (HUD, InventoryUI, JournalUI)
       ├──> [Audio / FX] (SFX, floating text, particle effects)
       └──> [Future Network Dispatcher] (Replication packet to peers)
```

* **Context Parameter Enrichment**:
  * Currently: `EventBus.plant_planted.emit(pos: Vector2i, plant_id: String)`
  * Multiplayer-Ready: `EventBus.plant_planted.emit(player_id: String, world_id: String, pos: Vector2i, plant_id: String)`

---

## 15. Multiplayer Mock Test Scenarios (Design)

| Scenario No | Scenario Title | Action & Observation Description | Validation Assertion |
| :--- | :--- | :--- | :--- |
| **MOCK 1** | Shared Planting | Player A plants `red_flower` at `(5, 5)` on `farm`. | Player B's grid renderer on `farm` displays stage 0 sprout at `(5, 5)`. |
| **MOCK 2** | Shared Watering | Player A waters `(5, 5)`. | Player B observes dark watered soil at `(5, 5)`. |
| **MOCK 3** | Harvest Ownership | Player A harvests mature `red_flower` at `(5, 5)`. | Tile becomes empty; Player A receives 1 crop; Player B receives 0 items. |
| **MOCK 4** | Shared Discovery | Player A synthesizes `purple_flower`. | `SharedWorldState` discovers `combo_001`; Player B sees formula in Journal. |
| **MOCK 5** | Synthesis Reward | Player A synthesizes `purple_flower`. | Player A receives seed reward; Player B receives NO seed reward. |
| **MOCK 6** | Inventory Isolation| Player A buys 5 seeds in shop. | Player A's bag count increases by 5; Player B's inventory is unchanged. |
| **MOCK 7** | Shared Container | Player A puts 3 crops into `farm_chest_01`. | Player B opens `farm_chest_01` and sees 3 crops. |
| **MOCK 8** | Multi-World Presence| Player A enters `town`; Player B stays in `farm`. | Both players continue updating in their respective worlds without collision. |
| **MOCK 9** | Shared Calendar | TimeManager advances to Day 2. | Both players observe Day 2 notification and morning crop growth. |
| **MOCK 10**| World Unlock | Player A completes Chapter 2. | Whispering Forest unlocks; both Player A and Player B can travel to Forest. |
| **MOCK 11**| Personal Quests | Player A completes `quest_01`. | Player A's status is `completed`; Player B's `quest_01` remains in progress. |
| **MOCK 12**| Shared World Quests| Community goal completed. | Both players observe quest completion and shared world progress update. |

---

## 16. Architectural Risks & Mitigations

1. **Risk: Single-Player Singleton Refactoring Regression**
   * *Mitigation*: Maintain singleton wrappers (`InventoryManager.get_instance()`) that default to `player_id = "local_player"` in single-player mode, preserving 100% backward compatibility with existing UI.
2. **Risk: Multi-World Camera & Audio Desynchronization**
   * *Mitigation*: Audio and camera controllers must listen only to the local client's controlled player character.
3. **Risk: Save File Bloat / Corruption**
   * *Mitigation*: Atomic save file writes (`.tmp` + rename) with separate sub-dictionaries for `world` and `players`.

---

## 17. Recommended Architecture: Decoupled State Model

```
                    ┌───────────────────────────────┐
                    │      CO-OP SESSION ROOT       │
                    └───────────────┬───────────────┘
                                    │
         ┌──────────────────────────┴──────────────────────────┐
         ↓                                                     ↓
┌─────────────────────────────┐               ┌─────────────────────────────┐
│      SHARED WORLD STATE     │               │     PLAYER STATE REGISTRY   │
│  - Multi-World Tile Grids   │               │  - Player 1 (Host State)    │
│  - Plant Instances / Growth │               │  - Player 2 (Peer State)    │
│  - World Calendar & Weather │               │  - Player 3 (Peer State)    │
│  - Discovered Combinations  │               │  - Player 4 (Peer State)    │
│  - World Container Chests   │               │                             │
│  - Unlocked World Areas     │               │  * Inventory, Gold, Position│
│  - Main Story Chapters      │               │  * Personal Quests, Skills  │
└─────────────────────────────┘               └─────────────────────────────┘
```

---

## 18. Phased Refactor Roadmap

```
PHASE 1 (Completed): Readiness Audit & Architecture Design
       │
       ▼
PHASE 2: SharedWorldState Extraction (Decouple grids, plants, calendar, discoveries)
       │
       ▼
PHASE 3: PlayerState Extraction (Decouple inventory, gold, position, personal quests)
       │
       ▼
PHASE 4: Local State Isolation (Settings, Camera, Audio, UI Modals)
       │
       ▼
PHASE 5: Manager Dependency Cleanup (Single-Player compatibility adapters)
       │
       ▼
PHASE 6: Save Architecture Preparation (Dual World/Player save container with v1-v7 migration)
       │
       ▼
PHASE 7: Gameplay Event Boundary Cleanup (Enrich EventBus with player_id & world_id)
       │
       ▼
PHASE 8: Entity Identity Hardening (Unique composite keys for objects & containers)
       │
       ▼
PHASE 9: Multiplayer Mock Test Suite (Verify all 12 mock scenarios in local runtime)
       │
       ▼
PHASE 10: Full Regression & Milestone Sign-Off
```

---

## 19. Migration Strategy

* **Phase 2–5 (Non-Breaking In-Place Migration)**:
  * Existing singletons (`InventoryManager`, `QuestManager`, `WorldManager`) become facades routing to `PlayerState` (defaulting to the local player ID `player_1`).
  * Existing scenes (`farm.tscn`, `world_builder.tscn`) continue running without modification.
* **Save Migration**:
  * Existing save files (v1 through v7) are seamlessly ingested by `SaveData.from_dict()`, mapping global inventory/player coordinates into `players["player_1"]` and world tiles into `world_states`.

---

## 20. Regression Strategy

To guarantee that gameplay remains 100% unbroken throughout subsequent refactor phases:
1. **Automated GDScript Validation**: Run `script_validate` on all 101+ scripts after every step.
2. **Scene Validation**: Run `scene_validate` across `farm.tscn`, `world_builder.tscn`, `settings_ui.tscn`, `journal_ui.tscn`.
3. **Runtime Test Suite**: Execute the 25-point gameplay loop regression:
   `Plant ➔ Water ➔ Grow ➔ Harvest ➔ Combine ➔ Discover ➔ Journal ➔ Quest ➔ Shop ➔ World Transition ➔ Save/Load`.

---

## System Audit Matrix Summary Table

| System | Current Owner | Recommended Owner | Type | Multiplayer Risk | Action |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Grid / Tiles** | `GridManager` / `WorldLoader` | `SharedWorldState` | `SHARED_WORLD` | Low | Group under SharedWorldState per world. |
| **Plant Instances** | `GridManager` | `SharedWorldState` | `SHARED_WORLD` | Low | Extract crop growth state into SharedWorldState. |
| **Inventory** | `InventoryManager` (Global) | `PlayerState` | `PLAYER` | **High** | Refactor into `PlayerInventory` per player entity. |
| **Economy (Gold)**| `EconomyManager` (Global) | `PlayerState` | `PLAYER` | Medium | Make wallet player-owned. |
| **Combination** | `CombinationManager` | `SharedWorldState` + `Player` | `DERIVED` | **High** | Split formula discovery (World) from ingredient consumption (Player). |
| **Journal** | `JournalManager` | `SharedWorldState` + `Player` | `DERIVED` | Medium | Read shared discoveries + personal inventory. |
| **Quests** | `QuestManager` | `SharedWorldState` + `Player` | `DERIVED` | **High** | Split world unlocks (World) from tutorial/personal quests (Player). |
| **Progression** | `ProgressionManager` | `SharedWorldState` | `SHARED_WORLD` | Medium | Keep world unlock state shared across all peers. |
| **Time & Calendar**| `TimeManager` | `SharedWorldState` | `SHARED_WORLD` | Low | World calendar shared by all connected players. |
| **Weather** | `WeatherManager` | `SharedWorldState` | `SHARED_WORLD` | Low | Weather synchronized across shared worlds. |
| **NPCs** | `NPCManager` | `SharedWorldState` | `SHARED_WORLD` | Medium | Positions shared; friendship points per player. |
| **World Transitions**| `WorldManager` (Single world) | `WorldManager` (Multi-inst) | `PLAYER` | **High** | Support concurrent players on different world maps. |
| **Settings** | `SettingsManager` | `LOCAL_STATE` | `LOCAL` | None | Strictly client-side, zero network replication. |
| **Save / Load** | `SaveManager` / `SaveData` | `SaveManager` | `DERIVED` | Medium | Split save into world data + player data buckets. |

---

## Final Architecture Status Verdict

### **ARCHITECTURE STATUS: `NEEDS REFACTOR`**

**Rationale**:
The current codebase has high modularity, clean signals, and strong data-driven structures (JSON catalogs). However, single-player assumptions—specifically global singleton ownership of inventory (`InventoryManager`), wallet (`EconomyManager`), active world location (`WorldManager.current_world_id`), and combined deduction/discovery logic (`CombinationManager`)—prevent immediate multiplayer implementation.

By following the **10-Phase Refactor Roadmap** detailed in Section 18, the architecture will achieve complete multiplayer readiness with zero gameplay regressions, robust mock verification, and backward-compatible save migration.
