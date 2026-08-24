# Botanical Haven — Art Production Pipeline Guide

## Overview

The **Botanical Haven Art Pipeline** is built on a decoupled, data-driven **Stable Asset ID** architecture. Artists can add, modify, or replace 2D sprites, animations, tiles, UI themes, VFX, SFX, and music without modifying a single line of GDScript gameplay code.

---

## 1. Directory Structure

All production assets belong in `res://assets/`:

```text
res://assets/
├── audio/
│   ├── music/           # Ambient, world, and seasonal background tracks (.ogg/.wav)
│   └── sfx/             # UI, farming, tools, and interaction sounds (.wav)
├── fonts/               # Pixel-art and UI typography (.ttf/.otf)
├── sprites/
│   ├── buildings/       # Greenhouse, houses, barn structures (.png)
│   ├── characters/      # Player animations and directional frames (.png)
│   ├── environment/     # Trees, rocks, debris, fences, flora (.png)
│   ├── items/           # Harvested crops, seeds, craftables (.png)
│   ├── npc/             # NPC idle, walk, work, eat, and portraits (.png)
│   ├── plants/          # Crop growth stages 0..3 (.png)
│   ├── tiles/           # Grass, tilled soil, watered soil, paths (.png)
│   ├── tools/           # Hoe, watering can, axe, pickaxe (basic..gold) (.png)
│   ├── ui/              # Icons, buttons, dialogue frames, HUD elements (.png)
│   └── vfx/             # Particle textures, sparkles, dust, splashes (.png)
└── data/assets/
    └── asset_manifest.json # Central Stable ID to physical file mapping
```

---

## 2. Stable Asset ID Conventions

Every asset in the game is resolved through a unique, dot-separated **Stable ID**:

| Category | Stable ID Format | Example |
|---|---|---|
| **Player Animation** | `character.player.<action>.<direction>` | `character.player.idle.down`, `character.player.walk.left` |
| **NPC Animation** | `npc.<npc_id>.<action>.<direction>.<frame>` | `npc.rowan.walk.down.0`, `npc.mira.work.left.1` |
| **NPC Portrait** | `npc.<npc_id>.portrait.<emotion>` | `npc.rowan.portrait.neutral`, `npc.rowan.portrait.happy` |
| **Crop Stages** | `plant.<crop_id>.<stage_index>` | `plant.red_flower.0`, `plant.red_flower.3` |
| **Tools** | `tool.<tool_id>.<quality>` | `tool.hoe_basic.icon`, `tool.hoe_gold.icon` |
| **Items** | `item.<item_id>` | `item.seed_red_flower`, `item.plant_red_flower` |
| **World Props** | `prop.<prop_name>` | `prop.tree.oak`, `prop.rock.small` |
| **Tiles** | `tile.<tile_name>.<variant>` | `tile.grass.0`, `tile.watered_soil.0` |
| **VFX** | `effect.<category>.<action>` | `effect.farming.plant`, `effect.farming.harvest` |
| **Audio SFX** | `audio.sfx.<category>.<name>` | `audio.sfx.farming.water`, `audio.sfx.ui.open` |

---

## 3. Artist Workflow: Adding or Swapping Art

```text
1. EXPORT ARTWORK
   └─ Save PNG/WAV files into the appropriate folder under res://assets/

2. UPDATE MANIFEST
   └─ Add or edit entries in res://data/assets/asset_manifest.json

3. RUN VALIDATOR
   └─ Execute AssetPipelineValidator.validate_all() to verify zero broken paths

4. IN-GAME REFRESH
   └─ Launch game; new artwork appears immediately with 0 gameplay script changes!
```

---

## 4. Automatic Missing Asset Fallback

If an asset is referenced before its artwork is finished, `AssetRegistry` automatically generates a safe colored placeholder texture with a visual identifier label. The game will **never crash** or render null textures.
