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
	if type in textures:
		var texture = load(textures[type])
		if texture:
			$Sprite2D.texture = texture
		else:
			print("Error: Failed to load texture for type: ", type)
	else:
		print("Error: Invalid item type: ", type)
	position = pos

func _on_Collectible_body_entered(_body: Node) -> void:
	# print('pickup!!!')
	emit_signal('pickup')
	$AnimationPlayer.play('pickup')
	# $PickupSound.play()
	AudioManager.play_se("COIN")
	await $AnimationPlayer.animation_finished
	queue_free()
