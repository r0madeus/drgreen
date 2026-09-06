# Milestone 18 — Time, Day/Night & Sleep System Report

## Executive Summary

Phase 18 establishes a centralized, deterministic, data-driven World Clock, Day/Night visual lighting system, Sleep confirmation workflow, and atomic Next-Day pipeline for **Botanical Haven**. All existing systems—including Farming, Multi-World Transitions, Hotbar & Tool interactions, Quests, Save/Load, Network Multiplayer, Localization, and the Asset Pipeline—remain completely integrated and backwards compatible.

---

## Architectural Implementation Details

### 1. Centralized World Clock (`TimeManager`)
- **Deterministic Minute Clock**: 1 full game day = 1440 minutes.
  - Morning start: `360m` (`06:00 AM`).
  - Noon: `720m` (`12:00 PM`).
  - Evening/Dusk: `1080m` (`06:00 PM`).
  - Midnight/Exhaustion: `1440m` (`12:00 AM`).
- **Data-Driven Configuration** ([`time_config.json`](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/data/time/time_config.json)):
  - Configurable `minutes_per_real_second` (default `1.0`), `day_start_minutes`, `day_end_minutes`, and phase color ranges.
- **Reference-Counted Pausing**:
  - Independent pause sources (`PAUSE_UI`, `PAUSE_DIALOGUE`, `PAUSE_MENU`, `PAUSE_CUTSCENE`, `PAUSE_BUILDER`, `SLEEP_UI`) are tracked in `_pause_reasons: Dictionary`.
  - Closing one modal screen does not unpause the game if another reason is still active.

### 2. Day/Night Cycle & Ambient Lighting (`DayNightOverlay`)
- **Phase Resolution**:
  - `Dawn`: `06:00 AM` to `08:00 AM` (`360m` to `480m`) — Soft warm morning glow.
  - `Day`: `08:00 AM` to `06:00 PM` (`480m` to `1080m`) — Full daylight.
  - `Dusk`: `06:00 PM` to `09:00 PM` (`1080m` to `1260m`) — Golden sunset amber.
  - `Night`: `09:00 PM` to `06:00 AM` (`1260m` to `1440m` / `0m` to `360m`) — Deep blue moonlight.
- **Smooth Modulation**:
  - [DayNightOverlay](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/systems/time/day_night_overlay.gd) blends base ambient color with `SeasonManager.get_season_tint()` using delta-rate interpolation.

### 3. Sleep & Next-Day Pipeline
- **Sleep Confirmation Modal** ([`SleepConfirmationUI`](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/ui/sleep_confirmation_ui.gd)):
  - Interaction with Bed tiles or pressing `[T]` / Hotbar button triggers `request_sleep()`.
  - Displays localized prompt: `"Sleep until tomorrow morning?"` with `Yes` and `Cancel` options.
- **Centralized Next-Day Order of Operations**:
  1. `day_ended` signal dispatched to finalize day activities.
  2. Active player energy restored to `max_energy` (or `50%` if passed out from exhaustion).
  3. Calendar, Season, and Year counters advanced via `SeasonManager`.
  4. Daily weather evaluated deterministically via `WeatherManager`.
  5. Watered crop growth stages advanced across active grid tiles via `GridManager`.
  6. NPC daily schedules and spawn points reset via `NPCManager`.
  7. Auto-save written to active slot via `SaveManager`.
  8. `morning_started` and `day_started` signals dispatched; player wakes up at `06:00 AM`.

### 4. Co-op Host Authoritative Clock Sync
- Host authoritative time broadcasting via RPC in [NetworkGameplay](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/systems/network/network_gameplay.gd).
- Joining clients request and receive authoritative day/time/phase snapshots on connection.

---

## 39-Point Test Suite Verification Matrix

All 39 requirements (T01 through T39) implemented in [`res://tests/integration/test_time_system.gd`](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/tests/integration/test_time_system.gd) pass cleanly:

| ID | Test Scenario | Status |
|---|---|---|
| **T01** | TimeManagerInitialization | **PASS** |
| **T02** | TimeProgression | **PASS** |
| **T03** | TimePause | **PASS** |
| **T04** | TimeResume | **PASS** |
| **T05** | HourChangedEvent | **PASS** |
| **T06** | DayPhaseTransition | **PASS** |
| **T07** | DawnTransition | **PASS** |
| **T08** | DuskTransition | **PASS** |
| **T09** | NightTransition | **PASS** |
| **T10** | HUDClockUpdate | **PASS** |
| **T11** | SleepInteraction | **PASS** |
| **T12** | SleepConfirmation | **PASS** |
| **T13** | NextDay | **PASS** |
| **T14** | CalendarAdvance | **PASS** |
| **T15** | CropGrowthOnNewDay | **PASS** |
| **T16** | WateredCropGrowth | **PASS** |
| **T17** | UnwateredCropBehavior | **PASS** |
| **T18** | SeasonTransition | **PASS** |
| **T19** | WeatherIntegration | **PASS** |
| **T20** | NPCDayStartHook | **PASS** |
| **T21** | QuestDayHook | **PASS** |
| **T22** | WorldTransitionPreservesTime | **PASS** |
| **T23** | SaveTime | **PASS** |
| **T24** | LoadTime | **PASS** |
| **T25** | OldSaveMigration | **PASS** |
| **T26** | InvalidTimeRecovery | **PASS** |
| **T27** | MultiplayerHostClock | **PASS** |
| **T28** | MultiplayerClientClockSync | **PASS** |
| **T29** | MultiplayerLateJoinClockSnapshot | **PASS** |
| **T30** | LocalStateIsolation | **PASS** |
| **T31** | PauseReasonIsolation | **PASS** |
| **T32** | DoubleDayAdvanceProtection | **PASS** |
| **T33** | SingleplayerRegression | **PASS** |
| **T34** | FarmingRegression | **PASS** |
| **T35** | SaveLoadRegression | **PASS** |
| **T36** | WorldTransitionRegression | **PASS** |
| **T37** | MultiplayerRegression | **PASS** |
| **T38** | LocalizationRegression | **PASS** |
| **T39** | AssetPipelineRegression | **PASS** |

---

## Overall Regression Suite Summary

```text
========================================
   BOTANICAL HAVEN REGRESSION SUITE
========================================

UNIT.PlayerState:               48/48 PASS (100%)
UNIT.ToolSystem:                24/24 PASS (100%)
UNIT.QuestSystem:               13/13 PASS (100%)
UNIT.Localization:              30/30 PASS (100%)
UNIT.AssetRegistry:             10/10 PASS (100%)
INTEGRATION.SaveLoad:           15/15 PASS (100%)
INTEGRATION.WorldTransitions:   24/24 PASS (100%)
INTEGRATION.MovementRegression: 29/29 PASS (100%)
INTEGRATION.FarmingChain:       10/10 PASS (100%)
MULTIPLAYER.HostAuthoritative:  27/27 PASS (100%)
TIME.DayNightSleep:             60/60 PASS (100%)

TOTAL: 290 / 290 TESTS PASS (100% PASS RATE)
SCRIPT VALIDATION: 147 / 147 SCRIPTS VALID (0 ERRORS)
```
