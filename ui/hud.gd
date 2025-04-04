extends Control

@onready var mask = $Mask
@onready var message_label = $MessageLabel
@onready var memory_label = $MemoryLabel

func _process(_delta: float) -> void:
	var memory_usage = OS.get_static_memory_usage() / 1024.0 / 1024.0  # Convert to MB
	memory_label.text = "Memory: %.2f MB" % memory_usage

func _on_score_changed(value: int) -> void:
	$ScoreLabel.text = str(value)
	hide_message()

func show_message(text: String) -> void:
	message_label.text = text
	message_label.show()
	mask.visible = true

func hide_message() -> void:
	message_label.text = ""
	message_label.hide()
	mask.visible = false
