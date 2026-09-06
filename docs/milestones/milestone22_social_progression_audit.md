# Milestone 22 — Player Progression, NPC Relationships & Social Gameplay Audit Report

## Executive Summary

Phase 22 conducted a comprehensive, non-destructive audit of **Botanical Haven's** player progression, NPC relationship, dialogue, quest, and world systems. The audit identified that while robust lower-level primitives exist (such as raw friendship points in `PlayerState`, multi-world unlocks in `ProgressionManager`, and quest reward granting in `RewardManager`), the social layer lacks a structured **Heart / Relationship Level tier system**, has **hardcoded dialogue branch evaluations**, lacks a **data-driven Gifting engine**, and has no **Heart-gated milestone unlocks**.

This report outlines the existing systems, architectural risks, data-driven design specifications, long-term gameplay loop retention analysis, and a phased implementation roadmap.

---

## 1. Existing Systems & Current State Matrix

| System Component | File Path | Current Status | Capabilities & Limitations |
|---|---|---|---|
| **Player State & Friendship** | [`player_state.gd`](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/systems/player/player_state.gd) | **Functional Primitive** | Tracks raw integer points `friendship[npc_id]`; saves per-player in multiplayer. Lacks heart tiers (0–5), daily interaction caps, and relationship status. |
| **Dialogue Manager** | [`dialogue_manager.gd`](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/systems/dialogue/dialogue_manager.gd) | **Functional (Hardcoded Nodes)** | Loads JSON dialogues and displays lines via UI. However, node selection (`_evaluate_dialogue_node_key`) is **hardcoded in GDScript** rather than data-driven. |
| **Quest & Reward Engine** | [`quest_manager.gd`](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/systems/quest/quest_manager.gd), [`reward_manager.gd`](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/systems/quest/reward_manager.gd) | **Working** | Quests award Gold, Items, Unlocks, and Friendship. However, quests cannot currently be unlocked by NPC friendship level (`friendship_level >= 2`). |
| **Progression Manager** | [`progression_manager.gd`](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/systems/progression/progression_manager.gd) | **Working** | Data-driven world unlocks via `world_unlocks.json` based on quests and plant discoveries. |
| **Gifting System** | N/A | **Missing** | No gift transfer interaction, item preference tables (Loved, Liked, Neutral, Disliked, Hated), or weekly gift limits. |
| **Multiplayer Authority** | [`network_npc.gd`](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/systems/network/network_npc.gd) | **Working** | Personal friendship and personal dialogue history are properly isolated to each individual player peer. |
| **Save / Load Persistence** | [`save_manager.gd`](file:///C:/Users/Melih%20U%C3%A7gun/Documents/aitest/systems/save/save_manager.gd) | **Working** | Serializes `PlayerState` per active slot. Backward-compatible migration supported. |

---

## 2. Detailed Audit Findings

### 2.1 NPC Relationship System
- **Storage**: `PlayerState.friendship` dictionary (`npc_id -> points`).
- **Points Source**: +5 points on daily interaction (`NetworkNPC`), quest rewards (+10 to +25 points via `RewardManager`).
- **Gaps**:
  - Raw point integers without defined Heart tiers (e.g. 100 points = 1 Heart, max 5 Hearts = 500 points).
  - No daily conversation point limit (+20 points once per game day).
  - No relationship status indicators (Stranger, Acquaintance, Friend, Close Friend, Best Friend).

### 2.2 Dialogue Progression Architecture
- **Issue**: `DialogueManager._evaluate_dialogue_node_key()` contains hardcoded `if dialogue_id == "rowan": if jm.get_discovered_plants_count() >= 8...`.
- **Requirement**: Replace hardcoded checks with a universal, data-driven condition evaluator supporting:
  - `min_hearts` / `min_friendship_points`
  - `season` (`spring`, `summer`, `autumn`, `winter`)
  - `weather` (`clear`, `rain`, `storm`)
  - `time_of_day` (`morning`, `day`, `evening`, `night`)
  - `quest_active` / `quest_completed`
  - `unseen_priority` (first encounter vs daily greeting pools)

### 2.3 Gifting & Item Preference System
- **Missing Architecture**:
  - Need data-driven NPC preference catalog (`res://data/npcs/preferences.json`):
    - `loved` (+80 pts, unique dialogue reaction)
    - `liked` (+45 pts)
    - `neutral` (+20 pts)
    - `disliked` (-20 pts)
    - `hated` (-40 pts)
  - Need daily gift limit (1 gift per day per NPC, max 2 gifts per week).

### 2.4 World & Economy Progression Integration
- Reaching relationship milestones should unlock tangible gameplay rewards:
  - **Heart 1**: Unique daily greeting variations and lore dialogue.
  - **Heart 2**: NPC-specific side quest unlocked.
  - **Heart 3**: Shop discounts (e.g. 10% seed discount from Rowan, exclusive general store stock from Elias).
  - **Heart 4**: Unique hybrid seed blueprint or tool crafting recipe.
  - **Heart 5**: Rare decorative item or community trophy.

---

## 3. Gameplay Loop & Long-Term Retention Analysis

```text
CURRENT LOOP:
Farming (Till/Plant/Water/Harvest) ──► Sell for Gold ──► Buy Seeds ──► Base Quests ──► World Unlock
                                                                                       │
                                                                                       ▼
                                                                             [LOOP TERMINATES]

ENHANCED SOCIAL & RETENTION LOOP (PROPOSED):
Farming ──► Harvest Diverse Crops & Forage
   │
   ├─► Deliver Daily Gifts (Loved/Liked Crops) ──► Increase Heart Level (1 to 5)
   │                                                     │
   ├─► Daily Conversations (Weather/Season/Lore)        ▼
   │                                            Unlock Heart Milestones
   │                                            ├─► Special NPC Story Quests
   │                                            ├─► Shop Discounts & Exclusive Seeds
   │                                            ├─► Synthesis Blueprints
   │                                            └─► Community Greenhouse Restorations
   ▼
Long-Term Narrative & Economic Mastery
```

---

## 4. Proposed Implementation Plan for Phase 22+

### Priority 0 (P0) — Critical Foundation
1. **Relationship Tiers & Hearts Model**:
   - Standardize 5 Heart levels (100 pts per Heart, max 500 pts).
   - Add daily conversation cap (once per game day).
2. **Data-Driven Dialogue Condition Engine**:
   - Remove hardcoded branches in `DialogueManager`.
   - Implement declarative evaluation for weather, season, hearts, and quest status from JSON.

### Priority 1 (P1) — Core Social Gameplay
3. **Data-Driven Gifting Engine (`preferences.json`)**:
   - NPC item preference tables with Loved, Liked, Neutral, Disliked, Hated tiers.
   - Gift interaction interface (`[G] Give Gift` from Hotbar/Inventory).
   - Daily/weekly gifting limits tracked in `PlayerState`.
4. **Heart Milestone Rewards & Unlock Routing**:
   - Heart 2/3/4/5 milestone triggers unlocking quests, shop discounts, and recipes via `RewardManager`.

### Priority 2 (P2) — Polish & Observability
5. **Relationship UI & Journal Integration**:
   - Relationship tab in Journal / HUD displaying hearts, gift counts, and unlocked lore.
6. **Multiplayer Isolation & Save/Load Verification**:
   - Ensure co-op peers maintain independent heart levels and gift logs.

---

## 5. Verification & Test Plan

1. **Relationship Persistence**: Verify `PlayerState` serializes and restores heart levels and points.
2. **Friendship Progression**: Verify talk once/day gives points, duplicate talks same day yield 0 extra points.
3. **Dialogue Conditions**: Verify rainy weather, high friendship, and quest state select expected dialogue nodes from JSON.
4. **Gift Preferences**: Test Loved (+80), Liked (+45), Neutral (+20), Disliked (-20), Hated (-40) reactions and daily limits.
5. **Milestone Unlocks**: Test reaching Heart 2 unlocks related quest and Heart 3 unlocks shop discounts.
6. **Multiplayer Isolation**: Ensure Player 1 and Player 2 maintain independent friendship states in co-op.
7. **Regression Suite**: 100% pass across all 482 existing test cases.

---

## 6. Recommendation

The highest-leverage next step for **Phase 22 Implementation** is:
> **Implement the Data-Driven Relationship Tier & Gifting Engine with Declarative Dialogue Progression.**
> This directly connects the completed farming/harvesting loop with the Living NPC world, giving harvested crops and daily interactions immediate purpose.
