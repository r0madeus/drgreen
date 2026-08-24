# In-Game World & Map Editor Guide (Phase 28)

Botanical Haven features a fully integrated, standalone In-Game World & Map Editor that allows developers, designers, and modders to author, customize, validate, and test game maps directly inside the running game engine without relying on external Godot editor tooling.

---

## 1. Overview & Architecture

The In-Game World & Map Editor operates on the **Phase 27 Foundation & Mod Layer**:
- **Non-Destructive Overrides**: Changes are staged in memory and saved to `user://editor_overrides.json` or active mod manifests (`user://mods/<mod_id>/manifest.json`).
- **Base Game Immutability**: Base game world definitions in `res://data/worlds/` (`farm.json`, `town.json`, `forest.json`, `greenhouse.json`) are read-only and never modified directly.
- **Unified Editor Shell Integration**: Seamlessly hosted inside the 3-dock responsive `EditorShell`, accessible via `Main Menu -> Editor -> 🌍 World`.

---

## 2. Interface Layout

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 🌍 Botanical Haven In-Game Editor                                Save  Undo  Redo  ▶️ Test │
├───────────────┬─────────────────────────────────────────────────────────┬──────────────┤
│ 🌍 World      │ [World: Farm ▼]  [🔍] [🖌️] [🧹] [🪣]  [📍 Spawn] [🚪 Trans]│ Property     │
│ 👤 NPCs       ├─────────────────────────────────────────────────────────┤ Inspector    │
│ 💬 Dialogue   │                                                         │              │
│ 📜 Quests     │                   2D World Canvas                       │ Identity     │
│ 🎒 Items      │          (WASD / MMB Pan • Wheel Zoom)                  │ Transform    │
│ 🌾 Crops      │                                                         │ Collision    │
│ 🔨 Tools      │                                                         │ Interaction  │
│ 🏪 Shops      │                                                         │ Presets      │
│ ⏰ Schedules  │                                                         │ Drop Tables  │
│ 📦 Mods       │                                                         │              │
├───────────────┴─────────────────────────────────────────────────────────┴──────────────┤
│ Coord: (16, 12)  |  Selected: oak_tree_01  |  Changes: 3  |  Validation: OK           │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Core Tools & Operations

### 3.1 World Selection
- Switch seamlessly between worlds using the **World Dropdown** (`Farm`, `Town`, `Forest`, `Greenhouse`, and custom modded maps).

### 3.2 Tile & Terrain Painting
- **🔍 Select**: Click to inspect tiles or props.
- **🖌️ Paint**: Paint selected terrain/tile from the Asset Palette onto the canvas.
- **🧹 Erase**: Paint default ground base terrain.
- **🪣 Fill**: Flood fill contiguous matching tile regions.

### 3.3 Prop Placement & Manipulation
- **Palette Categorization**: Browse Terrain, Nature, Buildings, Interactive, NPCs, and Portals.
- **Placement**: Click anywhere on the 2D grid to drop the active asset.
- **Selection**: Click single props or drag a selection box.
- **Movement**: Drag selected items to reposition them on the grid.
- **Shortcuts**:
  - `Ctrl + C`: Copy selected prop.
  - `Ctrl + V`: Paste copied prop at hovered coordinate.
  - `Ctrl + D`: Duplicate selected prop.
  - `Delete / Backspace`: Delete selected prop.

### 3.4 Spawns & World Transitions
- **📍 Spawn Point Tool**: Set default player spawn coordinate.
- **🚪 Transition Tool**: Create cross-world portal links (target world, target entry point, spawn direction).
- **👤 NPC Points**: Create NPC spawn locations and schedule waypoints.

### 3.5 Collision & Walkability Debug
- Toggle collision overlay to visualize solid versus walkable tiles and check NPC reachability.

---

## 4. Persistence, Undo/Redo & Playtesting

- **Undo / Redo (`Ctrl + Z` / `Ctrl + Y`)**: Full reversibility for tile brush strokes, object placement, transforms, and deletions.
- **Validation**: 10-point static analysis detecting out-of-bound spawns, solid overlaps, missing assets, and broken transition references.
- **▶️ Test World**: Instantly launch runtime gameplay in the edited world with staged modifications applied.
- **Reset Options**: Restore specific objects, tiles, or the entire world back to base default JSON.
