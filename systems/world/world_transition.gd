class_name WorldTransition
extends CanvasLayer

## Visual fade-out / fade-in overlay providing smooth, seamless world transitions.

var color_rect: ColorRect
var is_fading: bool = false

func _ready() -> void:
	layer = 100
	color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

func fade_out(duration: float = 0.25) -> void:
	is_fading = true
	var tw = create_tween()
	tw.tween_property(color_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished

func fade_in(duration: float = 0.25) -> void:
	var tw = create_tween()
	tw.tween_property(color_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	is_fading = false
