# Botanical Haven — Generic Gameplay System Architecture
## Event, Condition, Action & Trigger Engine (Phase 39)

The Botanical Haven Engine features a fully modular, data-driven **Generic Gameplay Architecture** capable of powering any game genre (Farming, RPG, Adventure, Simulation, Puzzle).

---

## 1. System Pipeline

```
[ GAMEPLAY EVENT BUS ]
         │ (Dispatches GameplayEvent)
         ▼
[ TRIGGER EVALUATOR ] ◄── Cooldown & Priority Sorting
         │
         ▼
[ CONDITION EVALUATOR ] ◄── Dot-notation, operators, AND/OR/NOT trees
         │ (True / False)
         ▼
[ ACTION SEQUENCE ] ──► Atomic state modifications, branching, chaining
         │
         ▼
[ GLOBAL STATE & PERSISTENCE ] (Flags, Variables, SaveData.gameplay_state)
```

---

## 2. Core Components Reference

### A. `GameplayEvent` (`res://core/gameplay/gameplay_event.gd`)
- Fields: `event_id`, `event_type`, `source`, `target`, `payload`, `context`, `timestamp`, `authority`, `replication`.
- Example events: `player_entered_world`, `entity_interacted`, `item_added`, `dialogue_completed`, `quest_completed`, `custom_event`.

### B. `GameplayCondition` (`res://core/gameplay/gameplay_condition.gd`)
- Operators: `==`, `!=`, `>`, `<`, `>=`, `<=`, `contains`, `not_contains`, `exists`, `not_exists`, `in_range`.
- Logical combinators: `all` (AND), `any` (OR), `not` / `none` (NOT).
- Path resolution: dot notation over context (`flags.door_open`, `player.gold`, `inventory.key_iron`).

### C. `GameplayAction` (`res://core/gameplay/gameplay_action.gd`)
- Built-in actions: `set_flag`, `clear_flag`, `set_var`, `modify_var`, `add_item`, `remove_item`, `add_gold`, `remove_gold`, `change_world`, `start_dialogue`, `start_quest`, `complete_quest`, `show_message`, `call_event`, `branch`.

### D. `GameplayTrigger` (`res://core/gameplay/gameplay_trigger.gd`)
- Ties events to condition filters and action sequences with `priority`, `cooldown`, and `once` restrictions.

### E. `GameplayRuleManager` (`res://core/gameplay/gameplay_rule_manager.gd`)
- Global authority for active triggers, persistent flags, game variables, and event dispatching.

### F. `GameplaySimulator` (`res://core/gameplay/gameplay_simulator.gd`)
- Sandboxed dry-run engine for live testing in the In-Game Editor without altering live state or save files.
