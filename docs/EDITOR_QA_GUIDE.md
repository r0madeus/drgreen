# In-Game Editor QA & Authoring Workflow Manual (Phase 34)

Botanical Haven provides a complete, self-contained, in-game authoring suite allowing creators and players to build, modify, test, save, package, and distribute content without ever opening the Godot Editor.

---

## 1. End-to-End Content Authoring Workflow

```
┌────────────────────────────────────────────────────────────────────────┐
│                        1. WORLD AUTHORING                              │
│   • Paint terrain layers (Ground / Terrain / Decoration / Obstacle)    │
│   • Place props, chests, trees, and buildings                          │
│   • Set player spawn points, map transitions, and NPC waypoints        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         2. NPC & SCHEDULES                             │
│   • Configure NPC identity, role, sprite, and home location            │
│   • Create hour-by-hour daily timeline (movement, tasks, weather)      │
│   • Link waypoints to World locations                                  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                       3. BRANCHING DIALOGUES                           │
│   • Create dialogue nodes with condition gating (heart levels, quests) │
│   • Add player choices leading to branching dialogue trees             │
│   • Trigger gameplay actions (open shop, give quest, reward item)      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         4. QUESTS & EVENTS                             │
│   • Define main/side quests with multi-step objectives                 │
│   • Set prerequisites and rewards (Gold, Items, Friendship)            │
│   • Connect quest givers to NPCs and destination locations             │
└───────────────────────────────────┬────────────────────────────────────┘
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     5. ITEMS, CROPS & ECONOMY                          │
│   • Define custom items, seeds, crops, and growth stage timelines      │
│   • Adjust tool powers, upgrade costs, and energy consumption          │
│   • Simulate ROI economy balance in real time                          │
└───────────────────────────────────┬────────────────────────────────────┘
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   6. VALIDATE, PACKAGE & TEST                          │
│   • Run Central Validation (0 Errors)                                  │
│   • Save overrides or Export standalone `.bhmod` package               │
│   • Instant In-Game Playtest without mutating live player saves        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Controls & Keyboard Shortcuts Reference

| Action | Shortcut / Input | Scope |
|---|---|---|
| **Select Tool** | `1` | World Canvas |
| **Paint / Brush Tool** | `2` | World Canvas |
| **Erase Tool** | `3` / `Right-Click Drag` | World Canvas |
| **Flood Fill Tool** | `4` | World Canvas |
| **Rectangle Fill Tool** | `5` | World Canvas |
| **Undo Action** | `Ctrl + Z` | Global Editor |
| **Redo Action** | `Ctrl + Y` / `Ctrl + Shift + Z` | Global Editor |
| **Save Overrides** | `Ctrl + S` | Global Editor |
| **Duplicate Selection** | `Ctrl + D` | World Canvas |
| **Delete Selection** | `Delete` | World Canvas |
| **Pan Canvas** | `Middle Mouse Drag` / `Space + Left Drag` | World Canvas |
| **Zoom Canvas** | `Mouse Wheel` | World Canvas |
| **Toggle Side Docks** | `F11` / `Toggle Panels` Button | World Canvas |

---

## 3. Responsive Layout & Resolution Standards

The Editor Shell dynamically adapts across all standard display resolutions:
- **1280x720 (720p HD)**: Compact dock mode preserving canvas workspace.
- **1366x768 (Laptop Standard)**: Adaptive splitters with collapsible toolbars.
- **1600x900 / 1920x1080 (1080p FHD)**: Standard 3-zone authoring layout.
- **2560x1440 (1440p 2K)**: Expanded canvas area with high-density palette views.
