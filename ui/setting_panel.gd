extends Control

@onready var settings_panel = self  # ルートノードを指す
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
var sound_enabled = true
var bgm_volume = 50
var se_volume = 50
var updating_fullscreen = false
var current_selection = 0
var is_paused = false

@onready var menu_labels = [
	$Panel/ScrollContainer/SettingList/Sound/Label,
	$Panel/ScrollContainer/SettingList/BGM/Label,
	$Panel/ScrollContainer/SettingList/SE/Label,
	$Panel/ScrollContainer/SettingList/Fullscreen/Label,
	$Panel/ScrollContainer/SettingList/Exit/Label
]

func _ready() -> void:
	# Panelを非表示に設定
	settings_panel.visible = false
	# トグルモードを有効にする
	button_sound_on.toggle_mode = true
	button_sound_off.toggle_mode = true
	button_fullscreen_on.toggle_mode = true
	button_fullscreen_off.toggle_mode = true

	# 初期状態を設定
	_update_button_states()
	# ラベルの初期値を設定
	_update_label_bgm_volume(false)
	_update_label_se_volume(false)

	# スライダーの初期値を設定
	volume_slider_bgm.value = bgm_volume
	volume_slider_se.value = se_volume
	# シグナル接続
	button_sound_on.connect("toggled", Callable(self, "_on_button_toggled").bind(button_sound_on))
	button_sound_off.connect("toggled", Callable(self, "_on_button_toggled").bind(button_sound_off))
	volume_slider_bgm.connect("value_changed", Callable(self, "_on_bgm_volume_slider_changed"))
	volume_slider_se.connect("value_changed", Callable(self, "_on_se_volume_slider_changed"))
	button_fullscreen_on.connect("toggled", Callable(self, "_on_button_toggled").bind(button_fullscreen_on))
	button_fullscreen_off.connect("toggled", Callable(self, "_on_button_toggled").bind(button_fullscreen_off))
	button_close.connect("pressed", Callable(self, "_toggle_settings_panel_visibility"))
	icon_close.connect("pressed", Callable(self, "_toggle_settings_panel_visibility"))

	_update_menu_selection()

func _update_button_states() -> void:
	# sound_enabledの状態に基づいてボタンの状態を設定
	button_sound_on.set_pressed(sound_enabled)
	button_sound_off.set_pressed(!sound_enabled)
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	button_fullscreen_on.set_pressed(is_fullscreen)
	button_fullscreen_off.set_pressed(!is_fullscreen)

func _on_button_toggled(button_pressed: bool, button: Button) -> void:
	if updating_fullscreen:
		return

	if button == button_sound_on:
		sound_enabled = button_pressed
		button_sound_off.disconnect("toggled", Callable(self, "_on_button_toggled"))
		button_sound_off.set_pressed(!button_pressed)
		button_sound_off.connect("toggled", Callable(self, "_on_button_toggled").bind(button_sound_off))
	elif button == button_sound_off:
		sound_enabled = !button_pressed
		button_sound_on.disconnect("toggled", Callable(self, "_on_button_toggled"))
		button_sound_on.set_pressed(!button_pressed)
		button_sound_on.connect("toggled", Callable(self, "_on_button_toggled").bind(button_sound_on))
	elif button == button_fullscreen_on or button == button_fullscreen_off:
		updating_fullscreen = true
		var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if !is_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		is_fullscreen = !is_fullscreen # モードを切り替えた後に状態を更新

		button_fullscreen_on.set_pressed(is_fullscreen)
		button_fullscreen_off.set_pressed(!is_fullscreen)
		updating_fullscreen = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select") and !is_paused:
		_toggle_settings_panel_visibility()

	elif settings_panel.visible:
		if event is InputEventMouseButton:
			if event.pressed:
				dragging = true
				last_mouse_position = event.position
			else:
				dragging = false

		if event is InputEventMouseMotion and dragging:
			var delta = event.position - last_mouse_position
			scroll_container.scroll_vertical -= delta.y
			scroll_container.scroll_horizontal -= delta.x
			last_mouse_position = event.position


		if event.is_action_pressed("ui_down"):
			current_selection = (current_selection + 1) % menu_labels.size()
			_update_menu_selection()
			AudioManager.play_se("CURSOR")
		elif event.is_action_pressed("ui_up"):
			current_selection = (current_selection - 1 + menu_labels.size()) % menu_labels.size()
			_update_menu_selection()
			AudioManager.play_se("CURSOR")
		elif event.is_action_pressed("ui_right") or event.is_action_pressed("jump"):
			_handle_right_action()
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("dash"):
			_handle_left_action()

func _toggle_settings_panel_visibility() -> void:
	settings_panel.visible = not settings_panel.visible
	current_selection = 0
	get_tree().paused = settings_panel.visible
	_update_menu_selection()


func _on_bgm_volume_slider_changed(value: float) -> void:
	# bgm_volumeを更新
	bgm_volume = int(value)

	# ラベルを更新
	_update_label_bgm_volume()

func _on_se_volume_slider_changed(value: float) -> void:
	# bgm_volumeを更新
	se_volume = int(value)

	# ラベルを更新
	_update_label_se_volume()

func _update_label_bgm_volume(play_se: bool = true) -> void:
	# bgm_volumeに応じてラベルを更新
	if bgm_volume == 0:
		label_bgm_volume.text = "OFF"
	elif bgm_volume == 100:
		label_bgm_volume.text = "MAX"
	else:
		label_bgm_volume.text = str(bgm_volume).pad_zeros(3)
		if play_se:
			AudioManager.play_se("CURSOR")

func _update_label_se_volume(play_se: bool = true) -> void:
	# se_volumeに応じてラベルを更新
	if se_volume == 0:
		label_se_volume.text = "OFF"
	elif se_volume == 100:
		label_se_volume.text = "MAX"
	else:
		label_se_volume.text = str(se_volume).pad_zeros(3)
		if play_se:
			AudioManager.play_se("CURSOR")

func _update_menu_selection() -> void:
	for i in range(menu_labels.size()):
		if i == current_selection:
			menu_labels[i].text = ">> " + _remove_prefix(menu_labels[i].text, ">> ")
		else:
			menu_labels[i].text = _remove_prefix(menu_labels[i].text, ">> ")

func _remove_prefix(text: String, prefix: String) -> String:
	if text.begins_with(prefix):
		return text.substr(prefix.length())
	return text

func _handle_right_action() -> void:
	match current_selection:
		0: # SOUND
			sound_enabled = !sound_enabled
			button_sound_on.set_pressed(sound_enabled)
			button_sound_off.set_pressed(!sound_enabled)
			AudioManager.play_se("CURSOR")
		1: # BGM
			bgm_volume = min(bgm_volume + 10, 100)
			volume_slider_bgm.value = bgm_volume
		2: # SE
			se_volume = min(se_volume + 10, 100)
			volume_slider_se.value = se_volume
		3: # FULLSCREEN
			_toggle_fullscreen()
			AudioManager.play_se("CURSOR")
		4: # EXIT
			_toggle_settings_panel_visibility()
			AudioManager.play_se("CURSOR")

func _handle_left_action() -> void:
	match current_selection:
		0: # SOUND
			sound_enabled = !sound_enabled
			button_sound_on.set_pressed(sound_enabled)
			button_sound_off.set_pressed(!sound_enabled)
			AudioManager.play_se("CURSOR")
		1: # BGM
			bgm_volume = max(bgm_volume - 10, 0)
			volume_slider_bgm.value = bgm_volume
		2: # SE
			se_volume = max(se_volume - 10, 0)
			volume_slider_se.value = se_volume
		3: # FULLSCREEN
			_toggle_fullscreen()
			AudioManager.play_se("CURSOR")
		4: # EXIT
			_toggle_settings_panel_visibility()
			AudioManager.play_se("CURSOR")


func _toggle_fullscreen() -> void:
	if updating_fullscreen:
		return

	updating_fullscreen = true
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if !is_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	is_fullscreen = !is_fullscreen # モードを切り替えた後に状態を更新

	button_fullscreen_on.set_pressed(is_fullscreen)
	button_fullscreen_off.set_pressed(!is_fullscreen)
	updating_fullscreen = false
