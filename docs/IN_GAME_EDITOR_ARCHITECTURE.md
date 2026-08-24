# In-Game Content Creation & Modding Editor Architecture

## 1. Executive Summary & Philosophy

Botanical Haven features a decoupled, data-driven **In-Game Content Creation & Modding Engine**. 
Developers, content designers, and community modders do not author gameplay content within the Godot Engine Editor. Instead, the entire game definition model—including Worlds, NPCs, Dialogues, Quests, Items, Crops, Tools, Shops, Schedules, Events, Relationships, and Mods—is managed directly through the in-game editor framework.

### Fundamental Principles
1. **Zero Godot Editor API Dependencies**: Built 100% using standard Godot runtime nodes and GDScript (`RefCounted` services and `Control` UI), allowing seamless compilation for desktop, console, and standalone modding distributions.
2. **Strict Save Data vs. Content Data Isolation**: Content definitions (data layer) are completely isolated from runtime gameplay save states (player inventories, coordinates, current day, planted tiles).
3. **Immutable Base Data with Layered Overrides**: Base game definitions (`res://data/`) are immutable. User edits and mod packages exist strictly as override layers:
   $$\text{Effective Data} = \text{Base Data} \oplus \text{Mod Overrides} \oplus \text{User / Editor Overrides}$$
4. **Reversible Command Pattern**: All user modifications support instant, multi-level Undo/Redo and granular "Restore to Default" reversion.
5. **Stable ID Addressing**: All game entities are identified by universal stable IDs (`crop.red_flower`, `npc.rowan`, `tool.hoe_basic`, `world.farm`, `quest.first_seeds`).

---

## 2. Main Menu & Mode Transition Architecture

```
Application Launch
        │
        ▼
   [MainMenuUI]
        ├── 1. Continue (Active only when valid save exists)
        ├── 2. New Game (Opens SaveSelectUI or fresh slot)
        ├── 3. Saves (Manage save slots 1..3)
        ├── 4. Editor (Opens In-Game Editor Mode)
        ├── 5. Multiplayer (Host / Join lobby)
        ├── 6. Settings (Audio, Video, Controls, Gameplay)
        ├── 7. Credits (Data-driven team acknowledgments)
        └── 8. Quit (Graceful application exit)
```

### Game vs. Editor State Isolation
When transitioning to **Editor Mode**:
- `EditorService.get_instance().enter_editor_mode()` is invoked.
- Time progression (`TimeManager`) and World simulation (`NPCManager`, `CropGrowth`) are suspended.
- Player character movement is locked (`set_movement_locked(true)`).
- Input is fully handled/absorbed by the `EditorShell` UI.
- On exit, if unstaged/dirty changes exist, an exit confirmation modal prompts the user to **Save & Exit**, **Discard & Exit**, or **Cancel**.

---

## 3. Layered Content Data Resolution Architecture

```
┌────────────────────────────────────────────────────────┐
│               EditorDataService Request                │
│       get_effective_value(stable_id, property)         │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
           ┌─────────────────────────────────┐
           │ 1. Staged In-Memory Overrides  │──[Found]──► Return Staged Value
           │    (_staged_overrides)          │
           └────────────────┬────────────────┘
                            │ [Not Found]
                            ▼
           ┌─────────────────────────────────┐
           │ 2. Mod Layer (ModManager)       │──[Found]──► Return Mod Value
           │    (Priority-Sorted Active Mods)│
           └────────────────┬────────────────┘
                            │ [Not Found]
                            ▼
           ┌─────────────────────────────────┐
           │ 3. Base Game Data (res://data/) │──[Found]──► Return Base Value
           │    (_base_* dictionaries)       │
           └────────────────┬────────────────┘
                            │ [Not Found]
                            ▼
                  Return Fallback Default
```

---

## 4. Key Components and Services

### 4.1. `EditorService` (`res://editor/core/editor_service.gd`)
The central runtime coordinator singleton for in-game content creation.
- **State Management**: Tracks `is_editor_active`, `active_module`, and `selected_object_id`.
- **Command Dispatch**: Exposes `set_property()`, `restore_property_default()`, `undo()`, `redo()`, `save()`, `discard()`.
- **Validation**: Coordinates reference integrity and schema validation across modules.

### 4.2. `EditorDataService` (`res://editor/core/editor_data_service.gd`)
The authoritative data layer provider.
- **Base Data Loaders**: Automatically indexes Worlds, NPCs, Dialogues, Quests, Items, Crops, Tools, Shops, and Schedules from `res://data/`.
- **Dirty State Tracking**: Real-time comparison between in-memory `_staged_overrides` and persisted `_saved_overrides`.
- **Persistence**: Safely stores overrides in `user://editor_overrides.json` with schema versioning (`SCHEMA_VERSION = 1`).

### 4.3. `EditorUndoManager` (`res://editor/core/editor_undo_manager.gd`)
Lightweight, reversible Command Pattern implementation.
- Encapsulates discrete `EditorAction` instances with `execute()`, `undo()`, and `redo()` callbacks.
- History stack up to 50 operations.

### 4.4. `ModManager` (`res://editor/core/mod_manager.gd`)
Mod discovery, lifecycle, and conflict detection engine.
- **`ModDefinition`**: Schema containing `id`, `name`, `version`, `author`, `description`, `game_version`, `enabled`, `priority`, and `overrides`.
- **Deterministic Priority Sorting**: Mods with higher priority values take precedence in overlapping property overrides.
- **Conflict Detection**: Detects collisions across installed mods and identifies the active override winner.

### 4.5. `EditorValidationService` (`res://editor/core/editor_validation_service.gd`)
Data-integrity auditor preventing broken references across schedules, dialogue trees, quest rewards, and asset identifiers without throwing exceptions.

### 4.6. `EditorShell` (`res://editor/ui/editor_shell.gd`)
Responsive, dockable 3-panel UI:
- **Top Command Bar**: Project title, Save, Undo, Redo, Discard, Exit.
- **Left Navigation Dock**: 14 category buttons (`World`, `NPC`, `Dialogue`, `Quest`, `Items`, `Crops`, `Tools`, `Shops`, `Schedules`, `Events`, `Relationships`, `Assets`, `Settings`, `Mods`).
- **Center Workspace**: Dynamic item list and visual workspace.
- **Right Property Inspector**: Interactive live property editors with instant [Restore Default] action.
- **Bottom Status Bar**: Active module name, Dirty indicator ("Clean" / "Unsaved Changes"), and Validation badge ("Validation: OK").

---

## 5. Modding Example (`mod.json`)

```json
{
  "id": "expanded_botany",
  "name": "Expanded Botany & Rare Flora",
  "version": "1.0.0",
  "author": "Haven Modder",
  "description": "Adds higher yield and unique growth properties to rare flowers.",
  "game_version": "1.0.0",
  "enabled": true,
  "priority": 150,
  "content_version": 1,
  "overrides": {
    "crop.red_flower": {
      "name": "Crimson Twilight Orchid",
      "sell_price": 45,
      "growth_days": 4
    }
  }
}
```

---

## 6. Verification and Regression Testing

The system is verified with a dedicated 30-point integration test suite (`tests/integration/test_editor_foundation.gd`) spanning:
- Main menu button flows & localization (T01 - T07)
- Editor mode entry, exit, gameplay isolation, input trapping (T08 - T11)
- Dirty state, save, discard, undo/redo command pattern (T12 - T16)
- Stable ID resolution, content data isolation, save data isolation, default restoration (T17 - T20)
- Mod definition loading, enable/disable, priority resolution, conflict detection, data isolation (T21 - T25)
- Automated validation, broken reference handling, localization, art pipeline, and gameplay regressions (T26 - T30)
