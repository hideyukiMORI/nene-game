extends Node


func _ready() -> void:
	var level_num = str(GameState.current_level).pad_zeros(2)
	var path = 'res://levels/level_%s.tscn' % level_num
	var map = load(path).instantiate()
	add_child(map)
