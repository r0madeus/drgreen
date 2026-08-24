# Botanical Haven — Generic Event System & Context Specification
## Standardized Event Hierarchy for Custom Gameplay Rules

Events carry rich contextual payloads that condition evaluators and action sequences query via dot-notation.

---

## 1. Event Payloads Reference

### `entity.death`
- `source`: Entity that died.
- `payload`: `{ "killer": "<id>", "damage_type": "fire" }`

### `timer.completed`
- `source`: Timer name.
- `payload`: `{ "timer_name": "door_close" }`

### `plate.enter` / `plate.exit`
- `source`: Pressure plate entity.
- `payload`: `{ "actor": "player", "plate_id": "plate_01" }`

### `item.collected`
- `source`: Collectible entity.
- `payload`: `{ "item_id": "dungeon_key", "amount": 1, "collector": "player" }`
