# Phase 16.5 — Smooth Stardew-like Player Movement

## Problem and root cause

`PlayerMovement` already used continuous `CharacterBody2D` physics (`Input.get_vector`, normalized diagonal input, acceleration/friction, and `move_and_slide`). The remaining grid coupling was in `Player`: every derived grid-cell change was treated as a completed movement. That path forced the animation back to idle and wrote a `Vector2i` grid coordinate into player state. Tool-range checks also used grid coordinates directly.

## Refactor

- Physical player and saved state positions are now continuous world-space `Vector2` values.
- `grid_position` remains a derived `Vector2i`, used only for tile targeting, tile events, and transition trigger lookup.
- Crossing a tile now calls `_on_grid_position_changed`; it does not reset animation or reposition the player.
- Movement retains normalized eight-direction input, 85 px/s walk speed, acceleration 850 px/s², friction 1100 px/s², collision via `move_and_slide`, and world-bound clamping.
- Walk/idle state now comes directly from continuous velocity. Facing is retained after stopping.

## Interaction, collision, camera, and tools

- Tool range now measures the continuous player world position to the target tile centre, while preserving the former two-tile diagonal reach envelope.
- Target selection, farming, world-builder tiles, and transitions continue to consume `Vector2i` grid targets.
- Existing `CharacterBody2D` collision layers/masks and Camera2D node were retained unchanged.
- World transitions still use grid spawn data, converting it to a world-space spawn position without ordinary movement snapping.

## Multiplayer and save/load

- The existing 20 Hz network publisher already sends continuous world-space `position.x/y`; remote players retain interpolation through `NetworkPlayer.target_position`.
- Network session identities still use grid coordinates only for initial spawn compatibility; they are derived from continuous local state.
- `PlayerState.position` now serializes continuous world coordinates with `position_space: "world"`.
- Legacy saves without that marker are migrated from grid cells to tile-centre world coordinates.
- The legacy top-level save player position is likewise read as grid data unless marked world-space.

## Validation

- `script_validate --all`: **129 passed, 0 failed**.
- Runtime diagonal-input check: position moved continuously from `(264, 200)` to `(506, 378)` while both right and down were held.
- Releasing input reduced velocity to `(0, 0)` with no snap.
- Runtime error buffer: **0 errors**.

## Remaining validation scope

The local continuous-movement, animation state, and stop behavior were exercised at runtime. Multiplayer peer-to-peer and full tool/save/world-transition scenarios should be smoke-tested manually in their respective gameplay flows before release, as they require configured sessions and save fixtures.
