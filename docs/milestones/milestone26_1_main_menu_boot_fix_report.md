# Milestone 26.1 Report: Main Menu Boot & Navigation Critical Fix

## 1. Executive Summary

In **Phase 26.1**, the application boot pipeline and scene architecture for **Botanical Haven** were completely audited, debugged, and restructured. Previously, the application booted directly into the gameplay world (`Farm`), keeping the Main Menu hidden or suppressed, while interacting with menu buttons or pause menu options could trigger direct application termination (`get_tree().quit()`).

With Phase 26.1, a clean **Bootstrap & Application State Architecture** has been established:
1. **Application Entry Point**: `scenes/main.tscn` (managed by `scenes/main.gd`) acts as the root orchestrator.
2. **Explicit Modes**:
   - `AppMode.MENU`: Displays `MainMenuUI` under `UIContainer`. `SceneContainer` holds zero gameplay simulation; `TimeManager` is paused.
   - `AppMode.GAMEPLAY`: Instantiates the active level (e.g. `Farm`) dynamically inside `SceneContainer`; resumes time, unlocks player input.
   - `AppMode.EDITOR`: Instantiates `EditorShell` dynamically inside `EditorContainer`; halts gameplay simulation and allows in-game modding/data authoring.
3. **Safe Sub-Menu Navigation**: `SaveSelectUI`, `SettingsUI`, `CreditsUI`, and `MultiplayerUI` open and close cleanly with zero unexpected crashes or desktop terminations.
4. **Transition Mutex**: `is_transitioning` boolean guard eliminates rapid double-click race conditions and orphaned scene instances.
5. **100% Verification**: All 22 test suites pass (**738 / 738 tests PASS**).

---

## 2. Root Cause Analysis & Resolutions

| Issue | Root Cause | Resolution |
|---|---|---|
| **Direct Boot to Gameplay** | `scenes/main.tscn` directly instantiated `farm.tscn` as a static child node, running farming, NPC spawns, and time ticks at startup. | Removed static level node. `Main` now starts in `AppMode.MENU` with an empty `SceneContainer`. |
| **Main Menu Inaccessible** | `MainMenu` was nested in `Farm/UI/MainMenu` with `visible = false`. | Extracted `MainMenu` as a direct component of `Main/UIContainer`, opened on `_ready()`. |
| **Quit-to-Desktop on Main Menu Click** | `PauseMenu._on_quit_pressed()` called `get_tree().quit()` directly instead of transitioning to `MainMenu`. | Re-routed Pause Menu quit action to `Main.return_to_main_menu()`. Only the Main Menu's explicit Quit button terminates the process. |
| **Unprotected Scene Transitions** | Rapid button clicks could invoke concurrent async transitions leading to orphaned nodes and freed object errors. | Added `is_transitioning` mutex locks and safe object checks across all scene and menu changes. |
| **Freed Instance in Effects** | `EffectSpawner` timer timeouts invoked `container.queue_free()` directly after scene change without validation. | Added `_safe_free_node` and `is_instance_valid` guards across all VFX spawners. |

---

## 3. Architecture Overview

```
Main (res://scenes/main.tscn)
├── Background (CanvasLayer -100) -> ColorRect (Cozy dark theme)
├── SceneContainer (Node2D)        -> Dynamic World (Farm, Town, etc. when in GAMEPLAY)
├── EditorContainer (CanvasLayer 80) -> Dynamic EditorShell (when in EDITOR)
└── UIContainer (CanvasLayer 50)   -> MainMenuUI / SaveSelectUI / SettingsUI / CreditsUI / MultiplayerUI
```

---

## 4. Main Menu Actions & Capabilities

| Action | Behavior | Return Flow |
|---|---|---|
| **📂 Continue** | Checks `SaveManager.has_any_save()`. Loads active slot and transitions to `GAMEPLAY`. Disabled if no saves exist. | Esc -> PauseMenu -> "Main Menu" returns to `MENU`. |
| **🌱 New Game** | Prompts slot selection via `SaveSelectUI` or starts slot 1. Initializes fresh state and transitions to `GAMEPLAY`. | Esc -> PauseMenu -> "Main Menu" returns to `MENU`. |
| **💾 Saves** | Opens `SaveSelectUI` with slot details, dates, and playtimes. | "Back" button returns cleanly to `MainMenuUI`. |
| **🛠️ Editor** | Transitions `Main` to `EDITOR` mode. Loads `EditorShell` without background gameplay. | "Exit" button in Editor returns cleanly to `MainMenuUI`. |
| **🌐 Multiplayer** | Opens `MultiplayerUI` lobby setup. | "Back" returns cleanly to `MainMenuUI`. |
| **⚙️ Settings & Audio** | Opens `SettingsUI` (Audio sliders, Graphics, Keybinds, Language). | "Cancel"/"Close" returns cleanly to `MainMenuUI`. |
| **📜 Credits** | Opens `CreditsUI` reading data from `res://data/credits.json`. | "Back" / Escape returns cleanly to `MainMenuUI`. |
| **✕ Quit** | Calls `get_tree().quit()` to exit application cleanly. | N/A |

---

## 5. Test Verification Results

All 22 test suites executed via Godot live runtime:

```
========================================
   BOTANICAL HAVEN REGRESSION SUITE
========================================

✅ UNIT.PlayerState — 48/48 PASS
✅ UNIT.ToolSystem — 24/24 PASS
✅ UNIT.QuestSystem — 13/13 PASS
✅ UNIT.Localization — 30/30 PASS
✅ UNIT.AssetRegistry — 10/10 PASS
✅ INTEGRATION.SaveLoad — 15/15 PASS
✅ INTEGRATION.WorldTransitions — 24/24 PASS
✅ INTEGRATION.MovementRegression — 29/29 PASS
✅ INTEGRATION.FarmingChain — 10/10 PASS
✅ MULTIPLAYER.HostAuthoritative — 27/27 PASS
✅ TIME.DayNightSleep — 60/60 PASS
✅ NPC.DailySchedule — 56/56 PASS
✅ NPC.Navigation — 44/44 PASS
✅ NPC.LivingWorld — 40/40 PASS
✅ NPC.BehaviorQuality — 26/26 PASS
✅ NPC.VisualAnimation — 26/26 PASS
✅ NPC.SocialProgression — 62/62 PASS
✅ BALANCE.FirstHourPlaytest — 44/44 PASS
✅ FARMING.GameFeel — 35/35 PASS
✅ ART.ProductionPipeline — 27/27 PASS
✅ EDITOR.Foundation — 47/47 PASS
✅ MAIN_MENU.BootNavigation — 41/41 PASS
----------------------------------------
TOTAL: 738 / 738 TESTS PASS (100% PASS RATE)
```
