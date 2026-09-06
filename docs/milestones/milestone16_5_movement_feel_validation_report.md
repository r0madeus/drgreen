# Phase 16.5 — Movement Feel & Gameplay Smoke Test

## Scope

This validation inspected the existing smooth-movement refactor and tested the running game without replacing its movement system.

## Runtime scenarios exercised

- WASD and arrow-key movement were both injected into the live game.
- Eight-direction input was exercised. Diagonal velocity was `(60.104, 60.104)`, whose magnitude is `85 px/s`: equal to normal walk speed, so it is normalized.
- Hold/release behavior, acceleration/friction stop behavior, direction changes, idle/walk transitions, facing direction, and Camera2D following were observed.
- At rest after a raw key sequence, the player was at `(481.4307, 353.4307)` with velocity `(0, 0)`, grid coordinate `(30, 22)`, up-facing idle animation, and camera at the same world position. This physical position is not a tile centre (`(488, 360)`), proving ordinary movement is not snapped to grid centres.
- World bounds were reached at physical clamp coordinates such as `(506, 378)`; this is the intentional map boundary clamp, not a grid snap.
- A live transition occurred during travel; the active world became `town`, whose two transition trigger definitions were present and remained grid-based as intended.
- Tool target/range resolution was checked through the live `PlayerInteraction` component. The player remains continuous while target cells are `Vector2i`.

## Save/load and multiplayer checks

- `PlayerState.from_dict({ position: [12, 7] })` migrated the legacy grid position to world-space `(200, 120)` (tile centre).
- A world-space save position `(201.25, 118.75)` with `position_space: "world"` was preserved exactly.
- A temporary `NetworkPlayer` was updated from `(100, 100)` to target `(200, 100)`. One interpolation step yielded `(136, 100)`, confirming the existing remote smoothing path. The 20 Hz network replication design was not changed.

## Small correction made

`Player.get_state()` previously exposed only the derived grid coordinate as `position`, which made diagnostics ambiguous. It now reports continuous world-space `position`, derived `grid_position`, and `velocity`. No movement algorithm, speed, acceleration, collision, networking, or world-builder behavior was changed.

## Findings

No normal-gameplay grid snapping was found. Player physics stays in continuous `Vector2` space; `Vector2i` is used only for gameplay target cells, tile events, and transition lookup. The retained acceleration and friction feel controlled rather than slippery, while diagonal motion is speed-normalized.

## Final validation

- `script_validate --all`: **129 passed, 0 failed**.
- `scene_validate` on `res://scenes/main.tscn`: **0 issues**.
- `runtime_errors`: **0 errors**.

## Remaining manual coverage

The actual multiplayer host/client session, every tool animation, and a persistent-disk save/load cycle need configured peer/save fixtures for full end-to-end manual coverage. Static integration and runtime component smoke checks found no regression in those paths.
