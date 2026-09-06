extends Node

## Global EventBus singleton for decoupled communication between systems.

# Player signals
signal player_moved(grid_position: Vector2i)
signal player_interacted(grid_position: Vector2i)

# Grid signals
signal tile_changed(grid_position: Vector2i, tile_data: Dictionary)
signal tile_selected(grid_position: Vector2i)

# Time & Day/Night signals
signal day_started(day_number: int)
signal day_ended(day_number: int)
signal time_changed(minutes: int, time_str: String)
signal hour_changed(hour: int)
signal day_phase_changed(old_phase: String, new_phase: String)
signal morning_started(day_number: int)
signal night_started(day_number: int)
signal time_paused(is_paused: bool, reason: String)
signal sleep_requested()
signal sleep_completed(new_day: int)


# Future milestones signals
signal inventory_changed()
signal combination_discovered(combo_id: String, result_id: String)

# Milestone 9 Gameplay & Quest signals
signal plant_planted(player_id: String, pos: Vector2i, plant_id: String)
signal plant_watered(player_id: String, pos: Vector2i)
signal plant_harvested(player_id: String, pos: Vector2i, plant_id: String, count: int)
signal plant_combined(player_id: String, input_a: String, input_b: String, output: String)
signal plant_discovered(player_id: String, plant_id: String)
signal item_sold(player_id: String, item_id: String, count: int, total_gold: int)
signal item_bought(player_id: String, item_id: String, count: int, price: int)
signal npc_talked(player_id: String, npc_id: String)
signal quest_completed(player_id: String, quest_id: String)
signal quest_claimed(player_id: String, quest_id: String)
signal greenhouse_repaired(stage: int)

# Phase 9 Co-op Objective & Event Pipeline signals
signal container_deposited(player_id: String, container_id: String, item_id: String, count: int)
signal container_withdrawn(player_id: String, container_id: String, item_id: String, count: int)
signal synthesis_performed(player_id: String, formula_id: String, result_id: String, count: int)
signal dialogue_action_executed(player_id: String, npc_id: String, action_id: String, action_params: Dictionary)
signal friendship_changed(player_id: String, npc_id: String, new_points: int)
signal shared_event_triggered(event_id: String, data: Dictionary)
signal world_unlocked(world_id: String, display_name: String)

# Milestone 14 World Transition & Loader signals
signal world_transition_started(target_world: String)
signal world_changed(world_id: String, world_data: Dictionary)
signal world_transition_completed(world_id: String)

# Phase 15 Core Tool, Farming & Resource signals
signal tool_used(tool_id: String, target_pos: Vector2i)
signal soil_tilled(pos: Vector2i)
signal resource_hit(node_id: String, pos: Vector2i, damage: int, remaining_hp: int)
signal resource_destroyed(node_id: String, pos: Vector2i)
signal tool_upgraded(tool_id: String, new_quality: String)

# Phase 21 Living World & Social signals
signal npc_activity_started(npc_id: String, activity_id: String)
signal npc_activity_finished(npc_id: String, activity_id: String)
signal npc_social_started(npc_a: String, npc_b: String, social_type: String)
signal npc_social_finished(npc_a: String, npc_b: String)
signal npc_schedule_changed(npc_id: String, schedule_entry: Dictionary)
