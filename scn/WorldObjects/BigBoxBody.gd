extends CharacterBody2D

const SPEED = 300.0

var gravity = 980

func _physics_process(delta):
	if !is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()
