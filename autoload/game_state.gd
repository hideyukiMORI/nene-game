extends Node

# シーンのパス定義
const SCENES = {
	"title": "res://ui/title_screen.tscn",
	"level_01": "res://levels/level_01.tscn",
	"cave_entrance": "res://scenes/cave_entrance.tscn"
}

# 現在のシーン名
var current_scene: String = "title"

# デフォルトのスポーン位置名（シーンごとに設定可能）
var default_spawn_points = {
	"level_01": "StartPoint",
	"cave_entrance": "MainEntrance"
}

# ゲームの状態管理
var score: int = 0
signal score_changed(value: int)

# 言語設定
var current_language: String = "en"
signal language_changed(language: String)

# セーブデータのキー
const SAVE_KEY_SCORE = "score"
const SAVE_KEY_SCENE = "current_scene"
const SAVE_KEY_LANGUAGE = "language"

func _ready() -> void:
	_load_settings()
	# セーブデータの読み込み（将来的に実装）
	# load_game_state()

func restart() -> void:
	change_scene("title")
	reset_score()

func change_scene(scene_name: String, spawn_point: String = "") -> void:
	print("change_scene: " + scene_name)
	if not SCENES.has(scene_name):
		push_error("Invalid scene name: " + scene_name)
		return
		
	current_scene = scene_name
	
	# スポーン位置が指定されていない場合はデフォルトを使用
	if spawn_point.is_empty():
		spawn_point = default_spawn_points.get(scene_name, "DefaultSpawn")
	
	get_tree().change_scene_to_file(SCENES[scene_name])

# スコア管理
func set_score(value: int) -> void:
	score = value
	score_changed.emit(score)

func add_score(value: int) -> void:
	score += value
	score_changed.emit(score)

func reset_score() -> void:
	score = 0
	score_changed.emit(score)

# セーブ/ロード機能（将来的に実装）
func save_game_state() -> void:
	var save_data = {
		SAVE_KEY_SCORE: score,
		SAVE_KEY_SCENE: current_scene,
		SAVE_KEY_LANGUAGE: current_language
	}
	# TODO: セーブデータの保存処理

func load_game_state() -> void:
	# TODO: セーブデータの読み込み処理
	pass
func set_language(language: String) -> void:
	if language != current_language:
		current_language = language
		language_changed.emit(language)
		_save_settings()

func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		var language_value = config.get_value("language", "current", current_language)  # デフォルト値を現在の言語に変更
		# 型を確認して適切に変換
		var language: String
		if language_value is int:
			# int型の場合はインデックスとして扱う
			language = "en" if language_value == 0 else "ja"
		elif language_value is String:
			# String型の場合はそのまま使用
			language = language_value
		else:
			# その他の型の場合は現在の言語設定を維持
			language = current_language
		
		# 有効な言語かチェック
		if not (language == "en" or language == "ja"):
			# 無効な値の場合は現在の言語設定を維持
			language = current_language
		
		# 言語が変更された場合のみ更新
		if language != current_language:
			current_language = language
			language_changed.emit(current_language)

func _save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("language", "current", current_language)
	config.save("user://settings.cfg")

# ゲームの状態を完全にリセットする
func reset_game_state() -> void:
	score = 0
	score_changed.emit(score)
	PlayerStats.reset_health()
	# 将来的に追加する可能性のある他のリセット処理
	# - アイテムの状態
	# - 敵の配置
	# - ステージの状態
	# - プレイヤーの位置
	# - その他のゲーム変数
