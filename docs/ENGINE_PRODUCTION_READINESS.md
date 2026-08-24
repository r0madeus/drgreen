# Botanical Haven Engine — Production Readiness & Architecture Specification (Phase 43)

## 1. Engine vs GamePackage Isolation

```
                               ┌──────────────────────────┐
                               │  BOTANICAL HAVEN ENGINE  │
                               └────────────┬─────────────┘
                                            │
        ┌───────────────────────────────────┼───────────────────────────────────┐
        ▼                                   ▼                                   ▼
 [ Core Runtime ]                  [ Gameplay Infra ]                  [ Editor Infra ]
 • Component Framework             • Generic Event Bus                 • In-Game Studio
 • Entity Query Engine             • Safe Expression Evaluator         • Component Builder
 • Save/Load Infra                 • Mechanic Graph Engine             • Mechanic Graph Panel
 • Network Synchronizer            • State Machine Engine              • Mod Manager
        │                                   │                                   │
        └───────────────────────────────────┼───────────────────────────────────┘
                                            │
                                            ▼
                               ┌──────────────────────────┐
                               │     CONTENT PACKAGES     │
                               └────────────┬─────────────┘
                                            │
        ┌───────────────────────────────────┼───────────────────────────────────┐
        ▼                                   ▼                                   ▼
[ Botanical Haven (Official) ]      [ Dungeon Crawler ]                 [ Custom User Mods ]
• Farming, Crops, Tools             • Combat, Loot, Keys                • Overrides & Expansions
• NPCs, Quests, Dialogues           • Traps, Secret Doors               • Custom Building Blocks
```

---

## 2. Error Recovery & Graceful Fallback Patterns

1. **Corrupted Save Data:** If an entity or custom component fails deserialization, `EngineCompatibilityService` records a diagnostic and restores default properties without crashing the game loop.
2. **Missing Asset:** Unresolved asset IDs fallback cleanly to `res://icon.svg`.
3. **Missing Localization:** Unresolved localization keys return the key or fallback text.
4. **Missing Mod Dependency:** Mods with missing or conflicting dependencies are safely flagged and disabled before execution.
5. **Clean Unload:** Unloading a mod purges its custom components and mechanic listeners without stale references.
