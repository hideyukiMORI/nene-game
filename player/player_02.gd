extends CharacterBody2D

@export var run_speed: int = 350
@export var jump_speed: int = -500
@export var gravity: int = 1000
@export var climb_speed: int = 50
@export var acceleration: int = 800
@export var air_acceleration: int = 5500
@export var max_jumps: int = 2

signal life_changed
signal dead

enum State {IDLE, RUN, JUMP, HURT, DEAD, CROUCH, CLIMB}
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

func start(pos) -> void:
	print("START", pos)
	position = pos
	show()
	life = 3
	emit_signal("life_changed", life)
	change_state(State.IDLE)

func change_state(new_state: State):
	state = new_state
	match state:
		State.IDLE:
			new_anim = "idle"
		State.RUN:
			new_anim = "walk"
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
		if collision.get_collider().is_in_group('enemies'):
			var player_feet = (position + $CollisionShape2D.shape.extents).y
			if player_feet < collision.get_collider().position.y:
				collision.get_collider().take_damage()
				velocity.y = -200
			else:
				hurt()

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
		jump_count = 0  # Reset jump count when on the floor
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

	var target_velocity_x = 0
	if right:
		target_velocity_x += run_speed
		$Sprite2D.flip_h = false
	if left:
		target_velocity_x -= run_speed
		$Sprite2D.flip_h = true

	var current_acceleration = acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, target_velocity_x, current_acceleration * delta)

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

	if jump and (is_on_floor() or coyote_time):
		change_state(State.JUMP)
		velocity.y = jump_speed
		coyote_time = false
		$CoyoteTimer.stop()
		jump_count += 1
		
	elif jump and (!is_on_floor() and !coyote_time and jump_count < max_jumps):
		print("JUMP")
		print("JUMP COUNT", jump_count)
		change_state(State.JUMP)
		velocity.y = jump_speed / 1.5
		jump_count += 1

	# IDLE transitions to RUN when moving
	if state in [State.IDLE, State.CROUCH] and velocity.x != 0:
		change_state(State.RUN)

	# RUN transitions to IDLE when standing still
	if state == State.RUN and velocity.x == 0:
		change_state(State.IDLE)

	# transition to JUMP when falling off an edge
	if state in [State.IDLE, State.RUN] and not is_on_floor():
		change_state(State.JUMP)

	if Input.is_action_pressed("select"):
		get_tree().quit()

func hurt() -> void:
	if state != State.HURT:
		$HurtSound.play()
		change_state(State.HURT)

func _on_CoyoteTimer_timeout() -> void:
	coyote_time = false







# const SPEED = 300.0
# const JUMP_VELOCITY = -400.0


# func _physics_process(delta: float) -> void:
# 	# Add the gravity.
# 	if not is_on_floor():
# 		velocity += get_gravity() * delta

# 	# Handle jump.
# 	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
# 		velocity.y = JUMP_VELOCITY

# 	# Get the input direction and handle the movement/deceleration.
# 	# As good practice, you should replace UI actions with custom gameplay actions.
# 	var direction := Input.get_axis("ui_left", "ui_right")
# 	if direction:
# 		velocity.x = direction * SPEED
# 	else:
# 		velocity.x = move_toward(velocity.x, 0, SPEED)

# 	move_and_slide()
