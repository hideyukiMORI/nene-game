extends Control

@onready var message_text: RichTextLabel = $NinePatchRect/RichTextLabel
@onready var arrow_next_page = $NinePatchRect/ArrowNextPage

var is_text_completed: bool = true
var scroll_speed: int = 10  # スクロール速度
var current_tween: Tween = null  # 現在実行中のtweenを保持


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var v_scroll_bar = message_text.get_v_scroll_bar()
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color("ffffff")  # 白色
	
	v_scroll_bar.add_theme_stylebox_override("grabber", style_box)  # つまみの部分
	v_scroll_bar.modulate = Color("ffffff")  # スクロールバー全体

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
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

func show_message(speaker: String, speaker_color: String, text: String, text_color: String, text_speed: float) -> void:
	if !is_text_completed:
		return
	is_text_completed = false
	arrow_next_page.visible = false
	message_text.scroll_to_line(0)
	
	# 話者名と本文を色付きで結合
	var formatted_text = "[color=%s]%s[/color]:\n[color=%s]%s[/color]" % [
		speaker_color,
		speaker,
		text_color,
		text
	]
	
	message_text.text = formatted_text
	message_text.visible_characters = 0
	
	var plain_text = message_text.get_parsed_text()
	var newline_pause: float = 0.3
	var space_pause: float = 0.03
	
	# 既存のtweenがあれば停止
	if current_tween:
		current_tween.kill()
	
	current_tween = create_tween()
	for i in range(plain_text.length()):
		var current_char = plain_text[i]
		
		current_tween.tween_property(
			message_text,
			"visible_characters",
			i + 1,
			text_speed
		).set_trans(Tween.TRANS_LINEAR)
		
		if current_char == "\n":
			current_tween.tween_interval(newline_pause)
		elif current_char == " ":
			current_tween.tween_interval(space_pause)
		elif current_char != " " and current_char != "　":
			current_tween.tween_callback(func(): AudioManager.play_se("PI01"))
	
	current_tween.finished.connect(func(): _on_tween_finished())

func skip_text() -> void:
	if not is_text_completed:
		# 実行中のtweenを停止
		if current_tween:
			current_tween.kill()
			current_tween = null
		
		message_text.visible_characters = -1  # 全文字表示
		is_text_completed = true
		_on_tween_finished()  # 矢印表示も更新

func _on_tween_finished() -> void:
	arrow_next_page.visible = true
	is_text_completed = true
