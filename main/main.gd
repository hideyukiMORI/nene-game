extends Node

# シーン番号とパスの辞書
var level_paths = {
	1: "res://levels/level_01.tscn",
	2: "res://levels/level_02.tscn",
	# 他のレベルもここに追加
}

func _ready() -> void:
	var level_num = GameState.current_level
	if level_num in level_paths:
		var path = level_paths[level_num]
		var scene = load(path)
		if scene:
			add_child(scene.instantiate())
		else:
			print("Error: Failed to load level scene")
	else:
		print("Error: Invalid level number: ", level_num)

	# シーンが読み込まれたら、保存されていたスポーン位置にプレイヤーを配置
	var spawn_point_name = GameState.last_spawn_point
	if not spawn_point_name.is_empty():
		call_deferred("_place_player_at_spawn", spawn_point_name)

func _place_player_at_spawn(spawn_name: String) -> void:
	var spawn_point = find_child(spawn_name, true, false)
	var player = find_child("Player", true, false)
	
	if spawn_point and player:
		player.global_position = spawn_point.global_position
	else:
		push_error("Could not find spawn point or player")
