class_name AssetRegistry
extends RefCounted

## Central asset path resolver, stable ID router, and resource cache for sprites, audio, UI, and VFX.

const SPRITE_ROOT = "res://assets/sprites/"
const AUDIO_ROOT = "res://assets/audio/"
const MANIFEST_PATH = "res://data/assets/asset_manifest.json"

static var _manifest: Dictionary = {}
static var _texture_cache: Dictionary = {}
static var _placeholder_cache: Dictionary = {}
static var _resource_overrides: Dictionary = {} # asset_id -> Resource (for asset swapping & modding)
static var _initialized: bool = false

# ==============================================================================
# INITIALIZATION & MANIFEST
# ==============================================================================

static func ensure_initialized() -> void:
	if _initialized: return
	_load_manifest()
	_initialized = true

static func _load_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH): return
	var f = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if f:
		var text = f.get_as_text()
		f.close()
		var json = JSON.new()
		if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
			_manifest = json.data.get("assets", {})

static func get_metadata(asset_id: String) -> Dictionary:
	ensure_initialized()
	return _manifest.get(asset_id, {})

static func get_all_asset_ids() -> Array:
	ensure_initialized()
	return _manifest.keys()

# ==============================================================================

# RUNTIME ASSET SWAP / OVERRIDE API (MODDING & TESTS)
# ==============================================================================

static func register_asset_override(asset_id: String, res: Resource) -> void:
	if res:
		_resource_overrides[asset_id] = res

static func register_texture_override(asset_id: String, texture: Texture2D) -> void:
	register_asset_override(asset_id, texture)

static func remove_texture_override(asset_id: String) -> void:
	_resource_overrides.erase(asset_id)

static func clear_texture_overrides() -> void:
	_resource_overrides.clear()

static func clear_overrides() -> void:
	_resource_overrides.clear()

static func has_texture_override(asset_id: String) -> bool:
	return _resource_overrides.has(asset_id)

# ==============================================================================
# UNIVERSAL RESOLVERS
# ==============================================================================

static func get_texture(asset_id: String) -> Texture2D:
	return get_asset_texture(asset_id)

static func get_sprite_frames(asset_id: String) -> SpriteFrames:
	ensure_initialized()
	if _resource_overrides.has(asset_id) and _resource_overrides[asset_id] is SpriteFrames:
		return _resource_overrides[asset_id] as SpriteFrames
		
	var sf = SpriteFrames.new()
	var base_tex = get_texture(asset_id)
	if base_tex:
		sf.add_frame("default", base_tex)
	return sf

static func get_animation(asset_id: String) -> Dictionary:
	var meta = get_metadata(asset_id)
	return {
		"id": asset_id,
		"frames": meta.get("frames", 1),
		"fps": meta.get("fps", 6),
		"loop": meta.get("loop", true)
	}

static func get_font(asset_id: String) -> Font:
	if _resource_overrides.has(asset_id) and _resource_overrides[asset_id] is Font:
		return _resource_overrides[asset_id] as Font
	var path = "res://assets/fonts/%s.ttf" % asset_id
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Font
	return null

static func get_audio(asset_id: String) -> AudioStream:
	if _resource_overrides.has(asset_id) and _resource_overrides[asset_id] is AudioStream:
		return _resource_overrides[asset_id] as AudioStream
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var am = root.get_node_or_null("/root/AudioManager") if root else null
	if am and am.has_method("get_sound_stream"):
		return am.get_sound_stream(asset_id)
	return null

static func get_music(music_id: String) -> AudioStream:
	return get_audio(music_id)

static func get_effect(effect_id: String) -> Dictionary:
	var meta = get_metadata(effect_id)
	if meta.is_empty():
		return { "id": effect_id, "type": "particles", "color": Color.WHITE }
	return meta

static func get_material(mat_id: String) -> Material:
	if _resource_overrides.has(mat_id) and _resource_overrides[mat_id] is Material:
		return _resource_overrides[mat_id] as Material
	return null

static func get_shader(shader_id: String) -> Shader:
	if _resource_overrides.has(shader_id) and _resource_overrides[shader_id] is Shader:
		return _resource_overrides[shader_id] as Shader
	return null

static func get_tileset(_tileset_id: String) -> TileSet:
	return null

static func get_ui_style(style_id: String) -> StyleBoxFlat:
	match style_id:
		"panel", "card": return UIConstants.create_panel_stylebox()
		"button": return UIConstants.create_button_stylebox()
		"slot": return UIConstants.create_slot_stylebox(false)
		"slot_selected": return UIConstants.create_slot_stylebox(true)
		_: return UIConstants.create_panel_stylebox()

# ==============================================================================
# TEXTURE RESOLVERS BY CATEGORY
# ==============================================================================

static func get_plant_texture(plant_id: String, stage: int = 3) -> Texture2D:
	ensure_initialized()
	var key = "plant.%s.%d" % [plant_id, stage]
	if _resource_overrides.has(key): return _resource_overrides[key] as Texture2D
	if _resource_overrides.has(plant_id): return _resource_overrides[plant_id] as Texture2D
	
	var path = "%splants/%s_stage_%d.png" % [SPRITE_ROOT, plant_id, stage]
	var tex = _load_texture_safe(path)
	if tex: return tex
	return get_fallback_placeholder_texture(plant_id, Color(0.2, 0.8, 0.3))

static func get_crop_texture(crop_id: String, stage: int = 3) -> Texture2D:
	return get_plant_texture(crop_id, stage)


static func get_item_icon(item_id: String) -> Texture2D:
	ensure_initialized()
	if _resource_overrides.has(item_id): return _resource_overrides[item_id] as Texture2D
	if _resource_overrides.has("item." + item_id): return _resource_overrides["item." + item_id] as Texture2D
	
	var lookup = item_id
	if item_id == "fertilizer_growth": lookup = "fertilizer"
	elif item_id == "herbal_tonic": lookup = "tonic"
	var path = "%sitems/%s.png" % [SPRITE_ROOT, lookup]
	var tex = _load_texture_safe(path)
	if tex: return tex
	
	var direct_path = "%sitems/%s.png" % [SPRITE_ROOT, item_id]
	tex = _load_texture_safe(direct_path)
	if tex: return tex
	return get_fallback_placeholder_texture(item_id, Color(0.9, 0.7, 0.2))

static func get_tool_icon(tool_id: String, quality: String = "basic") -> Texture2D:
	ensure_initialized()
	var qual_key = "tool.%s.%s" % [tool_id, quality]
	if _resource_overrides.has(qual_key): return _resource_overrides[qual_key] as Texture2D
	if _resource_overrides.has(tool_id): return _resource_overrides[tool_id] as Texture2D
	
	var icon = get_item_icon(tool_id)
	if icon: return icon
	return get_fallback_placeholder_texture(tool_id, Color(0.6, 0.6, 0.8))

static func get_tile_texture(tile_type: String, variant: int = 0) -> Texture2D:
	ensure_initialized()
	var key = "tile.%s.%d" % [tile_type, variant]
	if _resource_overrides.has(key): return _resource_overrides[key] as Texture2D
	if _resource_overrides.has(tile_type): return _resource_overrides[tile_type] as Texture2D
	
	if variant > 0:
		var var_path = "%stiles/%s_%d.png" % [SPRITE_ROOT, tile_type, variant]
		var tex = _load_texture_safe(var_path)
		if tex: return tex
	var path = "%stiles/%s.png" % [SPRITE_ROOT, tile_type]
	var base_tex = _load_texture_safe(path)
	if base_tex: return base_tex
	
	# Fallback aliases for tiles
	if tile_type == "water" or tile_type == "watered":
		return _load_texture_safe("%stiles/watered_soil.png" % SPRITE_ROOT)
	elif tile_type == "sand":
		return _load_texture_safe("%stiles/path_2.png" % SPRITE_ROOT)
	elif tile_type == "stone":
		return _load_texture_safe("%stiles/path_1.png" % SPRITE_ROOT)
	return get_fallback_placeholder_texture(tile_type, Color(0.4, 0.6, 0.3))

static func get_environment_prop(prop_name: String) -> Texture2D:
	ensure_initialized()
	if _resource_overrides.has(prop_name): return _resource_overrides[prop_name] as Texture2D
	if _resource_overrides.has("prop." + prop_name): return _resource_overrides["prop." + prop_name] as Texture2D
	
	var path = "%senvironment/%s.png" % [SPRITE_ROOT, prop_name]
	var tex = _load_texture_safe(path)
	if tex: return tex
	
	# Environment aliases
	if prop_name in ["bush", "ancient_tree"]:
		return _load_texture_safe("%senvironment/bush_small.png" % SPRITE_ROOT)
	elif prop_name in ["rock", "boulder"]:
		return _load_texture_safe("%senvironment/rock_small.png" % SPRITE_ROOT)
	elif prop_name in ["tree", "stump"]:
		return _load_texture_safe("%senvironment/tree_stump.png" % SPRITE_ROOT)
	return get_fallback_placeholder_texture(prop_name, Color(0.5, 0.4, 0.3))

static func get_npc_animation_texture(npc_name: String, anim_name: String = "idle", direction_str: String = "down", frame: int = 0) -> Texture2D:
	ensure_initialized()
	var keys = [
		"npc.%s.%s.%s.%d" % [npc_name, anim_name, direction_str, frame],
		"npc.%s.%s.%s" % [npc_name, anim_name, direction_str],
		"npc.%s.%s.%d" % [npc_name, anim_name, frame],
		"npc.%s.%s" % [npc_name, anim_name],
		"npc.%s.idle.%s.%d" % [npc_name, direction_str, frame],
		"npc.%s.idle.%d" % [npc_name, frame],
		"npc.%s.%d" % [npc_name, frame],
		"npc." + npc_name,
		npc_name
	]
	for k in keys:
		if _resource_overrides.has(k) and _resource_overrides[k] is Texture2D:
			return _resource_overrides[k] as Texture2D

	var lookup = npc_name
	if lookup == "rowan": lookup = "merchant"
	
	var candidates = [
		"%snpc/%s_%s_%s_%d.png" % [SPRITE_ROOT, lookup, anim_name, direction_str, frame],
		"%snpc/%s_%s_%d.png" % [SPRITE_ROOT, lookup, anim_name, frame],
		"%snpc/%s_idle_%d.png" % [SPRITE_ROOT, lookup, frame],
		"%snpc/%s.png" % [SPRITE_ROOT, lookup]
	]
	for p in candidates:
		var tex = _load_texture_safe(p)
		if tex: return tex

	return get_fallback_placeholder_texture(npc_name, Color(0.8, 0.5, 0.7))

static func get_npc_texture(npc_name: String, frame: int = 0) -> Texture2D:
	return get_npc_animation_texture(npc_name, "idle", "down", frame)


static func get_npc_portrait(npc_name: String, emotion: String = "neutral") -> Texture2D:
	ensure_initialized()
	var key = "npc.portrait.%s.%s" % [npc_name, emotion]
	if _resource_overrides.has(key): return _resource_overrides[key] as Texture2D
	if _resource_overrides.has("npc.portrait." + npc_name): return _resource_overrides["npc.portrait." + npc_name] as Texture2D
	
	var lookup = npc_name
	if lookup == "rowan": lookup = "merchant"
	
	var path = "%snpc/%s_portrait.png" % [SPRITE_ROOT, lookup]
	var tex = _load_texture_safe(path)
	if tex: return tex
	
	var idle_tex = get_npc_texture(npc_name, 0)
	if idle_tex: return idle_tex
	return get_fallback_placeholder_texture(npc_name + "_portrait", Color(0.8, 0.4, 0.6))

static func get_player_texture(direction: Vector2i = Vector2i.DOWN, frame: int = 0) -> Texture2D:
	ensure_initialized()
	var dir_str = "down"
	if direction == Vector2i.UP: dir_str = "up"
	elif direction == Vector2i.LEFT: dir_str = "left"
	elif direction == Vector2i.RIGHT: dir_str = "right"
		
	var key = "player.%s.%d" % [dir_str, frame]
	if _resource_overrides.has(key): return _resource_overrides[key] as Texture2D
	
	if frame > 0:
		var frame_path = "%splayer/player_%s_%d.png" % [SPRITE_ROOT, dir_str, frame]
		var ftex = _load_texture_safe(frame_path)
		if ftex: return ftex
			
	var path = "%splayer/player_%s.png" % [SPRITE_ROOT, dir_str]
	var main_tex = _load_texture_safe(path)
	if main_tex: return main_tex
	return get_fallback_placeholder_texture("player", Color(0.3, 0.6, 0.9))

static func get_ui_icon(icon_name: String) -> Texture2D:
	ensure_initialized()
	var key = "ui.icon." + icon_name
	if _resource_overrides.has(key): return _resource_overrides[key] as Texture2D
	if _resource_overrides.has(icon_name): return _resource_overrides[icon_name] as Texture2D
	
	var lookup = icon_name
	if not lookup.begins_with("icon_"): lookup = "icon_" + lookup
	var path = "%sui/%s.png" % [SPRITE_ROOT, lookup]
	var tex = _load_texture_safe(path)
	if tex: return tex
	return get_fallback_placeholder_texture(icon_name, Color(0.9, 0.8, 0.4))

static func get_effect_texture(effect_name: String) -> Texture2D:
	ensure_initialized()
	var key = "effect." + effect_name
	if _resource_overrides.has(key): return _resource_overrides[key] as Texture2D
	
	var path = "%senvironment/%s.png" % [SPRITE_ROOT, effect_name]
	var tex = _load_texture_safe(path)
	if tex: return tex
	return get_fallback_placeholder_texture(effect_name, Color(0.4, 0.9, 0.9))

## Unified generic asset texture resolver for World Builder, UI & Gameplay
static func get_asset_texture(asset_id: String, asset_type: String = "") -> Texture2D:
	ensure_initialized()
	if asset_id.is_empty(): return null
	
	if _resource_overrides.has(asset_id) and _resource_overrides[asset_id] is Texture2D:
		return _resource_overrides[asset_id] as Texture2D
		
	# Check manifest entry first
	if _manifest.has(asset_id):
		var meta = _manifest[asset_id]
		var tex_path = str(meta.get("texture", ""))
		if tex_path != "":
			var tex = _load_texture_safe(tex_path)
			if tex: return tex
	
	# Check prefixes
	if asset_id.begins_with("item."): return get_item_icon(asset_id.substr(5))
	if asset_id.begins_with("tile."): return get_tile_texture(asset_id.substr(5))
	if asset_id.begins_with("prop."): return get_environment_prop(asset_id.substr(5))
	if asset_id.begins_with("building."): return get_environment_prop(asset_id.substr(9))
	if asset_id.begins_with("npc."): 
		if asset_id.ends_with(".portrait"):
			return get_npc_portrait(asset_id.trim_prefix("npc.").trim_suffix(".portrait"))
		return get_npc_texture(asset_id.substr(4))
	if asset_id.begins_with("ui.icon."): return get_ui_icon(asset_id.substr(8))
	if asset_id.begins_with("plant."): return get_plant_texture(asset_id.substr(6))
	if asset_id.begins_with("tool."): return get_tool_icon(asset_id.substr(5))
	
	# 1. Check tile textures
	if asset_type in ["tile", "terrain"] or asset_id in ["grass", "soil", "path", "fence", "water", "sand", "stone", "watered_soil"]:
		var t_tex = get_tile_texture(asset_id)
		if t_tex: return t_tex
		
	# 2. Check environment props & buildings
	var env_tex = get_environment_prop(asset_id)
	if env_tex: return env_tex
	
	# 3. Check plant textures (stage 3)
	var plant_tex = get_plant_texture(asset_id, 3)
	if plant_tex: return plant_tex
	
	# 4. Check NPC textures
	var npc_tex = get_npc_texture(asset_id)
	if npc_tex: return npc_tex
	
	# 5. Check item icons
	var item_tex = get_item_icon(asset_id)
	if item_tex: return item_tex
	
	# 6. Specific ID mappings / Aliases for buildings, interactive & world elements
	var alias_map = {
		"rowan": "%snpc/merchant_idle_0.png" % SPRITE_ROOT,
		"merchant": "%snpc/merchant_idle_0.png" % SPRITE_ROOT,
		"mira": "%snpc/mira_idle_0.png" % SPRITE_ROOT,
		"elias": "%snpc/elias_idle_0.png" % SPRITE_ROOT,
		"seed_shop": "%snpc/market_stall.png" % SPRITE_ROOT,
		"shipping_box": "%snpc/market_stall.png" % SPRITE_ROOT,
		"farm_house": "%senvironment/greenhouse_repaired.png" % SPRITE_ROOT,
		"greenhouse_repaired": "%senvironment/greenhouse_repaired.png" % SPRITE_ROOT,
		"greenhouse_ruined": "%senvironment/greenhouse_ruined.png" % SPRITE_ROOT,
		"laboratory": "%senvironment/greenhouse_ruined.png" % SPRITE_ROOT,
		"barn": "%senvironment/greenhouse_repaired.png" % SPRITE_ROOT,
		"storage_shed": "%senvironment/greenhouse_ruined.png" % SPRITE_ROOT,
		"wooden_gate": "%senvironment/wooden_gate.png" % SPRITE_ROOT,
		"tree_stump": "%senvironment/tree_stump.png" % SPRITE_ROOT,
		"tree": "%senvironment/tree_stump.png" % SPRITE_ROOT,
		"ancient_tree": "%senvironment/bush_small.png" % SPRITE_ROOT,
		"bush": "%senvironment/bush_small.png" % SPRITE_ROOT,
		"rock": "%senvironment/rock_small.png" % SPRITE_ROOT,
		"fallen_branch": "%senvironment/fallen_branch.png" % SPRITE_ROOT,
		"flower_patch": "%senvironment/flower_patch.png" % SPRITE_ROOT,
		"chest": "%sitems/expanded_satchel.png" % SPRITE_ROOT,
		"workbench": "%sitems/better_tools.png" % SPRITE_ROOT,
		"signpost": "%senvironment/wooden_gate.png" % SPRITE_ROOT,
		"well": "%senvironment/rock_small.png" % SPRITE_ROOT,
		"bench": "%senvironment/tree_stump.png" % SPRITE_ROOT,
		"mushroom": "%splants/crystal_fern_stage_3.png" % SPRITE_ROOT,
		"pond": "%senvironment/flower_patch.png" % SPRITE_ROOT,
		"world_exit": "%senvironment/wooden_gate.png" % SPRITE_ROOT,
		"portal": "%sitems/astral_moss.png" % SPRITE_ROOT,
		"player_start": "%splayer/player_down.png" % SPRITE_ROOT
	}
	
	if alias_map.has(asset_id):
		var mapped_tex = _load_texture_safe(alias_map[asset_id])
		if mapped_tex: return mapped_tex
		
	# 7. Check if player texture matches
	if asset_id.begins_with("player"):
		var p_tex = get_player_texture()
		if p_tex: return p_tex

	return get_fallback_placeholder_texture(asset_id)

## Returns true if the asset exists physically or as an override/alias
static func has_asset(asset_id: String) -> bool:
	ensure_initialized()
	if _resource_overrides.has(asset_id): return true
	if _manifest.has(asset_id): return true
	var path = SPRITE_ROOT + asset_id + ".png"
	if ResourceLoader.exists(path) or FileAccess.file_exists(path): return true
	var a_path = AUDIO_ROOT + asset_id + ".ogg"
	if ResourceLoader.exists(a_path) or FileAccess.file_exists(a_path): return true
	return false


## Generate or retrieve a crisp pixel-art placeholder icon for missing assets
static func get_fallback_placeholder_texture(asset_id: String, col: Color = Color(0.8, 0.5, 0.2)) -> Texture2D:
	if _placeholder_cache.has(asset_id):
		return _placeholder_cache[asset_id]
		
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(col.r * 0.4, col.g * 0.4, col.b * 0.4, 0.9))
	for x in range(16):
		img.set_pixel(x, 0, col)
		img.set_pixel(x, 15, col)
	for y in range(16):
		img.set_pixel(0, y, col)
		img.set_pixel(15, y, col)
	# Center dot
	img.set_pixel(7, 7, Color.WHITE)
	img.set_pixel(8, 7, Color.WHITE)
	img.set_pixel(7, 8, Color.WHITE)
	img.set_pixel(8, 8, Color.WHITE)
	
	var tex = ImageTexture.create_from_image(img)
	_placeholder_cache[asset_id] = tex
	return tex

static func _load_texture_safe(path: String) -> Texture2D:
	if path == "": return null
	if _texture_cache.has(path):
		return _texture_cache[path]
		
	if ResourceLoader.exists(path):
		var tex = ResourceLoader.load(path) as Texture2D
		if tex:
			_texture_cache[path] = tex
			return tex
			
	if FileAccess.file_exists(path):
		var img = Image.load_from_file(path)
		if img and not img.is_empty():
			var tex = ImageTexture.create_from_image(img)
			if tex:
				_texture_cache[path] = tex
				return tex
			
	return null

## Safely imports an external image file into the user override layer
static func import_user_asset(source_path: String, target_stable_id: String) -> String:
	if not FileAccess.file_exists(source_path):
		push_error("[AssetRegistry] Source asset file not found: " + source_path)
		return ""
		
	var user_dir = "user://imported_assets"
	if not DirAccess.dir_exists_absolute(user_dir):
		DirAccess.make_dir_recursive_absolute(user_dir)
		
	var ext = source_path.get_extension()
	if ext == "": ext = "png"
	var dest_file = "%s/%s.%s" % [user_dir, target_stable_id.replace(".", "_"), ext]
	
	var src = FileAccess.open(source_path, FileAccess.READ)
	if not src:
		push_error("[AssetRegistry] Failed to open source asset file: " + source_path)
		return ""
	var buf = src.get_buffer(src.get_length())
	src.close()
	
	var dst = FileAccess.open(dest_file, FileAccess.WRITE)
	if not dst:
		push_error("[AssetRegistry] Failed to write imported asset: " + dest_file)
		return ""
	dst.store_buffer(buf)
	dst.close()
	
	var loaded_tex = _load_texture_safe(dest_file)
	if loaded_tex:
		register_texture_override(target_stable_id, loaded_tex)
		
	return dest_file

## Synchronizes runtime resource overrides with active EditorDataService staged/saved overrides
static func sync_with_data_service(data_service: Variant) -> void:
	if not data_service: return
	if data_service.has_method("get_all_stable_ids"):
		var ids: Array = data_service.get_all_stable_ids()
		for sid in ids:
			if data_service.has_method("has_override") and data_service.has_override(sid):
				var tex_val = data_service.get_resolved_value(sid, "texture")
				if tex_val and typeof(tex_val) == TYPE_STRING and str(tex_val) != "":
					var tex = _load_texture_safe(str(tex_val))
					if tex:
						register_texture_override(sid, tex)
			elif has_texture_override(sid):
				remove_texture_override(sid)



