# Botanical Haven — Editor UX & Production Readiness Guide
## Official Production & Authoring Manual (Phase 37)

Welcome to the **Production-Hardened In-Game Content Authoring Suite** for Botanical Haven!
This guide covers everything you need to know about the standardized user interface, workflow conventions, safety mechanisms, validation diagnostics, keyboard shortcuts, and mod packaging.

---

## 1. Unified Interaction Model & Visual Language

### Status Badges
- **Dirty State:**
  - `SAVED` (Green `Color(0.4, 0.9, 0.4)`): Workspace is clean and in sync with disk.
  - `UNSAVED CHANGES` (Amber `Color(1.0, 0.65, 0.2)`): In-memory modifications are staged and ready to save.
- **Validation Status:**
  - `VALID` (Green): 100% clean references and verified IDs across all domains.
  - `WARNING (N)` (Yellow): Non-critical notices (e.g. unverified optional fields or mod conflicts).
  - `ERROR (N)` (Red): Critical broken references (e.g. missing target items, non-existent NPCs, or broken texture paths). Click to open the Validation Report dialog with direct jump links!

### Standardized Actions Across All Panels
- **Primary Actions:** Always positioned prominently in top toolbar (`+ Create`, `Save`, `Reset`, `Validate`).
- **Destructive Actions Confirmation:** Destructive operations like `Reset All Modifications`, `Discard Changes`, and `Exit with Unsaved Changes` always prompt the user with a non-destructive confirmation dialog.

---

## 2. Keyboard & Mouse Shortcuts Reference

| Shortcut | Context | Action |
| :--- | :--- | :--- |
| `Ctrl + S` | Global Editor | Save all staged overrides atomically to `user://editor_overrides.json`. |
| `Ctrl + Z` | Global Editor | Undo last authoring or editing action. |
| `Ctrl + Y` / `Ctrl + Shift + Z` | Global Editor | Redo last undone action. |
| `Ctrl + D` | World / Entity | Duplicate selected entity or tile object. |
| `Ctrl + C` / `Ctrl + V` | World Canvas | Copy and Paste selected map region / tiles. |
| `Delete` / `Backspace` | World / Entity | Delete selected object (guarded when typing in text fields). |
| `Escape` | Global Editor | Deselect current tool / prompt exit dialog. |
| `F` / `Home` | World Canvas | Fit canvas view to screen center. |
| `1` | World Canvas | Activate **Select** Tool. |
| `2` | World Canvas | Activate **Brush** Painting Tool. |
| `3` | World Canvas | Activate **Eraser** Tool. |
| `4` | World Canvas | Activate **Fill Bucket** Tool. |
| `5` | World Canvas | Activate **Rectangle Box** Tool. |
| `Middle Mouse Drag` | World Canvas | Pan across the map canvas. |
| `Mouse Wheel` | World Canvas | Smooth zoom in / zoom out. |
| `Right Click Drag` | World Canvas | Instant erase / cancel placement. |

> [!NOTE]
> All single-key shortcuts and tool hotkeys are strictly disabled while typing in `LineEdit` or `TextEdit` fields to prevent accidental tool switching during data entry.

---

## 3. Responsive Screen Layouts

The In-Game Editor dynamically scales to fit all standard PC and handheld gaming resolutions:
- **1280 x 720 (HD):** Compact mode with scrollable panels.
- **1366 x 768:** Standard laptop resolution.
- **1600 x 900:** High density workspace.
- **1920 x 1080 (Full HD):** Optimized default desktop layout.
- **2560 x 1440 (2K / QHD):** Expansive multi-panel layout.

---

## 4. Complete 8-Step Content Creation Workflow

```
[ Step 1: Create Mod Workspace ]
             │
             ▼
[ Step 2: Import Custom Textures / Sprites ]
             │
             ▼
[ Step 3: Create & Paint New World Canvas ]
             │
             ▼
[ Step 4: Create NPC & Set Daily Schedule ]
             │
             ▼
[ Step 5: Place NPC in World Canvas ]
             │
             ▼
[ Step 6: Create Branching Dialogue Tree ]
             │
             ▼
[ Step 7: Create Quest, Objectives & Rewards ]
             │
             ▼
[ Step 8: Validate -> Playtest -> Export .bhmod ]
```

---

## 5. Troubleshooting & FAQ

- **Q: Why is my quest marked with an ERROR in the validation badge?**  
  *A: The quest objective or reward likely targets an item ID that doesn't exist yet. Create the item in the Items panel or select it from the dropdown.*
- **Q: Will playtesting mess up my real game save?**  
  *A: No. In-game playtests dynamically inject staged overrides into memory singletons without modifying production save slots.*
- **Q: How do I share my mod with friends?**  
  *A: Go to Mod Manager -> Select your mod -> Click 'Export .bhmod'. Send the single `.bhmod` file from `user://mods/`.*
