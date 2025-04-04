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

func _ready() -> void:
	pass

func restart() -> void:
	change_scene("title")

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