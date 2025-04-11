extends Control

@onready var mask = $Mask
@onready var message_label = $MessageLabel
@onready var memory_label = $MemoryLabel
@onready var health_bar = $TopBar/HealthBar
@onready var health_label = $TopBar/HealthBar/HealthLabel

var current_health: float = 0.0
var target_health: float = 0.0
var current_max_health: float = 0.0
var target_max_health: float = 0.0
var health_tween: Tween = null

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

func _on_health_changed(current: float, max_health: float) -> void:
	animate_health(current, max_health)

func _on_max_health_changed(new_max: float) -> void:
	animate_health(PlayerStats.get_health(), new_max)

func animate_health(new_health: float, new_max: float) -> void:
	# 既存のTweenを停止
	if health_tween:
		health_tween.kill()
	
	# 新しいTweenを作成
	health_tween = create_tween()
	health_tween.set_trans(Tween.TRANS_CUBIC)
	health_tween.set_ease(Tween.EASE_OUT)
	
	# 最大体力のアニメーション
	health_tween.tween_property(health_bar, "max_value", new_max, 0.3)
	
	# 現在の体力のアニメーション
	health_tween.parallel().tween_property(health_bar, "value", new_health, 0.3)
	
	# ラベルのアニメーション
	health_tween.parallel().tween_method(
		func(value: float):
			health_label.text = "%d / %d" % [int(value), int(new_max)],
		health_bar.value,
		new_health,
		0.3
	)

func get_health() -> float:
	return health_bar.value
