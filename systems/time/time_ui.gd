class_name TimeUI
extends Label

## UI helper component displaying the active day.

func _ready() -> void:
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		tm.day_started.connect(_on_day_started)
		update_display(tm.get_current_day())
	else:
		update_display(1)

func _on_day_started(day: int) -> void:
	update_display(day)

func update_display(day: int) -> void:
	text = "📅 Day: %d" % day
