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
@export_file("*.tscn") var target_scene: String
@export var spawn_marker_name: String  # マーカーの名前を指定

# シグナル
signal player_warped(target_scene: String, spawn_marker_name: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# プレイヤーが入ったときの判定用
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
		
	# body.global_position = target_marker.global_position
	# player_warped.emit("", target_marker.global_position)
	print("warp_same_scene")

func _warp_other_scene() -> void:
	if target_scene.is_empty():
		push_error("Target scene is not set!")
		return
	
	if spawn_marker_name.is_empty():
		push_error("Spawn marker name is not set!")
		return
	
	player_warped.emit(target_scene, spawn_marker_name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
