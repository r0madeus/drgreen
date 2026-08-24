# Botanical Haven — NPC Daily Schedule & Living World Guide

## Overview

The **NPC Daily Schedule & Living World System** enables characters to follow realistic, data-driven daily routines. NPCs continuously move between locations using smooth world-space navigation (without grid snapping), adjust their behavior based on time and weather, and seamlessly transition between worlds.

---

## 1. Defining Locations & Anchors (`locations.json`)

All destination coordinates and anchor points are defined in `res://data/npcs/locations.json`.

```json
{
  "locations": {
    "rowan_home": {
      "world": "farm",
      "position": [224.0, 56.0],
      "grid_position": [14, 3],
      "name_key": "location.rowan_home"
    },
    "seed_shop": {
      "world": "farm",
      "position": [248.0, 56.0],
      "grid_position": [15, 3],
      "name_key": "location.seed_shop"
    }
  }
}
```

### Fields:
- `world`: The world scene identifier (`farm`, `town`, `forest`, `botanical_grove`, etc.).
- `position`: `[x, y]` world-space floating point coordinate in pixels.
- `grid_position`: `[x, y]` integer tile coordinates for spatial queries.
- `name_key`: Localization key for HUD/Journal display.

---

## 2. Defining NPC Daily Schedules (`schedules.json`)

Schedules are defined in `res://data/npcs/schedules.json`. Each NPC can have a `default` schedule as well as conditional variants (e.g. `rain`, `summer`, `winter`, `festival`).

```json
{
  "schedules": {
    "rowan": {
      "default": [
        {
          "start_time": "06:00",
          "start_minute": 360,
          "location_id": "rowan_home",
          "activity": "home",
          "facing": [0, 1]
        },
        {
          "start_time": "09:00",
          "start_minute": 540,
          "location_id": "seed_shop",
          "activity": "work",
          "facing": [0, 1]
        },
        {
          "start_time": "13:00",
          "start_minute": 780,
          "location_id": "farm_porch",
          "activity": "break",
          "facing": [1, 0]
        },
        {
          "start_time": "21:00",
          "start_minute": 1260,
          "location_id": "rowan_home",
          "activity": "sleep",
          "facing": [0, 1]
        }
      ],
      "rain": [
        {
          "start_time": "06:00",
          "start_minute": 360,
          "location_id": "rowan_home",
          "activity": "home",
          "facing": [0, 1]
        },
        {
          "start_time": "09:00",
          "start_minute": 540,
          "location_id": "seed_shop",
          "activity": "work",
          "facing": [0, 1]
        },
        {
          "start_time": "18:00",
          "start_minute": 1080,
          "location_id": "rowan_home",
          "activity": "sleep",
          "facing": [0, 1]
        }
      ]
    }
  }
}
```

---

## 3. Routine State Machine

Each `NPCInstance` manages its own active state:

| State | Description |
|---|---|
| `IDLE` | Stationary at the current anchor point. |
| `TRAVELING` | Moving smoothly in world-space toward `target_world_pos` at `walk_speed` (38 px/s). |
| `AT_DESTINATION` | Reached the target anchor; velocity is zero. |
| `WORKING` | Attending market stall, desk, or workstation. |
| `SOCIALIZING` | Interacting with player in dialogue or shop modal. |
| `RESTING` / `BREAK` | Lounging at porch or bench. |
| `SLEEPING` | Resting at home. |

---

## 4. How to Add a New NPC Schedule

1. Add your NPC profile in `res://data/npcs/<npc_id>.json`.
2. Add target location anchors in `res://data/npcs/locations.json`.
3. Add schedule entries in `res://data/npcs/schedules.json`.
4. Add localization entries in `res://localization/game.csv` for location and activity names.
5. The `NPCManager` will automatically evaluate and execute the new routine at runtime with zero additional GDScript required!
