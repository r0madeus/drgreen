# Botanical Haven — NPC Relationship & Social System Guide

## Overview

The **NPC Relationship & Social Progression System** bridges farming, harvesting, and living world simulation with character progression. The system is data-driven, host-authoritative in multiplayer, and integrated with `PlayerState`, `QuestManager`, `RewardManager`, and `DialogueManager`.

---

## 1. Heart Level & Friendship Points Model

Friendship is tracked per-player and per-NPC using **Friendship Points** that resolve into **Heart Levels (0–5)**:

| Heart Level | Point Range | Status Key | Description |
|---|---|---|---|
| **Heart 0** | 0 – 99 | `social.status.stranger` | Initial introduction level. |
| **Heart 1** | 100 – 199 | `social.status.acquaintance` | Basic familiarity; unlocks unique greetings. |
| **Heart 2** | 200 – 299 | `social.status.friendly` | Unlocks character-specific side quests. |
| **Heart 3** | 300 – 399 | `social.status.friend` | Unlocks economic / shop discounts and rare seeds. |
| **Heart 4** | 400 – 499 | `social.status.close_friend` | Unlocks exclusive crafting/synthesis recipes. |
| **Heart 5** | 500+ | `social.status.best_friend` | Maximum friendship; awards community trophies. |

---

## 2. Gifting & Item Preferences

NPC gift preferences are configured in `res://data/npcs/preferences.json`:

```json
{
  "preferences": {
    "rowan": {
      "loved": ["plant_sun_petal", "plant_golden_sunflower", "fertilizer_organic"],
      "liked": ["plant_red_flower", "plant_yellow_herb", "seed_red_flower"],
      "neutral": ["wood_oak", "stone"],
      "disliked": ["weeds", "debris_rock"],
      "hated": ["trash", "rotten_plant"]
    }
  }
}
```

### Point Calculations & Daily Limits
- **Loved (+80 pts)**: Special appreciation dialogue & particle burst.
- **Liked (+45 pts)**: Warm gratitude dialogue.
- **Neutral (+20 pts)**: Standard acceptance.
- **Disliked (-20 pts)**: Disappointed reaction.
- **Hated (-40 pts)**: Strong negative reaction.
- **Limit**: Max **1 gift per day** per NPC. Resets automatically at 06:00 on each new day.

---

## 3. Data-Driven Dialogue Condition Engine

Dialogue trees in `res://data/dialogue/*.json` evaluate declarative conditions deterministically. Candidate nodes are filtered by conditions and the one with the highest `priority` is selected.

### Supported Condition Types:
- `heart_level` / `min_hearts`: Minimum heart requirement (`{ "type": "heart_level", "min": 2 }`).
- `min_friendship`: Minimum raw friendship points.
- `weather`: Active weather condition (`{ "type": "weather", "is": "rain" }`).
- `season`: Current season (`{ "type": "season", "is": "spring" }`).
- `quest_active`: Required active quest (`{ "type": "quest_active", "quest_id": "quest_01" }`).
- `quest_completed`: Required finished quest.
- `world_unlocked`: Required unlocked world.
- `plants_discovered`: Minimum count of journal discoveries.
- `dialogue_seen`: History check for branching dialogue.

---

## 4. Heart Milestones & Reward Integration

Milestones in `res://data/npcs/milestones.json` award items, gold, and quest triggers via `RewardManager`:

```json
{
  "milestones": {
    "rowan": [
      { "heart_level": 1, "rewards": { "gold": 50 } },
      { "heart_level": 2, "rewards": { "unlock": "quest_rowan_herbalist" } },
      { "heart_level": 3, "rewards": { "gold": 150, "item": { "seed_golden_sunflower": 3 } } }
    ]
  }
}
```

---

## 5. Adding a New NPC (Zero GDScript Changes)

To add a new NPC with full relationship and social support:
1. Define NPC schedule and metadata in `data/npcs/schedules.json` and `data/npcs/locations.json`.
2. Add gift preferences to `data/npcs/preferences.json`.
3. Add heart milestone rewards to `data/npcs/milestones.json`.
4. Create dialogue script in `data/dialogue/{npc_id}.json` with prioritized condition nodes.
5. Add localized names and dialogue strings in `localization/game.csv`.
