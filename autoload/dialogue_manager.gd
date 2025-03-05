extends Node

var dialogue_flags: Dictionary = {}  # 会話フラグを管理
var dialogue_history: Array = []     # 会話履歴を管理
var dialogue_scene: PackedScene = preload("res://ui/dialogue_box.tscn")
var current_dialogue: Node = null
var is_dialogue_open: bool = false   # ダイアログが開いているかどうか
var canvas_layer: CanvasLayer = null  # UIレイヤーを追加

var current_pages: Array = []  # 現在の会話ページ配列
var current_page_index: int = 0  # 現在のページインデックス

func _ready():
	# 初期化処理
	process_mode = Node.PROCESS_MODE_ALWAYS
	# UIレイヤーを作成
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)

func start_dialogue(target: String, dialogue_id: String, page_id: String) -> void:
	if is_dialogue_open:
		return
	
	# JSONファイルのパスを生成
	var file_path = "res://dialogue/resources/data/%s/en/%s.json" % [target, dialogue_id]
	
	# JSONファイルを読み込む
	var json = JSON.new()
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open file: ", file_path)
		return
		
	var json_text = file.get_as_text()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("Failed to parse JSON: ", file_path)
		return
		
	var data = json.get_data()
	current_pages = data[page_id]["pages"]
	current_page_index = 0
	
	show_current_page()

func show_current_page() -> void:
	if not current_dialogue:
		is_dialogue_open = true
		get_tree().paused = true
		current_dialogue = dialogue_scene.instantiate()
		canvas_layer.add_child(current_dialogue)
	
	current_dialogue.show_message(current_pages[current_page_index]["text"])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and is_dialogue_open:
		if current_page_index < current_pages.size() - 1:
			current_page_index += 1
			show_current_page()
		else:
			close_dialogue()
	elif event.is_action_pressed("select") and is_dialogue_open:
		close_dialogue()
		

func close_dialogue() -> void:
	if not is_dialogue_open:
		return
		
	is_dialogue_open = false
	get_tree().paused = false
	
	if current_dialogue:
		current_dialogue.queue_free()
		current_dialogue = null
	
	current_pages = []
	current_page_index = 0

# フラグ管理
func set_flag(flag_name: String, value: bool) -> void:
	dialogue_flags[flag_name] = value

func get_flag(flag_name: String) -> bool:
	return dialogue_flags.get(flag_name, false)
