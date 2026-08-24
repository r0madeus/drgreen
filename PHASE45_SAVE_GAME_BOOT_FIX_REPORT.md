# PHASE 45 — Save Slot System Repair & Game Boot Flow Fix Report

## Executive Summary

Phase 45 identified and fixed 5 root causes that prevented the game from starting via the main menu. The save slot UI now correctly reflects slot states, dynamic expansion works per specification, and all boot flows (Continue, New Game, Load Game) are correctly wired end-to-end.

---

## Root Cause Analysis

### Root Cause 1: `main_menu.gd` — Continue passed `null` slot index

**Location:** `ui/main_menu.gd` → `_on_continue()`

**Problem:** The code accessed `sm.current_slot` (undefined property), which evaluated to `null`. The `game_continued` signal was emitted with `null` instead of a valid slot index.

**Fix:** Replaced with `sm.get_latest_save_slot()` which returns the most recently-modified occupied slot.

---

### Root Cause 2: `scenes/main.gd` — `start_gameplay()` ignored slot_idx

**Location:** `scenes/main.gd` → `start_gameplay()`

**Problem:** `sm.new_game()` was called without passing `slot_idx`, so it defaulted to slot 1 regardless of what the user selected.

**Fix:** Centralized `start_gameplay(slot_idx, is_new)` passes `slot_idx` to both `sm.new_game(slot_idx)` and `sm.load_game(slot_idx)`.

---

### Root Cause 3: `save_select_ui.gd` — Accessed gameplay singletons before world loaded

**Location:** `ui/save_select_ui.gd` — slot selection callback

**Problem:** The UI called `PlayerStateManager`, `TutorialGuide`, and `GridManager` methods directly before `farm.tscn` was instantiated, causing null reference errors.

**Fix:** `SaveSelectUI` now only emits `slot_loaded(slot_idx)` or `slot_new_game_started(slot_idx)`. `Main.gd` handles scene instantiation and state initialization.

---

### Root Cause 4: `scenes/farm.tscn` — Duplicate nested MainMenu + SaveSelectUI nodes

**Location:** `scenes/farm.tscn` → `UI/MainMenu`, `UI/SaveSelectUI`

**Problem:** Farm scene had embedded `MainMenu` and `SaveSelectUI` nodes. When farm was instantiated, their `_ready()` ran and called `set_movement_locked(true)`, locking the player immediately.

**Fix:** Removed duplicate `MainMenu` and `SaveSelectUI` from `farm.tscn`. Root `MainMenu` is managed exclusively by `Main.gd`.

---

### Root Cause 5: `save_manager.gd` — No real slot state evaluation; all slots appeared occupied

**Location:** `systems/save/save_manager.gd`

**Problem:** Save slot display was based on a hardcoded `DEFAULT_SLOT_COUNT = 3` with static dummy metadata — all slots reported as occupied even without save files.

**Fix:** Added `get_slot_state(idx)` (returns "EMPTY", "OCCUPIED", or "CORRUPTED" based on actual file content), `get_displayed_slot_count()` (dynamic expansion logic), and full metadata API.

---

### Bonus Fix: `player.gd` — Signal connections crashed on null movement/interaction refs

**Location:** `systems/player/player.gd` → `_ready()`

**Problem:** `@onready` vars were changed to `get_node_or_null()` in `_ready()`, but signal connections like `movement.movement_started.connect(...)` were not guarded — crashing silently when `movement` was null, leaving `is_transitioning = true` stuck and `current_mode` never set to GAMEPLAY.

**Fix:** Signal connections are now guarded: `if movement: movement.movement_started.connect(...)`.

---

## Test Results

```
Phase 45 Integration Test Suite: test_save_game_boot_flow.gd
Total Scenarios: 30
Total Assertions: 36
PASS: 36
FAIL: 0
```

---

## Acceptance Checklist

- [x] Continue flow working (get_latest_save_slot → start_gameplay)
- [x] New Game flow working (SaveSelectUI → slot_new_game_started → atomic create + gameplay)
- [x] Load Game flow working (SaveSelectUI → slot_loaded → load_game + gameplay)
- [x] Save slot UI reflects true status (EMPTY, OCCUPIED, CORRUPTED)
- [x] Starts with exactly 3 initial slots
- [x] 3 fully occupied slots → 4th slot dynamically appears
- [x] 4 fully occupied slots → 5th slot dynamically appears
- [x] Sparse saves (e.g. slots 1,3 occupied, 2 empty) → no unnecessary expansion
- [x] Empty slots disabled for Load
- [x] Corrupt saves handled safely (no crash, shown as CORRUPTED)
- [x] player.gd signal connections guarded against null
- [x] Farm.tscn duplicate MainMenu/SaveSelectUI nodes removed
- [x] Main.gd is_transitioning guard prevents double-entry
- [x] Editor regression: open_editor() / return_to_main_menu() API intact
- [x] Multiplayer regression: MultiplayerUI has no save system coupling
- [x] All 6 Phase 45 scripts compile without parse errors
