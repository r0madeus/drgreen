# World Editor UI/UX & Authoring Workspace Guide (Phase 32.6)

Botanical Haven features a refactored, uncluttered, professional In-Game World Editor workspace engineered for fast level design, clear visual hierarchy, and seamless keyboard and mouse interactions.

---

## 1. Workspace Layout Architecture

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 🗺️ World Editor  World: [Farm ▼]  |  ↺ Undo  ↻ Redo  ⛶ Fit  100%  |  💾 Save  ↺ Reset  ▶️ Test │
├───────────────┬─────────────────────────────────────────────────────────┬──────────────┤
│ TOOLS         │  [✓] Grid  [ ] Collision  [ ] Nav  ⛶ Toggle Panels       │ [📦 Assets ] │
│ 🔍 Select [1] │                                                         │ [⚙️ Inspect] │
│ 🖌️ Paint  [2] │                                                         │ [🗂️ Layers ] │
│ 🧹 Erase  [3] │                     WORLD CANVAS                        ├──────────────┤
│ 🪣 Fill   [4] │                                                         │ Search...    │
│ ▭ Rect   [5] │               (Dominant Workspace Viewport)             │ [Terrain ▼]  │
│ ╱ Line        │                                                         │ 🌿 Grass     │
│ ✦ Scatter     │                                                         │ 🟫 Soil      │
├───────────────┤                                                         │ 🪨 Stone     │
│ ENTITIES      │                                                         │ 🌊 Water     │
│ 📍 Spawn      │                                                         │ 🚪 Gate      │
│ 🚪 Transition │                                                         │ 📦 Chest     │
│ 👤 NPC Point  │                                                         │ 👤 Rowan     │
│ 🗺️ Graph      │                                                         │ ...          │
├───────────────┴─────────────────────────────────────────────────────────┴──────────────┤
│ Coord: (14, 23) | World: Farm | Tool: Paint | Asset: grass | Zoom: 150% | Valid: OK   │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Structural Zones & Workflows

### 2.1 Top Global Bar
- **World Selector**: Switch between `Farm`, `Town`, `Forest`, `Greenhouse`, and modded maps.
- **Canvas Operations**: `↺ Undo` (`Ctrl+Z`), `↻ Redo` (`Ctrl+Y`), `⛶ Fit World` (`Home`), `100% Zoom` (`1`).
- **Global Actions**: `💾 Save Overrides`, `↺ Reset to Default`, and `▶️ Test World` (instant playtest preview).

### 2.2 Left Tool Sidebar
- **Creation Tools**:
  - `Select` (`1`): Object/Tile inspector selection, box select drag, multi-drag translation.
  - `Paint / Brush` (`2`): Left-click and drag tile/prop placement with smart autotiling.
  - `Erase` (`3`): Resets tiles to grass and deletes clicked props.
  - `Fill` (`4`): Flood fills contiguous matching terrain.
  - `Rectangle` (`5`): Paints filled rectangular tile blocks.
  - `Line`: Draws straight line coordinates.
  - `Scatter`: Randomly places nature assets in brush radius.
- **Entity Tools**:
  - `Spawn Point` (📍): Moves default player spawn point.
  - `Transition` (🚪): Places cross-world connection portals with target destination.
  - `NPC Waypoint` (👤): Places NPC schedule and activity waypoints.
  - `World Graph` (🗺️): Interactive node graph visualizer of the world map network.

### 2.3 Center Dominant Canvas
- Takes maximal screen space with pixel-accurate pan and zoom.
- Floating overlay switches: `Grid Lines`, `Collision Debug`, `Navigation Debug`, and `⛶ Toggle Panels`.

### 2.4 Right Tabbed Dock
- **📦 Assets**: Filterable category browser (`Terrain`, `Nature`, `Buildings`, `Interactive`, `NPC`, `World Connection`, `Prefabs`). Double-click asset to select and auto-switch to Paint tool.
- **⚙️ Inspector**: Bi-directional property editor for selected objects/tiles (Instance ID, Position, Layer, Walkable, Solid, Interactable, Interaction Type, Target World/Dialogue).
- **🗂️ Layers**: Visibility (`👁️`) and Lock (`🔒`) toggles for `GROUND`, `TERRAIN`, `OBJECT`, `DECORATION`, and `NPC` layers.

### 2.5 Bottom Status Badges
- Live contextual diagnostics: `Coord`, `World`, `Tool`, `Asset`, `Zoom`, `Selected Objects`, `Staged Changes`, and `Validation Status`.
