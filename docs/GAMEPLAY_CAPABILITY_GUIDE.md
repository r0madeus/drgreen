# Botanical Haven — Gameplay Capability Resolution Guide
## Querying Behaviors Instead of Concrete Entity Classes

A **Capability** represents what an entity can *do*, dynamically inferred from its attached components.

---

## 1. Capability Resolution Map

```gdscript
# Querying capabilities in GDScript or Rules:
if entity.has_capability("combat"):
    # Entity has HealthComponent and/or CombatComponent
    pass

if entity.has_capability("interactable"):
    # Entity has InteractionComponent
    pass

if entity.has_capability("stateful"):
    # Entity has StateMachineComponent
    pass
```

---

## 2. Standard Capabilities

- `interactable`: Player or world can trigger interactions.
- `combat`: Can deal damage or participate in combat calculations.
- `damageable`: Can take damage, deplete health, and die.
- `inventory`: Can store and transfer items.
- `stateful`: Has finite state machine with transitions.
- `timed`: Runs local or global countdown timers.
- `destructible`: Takes damage and shatters/drops items.
- `collectible`: Can be picked up directly into an inventory.
