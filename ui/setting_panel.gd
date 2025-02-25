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
var current_selection = 0
var is_paused = false
var updating_fullscreen = false
var sound_enabled = false

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
	_initialize_panel()
	_connect_signals()
	_update_menu_selection()

func _initialize_panel() -> void:
	settings_panel.visible = false
	_toggle_buttons([button_sound_on, button_sound_off, button_fullscreen_on, button_fullscreen_off], true)
	_update_button_states()
	_update_label_bgm_volume(false)
	_update_label_se_volume(false)
	volume_slider_bgm.value = AudioManager.bgm_volume * MAX_VOLUME
	volume_slider_se.value = AudioManager.se_volume * MAX_VOLUME

func _toggle_buttons(buttons: Array, toggle_mode: bool) -> void:
	for button in buttons:
		button.toggle_mode = toggle_mode

func _connect_signals() -> void:
	button_sound_on.connect("toggled", Callable(self, "_on_button_toggled").bind(button_sound_on))
	button_sound_off.connect("toggled", Callable(self, "_on_button_toggled").bind(button_sound_off))
	volume_slider_bgm.connect("value_changed", Callable(self, "_on_bgm_slider_value_changed"))
	volume_slider_se.connect("value_changed", Callable(self, "_on_se_slider_value_changed"))
	button_fullscreen_on.connect("toggled", Callable(self, "_on_button_toggled").bind(button_fullscreen_on))
	button_fullscreen_off.connect("toggled", Callable(self, "_on_button_toggled").bind(button_fullscreen_off))
	button_close.connect("pressed", Callable(self, "_toggle_settings_panel_visibility"))
	icon_close.connect("pressed", Callable(self, "_toggle_settings_panel_visibility"))

func _update_button_states() -> void:
	# 一時的にシグナルを切断
	button_sound_on.disconnect("toggled", Callable(self, "_on_button_toggled").bind(button_sound_on))
	button_sound_off.disconnect("toggled", Callable(self, "_on_button_toggled").bind(button_sound_off))

	button_sound_on.set_pressed(AudioManager.sound_enabled)
	button_sound_off.set_pressed(!AudioManager.sound_enabled)

	# シグナルを再接続
	button_sound_on.connect("toggled", Callable(self, "_on_button_toggled").bind(button_sound_on))
	button_sound_off.connect("toggled", Callable(self, "_on_button_toggled").bind(button_sound_off))

	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	button_fullscreen_on.set_pressed(is_fullscreen)
	button_fullscreen_off.set_pressed(!is_fullscreen)

func _on_button_toggled(_button_pressed: bool, button: Button) -> void:
	if updating_fullscreen:
		return

	if button == button_sound_on or button == button_sound_off:
		# 一時的にシグナルを切断してボタンの状態を更新
		button_sound_on.disconnect("toggled", Callable(self, "_on_button_toggled").bind(button_sound_on))
		button_sound_off.disconnect("toggled", Callable(self, "_on_button_toggled").bind(button_sound_off))

		AudioManager.toggle_sound(not AudioManager.sound_enabled)
		_update_button_states()

		# シグナルを再接続
		button_sound_on.connect("toggled", Callable(self, "_on_button_toggled").bind(button_sound_on))
		button_sound_off.connect("toggled", Callable(self, "_on_button_toggled").bind(button_sound_off))

		current_selection = 0  # Soundボタンのインデックス
		# _update_menu_selection()
		
	elif button == button_fullscreen_on or button == button_fullscreen_off:
		_toggle_fullscreen(button == button_fullscreen_on)
		current_selection = 3  # Fullscreenボタンのインデックス
		_update_menu_selection()
	# Play sound effect when toggling
	AudioManager.play_se("CURSOR")

func _toggle_fullscreen(enable_fullscreen: bool) -> void:
	updating_fullscreen = true
	var current_mode = DisplayServer.window_get_mode()
	var new_mode = DisplayServer.WINDOW_MODE_FULLSCREEN if enable_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if current_mode != new_mode:
		DisplayServer.window_set_mode(new_mode)
		AudioManager.play_se("CURSOR")
	button_fullscreen_on.set_pressed(enable_fullscreen)
	button_fullscreen_off.set_pressed(not enable_fullscreen)
	updating_fullscreen = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select") and !is_paused:
		_toggle_settings_panel_visibility()
	elif settings_panel.visible:
		_handle_input(event)

func _handle_input(event: InputEvent) -> void:
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
	if event.pressed:
		dragging = true
		last_mouse_position = event.position
	else:
		dragging = false

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	var delta = event.position - last_mouse_position
	scroll_container.scroll_vertical -= delta.y
	scroll_container.scroll_horizontal -= delta.x
	last_mouse_position = event.position

func _change_selection(direction: int) -> void:
	current_selection = (current_selection + direction + menu_labels.size()) % menu_labels.size()
	_update_menu_selection()
	AudioManager.play_se("CURSOR")

func _toggle_settings_panel_visibility() -> void:
	settings_panel.visible = not settings_panel.visible
	current_selection = 0
	get_tree().paused = settings_panel.visible
	_update_menu_selection()

func _on_bgm_slider_value_changed(value: float) -> void:
	AudioManager.bgm_volume = value / MAX_VOLUME
	_update_label_bgm_volume()
	current_selection = 1  # BGMスライダーのインデックス
	# When the BGM slider value changes, remove focus from the slider
	volume_slider_bgm.release_focus()
	_update_menu_selection()

func _on_se_slider_value_changed(value: float) -> void:
	AudioManager.se_volume = value / MAX_VOLUME
	_update_label_se_volume()
	current_selection = 2  # SEスライダーのインデックス
	volume_slider_bgm.release_focus()
	_update_menu_selection()

func _update_label_bgm_volume(play_se: bool = true) -> void:
	label_bgm_volume.text = _get_volume_text(int(AudioManager.bgm_volume * MAX_VOLUME))
	if play_se:
		AudioManager.play_se("CURSOR")

func _update_label_se_volume(play_se: bool = true) -> void:
	label_se_volume.text = _get_volume_text(int(AudioManager.se_volume * MAX_VOLUME))
	if play_se:
		AudioManager.play_se("CURSOR")

func _get_volume_text(volume: int) -> String:
	if volume == MIN_VOLUME:
		return "OFF"
	elif volume == MAX_VOLUME:
		return "MAX"
	else:
		return str(volume).pad_zeros(3)

func _update_menu_selection() -> void:
	for i in range(menu_labels.size()):
		menu_labels[i].text = ">> " + _remove_prefix(menu_labels[i].text, ">> ") if i == current_selection else _remove_prefix(menu_labels[i].text, ">> ")

func _remove_prefix(text: String, prefix: String) -> String:
	return text.substr(prefix.length()) if text.begins_with(prefix) else text

func _handle_right_action() -> void:
	match current_selection:
		0: 
			if !AudioManager.sound_enabled:
				AudioManager.toggle_sound(true)
				AudioManager.play_se("CURSOR")
			_update_button_states()
		1: _change_volume(volume_slider_bgm, VOLUME_STEP)
		2: _change_volume(volume_slider_se, VOLUME_STEP)
		3: _toggle_fullscreen(true)
		4: _toggle_settings_panel_visibility()

func _handle_left_action() -> void:
	match current_selection:
		0: 
			if AudioManager.sound_enabled:
				AudioManager.toggle_sound(false)
				AudioManager.play_se("CURSOR")
				_update_button_states()
		1: _change_volume(volume_slider_bgm, -VOLUME_STEP)
		2: _change_volume(volume_slider_se, -VOLUME_STEP)
		3: _toggle_fullscreen(false)
		4: _toggle_settings_panel_visibility()

func _change_volume(slider: Slider, step: int) -> void:
	slider.value = clamp(slider.value + step, MIN_VOLUME, MAX_VOLUME)
	slider.release_focus()
