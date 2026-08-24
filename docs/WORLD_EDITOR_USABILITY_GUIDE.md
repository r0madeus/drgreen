# World Editor Usability & Input Guide (Phase 32.5)

This guide documents the repaired input routing architecture, mouse interactions, keyboard shortcuts, tool behaviors, and live visual preview pipelines in the Botanical Haven In-Game World Editor.

---

## 1. Input Architecture & Mouse Handling

### Direct Canvas Input via `_gui_input`
- `WorldCanvas` implements `_gui_input(event: InputEvent)` to consume direct GUI mouse interactions.
- `mouse_filter = Control.MOUSE_FILTER_STOP` ensures canvas events are never swallowed by parent panels.
- `_pixel_to_coord(local_pos)` uses exact local coordinates relative to the canvas origin, ensuring pixel-perfect tile and prop mapping at all zoom levels (0.5x to 3.5x).

---

## 2. Supported Tools & Actions

| Tool | Shortcut | Behavior |
|---|---|---|
| **Select** | `1` | Click to select object/tile; drag to move; drag on empty area for box select |
| **Paint / Brush** | `2` | Left-click or drag to paint selected palette asset (tiles, nature, buildings) |
| **Erase** | `3` or Right-Click | Erases placed props or resets tiles to base grass |
| **Flood Fill** | `4` | Fills contiguous matching tile areas |
| **Rectangle / Place** | `5` | Drag rectangle to paint bounding box of tiles |
| **Delete** | `Del` / `Backspace` | Deletes currently selected objects/tiles |
| **Copy** | `Ctrl + C` | Copies selected objects to clipboard |
| **Paste** | `Ctrl + V` | Pastes clipboard objects at hovered coordinate |
| **Duplicate** | `Ctrl + D` | Clones selected object at adjacent coordinate |
| **Select All** | `Ctrl + A` | Selects all objects in active layer |
| **Focus** | `F` | Centers canvas on selected object |
| **Fit Screen** | `Home` | Centers and frames entire world map |
| **Zoom** | `Mouse Wheel` | Smoothly zooms canvas (0.5x to 3.5x) |
| **Pan** | `Middle Mouse Drag` | Drags canvas viewport smoothly |

---

## 3. Asset Palette & Canvas Placement Pipeline

1. Open **World Editor** (`Main Menu -> Editor -> 🗺️ World`).
2. Select a category from the left **Asset Palette** (`Terrain`, `Nature`, `Buildings`, `Interactive`, `NPC`, `World Connection`, `Prefabs`).
3. Click any asset (e.g. `Oak Tree`, `Tillable Soil`, `Storage Chest`).
4. Move cursor over the central canvas — a yellow hover ghost highlights the target tile.
5. Left-click or drag to place.
6. Changes are immediately staged in `EditorDataService` overrides without altering base files.
