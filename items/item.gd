extends Area2D

signal pickup

var textures = {
	'coin_01': 'res://assets/sprites/coin_01.png',
	'cherry': 'res://assets/sprites/cherry.png',
	'gem': 'res://assets/sprites/gem.png'
}


func _ready() -> void:
	$AnimationPlayer.play('animation')

func initialize(type: String, pos: Vector2) -> void:
	$Sprite2D.texture = load(textures[type])
	position = pos

func _on_Collectible_body_entered(_body: Node) -> void:
	print('pickup!!!')
	emit_signal('pickup')
	$AnimationPlayer.play('pickup')
	$PickupSound.play()
	await $AnimationPlayer.animation_finished
	queue_free()
