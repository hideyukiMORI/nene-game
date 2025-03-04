extends Control

@onready var message_text: RichTextLabel = $NinePatchRect/RichTextLabel

var text_speed: float = 0.05  # 1文字の表示時間（秒）
var is_text_completed: bool = false
var scroll_speed: int = 10  # スクロール速度

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var v_scroll_bar = message_text.get_v_scroll_bar()
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color("ffffff")  # 白色
	
	v_scroll_bar.add_theme_stylebox_override("grabber", style_box)  # つまみの部分
	v_scroll_bar.modulate = Color("ffffff")  # スクロールバー全体

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_text_completed:
		return
		
	# キーボードでのスクロール
	var scroll = 0
	if Input.is_action_pressed("ui_up"):
		scroll -= scroll_speed  # ピクセル単位のスクロール量
	elif Input.is_action_pressed("ui_down"):
		scroll += scroll_speed
		
	if scroll != 0:
		var v_scroll_bar = message_text.get_v_scroll_bar()
		v_scroll_bar.value += scroll  # 直接スクロールバーの値を変更

func _input(event: InputEvent) -> void:
	if not is_text_completed:
		return
		
	# マウスホイールでのスクロール
	if event is InputEventMouseButton:
		var scroll = 0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll -= scroll_speed * 2
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll += scroll_speed * 2
			
		if scroll != 0:
			var v_scroll_bar = message_text.get_v_scroll_bar()
			v_scroll_bar.value += scroll  # 直接スクロールバーの値を変更

func show_message(text: String) -> void:
	message_text.scroll_to_line(0)
	message_text.text = text
	message_text.visible_characters = 0
	is_text_completed = false
	
	var plain_text = message_text.get_parsed_text()
	var newline_pause: float = 0.3  # 改行時の待ち時間（秒）
	var space_pause: float = 0.03  # スペース時の待ち時間（秒）
	
	var tween = create_tween()
	for i in range(plain_text.length()):
		var current_char = plain_text[i]
		
		# 文字を表示
		tween.tween_property(
			message_text,
			"visible_characters",
			i + 1,
			text_speed
		).set_trans(Tween.TRANS_LINEAR)
		
		# 改行の場合は追加の待ち時間
		if current_char == "\n":
			tween.tween_interval(newline_pause)
		# スペースの場合は追加の待ち時間
		elif current_char == " ":
			tween.tween_interval(space_pause)
		# 通常の文字の場合は音を鳴らす
		elif current_char != " " and current_char != "　":
			tween.tween_callback(func(): AudioManager.play_se("PI01"))
	
	tween.finished.connect(func(): is_text_completed = true)

# 文字送りをスキップする機能
func skip_text() -> void:
	if not is_text_completed:
		message_text.visible_characters = -1  # 全文字表示
		is_text_completed = true
