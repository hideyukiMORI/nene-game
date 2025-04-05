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

# セーブデータのキー
const SAVE_KEY_SCORE = "score"
const SAVE_KEY_SCENE = "current_scene"

func _ready() -> void:
	pass
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
		SAVE_KEY_SCENE: current_scene
	}
	# TODO: セーブデータの保存処理

func load_game_state() -> void:
	# TODO: セーブデータの読み込み処理
	pass
