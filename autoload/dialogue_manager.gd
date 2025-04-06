extends Node

var dialogue_flags: Dictionary = {}  # 会話フラグを管理
var dialogue_history: Array = []     # 会話履歴を管理
var dialogue_scene: PackedScene = preload("res://ui/dialogue_box.tscn")
var current_dialogue: Node = null
var is_dialogue_open: bool = false   # ダイアログが開いているかどうか
var canvas_layer: CanvasLayer = null  # UIレイヤーを追加

var current_pages: Array = []  # 現在の会話ページ配列
var current_page_index: int = 0  # 現在のページインデックス
var current_characters: Dictionary = {}  # キャラクター情報を保持

# 言語設定
var current_language: String = "en"  # デフォルトは英語

# フォント設定
var fonts = {
	"en": "res://assets/fonts/Hardpixel.OTF",
	# "ja": "res://assets/fonts/misaki_gothic.ttf"
	"ja": "res://assets/fonts/PixelMplus12-Regular.ttf"
}

func _ready():
	# 初期化処理
	process_mode = Node.PROCESS_MODE_ALWAYS
	# UIレイヤーを作成
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 2  # HUDより手前に表示
	add_child(canvas_layer)
	print("DialogueManager initialized with language: ", current_language)

func start_dialogue(target: String, dialogue_id: String, page_id: String) -> void:
	if is_dialogue_open:
		return
	
	var file_path = "res://dialogue/resources/data/%s/%s/%s.json" % [target, current_language, dialogue_id]
	print("Attempting to load dialogue from: ", file_path)
	print("Current language setting: ", current_language)
	
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
	current_characters = data[page_id]["initial_state"]["characters"]  # キャラクター情報を保存
	current_pages = data[page_id]["pages"]
	current_page_index = 0
	
	show_current_page()

func show_current_page() -> void:
	if not current_dialogue:
		is_dialogue_open = true
		get_tree().paused = true
		current_dialogue = dialogue_scene.instantiate()
		canvas_layer.add_child(current_dialogue)
		
		# フォントを設定
		var rich_text_label = current_dialogue.get_node("NinePatchRect/RichTextLabel")
		if rich_text_label:
			print("Setting font for language: ", current_language)
			var font = load(fonts[current_language])
			if font:
				rich_text_label.add_theme_font_override("normal_font", font)
				print("Font loaded and set successfully")
			else:
				print("Failed to load font: ", fonts[current_language])
	
	var page = current_pages[current_page_index]
	var speaker = page["speaker"]
	var speaker_color = current_characters[speaker]["name_color"]
	var text_color = current_characters[speaker]["text_color"]
	
	# スピード設定を取得（ページごとの設定があれば上書き）
	var text_speed = current_characters[speaker]["text_speed"]
	if "text_speed" in page:
		text_speed = page["text_speed"]
	
	current_dialogue.show_message(speaker, speaker_color, page["text"], text_color, text_speed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and is_dialogue_open:
		if not current_dialogue.is_text_completed:
			current_dialogue.skip_text()
		elif current_dialogue.is_text_completed and current_page_index < current_pages.size() - 1:
			current_page_index += 1
			show_current_page()
		elif current_dialogue.is_text_completed:
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

# 言語設定の変更
func set_language(language: String) -> void:
	print("Setting language from ", current_language, " to ", language)
	current_language = language
	print("Dialogue language set to: ", current_language)
