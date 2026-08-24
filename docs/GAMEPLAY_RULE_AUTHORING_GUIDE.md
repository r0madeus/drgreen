# Botanical Haven — Gameplay Rule Authoring Guide
## Creating Custom Gameplay Triggers & Action Chains

This guide explains how to define, test, and package custom gameplay mechanics using the In-Game Editor and JSON rule schemas.

---

## 1. Defining a Trigger in JSON

```json
{
  "id": "ancient_chest_unlock",
  "name": "Ancient Chest Unlock",
  "event_type": "interact_chest",
  "priority": 100,
  "cooldown": 0.0,
  "once": true,
  "condition": {
    "all": [
      { "path": "inventory.dungeon_key", "op": ">=", "value": 1 },
      { "path": "flags.chest_opened", "op": "==", "value": false }
    ]
  },
  "actions": [
    { "type": "remove_item", "item_id": "dungeon_key", "count": 1 },
    { "type": "add_item", "item_id": "legendary_sword", "count": 1 },
    { "type": "add_gold", "amount": 500 },
    { "type": "set_flag", "flag": "chest_opened", "value": true },
    { "type": "show_message", "text": "You unlocked the Ancient Chest!" }
  ]
}
```

---

## 2. Live Simulator Workflow

1. Open **EditorShell** -> Select the **⚡ Rules** panel.
2. Select your trigger from the list or create a new one.
3. Switch to the **▶ Live Simulator** tab.
4. Input a mock event type (e.g. `interact_chest`) and mock context:
   ```json
   {
     "gold": 50,
     "inventory": { "dungeon_key": 1 },
     "flags": { "chest_opened": false }
   }
   ```
5. Click **▶ Run Dry-Run Simulation**.
6. Inspect the colored trace log to verify condition passes/fails and projected action results!
