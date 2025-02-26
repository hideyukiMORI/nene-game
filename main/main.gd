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
		if FileAccess.file_exists(path):
			var map = load(path)
			if map:
				add_child(map.instantiate())
			else:
				print("Error: Failed to load level scene: ", path)
		else:
			print("Error: Level scene file not found: ", path)
	else:
		print("Error: Invalid level number: ", level_num)
