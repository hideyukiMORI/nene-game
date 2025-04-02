extends CharacterBody2D

# @export var walk_speed: int = 350
@export var dash_speed: int = 350
@export var dash_trail_ground_start_speed: int = 400
@export var dash_trail_ground_end_speed: int = 355
@export var dash_trail_air_speed: int = 800
@export var dash_trail_air_end_speed: int = 350
@export var jump_speed: int = -500
@export var gravity: int = 1000
@export var climb_speed: int = 50
@export var acceleration: int = 800
@export var air_acceleration: int = 5500
@export var max_jumps: int = 2

signal life_changed
signal dead

enum State {IDLE, WALK, DASH, JUMP, HURT, DEAD, CROUCH, CLIMB}
var state: State = State.IDLE
var anim: String = ""
var new_anim: String = ""
var life: int = 3
var jump_count: int = 0
var is_on_ladder: bool = false
var coyote_time: bool = false
var bounce_grace_time: float = 0.1
var bounce_timer: float = 0.0

func _ready() -> void:
	change_state(State.IDLE)
	position.x = 550
	position.y = 200
	$CoyoteTimer.wait_time = 0.2
	$CoyoteTimer.connect("timeout", Callable(self, "_on_CoyoteTimer_timeout"))

func reset(pos) -> void:
	print("START", pos)
	position = pos
	show()
	life = 3
	emit_signal("life_changed", life)
	change_state(State.IDLE)

func change_state(new_state: State):
	if state == State.DASH and new_state != State.DASH:
		AudioManager.stop_se("DASH")
	if state != new_state:
		state = new_state
		match state:
			State.IDLE:
				play_animation("idle")
			State.WALK:
				play_animation("walk")
			State.DASH:
				play_animation("dash")
				AudioManager.play_se("DASH", true)
			State.CROUCH:
				play_animation("crouch")
			State.HURT:
				play_animation("hurt")
				velocity.y = -200
				velocity.x = -100 * sign(velocity.x)
				life -= 1
				emit_signal('life_changed', life)
				await get_tree().create_timer(0.5).timeout
				change_state(State.IDLE)
				if life <= 0:
					change_state(State.DEAD)
			State.JUMP:
				play_animation("jump_up")
			State.CLIMB:
				play_animation("climb")
			State.DEAD:
				emit_signal('dead')
				hide()

func play_animation(animation_name: String) -> void:
	anim = animation_name
	new_anim = animation_name
	$AnimationPlayer.play(animation_name)

func _physics_process(delta: float) -> void:
	if state != State.CLIMB:
		velocity.y += gravity * delta
	get_input(delta)
	
	# ダッシュの残像エフェクト処理
	var speed = velocity.length()  # x と y の合成速度を計算
	var dash = Input.is_action_pressed("dash")

	print("SPEED :: ", speed)
	print("DASH TRAIL GROUND END SPEED :: ", dash_trail_ground_end_speed)
	print("is_on_floor :: ", is_on_floor())
	print("emitting :: ", $DashTrail.emitting)
	print("result :: ", is_on_floor() and not $DashTrail.emitting and speed > dash_trail_ground_start_speed)

	if is_on_floor():
		# 地上での処理
		if not $DashTrail.emitting:
			# 残像が出ていない状態で、ダッシュボタンを押していて、速度が閾値を超えたら開始
			if dash and speed > dash_trail_ground_start_speed:
				$DashTrail.emitting = true
				update_particle_direction()
		else:
			# 残像が出ている状態で、速度が閾値以下になったら終了（ダッシュボタンの状態は関係なし）
			if speed < dash_trail_ground_end_speed:
				$DashTrail.emitting = false
	else:
		# 空中での処理（変更なし）
		if not $DashTrail.emitting and speed > dash_trail_air_speed:
			$DashTrail.emitting = true
			update_particle_direction()
		elif $DashTrail.emitting and speed < dash_trail_air_end_speed:
			$DashTrail.emitting = false

	# ジャンプ下降時のアニメーション
	if state == State.JUMP and velocity.y > 0:
		play_animation("jump_down")
	
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
		$Dust.emitting = true  # パーティクル処理を先に実行
		# 移動入力がある場合
		if Input.is_action_pressed("right") or Input.is_action_pressed("left"):
			if Input.is_action_pressed("dash"):
				change_state(State.DASH)
			else:
				change_state(State.WALK)
		else:
			change_state(State.IDLE)

	if position.y > 1000:
		change_state(State.DEAD)

	if is_on_floor():
		bounce_timer = bounce_grace_time
		$CoyoteTimer.stop()
		coyote_time = true
		jump_count = 0
		
		# 速度に基づく残像処理は、DASH状態の時のみ行う
		if state == State.DASH and abs(velocity.x) > dash_speed:
			$DashTrail.emitting = true
	else:
		bounce_timer = max(0, bounce_timer - delta)
		if !$CoyoteTimer.is_stopped():
			$CoyoteTimer.start()

	if state in [State.IDLE, State.WALK, State.DASH] and not is_on_floor() and bounce_timer <= 0:
		change_state(State.JUMP)

	if state in [State.IDLE, State.WALK, State.DASH] and not is_on_floor():
		change_state(State.JUMP)

	# if Input.is_action_pressed("select"):
	# 	get_tree().quit()

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
		target_velocity_x += dash_speed
		$Sprite2D.flip_h = false
	if left:
		target_velocity_x -= dash_speed
		$Sprite2D.flip_h = true

	if dash:
		target_velocity_x *= 2

	var current_acceleration = acceleration if is_on_floor() else air_acceleration

	# 空中での慣性制御
	if not is_on_floor():
		if not (right or left):
			# 入力がない場合は、現在の速度からゆっくり減速
			target_velocity_x = velocity.x * 0.95  # 空中での減速率
		else:
			# 入力がある場合は、方向転換を可能に
			current_acceleration = air_acceleration * 1  # 空中での方向転換をより自然に
	
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
			AudioManager.play_se("JUMP")
			change_state(State.JUMP)
			velocity.y = jump_speed
			coyote_time = false
			$CoyoteTimer.stop()
			jump_count += 1
				
		elif !is_on_floor() and !coyote_time and jump_count < max_jumps:
			AudioManager.play_se("HIGH_JUMP")
			change_state(State.JUMP)
			velocity.y = jump_speed / 1.5
			jump_count += 1

		elif is_on_wall():
			AudioManager.play_se("JUMP")
			change_state(State.JUMP)
			velocity.y = jump_speed
			velocity.x = -target_velocity_x
			jump_count += 1

	if state in [State.IDLE, State.CROUCH] and velocity.x != 0:
		change_state(State.WALK)

	# 速度に基づく状態遷移
	if state == State.DASH and abs(velocity.x) <= dash_speed:
		change_state(State.WALK)  # 速度がしきい値以下ならWALK
	elif state == State.WALK and abs(velocity.x) > dash_speed and dash:
		change_state(State.DASH)  # 速度がしきい値を超えていて、かつdashボタンが押されている場合のみDASH

	# 完全停止時の処理
	if state in [State.DASH, State.WALK] and abs(velocity.x) < 0.1:  # 微小な速度も考慮
		change_state(State.IDLE)

func hurt() -> void:
	# if state != State.HURT:
		# $HurtSound.play()
		# change_state(State.HURT)
	pass

func _on_CoyoteTimer_timeout() -> void:
	coyote_time = false

func update_particle_direction():
	# プレイヤーの向きに応じてパーティクルの方向を設定
	var particle_material = $DashTrail.process_material as ParticleProcessMaterial
	if $Sprite2D.flip_h:
		particle_material.direction = Vector3(-1, 0, 0)  # 左を向いているとき
		$DashTrail.position.x = 14  # 右を向いているとき
		# $DashTrail.rotation_degrees = 0
		$DashTrail.skew = 18.5
	else:
		particle_material.direction = Vector3(1, 0, 0)  # 右を向いているとき
		$DashTrail.position.x = -14  # 左を向いているとき
		# $DashTrail.rotation_degrees = -180
		$DashTrail.skew = -18.5
