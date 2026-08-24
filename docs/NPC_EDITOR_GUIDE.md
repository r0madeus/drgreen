# In-Game NPC & Schedule Editor Guide (Phase 29)

Botanical Haven features an integrated, standalone In-Game NPC & Daily Schedule Editor that allows developers, level designers, and modders to inspect, create, customize, and test living NPC characters and daily routines directly inside the game runtime without external tooling.

---

## 1. Architecture & Mod Safety

The NPC & Schedule Editor operates on the **Phase 27 In-Game Foundation & Mod Layer**:
- **Non-Destructive Overrides**: Changes made in the editor are staged in memory and saved to `user://editor_overrides.json` or active mod packages (`user://mods/<mod_id>/manifest.json`).
- **Base Game Asset Protection**: Base JSON files in `res://data/npcs/` (`rowan.json`, `elias.json`, `mira.json`, `schedules.json`, `social.json`, `locations.json`) remain strictly read-only.
- **Unified Shell Integration**: Mounted within `EditorShell`, accessible via `Main Menu -> Editor -> 👤 NPCs`.

---

## 2. Interface Layout

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 👤 In-Game NPC & Schedule Editor          [➕ Add NPC] [📋 Dup] [🗺️ Route] [▶️ Test NPC]│
├───────────────┬─────────────────────────────────────────────────────────┬──────────────┤
│ NPC List      │  [Sprite] Rowan the Herbalist                           │ Identity     │
│               │  Activity: work | Location: seed_shop | World: farm     │ Activity     │
│ Rowan         │  ⏰ Time: ──────●────── 09:00                          │ Social       │
│ Elias         ├─────────────────────────────────────────────────────────┤ Appearance   │
│ Mira          │  Daily Schedule Timeline                                │              │
│ ...           │  06:00 ─ 08:30 [HOME]  📍 rowan_home (Priority 2)       │ Role / World │
│               │  09:00 ─ 12:30 [WORK]  📍 seed_shop  (Priority 3)       │ Shop / Dial  │
│               │  13:00 ─ 14:30 [EAT]   📍 farm_porch (Priority 2)       │ Weather Var  │
│               │  15:00 ─ 16:30 [REST]  📍 farm_porch (Priority 2)       │ Friends List │
│               │  17:00 ─ 20:30 [WORK]  📍 seed_shop  (Priority 3)       │              │
├───────────────┴─────────────────────────────────────────────────────────┴──────────────┤
│ World: Farm  |  Changes: 0  |  Validation: OK                                           │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Core Modules & Features

### 3.1 NPC List & Management
- Dynamically populated from `NPCManager` and `EditorDataService`.
- **➕ Add NPC**: Create new custom characters with unique stable IDs.
- **📋 Duplicate NPC**: Clone an existing character with all schedules and social relationships intact.

### 3.2 Appearance & Art Pipeline
- Integrates directly with Phase 25 `AssetRegistry`.
- Dynamic sprite swapping (`merchant`, `blacksmith`, `researcher`, or custom mod sprites).
- Real-time character preview rendering.

### 3.3 Visual Schedule Timeline Editor
- Visual display of daily schedule entries from 06:00 to 24:00.
- **Activity Types**: `home`, `work`, `eat`, `rest`, `sit`, `shop`, `sleep`, `wander`, `social`, `talk`, `idle`, `travel`.
- **Location Selector**: Dropdown populated from `locations.json` and World Editor waypoint points.
- **Timeline Manipulation**: Add, delete, move up/down, edit start/end minute, adjust priority (1–5).

### 3.4 Time Scrubber & Live Behavior Preview
- Drag the 24-hour time scrubber to instantly view what activity, location, and state the NPC is executing at any time of day.
- **▶️ Test NPC**: Launch real-time gameplay preview with staged NPC routine overrides applied.

### 3.5 Weather & Social Schedules
- Switch between `default`, `rain`, `storm`, and `snow` routine variants.
- Configure social friendships, meeting locations, and conversational talkative chances.

### 3.6 Diagnostics & Validation
- Real-time detection of:
  - Invalid / overlapping time ranges.
  - Missing sleep/home routines.
  - Non-existent location targets.
  - Broken asset / texture references.

### 3.7 World Editor Cross-Navigation
- Click **🗺️ Route in World** to seamlessly open World Editor at the NPC's home world coordinate.
