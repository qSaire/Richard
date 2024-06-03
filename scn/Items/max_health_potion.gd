extends CharacterBody2D

var gravity = 980
var is_picked = false
var is_nearPlayer = false
var additionalHealth = 20

func _ready():
	$EquipLabel.text = InputMap.action_get_events("use")[0].as_text()[0] + " Взять"
	if is_picked:
		queue_free()

func _physics_process(delta):
	if !is_on_floor():
		velocity.y += gravity * delta
	elif is_nearPlayer:
		$EquipLabel.visible = true
		if Input.is_action_just_pressed("use"):
			is_picked = true
			Events.emit_signal("maxHealthPotionPicked", additionalHealth)
			Global.emit_signal("sendNotification", "Максимальное здоровье увеличено")
			queue_free()
	
	move_and_slide()

func _on_pick_area_body_entered(_body):
	is_nearPlayer = true

func _on_pick_area_body_exited(_body):
	is_nearPlayer = false
	$EquipLabel.visible = false
