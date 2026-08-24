# Gameplay Engine Invariants

## Core Principles

The Botanical Haven Engine relies on these strict invariants. ANY violation of these rules is considered a P0 or P1 bug and must block release.

### 1. State Immutability & Serialization
- **Invariant**: `ComponentState` -> `Serialize` -> `Deserialize` -> `ComponentState` must result in an exact identical state object. No data loss is permitted.
- **Invariant**: Saving a world with N entities must load a world with exactly N entities.

### 2. Time & Determinism
- **Invariant**: Advancing time by `Delta T` 100 times must produce the identical resulting world state as advancing time by `100 * Delta T` once, assuming no external inputs.
- **Invariant**: Crops, NPC positions, and weather must correctly evaluate their target states if skipped ahead (offline progression).

### 3. Resource & Entity Management
- **Invariant**: World transitions must clean up 100% of the previous world's entities. `Orphan Node` count should remain flat across transitions.
- **Invariant**: Inventories can never "lose" an item due to a failed transfer or full target inventory. Items must remain at their source if transfer fails.

### 4. Custom Execution Safety
- **Invariant**: The `SafeExpressionEvaluator` must NEVER throw a hard exception or crash the engine, regardless of how malformed the input data is.
- **Invariant**: A missing Custom Component Definition must default to a safe mock state, not crash the loading sequence.
