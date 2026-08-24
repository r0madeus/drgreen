# Botanical Haven — Custom Game Mechanics Authoring Guide
## Building Emergent Gameplay Without GDScript Code

This guide demonstrates how to author two complete non-farming mechanics using Generic Components, Timers, States, and Gameplay Rules.

---

## Mechanic 1: Enemy Loot Drop & Auto-Closing Door
1. **Enemy**: Attach `HealthComponent` and `LootComponent` (`drop_item: "dungeon_key"`).
2. **Door**: Attach `StateMachineComponent` (`states: ["closed", "open"]`).
3. **Trigger A (Enemy Death)**:
   - `WHEN entity.death` -> `THEN drop_loot("dungeon_key")`
4. **Trigger B (Door Interact)**:
   - `WHEN door_interacted` -> `IF inventory.dungeon_key >= 1` -> `THEN remove_item("dungeon_key"), transition_state(door, "open"), start_timer("door_close", 5.0)`
5. **Trigger C (Timer Completed)**:
   - `WHEN timer.completed("door_close")` -> `THEN transition_state(door, "closed")`

---

## Mechanic 2: Pressure Plate Secret Door
1. **Pressure Plate**: Attach `InteractionComponent` (`on_enter: true`, `on_exit: true`) and `StateMachineComponent`.
2. **Trigger A (Step On)**:
   - `WHEN plate.enter` -> `THEN transition_state(plate, "activated"), transition_state(secret_door, "open")`
3. **Trigger B (Step Off)**:
   - `WHEN plate.exit` -> `THEN transition_state(plate, "deactivated"), transition_state(secret_door, "closed")`
