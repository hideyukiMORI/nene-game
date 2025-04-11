extends Area2D

@export var damage: float = 10.0

func _ready() -> void:
	pass # Replace with function body.


func _process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.hurt(damage)  # 設定されたダメージ量を渡す
