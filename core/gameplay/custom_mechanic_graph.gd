class_name CustomMechanicGraph
extends RefCounted

## Declarative Gameplay Mechanic Graph & Action Sequence Runner (Phase 42 & 43).
## Wires Events -> Conditions -> Action Chains -> State Transitions -> Chained Events.

const EXPR_SCRIPT = preload("res://core/gameplay/safe_expression_evaluator.gd")
const FACTORY_SCRIPT = preload("res://core/components/component_factory.gd")

var mechanic_id: String = ""
var name: String = ""
var description: String = ""
var trigger_event: String = ""
var nodes: Array[Dictionary] = []

func _init(p_id: String = "", p_name: String = "", p_event: String = "") -> void:
	mechanic_id = p_id if p_id != "" else "mech_%d" % int(Time.get_unix_time_from_system())
	name = p_name if p_name != "" else mechanic_id.capitalize()
	trigger_event = p_event

func add_node(node_dict: Dictionary) -> void:
	nodes.append(node_dict.duplicate(true))

func execute(context: Dictionary) -> Dictionary:
	var trace: Array[String] = []
	var success_count = 0
	
	trace.append("▶ Executing Mechanic Graph '%s'" % name)
	
	for node in nodes:
		var ntype = str(node.get("type", "")).to_lower()
		
		if ntype == "condition":
			var expr = node.get("expression", node.get("condition", {}))
			var passed = EXPR_SCRIPT.evaluate(expr, context)
			trace.append("  Condition '%s' -> %s" % [str(expr), "PASSED" if passed else "FAILED"])
			if passed:
				var if_true = node.get("if_true", [])
				if if_true is Array and not if_true.is_empty():
					_execute_action_list(if_true, context, trace)
					success_count += 1
			else:
				var if_false = node.get("if_false", [])
				if if_false is Array and not if_false.is_empty():
					_execute_action_list(if_false, context, trace)
					success_count += 1
				if bool(node.get("stop_on_fail", false)):
					return { "success": true, "stopped": true, "reason": "Condition failed", "trace": trace }
		else:
			_execute_single_action(node, context, trace)
			success_count += 1

	return { "success": true, "success_count": success_count, "trace": trace }

func _execute_action_list(actions: Array, context: Dictionary, trace: Array[String]) -> void:
	for act in actions:
		if act is Dictionary:
			_execute_single_action(act, context, trace)

func _execute_single_action(node: Dictionary, context: Dictionary, trace: Array[String]) -> void:
	var atype = str(node.get("type", "")).to_lower()
	match atype:
		"set_property", "set":
			var path = str(node.get("path", ""))
			var val = node.get("value", null)
			_set_context_path(context, path, val)
			trace.append("  Set '%s' = %s" % [path, str(val)])
			
		"modify_property", "add_property", "modify":
			var path = str(node.get("path", ""))
			var delta = float(node.get("delta", node.get("amount", 1.0)))
			var cur = float(EXPR_SCRIPT.resolve_value(path, context) if EXPR_SCRIPT.resolve_value(path, context) != null else 0.0)
			_set_context_path(context, path, cur + delta)
			trace.append("  Modified '%s' to %.1f" % [path, cur + delta])
			
		"transition_state", "set_state":
			var st = str(node.get("state", "active"))
			if not context.has("state_machine"): context["state_machine"] = { "current_state": "idle" }
			FACTORY_SCRIPT.transition_state(context["state_machine"], st)
			trace.append("  State transitioned to '%s'" % st)
			
		"damage_entity", "damage":
			var amt = float(node.get("amount", node.get("damage", 10.0)))
			if not context.has("health"): context["health"] = { "current_health": 100.0 }
			var hres = FACTORY_SCRIPT.apply_damage(context["health"], amt)
			trace.append("  Damaged entity by %.1f (New health: %.1f)" % [amt, hres.get("new_health", 0.0)])
			
		"heal_entity", "heal":
			var amt = float(node.get("amount", node.get("heal", 10.0)))
			if not context.has("health"): context["health"] = { "current_health": 100.0 }
			var hres = FACTORY_SCRIPT.apply_heal(context["health"], amt)
			trace.append("  Healed entity by %.1f (New health: %.1f)" % [amt, hres.get("new_health", 0.0)])
			
		"emit_event":
			var evt_name = str(node.get("event", ""))
			trace.append("  Emitted event '%s'" % evt_name)

func _set_context_path(context: Dictionary, path: String, val: Variant) -> void:
	var segs = path.split(".")
	if segs.size() == 1:
		context[segs[0]] = val
		return
		
	var curr: Dictionary = context
	for i in range(segs.size() - 1):
		var s = segs[i]
		if not curr.has(s) or not (curr[s] is Dictionary):
			curr[s] = {}
		curr = curr[s]
	curr[segs[segs.size() - 1]] = val

func to_dict() -> Dictionary:
	return {
		"mechanic_id": mechanic_id,
		"name": name,
		"description": description,
		"trigger_event": trigger_event,
		"nodes": nodes.duplicate(true)
	}

static func from_dict(d: Dictionary) -> Variant:
	var g = (load("res://core/gameplay/custom_mechanic_graph.gd") as GDScript).new(
		str(d.get("mechanic_id", d.get("id", ""))),
		str(d.get("name", "")),
		str(d.get("trigger_event", d.get("event", "")))
	)
	g.description = str(d.get("description", ""))
	var raw_nodes = d.get("nodes", [])
	if raw_nodes is Array:
		for n in raw_nodes:
			g.nodes.append(n.duplicate(true))
	return g
