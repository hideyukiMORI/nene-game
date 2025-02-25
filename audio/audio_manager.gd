extends Node

@onready var bgm_player = AudioStreamPlayer.new()

var bgm_volume: float = 0.5
var se_volume: float = 0.5
var sound_enabled: bool = true

var current_bgm: String = ""
var looping_se_players = {}
var active_se_players = []
var bgm_position: float = 0.0

# 音響ファイルのパスを保持
var bgm_paths = {
	"STAGE_01": "res://assets/audio/bgm/stage_01.wav"
}

var se_paths = {
	"START": "res://assets/audio/se/start.wav",
	"PAUSE": "res://assets/audio/se/pause.wav",
	"CURSOR": "res://assets/audio/se/cursor.wav",
	"JUMP": "res://assets/audio/se/jump_02.wav",
	"HIGH_JUMP": "res://assets/audio/se/jump_01.wav",
	"DASH": "res://assets/audio/se/dash_01.wav",
	"COIN": "res://assets/audio/se/coin_01.wav",
	"PUCHI": "res://assets/audio/se/puchi.mp3"
}

func _ready() -> void:
	add_child(bgm_player)
	bgm_player.process_mode = AudioStreamPlayer.PROCESS_MODE_ALWAYS
	set_process(true)
	set_process_priority(0)  # Optional: Set priority if needed

func play_bgm(bgm_key: String) -> void:
	if bgm_key in bgm_paths and current_bgm != bgm_key:
		bgm_player.stop()
		bgm_player.stream = load(bgm_paths[bgm_key])
		bgm_player.volume_db = linear_to_db(bgm_volume)
		bgm_player.play()
		if !sound_enabled:
			bgm_player.stop()
		current_bgm = bgm_key
		bgm_position = 0.0

func stop_bgm() -> void:
	if is_instance_valid(bgm_player):
		bgm_player.stop()
	current_bgm = ""
	bgm_position = 0.0

func pause_bgm() -> void:
	if is_instance_valid(bgm_player) and bgm_player.playing:
		bgm_position = bgm_player.get_playback_position()
		bgm_player.stop()

func resume_bgm() -> void:
	if is_instance_valid(bgm_player) and not bgm_player.playing and current_bgm != "":
		bgm_player.play(bgm_position)

func play_se(se_key: String, loop: bool = false) -> void:
	if sound_enabled and se_key in se_paths:
		var se_player = AudioStreamPlayer.new()
		se_player.stream = load(se_paths[se_key])
		se_player.volume_db = linear_to_db(se_volume)
		add_child(se_player)
		se_player.play()
		active_se_players.append(se_player)
		if loop:
			looping_se_players[se_key] = se_player
		else:
			se_player.connect("finished", Callable(se_player, "queue_free"))

func play_se_with_callback(se_key: String, callback: Callable) -> void:
	if sound_enabled and se_key in se_paths:
		var se_player = AudioStreamPlayer.new()
		se_player.stream = load(se_paths[se_key])
		se_player.volume_db = linear_to_db(se_volume)
		add_child(se_player)
		se_player.play()
		se_player.connect("finished", callback)
		se_player.connect("finished", Callable(se_player, "queue_free"))

func stop_se(se_key: String) -> void:
	if se_key in looping_se_players:
		var se_player = looping_se_players[se_key]
		if se_player:
			se_player.stop()
			se_player.queue_free()
		looping_se_players.erase(se_key)

func stop_all_se() -> void:
	for se_player in active_se_players:
		if is_instance_valid(se_player):
			se_player.stop()
			se_player.queue_free()
	active_se_players.clear()
	looping_se_players.clear()

func pause_se() -> void:
	for se_player in active_se_players:
		if is_instance_valid(se_player) and se_player.playing:
			se_player.stop()

func resume_se() -> void:
	for se_player in active_se_players:
		if is_instance_valid(se_player):
			se_player.play()

func set_bgm_volume(volume: float) -> void:
	bgm_volume = volume
	if is_instance_valid(bgm_player):
		bgm_player.volume_db = linear_to_db(bgm_volume)

func set_se_volume(volume: float) -> void:
	se_volume = volume

func toggle_sound(enabled: bool) -> void:
	sound_enabled = enabled
	if not sound_enabled:
		stop_bgm()
		stop_all_se()
	else:
		# BGMが停止されていた場合に再開
		if not bgm_player.playing:
			bgm_player.play()

func pause_all_with_se() -> void:
	pause_all()
	play_se("PAUSE")

func pause_all() -> void:
	pause_bgm()
	pause_se()

func resume_all() -> void:
	resume_bgm()
	resume_se()

func stop_all() -> void:
	stop_bgm()
	stop_all_se()
