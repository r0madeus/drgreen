class_name GridRenderer
extends Node2D

## Visually renders dynamic grid tiles and subtle grid lines based on active world dimensions.

@export var grid_manager: GridManager

const COLOR_GRASS = Color(0.31, 0.47, 0.18)
const COLOR_GRASS_INNER = Color(0.36, 0.53, 0.21)
const COLOR_GRASS_SPECK = Color(0.56, 0.66, 0.33, 0.6)

const COLOR_SOIL = Color(0.35, 0.18, 0.05)
const COLOR_SOIL_INNER = Color(0.44, 0.25, 0.10)
const COLOR_SOIL_FURROW = Color(0.28, 0.14, 0.04)

const COLOR_SOIL_WET = Color(0.20, 0.09, 0.00)
const COLOR_SOIL_WET_INNER = Color(0.28, 0.14, 0.00)
const COLOR_SOIL_WET_SHEEN = Color(0.25, 0.45, 0.65, 0.35)

const COLOR_PATH = Color(0.72, 0.64, 0.53)
const COLOR_PATH_INNER = Color(0.82, 0.74, 0.64)
const COLOR_PATH_STONE = Color(0.58, 0.50, 0.40)

const COLOR_FENCE_POST = Color(0.44, 0.28, 0.15)
const COLOR_FENCE_RAIL = Color(0.55, 0.36, 0.20)
const COLOR_FENCE_BG = Color(0.25, 0.38, 0.14)

const COLOR_GRID_LINE = Color(0.0, 0.0, 0.0, 0.06)

func _ready() -> void:
	if not grid_manager:
		grid_manager = get_parent() as GridManager
	if grid_manager:
		grid_manager.grid_initialized.connect(queue_redraw)
		grid_manager.tile_updated.connect(_on_tile_updated)
		
	var sm = get_node_or_null("/root/SeasonManager")
	if sm: sm.season_changed.connect(func(_o, _n): queue_redraw())
	queue_redraw()

func _on_tile_updated(_pos: Vector2i, _tile: GridTileData) -> void:
	queue_redraw()

func _get_seasonal_grass_colors() -> Array[Color]:
	var sm = get_node_or_null("/root/SeasonManager")
	var season = sm.get_season_id() if sm else "spring"
	match season:
		"summer": return [Color(0.38, 0.52, 0.14), Color(0.44, 0.58, 0.18), Color(0.65, 0.72, 0.28, 0.6)]
		"autumn": return [Color(0.52, 0.38, 0.15), Color(0.60, 0.45, 0.18), Color(0.80, 0.55, 0.20, 0.6)]
		"winter": return [Color(0.68, 0.76, 0.82), Color(0.78, 0.85, 0.90), Color(0.92, 0.96, 1.0, 0.8)]
		_: return [COLOR_GRASS, COLOR_GRASS_INNER, COLOR_GRASS_SPECK]

func _draw() -> void:
	if not grid_manager: return
	var ts = grid_manager.tile_size
	var gw = grid_manager.grid_width
	var gh = grid_manager.grid_height
	
	for y in range(gh):
		for x in range(gw):
			var pos = Vector2i(x, y)
			var tile = grid_manager.get_tile(pos)
			if not tile: continue
				
			var rect = Rect2(x * ts, y * ts, ts, ts)
			var tile_key = "watered_soil" if (tile.type == "soil" and tile.watered_today) else tile.type
			var custom_tex = AssetRegistry.get_tile_texture(tile_key)
			if custom_tex:
				var sm = get_node_or_null("/root/SeasonManager")
				var modulate_col = sm.get_season_tint() if sm else Color.WHITE
				if tile.type == "soil": modulate_col = Color.WHITE
				draw_texture_rect(custom_tex, rect, false, modulate_col)
				draw_rect(rect, COLOR_GRID_LINE, false, 1.0)
				continue
				
			match tile.type:
				"grass":
					var g_cols = _get_seasonal_grass_colors()
					draw_rect(rect, g_cols[0])
					draw_rect(rect.grow(-1), g_cols[1])
					if (x + y) % 3 == 0:
						draw_line(Vector2(rect.position.x + 4, rect.position.y + 11), Vector2(rect.position.x + 5, rect.position.y + 7), g_cols[2], 1.0)
						draw_line(Vector2(rect.position.x + 5, rect.position.y + 7), Vector2(rect.position.x + 7, rect.position.y + 11), g_cols[2], 1.0)
				"soil":
					if tile.watered_today:
						draw_rect(rect, COLOR_SOIL_WET)
						draw_rect(rect.grow(-1), COLOR_SOIL_WET_INNER)
						draw_rect(rect.grow(-3), COLOR_SOIL_WET_SHEEN)
					else:
						draw_rect(rect, COLOR_SOIL)
						draw_rect(rect.grow(-1), COLOR_SOIL_INNER)
				"path":
					draw_rect(rect, COLOR_PATH)
					draw_rect(rect.grow(-1), COLOR_PATH_INNER)
				"fence", "blocked":
					draw_rect(rect, COLOR_FENCE_BG)
					draw_line(Vector2(rect.position.x, rect.position.y + 6), Vector2(rect.position.x + 16, rect.position.y + 6), COLOR_FENCE_RAIL, 2.0)
					draw_line(Vector2(rect.position.x, rect.position.y + 12), Vector2(rect.position.x + 16, rect.position.y + 12), COLOR_FENCE_RAIL, 2.0)
					draw_rect(Rect2(rect.position.x + 5, rect.position.y + 2, 6, 12), COLOR_FENCE_POST)
				_:
					draw_rect(rect, Color(0.31, 0.47, 0.18))
			draw_rect(rect, COLOR_GRID_LINE, false, 1.0)
