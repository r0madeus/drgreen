# In-Game Quest & Event Editor Guide (Phase 31)

Botanical Haven features a standalone, integrated In-Game Quest & Event Editor that empowers game designers and modders to author quests, configure complex multi-step objectives, wire branching prerequisite dependencies, set declarative conditions, grant rewards, and test progression without external tooling.

---

## 1. Architecture & Mod Safety

The Quest & Event Editor operates on the **Phase 27 Foundation & Mod Layer**:
- **Non-Destructive Overrides**: Changes are staged in memory and serialized to `user://editor_overrides.json` or active mod packages (`user://mods/<mod_id>/manifest.json`).
- **Base Game Data Protection**: Base JSON files in `res://data/quests/` (`base_quests.json`) remain strictly read-only.
- **Unified Shell Integration**: Mounted within `EditorShell`, accessible via `Main Menu -> Editor -> 📜 Quests`.

---

## 2. Interface Layout

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 📜 In-Game Quest & Event Editor     [➕ New Quest] [📋 Dup] [👤 Giver NPC] [▶️ Play] │
├───────────────┬─────────────────────────────────────────────────────────┬──────────────┤
│ Quest Catalog │  Quest Flow & Objective Pipeline                        │ Metadata     │
│ [Search...  ] │  🚀 Quest Start: First Seeds | Trigger: auto            │ Objectives   │
│ [All Types ▼] │     ├─────────────────────────────────────────────┤     │ Unlocks      │
│ ● quest_01    │  🎯 Objective 1: PLANT 1 [any]                          │ Rewards      │
│   quest_02    │     ├─────────────────────────────────────────────┤     ├──────────────┤
│   quest_03    │  🎁 Completion Rewards: 25 Gold | Unlocks: quest_02    │ Giver: Rowan │
│   quest_04    ├─────────────────────────────────────────────────────────┤ Type: Main   │
│   ...         │  Quest State & Simulation Diagnostics                   │ Gold: 25     │
│               │  Simulation: Quest 'First Seeds' Available | 1 Obj     │ Unlock: q_02 │
├───────────────┴─────────────────────────────────────────────────────────┴──────────────┤
│ Quest: quest_01  |  Changes: 0  |  Validation: OK                                       │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Core Modules & Features

### 3.1 Quest List & Filters
- Dynamic list loading base quests (`quest_01` to `quest_05`) and custom modded quests.
- Search by ID, Title, Description, Giver NPC, and Objectives.
- Type filtering: `Main`, `Side`, `NPC`, `Farming`, `Exploration`, `Collection`, `Tutorial`, `Seasonal`, `Event`.

### 3.2 Objective Pipeline & Builder
Supported objective types:
- `plant`, `water`, `harvest`: Crop lifecycle activities.
- `combine`, `synthesis`: Hybridization and synthesis alchemy.
- `discover`: Botanical journal entries.
- `sell`, `buy`: Economy trading.
- `deposit`, `withdraw`: Storage logistics.
- `talk`, `dialogue_action`: Social interaction and conversations.
- `friendship`: NPC heart levels.
- `world_event`, `unlock_world`: Exploration and progression milestones.

### 3.3 Prerequisites & Branching Unlocks
- Unlocks: `auto`, `quest_completed`, `heart_level`, `season`, `weather`, `world_unlocked`, `gold`, `item`.
- Dependency wiring: Chain sequential quests (e.g. `quest_01 -> quest_02 -> quest_03`).

### 3.4 Rewards Engine
- Gold grants.
- Next quest unlocks (`unlock_quest`).
- World realm unlocks (`unlock_world`).
- Item rewards and friendship point bonuses.

### 3.5 Live Quest Simulation & Playtest
- **🧪 Simulate Quest**: Test availability, objective evaluation, and completion rewards against virtual state without modifying real save files.
- **▶️ Play Quest**: Dispatch live objective events to runtime `QuestManager`.

### 3.6 Cross-Editor Integration
- **👤 Giver NPC**: Open the giver character in the NPC Editor.
- **💬 Dialogue**: Open related quest dialogue trees in the Dialogue Editor.
- **🗺️ World Realm**: Inspect destination coordinates in the World Editor.
