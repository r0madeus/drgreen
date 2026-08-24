class_name ValidationPanel
extends PanelContainer

## Collapsible dock displaying real-time world validation errors and warnings.

signal issue_selected(pos: Vector2i)

var results_list_vbox: VBoxContainer
var filter_opt: OptionButton
var status_header: Label
var all_issues: Array[Dictionary] = []

func _ready() -> void:
	results_list_vbox = find_child("ResultsVBox", true, false) as VBoxContainer
	filter_opt = find_child("FilterOption", true, false) as OptionButton
	status_header = find_child("ValidationStatusLabel", true, false) as Label
	if filter_opt:
		filter_opt.clear()
		filter_opt.add_item("All Issues")
		filter_opt.add_item("Errors Only ()")
		filter_opt.add_item("Warnings Only ()")
		filter_opt.item_selected.connect(func(_i): _populate_list())

func display_results(results: Array[Dictionary]) -> void:
	all_issues = results
	var err_count = 0
	var warn_count = 0
	for r in results:
		if r.get("severity") == WorldValidator.Severity.ERROR: err_count += 1
		elif r.get("severity") == WorldValidator.Severity.WARNING: warn_count += 1
		
	if status_header:
		if err_count == 0 and warn_count == 0:
			status_header.text = " World Validation: 0 Errors, 0 Warnings"
			status_header.modulate = Color.GREEN
		else:
			status_header.text = " Validation: %d Errors, %d Warnings" % [err_count, warn_count]
			status_header.modulate = Color(1.0, 0.4, 0.4) if err_count > 0 else Color(1.0, 0.8, 0.2)
			
	visible = true
	_populate_list()

func _populate_list() -> void:
	if not results_list_vbox: return
	for c in results_list_vbox.get_children():
		c.queue_free()
		
	var filter_idx = filter_opt.selected if filter_opt else 0
	for r in all_issues:
		var sev = r.get("severity", WorldValidator.Severity.INFO)
		if filter_idx == 1 and sev != WorldValidator.Severity.ERROR: continue
		if filter_idx == 2 and sev != WorldValidator.Severity.WARNING: continue
		
		var btn = Button.new()
		var icon_str = " " if sev == WorldValidator.Severity.ERROR else (" " if sev == WorldValidator.Severity.WARNING else "ℹ ")
		btn.text = icon_str + str(r.get("message", ""))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if sev == WorldValidator.Severity.ERROR: btn.modulate = Color(1.0, 0.7, 0.7)
		elif sev == WorldValidator.Severity.WARNING: btn.modulate = Color(1.0, 0.9, 0.6)
		
		var pos = r.get("pos", Vector2i(-1, -1))
		btn.pressed.connect(func():
			if pos.x >= 0: issue_selected.emit(pos)
		)
		results_list_vbox.add_child(btn)
