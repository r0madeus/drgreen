# Botanical Haven — Gameplay Balance & Economy Guide

## Overview

This guide details the mathematical balancing, pacing, energy costs, economic ROI, and friendship progression curves designed for **Botanical Haven**. All values are data-driven and maintained within `res://data/`.

---

## 1. Energy & Stamina System

The player starts with **100 Max Energy**. Daily farm chores and foraging consume predictable energy:

| Tool / Action | Base Energy Cost | Operations / 100 Energy | Day 1 Typical Usage |
|---|---:|---:|---:|
| **Hoe (Till Ground)** | 2.0 | 50 plots | 5 plots (10.0 energy) |
| **Watering Can** | 1.5 | 66 plots | 5 plots (7.5 energy) |
| **Axe (Wood Chopping)** | 3.0 | 33 chops | 3 chops (9.0 energy) |
| **Pickaxe (Mining Rock)** | 3.0 | 33 swings | 2 swings (6.0 energy) |
| **Planting / Harvesting** | 0.0 | Unlimited | Free action |
| **Sleep at Night** | +100.0 | Full Recovery | Resets to 100/100 |

> **Balance Assessment**: A typical Day 1 uses **32.5 Energy**, leaving **67.5 Energy** for exploration, NPC social interactions, and village transit. Players are never prematurely immobilized on their first day.

---

## 2. Crop Economy & Return on Investment (ROI)

Seed and crop selling prices create clear economic tiers:

| Crop Name | Seed Buy Price | Growth Time | Crop Sell Price | Yield / Harvest | Net Profit / Seed | ROI |
|---|---:|---:|---:|---:|---:|---:|
| **Red Flower** | 25g | 3 Days | 50g | 1 – 2 | +25g to +75g | **2.0x – 4.0x** |
| **Yellow Herb** | 20g | 2 Days | 40g | 1 – 2 | +20g to +60g | **2.0x – 4.0x** |
| **Blue Flower** | 30g | 4 Days | 60g | 1 – 2 | +30g to +90g | **2.0x – 4.0x** |
| **White Lily** | 35g | 4 Days | 75g | 1 – 2 | +40g to +115g | **2.1x – 4.3x** |
| **Green Vine** | 40g | 5 Days | 80g | 1 – 2 | +40g to +120g | **2.0x – 4.0x** |

---

## 3. Social Progression & Heart Cadence

Friendship points scale smoothly across 5 Hearts (100 points per Heart):

| Interaction | Friendship Points | Frequency Limit | Days to Heart 1 | Days to Heart 2 |
|---|---:|---|---|---|
| **Daily Talk** | +20 pts | 1 / Day | 5 Days | 10 Days |
| **Liked Gift** | +45 pts | 1 / Day | 3 Days | 5 Days |
| **Loved Gift** | +80 pts | 1 / Day | 1 – 2 Days | 3 – 4 Days |
| **Heart 2 Quest** | +50 pts | One-time | N/A | Immediate boost to Heart 3 |

---

## 4. First-Hour Playtest Progression Summary

```text
DAY 1:
- Start with 100g & 16 starter seeds.
- Plant 5 Red Seeds (use 17.5 energy).
- Talk & Gift Rowan (Loved Gift -> 100 pts -> Heart 1 unlocked!).
- Milestone 1 awards +50g. Complete Quest 1 (+25g).
- Ending Gold: 175g. Remaining Energy: 82.5.

DAY 2:
- Water 5 crops (7.5 energy). Chop 2 wood (6.0 energy).
- Talk & Gift Rowan (Liked Gift -> 165 pts).
- Complete Quest 2 (+25g).
- Ending Gold: 200g.

DAY 3:
- Harvest 5 Red Flowers!
- Sell 4 crops (+200g) and gift 1 crop (+45 pts -> 230 pts -> Heart 2 unlocked!).
- Heart 2 unlocks "Rowan's Herbal Tonic" Quest!
- Complete Quest 3 (+35g).
- Ending Gold: 435g.
```
