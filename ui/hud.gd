extends Control

@onready var mask = $Mask
@onready var message_label = $MessageLabel
@onready var memory_label = $MemoryLabel
@onready var health_bar = $TopBar/HealthBar
@onready var health_label = $TopBar/HealthBar/HealthLabel

func _ready() -> void:
	# グローバルなスコア変更シグナルを接続
	GameState.score_changed.connect(_on_score_changed)
	# 初期スコアを表示
	$TopBar/ScoreBox/ScoreLabel.text = str(GameState.score)
	# メッセージを非表示に
	hide_message()
	# 体力値を更新
	update_health_display()
	# グローバルな体力変更シグナルを接続
	PlayerStats.health_changed.connect(_on_health_changed)
	PlayerStats.max_health_changed.connect(_on_max_health_changed)

func _process(_delta: float) -> void:
	var memory_usage = int(OS.get_static_memory_usage() / 1024.0 / 1024.0)  # Convert to MB
	memory_label.text = "Memory: %d MB" % memory_usage

func _on_score_changed(value: int) -> void:
	$TopBar/ScoreBox/ScoreLabel.text = str(value)
	hide_message()

func show_message(text: String) -> void:
	message_label.text = text
	message_label.show()
	mask.visible = true

func hide_message() -> void:
	message_label.text = ""
	message_label.hide()
	mask.visible = false

func update_health_display() -> void:
	health_bar.max_value = PlayerStats.get_max_health()
	health_bar.value = PlayerStats.get_health()
	health_label.text = "%d / %d" % [PlayerStats.get_health(), PlayerStats.get_max_health()]

func _on_health_changed(_current: float, _max: float) -> void:
	update_health_display()

func _on_max_health_changed(_new_max: float) -> void:
	update_health_display()

func get_health() -> float:
	return health_bar.value
