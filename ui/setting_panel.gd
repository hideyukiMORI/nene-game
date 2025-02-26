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
	_load_settings()
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
	current_selection = (current_selection + direction + menu_labels.size()) % menu_labels.size()
	_update_menu_selection()
	AudioManager.play_se("CURSOR")

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
		4: _toggle_settings_panel_visibility()

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
		4: _toggle_settings_panel_visibility()

func _change_volume(slider: Slider, step: int) -> void:
	"""
	指定されたステップでスライダーのボリュームを変更します。
	:param slider: ボリュームを変更するスライダー。
	:param step: ボリュームを変更する量。
	"""
	slider.value = clamp(slider.value + step, MIN_VOLUME, MAX_VOLUME)
	slider.release_focus()

func _save_settings() -> void:
	"""
	現在のオーディオ設定とフルスクリーン設定をファイルに保存します。
	"""
	var config = ConfigFile.new()
	config.set_value("audio", "bgm_volume", AudioManager.bgm_volume)
	config.set_value("audio", "se_volume", AudioManager.se_volume)
	config.set_value("audio", "sound_enabled", AudioManager.sound_enabled)
	config.set_value("display", "fullscreen", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	var err = config.save("user://settings.cfg")
	if err == OK:
		print("Settings saved successfully")
	else:
		print("Failed to save settings")

func _load_settings() -> void:
	"""
	保存されたオーディオ設定とフルスクリーン設定を読み込みます。
	"""
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
	else:
		print("Error: Failed to load settings.cfg")

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
	else:
		print("Failed to load settings.cfg")
