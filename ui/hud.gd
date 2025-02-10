extends MarginContainer


func _on_score_changed(value: int) -> void:
	$HBoxContainer/ScoreLabel.text = str(value)
