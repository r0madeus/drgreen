# Editor Integration, Persistence & Mod Packaging Guide (Phase 33)

Botanical Haven unifies all in-game content creation systems (World, NPCs, Dialogue, Quests, Items, Crops, Tools, Economy) under a central, cohesive authoring session, multi-layered data persistence architecture, and standalone `.bhmod` package management system.

---

## 1. Central Architecture

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                   MAIN MENU                                            │
│   Continue  |  New Game  |  Saves  |  Multiplayer  |  [ EDITOR ]  |  Settings          │
└───────────────────────────────────────────┬────────────────────────────────────────────┘
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              CENTRAL EDITOR SESSION                                    │
│   active_module  |  active_entity  |  active_mod  |  dirty_state  |  validation_state   │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 🗺️ World  |  👤 NPCs  |  💬 Dialogue  |  📜 Quests  |  🧰 Items  |  🧩 Mods             │
├────────────────────────────────────────────────────────────────────────────────────────┤
│                                 DATA RESOLUTION LAYERS                                 │
│   Layer 1: User Staged Overrides (Memory)                                              │
│   Layer 2: Active Mod Overrides (user://mods/<mod_id>/manifest.json)                   │
│   Layer 3: Base Game Content (res://data/... - Read Only)                              │
├────────────────────────────────────────────────────────────────────────────────────────┤
│                               PERSISTENCE & BACKUPS                                    │
│   user://editor_overrides.json  |  user://editor/active_project.json                   │
│   user://editor/backups/backup_<timestamp>.json (Rolling 10-snapshot backup system)    │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Core Systems & Workflows

### 2.1 Central Editor Session (`EditorSession`)
- **Single Source of Truth**: Tracks active module, focused entity, dirty state, and validation diagnostics.
- **Cross-Editor Navigation**: Bidirectional navigation history with Back (`can_navigate_back()`) and Forward (`can_navigate_forward()`) traversal between interlinked entities (Quests <-> Giver NPCs <-> Rewards <-> Dialogues).

### 2.2 Global Undo / Redo & Atomic Persistence
- **Global Actions**: `Undo` (`Ctrl+Z`), `Redo` (`Ctrl+Y` / `Ctrl+Shift+Z`), `Save Overrides` (`Ctrl+S`), `Reset to Default`.
- **Atomic File Saving**: Uses temporary file writes (`.tmp`) prior to atomic filesystem replacement to prevent corrupted state on unexpected interruptions.
- **Automated Snapshots**: Every save automatically creates a timestamped backup in `user://editor/backups/` with rolling retention.

### 2.3 Safe Reset Operations
- **Reset Current Entity**: `restore_property_default(stable_id)` reverts only the active entity to base data.
- **Reset Module Section**: `reset_section(category_prefix)` reverts all changes in the active category (e.g. `world.*`, `npc.*`).
- **Reset All Modifications**: `reset_all_modifications()` clears all overrides and returns the project to pristine base game state.

### 2.4 Standalone Mod Packaging (`.bhmod`)
- **Mod Creation**: Create mods with metadata (`id`, `name`, `author`, `version`, `description`, `game_version`, `dependencies`).
- **Mod Export**: Export complete mod packages as `.bhmod` archives containing manifests and data overrides.
- **Mod Import & Staging**: Import `.bhmod` packages with schema migration, validation, and staging.
- **Conflict Matrix**: Real-time detection of conflicting property overrides across multiple installed mods (`detect_conflicts()`) with explicit priority resolution.
- **Mod Preview**: Summary breakdown of all affected worlds, NPCs, dialogues, quests, and items before enabling.

### 2.5 Central Validation Aggregator (`EditorValidationService`)
- Aggregated health checks across Worlds, NPCs, Dialogues, Quests, Items, and Mods.
- Reports clear actionable diagnostic messages (`✓ Valid`, `⚠ Warnings`, `✕ Errors`) with direct entity navigation links.
