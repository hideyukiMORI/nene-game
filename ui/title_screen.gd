extends Control

# Declare the StartSound variable
@onready var settings_panel = $SettingPanel


func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_select") or event.is_action_pressed("start")) and not settings_panel.visible:
		# Start sound and change scene when finished
		if AudioManager.sound_enabled:
			AudioManager.play_se_with_callback("START", Callable(self, "_on_start_sound_finished"))
		else:
			get_tree().change_scene_to_file(GameState.game_scene)

func _on_start_sound_finished() -> void:
	var result = get_tree().change_scene_to_file(GameState.game_scene)
	if result != OK:
		print("Error: Failed to change scene to game scene")