extends CharacterBody2D

@export var base_speed: int = 15
@export var gravity: int = 900
@export var movement_range: Vector2 = Vector2(100, 100)  # 行動範囲を設定
@export var vertical_wave_amplitude: float = 20.0  # 垂直方向の波の振幅
@export var vertical_wave_frequency: float = 1.0  # 垂直方向の波の周波数
var facing: int = 1
var start_position: Vector2
var time_passed: float = 0.0
var random_offset: float
var speed_variation: float
var speed_change_timer: float = 0.0
var speed_change_interval: float = 2.0  # スピードが変化する間隔

func _ready() -> void:
	randomize()  # 乱数を初期化
	start_position = position  # 初期位置を保存
	random_offset = randf() * PI * 2  # ランダムなオフセットを生成
	speed_variation = randf_range(0.5, 3.0)  # 初期スピードの変化を生成

func _physics_process(delta: float) -> void:
	time_passed += delta
	speed_change_timer += delta

	# 一定時間ごとにスピードをランダムに変化させる
	if speed_change_timer >= speed_change_interval:
		speed_variation = randf_range(0.5, 3.0)
		speed_change_timer = 0.0

	$Sprite2D.flip_h = velocity.x < 0
	velocity.y = vertical_wave_amplitude * sin(vertical_wave_frequency * time_passed + random_offset)
	velocity.x = facing * base_speed * speed_variation
	move_and_slide()
	
	# フレームごとに元の位置に戻る力を加える
	var return_force = 0.2  # 戻る力の強さを調整
	if position.x < start_position.x - movement_range.x or position.x > start_position.x + movement_range.x:
		velocity.x += (start_position.x - position.x) * return_force
		facing = sign(start_position.x - position.x)  # 戻る方向に向きを設定

	for idx in range(get_slide_collision_count()):
		var collision = get_slide_collision(idx)
		if collision.get_collider().name == 'Player':
			collision.get_collider().hurt()
		if collision.get_normal().x != 0:
			facing = sign(collision.get_normal().x)
			velocity.y = -100
	
	if position.y > 1000:
		queue_free()

func take_damage():
	$HitSound.play()
	$AnimationPlayer.play('death')
	$CollisionShape2D.set_disabled(true)
	set_physics_process(false)

func _on_animation_player_animation_finished(anim_name:StringName) -> void:
	if anim_name == 'death':
		queue_free()
