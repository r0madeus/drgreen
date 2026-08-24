# Botanical Haven — Custom Definition Schema Specification (Phase 42)
## JSON Schema for GamePackage and .bhmod Custom Content

```json
{
  "schema_version": 1,
  "custom_components": [
    {
      "component_id": "hunger",
      "name": "Hunger",
      "category": "Survival",
      "description": "Tracks player hunger",
      "capabilities": ["survival"],
      "properties": {
        "current": { "type": "float", "default": 100.0, "min": 0.0, "max": 100.0 },
        "maximum": { "type": "float", "default": 100.0, "min": 10.0, "max": 200.0 },
        "drain_rate": { "type": "float", "default": 1.0 }
      }
    }
  ],
  "custom_mechanics": [
    {
      "mechanic_id": "hunger_loop",
      "name": "Hunger Loop",
      "trigger_event": "hunger.changed",
      "nodes": [
        {
          "type": "condition",
          "expression": { "left": "component.hunger.current", "op": "<=", "right": 25.0 },
          "if_true": [{ "type": "transition_state", "state": "hungry" }]
        }
      ]
    }
  ]
}
```
