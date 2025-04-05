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
	update_health(80)

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

func update_health(value: float) -> void:
	health_bar.value = value
	health_label.text = "%d / 100" % value

func get_health() -> float:
	return health_bar.value
