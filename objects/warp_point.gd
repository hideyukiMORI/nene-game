extends Area2D

enum WarpType {
	SAME_SCENE,    # 同一シーン内の移動
	OTHER_SCENE    # 別シーンへの移動
}

enum SameSceneTransitionType {
	FADE_WHITE = 1,    # 白フェード
	FADE_BLACK = 2,    # 黒フェード
	CIRCLE_WIPE = 3    # サークルワイプ
}

enum OtherSceneTransitionType {
	FADE_WHITE = 1,    # 白フェード
	FADE_BLACK = 2     # 黒フェード
}

# ワープの基本設定
@export_group("Warp Settings")
@export var warp_type: WarpType
@export var is_enabled: bool = true

# 同一シーン内ワープ用の設定
@export_group("Same Scene Settings")
@export var target_marker: Marker2D
@export var transition_type: SameSceneTransitionType = SameSceneTransitionType.CIRCLE_WIPE

# 別シーンへのワープ用の設定
@export_group("Other Scene Settings")
@export var target_scene_name: String  # シーン名を直接指定
@export var spawn_marker_name: String  # マーカーの名前を指定
@export var other_scene_transition_type: OtherSceneTransitionType = OtherSceneTransitionType.FADE_WHITE

# シグナル
# signal player_warped(target_scene: String, spawn_marker_name: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not is_enabled or not body.is_in_group("player"):
		return
		
	match warp_type:
		WarpType.SAME_SCENE:
			_warp_same_scene(body)
		WarpType.OTHER_SCENE:
			_warp_other_scene()

func _warp_same_scene(body: Node2D) -> void:
	if not target_marker:
		push_error("Target marker is not set!")
		return
		
	print("\n=== Warp Debug ===")
	print("Character local position: ", body.position)
	print("Character global position: ", body.global_position)
	print("Target marker local position: ", target_marker.position)
	print("Target marker global position: ", target_marker.global_position)
	print("Character parent: ", body.get_parent().name)
	print("Target marker parent: ", target_marker.get_parent().name)
	print("=== End Warp Debug ===\n")
		
	# トランジション付きのワープ
	var warp_callback = func():
		body.global_position = target_marker.global_position
		# ワープ先の位置をfall_start_yに設定
		if body.has_method("set_fall_start_y"):
			body.set_fall_start_y(target_marker.global_position.y)
	
	# トランジションタイプに応じて適切なトランジションを実行
	match transition_type:
		SameSceneTransitionType.FADE_WHITE:
			await TransitionManager.do_fade_transition(warp_callback)
		SameSceneTransitionType.CIRCLE_WIPE:
			await TransitionManager.do_circle_wipe_transition(warp_callback, body.global_position, target_marker)
		SameSceneTransitionType.FADE_BLACK:
			await TransitionManager.do_fade_black_transition(warp_callback)

func _warp_other_scene() -> void:
	print("Warp to other scene: ", target_scene_name)
	print("Spawn marker name: ", spawn_marker_name)
	print("Transition type: ", other_scene_transition_type)
	print("OtherSceneTransitionType FADE_WHITE:", OtherSceneTransitionType.FADE_WHITE)
	print("OtherSceneTransitionType FADE_BLACK:", OtherSceneTransitionType.FADE_BLACK)
	if target_scene_name.is_empty():
		push_error("Target scene name is not set!")
		return
	
	if not GameState.SCENES.has(target_scene_name):
		push_error("Invalid scene name: " + target_scene_name)
		return
	
	# トランジション付きのワープ
	var warp_callback = func():
		GameState.change_scene(target_scene_name, spawn_marker_name)

	# トランジションタイプに応じて適切なトランジションを実行
	match other_scene_transition_type:
		OtherSceneTransitionType.FADE_WHITE:
			await TransitionManager.do_fade_transition(warp_callback)
		OtherSceneTransitionType.FADE_BLACK:
			await TransitionManager.do_fade_black_transition(warp_callback)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
