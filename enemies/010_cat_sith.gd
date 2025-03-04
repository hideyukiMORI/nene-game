extends CharacterBody2D

@export var speed: int = 10
@export var gravity: int = 900
var facing: int = 1
var player_in_range: bool = false  # プレイヤーが範囲内にいるかどうかのフラグ

func _ready():
	$Sprite2D.flip_h = true
	$TalkPrompt.flip_h = false

func _physics_process(delta: float) -> void:
	# $Sprite2D.flip_h = velocity.x < 0
	velocity.y += gravity * delta
	move_and_slide()
	
	# プレイヤーが範囲内にいる状態でclimbキーが押されたら会話開始
	if player_in_range and Input.is_action_pressed("climb"):

		var message_text = """ [color=#FF9ECD][wave amp=20 freq=2]Cat Sith[/wave][/color]:
"[i]Well well... What do we have here?
A little witch in my territory?[/i]"

[color=#7DFFB2]Nene[/color]:
"[shake rate=5 level=5]Eek![/shake] A... a talking cat!?"

[color=#FF9ECD]Cat Sith[/color]:
"[rainbow freq=0.5]Not just any cat, dearie...[/rainbow] 
[wave amp=30 freq=3]I am a Cat Sith, a magical feline![/wave]"

[color=#7DFFB2]Nene[/color]:
"[b]Oh![/b] I've read about you in my spellbooks!"

"""

		DialogueManager.show_dialogue(message_text)  # 直接DialogueManagerを呼ぶ
		# DialogueManager.show_dialogue("cat_sith_first")  # 直接DialogueManagerを呼ぶ

	if position.y > 1000:
		queue_free()

func take_damage():
	pass

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$TalkPrompt.on_active()
		player_in_range = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		$TalkPrompt.on_inactive()
		player_in_range = false
