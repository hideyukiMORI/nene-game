extends CharacterBody2D

@export var run_speed: int = 350
@export var dash_speed: int = 700  # New export variable for dash speed
@export var jump_speed: int = -500
@export var gravity: int = 1000
@export var climb_speed: int = 50
@export var acceleration: int = 800
@export var air_acceleration: int = 5500
@export var max_jumps: int = 2

signal life_changed
signal dead

enum State {IDLE, WALK, RUN, JUMP, HURT, DEAD, CROUCH, CLIMB}
var state: State = State.IDLE
var anim: String = ""
var new_anim: String = ""
var life: int = 3
var jump_count: int = 0
var is_on_ladder: bool = false
var coyote_time: bool = false

func _ready() -> void:
	# $Camera2D.make_current()
	change_state(State.IDLE)
	position.x = 550
	position.y = 200
	$CoyoteTimer.wait_time = 0.2  # Adjust this value as needed
	$CoyoteTimer.connect("timeout", Callable(self, "_on_CoyoteTimer_timeout"))

func reset(pos) -> void:
	print("START", pos)
	position = pos
	show()
	life = 3
	emit_signal("life_changed", life)
	change_state(State.IDLE)

func change_state(new_state: State):
	if state == State.RUN and new_state != State.RUN:
		$DashSound.stop()  # Stop the dash sound when leaving RUN state

	state = new_state
	match state:
		State.IDLE:
			new_anim = "idle"
		State.WALK:
			new_anim = "walk"
		State.RUN:
			new_anim = "run"
			$DashSound.play()  # Play the dash sound when entering RUN state
		State.CROUCH:
			new_anim = 'crouch'
		State.HURT:
			new_anim = 'hurt'
			velocity.y = -200
			velocity.x = -100 * sign(velocity.x)
			life -= 1
			emit_signal('life_changed', life)
			await get_tree().create_timer(0.5).timeout
			change_state(State.IDLE)
			if life <= 0:
				change_state(State.DEAD)
		State.JUMP:
			new_anim = 'jump_up'
		State.CLIMB:
			new_anim = 'climb'
		State.DEAD:
			emit_signal('dead')
			hide()

func _physics_process(delta: float) -> void:
	if state != State.CLIMB:
		velocity.y += gravity * delta
	get_input(delta)
		
	if new_anim != anim:
		anim = new_anim
		$AnimationPlayer.play(anim)
	move_and_slide()
	if state == State.HURT:
		return
	
	for idx in range(get_slide_collision_count()):
		var collision = get_slide_collision(idx)
		if collision.get_collider().name == 'Danger':
			hurt()
		# print("COLLISION :: ", collision.get_collider().name)
		if collision.get_collider().is_in_group('enemies'):
			# print("POSITION :: ", position)
			var player_feet = (position + $CollisionShape2D.shape.extents).y
			# print("PLAYER FEET :: ", player_feet)
			# print("ENEMY POSITION :: ", collision.get_collider().position)
			if player_feet < collision.get_collider().position.y:
				collision.get_collider().take_damage()
				velocity.y = -200
			else:
				hurt()

		var normal = collision.get_normal()
		var angle = rad_to_deg(acos(normal.dot(Vector2.UP)))
		if angle > 20:
			# Slide down if the angle is greater than 30 degrees
			velocity.x += normal.x * gravity * delta * 2  # Increase the multiplier for faster sliding

	if state == State.JUMP and is_on_floor():
		change_state(State.IDLE)
		$Dust.emitting = true
	if state == State.JUMP and velocity.y > 0:
		new_anim = 'jump_down'
	if position.y > 1000:
		change_state(State.DEAD)

	if is_on_floor():
		$CoyoteTimer.stop()
		coyote_time = true
		jump_count = 0
	else:
		if !$CoyoteTimer.is_stopped():
			$CoyoteTimer.start()

func get_input(delta: float):
	if state == State.HURT:
		return

	var right = Input.is_action_pressed("right")
	var left = Input.is_action_pressed("left")
	var jump = Input.is_action_just_pressed("jump")
	var down = Input.is_action_pressed("crouch")
	var climb = Input.is_action_pressed("climb")
	var dash = Input.is_action_pressed("dash")

	var target_velocity_x = 0
	if right:
		target_velocity_x += run_speed
		$Sprite2D.flip_h = false
	if left:
		target_velocity_x -= run_speed
		$Sprite2D.flip_h = true

	if dash:
		target_velocity_x *= 2

	var current_acceleration = acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, target_velocity_x, current_acceleration * delta)

	if is_on_floor():
		for idx in range(get_slide_collision_count()):
			var collision = get_slide_collision(idx)
			var normal = collision.get_normal()
			var angle = rad_to_deg(acos(normal.dot(Vector2.UP)))
			if angle > 20 and angle < 50:
				if right or left:
					velocity.y = -10
					var climb_speed_factor = 1 - ((angle - 30) / 40)
					velocity.x -= normal.x * gravity * delta * climb_speed_factor * 0.2

	if climb and state != State.CLIMB and is_on_ladder:
		change_state(State.CLIMB)
	if state == State.CLIMB:
		if climb:
			velocity.y = -climb_speed
		elif down:
			velocity.y = climb_speed
		else:
			velocity.y = 0
			$AnimationPlayer.play("climb")
	if state == State.CLIMB and not is_on_ladder:
		change_state(State.IDLE)
	if down and is_on_floor():
		change_state(State.CROUCH)
	if !down and state == State.CROUCH:
		change_state(State.IDLE)

	if jump:
		if is_on_floor() or coyote_time:
			$JumpSound.play()
			change_state(State.JUMP)
			velocity.y = jump_speed
			coyote_time = false
			$CoyoteTimer.stop()
			jump_count += 1
				
		elif !is_on_floor() and !coyote_time and jump_count < max_jumps:
			$HighJumpSound.play()
			change_state(State.JUMP)
			velocity.y = jump_speed / 1.5
			jump_count += 1

		elif is_on_wall():
			$JumpSound.play()
			change_state(State.JUMP)
			velocity.y = jump_speed
			velocity.x = -target_velocity_x
			jump_count += 1

	if state in [State.IDLE, State.CROUCH] and velocity.x != 0:
		change_state(State.WALK)

	if state == State.WALK and abs(velocity.x) > run_speed:
		change_state(State.RUN)
	if state == State.RUN and abs(velocity.x) <= run_speed:
		change_state(State.WALK)

	if state == State.RUN and !dash and (right or left):
		change_state(State.WALK)

	if state in [State.RUN, State.WALK] and velocity.x == 0:
		change_state(State.IDLE)

	if state in [State.IDLE, State.WALK, State.RUN] and not is_on_floor():
		change_state(State.JUMP)

	if Input.is_action_pressed("select"):
		get_tree().quit()

func hurt() -> void:
	# if state != State.HURT:
		# $HurtSound.play()
		# change_state(State.HURT)
	pass

func _on_CoyoteTimer_timeout() -> void:
	coyote_time = false






