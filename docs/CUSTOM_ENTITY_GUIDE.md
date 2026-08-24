# Botanical Haven — Custom Entity Guide (Phase 42)
## Assembling Entities from Built-in and Custom Components

Entities are dynamic component aggregators with zero hardcoded class inheritance.

---

## 1. Assembling a Pressure Plate
- `TransformComponent`: Position `[100, 200]`
- `VisualComponent`: Sprite `res://assets/plate.png`
- `CollisionComponent`: Shape `box`, Size `[16, 16]`
- `InteractionComponent`: `on_enter: true`, `on_exit: true`
- `StateMachineComponent`: States `["inactive", "active"]`, default `inactive`

---

## 2. Assembling a Treasure Chest
- `TransformComponent`
- `VisualComponent`
- `InteractionComponent`: Range `1.5`
- `StateMachineComponent`: States `["closed", "open"]`, default `closed`
- `InventoryComponent`: Slots `10`, Items `{ "gold_coin": 50 }`
