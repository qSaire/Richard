extends CharacterBody2D

var gravity = 980
var is_inPickArea = false
var is_picked = false
var healPoints = 30

func _ready():
	if is_picked:
		queue_free()

func _physics_process(delta):
	if !is_on_floor():
		velocity.y += gravity * delta
	
	if is_inPickArea && Global.playerCurrentHealth < Global.playerMaxHealth:
		Events.emit_signal("healthPotionPicked", healPoints)
		queue_free()
	
	move_and_slide()

func _on_pick_area_body_entered(_body):
	is_inPickArea = true

func _on_pick_area_body_exited(_body):
	is_inPickArea = false
