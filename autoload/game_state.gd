extends Node

# シーンのパス定義
const SCENES = {
	"title": "res://ui/title_screen.tscn",
	"level_01": "res://levels/level_01.tscn",
	"cave_entrance": "res://scenes/cave_entrance.tscn",
	"underground_lake": "res://scenes/underground_lake.tscn",
	"crystal_cavern": "res://scenes/crystal_cavern.tscn",
	# 他のシーンもここに追加
}

# 現在のシーン名
var current_scene: String = "title"
var last_spawn_point: String = ""

# デフォルトのスポーン位置名（シーンごとに設定可能）
var default_spawn_points = {
	"level_01": "StartPoint",
	"cave_entrance": "MainEntrance",
	"underground_lake": "LakeEntrance",
	"crystal_cavern": "CavernEntrance",
}

func change_scene(scene_name: String, spawn_point: String = "") -> void:
	if not SCENES.has(scene_name):
		push_error("Invalid scene name: " + scene_name)
		return
		
	current_scene = scene_name
	
	# スポーン位置が指定されていない場合はデフォルトを使用
	if spawn_point.is_empty():
		spawn_point = default_spawn_points.get(scene_name, "DefaultSpawn")
	
	# シーン変更前に現在のスポーン位置を保存（必要に応じて）
	GameState.last_spawn_point = spawn_point
	
	var result = get_tree().change_scene_to_file(SCENES[scene_name])
	if result != OK:
		push_error("Failed to change scene to: " + scene_name)

func restart() -> void:
	change_scene("title")
