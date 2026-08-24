# Botanical Haven — NPC Living World, Daily Behavior & Social Simulation Guide

## Overview

The **NPC Living World & Behavior System** turns characters into reactive, socially simulated town residents. NPCs perform data-driven activities (work, eat, rest, sleep, wander, sit, shop), react naturally to player presence and weather events, interact socially with each other, and manage prioritized schedule interrupts while following continuous, obstacle-aware world-space paths.

---

## 1. Architecture

```text
TimeManager & WeatherManager
            │
            ▼
        NPCManager ──── Social Coordination & Schedules
            │
            ▼
   NPCBehaviorController ──── State Machine & Interrupt Priority
            │
            ▼
    NPCInstance / SeedMerchant ──── Waypoint Steering & Locomotion
            │
            ▼
     WorldNavigation ──── Obstacle-Aware Pathfinding (AStar2D)
```

---

## 2. Behavior State Machine

The state machine is managed by [`NPCBehaviorController`](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/systems/npc/npc_behavior_controller.gd):

| State | Description |
|---|---|
| `IDLE` | Standing at current position. |
| `WALKING` / `TRAVELING` / `NAVIGATING` | Moving along obstacle-aware navigation waypoints toward destination. |
| `WORKING` | Attending market stall, research desk, or farm field. |
| `SOCIALIZING` / `TALKING` | Conversing with another NPC in a shared social area. |
| `EATING` | Eating meal at dining area. |
| `RESTING` / `SITTING` | Lounging at porch, chair, or bench. |
| `SHOPPING` | Browsing or trading at store. |
| `PLAYER_INTERACTION` | Paused and facing the player during dialogue. |
| `SLEEPING` | Sleeping at home overnight. |
| `WANDERING` | Strolling to random walkable tiles in assigned social area. |
| `NAVIGATION_FAILED` | Safe fallback state when a destination is unreachable. |

---

## 3. Interrupt Priority Stack

```text
INTERRUPT_PLAYER (6)
  > INTERRUPT_EMERGENCY (5)
    > INTERRUPT_QUEST (4)
      > INTERRUPT_SOCIAL (3)
        > INTERRUPT_SCHEDULE (2)
          > INTERRUPT_WANDER (1)
            > INTERRUPT_NONE (0)
```

- When the player interacts with an NPC, the controller saves `saved_state`, `saved_activity`, and `saved_target_pos`.
- Upon dialogue completion, the NPC automatically restores its prior state and continues its active navigation path without restarting the whole day.

---

## 4. NPC-NPC Social Simulation

- Defined in [`data/npcs/social.json`](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/data/npcs/social.json).
- When two idle/resting/wandering NPCs come within `40.0px` in a shared social zone:
  1. Both NPCs turn to face each other.
  2. Enter `STATE_SOCIALIZING`.
  3. Emit `EventBus.npc_social_started(npc_a, npc_b, "casual_greeting")`.
  4. After 4.0 seconds, emit `EventBus.npc_social_finished(npc_a, npc_b)` and resume their daily schedule.
  5. A 30-second social cooldown is applied to prevent repetitive chatting loops.

---

## 5. Weather & Time Reactivity

- **Rain Events**: When `WeatherManager` signals rain, NPCs with rain schedule variants automatically transition to indoor/sheltered locations.
- **Night Sleep**: Late night hours route NPCs to their home beds.
- **New Day**: On `TimeManager.day_started`, all NPC routines reset to their morning schedules.
