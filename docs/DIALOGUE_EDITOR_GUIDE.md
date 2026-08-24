# In-Game Dialogue Editor Guide (Phase 30)

Botanical Haven features an integrated, standalone In-Game Dialogue Editor that allows writers, game designers, and modders to author, branch, condition-test, and localize complex NPC dialogue trees without leaving the game or touching external tools.

---

## 1. Architecture & Data-Driven Logic

The Dialogue Editor operates on the **Phase 27 Foundation & Mod Layer**:
- **Non-Destructive Overrides**: Changes are staged in memory and saved to `user://editor_overrides.json` or active mod manifests (`user://mods/<mod_id>/manifest.json`).
- **Base Game Asset Protection**: Base JSON files in `res://data/dialogue/` (`rowan.json`, `elias.json`, `mira.json`) remain strictly read-only.
- **Unified Shell Integration**: Mounted within `EditorShell`, accessible via `Main Menu -> Editor -> 💬 Dialogue`.

---

## 2. Interface Layout

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 💬 In-Game Dialogue Editor         [➕ New Node] [📋 Dup Node] [👤 Open NPC] [▶️ Play]│
├───────────────┬─────────────────────────────────────────────────────────┬──────────────┤
│ Target NPC    │  Visual Dialogue Flow                                   │ Node & Lines │
│ [Rowan     ▼] │  🔷 Node: default (Priority 0)                          │ Conditions   │
│               │     "Greetings, professor! The soil is vibrant today."  │ Choices/Acts │
│ Search:       │  🔷 Node: rain_greeting (Priority 5) [Weather: Rain]    ├──────────────┤
│ [Search...  ] │     "A refreshing rain for the crops!"                  │ Priority: 20 │
│               │  🔷 Node: heart_2_greeting (Priority 20) [Hearts >= 2]  │ Emotion: :-) │
│ ▶ default     │     "Ah, my favorite botanist! Your dedication..."      │ Lines (Text) │
│ ● rain_greet  ├─────────────────────────────────────────────────────────┤ Action: Shop │
│ ● heart2_greet│  [Portrait] Rowan                                       │              │
│ ● intro       │  "Greetings, professor! The valley's soil is vibrant."  │ Choice Links │
├───────────────┴─────────────────────────────────────────────────────────┴──────────────┤
│ NPC: Rowan  |  Changes: 0  |  Validation: OK                                            │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Core Modules & Features

### 3.1 Visual Dialogue Graph & Nodes
- **Dialogue Nodes**: Visual cards representing branches, priority levels, and dialogue lines.
- **Node Management**: Create new nodes, duplicate existing branches, modify priority (0–100), and inspect details.

### 3.2 Declarative Data-Driven Conditions
Dialogue nodes trigger dynamically based on context without hardcoded scripts:
- `heart_level`: Minimum NPC friendship heart requirement (e.g. `min: 2`).
- `friendship`: Minimum friendship points requirement (e.g. `min: 100`).
- `weather`: Active weather match (`clear`, `rain`, `storm`, `snow`).
- `season`: Active season match (`spring`, `summer`, `autumn`, `winter`).
- `quest_active` / `quest_completed`: Progress in quest lines (e.g. `quest_01`).
- `world_unlocked`: Unlocked areas (`forest`, `botanical_grove`).
- `plants_discovered`: Minimum count of harvested / cataloged crops.
- `dialogue_seen`: Prior conversation memory.

### 3.3 Player Branching Choices & Actions
- Multi-choice branching with localized options (`text`, `text_key`, `target_node`).
- Post-dialogue actions: `open_shop`, `trigger_quest`, `add_friendship`, `give_item`, `add_gold`, `set_flag`.

### 3.4 Interactive Preview & Condition Simulator
- **▶️ Interactive Preview**: Preview portrait rendering, line pacing, and branching choices.
- **🧪 Simulate Evaluation**: Adjust virtual test sliders (Simulated Weather, Season, Heart Level, Quest Status) to verify deterministic priority resolution before exporting.
- **▶️ Play in Game**: Test the active dialogue directly in the runtime dialogue UI.

### 3.5 Localization & Asset Pipeline
- Dynamic generation of stable localization keys (`dialogue.<npc>.<node>.<idx>`).
- Portrait routing through Phase 25 `AssetRegistry.get_npc_portrait(...)`.

### 3.6 Cross-Editor Integration
- **👤 Open NPC Editor**: Navigate to the NPC character profile in the NPC Editor.
- **🗺️ Open World Editor**: View NPC location in the World Editor.
