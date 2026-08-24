class_name NetworkAuthoringSynchronizer
extends RefCounted

## Multiplayer Custom Gameplay & Authoring State Synchronizer (Phase 43).
## Serializes and validates host-authoritative component states, custom events,
## and state machine transitions using semantic IDs (avoiding raw scene/file paths).

const COMPAT_SERVICE = preload("res://core/engine_compatibility_service.gd")

static func pack_component_state(entity_id: String, comp_type: String, comp_data: Dictionary) -> Dictionary:
	return {
		"type": "COMPONENT_STATE",
		"entity_id": entity_id,
		"component": comp_type,
		"data": comp_data.duplicate(true),
		"timestamp": Time.get_unix_time_from_system()
	}

static func pack_event(event_type: String, source_id: String, payload: Dictionary = {}) -> Dictionary:
	return {
		"type": "CUSTOM_EVENT",
		"event": event_type,
		"source": source_id,
		"payload": payload.duplicate(true),
		"timestamp": Time.get_unix_time_from_system()
	}

static func pack_state_transition(entity_id: String, from_state: String, to_state: String) -> Dictionary:
	return {
		"type": "STATE_TRANSITION",
		"entity_id": entity_id,
		"from": from_state,
		"to": to_state,
		"timestamp": Time.get_unix_time_from_system()
	}

static func apply_packet_to_entity(packet: Dictionary, entity: Variant) -> Dictionary:
	if not entity:
		return { "success": false, "error": "Target entity is null" }
		
	var ptype = str(packet.get("type", ""))
	match ptype:
		"COMPONENT_STATE":
			var ctype = str(packet.get("component", ""))
			var cdata = packet.get("data", {})
			if entity.has_method("get_component"):
				var comp = entity.get_component(ctype)
				if comp and "data" in comp and (cdata is Dictionary):
					comp.data = cdata.duplicate(true)
					return { "success": true, "action": "updated_component", "component": ctype }
				elif not comp and entity.has_method("add_component"):
					entity.add_component(ctype, cdata)
					return { "success": true, "action": "added_component", "component": ctype }
					
		"STATE_TRANSITION":
			var to_st = str(packet.get("to", ""))
			if entity.has_method("get_component_data"):
				var sm = entity.get_component_data("state_machine")
				if sm:
					sm["current_state"] = to_st
					return { "success": true, "action": "state_transitioned", "state": to_st }

	return { "success": false, "error": "Unhandled or invalid packet type '%s'" % ptype }

static func validate_handshake(server_info: Dictionary, client_info: Dictionary) -> Dictionary:
	var s_pkg = str(server_info.get("game_id", "botanical_haven"))
	var c_pkg = str(client_info.get("game_id", "botanical_haven"))
	if s_pkg != c_pkg:
		return { "compatible": false, "error": "Game Package Mismatch (Server: %s, Client: %s)" % [s_pkg, c_pkg] }
		
	var s_ver = str(server_info.get("version", "1.0.0"))
	var c_ver = str(client_info.get("version", "1.0.0"))
	if s_ver != c_ver:
		return { "compatible": false, "error": "Game Version Incompatible (Server: %s, Client: %s)" % [s_ver, c_ver] }
		
	return { "compatible": true, "error": "" }
