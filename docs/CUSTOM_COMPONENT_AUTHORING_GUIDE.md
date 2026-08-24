# Botanical Haven — Custom Component Authoring Guide (Phase 42)
## Creating Custom Data Schemas and Property Constraints In-Game

In Phase 42, creators can define entirely new components with custom properties, types, default values, and range constraints directly within Game Studio.

---

## 1. Defining a Custom Component in Game Studio

Navigate to **Game Studio ➔ 🧩 Components ➔ + New Component**:

- **Component ID:** `hunger`
- **Display Name:** `Hunger`
- **Category:** `Survival`
- **Description:** `Tracks entity hunger and starvation status.`

### Adding Properties
1. `current` — `float` (default: 100.0, min: 0.0, max: 100.0, required: true)
2. `maximum` — `float` (default: 100.0, min: 10.0, max: 200.0)
3. `drain_rate` — `float` (default: 1.0)
4. `enabled` — `bool` (default: true)

---

## 2. Dynamic Registration & Capability Mapping

Custom components are dynamically registered into `ComponentRegistry`:
```gdscript
var hunger_def = CustomComponentDefinition.new("hunger", "Hunger", "Survival")
hunger_def.add_property("current", "float", 100.0)
hunger_def.capabilities.append("survival")
ComponentRegistry.register_custom_component(hunger_def)
```
