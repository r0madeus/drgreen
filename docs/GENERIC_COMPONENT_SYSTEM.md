# Botanical Haven — Generic Component System Architecture (Phase 41)
## Decoupled, Data-Driven Entity-Component Framework

The Botanical Haven Engine replaces rigid object hierarchies and hardcoded class checks (`if type == "enemy"`) with a completely data-driven **Generic Component Architecture**.

---

## 1. Core Model & Composition

```
[ GenericEntity ]
     ├── TransformComponent      (position, rotation, scale)
     ├── VisualComponent         (sprite, color, layer)
     ├── CollisionComponent      (shape, size, solid)
     ├── InteractionComponent    (event, range, on_enter, on_exit)
     ├── HealthComponent         (max_health, current_health, regeneration)
     ├── CombatComponent         (attack_power, attack_range, cooldown)
     ├── InventoryComponent      (slots, items)
     ├── StateMachineComponent   (states, current_state, transitions)
     ├── TimerComponent          (named countdown timers)
     └── StatsComponent          (base stats, flat & percentage modifiers)
```

---

## 2. Component Registry Reference

| Component Type | Default Schema Keys | Derived Capabilities |
| :--- | :--- | :--- |
| `transform` | `position`, `rotation`, `scale` | `transform` |
| `visual` | `sprite`, `color`, `layer` | `renderable` |
| `collision` | `shape`, `size`, `solid` | `collidable` |
| `interaction` | `event`, `range`, `on_enter`, `on_exit` | `interactable` |
| `health` | `max_health`, `current_health`, `regeneration` | `health`, `damageable` |
| `combat` | `attack_power`, `attack_range`, `cooldown`, `damage_type` | `combat`, `attacker` |
| `inventory` | `slots`, `items` | `inventory`, `container` |
| `equipment` | `weapon`, `armor`, `accessory` | `equipment` |
| `state_machine` | `states`, `current_state`, `transitions` | `stateful` |
| `timer` | `timers` | `timed` |
| `destructible` | `durability`, `cracked_threshold`, `drop_item` | `destructible` |
| `collectible` | `item_id`, `amount`, `auto_pickup` | `collectible` |
| `stats` | `base`, `modifiers` | `stats` |
| `spawner` | `spawn_type`, `interval`, `max_count` | `spawner` |
