extends CharacterBody2D

@export var speed: int = 10
@export var gravity: int = 900
var facing: int = 1

func _physics_process(delta: float) -> void:
	$Sprite2D.flip_h = velocity.x < 0
	velocity.y += gravity * delta
	velocity.x = facing * speed
	move_and_slide()
	
	for idx in range(get_slide_collision_count()):
		var collision = get_slide_collision(idx)
		if collision.get_collider().name == 'Player':
			collision.get_collider().hurt()
		if collision.get_normal().x != 0:
			facing = sign(collision.get_normal().x)
			velocity.y = -100
	
	# Check if there is no floor ahead using intersect_ray
	if is_on_floor():
		var floor_check_start = position + Vector2(0, $CollisionShape2D.shape.extents.y)
		var floor_check_end = floor_check_start + Vector2(facing * $CollisionShape2D.shape.extents.x * 2, 10)
		var space_state = get_world_2d().direct_space_state
		var ray_params = PhysicsRayQueryParameters2D.new()
		ray_params.from = floor_check_start
		ray_params.to = floor_check_end
		ray_params.exclude = [self]
		var result = space_state.intersect_ray(ray_params)
		if not result.has("position"):
			facing = -facing

	if position.y > 1000:
		queue_free()

func take_damage():
	# $HitSound.play()
	AudioManager.play_se("PUCHI")
	$AnimationPlayer.play('death')
	$CollisionShape2D.set_disabled(true)
	set_physics_process(false)

func _on_animation_player_animation_finished(anim_name:StringName) -> void:
	if anim_name == 'death':
		queue_free()
