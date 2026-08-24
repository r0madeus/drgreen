# Botanical Haven — Complete In-Game Content Authoring & Mod Creation Guide
## A Comprehensive Manual for Creators & Modders (Phase 36)

Welcome to the **In-Game Content Authoring Suite** of Botanical Haven!
With this toolset, you can build complete game expansions, custom NPCs, brand new maps, items, crops, branching dialogues, and quests **entirely inside the game runtime without opening the Godot Engine Editor**.

---

## Table of Contents
1. [Overview & Core Philosophy](#1-overview--core-philosophy)
2. [Step 1: Creating a Mod Workspace](#step-1-creating-a-mod-workspace)
3. [Step 2: Importing Custom Visual Assets](#step-2-importing-custom-visual-assets)
4. [Step 3: Creating Items, Crops & Tools](#step-3-creating-items-crops--tools)
5. [Step 4: Creating NPCs, Schedules & Social Preferences](#step-4-creating-npcs-schedules--social-preferences)
6. [Step 5: Creating New Worlds & Placing NPCs](#step-5-creating-new-worlds--placing-npcs)
7. [Step 6: Creating Branching Dialogue Trees](#step-6-creating-branching-dialogue-trees)
8. [Step 7: Creating Quests & Reward Pipelines](#step-7-creating-quests--reward-pipelines)
9. [Step 8: Cross-Editor Navigation & Project Hierarchy](#step-8-cross-editor-navigation--project-hierarchy)
10. [Step 9: Global Validation & Error Diagnostics](#step-9-global-validation--error-diagnostics)
11. [Step 10: In-Game Playtest Simulation](#step-10-in-game-playtest-simulation)
12. [Step 11: Exporting & Distributing `.bhmod` Packages](#step-11-exporting--distributing-bhmod-packages)
13. [Step 12: Installing & Deactivating Mods](#step-12-installing--deactivating-mods)

---

## 1. Overview & Core Philosophy

### Non-Destructive Layering Architecture
- **Base Game Layer (`res://`):** Always read-only. Vanilla files are never mutated.
- **User Mod Layer (`user://`):** All new assets, worlds, entities, and overrides are stored in `user://imported_assets/`, `user://editor_overrides.json`, or packaged into portable `.bhmod` zip archives.
- **Disaster Recovery:** Automatic timestamps and `.tmp` atomic saving protect against file corruption.

---

## 2. Step 1: Creating a Mod Workspace

1. Open the In-Game Editor via `F12` or Main Menu.
2. Select **📦 Mod Manager** in the left navigation sidebar.
3. Click **➕ Create Mod**.
4. Fill in the Mod Metadata:
   - **Mod Name:** `Moonlit Garden Mod`
   - **Mod ID:** `moonlit_garden` (auto-slugged to lowercase snake_case)
   - **Author:** `Your Name`
   - **Version:** `1.0.0`
   - **Description:** `A mysterious hidden sanctuary with new flora and characters.`
5. Click **Create & Activate**. Your active authoring session is now linked to this mod.

---

## 3. Step 2: Importing Custom Visual Assets

1. Navigate to **🎨 Assets** panel.
2. Click **📥 Import Asset**.
3. Select your `.png`, `.jpg`, or `.webp` file from disk.
4. Set the stable ID: e.g. `item.moon_flower_icon`, `crop.moon_flower_seed`, `tile.moon_grass`.
5. The texture is copied into `user://imported_assets/` and registered into `AssetRegistry` instantly without game restart.

---

## 4. Step 3: Creating Items, Crops & Tools

1. Navigate to **🎒 Items / 🌱 Crops / 🔨 Tools** panel.
2. **To create an Item:**
   - Click **➕ New Item**.
   - Set ID: `moon_flower`, Display Name: `Moon Flower`, Sell Price: `150`, Icon: `item.moon_flower_icon`.
3. **To create a Crop:**
   - Switch to **Crops** tab, click **➕ New Crop**.
   - Set ID: `moon_flower_seed`, Growth Duration: `3 days`, Harvest Yield: `item.moon_flower`.
   - The corresponding seed item (`item.seed_moon_flower_seed`) is automatically generated!
4. **To create a Tool:**
   - Switch to **Tools** tab, click **➕ New Tool**.
   - Set Power: `2`, Energy Cost: `1`.

---

## 5. Step 4: Creating NPCs, Schedules & Social Preferences

1. Navigate to **👤 NPCs** panel.
2. Click **➕ Create NPC**.
3. Fill in:
   - **ID:** `elara`
   - **Display Name:** `Elara`
   - **Role:** `botanist`
   - **Default World:** `moonlit_garden`
4. Configure Schedule in the **Schedule Timeline** tab (e.g. 08:00 home, 12:00 garden, 18:00 home).
5. Set Gift Preferences in the **Social** tab.

---

## 6. Step 5: Creating New Worlds & Placing NPCs

1. Navigate to **🌍 World** panel.
2. Click **➕ New World**.
3. Set World ID: `moonlit_garden`, Width: `32`, Height: `24`, Background: `grass` or `tile.moon_grass`.
4. The world canvas opens immediately:
   - Use mouse brushes to paint ground tiles, water, paths, and props.
5. **Place NPC:**
   - In the palette/tool bar, select **Place NPC**.
   - Click on the canvas at `(16, 10)` to place Elara's spawn location.
   - Her spawn coordinate is saved directly to `world.moonlit_garden`.

---

## 7. Step 6: Creating Branching Dialogue Trees

1. Navigate to **💬 Dialogue** panel.
2. Click **➕ Create Dialogue**.
3. Set Owner NPC: `elara`.
4. In the visual node graph:
   - Set Start Line: `"Welcome to the Moonlit Garden! Please grow a Moon Flower for my research."`
   - Add Action: `start_quest:the_moonlit_garden`.
5. Test playback immediately using **▶ Play Dialogue Simulator**.

---

## 8. Step 7: Creating Quests & Reward Pipelines

1. Navigate to **📜 Quests** panel.
2. Click **➕ Create Quest**.
3. Set Title: `The Moonlit Garden`, Giver: `Elara`.
4. Add Objective:
   - Type: `harvest`
   - Target: `item.moon_flower`
   - Amount: `1`
5. Add Rewards:
   - Gold: `200`
   - Unlocks: `world.moonlit_garden`

---

## 9. Step 8: Cross-Editor Navigation & Project Hierarchy

- Every panel includes instant cross-editor jump buttons:
  - From NPC Editor -> **Open World Editor**, **Edit Schedule**, **Edit Dialogue**, **Edit Quests**.
  - From Quest Editor -> **Open Giver NPC**, **Open Quest Dialogue**.
  - From World Editor -> Click NPC -> **Open NPC Editor**.
- Call **Project Outline** to view all entities in your mod in an organized tree.

---

## 10. Step 9: Global Validation & Error Diagnostics

1. Click **🔍 Validate** in the top navigation bar.
2. The validator verifies:
   - Duplicate IDs
   - Broken item/crop/quest/dialogue references
   - Missing textures
   - Disconnected dialogue branches
3. Click any reported error to jump directly to the offending entity.

---

## 11. Step 10: In-Game Playtest Simulation

1. Click **▶ Test In Game** or press `F5`.
2. The editor automatically invokes `apply_to_gameplay_managers()`, pushing all new entities into live singletons.
3. Walk around the new world, talk to Elara, accept the quest, grow the flower, turn in the quest, and receive gold.
4. Press `F12` to return to the editor without losing state.

---

## 12. Step 11: Exporting & Distributing `.bhmod` Packages

1. Open **📦 Mod Manager**.
2. Select your mod `moonlit_garden`.
3. Click **📦 Export Mod (.bhmod)**.
4. Your complete mod is packaged into `user://mods/moonlit_garden.bhmod`.
5. Share this single file with other players!

---

## 13. Step 12: Installing & Deactivating Mods

- **Installing:** Place any `.bhmod` into `user://mods/` or click **Import Mod** in Mod Manager.
- **Disabling:** Uncheck or disable the mod in Mod Manager. All mod entities disappear instantly, restoring the clean vanilla base game with zero side effects.
