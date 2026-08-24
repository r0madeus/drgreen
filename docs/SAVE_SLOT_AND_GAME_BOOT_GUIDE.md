# Save Slot System & Game Boot Flow Guide

> **Phase 45 — Botanical Haven Engine**

---

## 1. Overview

This guide documents the save slot architecture, dynamic slot expansion rules, and the game boot lifecycle after Phase 45 hardening.

---

## 2. Game Boot Flow Architecture

```
                 ┌───────────────────────┐
                 │     scenes/main.gd    │  (AppMode.MENU)
                 └──────────┬────────────┘
                            │
              ┌─────────────┼──────────────┐
              ▼             ▼              ▼
         [Continue]   [New Game]     [Load Game]
              │             │              │
   Latest valid save    SaveSelectUI   SaveSelectUI
   (get_latest_save_slot)  │  (empty)     │  (occupied)
              │             │              │
              └─────────────┴──────────────┘
                            │
                  game_continued / new_game_started
                            │
                            ▼
                  Main.start_gameplay(slot_idx, is_new)
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
        [is_new=true]              [is_new=false]
        sm.new_game(slot_idx)     sm.load_game(slot_idx)
        (atomic create + init)    (validate + restore)
              │                           │
              └─────────────┬─────────────┘
                            │
                   Instantiate farm.tscn
                   Hide nested MainMenu (if any)
                   Unpause TimeManager
                   Unlock Player movement
                            │
                            ▼
                  AppMode.GAMEPLAY ✓
```

---

## 3. Dynamic Save Slot Expansion Rules

### Starting State
- Always begin with **3 displayed slots**: Slot 1, Slot 2, Slot 3.

### Expansion Rule
```
displayed_slots = max(INITIAL_SLOTS=3, occupied_count + 1)
```
**But only when ALL displayed slots are occupied.** If any empty slot exists among displayed slots, no expansion occurs.

### Examples

| Occupied | Empty Among Displayed | Displayed Count | Expansion? |
|:---------|:----------------------|:----------------|:-----------|
| 0 | Slots 1,2,3 | 3 | No |
| 1 | Slots 2,3 | 3 | No |
| 2 | Slot 3 | 3 | No |
| Sparse: 1,3 occupied; 2 empty | Slot 2 | 3 | No |
| 3 (all full) | None | **4** | Yes → Slot 4 appears |
| 4 (all full) | None | **5** | Yes → Slot 5 appears |

### Implementation: `SaveManager.get_displayed_slot_count()`
```gdscript
func get_displayed_slot_count() -> int:
    var occupied = 0
    var has_gap = false
    for i in range(1, _max_checked_slot + 1):
        var state = get_slot_state(i)
        if state == "OCCUPIED":
            occupied += 1
        elif state == "EMPTY" and i <= maxi(INITIAL_SLOTS, occupied):
            has_gap = true
    if has_gap:
        return maxi(INITIAL_SLOTS, occupied)
    return maxi(INITIAL_SLOTS, occupied + 1) if occupied >= INITIAL_SLOTS else INITIAL_SLOTS
```

---

## 4. Slot State Categorization

Every slot is evaluated by `SaveManager.get_slot_state(slot_idx)`:

| State | Condition | UI Display | Available Actions |
|:------|:----------|:-----------|:-----------------|
| `EMPTY` | No file exists at slot path | 📁 Empty Slot — New Game | New Game only |
| `OCCUPIED` | Valid JSON save file exists | 🌱 Save with metadata | Load, Delete |
| `CORRUPTED` | File exists but malformed JSON | ⚠️ Corrupted — Reset | Reset (delete) only |

---

## 5. SaveManager API Reference

All UI components use `SaveManager` exclusively — no direct filesystem access from UI.

| Method | Returns | Description |
|:-------|:--------|:------------|
| `get_displayed_slot_count()` | `int` | How many slots to show in UI |
| `get_slot_state(idx)` | `String` | "EMPTY", "OCCUPIED", or "CORRUPTED" |
| `has_slot_save(idx)` | `bool` | True if valid save file exists |
| `is_slot_empty(idx)` | `bool` | True if slot has no file |
| `is_slot_corrupted(idx)` | `bool` | True if file exists but is invalid |
| `has_any_save()` | `bool` | True if at least one occupied slot |
| `get_latest_save_slot()` | `int` | Slot index of most recent save (by timestamp) |
| `get_save_slot_metadata(idx)` | `Dictionary` | Slot metadata for UI display |
| `get_all_slots_metadata()` | `Array` | All displayed slots metadata |
| `create_new_save(idx)` | `bool` | Atomic creation of new save |
| `new_game(idx)` | `bool` | Initialize + save new game to slot |
| `load_game(idx)` | `bool` | Load save from slot |
| `delete_slot(idx)` | `bool` | Delete slot save file |
| `get_slot_path(idx)` | `String` | Absolute path to slot file |

---

## 6. AppMode Transitions (scenes/main.gd)

```
AppMode.MENU  ──→  AppMode.GAMEPLAY   via start_gameplay(slot_idx, is_new)
AppMode.MENU  ──→  AppMode.EDITOR     via open_editor()
AppMode.GAMEPLAY ──→ AppMode.MENU     via return_to_main_menu()
AppMode.EDITOR ──→  AppMode.MENU      via return_to_main_menu() (EditorShell.exit_requested)
```

**Safety:** `is_transitioning` flag prevents double-entry into any transition.

---

## 7. Phase 45 Modified Files

| File | Change |
|:-----|:-------|
| `systems/save/save_manager.gd` | Added: `get_displayed_slot_count()`, `get_slot_state()`, `is_slot_empty()`, `is_slot_corrupted()`, `has_slot_save()`, `get_latest_save_slot()`, `create_new_save()`, `get_save_slot_metadata()`, `get_slot_path()` |
| `ui/save_select_ui.gd` | Rewrote to metadata-driven dynamic rendering; emits `slot_loaded` / `slot_new_game_started` to `Main` |
| `ui/main_menu.gd` | Fixed `_on_continue()` to use `get_latest_save_slot()`; safe player/root access; fixed `_ensure_save_select_ui()` |
| `scenes/main.gd` | Centralized `start_gameplay()`, `open_editor()`, `return_to_main_menu()` with `is_transitioning` guard; safe `_get_safe_node()` |
| `scenes/farm.tscn` | Removed duplicate nested `MainMenu` and `SaveSelectUI` nodes |
| `systems/player/player.gd` | Converted `@onready` to guarded `get_node_or_null()` in `_ready()`; guarded signal connections against null |
| `tests/integration/test_save_game_boot_flow.gd` | 30 scenarios, 36 total assertions — **36 PASS / 0 FAIL** |

---

## 8. Runtime Test Checklist

These flows must be verified in the running game:

| Flow | Expected |
|:-----|:---------|
| Launch → Continue | Loads latest save, enters gameplay |
| Launch → New Game → Slot 1 | Creates save, enters gameplay |
| Launch → New Game → Slot 2 | Creates save, enters gameplay |
| Launch → Load Game → Slot 1 | Restores state, enters gameplay |
| 3 saves full → Slot 4 appears | Dynamic expansion |
| Restart → Load Game → previous saves exist | Persistence |
| Launch → Editor → Main Menu → New Game → Gameplay | No regression |
| Multiplayer menu open/close | No save system interference |
