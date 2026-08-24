class_name GameplaySimulator
extends RefCounted

## Sandboxed Dry-Run Simulation Engine for Gameplay Rules (Phase 39).
## Allows game designers and modders to test trigger events, condition trees, and action chains
## without altering runtime state or corrupting live save files.

const COND_SCRIPT = preload("res://core/gameplay/gameplay_condition.gd")
const ACT_SCRIPT = preload("res://core/gameplay/gameplay_action.gd")
const TRIG_SCRIPT = preload("res://core/gameplay/gameplay_trigger.gd")

static func simulate(trigger_data: Dictionary, mock_event: Dictionary, mock_context: Dictionary) -> Dictionary:
	var trace: Array[String] = []
	var sandbox_ctx = mock_context.duplicate(true)
	
	trace.append("▶ Starting Simulation for Trigger '%s'" % str(trigger_data.get("id", trigger_data.get("trigger_id", "sim_trig"))))
	
	# 1. Event Type Match
	var trig_evt = str(trigger_data.get("event_type", trigger_data.get("event", "")))
	var incoming_evt = str(mock_event.get("event_type", mock_event.get("type", "")))
	
	var event_matched = true
	if trig_evt != "" and trig_evt != "all" and trig_evt != "*":
		if incoming_evt != trig_evt:
			event_matched = false
			trace.append("❌ Event mismatch: incoming '%s' != trigger '%s'" % [incoming_evt, trig_evt])
		else:
			trace.append("✓ Event matched: '%s'" % incoming_evt)
	else:
		trace.append("✓ Wildcard event match: '%s'" % incoming_evt)
		
	if not event_matched:
		return {
			"success": false,
			"event_matched": false,
			"condition_passed": false,
			"projected_actions": [],
			"resulting_context": sandbox_ctx,
			"trace": trace
		}

	# 2. Condition Evaluation
	sandbox_ctx["event"] = mock_event
	var cond_data = trigger_data.get("condition", {})
	var condition_passed = COND_SCRIPT.evaluate(cond_data, sandbox_ctx)
	
	if condition_passed:
		trace.append("✓ Condition evaluation PASSED")
	else:
		trace.append("❌ Condition evaluation FAILED")
		return {
			"success": false,
			"event_matched": true,
			"condition_passed": false,
			"projected_actions": [],
			"resulting_context": sandbox_ctx,
			"trace": trace
		}

	# 3. Action Sequence Execution
	var raw_actions = trigger_data.get("actions", [])
	var projected_actions: Array[Dictionary] = []
	
	if raw_actions is Array:
		trace.append("⚡ Executing %d actions..." % raw_actions.size())
		projected_actions = ACT_SCRIPT.execute_sequence(raw_actions, sandbox_ctx)
		for act_res in projected_actions:
			trace.append("  ➜ %s" % str(act_res.get("output", "Action executed")))
			
	trace.append("✓ Simulation completed successfully.")
	
	return {
		"success": true,
		"event_matched": true,
		"condition_passed": true,
		"projected_actions": projected_actions,
		"resulting_context": sandbox_ctx,
		"trace": trace
	}
