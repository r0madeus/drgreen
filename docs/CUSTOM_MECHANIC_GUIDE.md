# Botanical Haven — Custom Mechanic Graph Guide (Phase 42)
## Visual Logic, Declarative Expressions & Live Simulation

The Mechanic Graph connects Events, Conditions, Action Sequences, and State Transitions into declarative execution chains without GDScript.

---

## 1. Safe Declarative Expression Evaluation

Expressions are sandboxed and resolve dot-notation paths safely:
- `component.hunger.current <= 25.0`
- `state_machine.current_state == "closed"`
- `inventory.contains("meat")`

---

## 2. Mechanic Graph Execution Flow

```
[ Trigger Event: hunger.changed ]
             │
             ▼
[ Condition: component.hunger.current <= 25.0 ]
       ├── True  ➔ [ Action: transition_state("hungry") ]
       └── False ➔ continue
             │
             ▼
[ Condition: component.hunger.current <= 0.0 ]
       ├── True  ➔ [ Action: transition_state("starving") ]
       │            [ Action: damage_entity(5.0) ]
       └── False ➔ continue
```
