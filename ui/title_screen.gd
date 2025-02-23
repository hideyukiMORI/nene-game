extends Control

# Declare the StartSound variable
@onready var start_sound = $StartSound
@onready var settings_panel = $SettingPanel  # 追加したPanelノードを参照
@onready var scroll_container = $SettingPanel/ScrollContainer  # 追加したScrollContainerノードを参照
@onready var button_sound_on = $SettingPanel/ScrollContainer/SettingList/Sound/OnButton
@onready var button_sound_off = $SettingPanel/ScrollContainer/SettingList/Sound/OffButton
@onready var label_bgm_volume = $SettingPanel/ScrollContainer/SettingList/BGM/BGMValue
@onready var volume_slider_bgm = $SettingPanel/ScrollContainer/SettingList/BGM/VolumeSlider
@onready var label_se_volume = $SettingPanel/ScrollContainer/SettingList/SE/SEValue
@onready var volume_slider_se = $SettingPanel/ScrollContainer/SettingList/SE/VolumeSlider
@onready var button_fullscreen_on = $SettingPanel/ScrollContainer/SettingList/Fullscreen/OnButton
@onready var button_fullscreen_off = $SettingPanel/ScrollContainer/SettingList/Fullscreen/OffButton
@onready var button_close = $SettingPanel/ScrollContainer/SettingList/CloseButton
@onready var icon_close = $SettingPanel/CloseIcon

var dragging = false
var last_mouse_position = Vector2()
var sound_enabled = true
var bgm_volume = 50
var se_volume = 50

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
	_update_label_bgm_volume()
	_update_label_se_volume()

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

func _update_button_states() -> void:
	# sound_enabledの状態に基づいてボタンの状態を設定
	button_sound_on.set_pressed(sound_enabled)
	button_sound_off.set_pressed(!sound_enabled)
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	button_fullscreen_on.set_pressed(is_fullscreen)
	button_fullscreen_off.set_pressed(!is_fullscreen)

func _on_button_toggled(button_pressed: bool, button: Button) -> void:
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
	elif button == button_fullscreen_on:
		var is_fullscreen = button_pressed
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if is_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		button_fullscreen_off.set_pressed(!is_fullscreen)
	elif button == button_fullscreen_off:
		var is_fullscreen = !button_pressed
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if is_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		button_fullscreen_on.set_pressed(is_fullscreen)

func _input(event: InputEvent) -> void:
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

	if event.is_action_pressed("ui_select") or event.is_action_pressed("start"):
		# Play the start sound
		start_sound.play()
		# Connect the finished signal to a function to change the scene
		start_sound.connect("finished", Callable(self, "_on_start_sound_finished"))

	if event.is_action_pressed("select"):
		# Panelの表示をトグル
		_toggle_settings_panel_visibility()

func _toggle_settings_panel_visibility() -> void:
	settings_panel.visible = not settings_panel.visible

func _on_start_sound_finished() -> void:
	# Change the scene after the sound has finished playing
	get_tree().change_scene_to_file(GameState.game_scene)

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

func _update_label_bgm_volume() -> void:
	# bgm_volumeに応じてラベルを更新
	if bgm_volume == 0:
		label_bgm_volume.text = "OFF"
	elif bgm_volume == 100:
		label_bgm_volume.text = "MAX"
	else:
		label_bgm_volume.text = str(bgm_volume).pad_zeros(3)

func _update_label_se_volume() -> void:
	# se_volumeに応じてラベルを更新
	if se_volume == 0:
		label_se_volume.text = "OFF"
	elif se_volume == 100:
		label_se_volume.text = "MAX"
	else:
		label_se_volume.text = str(se_volume).pad_zeros(3)
