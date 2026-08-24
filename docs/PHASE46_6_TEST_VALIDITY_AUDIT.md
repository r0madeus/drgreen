# Phase 46.6 — Acceptance Test Validity Audit & Test Invalidation Report

**Author:** Antigravity  
**Date:** 2026-08-24  
**Engine:** Godot Engine 4.7.2-stable (win64)  
**Objective:** Audit existing tests for false positives, eliminate internal method shortcuts, and enforce genuine runtime UI event dispatching.

---

## 1. Test Invalidation Matrix

| Test ID | What It Claimed to Test | What It Actually Tested | Valid / Invalid | Reason | Replacement Real UI Test |
|---|---|---|:---:|---|---|
| **UA01** | Real Main Menu to Editor Boot & Navigation | Instantiated Main and navigated via `_select_category()` | **PARTIALLY VALID** | Tested module switching via method call rather than clicking toolbar/navigation buttons. | Replaced with real UI button press events on `nav_container` child buttons and top bar buttons. |
| **UA02** | Real Mouse Input & Canvas Tools | Called `paint_tile_at()`, `_paint_rect()`, `_finalize_drag_move()`, `duplicate_selection()` | **INVALID** | Bypassed UI mouse drag, toolbar tool selection buttons, and palette UI button clicks. | Replaced with full UI flow: Tool button clicks -> Palette asset item clicks -> `InputEventMouseButton` press -> `InputEventMouseMotion` drag -> `InputEventMouseButton` release -> keyboard shortcuts (`KEY_D`, `KEY_DELETE`). |
| **UA03** | World Persistence & Save Flow | Called `service.save()` and `_load_world()` | **PARTIALLY VALID** | Stored data in service but did not test clicking the Save button in the UI or checking the dirty badge. | Replaced with clicking `top_bar` Save button -> asserting Clean status badge -> fresh instance reload. |
| **UA04** | NPC Authoring & Gameplay Spawn | Called `_on_npc_field_changed()` directly | **INVALID** | Directly invoked panel callback instead of entering text into `LineEdit` / `SpinBox` UI controls. | Replaced with setting `display_name_edit.text`, emitting `text_changed`, clicking Save button, and asserting live NPC node in SceneTree. |
| **UA05** | Dialogue Graph Authoring & Gameplay | Directly mutated `service.set_property()` and checked `if dm:` | **INVALID** | Mutated internal dictionary directly and used conditional `if dm:` guard that could silently pass if manager missing. | Replaced with editing `DialogueEditorPanel` fields (`lines_text_edit`, `node_key_edit`), asserting manager strictly non-null, and verifying `DialogueUI` choice buttons. |
| **UA06** | Quest Authoring & Progression | Called `service.set_property()` and `if qm: qm.advance_objective()` | **INVALID** | Bypassed Quest Editor UI input fields and used optional manager check with `assert_true(true)` fallback. | Replaced with editing Quest UI fields (`title_edit`, `reward_gold_spin`), asserting strict `QuestManager` presence, and completing objective via gameplay action. |
| **UA07** | Item / Crop / Tool Authoring | Called `service.set_property()` directly | **INVALID** | Bypassed `ItemEditorPanel` inspector SpinBox / LineEdit UI controls. | Replaced with mutating `sell_price_spin`, `crop_yield_spin`, `tool_power_spin` via UI controls, saving, and verifying inventory receipt in gameplay. |
| **UA08** | Mod Packaging Pipeline | Invoked `ModManager` class API directly | **PARTIALLY VALID** | Verified underlying packaging but bypassed `ModManagerPanel` UI buttons (`Create Mod`, `Export`, `Enable/Disable`). | Replaced with dispatching clicks to `ModManagerPanel` UI buttons and verifying dynamic runtime override resolution. |
| **UA09** | Playtest Isolation | Called `main.start_gameplay()` directly | **PARTIALLY VALID** | Verified state switching but did not use Editor top bar `Test World` button. | Replaced with clicking `playtest_btn` on `WorldEditorPanel` -> asserting gameplay -> exiting back to editor. |
| **UA10** | Save / Load & Editor Separation | Called `main.start_gameplay()` directly | **PARTIALLY VALID** | Lower-level integration test rather than UI flow. | Replaced with Main Menu UI button interactions (`NewGameButton`, `SavesButton`, `ContinueButton`). |
| **UA11** | Main Menu UI Regression | Checked `main.current_mode` | **VALID** | Verified Main Menu boot and node hierarchy. | Retained and strengthened with strict button existence assertions. |
| **UA12** | Input Routing & Isolation | Checked `shell.mouse_filter` | **PARTIALLY VALID** | Checked single property; did not verify keyboard focus consumption or WASD player restoration. | Replaced with comprehensive input focus tests: LineEdit typing consumption + player movement lock/unlock verification. |
| **UA13** | Responsive UI Across 5 Resolutions | Checked `shell.custom_minimum_size = res` | **FATALLY INVALID** | Did not resize viewports, did not test geometry, did not verify clipping or dock layout. | Completely replaced with multi-resolution `SubViewport` geometric layout audit across 720p, 768p, 900p, 1080p, and 1440p checking non-zero bounds, no negative sizes, and dominant canvas area. |
| **UA14** | Corrupt Data & Base Data Protection | Verified `worlds.json` byte integrity and fallback | **VALID** | Verified `res://` immutability and schema fault tolerance. | Retained and expanded to cover all data domains. |

---

## 2. Mandatory Audit Standards Applied

1. **Zero Mock / Evasion Guards:** Removed all `if manager`, `if service`, `assert_true(true)` evasion logic.
2. **Real Input Pipeline:** All tests must pass `InputEvent` instances through Control `_gui_input()` / `_unhandled_input()`.
3. **Strict Separation of Classification:**
   - **UNIT:** Individual class algorithms (e.g. `EditorHistory`, `SelectionManager`).
   - **INTEGRATION:** Multi-service coordination without UI (e.g. `EditorDataService` + `ModManager`).
   - **RUNTIME:** Live SceneTree nodes reacting to lifecycle states.
   - **REAL UI ACCEPTANCE:** Concrete `InputEvent` dispatching, Control focus, and UI button presses.
   - **END-TO-END:** Complete developer flow from Editor UI authoring to Live Gameplay execution.
