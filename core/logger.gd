extends Node


## Centralized structured logger for Botanical Haven.
## Levels: DEBUG < INFO < WARN < ERROR
## In release builds, DEBUG messages are silently dropped.
##
## Usage:
##   GameLogger.debug("player", "velocity: %v" % str(velocity))
##   GameLogger.info("save", "Game saved to %s" % path)
##   GameLogger.warn("quest", "Quest %s already claimed" % qid)
##   GameLogger.error("world", "World %s not found!" % wid)

enum Level { DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3 }

const LEVEL_NAMES := ["DEBUG", "INFO ", "WARN ", "ERROR"]

## Minimum log level to emit. Raised to INFO automatically in release builds.
var min_level: int = Level.DEBUG

func _ready() -> void:
	if not OS.is_debug_build():
		min_level = Level.INFO

# ---------- Public Static API ----------

static func debug(tag: String, message: String) -> void:
	_emit(Level.DEBUG, tag, message)

static func info(tag: String, message: String) -> void:
	_emit(Level.INFO, tag, message)

static func warn(tag: String, message: String) -> void:
	_emit(Level.WARN, tag, message)

static func error(tag: String, message: String) -> void:
	_emit(Level.ERROR, tag, message)

# ---------- Internal ----------

static func _emit(level: int, tag: String, message: String) -> void:
	var effective_min: int = Level.DEBUG if OS.is_debug_build() else Level.INFO
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop.root:
		var gl = main_loop.root.get_node_or_null("/root/GameLogger")
		if gl: effective_min = gl.min_level

	if level < effective_min:
		return

	var lvl_str: String = LEVEL_NAMES[level] if level < LEVEL_NAMES.size() else "?????"
	var line: String = "[%s] [%s] %s" % [lvl_str, tag.to_upper(), message]

	match level:
		Level.WARN:
			push_warning(line)
		Level.ERROR:
			push_error(line)
		_:
			print(line)
