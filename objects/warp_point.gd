extends Area2D

enum WarpType {
	SAME_SCENE,    # 同一シーン内の移動
	OTHER_SCENE    # 別シーンへの移動
}

# ワープの基本設定
@export var warp_type: WarpType
@export var is_enabled: bool = true

# 同一シーン内ワープ用の設定
@export var target_marker: Marker2D

# 別シーンへのワープ用の設定
@export var target_scene_name: String  # シーン名を直接指定
@export var spawn_marker_name: String  # マーカーの名前を指定

# シグナル
signal player_warped(target_scene: String, spawn_marker_name: String)

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
	
	# プレイヤーの位置を中心にトランジションを実行
	await TransitionManager.do_circle_wipe_transition(warp_callback, body.global_position, target_marker)

func _warp_other_scene() -> void:
	if target_scene_name.is_empty():
		push_error("Target scene name is not set!")
		return
	
	if not GameState.SCENES.has(target_scene_name):
		push_error("Invalid scene name: " + target_scene_name)
		return
	
	GameState.change_scene(target_scene_name, spawn_marker_name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
