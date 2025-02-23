extends Control

# Declare the StartSound variable
@onready var start_sound = $StartSound
@onready var settings_panel = $SettingPanel  # 追加したPanelノードを参照
@onready var scroll_container = $SettingPanel/ScrollContainer  # 追加したScrollContainerノードを参照
@onready var buttonSoundOn = $SettingPanel/ScrollContainer/SettingList/Sound/OnButton
@onready var buttonSoundOff = $SettingPanel/ScrollContainer/SettingList/Sound/OffButton

var dragging = false
var last_mouse_position = Vector2()
var sound_enabled = true

func _ready() -> void:
	# Panelを非表示に設定
	settings_panel.visible = false
	# トグルモードを有効にする
	buttonSoundOn.toggle_mode = true
	buttonSoundOff.toggle_mode = true

	# シグナル接続
	buttonSoundOn.connect("toggled", Callable(self, "_on_button_toggled").bind(buttonSoundOn))
	buttonSoundOff.connect("toggled", Callable(self, "_on_button_toggled").bind(buttonSoundOff))

func _on_button_toggled(button_pressed: bool, button: Button) -> void:
	if button == buttonSoundOn:
		sound_enabled = button_pressed
		buttonSoundOff.disconnect("toggled", Callable(self, "_on_button_toggled"))
		buttonSoundOff.set_pressed(!button_pressed)
		buttonSoundOff.connect("toggled", Callable(self, "_on_button_toggled").bind(buttonSoundOff))
	elif button == buttonSoundOff:
		sound_enabled = !button_pressed
		buttonSoundOn.disconnect("toggled", Callable(self, "_on_button_toggled"))
		buttonSoundOn.set_pressed(!button_pressed)
		buttonSoundOn.connect("toggled", Callable(self, "_on_button_toggled").bind(buttonSoundOn))

	# サウンドの状態を出力
	print("Sound enabled:", sound_enabled)

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
		start_sound.connect("finished", Callable(self, "_on_StartSound_finished"))

	if event.is_action_pressed("select"):
		# Panelの表示をトグル
		settings_panel.visible = not settings_panel.visible

func _on_StartSound_finished() -> void:
	# Change the scene after the sound has finished playing
	get_tree().change_scene_to_file(GameState.game_scene)
