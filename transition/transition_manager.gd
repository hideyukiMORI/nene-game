extends CanvasLayer

signal transition_finished

@onready var animation_player = $AnimationPlayer
@onready var transition_rect = $ColorRect

func _ready() -> void:
	transition_rect.visible = false
	transition_rect.color = Color.WHITE  # デフォルトは白色

# フェードトランジション（白フェード）
func do_fade_transition(callback: Callable) -> void:
	# トランジション開始時にポーズ
	get_tree().paused = true
	
	transition_rect.visible = true
	transition_rect.color = Color.WHITE  # 明示的に白色に設定
	AudioManager.play_se("WARP")
	animation_player.play("fade_out")
	await animation_player.animation_finished
	
	# コールバックで実際のワープ処理を実行
	callback.call()
	
	await get_tree().create_timer(0.1).timeout
	# AudioManager.play_se("WARP_END")
	animation_player.play("fade_in")
	await animation_player.animation_finished
	transition_rect.visible = false
	
	# トランジション終了時にポーズ解除
	get_tree().paused = false

# フェードトランジション（黒フェード）
func do_fade_black_transition(callback: Callable) -> void:
	# トランジション開始時にポーズ
	get_tree().paused = true
	
	transition_rect.visible = true
	transition_rect.color = Color.BLACK  # 明示的に黒色に設定
	AudioManager.play_se("WARP")
	animation_player.play("fade_out")
	await animation_player.animation_finished
	
	# コールバックで実際のワープ処理を実行
	callback.call()
	
	await get_tree().create_timer(0.1).timeout
	# AudioManager.play_se("WARP_END")
	animation_player.play("fade_in")
	await animation_player.animation_finished
	transition_rect.visible = false
	transition_rect.color = Color.WHITE  # 白色に戻す
	
	# トランジション終了時にポーズ解除
	get_tree().paused = false

# サークルワイプ用のトランジション
func do_circle_wipe_transition(callback: Callable, center_pos: Vector2, target_marker: Marker2D) -> void:
	print("\n=== Circle Wipe Transition Debug ===")
	print("Starting circle wipe transition")
	get_tree().paused = true
	
	# シェーダーマテリアルの設定
	var shader_material = ShaderMaterial.new()
	shader_material.shader = preload("res://shaders/circle_wipe.gdshader")
	shader_material.set_shader_parameter("progress", 0.0)
	
	# カメラとビューポートの情報を取得
	var camera = get_viewport().get_camera_2d()
	if not camera:
		push_error("Camera2D not found. Circle wipe transition requires a camera.")
		return
	var viewport_size = get_viewport().get_visible_rect().size
	
	# 画面の長辺を基準に円のサイズを計算
	var max_size = max(viewport_size.x, viewport_size.y)
	var radius = max_size / min(viewport_size.x, viewport_size.y)  # 長辺/短辺の比率
	shader_material.set_shader_parameter("radius", radius)
	
	transition_rect.material = shader_material
	
	# カメラの位置とズームを取得
	var camera_pos = camera.global_position
	var camera_zoom = camera.zoom
	
	# カメラの制限範囲を取得
	var camera_limits = {
		"left": camera.limit_left,
		"top": camera.limit_top,
		"right": camera.limit_right,
		"bottom": camera.limit_bottom
	}
	
	print("\nCamera Info:")
	print("Camera position: ", camera_pos)
	print("Camera zoom: ", camera_zoom)
	print("Camera limits: ", camera_limits)
	
	print("\nViewport Info:")
	print("Viewport size: ", viewport_size)
	print("Max size: ", max_size)
	print("Radius: ", radius)
	
	print("\nTransition Info:")
	print("Center position (world): ", center_pos)
	
	# カメラの制限範囲を考慮した画面座標の計算
	var half_viewport = viewport_size / 2
	
	print("\nViewport Details:")
	print("Half viewport: ", half_viewport)
	print("Viewport size: ", viewport_size)
	print("Camera zoom: ", camera_zoom)
	
	# カメラの制限範囲を考慮してビューポートの位置を計算
	var viewport_pos = camera_pos - half_viewport / camera_zoom
	viewport_pos.x = clamp(viewport_pos.x, camera_limits.left, camera_limits.right - viewport_size.x / camera_zoom.x)
	viewport_pos.y = clamp(viewport_pos.y, camera_limits.top, camera_limits.bottom - viewport_size.y / camera_zoom.y)

	var viewport_rect = Rect2(
		viewport_pos,
		Vector2(viewport_size.x / camera_zoom.x, viewport_size.y / camera_zoom.y)
	)
	
	print("\nViewport Rectangle:")
	print("Position: ", viewport_rect.position)
	print("Size: ", viewport_rect.size)
	print("End: ", viewport_rect.end)
	
	# キャラクターの位置はそのまま使用（制限不要）
	var character_pos = center_pos
	
	print("\nPosition Details:")
	print("Character position: ", character_pos)
	print("Camera position: ", camera_pos)
	
	# ワールド座標を画面座標に変換（カメラのズームと制限を考慮）
	var initial_viewport_center = viewport_rect.position + viewport_rect.size / 2.0
	var relative_pos = character_pos - initial_viewport_center
	var screen_pos = Vector2(
		relative_pos.x * camera_zoom.x,
		relative_pos.y * camera_zoom.y
	)
	
	print("\nScreen Position Calculation:")
	print("Viewport center: ", initial_viewport_center)
	print("Clamped center - viewport center: ", relative_pos)
	print("After camera zoom: ", screen_pos)
	
	# 画面座標をUV座標に変換（0-1の範囲に正規化）
	var normalized_x = clamp(screen_pos.x / viewport_size.x + 0.5, 0.0, 1.0)
	var normalized_y = clamp(screen_pos.y / viewport_size.y + 0.5, 0.0, 1.0)
	
	print("\nUV Calculation:")
	print("Screen position: ", screen_pos)
	print("Viewport size: ", viewport_size)
	print("Normalized X: ", normalized_x)
	print("Normalized Y: ", normalized_y)
	
	# UV座標を0-1の範囲に制限（画面端での問題を防ぐ）
	var center_uv = Vector2(normalized_x, normalized_y)
	
	print("\nFinal UV Coordinates:")
	print("Center UV: ", center_uv)
	print("Clamped: ", center_uv)
	
	# シェーダーのパラメータを設定
	shader_material.set_shader_parameter("center", center_uv)
	shader_material.set_shader_parameter("radius", radius)  # 計算した半径を設定
	shader_material.set_shader_parameter("progress", 0.0)  # 初期値を設定
	
	print("\nShader Parameters:")
	print("Center: ", shader_material.get_shader_parameter("center"))
	print("Radius: ", shader_material.get_shader_parameter("radius"))
	print("Progress: ", shader_material.get_shader_parameter("progress"))
	
	# ワープ前の中心位置を記憶
	var start_center_uv = center_uv
	var start_camera_pos = camera.global_position
	
	transition_rect.visible = true
	transition_rect.modulate.a = 1.0  # 透明度を1に設定
	AudioManager.play_se("WARP")
	
	# フェードアウト
	var tween = create_tween()
	tween.tween_property(shader_material, "shader_parameter/progress", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC)
	print("\nStarting fade out")
	await tween.finished
	print("Fade out finished")
	
	print("\nBefore Warp Position:----------------------------------------")
	print("Character global position: ", callback.get_object().global_position)
	print("Target marker position: ", target_marker.global_position)
	
	# ワープ処理
	callback.call()
	
	print("\nAfter Warp Position:----------------------------------------")
	print("Character global position: ", callback.get_object().global_position)
	print("Target marker position: ", target_marker.global_position)
	
	# 新しいキャラクターの位置を取得して更新
	var new_center_pos = target_marker.global_position
	print("\nNew Position Details:")
	print("New center position: ", new_center_pos)
	
	# カメラの位置を更新
	if camera:
		# 新しい位置に基づいてカメラの位置を計算
		var target_camera_pos = new_center_pos
		target_camera_pos -= half_viewport / camera_zoom  # カメラの中心を調整
		
		# カメラの位置を制限範囲内に収める
		target_camera_pos.x = clamp(target_camera_pos.x, camera_limits.left, camera_limits.right - viewport_size.x / camera_zoom.x)
		target_camera_pos.y = clamp(target_camera_pos.y, camera_limits.top, camera_limits.bottom - viewport_size.y / camera_zoom.y)
		
		# カメラ位置を更新
		camera.global_position = target_camera_pos
		
		print("\nNew Camera Position:")
		print("Camera position: ", camera.global_position)
		
		# ビューポートの位置を更新（カメラの位置に基づいて）
		viewport_pos = camera.global_position - half_viewport / camera_zoom
		viewport_pos.x = clamp(viewport_pos.x, camera_limits.left, camera_limits.right - viewport_size.x / camera_zoom.x)
		viewport_pos.y = clamp(viewport_pos.y, camera_limits.top, camera_limits.bottom - viewport_size.y / camera_zoom.y)
		
		viewport_rect = Rect2(
			viewport_pos,
			Vector2(viewport_size.x / camera_zoom.x, viewport_size.y / camera_zoom.y)
		)
		
		print("\nNew Viewport Rectangle:")
		print("Position: ", viewport_rect.position)
		print("Size: ", viewport_rect.size)
		print("End: ", viewport_rect.end)

	# 新しいビューポートの中心を計算
	var new_viewport_center = viewport_rect.position + viewport_rect.size / 2.0
	
	# キャラクターの位置を制限範囲内に収める
	var clamped_new_center_pos = Vector2(
		clamp(new_center_pos.x, camera_limits.left, camera_limits.right),
		clamp(new_center_pos.y, camera_limits.top, camera_limits.bottom)
	)
	
	# 画面座標の計算
	var new_relative_pos = clamped_new_center_pos - new_viewport_center
	var new_screen_pos = Vector2(
		new_relative_pos.x * camera_zoom.x,
		new_relative_pos.y * camera_zoom.y
	)

	print("\nNew Screen Position Calculation:")
	print("Viewport center: ", new_viewport_center)
	print("New center - viewport center: ", new_relative_pos)
	print("After camera zoom: ", new_screen_pos)

	# 画面の中心からの最大距離を計算（画面の40%）
	var max_distance = min(viewport_size.x, viewport_size.y) * 0.4
	
	# UV座標の計算（0.5を中心とした範囲で正規化）
	var new_normalized_x = clamp(0.5 + (new_screen_pos.x / max_distance) * 0.4, 0.1, 0.9)
	var new_normalized_y = clamp(0.5 + (new_screen_pos.y / max_distance) * 0.4, 0.1, 0.9)

	print("\nNew UV Calculation:")
	print("Screen position: ", new_screen_pos)
	print("Viewport size: ", viewport_size)
	print("Max distance: ", max_distance)
	print("Normalized X: ", new_normalized_x)
	print("Normalized Y: ", new_normalized_y)

	# UV座標を0.1-0.9の範囲に制限
	var new_center_uv = Vector2(new_normalized_x, new_normalized_y)
	
	# カメラの制限と移動量に基づいて中心位置を調整
	var adjusted_center_uv = start_center_uv
	
	if camera:
		# カメラの制限チェック
		var camera_at_limit = false
		var camera_limit_direction = Vector2.ZERO
		
		# X方向のチェック
		if camera.global_position.x <= camera_limits.left + 1:
			camera_at_limit = true
			camera_limit_direction.x = -1
		elif camera.global_position.x >= camera_limits.right - viewport_size.x / camera_zoom.x - 1:
			camera_at_limit = true
			camera_limit_direction.x = 1
			
		# Y方向のチェック
		if camera.global_position.y <= camera_limits.top + 1:
			camera_at_limit = true
			camera_limit_direction.y = -1
		elif camera.global_position.y >= camera_limits.bottom - viewport_size.y / camera_zoom.y - 1:
			camera_at_limit = true
			camera_limit_direction.y = 1
		
		print("\nCamera Limit Check:")
		print("Camera at limit: ", camera_at_limit)
		print("Limit direction: ", camera_limit_direction)
		
		# カメラの移動量チェック
		var camera_movement = camera.global_position - start_camera_pos
		var significant_movement = abs(camera_movement.x) > 100 or abs(camera_movement.y) > 100
		print("Camera movement: ", camera_movement)
		print("Significant movement: ", significant_movement)
		
		# 調整が必要かどうかを判断
		var needs_adjustment = camera_at_limit or significant_movement
		
		if needs_adjustment:
			var adjustment = Vector2.ZERO
			
			# カメラが制限に達している場合の調整
			if camera_at_limit:
				if camera_limit_direction.x != 0:
					adjustment.x = camera_limit_direction.x * 0.35
				if camera_limit_direction.y != 0:
					adjustment.y = camera_limit_direction.y * 0.35
			
			# カメラが大きく移動した場合の調整
			if significant_movement and not camera_at_limit:
				var movement_direction = Vector2(
					sign(camera_movement.x),
					sign(camera_movement.y)
				)
				adjustment = movement_direction * 0.25
			
			# ワープ先が画面端に近い場合の調整
			if new_center_uv.x < 0.2 or new_center_uv.x > 0.8 or new_center_uv.y < 0.2 or new_center_uv.y > 0.8:
				adjustment = adjustment * 0.5 + (new_center_uv - Vector2(0.5, 0.5)) * 0.5
			
			# 調整された中心位置を計算
			adjusted_center_uv = Vector2(
				clamp(start_center_uv.x + adjustment.x, 0.1, 0.9),
				clamp(start_center_uv.y + adjustment.y, 0.1, 0.9)
			)
			
			print("Adjustment needed: ", needs_adjustment)
			print("UV adjustment: ", adjustment)
			print("Adjusted center UV: ", adjusted_center_uv)
		else:
			print("No adjustment needed, using start position")
	
	print("\nStored Start Center UV: ", start_center_uv)
	print("\nCalculated New Center UV: ", new_center_uv)
	print("\nAdjusted Center UV: ", adjusted_center_uv)

	print("\nNew Final UV Coordinates:")
	print("Center UV: ", adjusted_center_uv)

	# シェーダーの中心位置を更新
	shader_material.set_shader_parameter("center", adjusted_center_uv)

	# 1フレーム待って位置の更新を確実にする
	await get_tree().process_frame

	# フェードイン
	tween = create_tween()
	tween.tween_property(shader_material, "shader_parameter/progress", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	
	transition_rect.visible = false
	transition_rect.material = null
	get_tree().paused = false
	print("=== End Circle Wipe Transition ===\n")
