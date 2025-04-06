extends Control

@onready var settings_panel = self
@onready var scroll_container = $Panel/ScrollContainer
@onready var button_sound_on = $Panel/ScrollContainer/SettingList/Sound/OnButton
@onready var button_sound_off = $Panel/ScrollContainer/SettingList/Sound/OffButton
@onready var label_bgm_volume = $Panel/ScrollContainer/SettingList/BGM/BGMValue
@onready var volume_slider_bgm = $Panel/ScrollContainer/SettingList/BGM/VolumeSlider
@onready var label_se_volume = $Panel/ScrollContainer/SettingList/SE/SEValue
@onready var volume_slider_se = $Panel/ScrollContainer/SettingList/SE/VolumeSlider
@onready var button_fullscreen_on = $Panel/ScrollContainer/SettingList/Fullscreen/OnButton
@onready var button_fullscreen_off = $Panel/ScrollContainer/SettingList/Fullscreen/OffButton
@onready var button_language = $Panel/ScrollContainer/SettingList/Language/OptionButton
@onready var button_close = $Panel/ScrollContainer/SettingList/Exit/CloseButton
@onready var icon_close = $Panel/CloseIcon

var dragging = false
var last_mouse_position = Vector2()
var current_selection = 0
var is_paused = false

@onready var menu_labels = [
	$Panel/ScrollContainer/SettingList/Sound/Label,
	$Panel/ScrollContainer/SettingList/BGM/Label,
	$Panel/ScrollContainer/SettingList/SE/Label,
	$Panel/ScrollContainer/SettingList/Fullscreen/Label,
	$Panel/ScrollContainer/SettingList/Language/Label,
	$Panel/ScrollContainer/SettingList/Exit/Label
]

const MAX_VOLUME = 100
const MIN_VOLUME = 0
const VOLUME_STEP = 10

func _ready() -> void:
	"""
	設定パネルを初期化し、パネルの可視性を設定し、シグナルを接続し、
	メニュー選択を更新します。
	"""
	# デフォルトで英語に設定
	button_language.selected = 0
	_load_settings()  # 最初に設定を読み込む
	_initialize_panel()
	_connect_signals()
	_update_menu_selection()
	_check_config_file()

func _initialize_panel() -> void:
	"""
	設定パネルの初期可視性を設定し、ボタンの状態とボリュームスライダーを初期化します。
	"""
	settings_panel.visible = false
	_toggle_buttons([button_sound_on, button_sound_off, button_fullscreen_on, button_fullscreen_off], true)
	_update_button_states()
	_update_label_bgm_volume(false)
	_update_label_se_volume(false)
	volume_slider_bgm.value = AudioManager.bgm_volume * MAX_VOLUME
	volume_slider_se.value = AudioManager.se_volume * MAX_VOLUME

func _toggle_buttons(buttons: Array, toggle_mode: bool) -> void:
	"""
	ボタンのリストに対してトグルモードを設定します。
	:param buttons: トグルモードを設定するボタンの配列。
	:param toggle_mode: トグルモードを示すブール値。
	"""
	for button in buttons:
		button.toggle_mode = toggle_mode

func _connect_signals() -> void:
	"""
	ボタンとスライダーのシグナルをそれぞれのハンドラ関数に接続します。
	"""
	button_sound_on.connect("pressed", Callable(self, "_on_sound_on_pressed"))
	button_sound_off.connect("pressed", Callable(self, "_on_sound_off_pressed"))
	volume_slider_bgm.connect("value_changed", Callable(self, "_on_bgm_slider_value_changed"))
	volume_slider_se.connect("value_changed", Callable(self, "_on_se_slider_value_changed"))
	button_fullscreen_on.connect("pressed", Callable(self, "_on_fullscreen_on_pressed"))
	button_fullscreen_off.connect("pressed", Callable(self, "_on_fullscreen_off_pressed"))
	button_close.connect("pressed", Callable(self, "_toggle_settings_panel_visibility"))
	icon_close.connect("pressed", Callable(self, "_toggle_settings_panel_visibility"))
	button_language.item_selected.connect(_on_language_changed)

func _update_button_states() -> void:
	"""
	現在の設定に基づいて、サウンドとフルスクリーンボタンの押下状態を更新します。
	"""
	button_sound_on.set_pressed(AudioManager.sound_enabled)
	button_sound_off.set_pressed(!AudioManager.sound_enabled)
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	button_fullscreen_on.set_pressed(is_fullscreen)
	button_fullscreen_off.set_pressed(!is_fullscreen)

func _on_sound_on_pressed() -> void:
	"""
	サウンドオンボタンが押されたときのイベントを処理します。サウンドを有効にし、
	ボタンの状態を更新します。
	"""
	current_selection = 0
	if AudioManager.sound_enabled:
		button_sound_on.set_pressed(true)
		_update_menu_selection()
		return
	AudioManager.sound_enabled = true
	print("Sound enabled set to true")
	_update_button_states()
	_update_menu_selection()
	_save_settings()
	AudioManager.play_se("CURSOR")

func _on_sound_off_pressed() -> void:
	"""
	サウンドオフボタンが押されたときのイベントを処理します。サウンドを無効にし、
	ボタンの状態を更新します。
	"""
	current_selection = 0
	if !AudioManager.sound_enabled:
		button_sound_off.set_pressed(true)
		_update_menu_selection()
		return
	AudioManager.sound_enabled = false
	print("Sound enabled set to false")
	_update_button_states()
	_update_menu_selection()
	_save_settings()
	AudioManager.play_se("CURSOR")

func _on_fullscreen_on_pressed() -> void:
	"""
	フルスクリーンオンボタンが押されたときのイベントを処理します。ウィンドウを
	フルスクリーンモードに設定します。
	"""
	current_selection = 3
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		button_fullscreen_on.set_pressed(true)
		_update_menu_selection()
		return
	_set_fullscreen_mode(true)
	_update_menu_selection()
	AudioManager.play_se("CURSOR")

func _on_fullscreen_off_pressed() -> void:
	"""
	フルスクリーンオフボタンが押されたときのイベントを処理します。ウィンドウを
	ウィンドウモードに設定します。
	"""
	current_selection = 3
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		button_fullscreen_off.set_pressed(true)
		_update_menu_selection()
		return
	_set_fullscreen_mode(false)
	_update_menu_selection()
	AudioManager.play_se("CURSOR")

func _set_fullscreen_mode(enable_fullscreen: bool) -> void:
	"""
	ウィンドウのモードをフルスクリーンまたはウィンドウモードに設定します。
	:param enable_fullscreen: フルスクリーンを有効にするかどうかを示すブール値。
	"""
	var current_mode = DisplayServer.window_get_mode()
	var new_mode = DisplayServer.WINDOW_MODE_FULLSCREEN if enable_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if current_mode != new_mode:
		DisplayServer.window_set_mode(new_mode)
		AudioManager.play_se("CURSOR")
	button_fullscreen_on.set_pressed(enable_fullscreen)
	button_fullscreen_off.set_pressed(!enable_fullscreen)
	_save_settings()

func _input(event: InputEvent) -> void:
	"""
	設定パネルのトグルと、パネルが表示されているときの入力を処理します。
	:param event: 処理する入力イベント。
	"""
	if DialogueManager.is_dialogue_open:
		return
	if event.is_action_pressed("select") and !is_paused:
		_toggle_settings_panel_visibility()
	elif settings_panel.visible:
		_handle_input(event)

func _handle_input(event: InputEvent) -> void:
	"""
	マウスとキーボードのインタラクションの入力イベントを処理します。
	:param event: 処理する入力イベント。
	"""
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and dragging:
		_handle_mouse_motion(event)
	elif event.is_action_pressed("ui_down"):
		_change_selection(1)
	elif event.is_action_pressed("ui_up"):
		_change_selection(-1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("jump"):
		_handle_right_action()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("dash"):
		_handle_left_action()

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	"""
	ドラッグ機能のためのマウスボタンイベントを処理します。
	:param event: 処理するマウスボタンイベント。
	"""
	if event.pressed:
		dragging = true
		last_mouse_position = event.position
	else:
		dragging = false

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	"""
	コンテナをスクロールするためのマウスモーションイベントを処理します。
	:param event: 処理するマウスモーションイベント。
	"""
	var delta = event.position - last_mouse_position
	scroll_container.scroll_vertical -= delta.y
	scroll_container.scroll_horizontal -= delta.x
	last_mouse_position = event.position

func _change_selection(direction: int) -> void:
	"""
	方向に基づいて現在のメニュー選択を変更します。
	:param direction: 選択を変更する方向（1は下、-1は上）。
	"""
	print("\n=== 選択変更 ===")
	print("現在の選択: ", current_selection)
	print("変更方向: ", direction)
	
	current_selection = (current_selection + direction + menu_labels.size()) % menu_labels.size()
	print("新しい選択: ", current_selection)
	
	_update_menu_selection()
	_ensure_visible(current_selection)
	AudioManager.play_se("CURSOR")
	
	print("=== 選択変更終了 ===\n")

func _ensure_visible(index: int) -> void:
	if index < 0 or index >= menu_labels.size():
		return
		
	var item = menu_labels[index]
	var scroll_container = $Panel/ScrollContainer
	
	# アイテムの位置を取得
	var item_global_pos = item.get_global_position()
	var container_global_pos = scroll_container.get_global_position()
	var item_local_pos = item_global_pos - container_global_pos
	
	print("選択アイテム: ", index)
	print("アイテムの位置: ", item_local_pos)
	print("ビューポートサイズ: ", scroll_container.size)
	print("現在のスクロール位置: ", scroll_container.scroll_vertical)
	
	# アイテムをビューポートの中央に配置
	var viewport_center = scroll_container.size.y / 2
	var item_center = item_local_pos.y + item.size.y / 2
	var target_scroll = item_center - viewport_center
	
	print("ターゲットスクロール位置: ", target_scroll)
	
	# スムーズなスクロールアニメーション
	var tween = create_tween()
	tween.tween_property(scroll_container, "scroll_vertical", target_scroll, 0.2)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)

func _toggle_settings_panel_visibility() -> void:
	"""
	設定パネルの可視性をトグルし、ゲームの一時停止状態を更新します。
	"""
	settings_panel.visible = not settings_panel.visible
	current_selection = 0
	get_tree().paused = settings_panel.visible
	_update_menu_selection()

func _on_bgm_slider_value_changed(value: float) -> void:
	if value < MIN_VOLUME or value > MAX_VOLUME:
		print("Warning: BGM slider value out of range")
	else:
		AudioManager.set_bgm_volume(value / MAX_VOLUME)
	_update_label_bgm_volume()
	current_selection = 1
	volume_slider_bgm.release_focus()
	_update_menu_selection()
	_save_settings()

func _on_se_slider_value_changed(value: float) -> void:
	if value < MIN_VOLUME or value > MAX_VOLUME:
		print("Warning: SE slider value out of range")
	else:
		AudioManager.set_se_volume(value / MAX_VOLUME)
	_update_label_se_volume()
	current_selection = 2
	volume_slider_bgm.release_focus()
	_update_menu_selection()
	_save_settings()

func _update_label_bgm_volume(play_se: bool = true) -> void:
	"""
	BGMボリュームラベルのテキストを更新し、オプションで効果音を再生します。
	:param play_se: 効果音を再生するかどうかを示すブール値。
	"""
	label_bgm_volume.text = _get_volume_text(int(AudioManager.bgm_volume * MAX_VOLUME))
	if play_se:
		AudioManager.play_se("CURSOR")

func _update_label_se_volume(play_se: bool = true) -> void:
	"""
	SEボリュームラベルのテキストを更新し、オプションで効果音を再生します。
	:param play_se: 効果音を再生するかどうかを示すブール値。
	"""
	label_se_volume.text = _get_volume_text(int(AudioManager.se_volume * MAX_VOLUME))
	if play_se:
		AudioManager.play_se("CURSOR")

func _get_volume_text(volume: int) -> String:
	"""
	ボリュームレベルを表すフォーマットされた文字列を返します。
	:param volume: フォーマットするボリュームレベル。
	:return: ボリュームレベルを表す文字列。
	"""
	if volume == MIN_VOLUME:
		return "OFF"
	elif volume == MAX_VOLUME:
		return "MAX"
	else:
		return str(volume).pad_zeros(3)

func _update_menu_selection() -> void:
	"""
	現在の選択を反映するようにメニューラベルを更新します。
	"""
	for i in range(menu_labels.size()):
		menu_labels[i].text = ">> " + _remove_prefix(menu_labels[i].text, ">> ") if i == current_selection else _remove_prefix(menu_labels[i].text, ">> ")

func _remove_prefix(text: String, prefix: String) -> String:
	"""
	文字列からプレフィックスを削除します（存在する場合）。
	:param text: プレフィックスを削除するテキスト。
	:param prefix: 削除するプレフィックス。
	:return: プレフィックスを削除したテキスト。
	"""
	return text.substr(prefix.length()) if text.begins_with(prefix) else text

func _handle_right_action() -> void:
	"""
	現在のメニュー選択に対する右アクション入力を処理します。
	"""
	match current_selection:
		0: 
			if !AudioManager.sound_enabled:
				AudioManager.toggle_sound(true)
				AudioManager.play_se("CURSOR")
			_save_settings()
			_update_button_states()
		1: _change_volume(volume_slider_bgm, VOLUME_STEP)
		2: _change_volume(volume_slider_se, VOLUME_STEP)
		3: _set_fullscreen_mode(true)
		4: _next_language()
		5: _toggle_settings_panel_visibility()

func _handle_left_action() -> void:
	"""
	現在のメニュー選択に対する左アクション入力を処理します。
	"""
	match current_selection:
		0: 
			if AudioManager.sound_enabled:
				AudioManager.toggle_sound(false)
				AudioManager.play_se("CURSOR")
			_save_settings()
			_update_button_states()
		1: _change_volume(volume_slider_bgm, -VOLUME_STEP)
		2: _change_volume(volume_slider_se, -VOLUME_STEP)
		3: _set_fullscreen_mode(false)
		4: _prev_language()
		5: _toggle_settings_panel_visibility()

func _change_volume(slider: Slider, step: int) -> void:
	"""
	指定されたステップでスライダーのボリュームを変更します。
	:param slider: ボリュームを変更するスライダー。
	:param step: ボリュームを変更する量。
	"""
	slider.value = clamp(slider.value + step, MIN_VOLUME, MAX_VOLUME)
	slider.release_focus()

func _next_language() -> void:
	"""
	次の言語を選択します。
	"""
	var option_button = $Panel/ScrollContainer/SettingList/Language/OptionButton
	var current_index = option_button.selected
	var next_index = (current_index + 1) % option_button.item_count
	option_button.selected = next_index
	AudioManager.play_se("CURSOR")
	_on_language_changed(next_index)  # 言語変更イベントを発火
	_save_settings()

func _prev_language() -> void:
	"""
	前の言語を選択します。
	"""
	var option_button = $Panel/ScrollContainer/SettingList/Language/OptionButton
	var current_index = option_button.selected
	var prev_index = (current_index - 1 + option_button.item_count) % option_button.item_count
	option_button.selected = prev_index
	AudioManager.play_se("CURSOR")
	_on_language_changed(prev_index)  # 言語変更イベントを発火
	_save_settings()

func _save_settings() -> void:
	"""
	現在の設定を保存します。
	"""
	print("\n=== 設定の保存 ===")
	print("現在の言語インデックス: ", button_language.selected)
	print("現在のGameState言語: ", GameState.current_language)
	
	var config = ConfigFile.new()
	config.set_value("audio", "sound_enabled", AudioManager.sound_enabled)
	config.set_value("audio", "bgm_volume", AudioManager.bgm_volume)
	config.set_value("audio", "se_volume", AudioManager.se_volume)
	config.set_value("display", "fullscreen", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# 言語設定の保存を修正
	# GameStateの言語設定を優先して保存
	config.set_value("language", "current", GameState.current_language)
	
	var err = config.save("user://settings.cfg")
	if err == OK:
		print("設定を保存しました")
		print("保存した言語: ", GameState.current_language)
	else:
		print("設定の保存に失敗しました: ", err)
	print("=== 設定の保存終了 ===\n")

func _load_settings() -> void:
	"""
	保存されたオーディオ設定とフルスクリーン設定を読み込みます。
	"""
	print("\n=== 設定の読み込み ===")
	print("読み込み前の言語インデックス: ", button_language.selected)
	print("読み込み前のGameState言語: ", GameState.current_language)
	
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		print("settings.cfg loaded")
		var bgm_volume = config.get_value("audio", "bgm_volume", 1.0)
		if bgm_volume < 0 or bgm_volume > 1:
			print("Warning: BGM volume out of range, resetting to default")
			bgm_volume = 1.0
		AudioManager.set_bgm_volume(bgm_volume)
		AudioManager.set_se_volume(config.get_value("audio", "se_volume", 1.0))
		var sound_enabled = config.get_value("audio", "sound_enabled", true)
		print("Loaded sound_enabled: ", sound_enabled)
		AudioManager.toggle_sound(sound_enabled)
		var fullscreen = config.get_value("display", "fullscreen", false)
		_set_fullscreen_mode(fullscreen)
		
		# 言語設定の読み込みを修正
		var language_value = config.get_value("language", "current", GameState.current_language)
		print("設定ファイルから読み込んだ言語値: ", language_value)
		print("言語値の型: ", typeof(language_value))
		
		# 型を確認して適切に変換
		var language: String
		if language_value is int:
			print("言語値がint型です")
			# int型の場合はインデックスとして扱う
			language = "en" if language_value == 0 else "ja"
			print("変換後の言語: ", language)
		elif language_value is String:
			print("言語値がString型です")
			# String型の場合はそのまま使用
			language = language_value
			print("そのまま使用する言語: ", language)
		else:
			print("言語値が予期しない型です: ", typeof(language_value))
			# その他の型の場合は現在の言語設定を維持
			language = GameState.current_language
			print("現在の言語を維持: ", language)
		
		# 有効な言語かチェック
		if not (language == "en" or language == "ja"):
			print("無効な言語値です: ", language)
			# 無効な値の場合は現在の言語設定を維持
			language = GameState.current_language
			print("現在の言語を維持: ", language)
		
		# 言語が変更された場合のみ更新
		if language != GameState.current_language:
			print("言語が変更されました: ", GameState.current_language, " -> ", language)
			GameState.set_language(language)
		else:
			print("言語は変更されていません: ", language)
		
		# UIの更新（言語設定に関係なく常に更新）
		var new_selected = 0 if language == "en" else 1
		print("UI更新前の選択: ", button_language.selected)
		print("UI更新後の選択: ", new_selected)
		button_language.selected = new_selected
	else:
		print("Error: Failed to load settings.cfg")
		# デフォルト設定を維持
		print("デフォルト設定を維持します: ", button_language.selected)
		button_language.selected = 0
		GameState.set_language("en")
	
	print("読み込み後の言語インデックス: ", button_language.selected)
	print("読み込み後のGameState言語: ", GameState.current_language)
	print("=== 設定の読み込み終了 ===\n")

func _check_config_file() -> void:
	"""
	設定ファイルが存在するかどうかを確認します。
	"""
	if not FileAccess.file_exists("user://settings.cfg"):
		print("settings.cfg not found, creating new file")
		_save_settings()
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		print("BGM Volume: ", config.get_value("audio", "bgm_volume", 1.0))
		print("SE Volume: ", config.get_value("audio", "se_volume", 1.0))
		print("Sound Enabled: ", config.get_value("audio", "sound_enabled", true))
		print("Fullscreen: ", config.get_value("display", "fullscreen", false))
		print("Language: ", config.get_value("language", "current", 0))
	else:
		print("Failed to load settings.cfg")

func _on_language_changed(_index: int) -> void:
	"""
	言語設定が変更されたときのイベントを処理します。
	:param _index: 選択された言語のインデックス。
	"""
	AudioManager.play_se("CURSOR")
	_save_settings()
	# GameStateの言語設定を更新
	var language = "en" if _index == 0 else "ja"
	GameState.set_language(language)
