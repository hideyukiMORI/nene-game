extends Node2D

@export var flip_h: bool = false:
	set(value):
		flip_h = value
		$Control/Sprite2D.flip_h = value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Control/Sprite2D.flip_h = flip_h


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func on_active() -> void:
	print("ACTIVE!!")
	$Control/Label.add_theme_color_override("font_color", Color(0.5, 0, 0))  # Bordeaux color

func on_inactive() -> void:
	print("INACTIVE!!")
	$Control/Label.add_theme_color_override("font_color", Color(0, 0, 0))  # Reset to white color
