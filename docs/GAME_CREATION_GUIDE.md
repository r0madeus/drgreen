# Botanical Haven — Game Creation & Game Studio Guide (Phase 40)
## Complete Guide to Authoring Standalone Games in Botanical Haven Studio

The Botanical Haven Engine allows developers and modders to build, test, package, and share completely standalone games without touching the Godot Editor.

---

## 1. Game Studio Architecture

```
[ GAME CREATION HUB ]
       │
       ├──► [ NEW GAME WIZARD ] ──► Creates clean GamePackage (e.g., user://games/my_game/)
       │
       ├──► [ PROJECT DASHBOARD ] ──► Content Metrics, Validation, Playtest, Export
       │
       └──► [ CONTENT EDITORS ]
               ├── World Editor (Custom maps, sizes, backgrounds, spawns)
               ├── Generic Entity Editor (Props, chests, NPCs, triggers)
               ├── Item Editor (Keys, weapons, consumables)
               ├── Gameplay Rules Editor (Events, conditions, action chains)
               └── Dialogue & Quest Editors
```

---

## 2. Step-by-Step Game Creation

### Step 1: Open Game Studio
1. Launch the In-Game Editor.
2. Select **🚀 Game Studio** from the left navigation bar.
3. Switch to the **✨ New Game Wizard** tab.

### Step 2: Configure Game Manifest
- **Game Identifier (ID):** Unique slug (e.g. `dungeon_crawler`).
- **Display Name:** `Dungeon Crawler`.
- **Author & Version:** `YourName`, `1.0.0`.
- **Template:** Select `Empty` for a clean canvas with 0 Botanical Haven items or NPCs.
- Click **✨ Create Game Package & Open in Studio**.

### Step 3: Author World & Entities
1. Open **🌍 World Editor** -> create a 30x20 dungeon map.
2. Open **👤 NPCs / Entities** -> create `ancient_chest` with `on_interact: "chest_interacted"`.
3. Open **🎒 Items** -> create `dungeon_key` and `legendary_sword`.

### Step 4: Wire Gameplay Rules
1. Open **⚡ Rules** -> create trigger `chest_unlock`:
   - **Event:** `chest_interacted`
   - **Condition:** `inventory.dungeon_key >= 1` and `flags.chest_opened == false`
   - **Actions:** Remove `dungeon_key`, add `legendary_sword`, set flag `chest_opened`, show message.

### Step 5: Validate & Playtest
1. Return to **🚀 Game Studio** -> click **✓ Validate Project**.
2. Click **▶ PLAYTEST GAME** for an isolated, safe test session.
3. Approach chest -> unlock -> receive sword -> return to studio.

### Step 6: Export .bhgame Package
1. Click **📤 Export .bhgame**.
2. Your game is packaged to `user://exports/dungeon_crawler.bhgame` ready to be shared with players!
