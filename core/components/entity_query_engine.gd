class_name EntityQueryEngine
extends RefCounted

## High-Performance Generic Entity Query Engine (Phase 42).
## Filters entities by tags, attached components, derived capabilities, states, and spatial radii.

static func query(entities: Array, filter: Dictionary = {}, mode: String = "all") -> Array:
	var matches: Array = []
	
	var tag_req = filter.get("tag", "")
	var comp_req = filter.get("component", "")
	var cap_req = filter.get("capability", "")
	var state_req = filter.get("state", "")
	var radius = float(filter.get("radius", 0.0))
	var origin: Array = filter.get("origin", [])
	
	for ent in entities:
		if not ent: continue
		
		# 1. Tag filter
		if tag_req != "" and ("tags" in ent):
			if not ent.tags.has(tag_req): continue
			
		# 2. Component filter
		if comp_req != "" and ent.has_method("has_component"):
			if not ent.has_component(comp_req): continue
			
		# 3. Capability filter
		if cap_req != "" and ent.has_method("has_capability"):
			if not ent.has_capability(cap_req): continue
			
		# 4. State filter
		if state_req != "" and ent.has_method("get_component_data"):
			var sm = ent.get_component_data("state_machine")
			if sm.get("current_state", "") != state_req: continue
			
		# 5. Spatial Radius filter
		if radius > 0.0 and origin.size() >= 2 and ent.has_method("get_component_data"):
			var t_data = ent.get_component_data("transform")
			var pos = t_data.get("position", [0, 0])
			if pos.size() >= 2:
				var dx = float(pos[0]) - float(origin[0])
				var dy = float(pos[1]) - float(origin[1])
				var dist = sqrt(dx * dx + dy * dy)
				if dist > radius: continue
				
		matches.append(ent)
		if mode == "first":
			return matches
			
	return matches
