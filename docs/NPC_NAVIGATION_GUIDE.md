# Botanical Haven — NPC Navigation & Obstacle-Aware Living World Guide

## Overview

The **NPC Navigation System** provides data-driven, obstacle-aware pathfinding for all characters in Botanical Haven. NPCs no longer move blindly in straight lines; they navigate intelligently around buildings, fences, water, rocks, trees, and custom obstacles while maintaining continuous floating-point world-space locomotion without grid locking.

---

## 1. Architecture

```text
TimeManager (Clock / Season / Weather)
     │
     ▼
NPCManager (Schedule Boundaries & Target Anchors)
     │
     ▼
GridManager.find_path(start_pos, goal_pos)
     │
     ▼
WorldNavigation (AStar2D Graph with String-Pulling & Corner-Check)
     │
     ▼
NPCInstance / SeedMerchant (Waypoint Steering & Local Avoidance)
```

---

## 2. Walkability & Obstacle Integration

The navigation graph is built automatically from [`GridManager`](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/systems/grid/grid_manager.gd):
- **Impassable Tiles**: Any tile where `solid == true` or `walkable == false` (e.g. `fence`, `water`, `void`).
- **Solid World Objects**: Any object placed in `solid_obstacles` (buildings, market stalls, trees, rocks).
- **Corner-Cutting Prevention**: Diagonal connections in [`WorldNavigation`](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/systems/navigation/world_navigation.gd) are strictly forbidden if adjacent orthogonal cells are impassable, ensuring NPCs never cut through wall corners.
- **Line-of-Sight String-Pulling**: Unobstructed straight sections are compressed into smooth diagonal lines, eliminating artificial zigzag/staircase movement.

---

## 3. Waypoint Following & Locomotion

1. When a schedule destination is assigned, `NPCInstance.set_destination()` queries `GridManager.find_path()`.
2. The NPC advances along the waypoint list (`nav_path`) using continuous `Vector2` velocity (`walk_speed = 38.0 px/s`).
3. Directional facing is dynamically computed from the instantaneous motion vector.
4. When entering `< 3.5px` of a waypoint, the NPC advances to the next point until reaching the final destination.
5. Upon arrival at the target, the NPC switches to `STATE_AT_DESTINATION`, sets `velocity = Vector2.ZERO`, and assumes its scheduled activity (`work`, `sleep`, `break`, `socialize`).

---

## 4. NPC-NPC Local Avoidance

When multiple NPCs walk in close proximity (e.g. at market stalls or town squares), each NPC computes a soft repulsion vector against nearby active NPCs within an `18.0px` radius. This prevents unnatural stacking while ensuring movement remains smooth without erratic jitter or oscillation.

---

## 5. Dialogue & Interaction During Navigation

- Interacting with a navigating NPC (`[E] Talk`) sets `is_interacting = true`, stops movement, and turns the NPC to face the player.
- Upon dialogue completion (`dialogue_ended`), the NPC automatically resumes navigation towards its active schedule destination without needing to restart its daily routine.

---

## 6. Navigation Failure & Fallback Policy

If a target point is completely enclosed or disconnected:
1. `nav_failed` is set to `true`.
2. The state transitions to `STATE_NAVIGATION_FAILED`.
3. The NPC logs the unreachable target via `GameLogger`.
4. As a deterministic fallback, the NPC halts in place and transitions safely to `STATE_IDLE` without teleports or infinite loop freezes.
5. Once a valid schedule destination is received, `nav_failed` resets and navigation resumes normally.
