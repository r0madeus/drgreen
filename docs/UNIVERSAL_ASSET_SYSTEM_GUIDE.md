# Universal Asset System Guide

The Universal Asset System separates base Asset Definitions (components like Visual, Collision, Interaction) from World Instances (position, layer, overrides).

## 1. Asset Definition vs Instance
- **Definition**: Resides in es://data/assets/definitions.json. Contains base behaviors.
- **Instance**: Resides in world.json under objects. Contains an sset_id and any properties that override the definition.

## 2. Components
The generic system leverages the following standard components:
- identity: type, display_name, tags
- isual: sprite, offset, animation
- collision: solid, shapes
- 
avigation: walkable, movement_cost
- lighting: emits_light, light_color, light_radius
- interaction: type, range
- placement: allowed_terrain, grid_alignment

## 3. Resolving Properties at Runtime
The AssetDefinitionManager resolves an instance's properties automatically:
`gdscript
var overrides = object_instance.get("properties", {})
var asset_id = object_instance.get("asset_id", "")
var props = AssetDefinitionManager.resolve_instance_properties(asset_id, overrides)
`
These properties are dynamically merged and read by the GridManager, WorldLoader, and WorldValidator.

## 4. World Editor Integration
- The World Editor Inspector highlights overrides in yellow.
- World Canvas natively supports debug visualizations for Collision (Red), Walkability (Green), and Lighting (Yellow arcs) to visually verify Asset behaviors.
