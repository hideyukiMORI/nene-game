extends Control

# Declare the StartSound variable
@onready var start_sound = $StartSound

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select") or event.is_action_pressed("start"):
		# Play the start sound
		start_sound.play()
		# Connect the finished signal to a function to change the scene
		start_sound.connect("finished", Callable(self, "_on_StartSound_finished"))

func _on_StartSound_finished() -> void:
	# Change the scene after the sound has finished playing
	get_tree().change_scene_to_file(GameState.game_scene)