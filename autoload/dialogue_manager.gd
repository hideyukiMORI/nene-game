extends Node

var dialogue_flags: Dictionary = {}  # 会話フラグを管理
var dialogue_history: Array = []     # 会話履歴を管理
var dialogue_scene: PackedScene = preload("res://ui/dialogue_box.tscn")
var current_dialogue: Node = null
var is_dialogue_open: bool = false   # ダイアログが開いているかどうか
var canvas_layer: CanvasLayer = null  # UIレイヤーを追加

func _ready():
	# 初期化処理
	process_mode = Node.PROCESS_MODE_ALWAYS
	# UIレイヤーを作成
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)

func start_dialogue(dialogue_id: String) -> void:
	print("start_dialogue: ", dialogue_id)

func show_dialogue(dialogue_name: String) -> void:
	if is_dialogue_open:
		return
	
	is_dialogue_open = true
	get_tree().paused = true
	
	# シーンをCanvasLayerの子として追加
	current_dialogue = dialogue_scene.instantiate()
	canvas_layer.add_child(current_dialogue)
	current_dialogue.show_message(dialogue_name)

func close_dialogue() -> void:
	if not is_dialogue_open:
		return
		
	is_dialogue_open = false
	get_tree().paused = false
	
	# ダイアログを削除
	if current_dialogue:
		current_dialogue.queue_free()  # 安全に削除
		current_dialogue = null

# フラグ管理
func set_flag(flag_name: String, value: bool) -> void:
	dialogue_flags[flag_name] = value

func get_flag(flag_name: String) -> bool:
	return dialogue_flags.get(flag_name, false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select") and is_dialogue_open:
		close_dialogue()
