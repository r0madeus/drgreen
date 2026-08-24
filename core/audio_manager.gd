extends Node

## Central Audio Manager handling sound effects, ambient audio, volume buses, music and sound overrides.


enum Bus { MASTER, MUSIC, SFX, AMBIENT, UI }

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.8
var ambient_volume: float = 0.8

var _sfx_cache: Dictionary = {}
var _sound_overrides: Dictionary = {} # sfx_id -> AudioStream
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer = null
var _ambient_player: AudioStreamPlayer = null

const MAX_SFX_PLAYERS = 12

# Stable ID mapping to physical sound paths or aliases
const SOUND_MAP = {
	# UI Sounds
	"ui.select": "res://assets/audio/sfx/ui_select.wav",
	"ui.open": "res://assets/audio/sfx/ui_open.wav",
	"ui.close": "res://assets/audio/sfx/ui_close.wav",
	"ui_select": "res://assets/audio/sfx/ui_select.wav",
	"ui_open": "res://assets/audio/sfx/ui_open.wav",
	"ui_close": "res://assets/audio/sfx/ui_close.wav",
	"shop_open": "res://assets/audio/sfx/shop_open.wav",
	"ui.shop_open": "res://assets/audio/sfx/shop_open.wav",
	"ui.shop_close": "res://assets/audio/sfx/shop_close.wav",
	"ui.invalid_action": "res://assets/audio/sfx/insufficient_gold.wav",
	"invalid_action": "res://assets/audio/sfx/insufficient_gold.wav",

	
	# Farming & Tools
	"farming.water": "res://assets/audio/sfx/water.wav",
	"farming.plant": "res://assets/audio/sfx/plant.wav",
	"farming.harvest": "res://assets/audio/sfx/harvest.wav",
	"farming.hoe": "res://assets/audio/sfx/plant.wav",
	"farming.fertilize": "res://assets/audio/sfx/combine.wav",
	"water": "res://assets/audio/sfx/water.wav",
	"plant": "res://assets/audio/sfx/plant.wav",
	"harvest": "res://assets/audio/sfx/harvest.wav",
	
	# Economy & Lab
	"economy.buy": "res://assets/audio/sfx/buy.wav",
	"economy.sell": "res://assets/audio/sfx/sell.wav",
	"economy.upgrade": "res://assets/audio/sfx/upgrade_purchase.wav",
	"economy.error": "res://assets/audio/sfx/insufficient_gold.wav",
	"buy": "res://assets/audio/sfx/buy.wav",
	"sell": "res://assets/audio/sfx/sell.wav",
	"upgrade_purchase": "res://assets/audio/sfx/upgrade_purchase.wav",
	"insufficient_gold": "res://assets/audio/sfx/insufficient_gold.wav",
	"lab.combine": "res://assets/audio/sfx/combine.wav",
	"lab.discovery": "res://assets/audio/sfx/discovery.wav",
	"combine": "res://assets/audio/sfx/combine.wav",
	"discovery": "res://assets/audio/sfx/discovery.wav",
	
	# Dialogue & Quests
	"dialogue.open": "res://assets/audio/sfx/dialogue_open.wav",
	"dialogue.next": "res://assets/audio/sfx/dialogue_next.wav",
	"dialogue_open": "res://assets/audio/sfx/dialogue_open.wav",
	"dialogue_next": "res://assets/audio/sfx/dialogue_next.wav",
	"quest.accept": "res://assets/audio/sfx/quest_accept.wav",
	"quest.complete": "res://assets/audio/sfx/quest_complete.wav",
	"quest_accept": "res://assets/audio/sfx/quest_accept.wav",
	"quest_complete": "res://assets/audio/sfx/quest_complete.wav",
	"reward": "res://assets/audio/sfx/reward.wav",
	"quest.reward": "res://assets/audio/sfx/reward.wav",
	
	# World & Seasons
	"world.gate_open": "res://assets/audio/sfx/gate_open.wav",
	"world.greenhouse_repair": "res://assets/audio/sfx/greenhouse_repair.wav",
	"world.season_transition": "res://assets/audio/sfx/season_transition.wav",
	"gate_open": "res://assets/audio/sfx/gate_open.wav",
	"greenhouse_repair": "res://assets/audio/sfx/greenhouse_repair.wav",
	"season_transition": "res://assets/audio/sfx/season_transition.wav",
	"ambient.rain": "res://assets/audio/sfx/rain_ambient.wav",
	"ambient.snow": "res://assets/audio/sfx/snow_wind.wav"
}

func _ready() -> void:
	# Pool of AudioStreamPlayers to prevent audio clipping during rapid actions
	for i in range(MAX_SFX_PLAYERS):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		add_child(p)
		_sfx_players.append(p)
		
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)
	
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	add_child(_ambient_player)
	
	# Load volume from LocalStateManager if available
	var lsm = get_node_or_null("/root/LocalStateManager")
	if lsm:
		master_volume = float(lsm.get_setting("audio", "master_volume", 1.0))
		sfx_volume = float(lsm.get_setting("audio", "sfx_volume", 1.0))
		music_volume = float(lsm.get_setting("audio", "music_volume", 0.8))

# ==============================================================================
# RUNTIME SOUND OVERRIDE API (FOR ASSET SWAPPING / MODDING)
# ==============================================================================

func register_sound_override(sound_id: String, stream: AudioStream) -> void:
	if stream:
		_sound_overrides[sound_id] = stream

func remove_sound_override(sound_id: String) -> void:
	_sound_overrides.erase(sound_id)

func clear_sound_overrides() -> void:
	_sound_overrides.clear()

func has_sound_override(sound_id: String) -> bool:
	return _sound_overrides.has(sound_id)

# ==============================================================================
# PLAYBACK APIS
# ==============================================================================

func play_sfx(sound_id: String, pitch_variance: float = 0.04, volume_offset_db: float = 0.0) -> void:
	if sfx_volume <= 0.0 or master_volume <= 0.0:
		return
		
	var stream = get_sound_stream(sound_id)
	if not stream:
		return
		
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(sfx_volume * master_volume) + volume_offset_db
			player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
			player.play()
			return

func play_music(music_id: String, loop: bool = true) -> void:
	if not _music_player: return
	if music_volume <= 0.0 or master_volume <= 0.0:
		_music_player.stop()
		return
		
	var stream = get_sound_stream(music_id)
	if not stream:
		# Fallback: quiet ambient stream
		stream = get_sound_stream("ambient.rain")
		
	if stream:
		_music_player.stream = stream
		_music_player.volume_db = linear_to_db(music_volume * master_volume)
		_music_player.play()

func stop_music() -> void:
	if _music_player: _music_player.stop()

func get_sound_stream(sound_id: String) -> AudioStream:
	if _sound_overrides.has(sound_id):
		return _sound_overrides[sound_id]
		
	if _sfx_cache.has(sound_id):
		return _sfx_cache[sound_id]
		
	var path = ""
	if SOUND_MAP.has(sound_id):
		path = SOUND_MAP[sound_id]
	elif sound_id.begins_with("res://"):
		path = sound_id
	else:
		path = "res://assets/audio/sfx/%s.wav" % sound_id
		
	if ResourceLoader.exists(path):
		var stream = ResourceLoader.load(path) as AudioStream
		if stream:
			_sfx_cache[sound_id] = stream
			return stream
	return null

# ==============================================================================
# VOLUME CONTROLS
# ==============================================================================

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)
	if _music_player and _music_player.playing:
		_music_player.volume_db = linear_to_db(music_volume * master_volume)

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)

func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	if _music_player and _music_player.playing:
		_music_player.volume_db = linear_to_db(music_volume * master_volume)

