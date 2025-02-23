extends Control

@onready var mask = $Mask
@onready var message_label = $MessageLabel

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
