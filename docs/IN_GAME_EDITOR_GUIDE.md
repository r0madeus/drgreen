# Botanical Haven — In-Game Editor & Modding Architecture Guide

## 1. Overview & Vision
The **Botanical Haven In-Game Editor** is an embedded, standalone authoring environment allowing players and modders to inspect, modify, create, test, and package game content without Godot Editor dependencies or risk to base game files.

---

## 2. Multi-Layered Content Architecture

```
┌─────────────────────────────────────────────────────────┐
│              1. BASE GAME CONTENT DATA                  │
│       res://data/ (Read-Only, Never Mutated)            │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│              2. MOD OVERRIDES / ADDITIONS               │
│  user://mods/<mod_id>/manifest.json (Priority Sorted)   │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│             3. USER STAGED EDITOR OVERRIDES             │
│   user://editor_overrides.json (In-Memory / Atomic)     │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│              4. RUNTIME RESOLVED DATA                   │
│        Resolved Content Active in World & Systems       │
└─────────────────────────────────────────────────────────┘
```

### Layer Priority Rules
1. **User Staged Overrides**: Immediate authoring edits take top priority during editing and local playtesting.
2. **Active Mod Overrides**: Installed and enabled mods are loaded in ascending priority order (higher priority wins conflicts).
3. **Base Game Data**: Read-only baseline content ensuring `Reset to Default` always restores 100% original behavior.

---

## 3. Application Lifecycle & Isolation

The game operates across 3 discrete modes managed by `Main`:

| Mode | Active Systems | Player State | Time / Schedules | Network Status |
|---|---|---|---|---|
| `AppMode.MENU` | Main Menu UI, Background | Inactive | Paused | Offline / Lobby |
| `AppMode.GAMEPLAY` | Farm, Town, NPCs, Crops | Active & Movable | Running | Local / Networked |
| `AppMode.EDITOR` | EditorShell, DockPanels | Locked & Hidden | Paused | Offline Isolated |

---

## 4. Unified Editor Shell Architecture

The `EditorShell` provides a 3-column docking interface:
- **Top Command Bar**: `Undo` (`Ctrl+Z`), `Redo` (`Ctrl+Y`), `Save Overrides` (`Ctrl+S`), `Discard`, `Reset All`, `Test / Preview`, `Exit` (`Esc`).
- **Left Sidebar**: Category navigation (`World`, `NPCs`, `Dialogue`, `Quests`, `Items`, `Crops`, `Tools`, `Shops`, `Schedules`, `Mod Manager`).
- **Center Workspace**: Dynamic item list with override indicators (`●`) and container for category-specific sub-editors.
- **Right Property Inspector**: Interactive field editing with per-property `↺ Reset` buttons.
- **Bottom Status Bar**: Real-time status, change counter, modified indicator, and automated validation report.

---

## 5. Editor Panel API & Registration

All sub-editors inherit from `EditorPanel`:

```gdscript
class_name NPCEditorPanel
extends EditorPanel

func _init() -> void:
    super._init("npc", "ui.editor.cat_npc", "icon_npc")

func refresh() -> void:
    # Populate category-specific views

func validate() -> Dictionary:
    return { "valid": true, "errors": [], "warnings": [] }
```

Register panels dynamically with `EditorRegistry`:
```gdscript
EditorRegistry.register_panel("npc", NPCEditorPanel, "ui.editor.cat_npc", "icon_npc", 20)
```

---

## 6. Modding Pipeline: Create, Import & Export

### Mod Manifest Format (`manifest.json`)
```json
{
  "id": "autumn_festival_expansion",
  "name": "Autumn Festival Expansion",
  "version": "1.0.0",
  "author": "Haven Community",
  "description": "Adds festive seasonal quests, harvest crops, and NPC dialogue.",
  "game_version": "1.0.0",
  "enabled": true,
  "priority": 150,
  "dependencies": [],
  "overrides": {
    "npc.rowan": {
      "display_name": "Festive Rowan"
    }
  },
  "added_data": {
    "crop.golden_squash": {
      "name": "Golden Squash",
      "growth_days": 4
    }
  }
}
```

### Exporting & Sharing
- Click **Export Mod** in the Mod Manager.
- Packages all staged changes into `user://mods/<mod_id>/manifest.json`.
- Can be imported on another device seamlessly via **Import Mod**.

---

## 7. Safety, Atomic Saving & Reset

1. **Atomic File Saving**: Overrides are written to a `.tmp` file before renaming, preventing partial-write file corruption.
2. **Per-Property Reset**: Clicking `↺` resets individual fields back to base defaults.
3. **Category / Section Reset**: Clears overrides for an entire category (e.g. `npc.*` or `crop.*`).
4. **Reset All Modifications**: Clears all local overrides in `user://editor_overrides.json` without modifying `res://data/`.
