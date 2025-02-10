extends Area2D

signal pickup

var textures = {
	'cherry': 'res://assets/sprites/cherry.png',
	'gem': 'res://assets/sprites/gem.png'
}

func initialize(type: String, pos: Vector2) -> void:
	$Sprite2D.texture = load(textures[type])
	position = pos

func _on_Collectible_body_entered(_body: Node) -> void:
	emit_signal('pickup')
	queue_free()
