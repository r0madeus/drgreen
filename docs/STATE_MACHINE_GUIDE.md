# Botanical Haven — State Machine Authoring Guide
## Defining Deterministic Entity State Transitions

Entities with `StateMachineComponent` manage discrete states (`closed`, `opening`, `open`, `closing`, `idle`, `patrol`, `chase`, `attack`).

---

## 1. Defining States in JSON

```json
{
  "states": ["closed", "opening", "open", "closing"],
  "current_state": "closed",
  "transitions": {
    "closed": ["opening"],
    "opening": ["open"],
    "open": ["closing"],
    "closing": ["closed"]
  }
}
```

---

## 2. Triggering Transitions via Rules

```json
{
  "type": "transition_state",
  "target": "iron_gate",
  "state": "open"
}
```
