# In-Game Item, Crop, Tool & Economy Editor Guide (Phase 32)

Botanical Haven features an integrated, standalone In-Game Item, Crop, Tool & Economy Editor that allows developers, designers, and modders to configure game items, growth curves, tool parameters, shop prices, NPC gift preferences, and financial ROI models without modifying source code or base game files.

---

## 1. Architecture & Non-Destructive Modding

The Item, Crop, Tool & Economy Editor operates on the **Phase 27 Foundation & Mod Layer**:
- **Non-Destructive Overrides**: Changes are staged in memory and serialized to `user://editor_overrides.json` or active mod packages (`user://mods/<mod_id>/manifest.json`).
- **Base Game Data Protection**: Base JSON files in `res://data/` (`base_plants.json`, `tools.json`, `preferences.json`, `economy/`) remain strictly read-only.
- **Unified Shell Integration**: Mounted within `EditorShell`, accessible via `Main Menu -> Editor -> 🧰 Items`.

---

## 2. Interface Layout

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 🧰 Item, Crop, Tool & Economy Editor   [➕ New Entry] [📋 Dup] [🛡️ Safe Del] [▶️ Play] │
├───────────────┬─────────────────────────────────────────────────────────┬──────────────┤
│ Mode: [Items] │  Visual Preview & Lifecycle Pipeline                    │ Properties   │
│ [Search...  ] │  [Icon] Red Flower Plant                                │ Crop/Tool    │
│ [All Types ▼] │  Buy: 25g | Sell: 50g | Rarity: Common                  │ NPC Gifts    │
│ ● red_flower  ├─────────────────────────────────────────────────────────┤ Used By      │
│   blue_flower │  📊 Economy & Crop ROI Calculator                       ├──────────────┤
│   sunflower   │  Seed: 20g | Harvest: 50g | Net: +30g | ROI: 150%       │ Price: 50g   │
│   hoe_basic   │  Profit / Energy: 4.0                                   │ Stack: 99    │
│   axe_copper  ├─────────────────────────────────────────────────────────┤ Rarity: Comm │
│   ...         │  Used By:                                               │              │
│               │  📜 Quest: First Seeds | 👤 Rowan Loved Gift            │ Rowan: Loved │
├───────────────┴─────────────────────────────────────────────────────────┴──────────────┤
│ Item: plant_red_flower  |  Changes: 0  |  Validation: OK                                │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Core Modules & Features

### 3.1 Mode Switcher & Catalog Browser
- Switch effortlessly between **📦 Items**, **🌱 Crops**, **🔨 Tools**, and **💰 Economy**.
- Catalog search with real-time text and category filtering (`Crop`, `Seed`, `Tool`, `Material`, `Forage`, `Quest`, `Special`).

### 3.2 Crop Growth & Lifecycle Editor
- Configure growth stages (Stage 0 -> Stage 1 -> Stage 2 -> Harvestable).
- Edit days per stage (e.g. `[1.0, 1.0, 2.0]`), watering requirements, and harvest yield ranges.

### 3.3 Tool Upgrade Chains & Energy Costs
- Tool types: `Hoe`, `Watering Can`, `Axe`, `Pickaxe`.
- Quality tiers: `Basic`, `Copper`, `Iron`, `Gold`.
- Configure power, energy costs, and grid interaction ranges.

### 3.4 Economy & ROI Analytics Simulator
- Real-time calculator evaluates:
  - **Net Profit**: \( \text{Harvest Value} - \text{Seed Cost} \)
  - **ROI %**: \( \frac{\text{Net Profit}}{\text{Seed Cost}} \times 100 \)
  - **Energy Efficiency**: Net profit per energy point invested.

### 3.5 NPC Gift Preference Matrix
- Configure sentiment for each town NPC (`Loved`, `Liked`, `Neutral`, `Disliked`, `Hated`).
- Directly synchronized with `EditorDataService` social data.

### 3.6 Cross-Editor References & Safe Delete
- Shows all gameplay systems referencing the active item (Quests, Dialogues, NPC preferences).
- **🛡️ Safe Delete**: Protects against breaking referenced quests or shops.
- One-click navigation to **📜 Quest Editor**, **💬 Dialogue Editor**, and **👤 NPC Editor**.
