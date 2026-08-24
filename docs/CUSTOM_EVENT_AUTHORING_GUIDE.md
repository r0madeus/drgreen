# Botanical Haven — Custom Event Authoring Guide (Phase 42)
## Standardized Custom Events and Context Schema

Custom events notify the Gameplay Rule Manager and Mechanic Graphs when state changes occur.

---

## 1. Example Event Schemas

### `hunger.changed`
- **Source:** Entity with `HungerComponent`
- **Payload:** `{ "current": 20.0, "maximum": 100.0 }`

### `hunger.empty`
- **Source:** Entity with `HungerComponent`
- **Payload:** `{ "entity": "player", "starvation_ticks": 1 }`

### `pressure_plate.enter` / `pressure_plate.exit`
- **Source:** Pressure Plate entity
- **Payload:** `{ "plate_id": "plate_01", "actor": "player" }`
