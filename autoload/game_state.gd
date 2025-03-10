extends Node

@export var num_levels: int = 2
@export var current_level: int = 1

@export var game_scene: String = "res://main/main.tscn"
@export var title_screen: String = "res://ui/title_screen.tscn"


func restart() -> void:
	current_level = 1
	var result = get_tree().change_scene_to_file(title_screen)
	if result != OK:
		print("Error: Failed to change scene to title screen")

func next_level() -> void:
	current_level += 1
	if current_level <= num_levels:
		var result = get_tree().reload_current_scene()
		if result != OK:
			print("Error: Failed to reload current scene")