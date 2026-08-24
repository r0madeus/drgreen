class_name DayNightOverlay
extends CanvasModulate

## Smooth day/night lighting and seasonal color modulation overlay.
## Listens to TimeManager and smoothly interpolates world ambient color.

@export var interpolation_speed: float = 4.0

func _ready() -> void:
	z_index = 90
	_apply_immediate_color()

func _process(delta: float) -> void:
	var tm = get_node_or_null("/root/TimeManager")
	var sm = get_node_or_null("/root/SeasonManager")
	
	var base_ambient = tm.get_ambient_color() if tm else Color(1.0, 1.0, 1.0, 1.0)
	var season_tint = sm.get_season_tint() if sm else Color(1.0, 1.0, 1.0, 1.0)
	
	var target_color = base_ambient * season_tint
	color = color.lerp(target_color, clampf(delta * interpolation_speed, 0.0, 1.0))

func _apply_immediate_color() -> void:
	var tm = get_node_or_null("/root/TimeManager")
	var sm = get_node_or_null("/root/SeasonManager")
	var base_ambient = tm.get_ambient_color() if tm else Color(1.0, 1.0, 1.0, 1.0)
	var season_tint = sm.get_season_tint() if sm else Color(1.0, 1.0, 1.0, 1.0)
	color = base_ambient * season_tint
