extends CharacterBody2D

@export var speed: int = 10
@export var gravity: int = 900
var facing: int = 1

func _ready():
	$Sprite2D.flip_h = true
	$TalkPrompt.flip_h = false

func _physics_process(delta: float) -> void:
	# $Sprite2D.flip_h = velocity.x < 0
	velocity.y += gravity * delta
	move_and_slide()
	
	

	if position.y > 1000:
		queue_free()

func take_damage():
	pass


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$TalkPrompt.on_active()


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		$TalkPrompt.on_inactive()
