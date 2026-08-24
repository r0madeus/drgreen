class_name JournalEntry
extends RefCounted

## Data model for codex entries.

var id: String = ""
var name: String = ""
var is_discovered: bool = false
var category: String = "plant" # "plant" or "combination"
var data: Dictionary = {}
