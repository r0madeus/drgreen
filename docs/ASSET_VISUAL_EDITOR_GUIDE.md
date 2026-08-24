# Botanical Haven — In-Game Asset & Visual Content Editor Guide
**Phase 35 — In-Game Asset & Visual Content Management Pipeline**

---

## 1. Overview & Architecture

The **In-Game Asset & Visual Content Editor** provides developers and modders with an integrated visual authoring environment directly inside Botanical Haven. Game creators and modders can browse, preview, inspect, customize, swap, and package visual assets without opening the Godot Editor or touching raw project files.

### Architectural Pillars
- **Zero Raw File Mutation**: Base game assets located in `res://` are **never** modified. All edits are staged in memory via `EditorDataService` and saved into `user://editor_overrides.json` or exported into `.bhmod` packages.
- **Stable ID Mapping**: Visual assets are identified and swapped using stable dot-notated identifiers (e.g., `npc.rowan.idle.down.0`, `crop.red_flower.stage_1`, `item.fertilizer`, `tile.grass`).
- **Dynamic Manifest Resolution**: Visual definitions are cataloged in `res://core/asset_manifest.json` and dynamically loaded and extended by `AssetRegistry`.
- **Procedural & Fallback Safeguards**: Missing or invalid assets automatically generate graceful, colored fallback placeholder textures, preventing engine crashes.

---

## 2. 3-Zone Editor Interface

The Asset Editor panel features a responsive 3-zone layout:

```
+---------------------+-------------------------------+-------------------------+
|    LEFT ZONE        |         CENTER ZONE           |       RIGHT ZONE        |
|  Category Browser   |     High-Res Preview          |    Tabbed Inspector     |
|  Search & Filters   |     Checkerboard Canvas       | [General] [Visual]      |
|  Asset Catalog      |     Playback & Step Controls  | [Animation] [Metadata]  |
|  Missing Assets     |     4-Direction NPC Buttons   | Actions: Apply / Revert |
+---------------------+-------------------------------+-------------------------+
```

### Left Zone: Catalog, Search & Filters
- **Category Tree / List**: 16 standard categories (`player`, `npc`, `npc_portrait`, `npc_animation`, `crops`, `items`, `seeds`, `tools`, `tiles`, `props`, `buildings`, `vfx`, `ui`, `sfx`, `music`, `ambience`) plus dynamic categories loaded from manifest extensions.
- **Real-Time Search**: Instant filtering by asset ID or tag substring.
- **Triage Filters**:
  - **Modified**: Displays only assets with active overrides.
  - **Missing**: Displays broken or missing asset references.
  - **★ Favs**: Filters by starred/favorited assets for rapid access.
- **Missing Assets Section**: Dedicated list highlighting unmapped or missing textures with quick-fix options.

### Center Zone: Preview & Animation Workspace
- **High-Res Canvas**: Nearest-neighbor pixel-art rendering over a dark checkerboard background.
- **Zoom Controls**: `-` (zoom out), `+` (zoom in), and `Fit` (reset to 200%).
- **Animation Playback**: `▶ Play` / `⏸ Pause` toggle, frame stepping (`◀`, `▶`), and dynamic frame counter (`Frame X/Y`).
- **4-Directional NPC Preview**: Instant directional preview (`▲ Up`, `◀ Left`, `▼ Down`, `▶ Right`) for character sprites.
- **Test In Game**: Live playtesting trigger with the staged asset active.

### Right Zone: Tabbed Property Inspector
- **[General] Tab**:
  - Stable ID display
  - Category selector
  - Display Name & Description fields
  - File path & Source status badge (`Base Game` vs. `Overridden / Mod`)
  - Favorite toggle & Asset reset
- **[Visual] Tab**:
  - Texture path override field
  - Dimensions (`W` and `H` spinboxes)
  - Scale multiplier (0.1x to 10.0x)
  - Offset (`X` and `Y` pixel shifts)
  - Flip Horizontal (`Flip H`) & Flip Vertical (`Flip V`)
  - Texture Filter Mode (`Nearest` for pixel art, `Linear` for smooth)
  - Modulate Tint (Color picker)
  - Cross-Editor Quick Actions: Open NPC Editor, Open Item Editor, Open Crop Editor, Open Tool Editor, Place in World
- **[Animation] Tab**:
  - Character state animation selector (`idle`, `walk`, `work`, `eat`, `rest`, `sit`, `sleep`, `talk`)
  - Sprite sheet matrix (`Columns` and `Rows`)
  - Playback FPS (1 to 60)
  - Loop toggle
  - Playback mode (`forward`, `backward`, `ping_pong`)
- **[Metadata] Tab**:
  - Asset type (`sprite`, `tileset`, `audio`, etc.)
  - Comma-separated tag editor
  - Dependency Graph ("Used By" entity references)
  - Safety warning indicator

---

## 3. Workflow Examples

### Workflow 1: Replacing an NPC Sprite
1. Open the In-Game Editor (`F12` or Editor button in Main Menu).
2. Select **🎨 Assets** from the left navigation bar.
3. In Categories, select **NPC** or search for `npc.rowan`.
4. Click on `npc.rowan` in the asset catalog.
5. In the Center Zone, test the 4 directions (`▲`, `◀`, `▼`, `▶`) and click `▶ Play` to review walking frames.
6. In the Right Zone **[Visual]** tab, update `Texture Path` or toggle `Flip H`.
7. Click **💾 Apply / Save** to stage the modification.

### Workflow 2: Creating a Custom Mod Pack (.bhmod)
1. Modify crops, NPC outfits, and item textures in the Asset Editor.
2. In the Top Toolbar, click **🔍 Validate Assets** to ensure zero missing textures or duplicate IDs.
3. Switch to the **📦 Mods** panel in EditorShell.
4. Click **Create Mod**, name it `my_texture_pack`, and click **Export Mod**.
5. The resulting `.bhmod` package can be shared and imported by any player.

---

## 4. Troubleshooting & Fallbacks

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| **Pink/Purple checkerboard on asset** | Texture path does not exist in project or mod folder. | Check `Missing Assets` list in Asset Editor; enter a valid path or restore default. |
| **Animation plays too fast/slow** | FPS metadata set incorrectly. | Open `[Animation]` tab, adjust `Playback FPS`, and click `Save Animation Override`. |
| **Overrides not appearing in gameplay** | Changes staged but not saved to disk. | Click `Apply / Save` in inspector or `Save Changes` in Editor toolbar. |
| **Want to revert changes** | Modifications need to be reset. | Click `↺ Reset This Asset` or `↺ Reset Category` in toolbar. |
