extends CharacterBody2D

# @export var walk_speed: int = 350
@export var dash_speed: int = 330
@export var dash_trail_ground_start_speed: int = 400
@export var dash_trail_ground_end_speed: int = 331
@export var dash_trail_air_speed: int = 800
@export var dash_trail_air_end_speed: int = 300
@export var jump_speed: int = -500
@export var gravity: int = 1000
@export var climb_speed: int = 80
@export var acceleration: int = 800
@export var air_acceleration: int = 5500
@export var max_jumps: int = 2
@export var fast_fall_speed: int = 1200 # 垂直落下時の速度（より速く）
@export var fast_fall_gravity: int = 3000 # 垂直落下時の重力（より強く）
@export var fast_fall_delay: float = 0.1 # 垂直落下開始までの遅延
@export var trail_interval: float = 0.1 # 残像の生成間隔（より広く）
@export var min_fall_height: float = 100.0 # パーティクルが大きくなる最小落下距離

signal life_changed
signal dead

enum State {IDLE, WALK, DASH, JUMP, HURT, DEAD, CROUCH, CLIMB, CLIMB_IDLE}
var state: State = State.IDLE
var anim: String = ""
var new_anim: String = ""
var life: int = 3
var jump_count: int = 0
var is_on_ladder: bool = false
var coyote_time: bool = false
var bounce_grace_time: float = 0.1
var bounce_timer: float = 0.0
var was_dashing_on_ground: bool = false
var is_trail_active: bool = false
var trail_timer: float = 0.0 # 残像生成用のタイマー
var fast_fall_timer: float = 0.0
var is_fast_falling: bool = false
var trail_sprites: Array = [] # 残像スプライトを保持
var last_trail_time: float = 0.0 # 最後に残像を生成した時間
var fall_start_y: float = 0.0 # 落下開始時のY座標
var last_ground_y: float = 0.0 # 最後に地面にいた時のY座標
var is_falling: bool = false # 落下フラグ

# カメラ揺れ用の変数を追加
var is_camera_shaking: bool = false
var shake_amount: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_camera_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	change_state(State.IDLE)
	position.x = 550
	position.y = 200
	$CoyoteTimer.wait_time = 0.2
	$CoyoteTimer.connect("timeout", Callable(self, "_on_CoyoteTimer_timeout"))
	last_ground_y = position.y # 初期位置を記録

func reset(pos) -> void:
	print("START", pos)
	position = pos
	last_ground_y = pos.y # リセット時に新しい位置を記録
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
			State.CLIMB_IDLE:
				play_animation("climb_idle")
			State.DEAD:
				emit_signal('dead')
				hide()

func play_animation(animation_name: String) -> void:
	anim = animation_name
	new_anim = animation_name
	$AnimationPlayer.play(animation_name)

func _physics_process(delta: float) -> void:
	if is_camera_shaking:
		if state != State.CROUCH:
			change_state(State.CROUCH)
		return

	var objects = get_parent().get_node("Objects")
	# 梯子の判定は上ボタンが押された時とCLIMB状態の時のみ行う
	if (Input.is_action_just_pressed("climb") or state == State.CLIMB or state == State.CLIMB_IDLE) and objects:
		# プレイヤーの判定位置を調整（より広い範囲で判定）
		var player_top = position + Vector2(0, -16)  # 上部の判定位置
		var player_bottom = position + Vector2(0, 0)  # 下部の判定位置
		print("PLAYER TOP: ", player_top)
		print("PLAYER BOTTOM: ", player_bottom)
		is_on_ladder = check_ladder_tile(objects, player_top) or check_ladder_tile(objects, player_bottom)
	else:
		is_on_ladder = false

	# 上ボタンが押された時
	if Input.is_action_just_pressed("climb") and is_on_ladder:
		change_state(State.CLIMB)
		velocity.y = 0 # 梯子に掴まった瞬間の速度をリセット
		
	# CLIMB状態の時、梯子から離れたら状態を変更
	if state == State.CLIMB and not is_on_ladder:
		if is_on_floor():
			change_state(State.IDLE)
		else:
			change_state(State.JUMP)
	
	if state != State.CLIMB and state != State.CLIMB_IDLE:
		velocity.y += gravity * delta
	
	# CLIMB状態の処理
	if state == State.CLIMB or state == State.CLIMB_IDLE:
		# 梯子の判定をチェック
		var player_top = position + Vector2(0, -16)  # 上部の判定位置
		var player_bottom = position + Vector2(0, 0)  # 下部の判定位置
		is_on_ladder = check_ladder_tile(objects, player_top) or check_ladder_tile(objects, player_bottom)
		
		if not is_on_ladder:
			if is_on_floor():
				change_state(State.IDLE)
			else:
				change_state(State.JUMP)
	
	move_and_slide()

		
	# 地面にいる時のY座標を記録
	if is_on_floor():
		last_ground_y = position.y
	
	# 落下開始時の処理
	if state == State.JUMP and velocity.y > 0 and not is_falling:
		is_falling = true
		fall_start_y = position.y
		print("FALL START RECORDED: ", fall_start_y)
	
	# 垂直落下の処理
	if Input.is_action_pressed("crouch") and not is_on_floor() and state == State.JUMP:
		print("FAST FALL CHECK - velocity.y: ", velocity.y, " is_falling: ", is_falling, " is_fast_falling: ", is_fast_falling, " fast_fall_timer: ", fast_fall_timer)
		fast_fall_timer += delta
		if fast_fall_timer >= fast_fall_delay:
			if not is_fast_falling:
				# 垂直落下開始時の位置を記録
				fall_start_y = position.y
				print("FAST FALL START RECORDED: ", fall_start_y)
				is_fast_falling = true
				velocity.y = fast_fall_speed
				gravity = fast_fall_gravity
				$FastFallParticles.emitting = true # パーティクルエフェクト
				# AudioManager.play_se("FALL_START")  # 垂直落下開始時に音を再生
				
				# 残像の生成間隔を制御
				trail_timer += delta
				if trail_timer >= trail_interval:
					create_fall_trail()
					trail_timer = 0.0
		elif not Input.is_action_pressed("crouch"): # ボタンを離した時のみタイマーをリセット
			fast_fall_timer = 0.0
			trail_timer = 0.0
			if is_fast_falling:
				is_fast_falling = false
				gravity = 1000 # 通常の重力に戻す
				$FastFallParticles.emitting = false # パーティクルエフェクトを停止
	
	# 着地時に垂直落下の状態をリセット
	if is_on_floor():
		fast_fall_timer = 0.0
		trail_timer = 0.0
	
	# 着地時の状態遷移
	if state == State.JUMP and is_on_floor():
		print("LANDING DETECTED - STATE: ", state, " ON FLOOR: ", is_on_floor())
		
		# パーティクル処理
		print("JUMP STATE AND ON FLOOR - PROCESSING PARTICLES")
		var fall_distance = abs(position.y - fall_start_y)
		print("FALL START Y: ", fall_start_y)
		print("CURRENT Y: ", position.y)
		print("FALL DISTANCE: ", fall_distance)
		print("IS FAST FALLING: ", is_fast_falling) # デバッグ用に追加
		
		var dust_particles = $Dust.process_material as ParticleProcessMaterial
		
		if fall_distance > min_fall_height:
			print("FALL DISTANCE OVER THRESHOLD ----------------------")
			# 落下距離に応じてパーティクルを派手に
			var base_scale = 1.0
			var max_scale = 2.5 # 最大スケールを2.5倍に変更
			var min_distance = 130.0
			var max_distance = 600.0
			
			# 落下距離に応じたスケール係数を計算（130-600の範囲で1.0-2.5に正規化）
			var normalized_distance = clamp((fall_distance - min_distance) / (max_distance - min_distance), 0.0, 1.0)
			var scale_factor = base_scale + (max_scale - base_scale) * normalized_distance
			
			dust_particles.spread = 64.0 # 広がり角度は固定
			dust_particles.emission_box_extents = Vector3(1.0, scale_factor * 10.0, 1.0) # 発生範囲を大きく（最大y:25.0）
			$Dust.amount = int(20 * scale_factor * 1.2) # パーティクルの量を1.2倍に
			print("DUST AMOUNT --------------------: ", $Dust.amount)
			print("SCALE FACTOR --------------------: ", scale_factor)
			
			# 落下距離が600を超えたらカメラを揺らす
			if fall_distance > 500.0:
				print("SHAKE CAMERA TRIGGERED ----------------------")
				var camera = get_viewport().get_camera_2d()
				if camera:
					var calculated_shake = min((fall_distance - 600.0) * 0.5, 20.0) # 最大20.0の揺れ、計算を調整
					var duration = 0.3 # 0.3秒間揺らす
					_shake_camera(camera, calculated_shake, duration)
					# カメラが揺れるほどの大きな着地の時だけ着地音を再生
					AudioManager.play_se("LANDING")
			# 垂直落下の時は、fall_distanceに関わらずLANDING_02を再生
			elif is_fast_falling:
				print("LANDING_02 TRIGGERED (OVER THRESHOLD) ----------------------")
				AudioManager.play_se("LANDING_02") # 垂直落下時の着地音
				change_state(State.CROUCH)
		else:
			print("FALL DISTANCE UNDER THRESHOLD")
			# 通常のパーティクル設定
			dust_particles.spread = 64.0 # 通常の広がり角度
			dust_particles.emission_box_extents = Vector3(1.0, 6.0, 1.0) # 通常の発生範囲
			$Dust.amount = 20
			# 大きな落下でない場合で、垂直落下の時はLANDING_02を再生
			if is_fast_falling:
				print("LANDING_02 TRIGGERED (UNDER THRESHOLD) ----------------------")
				AudioManager.play_se("LANDING_02") # 垂直落下時の着地音
				change_state(State.CROUCH)
		
		$Dust.emitting = true
		is_falling = false # 着地時に落下フラグをリセット
		
	# 着地時の状態遷移
	if state == State.JUMP and is_on_floor():
		print("LANDING DETECTED - STATE: ", state, " ON FLOOR: ", is_on_floor())
		# 移動入力がある場合
		if Input.is_action_pressed("right") or Input.is_action_pressed("left"):
			if Input.is_action_pressed("dash"):
				change_state(State.DASH)
			else:
				change_state(State.WALK)
		else:
			change_state(State.IDLE)
	
	get_input(delta)
	
	# ダッシュの残像エフェクト処理
	var speed = velocity.length() # x と y の合成速度を計算
	var dash = Input.is_action_pressed("dash")

	if is_on_floor():
		# 地上での処理
		if is_fast_falling:
			is_fast_falling = false
			gravity = 1000 # 通常の重力に戻す
			$FastFallParticles.emitting = false # パーティクルエフェクトを停止

		if not is_trail_active:
			# 残像が出ていない状態で、ダッシュボタンを押していて、速度が閾値を超えたら開始
			if dash and speed > dash_trail_ground_start_speed:
				set_trail_active(true)
		else:
			# 残像が出ている状態で、速度が閾値以下になったら終了（ダッシュボタンの状態は関係なし）
			if speed < dash_trail_ground_end_speed:
				set_trail_active(false)
	else:
		# 空中での処理（変更なし）
		if not is_trail_active and speed > dash_trail_air_speed:
			set_trail_active(true)
		elif is_trail_active and speed < dash_trail_air_end_speed:
			set_trail_active(false)

	# 残像の生成間隔を制御
	if is_trail_active:
		trail_timer += delta
		var speed_factor = velocity.length() / dash_speed
		var interval = lerp(0.005, 0.01, speed_factor) # より短い間隔に
		if trail_timer >= interval:
			create_trail_sprite()
			trail_timer = 0.0

	# ジャンプ下降時のアニメーション
	if state == State.JUMP and velocity.y > 0:
		play_animation("jump_down")
	
	if position.y > 1000:
		change_state(State.DEAD)

	if is_on_floor():
		bounce_timer = bounce_grace_time
		$CoyoteTimer.stop()
		coyote_time = true
		jump_count = 0
		
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
	var jump_held = Input.is_action_pressed("jump") # ジャンプボタンを押し続けているかどうかを追加
	var down = Input.is_action_pressed("crouch")
	var climb = Input.is_action_pressed("climb")
	var dash = Input.is_action_pressed("dash")

	var target_velocity_x = 0
	if state == State.CLIMB or state == State.CLIMB_IDLE:
		# 梯子の時の左右移動はclimb_speedに制限
		if right:
			target_velocity_x = climb_speed
			$Sprite2D.flip_h = false
			change_state(State.CLIMB)  # 左右移動時はCLIMB状態に
		if left:
			target_velocity_x = -climb_speed
			$Sprite2D.flip_h = true
			change_state(State.CLIMB)  # 左右移動時はCLIMB状態に
		velocity.x = target_velocity_x  # 加速度なしで直接速度を設定
		
		# 上下移動の処理
		if climb:
			velocity.y = -climb_speed
			change_state(State.CLIMB)
		elif down:
			velocity.y = climb_speed
			change_state(State.CLIMB)
		else:
			velocity.y = 0
			# 左右にも動いていない時はCLIMB_IDLE状態に
			if target_velocity_x == 0:
				change_state(State.CLIMB_IDLE)
	else:
		if is_on_floor():
			# 地上での処理
			if right:
				target_velocity_x += dash_speed
				$Sprite2D.flip_h = false
			if left:
				target_velocity_x -= dash_speed
				$Sprite2D.flip_h = true
			if dash:
				target_velocity_x *= 2
				was_dashing_on_ground = true # 地上でダッシュ中ならフラグを設定
		else:
			# 空中での処理
			if not (right or left):
				# 入力がない場合は、現在の速度からゆっくり減速
				target_velocity_x = velocity.x * 0.95
			else:
				# 空中での方向転換は、目標速度を基準に
				if right:
					# 地上でダッシュ中で、かつ現在の速度が正の方向なら、ダッシュ速度を維持
					if was_dashing_on_ground and velocity.x > 0:
						target_velocity_x = dash_speed * 2
					else:
						target_velocity_x = dash_speed * 0.8
					$Sprite2D.flip_h = false
				if left:
					# 地上でダッシュ中で、かつ現在の速度が負の方向なら、ダッシュ速度を維持
					if was_dashing_on_ground and velocity.x < 0:
						target_velocity_x = - dash_speed * 2
					else:
						target_velocity_x = - dash_speed * 0.8
					$Sprite2D.flip_h = true

			# 空中で速度が閾値を下回ったらダッシュ効果を解除
			if was_dashing_on_ground and abs(velocity.x) < dash_trail_air_end_speed:
				was_dashing_on_ground = false

		# ダッシュボタンを離したら、フラグをリセット
		if not dash:
			was_dashing_on_ground = false

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
			fall_start_y = position.y # ジャンプ開始時に落下開始位置を記録
				
		elif !is_on_floor() and !coyote_time and jump_count < max_jumps:
			AudioManager.play_se("HIGH_JUMP")
			change_state(State.JUMP)
			velocity.y = jump_speed / 1.5
			jump_count += 1
			fall_start_y = position.y # 二段ジャンプ時も落下開始位置を記録

		elif is_on_wall():
			AudioManager.play_se("JUMP")
			change_state(State.JUMP)
			velocity.y = jump_speed
			velocity.x = - target_velocity_x
			jump_count += 1
			fall_start_y = position.y # 壁ジャンプ時も落下開始位置を記録

	if state in [State.IDLE, State.CROUCH] and velocity.x != 0:
		change_state(State.WALK)

	# 速度に基づく状態遷移
	if state == State.DASH and abs(velocity.x) <= dash_speed:
		change_state(State.WALK) # 速度がしきい値以下ならWALK
	elif state == State.WALK and abs(velocity.x) > dash_speed and dash:
		change_state(State.DASH) # 速度がしきい値を超えていて、かつdashボタンが押されている場合のみDASH

	# 完全停止時の処理
	if state in [State.DASH, State.WALK] and abs(velocity.x) < 0.1: # 微小な速度も考慮
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
		particle_material.direction = Vector3(-1, 0, 0) # 左を向いているとき
		$DashTrail.position.x = 14 # 右を向いているとき
		# $DashTrail.rotation_degrees = 0
		$DashTrail.skew = 18.5
	else:
		particle_material.direction = Vector3(1, 0, 0) # 右を向いているとき
		$DashTrail.position.x = -14 # 左を向いているとき
		# $DashTrail.rotation_degrees = -180
		$DashTrail.skew = -18.5


func create_trail_sprite() -> void:
	var trail_sprite = Sprite2D.new()
	get_tree().root.add_child(trail_sprite)
	
	var initial_position = $Sprite2D.global_position
	
	var current_frame = $Sprite2D.frame
	var current_hframes = $Sprite2D.hframes
	
	trail_sprite.texture = $Sprite2D.texture
	trail_sprite.hframes = current_hframes
	trail_sprite.frame = current_frame
	trail_sprite.flip_h = $Sprite2D.flip_h
	
	# シェーダーを適用
	var shader = load("res://shaders/trail.gdshader")
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("color", Color(0.0, 0.9, 1.0, 0.1)) # 水色に変更
	trail_sprite.material = shader_material
	
	trail_sprite.global_position = initial_position
	
	# 透明度の変化を速く（0.2秒）
	var tween = create_tween()
	tween.tween_property(shader_material, "shader_parameter/color:a", 0.0, 0.12)
	
	# 0.2秒後にスプライトを削除
	await get_tree().create_timer(0.12).timeout
	trail_sprite.queue_free()

func set_trail_active(active: bool) -> void:
	if is_trail_active != active: # 状態が変わったときだけ処理
		is_trail_active = active
		if active: # 残像を開始するときだけタイマーをリセット
			trail_timer = 0.0
	# $DashTrail.emitting = active
	# update_particle_direction()

func create_fall_trail() -> void:
	var trail = Sprite2D.new()
	get_tree().root.add_child(trail)
	
	# 残像の設定
	trail.texture = $Sprite2D.texture
	trail.hframes = $Sprite2D.hframes
	trail.frame = $Sprite2D.frame
	trail.flip_h = $Sprite2D.flip_h
	trail.scale = Vector2(0.8, 0.8) # 少し小さく
	
	# シェーダーマテリアルの適用
	var shader = load("res://shaders/fall_trail.gdshader")
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("color", Color(0.0, 0.8, 1.0, 0.3)) # 透明度を下げる
	trail.material = shader_material
	
	trail.global_position = $Sprite2D.global_position
	trail_sprites.append(trail)
	
	# フェードアウト
	var tween = create_tween()
	tween.tween_property(shader_material, "shader_parameter/color:a", 0.0, 0.15) # 時間を短く
	tween.tween_callback(trail.queue_free)
	tween.tween_callback(func(): trail_sprites.erase(trail))

# fall_start_yを設定するメソッド
func set_fall_start_y(y: float) -> void:
	fall_start_y = y
	print("FALL START Y SET TO: ", fall_start_y)

# カメラを揺らす関数
func _shake_camera(camera: Camera2D, amount: float, duration: float) -> void:
	print("SHAKE CAMERA STARTED - Amount: ", amount, " Duration: ", duration)
	original_camera_position = camera.global_position
	shake_amount = amount
	shake_duration = duration
	shake_timer = 0.0
	is_camera_shaking = true
	
	# カメラの追随を一時的に無効にする
	# var level = get_parent()
	# if level and level.has_method("set_camera_follow_enabled"):
	# 	level.set_camera_follow_enabled(false)
	# 	print("Camera follow disabled")

func _process(delta: float) -> void:
	if is_camera_shaking:
		var camera = get_viewport().get_camera_2d()
		if camera:
			shake_timer += delta
			
			# 揺れの強さを時間とともに減衰させる
			var progress = shake_timer / shake_duration
			var current_shake_amount = shake_amount * (1.0 - progress) * sin(progress * PI * 16.0)
			
			# ランダムな揺れを生成（x方向は小さく、y方向は大きく）
			var random_offset = Vector2(
				randf_range(-current_shake_amount, current_shake_amount) * 0.05,
				randf_range(-current_shake_amount, current_shake_amount) * 0.5
			)
			
			# カメラの位置を更新
			camera.global_position = original_camera_position + random_offset
			
			# 揺れが終了したら
			if shake_timer >= shake_duration:
				is_camera_shaking = false
				camera.global_position = original_camera_position
				
				# カメラの追随を再開
				var level = get_parent()
				if level and level.has_method("set_camera_follow_enabled"):
					level.set_camera_follow_enabled(true)
					print("Camera follow enabled")
				
				print("SHAKE CAMERA FINISHED - Frame: ", Engine.get_physics_frames())
				print("Final camera position: ", camera.global_position)

# 梯子の判定を最適化した実装
func check_ladder_tile(tilemap: TileMapLayer, pos: Vector2) -> bool:
	# プレイヤーの中心とサイズを計算
	var player_center = pos + Vector2(-2, 0)  # 判定幅に合わせて左にずらす
	var player_half_width = 12.0  # 判定を少し広く（28ピクセル）
	var player_half_height = 16.0  # 判定を少し狭く（32ピクセル）
	
	# プレイヤーの周囲のタイルを検索
	var start_tile = tilemap.local_to_map(player_center - Vector2(player_half_width, player_half_height))
	var end_tile = tilemap.local_to_map(player_center + Vector2(player_half_width, player_half_height))
	
	for x in range(start_tile.x, end_tile.x + 1):
		for y in range(start_tile.y, end_tile.y + 1):
			var check_pos = Vector2i(x, y)
			print("CHECK POS: ", check_pos)
			var tile_data = tilemap.get_cell_source_id(check_pos)
			print("TILE DATA: ", tile_data)
			if tile_data != -1:
				var tile_info = tilemap.get_cell_tile_data(check_pos)
				if tile_info and tile_info.get_custom_data("is_climbable"):
					# タイルの実際のサイズを取得
					var _source_id = tilemap.get_cell_source_id(check_pos)
					var _atlas_coords = tilemap.get_cell_atlas_coords(check_pos)
					var tile_size = tilemap.tile_set.tile_size
					
					# タイルの位置とサイズを計算
					var tile_pos = tilemap.map_to_local(check_pos)
					var tile_rect = Rect2(tile_pos, tile_size)
					
					# プレイヤーの矩形
					var player_rect = Rect2(
						player_center - Vector2(player_half_width, player_half_height),
						Vector2(player_half_width * 2, player_half_height * 2)
					)
					
					# 矩形が重なっているかチェック
					if tile_rect.intersects(player_rect):
						print("CUSTOM DATA: ", tile_info.get_custom_data("is_climbable"))
						return true
	return false
